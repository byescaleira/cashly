import CashlyData
import CashlyDomain
import Foundation
import Testing

@testable import CashlyMCP

private actor FakeImporter: TransactionImporting {
    var received: SpreadsheetPreview?
    let outcome: ImportOutcome

    init(outcome: ImportOutcome) {
        self.outcome = outcome
    }

    func requestImport(_ preview: SpreadsheetPreview, source: String) async -> ImportOutcome {
        received = preview
        return outcome
    }
}

struct MCPServerTests {
    private let owner = User(id: "owner", name: "Ana", photo: "1")

    private func server(_ importer: FakeImporter = FakeImporter(outcome: .imported(1))) async throws
        -> MCPServer
    {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        let repositories = database.repositories(for: owner.id)
        let market = CashlyDomain.Category(
            id: "market", user: owner, name: "Mercado", color: "C2602A", icon: "cart.fill")
        try await repositories.categories.save(market)
        try await repositories.transactions.save(
            Transaction(
                id: "t1", participants: [], category: market, money: Money(minorUnits: 12_345),
                date: .now,
                summary: "Feira", status: .settled, splitMode: nil, splitValue: nil,
                paymentsPlan: nil))
        let owner = owner
        let context = CashlyContext(workspace: { (repositories, owner) }, importer: importer)
        return CashlyTools.server(context)
    }

    private func call(_ server: MCPServer, _ method: String, _ params: JSONValue = [:], id: Int = 1)
        async throws
        -> JSONValue
    {
        let request: JSONValue = [
            "jsonrpc": "2.0", "id": .number(Double(id)), "method": .string(method),
            "params": params,
        ]
        let data = try #require(await server.handle(try JSONEncoder().encode(request)))
        return try JSONDecoder().decode(JSONValue.self, from: data)
    }

    private func text(_ response: JSONValue) -> String {
        response["result"]?["content"]?.array?.first?["text"]?.string ?? ""
    }

    @Test func initializeAndListTools() async throws {
        let server = try await server()
        let initialize = try await call(server, "initialize", ["protocolVersion": "2025-06-18"])
        #expect(initialize["result"]?["serverInfo"]?["name"]?.string == "cashly")
        let list = try await call(server, "tools/list")
        let names = Set(list["result"]?["tools"]?.array?.compactMap { $0["name"]?.string } ?? [])
        #expect(
            names == [
                "get_catalog", "get_summary", "list_transactions", "list_budgets", "run_analysis",
                "import_transactions",
            ])
        let notification: JSONValue = ["jsonrpc": "2.0", "method": "notifications/initialized"]
        #expect(await server.handle(try JSONEncoder().encode(notification)) == nil)
    }

    @Test func readToolsReturnTheData() async throws {
        let server = try await server()
        let catalog = try await call(server, "tools/call", ["name": "get_catalog"])
        #expect(text(catalog).contains("\"categories\":[\"Mercado\"]"))
        let transactions = try await call(
            server, "tools/call", ["name": "list_transactions", "arguments": ["text": "Fei"]])
        #expect(text(transactions).contains("\"amount\":123.45"))
        let summary = try await call(server, "tools/call", ["name": "get_summary"])
        #expect(text(summary).contains("\"expenses\":123.45"))
        let bad = try await call(
            server, "tools/call", ["name": "get_summary", "arguments": ["month": "outubro"]])
        #expect(bad["result"]?["isError"] == .bool(true))
    }

    @Test func importValidatesAndHandsRowsToTheApp() async throws {
        let importer = FakeImporter(outcome: .imported(1))
        let server = try await server(importer)
        let response = try await call(
            server, "tools/call",
            [
                "name": "import_transactions",
                "arguments": [
                    "source": "Extrato",
                    "transactions": [
                        [
                            "date": "2026-10-05", "description": "Padaria", "amount": 18.9,
                            "kind": "expense", "category": "Mercado",
                        ],
                        [
                            "date": "2026-02-30", "description": "Erro", "amount": 1,
                            "kind": "expense", "category": "X",
                        ],
                    ],
                ],
            ])
        #expect(text(response).hasPrefix("Importadas 1 transações."))
        #expect(text(response).contains("#2 data inválida"))
        let preview = try #require(await importer.received)
        #expect(preview.rows.first?.money.minorUnits == 1890)
        #expect(preview.issues.count == 1)
    }

    @Test func httpRequiresTheTokenAndThePath() async throws {
        let http = try MCPHTTPServer(server: try await server(), token: "secret", port: 0)
        let ping: JSONValue = ["jsonrpc": "2.0", "id": 1, "method": "ping"]
        let body = try JSONEncoder().encode(ping)
        func request(_ headers: String, path: String = "/mcp") -> HTTPRequest? {
            HTTPRequest(
                parsing: Data(
                    "POST \(path) HTTP/1.1\r\n\(headers)Content-Length: \(body.count)\r\n\r\n".utf8)
                    + body)
        }
        #expect(await http.respond(to: try #require(request(""))).status == 401)
        #expect(
            await http.respond(
                to: try #require(request("Authorization: Bearer secret\r\n", path: "/x"))
            ).status == 404)
        #expect(
            await http.respond(
                to: try #require(
                    request("Authorization: Bearer secret\r\nOrigin: https://evil.com\r\n"))
            )
            .status == 403)
        let ok = await http.respond(to: try #require(request("Authorization: Bearer secret\r\n")))
        #expect(ok.status == 200)
        #expect(
            HTTPRequest(parsing: Data("POST /mcp HTTP/1.1\r\nContent-Length: 10\r\n\r\nabc".utf8))
                == nil)
    }
}
