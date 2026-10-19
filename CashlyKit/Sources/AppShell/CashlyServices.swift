import CashlyData
import CashlyDomain
import CashlyExchange
import FeatureCore
import FeatureSettings
import FeatureStore
import Foundation
import Observation

@MainActor @Observable
public final class CashlyServices {
    public static let shared = CashlyServices()
    public var pendingURL: URL?
    public let sharing = SharingModel()
    public nonisolated let exchangeRates: any ExchangeRateProviding = ExchangeRateService.shared
    @ObservationIgnored private var opening: Task<CashlyLibrary, any Error>?
    @ObservationIgnored private var coordinator: SharingCoordinator?

    private init() {}

    public func library(cloudSync: Bool) async throws -> CashlyLibrary {
        if let opening {
            do { return try await opening.value } catch { self.opening = nil }
        }
        let task = Task.detached(priority: .userInitiated) {
            let library = try CashlyLibrary.open(cloudSync: cloudSync)
            await library.prepare()
            return library
        }
        opening = task
        do {
            return try await task.value
        } catch {
            opening = nil
            throw error
        }
    }

    public func startSharing(_ library: CashlyLibrary) async {
        guard coordinator == nil else { return }
        let coordinator = SharingCoordinator(
            database: library.shared, directory: CashlyLibrary.sharingStateDirectory)
        self.coordinator = coordinator
        await coordinator.start()
        await sharing.attach(SharingService(coordinator: coordinator))
        #if DEBUG
            await createDeveloperProfile(in: library)
        #endif
    }

    #if DEBUG
        private func createDeveloperProfile(in library: CashlyLibrary) async {
            let key = "cashly.developer.sharedProfile"
            guard let name = UserDefaults.standard.string(forKey: key) else { return }
            UserDefaults.standard.removeObject(forKey: key)
            let directory = library.repositories(for: nil)
            let users = (try? await directory.users.users()) ?? []
            if let existing = users.first(where: { $0.isShared && $0.name == name }) {
                sharing.inviting = existing
                return
            }
            let source = UserPreference.standard.selectedUserID ?? users.first?.id
            let categories =
                (try? await library.repositories(for: source).dashboard.snapshot(month: nil)
                    .categories) ?? []
            let id = UUID().uuidString
            let user = User(id: id, name: name, photo: .suggested(for: id), isShared: true)
            UserPreference.standard.save(id)
            do { try await sharing.create(user, copying: categories) } catch {
                sharing.acceptError = error as? CashlyError ?? .onSave
            }
        }
    #endif

    public static var launchCloudSync: Bool {
        #if targetEnvironment(simulator)
            false
        #else
            SettingsModel.launchSyncPreference
        #endif
    }

    public func isPro() async -> Bool {
        await ProRule.isPro(isEnforced: FeatureFlags().isOn(.pro))
    }

    public func workspace(
        userID: String? = nil, cloudSync: Bool = CashlyServices.launchCloudSync,
        preference: UserPreference = .standard
    ) async throws -> (Repositories, User) {
        if AppReleaseStore.shared.blocks { throw UpdateRequiredError() }
        let library = try await library(cloudSync: cloudSync)
        let users = try await library.repositories(for: nil).users.users()
        let selected = users.first { $0.id == (userID ?? preference.selectedUserID) }
        guard let user = selected ?? (userID == nil ? users.first : nil)
        else { throw CashlyError.missingRecord }
        return (library.repositories(for: user.id), user)
    }
}
