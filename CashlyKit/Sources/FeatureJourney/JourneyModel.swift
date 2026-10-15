import CashlyDomain
import CashlyGame
import FeatureCore
import Foundation
import Observation

@MainActor @Observable
public final class JourneyModel {
    public internal(set) var progress: GameProgress?
    public private(set) var categories: [CashlyDomain.Category] = []
    public private(set) var celebrations: [Celebration] = []
    public var selected: AchievementState?
    public internal(set) var unlockDates: [Achievement: Date] = [:]
    public internal(set) var pendingAction: AchievementAction?
    public var isChoosingChallenge = false
    public var challengePath: [Challenge.Kind] = []
    public var isOfferingRerolls = false
    public var isConfirmingAbandon = false
    public var draft = ChallengeDraft()
    public var error: CashlyError?
    @ObservationIgnored let session: SessionModel
    @ObservationIgnored let defaults: UserDefaults
    @ObservationIgnored let journeyStore: JourneySnapshotStore?
    @ObservationIgnored let now: () -> Date

    public init(
        session: SessionModel, defaults: UserDefaults = .standard,
        journeyStore: JourneySnapshotStore? = nil, now: @escaping () -> Date = { .now }
    ) {
        self.session = session
        self.defaults = defaults
        self.journeyStore = journeyStore
        self.now = now
    }

    public var celebration: Celebration? {
        get { celebrations.first }
        set { if newValue == nil, !celebrations.isEmpty { celebrations.removeFirst() } }
    }

    public func load() async {
        guard let userID = session.user?.id else {
            progress = nil
            await publish()
            return
        }
        guard let progress = await compute() else { return }
        celebrate(progress, userID: userID)
        self.progress = progress
        await publish()
    }

    func compute() async -> GameProgress? {
        do {
            let source = RepositoriesGameSource(
                repositories: session.repositories, guideCount: Guide.allCases.count)
            let snapshot = try await source.snapshot(today: now())
            categories = snapshot.ledger.categories.sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
            return GameEngine.progress(snapshot)
        } catch {
            self.error = error as? CashlyError ?? .onFetch
            return nil
        }
    }

    public func markNoSpendToday() async {
        await record(GameEvent(kind: .noSpendDay, date: now()))
    }

    public func chooseChallenge() {
        draft = ChallengeDraft(categoryID: defaultCategoryID)
        challengePath = []
        isChoosingChallenge = true
    }

    public func startChallenge() async {
        guard let challenge = draft.challenge, canStartDraft else { return }
        isChoosingChallenge = false
        challengePath = []
        await record(GameEvent(kind: .challengeStarted, date: now(), value: challenge.code))
    }

    public func abandonChallenge() async {
        await record(GameEvent(kind: .challengeAbandoned, date: now()))
    }

    private func record(_ event: GameEvent) async {
        do {
            try await session.repositories.game.record([event])
            await load()
        } catch {
            self.error = error as? CashlyError ?? .onSave
        }
    }

    private func celebrate(_ progress: GameProgress, userID: String) {
        let key = "cashly.journey.seen." + userID
        let unlocked = progress.achievements.filter(\.isUnlocked).map(\.achievement)
        defer {
            defaults.set(
                [Seen.level: progress.level.number, Seen.achievements: unlocked.map(\.rawValue)],
                forKey: key)
        }
        let seen = defaults.dictionary(forKey: key)
        let known = Set(seen?[Seen.achievements] as? [String] ?? [])
        let fresh = seen == nil ? [] : unlocked.filter { !known.contains($0.rawValue) }
        stampUnlocks(fresh, unlocked: unlocked, userID: userID)
        guard let seen else { return }
        let level = seen[Seen.level] as? Int ?? progress.level.number
        var news = fresh.map(Celebration.achievement)
        if progress.level.number > level { news.insert(.level(progress.level.number), at: 0) }
        celebrations += news.filter { !celebrations.contains($0) }
    }

    private enum Seen {
        static let level = "level"
        static let achievements = "achievements"
    }
}

public enum Celebration: Identifiable, Hashable, Sendable {
    case level(Int)
    case achievement(Achievement)

    public var id: String {
        switch self {
        case .level(let number): "level-\(number)"
        case .achievement(let achievement): "achievement-" + achievement.rawValue
        }
    }
}

public struct ChallengeDraft: Equatable, Sendable {
    public var kind = Challenge.Kind.noSpendWeekend
    public var categoryID: String?
    public var limit = 0.0

    public var challenge: Challenge? {
        if kind.needsCategory && categoryID == nil { return nil }
        let cents = kind.needsLimit ? (try? Money(validating: limit))?.minorUnits : nil
        if kind.needsLimit && (cents ?? 0) <= 0 { return nil }
        return Challenge(
            kind: kind, categoryID: kind.needsCategory ? categoryID : nil, limit: cents)
    }
}
