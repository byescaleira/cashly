import CashlyDesignSystem
import CashlyDomain
import CashlyWeb
import Foundation
import SwiftUI

extension WebSharingModel {
    static var invalidLinkMessage: String {
        String(
            appLocalized:
                "This QR code isn't from Cashly on the Web. Open cashly.byescaleira.com/app on the computer and scan the code shown there."
        )
    }

    public var overviewValue: String {
        sessions.isEmpty
            ? String(appLocalized: "Off") : String(appLocalized: "\(sessions.count) connected")
    }

    public var pageAddress: String { endpoints.pageAddress }

    var steps: [String] {
        [
            String(appLocalized: "Open \(pageAddress) on any computer."),
            isScannerSupported
                ? String(
                    appLocalized: "Scan its QR code with the Camera app or Scan QR Code below.")
                : String(
                    appLocalized: "Scan its QR code with the Camera app on your iPhone or iPad."),
            String(
                appLocalized:
                    "Confirm in Cashly. Your month opens there in a moment and stays up to date for 24 hours."
            ),
        ]
    }

    var sessionsFooter: String {
        let disconnect = String(
            appLocalized:
                "Disconnecting deletes the summary from the bridge right away, and that browser goes back to the QR code."
        )
        guard !isPro else { return disconnect }
        let paused = String(
            appLocalized: "Without Cashly Pro, these computers stop receiving updates.")
        return "\(paused) \(disconnect)"
    }

    public var connectedCount: Double { Double(sessions.count) }

    var heroTitle: String {
        sessions.isEmpty
            ? String(appLocalized: "Your month on a computer")
            : String(appLocalized: "\(sessions.count) computers connected")
    }

    var heroMessage: String {
        sessions.isEmpty
            ? String(
                appLocalized:
                    "Open \(pageAddress) on a computer and scan its QR code. Nothing to type.")
            : String(appLocalized: "Your month updates there when your data changes.")
    }

    public func title(of session: WebSession) -> String {
        String(appLocalized: "Connected \(connectedTime(of: session))")
    }

    func connectedTime(of session: WebSession) -> String {
        session.createdAt.formatted(
            Date.FormatStyle(date: .abbreviated, time: .shortened).locale(.app))
    }

    func disconnectLabel(for session: WebSession) -> String {
        String(appLocalized: "Disconnect the computer connected \(connectedTime(of: session))")
    }

    public func detail(of session: WebSession, at date: Date) -> String {
        let remaining = Duration.seconds(Int(session.remaining(at: date)))
            .formatted(
                .units(allowed: [.hours, .minutes], width: .abbreviated, maximumUnitCount: 2)
                    .locale(.app))
        return String(appLocalized: "Ends in \(remaining)")
    }

    func statusColor(of session: WebSession) -> Color {
        if !isPro { return .retroMustard }
        if failedIDs.contains(session.id) { return .negative }
        return session.lastSentAt == nil ? .secondary : .positive
    }

    func status(of session: WebSession, at date: Date) -> String {
        if !isPro { return String(appLocalized: "Paused") }
        if failedIDs.contains(session.id) { return String(appLocalized: "Retrying") }
        guard let sent = session.lastSentAt else { return String(appLocalized: "Not sent yet") }
        let ago = Date.RelativeFormatStyle(presentation: .named, locale: .app).format(
            min(sent, date))
        return String(appLocalized: "Sent \(ago)")
    }

    public func remainingFraction(of session: WebSession, at date: Date) -> Double {
        session.remaining(at: date) / WebSession.lifetime
    }

    static func pairingError(_ error: any Error) -> CashlyError {
        switch error as? WebBridgeError {
        case .unauthorized, .notFound:
            .invalidInput(
                String(
                    appLocalized:
                        "This QR code is no longer valid. Reload the page on the computer and scan the new code."
                ))
        default: cashlyError(error)
        }
    }

    static func cashlyError(_ error: any Error) -> CashlyError {
        if let error = error as? CashlyError { return error }
        let message =
            switch error as? WebBridgeError {
            case .offline:
                String(
                    appLocalized:
                        "Couldn't reach Cashly on the Web. Check your connection and try again.")
            case .rateLimited:
                String(appLocalized: "Too many attempts. Wait a minute and try again.")
            case .tooLarge: String(appLocalized: "This month is too large to send.")
            case .unauthorized, .notFound, .unavailable, nil:
                String(
                    appLocalized: "Cashly on the Web isn't available right now. Try again later.")
            }
        return .invalidInput(message)
    }
}
