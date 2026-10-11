import Foundation
import Network
import Testing

@testable import CashlyMCP

struct MCPHTTPServerTests {
    @Test func servesJSONRPCOverLoopback() async throws {
        let port = UInt16.random(in: 50_000...60_000)
        let http = try MCPHTTPServer(
            server: MCPServer(tools: [], instructions: "teste"), token: "secret", port: port)
        let ready = AsyncStream<Bool> { continuation in
            http.start { state in
                if case .ready = state { continuation.yield(true) }
                if case .failed = state { continuation.yield(false) }
            }
        }
        var iterator = ready.makeAsyncIterator()
        #expect(await iterator.next() == true)
        defer { http.stop() }

        var request = URLRequest(url: try #require(URL(string: "http://127.0.0.1:\(port)/mcp")))
        request.httpMethod = "POST"
        request.setValue("Bearer secret", forHTTPHeaderField: "Authorization")
        request.httpBody = Data(#"{"jsonrpc":"2.0","id":7,"method":"tools/list"}"#.utf8)
        let (data, response) = try await URLSession.shared.data(for: request)
        #expect((response as? HTTPURLResponse)?.statusCode == 200)
        let json = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(json["id"] == .number(7))
        #expect(json["result"]?["tools"] == .array([]))

        request.setValue(nil, forHTTPHeaderField: "Authorization")
        let (_, denied) = try await URLSession.shared.data(for: request)
        #expect((denied as? HTTPURLResponse)?.statusCode == 401)
    }
}
