import CashlyDomain
import CashlyGame
import FeatureCore
import Foundation

public struct JourneySummary: Equatable, Sendable {
    let level: Int
    let levelProgress: Double
    let xp: Int
    let xpIntoLevel: Int
    let xpForNextLevel: Int
    let streak: Int
    let bestStreak: Int
    let isTodayTracked: Bool
    let unlocked: Int
    let achievements: Int
    let completedChallenges: Int
    let hasActiveChallenge: Bool

    init(_ progress: GameProgress) {
        level = progress.level.number
        levelProgress = progress.level.progress
        xp = progress.xp
        xpIntoLevel = progress.level.xpIntoLevel
        xpForNextLevel = progress.level.xpForNextLevel
        streak = progress.streak.current
        bestStreak = progress.streak.best
        isTodayTracked = progress.streak.isTodayTracked
        unlocked = progress.achievements.filter(\.isUnlocked).count
        achievements = progress.achievements.count
        completedChallenges = progress.completedChallenges
        hasActiveChallenge = progress.challenge != nil
    }
}

extension SettingsModel {
    var journeyToggle: Bool {
        get { showsJourney }
        set {
            if newValue {
                showsJourney = true
            } else if showsJourney {
                isConfirmingHideJourney = true
            }
        }
    }

    func hideJourney() {
        showsJourney = false
        isConfirmingHideJourney = false
    }

    func loadJourney(session: SessionModel) async {
        guard session.user != nil else {
            journey = nil
            return
        }
        await loadJourney(
            from: RepositoriesGameSource(
                repositories: session.repositories, guides: Guide.journeyIDs))
    }

    var journeyValue: String {
        guard showsJourney else { return String(appLocalized: "Hidden") }
        return journey.map { String(appLocalized: "Level \($0.level)") }
            ?? String(appLocalized: "On")
    }

    var journeyHeadline: String {
        guard let journey else { return String(appLocalized: "Your Journey") }
        return String(appLocalized: "Level \(journey.level)")
    }

    var journeyXPCaption: String? {
        guard let journey else { return nil }
        guard journey.xpForNextLevel > 0 else {
            return String(appLocalized: "\(journey.xp) XP in total")
        }
        return String(appLocalized: "\(journey.xpIntoLevel) of \(journey.xpForNextLevel) XP")
    }

    var journeyStreakText: String {
        String(appLocalized: "\(journey?.streak ?? 0) days")
    }

    var journeyAchievementsText: String {
        guard let journey else { return "0" }
        return
            "\(journey.unlocked.formatted(.number.locale(.app)))/\(journey.achievements.formatted(.number.locale(.app)))"
    }

    var journeyChallengesText: String {
        (journey?.completedChallenges ?? 0).formatted(.number.locale(.app))
    }

    var journeyHideNotes: [SettingsNote] {
        var notes: [SettingsNote] = []
        if let journey {
            notes.append(
                SettingsNote(
                    title: String(appLocalized: "Level \(journey.level) stays yours"),
                    detail: String(appLocalized: "Your XP and achievements are kept.")))
        }
        notes.append(
            SettingsNote(
                title: String(appLocalized: "Progress keeps counting"),
                detail: String(
                    appLocalized:
                        "Days you record still count, and an active challenge keeps running.")))
        notes.append(
            SettingsNote(
                title: String(appLocalized: "Back in one tap"),
                detail: String(appLocalized: "Turn it on here whenever you want the tab back.")))
        return notes
    }

    var journeyStateText: String {
        showsJourney
            ? String(appLocalized: "The Journey tab is visible.")
            : String(appLocalized: "The Journey tab is hidden. Your progress keeps counting.")
    }
}
