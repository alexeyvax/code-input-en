import Carbon.HIToolbox
import Foundation

protocol InputSourceSelecting: AnyObject {
    var currentInputSourceID: String? { get }
    func selectInputSource(withID id: String) throws
}

enum InputSourceControllerError: LocalizedError {
    case sourceMissing(String)
    case selectionFailed(String, OSStatus)

    var errorDescription: String? {
        switch self {
        case let .sourceMissing(id):
            return "The selected input source is unavailable (\(id))."
        case let .selectionFailed(id, status):
            return "Could not select input source \(id) (error \(status))."
        }
    }
}

final class InputSourceController: InputSourceSelecting {
    var selectableInputSources: [InputSource] {
        sourceRecords()
            .filter { $0.isSelectCapable && $0.isASCIICapable }
            .map(\.model)
    }

    var currentInputSourceID: String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return nil
        }
        return stringProperty(kTISPropertyInputSourceID, of: source)
    }

    func selectInputSource(withID id: String) throws {
        guard currentInputSourceID != id else { return }
        guard let source = sourceRecords().first(where: {
            $0.model.id == id && $0.isSelectCapable && $0.isASCIICapable
        })?.source else {
            throw InputSourceControllerError.sourceMissing(id)
        }

        let status = TISSelectInputSource(source)
        guard status == noErr else {
            throw InputSourceControllerError.selectionFailed(id, status)
        }
    }

    static func preferredDefaultSourceID(
        from sources: [InputSource],
        locale: Locale = .current
    ) -> String? {
        let regionalIDs = preferredSourceIDsByRegion[locale.region?.identifier ?? ""] ?? []
        let preferredIDs = regionalIDs + [
            "com.apple.keylayout.ABC",
            "com.apple.keylayout.US"
        ]
        for preferredID in preferredIDs where sources.contains(where: { $0.id == preferredID }) {
            return preferredID
        }
        return sources.first?.id
    }

    private static let preferredSourceIDsByRegion: [String: [String]] = [
        "US": [
            "com.apple.keylayout.US",
            "com.apple.keylayout.USInternational-PC"
        ],
        "GB": [
            "com.apple.keylayout.British",
            "com.apple.keylayout.British-PC"
        ],
        "AU": ["com.apple.keylayout.Australian"],
        "CA": ["com.apple.keylayout.Canadian"],
        "IE": ["com.apple.keylayout.Irish"],
        "NZ": ["com.apple.keylayout.NewZealand"],
        "IN": ["com.apple.keylayout.ABC-India"]
    ]

    private struct SourceRecord {
        let source: TISInputSource
        let model: InputSource
        let isSelectCapable: Bool
        let isASCIICapable: Bool
    }

    private func sourceRecords() -> [SourceRecord] {
        guard let sourceList = TISCreateInputSourceList(nil, false)?.takeRetainedValue() else {
            return []
        }

        return (sourceList as NSArray).compactMap { value in
            let cfValue = value as CFTypeRef
            guard CFGetTypeID(cfValue) == TISInputSourceGetTypeID() else { return nil }
            let source = unsafeBitCast(cfValue, to: TISInputSource.self)

            guard stringProperty(kTISPropertyInputSourceCategory, of: source)
                    == (kTISCategoryKeyboardInputSource as String),
                  let id = stringProperty(kTISPropertyInputSourceID, of: source),
                  let name = stringProperty(kTISPropertyLocalizedName, of: source)
            else {
                return nil
            }

            return SourceRecord(
                source: source,
                model: InputSource(id: id, name: name),
                isSelectCapable: boolProperty(kTISPropertyInputSourceIsSelectCapable, of: source) ?? false,
                isASCIICapable: boolProperty(kTISPropertyInputSourceIsASCIICapable, of: source) ?? false
            )
        }
    }

    private func stringProperty(_ key: CFString, of source: TISInputSource) -> String? {
        property(key, of: source) as? String
    }

    private func boolProperty(_ key: CFString, of source: TISInputSource) -> Bool? {
        property(key, of: source) as? Bool
    }

    private func property(_ key: CFString, of source: TISInputSource) -> AnyObject? {
        guard let pointer = TISGetInputSourceProperty(source, key) else { return nil }
        return Unmanaged<AnyObject>.fromOpaque(pointer).takeUnretainedValue()
    }
}
