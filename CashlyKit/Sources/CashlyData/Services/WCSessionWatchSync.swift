//
//  WCSessionWatchSync.swift
//  CashlyKit
//
//  WatchConnectivity-backed WatchSyncUseCase. Uses
//  `updateApplicationContext` for latest-wins delivery so the Watch
//  always boots with the most recent snapshot even after long
//  offline periods. JSON-encodes the WatchSnapshot for the
//  applicationContext dictionary.
//

import Foundation
import CashlyDomain
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

public final class WCSessionWatchSync: NSObject, WatchSyncUseCase, @unchecked Sendable {
    public static let payloadKey = "cashly.watch.snapshot.v1"

    #if canImport(WatchConnectivity)
    private let session: WCSession?
    #endif

    public override init() {
        #if canImport(WatchConnectivity)
        self.session = WCSession.isSupported() ? .default : nil
        super.init()
        if let session {
            session.delegate = self
            session.activate()
        }
        #else
        super.init()
        #endif
    }

    public func send(_ snapshot: WatchSnapshot) async {
        #if canImport(WatchConnectivity)
        guard let session,
              session.activationState == .activated,
              let data = try? JSONEncoder().encode(snapshot)
        else { return }
        do {
            try session.updateApplicationContext([Self.payloadKey: data])
        } catch {
            // App context delivery can fail mid-transaction; the
            // next save call replaces the queued payload anyway, so
            // we degrade quietly.
        }
        #endif
    }

    public func isCompanionInstalled() async -> Bool {
        #if canImport(WatchConnectivity) && os(iOS)
        guard let session else { return false }
        return session.isPaired && session.isWatchAppInstalled
        #else
        return false
        #endif
    }
}

#if canImport(WatchConnectivity)
extension WCSessionWatchSync: WCSessionDelegate {
    public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
}
#endif
