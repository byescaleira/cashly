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
            await runDeveloperSharing(coordinator, library: library)
        #endif
    }

    #if DEBUG
        private func runDeveloperSharing(_ coordinator: SharingCoordinator, library: CashlyLibrary)
            async
        {
            let defaults = UserDefaults.standard
            if defaults.bool(forKey: "cashly.developer.logUserID") {
                let name = await coordinator.developerUserRecordName() ?? "none"
                CashlyMetrics.logger.info("Sharing test user \(name, privacy: .public)")
            }
            if let mode = defaults.string(forKey: "cashly.developer.openShare") {
                let users = (try? await library.repositories(for: nil).users.users()) ?? []
                for user in users where user.isShared {
                    guard await coordinator.isOwner(of: user.id) else { continue }
                    do {
                        let url = try await coordinator.developerOpenShare(
                            profileID: user.id, isOpen: mode == "open")
                        writeDeveloperLog("share \(mode) " + (url?.absoluteString ?? "none"))
                    } catch {
                        writeDeveloperLog("share failed " + String(describing: error))
                    }
                    break
                }
            }
            if defaults.bool(forKey: "cashly.developer.inspectZones") {
                for line in await coordinator.developerInspect() { writeDeveloperLog(line) }
            }
            if defaults.bool(forKey: "cashly.developer.seedShared") {
                await seedDeveloperProfile(coordinator, library: library)
            }
            if let value = defaults.string(forKey: "cashly.developer.acceptURL"),
                let url = URL(string: value)
            {
                do {
                    let profileID = try await coordinator.developerAccept(url: url)
                    sharing.joined = SharingModel.JoinedProfile(id: profileID, title: "")
                    CashlyMetrics.logger.info(
                        "Sharing test accepted \(profileID, privacy: .public)")
                } catch {
                    CashlyMetrics.failure("developerAccept", error: error)
                }
            }
        }

        private func seedDeveloperProfile(_ coordinator: SharingCoordinator, library: CashlyLibrary)
            async
        {
            let users = (try? await library.repositories(for: nil).users.users()) ?? []
            for user in users where user.isShared {
                guard await coordinator.isOwner(of: user.id) else { continue }
                let scoped = library.repositories(for: user.id)
                do {
                    let catalog = try await scoped.dashboard.snapshot(month: nil)
                    let category =
                        catalog.categories.first
                        ?? Category(
                            id: UUID().uuidString, user: user, name: "Casa", color: "C2602A",
                            icon: "house")
                    if catalog.categories.isEmpty { try await scoped.categories.save(category) }
                    let tag = Tag(
                        id: UUID().uuidString, user: user, name: "Teste", color: "466A93",
                        icon: "tag")
                    try await scoped.tags.save(tag)
                    try await scoped.budgets.save(
                        Budget(
                            id: UUID().uuidString, money: Money(minorUnits: 50_000),
                            category: category, month: YearMonth(.now),
                            summary: "Teste social"))
                    try await scoped.transactions.save(
                        Transaction(
                            id: UUID().uuidString, participants: [], category: category,
                            money: Money(minorUnits: 4_210), date: .now, summary: "Teste social",
                            status: .settled, splitMode: nil, splitValue: nil, paymentsPlan: nil,
                            tagIDs: [tag.id]))
                    writeDeveloperLog("seed ok")
                } catch {
                    writeDeveloperLog("seed failed " + String(describing: error))
                }
                break
            }
        }

        private func writeDeveloperLog(_ line: String) {
            let url = URL.documentsDirectory.appending(path: "cashly-developer.log")
            let text = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            try? (text + line + "\n").write(to: url, atomically: true, encoding: .utf8)
        }

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
        guard FeatureFlags().isOn(.pro) else { return true }
        if let simulated = StoreOverride.entitlement() { return simulated.isActive }
        let plans = Set(ShopCatalog.plans.map(\.id))
        return await StoreKitClient().currentEntitlements().contains { transaction in
            plans.contains(transaction.productID) && transaction.revocationDate == nil
                && (transaction.expirationDate ?? .distantFuture) > .now
        }
    }

    public func workspace(
        userID: String? = nil, cloudSync: Bool = CashlyServices.launchCloudSync,
        preference: UserPreference = .standard
    ) async throws -> (Repositories, User) {
        let library = try await library(cloudSync: cloudSync)
        let users = try await library.repositories(for: nil).users.users()
        let selected = users.first { $0.id == (userID ?? preference.selectedUserID) }
        guard let user = selected ?? (userID == nil ? users.first : nil)
        else { throw CashlyError.missingRecord }
        return (library.repositories(for: user.id), user)
    }
}
