#!/usr/bin/env bash
#
# test-release.sh — run the unit tests against an optimized (Release) build.
#
# TestFlight and the App Store ship Release. Some SwiftData paths behave differently
# once optimized — a generic `propertiesToFetch` key path passed every Debug test and
# still crashed build 1.1 (3) on device. Run this before every archive.
#
# Usage:
#   scripts/test-release.sh                    # whole suite
#   scripts/test-release.sh ExistingEntityTests  # one test class
#
set -euo pipefail

source "$(dirname "$0")/xcode-env.sh"

cd "$(dirname "$0")/../ExpenseKu"

DEVICE="${DEVICE:-iPhone 17 Pro}"
UDID="$(xcrun simctl list devices available | grep -F "$DEVICE (" | head -1 | grep -oE '[0-9A-F-]{36}')"
ONLY=()
if [[ $# -gt 0 ]]; then
  ONLY=(-only-testing:"ExpenseKuTests/$1")
fi

xcodebuild test \
  -project ExpenseKu.xcodeproj \
  -scheme ExpenseKu \
  -configuration Release \
  ENABLE_TESTABILITY=YES \
  -destination "id=$UDID" \
  -only-testing:ExpenseKuTests \
  "${ONLY[@]+"${ONLY[@]}"}" \
  | grep -iE "error:|test case .* failed|crashed|restarting after unexpected exit|\*\* TEST (SUCCEEDED|FAILED) \*\*"
