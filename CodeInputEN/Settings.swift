import Foundation

protocol FocusRuleSettings: AnyObject {
    var isEnabled: Bool { get }
    var selectedInputSourceID: String? { get }
}

final class Settings: FocusRuleSettings {
    private enum Key {
        static let isEnabled = "isEnabled"
        static let selectedInputSourceID = "selectedInputSourceID"
        static let launchAtLogin = "launchAtLogin"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [Key.isEnabled: true])
    }

    var isEnabled: Bool {
        get { defaults.bool(forKey: Key.isEnabled) }
        set { defaults.set(newValue, forKey: Key.isEnabled) }
    }

    var selectedInputSourceID: String? {
        get { defaults.string(forKey: Key.selectedInputSourceID) }
        set { defaults.set(newValue, forKey: Key.selectedInputSourceID) }
    }

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Key.launchAtLogin) }
        set { defaults.set(newValue, forKey: Key.launchAtLogin) }
    }
}
