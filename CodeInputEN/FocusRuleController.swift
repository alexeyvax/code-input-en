import Foundation

final class FocusRuleController {
    static let terminalBundleIdentifier = "com.apple.Terminal"
    static let visualStudioCodeBundleIdentifier = "com.microsoft.VSCode"
    static let xcodeBundleIdentifier = "com.apple.dt.Xcode"
    static let supportedBundleIdentifiers: Set<String> = [
        terminalBundleIdentifier,
        visualStudioCodeBundleIdentifier,
        xcodeBundleIdentifier
    ]

    static func supports(bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier else { return false }
        return supportedBundleIdentifiers.contains(bundleIdentifier)
    }

    private let settings: FocusRuleSettings
    private let inputSources: InputSourceSelecting
    var onError: ((Error) -> Void)?
    var onSuccess: (() -> Void)?

    init(settings: FocusRuleSettings, inputSources: InputSourceSelecting) {
        self.settings = settings
        self.inputSources = inputSources
    }

    func applicationDidActivate(bundleIdentifier: String?) {
        guard settings.isEnabled,
              Self.supports(bundleIdentifier: bundleIdentifier),
              let selectedID = settings.selectedInputSourceID
        else {
            return
        }

        guard inputSources.currentInputSourceID != selectedID else {
            onSuccess?()
            return
        }

        do {
            try inputSources.selectInputSource(withID: selectedID)
            onSuccess?()
        } catch {
            onError?(error)
        }
    }
}
