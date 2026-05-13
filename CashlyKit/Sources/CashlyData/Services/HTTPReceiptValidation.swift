//
//  HTTPReceiptValidation.swift
//  CashlyKit
//
//  URLSession-backed ReceiptValidationUseCase. Posts the JWS payload
//  to `<baseURL>/v1/receipts/validate` and maps the JSON response to
//  ``ReceiptValidationResult``. Skeleton implementation — the
//  endpoint contract is provisional pending backend work.
//

import Foundation
import CashlyDomain

public actor HTTPReceiptValidation: ReceiptValidationUseCase {
    private let baseURL: URL
    private let session: URLSession
    private let timeout: TimeInterval

    public init(
        baseURL: URL,
        session: URLSession = .shared,
        timeout: TimeInterval = 10
    ) {
        self.baseURL = baseURL
        self.session = session
        self.timeout = timeout
    }

    public func validate(_ payload: ReceiptPayload) async -> ReceiptValidationResult {
        let url = baseURL.appendingPathComponent("v1/receipts/validate")
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "jws": payload.jws,
            "bundle_id": payload.bundleId,
            "app_account_token": payload.appAccountToken?.uuidString as Any
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return .unreachable }
            switch http.statusCode {
            case 200:
                return Self.parseValid(data) ?? .invalid(reason: "malformed")
            case 400, 401, 403, 422:
                return .invalid(reason: "rejected_\(http.statusCode)")
            default:
                return .unreachable
            }
        } catch {
            return .unreachable
        }
    }

    private static func parseValid(_ data: Data) -> ReceiptValidationResult? {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let tierRaw = json["tier"] as? String,
            let tier = SubscriptionTier(rawValue: tierRaw)
        else { return nil }
        let expires = (json["expires_at"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) }
        return .valid(tier: tier, expiresAt: expires)
    }
}
