import CashlyAnalytics
import CashlyDomain
import CashlyMCP
import FeatureCore
import Foundation
import Network
import Observation

@MainActor @Observable
public final class MCPModel {
    public struct PendingImport: Identifiable, Sendable {
        public let id = UUID()
        public let preview: SpreadsheetPreview
        public let source: String
    }

    public enum State: Equatable {
        case off, starting, ready
        case failed(String)
    }

    public var isEnabled: Bool {
        didSet {
            defaults.set(isEnabled, forKey: Key.enabled)
            isEnabled ? start() : stop()
        }
    }
    public private(set) var token: String
    public private(set) var state = State.off
    public var pending: PendingImport?
    public let port = MCPHTTPServer.defaultPort
    @ObservationIgnored private let provider: any RepositoryProvider
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var server: MCPHTTPServer?
    @ObservationIgnored private var waiting: [UUID: CheckedContinuation<ImportOutcome, Never>] = [:]

    public init(provider: any RepositoryProvider, defaults: UserDefaults = .standard) {
        self.provider = provider
        self.defaults = defaults
        token = defaults.string(forKey: Key.token) ?? Self.newToken()
        isEnabled = defaults.bool(forKey: Key.enabled)
        defaults.set(token, forKey: Key.token)
        if isEnabled { start() }
    }

    public var command: String {
        "claude mcp add --transport http cashly http://127.0.0.1:\(port)/mcp --header \"Authorization: Bearer \(token)\""
    }

    public func regenerateToken() {
        token = Self.newToken()
        defaults.set(token, forKey: Key.token)
        if isEnabled {
            stop()
            start()
        }
    }

    public func finish(_ id: UUID, imported: Int?) {
        if pending?.id == id { pending = nil }
        waiting.removeValue(forKey: id)?.resume(
            returning: imported.map(ImportOutcome.imported) ?? .declined)
    }

    func present(_ preview: SpreadsheetPreview, source: String) async -> ImportOutcome {
        let request = PendingImport(preview: preview, source: source)
        pending = request
        return await withCheckedContinuation { continuation in
            waiting[request.id] = continuation
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(170))
                self?.waiting.removeValue(forKey: request.id)?.resume(returning: .waiting)
            }
        }
    }

    private func start() {
        guard server == nil else { return }
        let provider = provider
        let context = CashlyContext(
            workspace: { try await Self.workspace(provider) }, importer: Importer(model: self))
        do {
            let server = try MCPHTTPServer(
                server: CashlyTools.server(context), token: token, port: port)
            state = .starting
            server.start { [weak self] state in
                Task { @MainActor in self?.update(state) }
            }
            self.server = server
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func stop() {
        server?.stop()
        server = nil
        state = .off
    }

    private func update(_ listener: NWListener.State) {
        switch listener {
        case .ready: state = .ready
        case .failed(let error): state = .failed(error.localizedDescription)
        case .cancelled: if state != .off { state = .off }
        default: break
        }
    }

    private nonisolated static func workspace(_ provider: any RepositoryProvider) async throws -> (
        Repositories, User
    ) {
        let users = try await provider.repositories(for: nil).users.users()
        let selected = UserPreference.standard.selectedUserID
        guard let user = users.first(where: { $0.id == selected }) ?? users.first else {
            throw MCPToolError(
                "Nenhum perfil criado no Cashly ainda. Abra o app e conclua o início.")
        }
        return (provider.repositories(for: user.id), user)
    }

    private static func newToken() -> String {
        (0..<4).map { _ in UUID().uuidString.replacingOccurrences(of: "-", with: "") }.joined()
            .lowercased()
    }

    private enum Key {
        static let enabled = "cashly.mcp.enabled"
        static let token = "cashly.mcp.token"
    }
}

private struct Importer: TransactionImporting {
    weak var model: MCPModel?

    func requestImport(_ preview: SpreadsheetPreview, source: String) async -> ImportOutcome {
        guard let model else { return .declined }
        return await model.present(preview, source: source)
    }
}
