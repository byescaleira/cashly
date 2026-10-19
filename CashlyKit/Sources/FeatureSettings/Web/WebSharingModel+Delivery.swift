import CashlyDomain
import CashlyGame
import CashlyWeb
import FeatureCore
import Foundation

extension WebSharingModel {
    public func resume() {
        pruneExpired()
        scheduleSend(after: .zero)
    }

    public func scheduleSend(after delay: Duration = WebSharingModel.debounce) {
        guard !sessions.isEmpty else { return }
        pending?.cancel()
        pending = Task { [weak self] in
            if delay > .zero { try? await Task.sleep(for: delay) }
            guard !Task.isCancelled else { return }
            await self?.send()
        }
    }

    func snapshot() async throws -> Data {
        let users = try await provider.repositories(for: nil).users.users()
        let selected = preference.selectedUserID
        guard let user = users.first(where: { $0.id == selected }) ?? users.first else {
            throw CashlyError.missingRecord
        }
        return try await WebSnapshot.make(
            repositories: provider.repositories(for: user.id),
            context: WebSnapshot.Context(
                user: user, today: now(), currency: Money.currencyCode, locale: .app,
                includesJourney: includesJourney, guides: Guide.journeyIDs,
                unlocks: AchievementUnlocks.dates(for: user.id, in: .standard))
        ).encoded()
    }

    func persist() {
        do {
            try store.save(sessions)
        } catch {
            self.error = .persistence(String(appLocalized: "Couldn't save the connection."))
        }
    }

    func scheduleExpiry() {
        expiry?.cancel()
        guard let next = sessions.map(\.expiresAt).min() else { return }
        let delay = max(next.timeIntervalSince(now()), 0)
        expiry = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.pruneExpired()
        }
    }

    func listen() {
        let changes = provider.changes
        listener = Task { [weak self] in
            for await _ in changes.changes() {
                self?.scheduleSend()
            }
        }
    }
}
