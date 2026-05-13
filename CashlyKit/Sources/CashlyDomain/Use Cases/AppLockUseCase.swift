//
//  AppLockUseCase.swift
//  CashlyKit
//
//  Biometric / passcode gate at app foreground. Production impl in
//  CashlyData uses LocalAuthentication; in-memory impl returns a
//  fixed outcome for tests + previews.
//

import Foundation

public enum AppLockOutcome: Sendable, Equatable {
    /// User authenticated successfully.
    case unlocked
    /// User cancelled or failed authentication.
    case failed(reason: String)
    /// Device has no biometric / passcode enrolled — caller treats
    /// as `.unlocked` since the OS can't gate anything.
    case unavailable
}

public protocol AppLockUseCase: Sendable {
    /// Whether the user has opted into the app lock in settings.
    func isEnabled() async -> Bool
    /// Persists the user preference.
    func setEnabled(_ enabled: Bool) async
    /// Prompts the user with biometric / passcode. `reason` is the
    /// localized message shown above the Face ID / Touch ID sheet.
    func authenticate(reason: String) async -> AppLockOutcome
}
