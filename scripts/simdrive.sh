#!/usr/bin/env bash
#
# simdrive.sh — drive the booted iOS Simulator like a user: synthesize taps at
# screenshot-pixel coordinates, send key combos, relaunch, and screenshot. This
# is the INTERACTIVE verify tool for the feature harness: `shot.sh` only takes a
# static picture after launch (it never taps or types), so it can prove how a
# screen *looks* but not how it *behaves*. Use this to run a feature's real flow.
#
# Requires `cliclick` (brew install cliclick) and two macOS permissions for whatever
# runs it (Terminal/your agent host), both under System Settings → Privacy & Security:
# Accessibility (for the synthetic clicks) and Automation → Simulator (for raising
# the window before each one).
#
# Coordinates are SCREENSHOT PIXELS — the same numbers you read off a shot taken
# by this script or by shot.sh (e.g. a 1206×2622 PNG). You do NOT convert to
# points or screen coordinates; this script maps pixel → on-screen for you using
# the live Simulator window bounds. Workflow: `shot before`, Read before.png, pick
# the pixel you want to hit, `tap <x> <y>`, `shot after`, Read after.png, compare.
#
# Usage:
#   scripts/simdrive.sh launch [-a] [-- <launch args>]   relaunch the app (fresh state)
#   scripts/simdrive.sh shot   <name>                    screenshot → $SHOTS/<name>.png
#   scripts/simdrive.sh tap    <px> <py>                 tap at screenshot-pixel (px,py)
#   scripts/simdrive.sh swipe  <x1> <y1> <x2> <y2>       drag between two pixels
#   scripts/simdrive.sh key    [cmd|shift|option|ctrl ...] <key>   send a key combo
#
# `key` goes through AppleScript `keystroke`, so it sends whole STRINGS, not just
# single keys: `key kopi` types "kopi" in one call.
#
# `swipe` is what you need for anything gesture-driven — swipe-to-delete, sheet
# dismissal, paging. It presses, moves through intermediate points, then releases;
# the intermediate points are required, since a single jump reads as a teleport
# and UIKit won't recognise it as a swipe.
#   scripts/simdrive.sh bounds                           print the pixel→screen mapping
#
#   # Reveal the software keyboard (Simulator hides it when a HW keyboard is on):
#   scripts/simdrive.sh key cmd k
#
# Env: SHOT_DEVICE (default "iPhone 17 Pro"), SHOT_BUNDLE_ID (default
# randyefan.ExpenseKu), SIM_SHOTS (default .scratch/revamp/shots),
# SIM_TITLEBAR (window title-bar height in pt, default 28).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DERIVED="$ROOT/.scratch/revamp/DerivedData"
SHOTS="${SIM_SHOTS:-$ROOT/.scratch/revamp/shots}"
DEVICE="${SHOT_DEVICE:-iPhone 17 Pro}"
BUNDLE_ID="${SHOT_BUNDLE_ID:-randyefan.ExpenseKu}"
TITLEBAR="${SIM_TITLEBAR:-28}"

command -v cliclick >/dev/null || { echo "cliclick not found — run: brew install cliclick" >&2; exit 1; }

