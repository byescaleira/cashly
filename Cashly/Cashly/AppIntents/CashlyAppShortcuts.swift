//
//  CashlyAppShortcuts.swift
//  Cashly
//
//  Lightweight AppIntents catalogue. We avoid a separate extension
//  target — these intents run in-process and just publish deeplinks
//  through the same `MainDeeplink` channel SwiftUI already consumes.
//

import AppIntents
import CashlyPresentation

/// "Add Cashly Transaction" — Siri / Spotlight verb that opens the
/// new-transaction screen. Doesn't capture amount / category yet:
/// the real flow lives behind a SwiftUI form. Future iteration can
/// add `@Parameter` slots once we expose programmatic save.
struct AddTransactionIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Cashly Transaction"
    static let description = IntentDescription("Open Cashly with a fresh transaction form ready to fill in.")
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        PendingShortcutAction.shared.route = .addTransaction
        return .result()
    }
}

struct OpenInsightsIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Cashly Insights"
    static let description = IntentDescription("Open the spending breakdown screen.")
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        PendingShortcutAction.shared.route = .insights
        return .result()
    }
}

/// AppShortcutsProvider registers the catalogue with the system so
/// shortcuts appear in Spotlight / Siri without the user opening
/// the Shortcuts app first.
struct CashlyAppShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateTransactionIntent(),
            phrases: [
                "Log \(\.$utterance) in \(.applicationName)",
                "I spent \(\.$utterance) in \(.applicationName)",
                "Register in \(.applicationName) \(\.$utterance)",
                "New \(.applicationName) transaction \(\.$utterance)",
                "Registrar \(\.$utterance) no \(.applicationName)",
                "Gastei \(\.$utterance) no \(.applicationName)",
                "Nova transação \(\.$utterance) no \(.applicationName)"
            ],
            shortTitle: "Log Transaction",
            systemImageName: "plus.circle.fill"
        )
        AppShortcut(
            intent: AddTransactionIntent(),
            phrases: [
                "Add a transaction in \(.applicationName)",
                "New \(.applicationName) transaction",
                "Adicionar transação no \(.applicationName)",
                "Nova transação no \(.applicationName)"
            ],
            shortTitle: "Add Transaction",
            systemImageName: "square.and.pencil"
        )
        AppShortcut(
            intent: OpenInsightsIntent(),
            phrases: [
                "Show \(.applicationName) insights",
                "Open my \(.applicationName) spending",
                "Mostrar insights do \(.applicationName)",
                "Abrir gastos do \(.applicationName)"
            ],
            shortTitle: "Insights",
            systemImageName: "chart.bar.xaxis"
        )
    }
}

/// Side-channel between intent `perform` (background-ish) and the
/// SwiftUI scene. Intents stash a hint here; CashlyApp drains it on
/// the next `.active` transition and dispatches via routeExternal.
@MainActor
final class PendingShortcutAction {
    static let shared = PendingShortcutAction()
    private init() {}

    enum Route {
        case addTransaction
        case insights
    }

    var route: Route?
}
