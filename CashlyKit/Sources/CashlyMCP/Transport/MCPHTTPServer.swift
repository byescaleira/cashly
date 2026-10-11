import Foundation
import Network

public final class MCPHTTPServer: Sendable {
    public static let defaultPort: UInt16 = 41_337
    private let listener: NWListener
    private let server: MCPServer
    private let token: String
    private let queue = DispatchQueue(label: "cashly.mcp")

    public init(server: MCPServer, token: String, port: UInt16 = MCPHTTPServer.defaultPort) throws {
        let parameters = NWParameters.tcp
        parameters.requiredInterfaceType = .loopback
        parameters.allowLocalEndpointReuse = true
        guard let port = NWEndpoint.Port(rawValue: port) else {
            throw MCPToolError("Porta inválida.")
        }
        listener = try NWListener(using: parameters, on: port)
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
                Task {
                    let response = await respond(to: request)
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

    func respond(to request: HTTPRequest) async -> HTTPResponse {
        if let origin = request.headers["origin"], !origin.contains("localhost"),
            !origin.contains("127.0.0.1")
        {
            return HTTPResponse(status: 403, body: nil)
        }
        guard request.headers["authorization"] == "Bearer \(token)" else {
            return HTTPResponse(status: 401, body: nil)
        }
        guard request.path == "/mcp" else { return HTTPResponse(status: 404, body: nil) }
        guard request.method == "POST" else { return HTTPResponse(status: 405, body: nil) }
        guard let body = await server.handle(request.body) else {
            return HTTPResponse(status: 202, body: nil)
        }
        return HTTPResponse(status: 200, body: body)
    }
}
