import Foundation

struct HTTPRequest: Sendable {
    let method: String
    let path: String
    let headers: [String: String]
    let body: Data

    init?(parsing data: Data) {
        guard let separator = data.firstRange(of: Data("\r\n\r\n".utf8)) else { return nil }
        let head = String(decoding: data[..<separator.lowerBound], as: UTF8.self)
        var lines = head.components(separatedBy: "\r\n")
        let start = lines.removeFirst().split(separator: " ")
        guard start.count >= 2 else { return nil }
        var headers: [String: String] = [:]
        for line in lines {
            guard let colon = line.firstIndex(of: ":") else { continue }
            headers[line[..<colon].lowercased()] = line[line.index(after: colon)...]
                .trimmingCharacters(in: .whitespaces)
        }
        let length = Int(headers["content-length"] ?? "0") ?? 0
        let body = data[separator.upperBound...]
        guard body.count >= length else { return nil }
        method = String(start[0])
        path = String(start[1].split(separator: "?").first ?? "")
        self.headers = headers
        self.body = Data(body.prefix(length))
    }
}

struct HTTPResponse: Sendable {
    let status: Int
    let body: Data?
    var session: String?

    var data: Data {
        let reason =
            switch status {
            case 200: "OK"
            case 202: "Accepted"
            case 401: "Unauthorized"
            case 403: "Forbidden"
            case 404: "Not Found"
            case 405: "Method Not Allowed"
            default: "Bad Request"
            }
        var head =
            "HTTP/1.1 \(status) \(reason)\r\nConnection: close\r\nContent-Length: \(body?.count ?? 0)\r\n"
        if body != nil { head += "Content-Type: application/json\r\n" }
        if let session { head += "Mcp-Session-Id: \(session)\r\n" }
        return Data((head + "\r\n").utf8) + (body ?? Data())
    }
}
