#if canImport(UIKit)
    import UIKit
#endif

public protocol AppIconSwitching: Sendable {
    @MainActor var supportsAlternateIcons: Bool { get }
    @MainActor var current: String? { get }
    @MainActor func set(_ name: String?) async throws
}

public struct SystemAppIcon: AppIconSwitching {
    public init() {}

    @MainActor public var supportsAlternateIcons: Bool {
        #if os(iOS)
            UIApplication.shared.supportsAlternateIcons
        #else
            false
        #endif
    }

    @MainActor public var current: String? {
        #if os(iOS)
            UIApplication.shared.alternateIconName
        #else
            nil
        #endif
    }

    @MainActor public func set(_ name: String?) async throws {
        #if os(iOS)
            try await UIApplication.shared.setAlternateIconName(name)
        #endif
    }
}
