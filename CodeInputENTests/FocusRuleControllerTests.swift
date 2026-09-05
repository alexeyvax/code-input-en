import XCTest
@testable import CodeInputEN

final class FocusRuleControllerTests: XCTestCase {
    private var settings: TestSettings!
    private var inputSources: TestInputSourceController!
    private var controller: FocusRuleController!

    override func setUp() {
        super.setUp()
        settings = TestSettings()
        inputSources = TestInputSourceController()
        inputSources.currentInputSourceID = "other"
        controller = FocusRuleController(settings: settings, inputSources: inputSources)
    }

    func testTerminalActivationSelectsConfiguredSourceOnceWhenDifferent() {
        controller.applicationDidActivate(bundleIdentifier: "com.apple.Terminal")

        XCTAssertEqual(inputSources.selectedIDs, ["english"])
    }

    func testVisualStudioCodeActivationSelectsConfiguredSourceOnceWhenDifferent() {
        controller.applicationDidActivate(bundleIdentifier: "com.microsoft.VSCode")

        XCTAssertEqual(inputSources.selectedIDs, ["english"])
    }

    func testXcodeActivationSelectsConfiguredSourceOnceWhenDifferent() {
        controller.applicationDidActivate(bundleIdentifier: "com.apple.dt.Xcode")

        XCTAssertEqual(inputSources.selectedIDs, ["english"])
    }

    func testTerminalActivationDoesNotSelectWhenSourceIsAlreadyCurrent() {
        inputSources.currentInputSourceID = "english"

        controller.applicationDidActivate(bundleIdentifier: "com.apple.Terminal")

        XCTAssertTrue(inputSources.selectedIDs.isEmpty)
    }

    func testOtherApplicationDoesNotSelect() {
        controller.applicationDidActivate(bundleIdentifier: "com.apple.Safari")

        XCTAssertTrue(inputSources.selectedIDs.isEmpty)
    }

    func testDisabledRuleDoesNotSelect() {
        settings.isEnabled = false

        controller.applicationDidActivate(bundleIdentifier: "com.apple.Terminal")

        XCTAssertTrue(inputSources.selectedIDs.isEmpty)
    }

    func testMissingConfigurationDoesNotSelectOrCrash() {
        settings.selectedInputSourceID = nil

        controller.applicationDidActivate(bundleIdentifier: "com.apple.Terminal")

        XCTAssertTrue(inputSources.selectedIDs.isEmpty)
    }

    func testMissingConfiguredSourceReportsErrorWithoutCrashing() {
        inputSources.selectionError = TestInputSourceError.missing
        var reportedError: Error?
        controller.onError = { reportedError = $0 }

        controller.applicationDidActivate(bundleIdentifier: "com.apple.Terminal")

        XCTAssertEqual(inputSources.selectedIDs, ["english"])
        XCTAssertNotNil(reportedError)
    }

    func testRepeatedUnrelatedActivationsDoNotSelect() {
        for bundleIdentifier in [nil, "com.apple.Safari", "com.apple.finder", nil] {
            controller.applicationDidActivate(bundleIdentifier: bundleIdentifier)
        }

        XCTAssertTrue(inputSources.selectedIDs.isEmpty)
    }
}

final class InputSourceDefaultSelectionTests: XCTestCase {
    func testRegionalEnglishLayoutIsPreferredWhenAvailable() {
        let sources = [
            InputSource(id: "com.apple.keylayout.US", name: "U.S."),
            InputSource(id: "com.apple.keylayout.British", name: "British"),
            InputSource(id: "com.apple.keylayout.Australian", name: "Australian"),
            InputSource(id: "com.apple.keylayout.Canadian", name: "Canadian"),
            InputSource(id: "com.apple.keylayout.Irish", name: "Irish"),
            InputSource(id: "com.apple.keylayout.NewZealand", name: "New Zealand"),
            InputSource(id: "com.apple.keylayout.ABC-India", name: "ABC – India")
        ]
        let expectations = [
            ("en-US", "com.apple.keylayout.US"),
            ("en-GB", "com.apple.keylayout.British"),
            ("en-UK", "com.apple.keylayout.British"),
            ("en-AU", "com.apple.keylayout.Australian"),
            ("en-CA", "com.apple.keylayout.Canadian"),
            ("en-IE", "com.apple.keylayout.Irish"),
            ("en-NZ", "com.apple.keylayout.NewZealand"),
            ("en-IN", "com.apple.keylayout.ABC-India")
        ]

        for (localeIdentifier, expectedSourceID) in expectations {
            XCTAssertEqual(
                InputSourceController.preferredDefaultSourceID(
                    from: sources,
                    locale: Locale(identifier: localeIdentifier)
                ),
                expectedSourceID,
                "Unexpected default for \(localeIdentifier)"
            )
        }
    }

    func testABCHasHighestPriority() {
        let sources = [
            InputSource(id: "third.party", name: "Third Party"),
            InputSource(id: "com.apple.keylayout.US", name: "U.S."),
            InputSource(id: "com.apple.keylayout.ABC", name: "ABC")
        ]

        XCTAssertEqual(
            InputSourceController.preferredDefaultSourceID(
                from: sources,
                locale: Locale(identifier: "es-ES")
            ),
            "com.apple.keylayout.ABC"
        )
    }

    func testUSIsPreferredWhenABCIsUnavailable() {
        let sources = [
            InputSource(id: "third.party", name: "Third Party"),
            InputSource(id: "com.apple.keylayout.US", name: "U.S.")
        ]

        XCTAssertEqual(
            InputSourceController.preferredDefaultSourceID(
                from: sources,
                locale: Locale(identifier: "es-ES")
            ),
            "com.apple.keylayout.US"
        )
    }

    func testFirstSourceIsFallback() {
        let sources = [
            InputSource(id: "first", name: "First"),
            InputSource(id: "second", name: "Second")
        ]

        XCTAssertEqual(
            InputSourceController.preferredDefaultSourceID(
                from: sources,
                locale: Locale(identifier: "es-ES")
            ),
            "first"
        )
    }

    func testNoSourcesProducesNoDefault() {
        XCTAssertNil(
            InputSourceController.preferredDefaultSourceID(
                from: [],
                locale: Locale(identifier: "en-US")
            )
        )
    }
}

final class InputSourceControllerSystemTests: XCTestCase {
    func testSystemSourcesCanBeReadSafely() {
        let controller = InputSourceController()
        let sources = controller.selectableInputSources

        XCTAssertFalse(sources.isEmpty)
        XCTAssertTrue(sources.allSatisfy { !$0.id.isEmpty && !$0.name.isEmpty })
        XCTAssertNotNil(controller.currentInputSourceID)
    }
}
