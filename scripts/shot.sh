#!/usr/bin/env bash
#
# shot.sh — build ExpenseKu for the iOS Simulator, drive it to a known state via
# DebugLaunch launch args, and capture a screenshot for the revamp verify loop.
#
# The app's DebugLaunch (Shared/DebugLaunch.swift) reads these launch args:
#   -seedSampleData                       seed a fixed dataset (only if store empty)
#   -startTab expenses|insights|manage
#   -startScreen categories|people|accounts|leaderboard
#
# Usage:
#   scripts/shot.sh <name> [options] [-- <extra launch args>]
#
#   scripts/shot.sh home            -- -seedSampleData -startTab expenses
#   scripts/shot.sh home-dark   -a  -- -seedSampleData -startTab expenses
#   scripts/shot.sh leaderboard     -- -seedSampleData -startScreen leaderboard
#   scripts/shot.sh --test          # run the unit tests, no screenshot
#
# Options:
#   -a            dark appearance (default: light)
#   -d <device>   simulator name or UDID (default: $SHOT_DEVICE or "iPhone 17 Pro")
#   -w <seconds>  seconds to wait after launch before the shot (default: 4)
#   --test        run `xcodebuild test` instead of screenshotting; exits non-zero on failure
#   --            everything after is passed verbatim as launch args to the app
#
# Output: .scratch/revamp/shots/<name>.png
#
# Worktree-safe: DerivedData lives under this checkout, and the target simulator is
# selectable, so parallel agents in separate worktrees can each target their own device.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT="$ROOT/ExpenseKu/ExpenseKu.xcodeproj"
SCHEME="ExpenseKu"
BUNDLE_ID="${SHOT_BUNDLE_ID:-randyefan.ExpenseKu}"
DERIVED="$ROOT/.scratch/revamp/DerivedData"
SHOTS="$ROOT/.scratch/revamp/shots"
DEVICE="${SHOT_DEVICE:-iPhone 17 Pro}"
APPEARANCE="light"
WAIT=4
MODE="shot"

# --- arg parsing -------------------------------------------------------------
if [[ "${1:-}" == "--test" ]]; then MODE="test"; shift; fi
NAME="${1:-}"; [[ "$MODE" == "shot" ]] && shift || true
LAUNCH_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -a) APPEARANCE="dark"; shift;;
    -d) DEVICE="$2"; shift 2;;
    -w) WAIT="$2"; shift 2;;
    --) shift; LAUNCH_ARGS=("$@"); break;;
    *) echo "unknown option: $1" >&2; exit 2;;
  esac
done

# --- test mode ---------------------------------------------------------------
if [[ "$MODE" == "test" ]]; then
  echo "==> xcodebuild test ($DEVICE)"
  xcodebuild test -project "$PROJECT" -scheme "$SCHEME" -configuration Debug \
    -destination "platform=iOS Simulator,name=$DEVICE" \
    -derivedDataPath "$DERIVED" -quiet
  exit $?
fi

[[ -z "$NAME" ]] && { echo "usage: shot.sh <name> [-a] [-d device] [-- launch args]" >&2; exit 2; }
mkdir -p "$SHOTS"

# --- resolve + boot device ---------------------------------------------------
UDID="$(xcrun simctl list devices available | grep -F "$DEVICE (" | head -1 | grep -oE '[0-9A-F-]{36}')"
[[ -z "$UDID" ]] && { echo "no available simulator matching '$DEVICE'" >&2; exit 1; }
echo "==> device $DEVICE ($UDID)"
if ! xcrun simctl list devices | grep -F "$UDID" | grep -q "(Booted)"; then
  echo "==> booting"; xcrun simctl boot "$UDID" 2>/dev/null || true; sleep 3
fi

# --- build -------------------------------------------------------------------
echo "==> building"
xcodebuild build -project "$PROJECT" -scheme "$SCHEME" -configuration Debug \
  -destination "id=$UDID" -derivedDataPath "$DERIVED" -quiet
APP="$DERIVED/Build/Products/Debug-iphonesimulator/$SCHEME.app"
[[ -d "$APP" ]] || { echo "built app not found at $APP" >&2; exit 1; }

# --- install, appearance, launch, shoot --------------------------------------
xcrun simctl ui "$UDID" appearance "$APPEARANCE" >/dev/null 2>&1 || true
xcrun simctl uninstall "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$UDID" "$APP"
echo "==> launching ($APPEARANCE): ${LAUNCH_ARGS[*]:-<none>}"
xcrun simctl launch "$UDID" "$BUNDLE_ID" "${LAUNCH_ARGS[@]}" >/dev/null
sleep "$WAIT"
OUT="$SHOTS/$NAME.png"
xcrun simctl io "$UDID" screenshot "$OUT" >/dev/null
echo "==> wrote $OUT"
