public protocol CaptureRepository: Sendable {
    func captures(status: Capture.Status?) async throws -> [Capture]
    func capture(id: String) async throws -> Capture?
    func save(_ capture: Capture) async throws -> Capture
    func memory(key: String) async throws -> MerchantMemory?
    func remember(_ memory: MerchantMemory) async throws
}
