@testable import CodeInputEN

final class TestSettings: FocusRuleSettings {
    var isEnabled = true
    var selectedInputSourceID: String? = "english"
}

enum TestInputSourceError: Error {
    case missing
}

final class TestInputSourceController: InputSourceSelecting {
    var currentInputSourceID: String?
    var selectionError: Error?
    private(set) var selectedIDs: [String] = []

    func selectInputSource(withID id: String) throws {
        selectedIDs.append(id)
        if let selectionError {
            throw selectionError
        }
        currentInputSourceID = id
    }
}
