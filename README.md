# KeyRemap Lite

A tiny macOS app for 1-to-1 key remapping (e.g. swap Esc ⇄ Caps Lock), with a menu bar status icon.

Inspired by [Karabiner-Elements](https://github.com/pqrs-org/Karabiner-Elements). This project started as a fork of it, then was rewritten from scratch for one job: simple key remaps, as light as possible.

| | Karabiner-Elements | KeyRemap Lite |
|---|---|---|
| Disk | ~170 MB | ~0.5 MB |
| RAM | ~23 MB (5 processes + driver) | ~18 MB (1 process, optional) |
| Kernel/driver extension | Yes | No |
| Remap engine | Own virtual HID driver | macOS built-in `hidutil` |

## How it works

- **Apply** runs `hidutil property --set` with your mappings, so the remap is active immediately.
- It also writes `~/Library/LaunchAgents/local.keyremap-lite.plist`, which reruns `hidutil` at every login.
- The remap does not depend on the app running. Quitting the app only hides the menu bar icon.
- The app registers itself as a login item so the menu bar icon is back after login. You can turn this off in System Settings → General → Login Items.

## Limitations

- Only 1 key → 1 key. No tap/hold, combos, or per-app rules (use Karabiner-Elements for those).
- Applies to all keyboards.
- Not active on the login / FileVault screen, only after you log in.

## Install

1. Download `KeyRemap-Lite.zip` from the [latest release](https://github.com/Mqdd27/keyremap-mac/releases/latest) and unzip it.
2. Move `KeyRemap Lite.app` to `/Applications`.
3. The app is not notarized by Apple, so macOS blocks it on first launch. Either:
   - open it once, then go to System Settings → Privacy & Security → **Open Anyway**, or
   - run `xattr -dr com.apple.quarantine "/Applications/KeyRemap Lite.app"`.
4. Click the ⌨️ menu bar icon → **Edit Remap…**, add your mappings, and click **Apply**.

Works on Apple Silicon and Intel, macOS 15+.

## Build from source

Requires macOS 15+ and the Xcode Command Line Tools (`xcode-select --install`). Xcode itself is not needed.

```sh
./build.sh
mv "KeyRemap Lite.app" /Applications/
open "/Applications/KeyRemap Lite.app"
```

Then click the ⌨️ menu bar icon → **Edit Remap…**, add your mappings, and click **Apply**.

## Uninstall

1. Open the app and click **Reset** (removes the remap and the LaunchAgent).
2. Quit it from the menu bar and delete `/Applications/KeyRemap Lite.app`.

## Files

- `main.swift`: the whole app (SwiftUI menu bar + editor window).
- `icon.swift`: draws the app icon at build time.
- `build.sh`: compiles with `swiftc`, builds the `.app` bundle and icon, ad-hoc signs it.

## License

Public domain ([Unlicense](LICENSE)), same as Karabiner-Elements.
