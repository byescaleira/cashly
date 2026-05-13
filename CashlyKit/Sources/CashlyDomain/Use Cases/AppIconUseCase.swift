//
//  AppIconUseCase.swift
//  CashlyKit
//
//  Abstracts the platform-specific alternate-app-icon API
//  (`UIApplication.setAlternateIconName`). Pro tier unlocks a
//  premium variant; gating logic + UI lives elsewhere. This
//  contract just lets UI ask "is this icon active?" and "switch
//  to this one."
//

import Foundation

public enum AppIcon: String, Sendable, CaseIterable, Equatable {
    /// The shipped default — always available to every tier.
    case primary
    /// Pro-only variant. Designer ships PNG assets under
    /// `AppIconPro.appiconset` + Info.plist alternate entry.
    case pro
}

public protocol AppIconUseCase: Sendable {
    /// Active icon — `.primary` when no alternate is set, else the
    /// matching `AppIcon` for the system's reported name.
    func currentIcon() async -> AppIcon

    /// Apply the icon. Returns true on success; false when the
    /// platform rejects the change (alternate not registered,
    /// unsupported OS, etc.).
    @discardableResult
    func setIcon(_ icon: AppIcon) async -> Bool
}
