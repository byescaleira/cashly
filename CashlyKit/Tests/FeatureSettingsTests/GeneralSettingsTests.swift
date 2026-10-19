import CashlyAnalytics
import CashlyDomain
import CashlyGame
import FeatureCore
import Foundation
import Testing

@testable import FeatureSettings

private actor AllowingScheduler: NotificationScheduling {
    var current: NotificationStatus

    init(status: NotificationStatus) {
        current = status
    }

    func status() -> NotificationStatus { current }

    func requestAuthorization() -> Bool {
        current = .allowed
        return true
    }

    func replace(prefix: String, with reminders: [Reminder]) {}
    func deliver(_ reminder: Reminder) {}
    func registerCaptureActions(_ groups: [CaptureActionGroup]) {}
    func setBadge(_ count: Int) {}
}

private struct SnapshotSource: GameSource {
    let events: [GameEvent]

    func snapshot(today: Date) async throws -> GameSnapshot {
        GameSnapshot(
            userID: "user",
            ledger: LedgerSnapshot(
                transactions: [], categories: [], tags: [], budgets: [], revision: "r",
                today: today),
            transactions: [], events: events, guides: ["a", "b", "c"])
    }
}

@MainActor
struct GeneralSettingsTests {
    private let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard

    private func makeSettings(status: NotificationStatus = .allowed) -> SettingsModel {
        SettingsModel(
            defaults: defaults, cloudContainer: nil, currencySetting: CurrencySetting(),
            languageSetting: LanguageSetting(),
            notifications: NotificationsModel(
                defaults: defaults, scheduler: AllowingScheduler(status: status)))
    }

