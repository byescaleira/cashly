//
//  AppDelegate.swift
//  Cashly
//
//  Bridges UIApplicationDelegate-only callbacks (Home-screen quick
//  actions, push registration, etc.) back into SwiftUI. Today the
//  only consumer is the cold-launch quick action: when the user taps
//  a Home-screen shortcut to launch the app from terminated, iOS
//  stashes the chosen `UIApplicationShortcutItem` in
//  `launchOptions[.shortcutItem]`. SwiftUI's
//  `.onContinueUserActivity` / scene callbacks don't surface that —
//  we capture it here and stash on `Self.launchShortcutType` for
//  `CashlyApp` to read on first frame.
//

import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    /// Set by `application(_:didFinishLaunchingWithOptions:)` when the
    /// app was cold-launched via a Home-screen quick action. Cleared
    /// by CashlyApp after it routes the shortcut.
    static var launchShortcutType: String?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if let shortcut = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            Self.launchShortcutType = shortcut.type
        }
        return true
    }

    /// Warm-launch path — iOS hands the shortcut directly here when
    /// the app was already in memory. SwiftUI scene callbacks pick
    /// up the same value because we re-publish via
    /// `UIApplication.willPerformShortcutItem` notification (not
    /// available; instead we mirror onto launchShortcutType and
    /// CashlyApp polls on scene phase change).
    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        Self.launchShortcutType = shortcutItem.type
        completionHandler(true)
    }
}
