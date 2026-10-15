import CoreGraphics

public enum WidgetSize: String, CaseIterable, Identifiable, Sendable {
    case small, medium, large, circular, rectangular, inline

    public var id: String { rawValue }

    public var isAccessory: Bool {
        switch self {
        case .circular, .rectangular, .inline: true
        case .small, .medium, .large: false
        }
    }

    public var canvas: CGSize {
        switch self {
        case .small: CGSize(width: 158, height: 158)
        case .medium: CGSize(width: 338, height: 158)
        case .large: CGSize(width: 338, height: 354)
        case .circular: CGSize(width: 72, height: 72)
        case .rectangular: CGSize(width: 160, height: 72)
        case .inline: CGSize(width: 220, height: 24)
        }
    }

    public static var supported: [WidgetSize] {
        #if os(iOS)
            allCases
        #else
            allCases.filter { !$0.isAccessory }
        #endif
    }
}
