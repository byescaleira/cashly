import Foundation
import Testing

@testable import CashlyMCP

private actor Decisions {
    var asked: [MCPClient] = []
    let allow: Bool

    init(allow: Bool) {
        self.allow = allow
    }

    func decide(_ client: MCPClient) -> Bool {
        asked.append(client)
        return allow
    }
}

struct MCPSessionTests {
    private func body(_ method: String) throws -> Data {
        let request: JSONValue = [
            "jsonrpc": "2.0", "id": 1, "method": .string(method),
            "params": [
                "protocolVersion": "2025-06-18",
                "clientInfo": ["name": "claude-code", "version": "2.1"],
            ],
        ]
        return try JSONEncoder().encode(request)
    }

    @Test func approvedClientGetsASessionThatUnlocksRequests() async throws {
        let decisions = Decisions(allow: true)
        let server = MCPServer(
            tools: [], instructions: "", authorizer: { await decisions.decide($0) })
        let initialize = await server.receive(
            try body("initialize"), session: nil, address: "192.168.0.10")
        let session = try #require(initialize.session)
        #expect(
            await decisions.asked == [
                MCPClient(name: "claude-code", version: "2.1", address: "192.168.0.10")
            ])
        #expect(
            await server.receive(try body("tools/list"), session: nil, address: "x").status == 400)
        #expect(
            await server.receive(try body("tools/list"), session: "outra", address: "x").status
                == 404)
        #expect(
            await server.receive(try body("tools/list"), session: session, address: "x").status
                == 200)
        await server.close(session: session)
        #expect(
            await server.receive(try body("tools/list"), session: session, address: "x").status
                == 404)
    }

    @Test func refusedClientGetsAnErrorAndNoSession() async throws {
        let server = MCPServer(tools: [], instructions: "", authorizer: { _ in false })
        let reply = await server.receive(try body("initialize"), session: nil, address: "x")
        #expect(reply.session == nil)
        let json = try JSONDecoder().decode(JSONValue.self, from: try #require(reply.body))
        #expect(json["error"]?["code"] == .number(-32001))
    }
}
