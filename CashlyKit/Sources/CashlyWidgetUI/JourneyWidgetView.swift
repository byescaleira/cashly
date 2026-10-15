import CashlyDesignSystem
import CashlyDomain
import SwiftUI

public struct JourneyWidgetView: View {
    private let snapshot: JourneySnapshot?
    private let size: WidgetSize
    private let date: Date

    public init(snapshot: JourneySnapshot?, size: WidgetSize, date: Date = .now) {
        self.snapshot = snapshot
        self.size = size
        self.date = date
    }

    public var body: some View {
        if let snapshot {
            switch snapshot.status {
            case .active: JourneyLayout(snapshot: snapshot, size: size, date: date)
            case .paused:
                WidgetMessage(symbol: "pause.circle", text: Text("Journey Paused"), size: size)
            case .hidden:
                WidgetMessage(
                    symbol: "trophy", text: Text("Turn the Journey on in Cashly › Settings."),
                    size: size)
            }
        } else {
            WidgetMessage(
                symbol: "trophy", text: Text("Open Cashly to start your journey."), size: size)
        }
    }
}

private struct JourneyLayout: View {
    let snapshot: JourneySnapshot
    let size: WidgetSize
    let date: Date

    var body: some View {
        switch size {
        case .circular, .rectangular, .inline:
            LockScreenJourney(snapshot: snapshot, size: size, date: date)
        case .medium: MediumJourney(snapshot: snapshot, date: date)
        case .large: LargeJourney(snapshot: snapshot, date: date)
        case .small: SmallJourney(snapshot: snapshot, date: date)
        }
    }
}

private struct SmallJourney: View {
    let snapshot: JourneySnapshot
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceXS) {
            HStack(alignment: .top) {
                LevelHeader(level: snapshot.level, size: .small)
                Spacer(minLength: 0)
                StreakCount(streak: snapshot.streak, date: date)
            }
            XPBar(level: snapshot.level)
            Spacer(minLength: 0)
            if let challenge = snapshot.challenge {
                ChallengeLine(challenge: challenge)
            } else {
                MissionsLine(snapshot: snapshot)
            }
        }
    }
}

private struct MediumJourney: View {
    let snapshot: JourneySnapshot
    let date: Date

    var body: some View {
        HStack(alignment: .top, spacing: .spaceL) {
            VStack(alignment: .leading, spacing: .spaceXS) {
                LevelHeader(level: snapshot.level, size: .medium)
                XPBar(level: snapshot.level)
                Spacer(minLength: 0)
                StreakRow(streak: snapshot.streak, date: date)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Group {
                if let challenge = snapshot.challenge {
                    ChallengeBlock(challenge: challenge, date: date)
                } else {
                    MissionList(snapshot: snapshot, isCompact: true)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

private struct LargeJourney: View {
    let snapshot: JourneySnapshot
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceM) {
            HStack(alignment: .center) {
                LevelHeader(level: snapshot.level, size: .large)
                Spacer(minLength: .spaceS)
                StreakRow(streak: snapshot.streak, date: date, size: .badgeM).fixedSize()
            }
            XPBar(level: snapshot.level, showsRemaining: true)
            MissionList(snapshot: snapshot, isCompact: false)
            Spacer(minLength: 0)
            if let challenge = snapshot.challenge {
                ChallengeBlock(challenge: challenge, date: date)
            } else if let achievement = snapshot.nextAchievement {
                AchievementBlock(achievement: achievement)
            }
        }
    }
}

private struct LockScreenJourney: View {
    let snapshot: JourneySnapshot
    let size: WidgetSize
    let date: Date

    var body: some View {
        let streak = snapshot.streak
        let flame = streak.isDone(on: date) ? "flame.fill" : "flame"
        switch size {
        case .circular:
            VStack(spacing: .spaceHairline) {
                Image(systemName: flame).font(.caption.weight(.bold))
                Text(verbatim: streak.current.formatted(.number.locale(.app)))
                    .font(.headline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                UsageBar(
                    ratio: snapshot.challenge?.progress ?? snapshot.level.progress, height: 4,
                    color: .primary
                )
                .frame(width: 34)
            }
        case .inline:
            Label {
                Text(
                    "\(Text("\(streak.current) days")) · \(Text("Level \(snapshot.level.number)"))")
            } icon: {
                Image(systemName: flame)
            }
        default:
            LockScreenRectangle(snapshot: snapshot, flame: flame)
        }
    }
}

private struct LockScreenRectangle: View {
    let snapshot: JourneySnapshot
    let flame: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: .space2XS) {
                Image(systemName: flame)
                Text(verbatim: snapshot.streak.current.formatted(.number.locale(.app)))
                Text(verbatim: "·").foregroundStyle(.secondary)
                Text("Level \(snapshot.level.number)")
            }
            .font(.headline)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
            if let challenge = snapshot.challenge {
                Text(verbatim: challenge.title).font(.footnote).lineLimit(1)
                Spacer(minLength: 0)
                HStack(spacing: .spaceS) {
                    UsageBar(ratio: challenge.progress, height: 5, color: .primary)
                    Text(verbatim: challenge.shortMeasure(currencyCode: snapshot.currencyCode))
                        .font(.footnote.monospacedDigit())
                        .lineLimit(1)
                }
            } else {
                Text(verbatim: snapshot.level.title).font(.footnote).lineLimit(1)
                Spacer(minLength: 0)
                HStack(spacing: .spaceS) {
                    UsageBar(ratio: snapshot.level.progress, height: 5, color: .primary)
                    Text(verbatim: "\(snapshot.missionsDone)/\(snapshot.missions.count)")
                        .font(.footnote.monospacedDigit())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
