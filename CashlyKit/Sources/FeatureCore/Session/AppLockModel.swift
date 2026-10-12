import Foundation
import LocalAuthentication
import Observation

public enum BiometryKind: Sendable {
    case none, touchID, faceID, opticID

    public var title: String {
        switch self {
        case .none: String(appLocalized: "Passcode")
        case .touchID: "Touch ID"
        case .faceID: "Face ID"
        case .opticID: "Optic ID"
        }
    }
}

public protocol Authenticating: Sendable {
    func biometry() -> BiometryKind
    func authenticate(reason: String) async -> Bool
}

public struct DeviceAuthentication: Authenticating {
    public init() {}

    public func biometry() -> BiometryKind {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else {
            return .none
        }
        switch context.biometryType {
        case .touchID: return .touchID
        case .faceID: return .faceID
        case .opticID: return .opticID
        default: return .none
        }
    }

    public func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else {
            return true
        }
        return
            (try? await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason))
            ?? false
    }
}

@MainActor @Observable
public final class AppLockModel {
    public private(set) var isLocked: Bool
    public private(set) var isAuthenticating = false
    public let biometry: BiometryKind
    @ObservationIgnored private let authenticator: any Authenticating

    public init(isEnabled: Bool, authenticator: any Authenticating = DeviceAuthentication()) {
        self.authenticator = authenticator
        biometry = authenticator.biometry()
        isLocked = isEnabled
    }

    public func lock() {
        isLocked = true
    }

    public func unlock() async {
        guard isLocked, !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }
        if await authenticator.authenticate(reason: String(appLocalized: "Unlock Cashly")) {
            isLocked = false
        }
    }
}
