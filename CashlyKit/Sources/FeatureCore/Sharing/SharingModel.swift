import CashlyDomain
import CloudKit
import Foundation
import Observation

@MainActor @Observable
public final class SharingModel {
    public private(set) var isAvailable = false
    public private(set) var hasCheckedAccount = false
    public private(set) var details: SharedProfileDetails?
    public private(set) var status = SharingSyncStatus()
    public private(set) var isWorking = false
    public private(set) var isLoading = false
    public private(set) var hasFailedLoading = false
    public var inviting: User?
    public var joined: JoinedProfile?
    public var confirmation: SharingConfirmation?
    public var error: CashlyError?
    public var loadError: CashlyError?
    public var acceptError: CashlyError?
    public var presenterID: UUID?
    public private(set) var isEnabled = false
    @ObservationIgnored private var shares: [String: CKShare] = [:]
    @ObservationIgnored private var pending: [CKShare.Metadata] = []
    @ObservationIgnored private var isUnavailable = false
    @ObservationIgnored private(set) var service: (any ProfileSharing)?

    public struct JoinedProfile: Identifiable, Hashable, Sendable {
        public let id: String
        public let title: String

        public init(id: String, title: String) {
            self.id = id
            self.title = title
        }
    }

    public init(service: (any ProfileSharing)? = nil) {
        self.service = service
        isEnabled = service != nil
    }

    public var canCreate: Bool { isEnabled && isAvailable }

    public func attach(_ service: any ProfileSharing) async {
        self.service = service
        isUnavailable = false
        isEnabled = true
        await checkAccount()
        let queued = pending
        pending = []
        for metadata in queued { await accept(metadata) }
    }

    public func checkAccount() async {
        guard let service else { return }
        isAvailable = await service.accountAvailable()
        hasCheckedAccount = true
    }

    public func load(profileID: String) async {
        guard let service else { return }
        if details?.profileID != profileID { details = nil }
        isLoading = true
        defer { isLoading = false }
        do {
            let value = try await service.details(profileID: profileID)
            try Task.checkCancellation()
            details = value
            hasFailedLoading = false
            status = await service.status()
        } catch is CancellationError {} catch {
            hasFailedLoading = true
            loadError = .persistence(Self.message(for: error))
        }
    }

    public func refresh(profileID: String) async {
        await service?.refresh()
        await load(profileID: profileID)
    }

    public func create(_ user: User, copying categories: [CashlyDomain.Category]) async throws {
        guard let service else { throw CashlyError.onSave }
        try await service.createProfile(user, copying: categories)
        var shared = user
        shared.isShared = true
        inviting = shared
    }

    public func invite(for user: User) -> SharedProfileInvite? {
        guard let service else { return nil }
        return SharedProfileInvite(
            profileID: user.id, title: user.name, service: service, existing: shares[user.id])
    }

    public func prepareInvite(for user: User) async {
        guard let service, shares[user.id] == nil else { return }
        shares[user.id] = try? await service.share(profileID: user.id, title: user.name)
    }

    public func confirm() async {
        guard let service, let confirmation else { return }
        isWorking = true
        defer { isWorking = false }
        let profileID = confirmation.profile.id
        do {
            switch confirmation {
            case .leave:
                try await service.leave(profileID: profileID)
                shares[profileID] = nil
                details = nil
            case .deleteForEveryone:
                try await service.deleteForEveryone(profileID: profileID)
                shares[profileID] = nil
                details = nil
            case .stopSharing:
                try await service.stopSharing(profileID: profileID)
                shares[profileID] = nil
                await load(profileID: profileID)
            case .removeMember(let member, _):
                try await service.removeMember(member.id, profileID: profileID)
                shares[profileID] = nil
                await load(profileID: profileID)
            }
            self.confirmation = nil
        } catch {
            self.error = .persistence(Self.message(for: error))
        }
    }

    public func accept(_ metadata: CKShare.Metadata) async {
        guard let service else {
            if isUnavailable {
                acceptError = Self.unavailableError
            } else {
                pending.append(metadata)
            }
            return
        }
        let title = metadata.share[CKShare.SystemFieldKey.title] as? String ?? ""
        do {
            let profileID = try await service.accept(metadata)
            joined = JoinedProfile(id: profileID, title: title)
        } catch {
            acceptError = .persistence(Self.message(for: error))
        }
    }

    public func markUnavailable() {
        isUnavailable = true
        guard !pending.isEmpty else { return }
        pending = []
        acceptError = Self.unavailableError
    }

    static var unavailableError: CashlyError {
        .invalidInput(
            String(
                appLocalized:
                    "Shared profiles aren't available on this device yet. Update Cashly and open the invitation again."
            ))
    }

    public func claimPresentation(_ id: UUID) {
        presenterID = id
    }

    public func claimIfUnclaimed(_ id: UUID) {
        if presenterID == nil { presenterID = id }
    }

    public func releasePresentation(_ id: UUID) {
        if presenterID == id { presenterID = nil }
    }

    public func open(_ joined: JoinedProfile, in session: SessionModel) async {
        await session.refreshUsers()
        await session.selectUser(id: joined.id)
        self.joined = nil
    }

    static func message(for error: any Error) -> String {
        if let error = error as? CashlyError, let description = error.errorDescription {
            return description
        }
        guard let error = error as? CKError else {
            return String(appLocalized: "Couldn't reach iCloud. Try again in a moment.")
        }
        switch error.code {
        case .notAuthenticated, .accountTemporarilyUnavailable:
            return String(appLocalized: "Sign in to iCloud in the Settings app to share profiles.")
        case .networkFailure, .networkUnavailable, .serviceUnavailable, .requestRateLimited:
            return String(appLocalized: "Couldn't reach iCloud. Try again in a moment.")
        case .quotaExceeded:
            return String(
                appLocalized: "The iCloud storage of whoever created this profile is full.")
        default:
            return String(appLocalized: "iCloud couldn't complete this. Try again in a moment.")
        }
    }
}
