# Releasing Code Input EN

Code Input EN has two distinct distribution paths. A GitHub build uses Developer ID signing and notarization without App Sandbox. A future Mac App Store build must use a separate sandboxed configuration and Apple Distribution signing.

## GitHub Release

Requirements:

- An active Apple Developer Program membership
- A `Developer ID Application` certificate installed in Keychain Access
- Xcode signed in to the Apple Developer account
- A clean working tree on the exact commit being released

Release steps:

1. Confirm `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`, update `CHANGELOG.md`, and verify the working tree:

   ```bash
   git status --short
   git rev-parse HEAD
   ```

2. Build and test the exact commit without signing:

   ```bash
   xcodebuild \
     -project CodeInputEN.xcodeproj \
     -scheme CodeInputEN \
     -configuration Release \
     -destination 'platform=macOS' \
     CODE_SIGNING_ALLOWED=NO \
     clean test
   ```

3. In Xcode, select **Any Mac**, then choose **Product → Archive**. In Organizer, choose **Distribute App → Developer ID → Upload** and keep automatic signing enabled. Xcode signs with an available Developer ID identity, uploads the app for notarization, and exports the notarized result. Do not hardcode a certificate name in the project.

4. Inspect and verify the exported app. If the exported app is not already stapled, staple the notarization ticket before validation:

   ```bash
   codesign --verify --deep --strict --verbose=2 "Code Input EN.app"
   codesign -dvvv --entitlements :- "Code Input EN.app"
   xcrun stapler staple "Code Input EN.app"
   xcrun stapler validate "Code Input EN.app"
   spctl --assess --type execute --verbose=2 "Code Input EN.app"
   ```

5. Create the distributable ZIP and checksum beside the exported app:

   ```bash
   ditto -c -k --sequesterRsrc --keepParent \
     "Code Input EN.app" "Code-Input-EN-1.0.0.zip"
   shasum -a 256 "Code-Input-EN-1.0.0.zip" \
     > "Code-Input-EN-1.0.0.zip.sha256"
   ```

6. Create tag `v1.0.0` from the tested commit, then create a **draft** GitHub Release titled `Code Input EN 1.0.0`. Attach both the ZIP and `.sha256` file and copy the checksum into the notes.

7. Download the draft assets on another Mac, verify the checksum, unzip the app, and test first launch, layout switching in every supported app, manual layout changes, Enable/Disable, Quit/relaunch, the menu-bar icon in light and dark modes, and Launch at Login after a restart.

8. Publish only after the clean-machine check succeeds and the repository owner explicitly confirms publication. Updating the Homebrew Cask is a separate post-release action.

## Mac App Store (deferred)

Do not upload the Developer ID build to App Store Connect. This path starts only after the notarized GitHub distribution is stable.

When that gate is reached:

1. Add a separate `AppStore` build configuration and entitlements file. Enable App Sandbox only there; keep the normal Debug and Release configurations unsandboxed.
2. Use automatic Apple Distribution signing for the Store archive.
3. On a real Mac, verify input-source enumeration and selection plus Launch at Login and its user-consent flow while sandboxed. If Text Input Source Services cannot perform the required system-wide change, stop the Store path and continue GitHub distribution.
4. Create the macOS record in App Store Connect using bundle ID `com.alexeyvax.CodeInputEN`.
5. Complete the privacy questionnaire as **Data Not Collected** only while the implementation remains entirely local. Provide the public `PRIVACY.md` URL.
6. Add screenshots, description, keywords, support URL, Utilities category, age rating, and App Review notes explaining the system-wide input-source behavior.
7. Archive with the `AppStore` configuration and choose **Distribute App → App Store Connect → Upload**.
8. Test the processed build through TestFlight before submitting it for App Review.

Do not publish a GitHub Release or submit an App Store version without explicit owner confirmation.
