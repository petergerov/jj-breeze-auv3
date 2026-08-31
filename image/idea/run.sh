#!/bin/zsh
# Build + install + launch + screenshot on one simulator.
# The binaries are deleted first: this project's build system keeps
# reporting "up to date" for the link step even when the objects rebuilt,
# so removing the outputs forces Ld to run.
set -e
DEV="$1"; SHOT="$2"
P=/Users/pgerov/Library/Developer/Xcode/DerivedData/JJBreeze-bcrqdyngcsimgffreyfpucuphyay/Build/Products/Debug-iphonesimulator
D="$P/jj-breeze.app"
rm -rf "$D" "$P/JJBreezeExtension.appex"
xcodebuild -project JJBreeze.xcodeproj -scheme jj-breeze -destination "id=$DEV" \
  -configuration Debug ENABLE_DEBUG_DYLIB=NO build 2>&1 | grep -E "error:|BUILD" | head -8
xcrun simctl terminate "$DEV" com.gerov.jjbreeze 2>/dev/null || true
xcrun simctl install "$DEV" "$D"
xcrun simctl launch "$DEV" com.gerov.jjbreeze
sleep 6
xcrun simctl io "$DEV" screenshot --type=png "$SHOT" >/dev/null 2>&1
echo "shot: $SHOT"
