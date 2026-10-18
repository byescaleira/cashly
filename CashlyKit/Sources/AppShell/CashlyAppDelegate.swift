import CloudKit
import FeatureCore

#if os(macOS)
    import AppKit

    public final class CashlyAppDelegate: NSObject, NSApplicationDelegate {
        public func application(
            _ application: NSApplication, userDidAcceptCloudKitShareWith metadata: CKShare.Metadata
        ) {
            Task { await CashlyServices.shared.sharing.accept(metadata) }
        }
    }
#else
    import UIKit

    public final class CashlyAppDelegate: NSObject, UIApplicationDelegate {
        public func application(
            _ application: UIApplication,
            configurationForConnecting connectingSceneSession: UISceneSession,
            options: UIScene.ConnectionOptions
        ) -> UISceneConfiguration {
            let configuration = UISceneConfiguration(
                name: nil, sessionRole: connectingSceneSession.role)
            configuration.delegateClass = CashlySceneDelegate.self
            return configuration
        }
    }

    final class CashlySceneDelegate: NSObject, UIWindowSceneDelegate {
        func scene(
            _ scene: UIScene, willConnectTo session: UISceneSession,
            options connectionOptions: UIScene.ConnectionOptions
        ) {
            guard let metadata = connectionOptions.cloudKitShareMetadata else { return }
            Task { await CashlyServices.shared.sharing.accept(metadata) }
        }

        func windowScene(
            _ windowScene: UIWindowScene,
            userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
        ) {
            Task { await CashlyServices.shared.sharing.accept(cloudKitShareMetadata) }
        }
    }
#endif
