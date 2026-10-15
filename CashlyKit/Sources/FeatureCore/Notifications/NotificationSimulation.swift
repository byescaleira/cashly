#if DEBUG
    import CashlyDomain
    import Foundation
    import Observation

    @MainActor @Observable
    public final class NotificationSimulation {
        public static let sampleMoney = Money(minorUnits: 3290)
        public static let sampleMerchant = "iFood"

        public private(set) var status: NotificationStatus = .notDetermined
        public private(set) var user: User?
        public private(set) var bill: PaymentDue?
        public private(set) var snapshot: WidgetSnapshot?
        public private(set) var scheduled: SimulatedNotification?
        public var error: CashlyError?
        @ObservationIgnored private var repositories: Repositories?
        @ObservationIgnored private let scheduler: any NotificationScheduling
        @ObservationIgnored private let suiteName: String
        @ObservationIgnored private let delay: TimeInterval
        @ObservationIgnored private let now: @Sendable () -> Date

        public init(
            scheduler: any NotificationScheduling = SystemNotifications(),
            suiteName: String = "cashly.developer.notifications", delay: TimeInterval = 5,
            now: @escaping @Sendable () -> Date = { .now }
        ) {
            self.scheduler = scheduler
            self.suiteName = suiteName
            self.delay = delay
            self.now = now
        }

        public var budget: WidgetSnapshot.BudgetLine? {
            snapshot?.budgets.first { $0.plannedMinorUnits > 0 }
        }

        public var settingsURL: URL? { NotificationsModel(scheduler: scheduler).systemSettingsURL }

        public var footer: String {
            if status == .denied {
                return String(
                    appLocalized: "Cashly notifications are turned off in system settings.")
            }
            if let scheduled {
                return String(
                    appLocalized:
                        "\(scheduled.title) arrives in five seconds. Lock the device to see it.")
            }
            return String(
                appLocalized:
                    "Each one arrives five seconds after you tap, with the real actions. Lock the device to see it on the Lock Screen."
            )
        }

        public func canSimulate(_ kind: SimulatedNotification) -> Bool {
            guard status == .allowed else { return false }
            return switch kind {
            case .bill: bill != nil
            case .budgetWarning, .budgetOver: budget != nil
            case .weekly: snapshot != nil
            case .planning: true
            case .capture: user != nil
            }
        }

        public func detail(of kind: SimulatedNotification) -> String {
            let noBudget = String(appLocalized: "No budgets this month.")
            let noProfile = String(appLocalized: "Choose a profile first.")
            return switch kind {
            case .bill:
                bill.map { "\($0.transaction.summary) · \($0.money.formatted)" }
                    ?? String(appLocalized: "No pending bills in this profile.")
            case .budgetWarning:
                budget.map { String(appLocalized: "\($0.categoryName) at 80% of the budget") }
                    ?? noBudget
            case .budgetOver:
                budget.map { String(appLocalized: "\($0.categoryName) is over budget") } ?? noBudget
            case .weekly:
                snapshot.map {
                    String(
                        appLocalized:
                            "\(Money(minorUnits: $0.spentMinorUnits).formatted) spent this month. See what changed this week."
                    )
                } ?? noProfile
            case .planning:
                String(appLocalized: "Start the month by reviewing your budgets in Cashly.")
            case .capture:
                user == nil
                    ? noProfile
                    : String(
                        appLocalized: "\(Self.sampleMoney.formatted) at \(Self.sampleMerchant)")
            }
        }

        public func load(user: User?, repositories: Repositories?) async {
            status = await scheduler.status()
            self.user = user
            self.repositories = repositories
            guard let user, let repositories else {
                bill = nil
                snapshot = nil
                return
            }
            let month = YearMonth(now())
            snapshot =
                (try? await repositories.dashboard.overview(query: TransactionQuery(month: month)))
                .map {
                    WidgetSnapshot(
                        user: user, month: month, overview: $0, currencyCode: Money.currencyCode)
                }
            let pending =
                (try? await repositories.dashboard.page(
                    query: TransactionQuery(statuses: PaymentSchedule.pendingStatuses), after: nil,
                    limit: 200
                ).items) ?? []
            bill =
                PaymentSchedule.upcoming(pending, after: now()).first
                ?? PaymentSchedule.upcoming(pending, after: .distantPast).first
        }

        public func requestPermission() async {
            _ = await scheduler.requestAuthorization()
            status = await scheduler.status()
        }

        public func simulate(_ kind: SimulatedNotification) async {
            guard canSimulate(kind) else { return }
            let delayed = DelayedNotifications(base: scheduler, delay: delay, now: now)
            do {
                switch kind {
                case .bill:
                    if let bill, let user { await delayed.deliver(bill.reminder(userID: user.id)) }
                case .budgetWarning: await alertBudget(percent: 80, through: delayed)
                case .budgetOver: await alertBudget(percent: 110, through: delayed)
                case .weekly:
                    guard let snapshot, let model = scratch(delayed) else { return }
                    await model.setWeekly(true)
                    await model.review(snapshot, now: now())
                case .planning: await scratch(delayed)?.setPlanning(true)
                case .capture: try await capture(through: delayed)
                }
            } catch {
                self.error = error as? CashlyError ?? .onSave
                return
            }
            scheduled = kind
            try? await Task.sleep(for: .seconds(delay))
            if scheduled == kind { scheduled = nil }
        }

        private func alertBudget(percent: Int64, through delayed: DelayedNotifications) async {
            guard let snapshot, let month = snapshot.yearMonth, let line = budget,
                let model = scratch(delayed)
            else { return }
            let spent = (line.plannedMinorUnits * percent + 99) / 100
            await model.setBudgets(true)
            await model.review(
                WidgetSnapshot(
                    userID: snapshot.userID, userName: snapshot.userName, month: month,
                    currencyCode: snapshot.currencyCode, plannedMinorUnits: line.plannedMinorUnits,
                    spentMinorUnits: spent, incomeMinorUnits: snapshot.incomeMinorUnits,
                    budgets: [
                        WidgetSnapshot.BudgetLine(
                            id: line.id, categoryName: line.categoryName, color: line.color,
                            icon: line.icon, plannedMinorUnits: line.plannedMinorUnits,
                            spentMinorUnits: spent)
                    ]), now: now())
        }

        private func capture(through delayed: DelayedNotifications) async throws {
            guard let user, let repositories else { return }
            let actions = CaptureActions(repositories: repositories, user: user, now: now)
            let capture = try await actions.capture(
                amount: Self.sampleMoney.doubleValue, merchant: Self.sampleMerchant
            ).capture
            let categories = try await actions.categories()
            let notifier = CaptureNotifier(scheduler: delayed)
            await notifier.register(
                categories: categories, frequent: try await actions.frequentCategories())
            await notifier.notify(capture, categories: categories)
            await notifier.updateBadge(pending: try await actions.pending().count)
        }

        private func scratch(_ delayed: DelayedNotifications) -> NotificationsModel? {
            guard let defaults = UserDefaults(suiteName: suiteName) else { return nil }
            defaults.removePersistentDomain(forName: suiteName)
            return NotificationsModel(defaults: defaults, scheduler: delayed)
        }
    }
#endif
