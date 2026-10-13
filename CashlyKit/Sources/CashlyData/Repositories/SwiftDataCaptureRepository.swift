import CashlyDomain

struct SwiftDataCaptureRepository: CaptureRepository {
    let scope: StoreScope

    func captures(status: Capture.Status?) async throws -> [Capture] {
        try await scope.store.getCaptures(status: status, userID: scope.requireUserID())
    }

    func capture(id: String) async throws -> Capture? {
        try await scope.store.getCapture(id: id, userID: scope.requireUserID())
    }

    func save(_ capture: Capture) async throws -> Capture {
        try await scope.store.saveCapture(capture, userID: scope.requireOwner(capture.ownerID))
    }

    func memory(key: String) async throws -> MerchantMemory? {
        try await scope.store.getMerchantMemory(key: key, userID: scope.requireUserID())
    }

    func remember(_ memory: MerchantMemory) async throws {
        try await scope.store.rememberMerchant(
            memory, userID: scope.requireOwner(memory.ownerID))
    }
}
