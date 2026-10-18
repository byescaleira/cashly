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

    private struct Route: Sendable {
        var statuses: [Int]
        var requests: [Request] = []
    }

    private static let routes = Mutex<[String: Route]>([:])

    static func session(statuses: [Int]) -> (URLSession, URL) {
        let host = "\(UUID().uuidString.lowercased()).test"
        routes.withLock { $0[host] = Route(statuses: statuses) }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FakeBridgeProtocol.self]
        return (
            URLSession(configuration: configuration),
            URL(string: "https://\(host)/bridge/v1") ?? URL(filePath: "/")
        )
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
        let status = Self.routes.withLock { routes -> Int in
            routes[host]?.requests.append(recorded)
            guard let statuses = routes[host]?.statuses, let first = statuses.first else {
                return 500
            }
            if statuses.count > 1 { routes[host]?.statuses.removeFirst() }
            return first
        }
        guard let url = request.url,
            let response = HTTPURLResponse(
                url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)
        else { return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data())
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
