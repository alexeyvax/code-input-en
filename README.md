# Code Input EN

Code Input EN is a small native macOS menu bar utility that selects a chosen ASCII-capable keyboard input source whenever Apple Terminal, Visual Studio Code, or Xcode becomes the foreground application. It responds only to application-activation notifications, so it does not poll or prevent you from changing the input source manually while a supported application remains active.

Repository: `code-input-en`  
Homebrew Cask token: `code-input-en`

## Requirements and build

- macOS 13.0 or newer
- Xcode with the macOS SDK
- No third-party dependencies

Open `CodeInputEN.xcodeproj` in Xcode and run the `CodeInputEN` scheme, or build from the repository root:

```bash
xcodebuild \
  -project CodeInputEN.xcodeproj \
  -scheme CodeInputEN \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Run the unit tests with:

```bash
xcodebuild \
  -project CodeInputEN.xcodeproj \
  -scheme CodeInputEN \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

## Install and use

Build the app, move `Code Input EN.app` to `/Applications`, and launch it. Finder displays it as **Code Input EN**. It appears as an `en` icon in the menu bar and does not appear in the Dock. On first launch it prefers an installed English layout matching the Mac's region (U.S., British, Australian, Canadian, Irish, New Zealand, or ABC – India), then falls back to ABC, U.S., or the first available ASCII-capable source.

The menu provides:

- **Enabled** — enables or disables switching when Apple Terminal, Visual Studio Code, or Xcode receives focus.
- **English Layout** — selects any enabled ASCII-capable input source, including regional English layouts, and marks the saved choice.
- **Launch at Login** — registers or unregisters the app with macOS using `SMAppService`. A mixed state means macOS requires approval in **System Settings → General → Login Items**.
- **Quit** — stops the observer and exits the app.

Settings are stored in `UserDefaults`. The source is saved by its stable Text Input Source Services identifier rather than its localized name.

## Privacy

Code Input EN has no networking, telemetry, analytics, crash reporting, or third-party runtime code. It observes foreground application changes locally and writes preferences only when you change a setting. It does not use Accessibility, AppleScript, or simulated keystrokes.

## Troubleshooting

If the menu says the selected layout is unavailable, add an English/ASCII-capable input source in **System Settings → Keyboard → Text Input → Edit**, then choose it from **English Layout**. If Launch at Login shows an approval warning, allow Code Input EN in **System Settings → General → Login Items**; the menu reflects macOS's actual registration status.

Only input sources enabled in macOS appear in the menu. To use British, Australian, Canadian, Irish, New Zealand, ABC – India, U.S. International, or another layout, first add it in **System Settings → Keyboard → Text Input → Edit**.

For a locally built app, Launch at Login works most reliably after moving `Code Input EN.app` to `/Applications` and launching it from there. Rebuild and relaunch after changing its bundle location.

## Removal

Turn off **Launch at Login**, choose **Quit**, and delete `Code Input EN.app`. You may also remove its preferences with:

```bash
defaults delete com.alexeyvax.CodeInputEN
```

## Known limitation

The app recognizes Apple Terminal (`com.apple.Terminal`), stable Visual Studio Code (`com.microsoft.VSCode`), and Xcode (`com.apple.dt.Xcode`). Because macOS application-activation notifications cannot identify the focused control inside an application, switching applies to the entire VS Code or Xcode application, not only VS Code's integrated terminal or Xcode's editor. The app switches once when focus enters a supported application; it neither restores the prior source on exit nor enforces the selected source while that application remains focused. VS Code Insiders, Xcode beta releases with a different bundle identifier, and other variants are not currently matched.
