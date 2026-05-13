//
//  MainDeeplink.swift
//  CashlyKit
//
//  Parses `cashly://…` URLs into MainRoute values so the app delegate
//  can hand a single onOpenURL push to the router. Centralises the
//  schema so URL shapes do not leak into views.
//

import Foundation
#if canImport(CoreSpotlight)
import CoreSpotlight
#endif

public enum MainDeeplink {
    /// Supported scheme — used by Info.plist URL types + universal
    /// links.
    public static let scheme = "cashly"

    /// Resolve a URL to a `MainRoute`, or `nil` when the URL is
    /// unrecognised. Supported shapes today:
    ///
    /// - `cashly://paywall` → `.paywall(.upgradeButton)`
    /// - `cashly://paywall?trigger=limit` → `.paywall(.limitReached)`
    /// - `cashly://paywall?trigger=intelligence` → `.paywall(.intelligenceTab)`
    /// - `cashly://settings` → `.settings`
    /// - `cashly://home` → `.home`
    /// - `cashly://intelligence` → `.intelligence`
    /// - `cashly://transactions` → `.transaction`
    /// - `cashly://categories` → `.category`
    public static func resolve(_ url: URL) -> MainRoute? {
        guard url.scheme == scheme,
              let host = url.host ?? url.pathComponents.dropFirst().first
        else { return nil }

        switch host {
        case "paywall":
            return .paywall(trigger: trigger(from: url))
        case "settings":
            return .settings
        case "home":
            return .home
        case "intelligence":
            return .intelligence
        case "transactions", "transaction":
            return .transaction
        case "categories", "category":
            return .category
        default:
            return nil
        }
    }

    /// Resolves a `UIApplicationShortcutItem` type identifier — wired
    /// from the Info.plist `UIApplicationShortcutItems` entries via
    /// SwiftUI's scenePhase Home-screen quick-action callback.
    public static func resolve(shortcutType: String) -> MainRoute? {
        switch shortcutType {
        case "com.cashly.app.shortcut.add-transaction":
            return .addTransaction(state: .new())
        case "com.cashly.app.shortcut.insights":
            return .insights
        case "com.cashly.app.shortcut.paywall":
            return .paywall(trigger: .upgradeButton)
        default:
            return nil
        }
    }

    /// Resolve an `NSUserActivity` arriving via `onContinueUserActivity`.
    /// Today only Spotlight (`CSSearchableItemActionType`) is handled —
    /// taps on indexed transactions route to the edit screen.
    #if canImport(CoreSpotlight)
    public static func resolve(_ activity: NSUserActivity) -> MainRoute? {
        guard activity.activityType == CSSearchableItemActionType,
              let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String
        else { return nil }
        return .addTransaction(state: .edit(id: identifier))
    }
    #endif

    private static func trigger(from url: URL) -> PaywallTrigger {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let raw = components?.queryItems?.first(where: { $0.name == "trigger" })?.value
        switch raw {
        case "limit": return .limitReached
        case "intelligence": return .intelligenceTab
        default: return .upgradeButton
        }
    }
}
