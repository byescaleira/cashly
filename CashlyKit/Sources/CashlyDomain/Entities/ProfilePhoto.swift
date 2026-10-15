import Foundation

public enum ProfilePhoto: Hashable, Sendable {
    case initials(color: String)
    case symbol(String, color: String)
    case emoji(String, color: String)
    case memoji(Data)

    public static let defaultColor = "C2602A"
    public static let maximumImageBytes = 1_000_000
    public static let `default` = ProfilePhoto.initials(color: defaultColor)

    public init(encoded: String, data: Data? = nil) {
        let parts = encoded.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false)
            .map(String.init)
        let photo: ProfilePhoto? =
            switch (parts.first, parts.count) {
            case ("initials", 2): .initials(color: parts[1])
            case ("symbol", 3): .symbol(parts[2], color: parts[1])
            case ("emoji", 3): .emoji(parts[2], color: parts[1])
            case ("memoji", 1): data.map(ProfilePhoto.memoji)
            default: nil
            }
        self = photo.flatMap { $0.isValid ? $0 : nil } ?? .default
    }

    public var encoded: String {
        switch self {
        case .initials(let color): "initials:\(color)"
        case .symbol(let name, let color): "symbol:\(color):\(name)"
        case .emoji(let emoji, let color): "emoji:\(color):\(emoji)"
        case .memoji: "memoji"
        }
    }

    public var data: Data? {
        guard case .memoji(let data) = self else { return nil }
        return data
    }

    public var color: String? {
        switch self {
        case .initials(let color), .symbol(_, let color), .emoji(_, let color): color
        case .memoji: nil
        }
    }

    public var isValid: Bool {
        switch self {
        case .initials(let color):
            Self.isColor(color)
        case .symbol(let name, let color):
            Self.isColor(color) && Self.isSymbolName(name)
        case .emoji(let emoji, let color):
            Self.isColor(color) && emoji.count == 1
                && !emoji.unicodeScalars.contains {
                    $0.properties.isWhitespace || $0.properties.generalCategory == .control
                }
        case .memoji(let data):
            !data.isEmpty && data.count <= Self.maximumImageBytes
        }
    }

    public func recolored(_ color: String) -> ProfilePhoto {
        switch self {
        case .initials: .initials(color: color)
        case .symbol(let name, _): .symbol(name, color: color)
        case .emoji(let emoji, _): .emoji(emoji, color: color)
        case .memoji: self
        }
    }

    private static func isColor(_ value: String) -> Bool {
        value.count == 6 && value.allSatisfy(\.isHexDigit)
    }

    private static func isSymbolName(_ value: String) -> Bool {
        !value.isEmpty && value.count <= 64
            && value.allSatisfy { $0 == "." || ($0.isASCII && ($0.isLowercase || $0.isNumber)) }
    }
}
