import Foundation

public enum ProfilePhoto: Hashable, Sendable {
    case initials(color: String)
    case symbol(String, color: String)
    case illustration(String)

    public static let defaultColor = "C2602A"
    public static let `default` = ProfilePhoto.initials(color: defaultColor)

    public init(encoded: String) {
        let parts = encoded.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false)
            .map(String.init)
        let photo: ProfilePhoto? =
            switch (parts.first, parts.count) {
            case ("initials", 2): .initials(color: parts[1])
            case ("symbol", 3): .symbol(parts[2], color: parts[1])
            case ("illustration", 2): .illustration(parts[1])
            default: nil
            }
        self = photo.flatMap { $0.isValid ? $0 : nil } ?? .default
    }

    public var encoded: String {
        switch self {
        case .initials(let color): "initials:\(color)"
        case .symbol(let name, let color): "symbol:\(color):\(name)"
        case .illustration(let id): "illustration:\(id)"
        }
    }

    public var color: String? {
        switch self {
        case .initials(let color), .symbol(_, let color): color
        case .illustration: nil
        }
    }

    public var isValid: Bool {
        switch self {
        case .initials(let color): Self.isColor(color)
        case .symbol(let name, let color): Self.isColor(color) && Self.isSymbolName(name)
        case .illustration(let id): Self.isIllustrationID(id)
        }
    }

    public func recolored(_ color: String) -> ProfilePhoto {
        switch self {
        case .initials: .initials(color: color)
        case .symbol(let name, _): .symbol(name, color: color)
        case .illustration: self
        }
    }

    private static func isColor(_ value: String) -> Bool {
        value.count == 6 && value.allSatisfy(\.isHexDigit)
    }

    private static func isSymbolName(_ value: String) -> Bool {
        !value.isEmpty && value.count <= 64
            && value.allSatisfy { $0 == "." || ($0.isASCII && ($0.isLowercase || $0.isNumber)) }
    }

    private static func isIllustrationID(_ value: String) -> Bool {
        let parts = value.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 2, let section = parts.first, let number = parts.last else {
            return false
        }
        return !section.isEmpty && section.allSatisfy { $0.isASCII && $0.isLowercase }
            && number.count == 2 && number.allSatisfy { $0.isASCII && $0.isNumber }
    }
}
