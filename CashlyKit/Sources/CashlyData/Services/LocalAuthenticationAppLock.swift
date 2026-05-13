//
//  LocalAuthenticationAppLock.swift
//  CashlyKit
//
//  LocalAuthentication-backed AppLockUseCase. Persists the user
//  toggle in UserDefaults (`cashly.appLock.enabled`) and prompts via
//  LAContext when authenticate(reason:) is called.
//

import Foundation
import CashlyDomain
#if canImport(LocalAuthentication)
import LocalAuthentication
#endif

public actor LocalAuthenticationAppLock: AppLockUseCase {
    public static let userDefaultsKey = "cashly.appLock.enabled"

    private let suite: UserDefaults

    public init(suite: UserDefaults = .standard) {
        self.suite = suite
    }

    public func isEnabled() async -> Bool {
        suite.bool(forKey: Self.userDefaultsKey)
    }

    public func setEnabled(_ enabled: Bool) async {
        suite.set(enabled, forKey: Self.userDefaultsKey)
    }

    public func authenticate(reason: String) async -> AppLockOutcome {
        #if canImport(LocalAuthentication)
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return .unavailable
        }
        return await withCheckedContinuation { cont in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { ok, err in
                if ok {
                    cont.resume(returning: .unlocked)
                } else {
                    cont.resume(returning: .failed(reason: err?.localizedDescription ?? "cancelled"))
                }
            }
        }
        #else
        return .unavailable
        #endif
    }
}
