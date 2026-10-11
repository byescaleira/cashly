import Foundation

public struct MCPToolError: Error, Sendable {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }
}

public protocol MCPTool: Sendable {
    var name: String { get }
    var description: String { get }
    var inputSchema: JSONValue { get }
    func call(_ arguments: JSONValue) async throws -> String
}

extension MCPTool {
    var definition: JSONValue {
        ["name": .string(name), "description": .string(description), "inputSchema": inputSchema]
    }
}

enum Schema {
    static func object(_ properties: [String: JSONValue], required: [String] = []) -> JSONValue {
        [
            "type": "object", "properties": .object(properties),
            "required": .array(required.map(JSONValue.string)),
        ]
    }

    static func string(_ description: String) -> JSONValue {
        ["type": "string", "description": .string(description)]
    }

    static func number(_ description: String) -> JSONValue {
        ["type": "number", "description": .string(description)]
    }

    static func integer(_ description: String) -> JSONValue {
        ["type": "integer", "description": .string(description)]
    }

    static func encode(_ value: some Encodable) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return String(decoding: try encoder.encode(value), as: UTF8.self)
    }
}
