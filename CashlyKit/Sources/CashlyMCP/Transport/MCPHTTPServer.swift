import Foundation
import Network

public final class MCPHTTPServer: Sendable {
    public static let defaultPort: UInt16 = 41_337
    public static let serviceType = "_cashly-mcp._tcp"
    private let listener: NWListener
    private let server: MCPServer
    private let token: String
    private let queue = DispatchQueue(label: "cashly.mcp")

    public init(
        server: MCPServer, token: String, port: UInt16 = MCPHTTPServer.defaultPort,
        localNetwork: Bool = false, serviceName: String? = nil
    ) throws {
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        if !localNetwork { parameters.requiredInterfaceType = .loopback }
        guard let port = NWEndpoint.Port(rawValue: port) else {
            throw MCPToolError("Porta inválida.")
        }
        listener = try NWListener(using: parameters, on: port)
        if localNetwork, let serviceName {
            listener.service = NWListener.Service(name: serviceName, type: Self.serviceType)
        }
        self.server = server
        self.token = token
    }

    public var port: UInt16? { listener.port?.rawValue }

    public func start(onState: @escaping @Sendable (NWListener.State) -> Void = { _ in }) {
        listener.stateUpdateHandler = onState
        listener.newConnectionHandler = { [self] connection in
            connection.start(queue: queue)
            receive(connection, buffer: Data())
        }
        listener.start(queue: queue)
    }

    public func stop() {
        listener.cancel()
    }

    private func receive(_ connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1 << 20) {
            [self] data, _, isComplete, error in
            var buffer = buffer
            if let data { buffer.append(data) }
            if let request = HTTPRequest(parsing: buffer) {
                let address = Self.address(of: connection.endpoint)
                Task {
                    let response = await respond(to: request, address: address)
                    connection.send(
                        content: response.data,
                        completion: .contentProcessed { _ in connection.cancel() })
                }
            } else if isComplete || error != nil || buffer.count > 16 << 20 {
                connection.cancel()
            } else {
                receive(connection, buffer: buffer)
            }
        }
    }

    func respond(to request: HTTPRequest, address: String = "127.0.0.1") async -> HTTPResponse {
        if let origin = request.headers["origin"], !origin.contains("localhost"),
            !origin.contains("127.0.0.1")
        {
            return HTTPResponse(status: 403, body: nil)
        }
        guard request.headers["authorization"] == "Bearer \(token)" else {
            return HTTPResponse(status: 401, body: nil)
        }
        guard request.path == "/mcp" else { return HTTPResponse(status: 404, body: nil) }
        let session = request.headers["mcp-session-id"]
        switch request.method {
        case "POST":
            let reply = await server.receive(request.body, session: session, address: address)
            return HTTPResponse(status: reply.status, body: reply.body, session: reply.session)
        case "DELETE":
            if let session { await server.close(session: session) }
            return HTTPResponse(status: 200, body: nil)
        default:
            return HTTPResponse(status: 405, body: nil)
        }
    }

    private static func address(of endpoint: NWEndpoint) -> String {
        guard case .hostPort(let host, _) = endpoint else { return "desconhecido" }
        switch host {
        case .ipv4(let address): return address.isLoopback ? "este aparelho" : "\(address)"
        case .ipv6(let address): return address.isLoopback ? "este aparelho" : "\(address)"
        case .name(let name, _): return name
        @unknown default: return "desconhecido"
        }
    }
}
