import Foundation
import Synchronization

final class FakeBridgeProtocol: URLProtocol, @unchecked Sendable {
    struct Request: Sendable {
        let method: String
        let url: URL
        let authorization: String?
        let contentType: String?
        let body: Data
    }

    struct Reply: Sendable {
        let status: Int
        let body: Data

        init(_ status: Int, body: Data = Data()) {
            self.status = status
            self.body = body
        }

        static let paused = Reply(503, body: Data(#"{"error":"paused"}"#.utf8))
    }

    private struct Route: Sendable {
        var replies: [Reply]
        var requests: [Request] = []
    }

    private static let routes = Mutex<[String: Route]>([:])

    static func session(statuses: [Int]) -> (URLSession, URL) {
        session(replies: statuses.map { Reply($0) })
    }

    static func session(replies: [Reply]) -> (URLSession, URL) {
        let host = "\(UUID().uuidString.lowercased()).test"
        routes.withLock { $0[host] = Route(replies: replies) }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FakeBridgeProtocol.self]
        return (
            URLSession(configuration: configuration),
            URL(string: "https://\(host)/bridge/v1") ?? URL(filePath: "/")
        )
    }

    static func reply(with replies: [Reply], to base: URL) {
        routes.withLock { $0[base.host() ?? ""]?.replies = replies }
    }

    static func requests(to base: URL) -> [Request] {
        routes.withLock { $0[base.host() ?? ""]?.requests ?? [] }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let host = request.url?.host() ?? ""
        let recorded = Request(
            method: request.httpMethod ?? "", url: request.url ?? URL(filePath: "/"),
            authorization: request.value(forHTTPHeaderField: "Authorization"),
            contentType: request.value(forHTTPHeaderField: "Content-Type"), body: body())
        let reply = Self.routes.withLock { routes -> Reply in
            routes[host]?.requests.append(recorded)
            guard let replies = routes[host]?.replies, let first = replies.first else {
                return Reply(500)
            }
            if replies.count > 1 { routes[host]?.replies.removeFirst() }
            return first
        }
        guard let url = request.url,
            let response = HTTPURLResponse(
                url: url, statusCode: reply.status, httpVersion: "HTTP/1.1", headerFields: nil)
        else { return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: reply.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private func body() -> Data {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return Data() }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }
}
