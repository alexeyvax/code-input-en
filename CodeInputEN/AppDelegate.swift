import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let settings = Settings()
    private let inputSources = InputSourceController()
    private let applicationMonitor = ApplicationMonitor()
    private lazy var focusRule = FocusRuleController(settings: settings, inputSources: inputSources)

    private var statusItem: NSStatusItem?
    private let menu = NSMenu()
    private var ruleWarningMessage: String?
    private var launchAtLoginWarningMessage: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else {
            return
        }

        chooseInitialInputSourceIfNeeded()
        configureRuleCallbacks()
        configureStatusItem()

        applicationMonitor.start { [weak self] bundleIdentifier in
            self?.focusRule.applicationDidActivate(bundleIdentifier: bundleIdentifier)
        }
        focusRule.applicationDidActivate(
            bundleIdentifier: applicationMonitor.frontmostApplicationBundleIdentifier
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        applicationMonitor.stop()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func configureStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let image = NSImage(named: NSImage.Name("MenuBarIcon")) ?? NSImage(
            systemSymbolName: "keyboard",
            accessibilityDescription: "Code Input EN"
        )
        image?.size = NSSize(width: 22, height: 12.5)
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.toolTip = "Code Input EN"
        menu.delegate = self
        statusItem.menu = menu
        self.statusItem = statusItem
        rebuildMenu()
    }

    private func configureRuleCallbacks() {
        focusRule.onError = { [weak self] error in
            self?.ruleWarningMessage = error.localizedDescription
        }
        focusRule.onSuccess = { [weak self] in
            self?.ruleWarningMessage = nil
        }
    }

    private func chooseInitialInputSourceIfNeeded() {
        guard settings.selectedInputSourceID == nil else { return }
        if let defaultID = InputSourceController.preferredDefaultSourceID(
            from: inputSources.selectableInputSources
        ) {
            settings.selectedInputSourceID = defaultID
        }
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        let titleItem = NSMenuItem(title: "Code Input EN", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(.separator())

        let enabledItem = menuItem(title: "Enabled", action: #selector(toggleEnabled))
        enabledItem.state = settings.isEnabled ? .on : .off
        menu.addItem(enabledItem)

        let layoutItem = NSMenuItem(title: "English Layout", action: nil, keyEquivalent: "")
        layoutItem.submenu = makeLayoutMenu()
        menu.addItem(layoutItem)

        let launchItem = menuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin))
        switch SMAppService.mainApp.status {
        case .enabled:
            launchItem.state = .on
        case .requiresApproval:
            launchItem.state = .mixed
        default:
            launchItem.state = .off
        }
        menu.addItem(launchItem)

        if let warning = currentWarning() {
            let warningItem = NSMenuItem(title: "⚠ \(warning)", action: nil, keyEquivalent: "")
            warningItem.isEnabled = false
            menu.addItem(warningItem)
        }

        menu.addItem(.separator())
        menu.addItem(menuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
    }

    private func makeLayoutMenu() -> NSMenu {
        let submenu = NSMenu(title: "English Layout")
        let sources = inputSources.selectableInputSources

        if sources.isEmpty {
            let item = NSMenuItem(
                title: "No ASCII-capable input sources",
                action: nil,
                keyEquivalent: ""
            )
            item.isEnabled = false
            submenu.addItem(item)
            return submenu
        }

        for source in sources {
            let item = menuItem(title: source.name, action: #selector(selectInputSource))
            item.representedObject = source.id
            item.state = source.id == settings.selectedInputSourceID ? .on : .off
            submenu.addItem(item)
        }
        return submenu
    }

    private func currentWarning() -> String? {
        let sources = inputSources.selectableInputSources
        guard !sources.isEmpty else { return "No ASCII-capable input source is installed." }

        if let selectedID = settings.selectedInputSourceID,
           !sources.contains(where: { $0.id == selectedID }) {
            return "The selected layout is unavailable. Choose another layout."
        }
        if settings.selectedInputSourceID == nil {
            return "Choose an English layout."
        }
        if SMAppService.mainApp.status == .requiresApproval {
            return "Allow Launch at Login in System Settings."
        }
        return launchAtLoginWarningMessage ?? ruleWarningMessage
    }

    private func menuItem(
        title: String,
        action: Selector,
        keyEquivalent: String = ""
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    @objc private func toggleEnabled() {
        settings.isEnabled.toggle()
        ruleWarningMessage = nil
        rebuildMenu()
    }

    @objc private func selectInputSource(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        settings.selectedInputSourceID = id
        ruleWarningMessage = nil

        if FocusRuleController.supports(
            bundleIdentifier: applicationMonitor.frontmostApplicationBundleIdentifier
        ) {
            focusRule.applicationDidActivate(
                bundleIdentifier: applicationMonitor.frontmostApplicationBundleIdentifier
            )
        }
        rebuildMenu()
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        let shouldEnable = service.status != .enabled

        do {
            if shouldEnable {
                try service.register()
            } else {
                try service.unregister()
            }
            settings.launchAtLogin = shouldEnable
            launchAtLoginWarningMessage = nil
        } catch {
            settings.launchAtLogin = service.status == .enabled
            launchAtLoginWarningMessage = "Launch at Login: \(error.localizedDescription)"
        }
        rebuildMenu()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
