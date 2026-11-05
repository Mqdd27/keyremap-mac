#!/bin/sh
# Builds KeyRemap Lite.app next to this script.
set -e
cd "$(dirname "$0")"
APP="KeyRemap Lite.app"
rm -rf "$APP" && mkdir -p "$APP/Contents/MacOS"
swiftc -O -parse-as-library main.swift -o "$APP/Contents/MacOS/KeyRemapLite"
mkdir -p "$APP/Contents/Resources" icon.iconset
swift icon.swift icon.png
for n in 16 32 128 256 512; do
  sips -z $n $n icon.png --out icon.iconset/icon_${n}x${n}.png >/dev/null
  sips -z $((n*2)) $((n*2)) icon.png --out icon.iconset/icon_${n}x${n}@2x.png >/dev/null
done
iconutil -c icns icon.iconset -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf icon.iconset icon.png
cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>KeyRemapLite</string>
<key>CFBundleIdentifier</key><string>local.keyremap-lite</string>
<key>CFBundleName</key><string>KeyRemap Lite</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSMinimumSystemVersion</key><string>15.0</string>
<key>LSUIElement</key><true/>
<key>CFBundleIconFile</key><string>AppIcon</string>
</dict></plist>
EOF
codesign -s - --force "$APP"
du -sh "$APP"
