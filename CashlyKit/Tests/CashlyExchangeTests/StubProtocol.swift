import Foundation
import Synchronization

final class StubProtocol: URLProtocol {
    static let responses = Mutex<[String: (status: Int, body: String)]>([:])
    static let requests = Mutex<[String]>([])

    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubProtocol.self]
        return URLSession(configuration: configuration)
    }

    static func respond(_ address: String, status: Int = 200, body: String) {
        responses.withLock { $0[address] = (status, body) }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else { return }
        let address = url.absoluteString
        Self.requests.withLock { $0.append(address) }
        let stub = Self.responses.withLock { $0[address] } ?? (404, "")
        if let response = HTTPURLResponse(
            url: url, statusCode: stub.status, httpVersion: nil, headerFields: nil)
        {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        client?.urlProtocol(self, didLoad: Data(stub.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
