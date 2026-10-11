import Foundation

public actor MCPServer {
    public static let protocolVersion = "2025-06-18"
    private let tools: [any MCPTool]
    private let instructions: String

    public init(tools: [any MCPTool], instructions: String) {
        self.tools = tools
        self.instructions = instructions
    }

    public func handle(_ data: Data) async -> Data? {
        guard let message = try? JSONDecoder().decode(JSONValue.self, from: data) else {
            return encode(error: -32700, message: "JSON inválido.", id: .null)
        }
        if let batch = message.array {
            var responses: [JSONValue] = []
            for item in batch {
                if let response = await respond(to: item) { responses.append(response) }
            }
            return responses.isEmpty ? nil : try? JSONEncoder().encode(JSONValue.array(responses))
        }
        return await respond(to: message).flatMap { try? JSONEncoder().encode($0) }
    }

    private func respond(to message: JSONValue) async -> JSONValue? {
        guard let method = message["method"]?.string else {
            return response(
                error: -32600, message: "Requisição inválida.", id: message["id"] ?? .null)
        }
        guard let id = message["id"] else { return nil }
        let params = message["params"] ?? [:]
        switch method {
        case "initialize":
            return response(
                result: [
                    "protocolVersion": params["protocolVersion"] ?? .string(Self.protocolVersion),
                    "capabilities": ["tools": ["listChanged": false]],
                    "serverInfo": ["name": "cashly", "title": "Cashly", "version": "1.0"],
                    "instructions": .string(instructions),
                ], id: id)
        case "ping":
            return response(result: [:], id: id)
        case "tools/list":
            return response(result: ["tools": .array(tools.map(\.definition))], id: id)
        case "tools/call":
            return await call(params, id: id)
        default:
            return response(error: -32601, message: "Método \(method) não suportado.", id: id)
        }
    }

    private func call(_ params: JSONValue, id: JSONValue) async -> JSONValue {
        guard let name = params["name"]?.string, let tool = tools.first(where: { $0.name == name })
        else {
            return response(error: -32602, message: "Ferramenta desconhecida.", id: id)
        }
        do {
            let text = try await tool.call(params["arguments"] ?? [:])
            return response(
                result: ["content": [["type": "text", "text": .string(text)]], "isError": false],
                id: id)
        } catch let error as MCPToolError {
            return response(
                result: [
                    "content": [["type": "text", "text": .string(error.message)]], "isError": true,
                ], id: id)
        } catch {
            return response(
                result: [
                    "content": [["type": "text", "text": .string(error.localizedDescription)]],
                    "isError": true,
                ],
                id: id)
        }
    }

    private func response(result: JSONValue, id: JSONValue) -> JSONValue {
        ["jsonrpc": "2.0", "id": id, "result": result]
    }

    private func response(error code: Int, message: String, id: JSONValue) -> JSONValue {
        [
            "jsonrpc": "2.0", "id": id,
            "error": ["code": .number(Double(code)), "message": .string(message)],
        ]
    }

    private func encode(error code: Int, message: String, id: JSONValue) -> Data? {
        try? JSONEncoder().encode(response(error: code, message: message, id: id))
    }
}
