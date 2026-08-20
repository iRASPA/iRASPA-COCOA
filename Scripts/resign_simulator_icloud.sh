#!/bin/bash
# Xcode Simulator uses "Sign to Run Locally" with an empty .xcent. The real iCloud
# entitlements are only in *-Simulated.xcent, so CloudKit calls hang forever.
# Re-sign the Simulator app ad-hoc but with those entitlements embedded.
set -euo pipefail

if [[ "${PLATFORM_NAME:-}" != "iphonesimulator" ]]; then
  exit 0
fi

APP="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"
SIM_XCENT="${TARGET_TEMP_DIR}/${FULL_PRODUCT_NAME}-Simulated.xcent"
if [[ ! -f "$SIM_XCENT" ]]; then
  echo "warning: missing Simulated.xcent at $SIM_XCENT — CloudKit may hang on Simulator"
  exit 0
fi

ENT="${TEMP_DIR}/iraspa-simulator-entitlements.plist"
plutil -convert xml1 -o "$ENT" "$SIM_XCENT"
/usr/libexec/PlistBuddy -c "Add :get-task-allow bool true" "$ENT" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Set :get-task-allow true" "$ENT"

echo "Note: embedding Simulated CloudKit entitlements into Simulator ad-hoc signature"
codesign --force --sign - --entitlements "$ENT" --timestamp=none "$APP"
echo "Embedded entitlements:"
codesign -d --entitlements :- "$APP" 2>/dev/null | plutil -p - | head -30