UDID="$(xcrun simctl list devices available | grep -F "$DEVICE (" | head -1 | grep -oE '[0-9A-F-]{36}')"
[[ -z "$UDID" ]] && { echo "no available simulator matching '$DEVICE'" >&2; exit 1; }
if ! xcrun simctl list devices | grep -F "$UDID" | grep -q "(Booted)"; then
  xcrun simctl boot "$UDID" 2>/dev/null || true; sleep 3
fi
# Bring the Simulator window forward WITHOUT clicking it (a click would be
# swallowed as window activation instead of registering as an in-app tap).
#
# `activate` is sent to the app itself, not to its process via System Events: the
# System Events form fails with -10006 when Simulator is not already running, and
# `activate` launches it instead. Failure is fatal on purpose — a silent no-op here
# lands every subsequent tap on the desktop, which looks exactly like a broken app.
frontmost() {
  osascript -e 'tell application "Simulator" to activate' >/dev/null || {
    echo "could not bring Simulator forward — grant Automation permission under" >&2
    echo "System Settings → Privacy & Security → Automation" >&2
    exit 1
  }
}

frontmost

# Live pixel→screen mapping.
#
# Preferred source: the Simulator window's device-screen AXGroup, whose position and
# size ARE the on-screen device rect — no guessing. `k` = on-screen points per
# screenshot pixel = groupWidth / pixelWidth; the same scale applies on both axes.
#
# Fallback (only if that element can't be read): the old estimate, which assumes the
# screen sits below a TITLEBAR-tall bar, horizontally centered in the window. That
# estimate is fragile — the title bar is not really 28pt on current Simulator builds,
# and the resulting ~28pt y-error silently lands taps just outside small controls.
read_mapping() {
  local grp gx gy gw gh tmp pxW pxH k
  local pos size WX WY WW WH devW originX originY

  tmp="$(mktemp -t simdrive).png"
  xcrun simctl io "$UDID" screenshot "$tmp" >/dev/null 2>&1
  pxW="$(sips -g pixelWidth "$tmp" | awk '/pixelWidth/{print $2}')"
  pxH="$(sips -g pixelHeight "$tmp" | awk '/pixelHeight/{print $2}')"
  rm -f "$tmp"

  # {x, y, w, h} of the device screen inside the window.
  grp="$(osascript -e 'tell application "System Events" to tell process "Simulator" to tell window 1 to get {position, size} of (first UI element whose role is "AXGroup")' 2>/dev/null || true)"
  if [[ -n "$grp" ]]; then
    IFS=', ' read -r gx gy gw gh <<< "$(echo "$grp" | tr -d ' ' | tr ',' ' ')"
  fi

  # Accept it only if its aspect ratio matches the screenshot's (guards against
  # picking up some other group if the window layout ever changes).
  if [[ -n "${gw:-}" && -n "${gh:-}" && "$gw" -gt 0 && "$gh" -gt 0 ]] \
     && awk -v a="$gw" -v b="$gh" -v c="$pxW" -v d="$pxH" \
            'BEGIN { r = a/b - c/d; if (r < 0) r = -r; exit !(r < 0.01) }'; then
    k="$(echo "scale=8; $gw / $pxW" | bc -l)"
    echo "$gx $gy $k"
    return
  fi

  pos="$(osascript -e 'tell application "System Events" to tell process "Simulator" to get position of window 1')"
  size="$(osascript -e 'tell application "System Events" to tell process "Simulator" to get size of window 1')"
  WX="${pos%%,*}"; WY="$(echo "$pos" | sed 's/.*, *//')"
  WW="${size%%,*}"; WH="$(echo "$size" | sed 's/.*, *//')"
  k="$(echo "scale=8; ($WH - $TITLEBAR) / $pxH" | bc -l)"
  devW="$(echo "scale=8; $pxW * $k" | bc -l)"
  originX="$(echo "scale=8; $WX + ($WW - $devW) / 2" | bc -l)"
  originY="$(echo "scale=8; $WY + $TITLEBAR" | bc -l)"
  echo "$originX $originY $k"
}

case "${1:-}" in
  launch)
    shift
    APPEARANCE="light"; ARGS=()
    while [[ $# -gt 0 ]]; do case "$1" in
      -a) APPEARANCE="dark"; shift;;
      --) shift; ARGS=("$@"); break;;
      *) ARGS+=("$1"); shift;;
    esac; done
    xcrun simctl ui "$UDID" appearance "$APPEARANCE" >/dev/null 2>&1 || true
    xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
    xcrun simctl launch "$UDID" "$BUNDLE_ID" "${ARGS[@]}" >/dev/null
    sleep 2; frontmost
    echo "launched ${ARGS[*]:-<none>} ($APPEARANCE)"
    ;;

  shot)
    NAME="${2:?usage: simdrive.sh shot <name>}"
    mkdir -p "$SHOTS"
    xcrun simctl io "$UDID" screenshot "$SHOTS/$NAME.png" >/dev/null
    echo "$SHOTS/$NAME.png"
    ;;

  tap)
    PX="${2:?usage: simdrive.sh tap <px> <py>}"; PY="${3:?usage: simdrive.sh tap <px> <py>}"
    frontmost; sleep 1
    read OX OY K < <(read_mapping)
    SX="$(printf '%.0f' "$(echo "$OX + $PX * $K" | bc -l)")"
    SY="$(printf '%.0f' "$(echo "$OY + $PY * $K" | bc -l)")"
    cliclick "c:$SX,$SY"
    echo "tapped pixel ($PX,$PY) → screen ($SX,$SY)"
    ;;

  press)
    PX="${2:?usage: simdrive.sh press <px> <py> [ms]}"; PY="${3:?usage: simdrive.sh press <px> <py> [ms]}"
    MS="${4:-140}"
    frontmost; sleep 1
    read OX OY K < <(read_mapping)
    SX="$(printf '%.0f' "$(echo "$OX + $PX * $K" | bc -l)")"
    SY="$(printf '%.0f' "$(echo "$OY + $PY * $K" | bc -l)")"
    # Hold briefly instead of an instant click. Rows inside a List sit under a
    # scroll-view gesture recogniser that delays touch delivery to decide
    # tap-vs-scroll; a zero-duration click is discarded before it resolves.
    cliclick "dd:$SX,$SY" "w:$MS" "du:$SX,$SY"
    echo "pressed pixel ($PX,$PY) for ${MS}ms → screen ($SX,$SY)"
    ;;

  swipe)
    X1="${2:?usage: simdrive.sh swipe <x1> <y1> <x2> <y2>}"; Y1="${3:?usage: simdrive.sh swipe <x1> <y1> <x2> <y2>}"
    X2="${4:?usage: simdrive.sh swipe <x1> <y1> <x2> <y2>}"; Y2="${5:?usage: simdrive.sh swipe <x1> <y1> <x2> <y2>}"
    frontmost; sleep 1
    read OX OY K < <(read_mapping)
    SX1="$(printf '%.0f' "$(echo "$OX + $X1 * $K" | bc -l)")"
    SY1="$(printf '%.0f' "$(echo "$OY + $Y1 * $K" | bc -l)")"
    SX2="$(printf '%.0f' "$(echo "$OX + $X2 * $K" | bc -l)")"
    SY2="$(printf '%.0f' "$(echo "$OY + $Y2 * $K" | bc -l)")"
    # Press, move in steps, release. The intermediate `dm:` points matter: a single
    # jump from start to end reads as a teleport and UIKit won't recognise a swipe.
    MIDX1="$(printf '%.0f' "$(echo "$SX1 + ($SX2 - $SX1) * 0.33" | bc -l)")"
    MIDY1="$(printf '%.0f' "$(echo "$SY1 + ($SY2 - $SY1) * 0.33" | bc -l)")"
    MIDX2="$(printf '%.0f' "$(echo "$SX1 + ($SX2 - $SX1) * 0.66" | bc -l)")"
    MIDY2="$(printf '%.0f' "$(echo "$SY1 + ($SY2 - $SY1) * 0.66" | bc -l)")"
    cliclick "dd:$SX1,$SY1" "dm:$MIDX1,$MIDY1" "dm:$MIDX2,$MIDY2" "dm:$SX2,$SY2" "du:$SX2,$SY2"
    echo "swiped pixel ($X1,$Y1) → ($X2,$Y2)  [screen ($SX1,$SY1) → ($SX2,$SY2)]"
    ;;

  key)
    shift
    [[ $# -ge 1 ]] || { echo "usage: simdrive.sh key [cmd|shift|option|ctrl ...] <key>" >&2; exit 2; }
    KEY="${!#}"; MODS=()
    for ((i=1; i<$#; i++)); do case "${!i}" in
      cmd|command) MODS+=("command down");;
      shift) MODS+=("shift down");;
      option|alt) MODS+=("option down");;
      ctrl|control) MODS+=("control down");;
    esac; done
    frontmost; sleep 1
    if [[ ${#MODS[@]} -gt 0 ]]; then
      USING="using {$(IFS=,; echo "${MODS[*]}")}"
    else USING=""; fi
    osascript -e "tell application \"System Events\" to keystroke \"$KEY\" $USING"
    echo "sent key: ${*}"
    ;;

  bounds)
    read OX OY K < <(read_mapping)
    printf 'origin=(%.1f, %.1f)  scale=%.5f screen-pt/screenshot-px\n' "$OX" "$OY" "$K"
    ;;

  *)
    grep '^#' "$0" | sed 's/^# \{0,1\}//' | sed '1d'
    exit 2
    ;;
esac
