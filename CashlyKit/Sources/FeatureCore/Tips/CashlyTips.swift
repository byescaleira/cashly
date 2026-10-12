import Foundation
import TipKit

@MainActor
public enum CashlyTips {
    nonisolated public static let transactionSaved = Tips.Event(id: "cashly.tips.transactionSaved")
    nonisolated public static let journeyOpened = Tips.Event(id: "cashly.tips.journeyOpened")
    private static let showAllKey = "cashly.tips.showAll"
    private static var isConfigured = false

    public static func configure(cloudContainer: String?, defaults: UserDefaults = .standard) {
        if defaults.bool(forKey: showAllKey) {
            defaults.removeObject(forKey: showAllKey)
            try? Tips.resetDatastore()
            Tips.showAllTipsForTesting()
        }
        var options: [Tips.ConfigurationOption] = [.displayFrequency(.daily)]
        if let cloudContainer {
            options.append(.cloudKitContainer(.named(cloudContainer)))
        }
        try? Tips.configure(options)
        isConfigured = true
    }

    public static func record(_ event: Tips.Event<Tips.EmptyDonation>) async {
        guard isConfigured else { return }
        await event.donate()
    }

    public static func showAllOnNextLaunch(defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: showAllKey)
    }
}
