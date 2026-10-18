import Foundation

public enum WebBridgeError: Error, Equatable, Sendable {
    case unauthorized
    case notFound
    case tooLarge
    case rateLimited
    case unavailable(Int)
    case offline
}

public struct WebBridge: Sendable {
    public let base: URL
    private let session: URLSession

    public init(base: URL, session: URLSession = .shared) {
        self.base = base
        self.session = session
    }

    public func url(for id: String) -> URL {
        base.appending(path: "snapshots").appending(path: id)
    }

    public func put(_ package: WebPackage, id: String, ownerToken: String) async throws {
        var request = request(id: id, method: "PUT", ownerToken: ownerToken)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try package.encoded()
        try check(await send(request), allowsMissing: false)
    }

    public func delete(id: String, ownerToken: String) async throws {
        try check(
            await send(request(id: id, method: "DELETE", ownerToken: ownerToken)),
            allowsMissing: true)
    }

    private func request(id: String, method: String, ownerToken: String) -> URLRequest {
        var request = URLRequest(url: url(for: id), timeoutInterval: 20)
        request.httpMethod = method
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("Bearer \(ownerToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func send(_ request: URLRequest) async throws -> Int {
        do {
            let (_, response) = try await session.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode ?? 0
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw WebBridgeError.offline
        }
    }

    private func check(_ status: Int, allowsMissing: Bool) throws {
        switch status {
        case 200..<300: return
        case 404 where allowsMissing: return
        case 401, 403: throw WebBridgeError.unauthorized
        case 404: throw WebBridgeError.notFound
        case 413: throw WebBridgeError.tooLarge
        case 429: throw WebBridgeError.rateLimited
        default: throw WebBridgeError.unavailable(status)
        }
    }
}