    @Test func entriesFollowGroupsFlagsAndSearch() {
        let settings = makeSettings()
        let general = settings.entries(in: .general, showsGuides: true, showsJourneyEntry: true)
        #expect(general.first == .appearance)
        #expect(general.contains(.journey))
        let hidden = settings.entries(in: .general, showsGuides: true, showsJourneyEntry: false)
        #expect(!hidden.contains(.journey))
        let data = settings.entries(in: .data, showsGuides: true, showsJourneyEntry: true)
        #expect(data == [.cloud])
        let help = settings.entries(in: .help, showsGuides: false, showsJourneyEntry: true)
        #expect(help == [.about])
        let found = settings.entries(
            matching: "face id", showsGuides: true, showsJourneyEntry: true)
        #expect(found == [.privacy])
        let titled = settings.entries(matching: "CURR", showsGuides: true, showsJourneyEntry: true)
        #expect(titled == [.currency])
        let shop = settings.entries(matching: "avatars", showsGuides: true, showsJourneyEntry: true)
        #expect(shop == [.shop])
        #expect(!general.contains(.shop))
        #expect(
            settings.entries(matching: "zzz", showsGuides: true, showsJourneyEntry: true).isEmpty)
    }

    @Test func planBadgeShowsProTrialDaysAndFree() {
        let settings = makeSettings()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        #expect(settings.planBadge(for: .active(expires: .distantFuture)).tone == .pro)
        let trial = settings.planBadge(
            for: .trial(expires: now.addingTimeInterval(3 * 86_400)), now: now)
        #expect(trial.tone == .trial)
        #expect(trial.title.contains("3"))
        #expect(settings.planBadge(for: .none).tone == .free)
        #expect(settings.planBadge(for: .expired(now)).tone == .free)
        let onHold = settings.planBadge(for: .expired(now), isOnHold: true)
        #expect(onHold.tone == .onHold)
        #expect(onHold.title == "On Hold")
        #expect(settings.proOfferTitle(for: .expired(now)) != settings.proOfferTitle(for: .none))
    }

    @Test func privacyValueAndSymbolsFollowTheChoices() {
        let settings = makeSettings()
        #expect(settings.privacyValue(.faceID) == "Off")
        settings.locksApp = true
        #expect(settings.privacyValue(.faceID) == "Face ID")
        settings.isDiscreet = true
        #expect(settings.privacyValue(.faceID).contains("Face ID"))
        #expect(settings.privacyValue(.faceID).contains("Discreet"))
        settings.locksApp = false
        #expect(settings.privacyValue(.faceID) == "Discreet")
        #expect(settings.lockSymbol(.faceID) == "faceid")
        #expect(settings.lockSymbol(.none) == "lock")
        #expect(settings.privacySample.count == 2)
    }

    @Test func suggestedCurrenciesComeFromTheRegions() {
        let settings = makeSettings()
        let regions = [Locale.Region("BR"), Locale.Region("US"), Locale.Region("BR")]
        #expect(settings.suggestedCurrencies(regions: regions) == ["BRL", "USD"])
        #expect(settings.suggestedCurrencies(regions: [Locale.Region("JP")]).isEmpty)
        let others = settings.otherCurrencies(regions: regions)
        #expect(!others.contains("BRL"))
        #expect(others.count == CurrencySetting.supported.count - 2)
        #expect(settings.currencies(matching: "eur").contains("EUR"))
        #expect(settings.currencies(matching: "").count == CurrencySetting.supported.count)
    }

    @Test func currencyChangeWaitsForConfirmation() async {
        let settings = makeSettings()
        settings.choose(currency: settings.currency)
        #expect(settings.currencyChoice == nil)
        settings.choose(currency: "XYZ")
        #expect(settings.currencyChoice == nil)
        settings.choose(currency: "USD")
        #expect(settings.currencyChoice == CurrencyChoice(from: "BRL", to: "USD"))
        #expect(settings.currency == "BRL")
        settings.cancelCurrencyChoice()
        #expect(settings.currency == "BRL")
        settings.choose(currency: "USD")
        await settings.confirmCurrencyChoice()
        #expect(settings.currency == "USD")
        #expect(settings.currencyChoice == nil)
        #expect(settings.currencyValue.hasSuffix("USD"))
        #expect(settings.correctionFailed)
        #expect(settings.correction == nil)
        #expect(settings.choiceNotes(CurrencyChoice(from: "BRL", to: "USD")).count == 2)
    }

    @Test func missingRatesAreFetchedAtLaunchAndOnRetry() async {
        let setting = CurrencySetting()
        let table = ExchangeTable(
            base: "BRL", day: "2026-10-14", rates: ["USD": Decimal(string: "0.2") ?? 0],
            source: .currencyAPI)
        let offline = SettingsModel(
            defaults: defaults, cloudContainer: nil, currencySetting: setting)
        await offline.prepareCorrection()
        #expect(offline.correction == nil)
        #expect(!offline.correctionFailed)
        await offline.retryCorrection()
        #expect(offline.correctionFailed)
        #expect(offline.correctionStatus.canRetry)
        let online = SettingsModel(
            defaults: defaults, cloudContainer: nil, currencySetting: setting,
            rates: FixedExchangeRates(table: table))
        await online.prepareCorrection()
        #expect(online.correction?.target == "BRL")
        #expect(setting.correctionRate(from: "USD")?.rate == 5)
        #expect(!online.correctionStatus.canRetry)
    }

    @Test func cancelIsIgnoredWhileRatesLoad() async {
        let table = ExchangeTable(
            base: "USD", day: "2026-10-14", rates: ["BRL": 5], source: .currencyAPI)
        let settings = SettingsModel(
            defaults: defaults, cloudContainer: nil, currencySetting: CurrencySetting(),
            rates: FixedExchangeRates(table: table, delay: .milliseconds(80)))
        settings.choose(currency: "USD")
        let confirming = Task { await settings.confirmCurrencyChoice() }
        try? await Task.sleep(for: .milliseconds(20))
        #expect(settings.isFetchingCorrection)
        settings.cancelCurrencyChoice()
        #expect(settings.currencyChoice != nil)
        await confirming.value
        #expect(settings.currency == "USD")
        #expect(settings.correction?.target == "USD")
    }

    @Test func currencyChangeKeepsTheRatesOfThatMoment() async throws {
        let setting = CurrencySetting()
        let table = ExchangeTable(
            base: "USD", day: "2026-10-14", rates: ["BRL": 5, "EUR": 1], source: .currencyAPI)
        let settings = SettingsModel(
            defaults: defaults, cloudContainer: nil, currencySetting: setting,
            rates: FixedExchangeRates(table: table))
        settings.choose(currency: "USD")
        await settings.confirmCurrencyChoice()
        #expect(!settings.correctionFailed)
        #expect(settings.correction != nil)
        #expect(setting.correctionRate(from: "BRL")?.rate == Decimal(string: "0.2"))
        let reopened = SettingsModel(
            defaults: defaults, cloudContainer: nil, currencySetting: CurrencySetting())
        #expect(reopened.correction?.target == "USD")
        #expect(reopened.correction?.rate(from: "BRL") == Decimal(string: "0.2"))
    }

    @Test func languageHelpersResolveDevicePreviewAndValue() {
        let settings = makeSettings()
        #expect(settings.deviceLanguage(preferences: ["pt-BR"]) == .portuguese)
        #expect(settings.deviceLanguage(preferences: ["ja-JP"]) == .japanese)
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let portuguese = settings.languagePreview(of: .portuguese, on: date)
        let english = settings.languagePreview(of: .english, on: date)
        #expect(portuguese.amount.contains("842"))
        #expect(english.amount.contains("842"))
        #expect(portuguese.date != english.date)
        #expect(!english.sentence.isEmpty)
        #expect(
            settings.languageDetail(of: .system, preferences: ["pt-BR"])?.contains("Português")
                == true)
        #expect(AppLanguage.languages.allSatisfy { !$0.glyph.isEmpty })
    }

    @Test func notificationOverviewCountsReminders() async {
        let settings = makeSettings()
        let notifications = settings.notifications
        #expect(notifications.overviewValue == "Off")
        await notifications.setPayments(true)
        await notifications.setWeekly(true)
        #expect(notifications.enabledCount == 2)
        #expect(notifications.isOn(.payments))
        #expect(!notifications.isOn(.budgets))
        #expect(notifications.overviewValue.contains("2"))
        await notifications.setBudgets(true)
        await notifications.setPlanning(true)
        #expect(notifications.overviewValue == "All On")
        #expect(notifications.actions(of: .payments).count == 2)
        #expect(notifications.actions(of: .weekly).isEmpty)
        #expect(notifications.preview(of: .budgets).title.contains("Groceries"))
        #expect(notifications.preview(of: .planning) == ReminderText.planning)
    }

    @Test func deniedNotificationsShowTheSystemState() async {
        let settings = makeSettings(status: .denied)
        let notifications = settings.notifications
        await notifications.refreshStatus()
        #expect(notifications.overviewValue == "Off in Settings")
        #expect(notifications.statusSymbol == "bell.slash")
        await notifications.setPayments(true)
        #expect(!notifications.remindsPayments)
    }

    @Test func journeyHidingAsksFirstAndKeepsTheSummary() async {
        let settings = makeSettings()
        #expect(settings.showsJourney)
        settings.journeyToggle = false
        #expect(settings.isConfirmingHideJourney)
        #expect(settings.showsJourney)
        settings.hideJourney()
        #expect(!settings.showsJourney)
        #expect(!settings.isConfirmingHideJourney)
        #expect(settings.journeyValue == "Hidden")
        settings.journeyToggle = true
        #expect(settings.showsJourney)
        await settings.loadJourney(
            from: SnapshotSource(events: [
                GameEvent(kind: .guideCompleted, value: "a"),
                GameEvent(kind: .guideCompleted, value: "b"),
            ]))
        let journey = settings.journey
        #expect((journey?.level ?? 0) >= 1)
        #expect((journey?.xp ?? 0) >= 40)
        #expect(journey?.achievements == Achievement.allCases.count)
        #expect(settings.journeyValue.hasPrefix("Level"))
        #expect(settings.journeyHideNotes.count == 3)
    }
}

private struct FixedExchangeRates: ExchangeRateProviding {
    let table: ExchangeTable
    var delay: Duration = .zero

    func table(base: String, on date: Date?) async throws -> ExchangeTable {
        try await Task.sleep(for: delay)
        guard base == table.base else { throw URLError(.badURL) }
        return table
    }

    func currencies() async throws -> [String] {
        CurrencySetting.supported
    }
}
