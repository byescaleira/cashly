import Foundation

enum SharedSyncPolicy {
    enum Incoming: Equatable { case apply, keepLocal }
    enum Conflict: Equatable { case adoptServer, resend }
    enum Missing: Equatable { case deleteLocal, recreate }

    static let batchSize = 300
    static let scanDelay = Duration.seconds(1)

    static func pendingEdit(_ local: SharedSyncState.Record?) -> Date? {
        guard let local, let edited = local.editedAt, local.local != local.digest else {
            return nil
        }
        return edited
    }

    static func incoming(_ local: SharedSyncState.Record?, remoteEditedAt: Date) -> Incoming {
        guard let edited = pendingEdit(local), edited > remoteEditedAt else { return .apply }
        return .keepLocal
    }

    static func remoteDeletion(_ local: SharedSyncState.Record?) -> Missing {
        pendingEdit(local) == nil ? .deleteLocal : .recreate
    }

    static func conflict(
        _ local: SharedSyncState.Record?, serverEditedAt: Date, serverDigest: String?
    ) -> Conflict {
        guard let local, local.digest != nil, let edited = pendingEdit(local),
            local.local != serverDigest, edited > serverEditedAt
        else { return .adoptServer }
        return .resend
    }

    static func missingOnServer(_ local: SharedSyncState.Record?) -> Missing {
        pendingEdit(local) == nil ? .deleteLocal : .recreate
    }

    static func outgoing(_ local: SharedSyncState.Record?, currentDigest: String) -> Date? {
        if let confirmed = local?.digest, confirmed == currentDigest { return nil }
        return local?.editedAt ?? .distantPast
    }
}
