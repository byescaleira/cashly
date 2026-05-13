//
//  UIKitAppIconService.swift
//  CashlyKit
//
//  iOS / visionOS implementation of `AppIconUseCase`. macOS falls
//  back to a no-op service via the factory.
//

#if canImport(UIKit)
import UIKit
import CashlyDomain

public actor UIKitAppIconService: AppIconUseCase {
    public init() {}

    public func currentIcon() async -> AppIcon {
        let name = await MainActor.run { UIApplication.shared.alternateIconName }
        switch name {
        case "AppIconPro": return .pro
        case nil: return .primary
        default: return .primary
        }
    }

    @discardableResult
    public func setIcon(_ icon: AppIcon) async -> Bool {
        let alternateName: String? = icon == .pro ? "AppIconPro" : nil
        return await MainActor.run {
            guard UIApplication.shared.supportsAlternateIcons else { return false }
            UIApplication.shared.setAlternateIconName(alternateName) { _ in }
            return true
        }
    }
}
#endif
