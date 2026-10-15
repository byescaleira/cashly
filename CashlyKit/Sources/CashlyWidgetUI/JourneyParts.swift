import CashlyDesignSystem
import CashlyDomain
import SwiftUI

struct StreakFlame: View {
    let isDone: Bool
    var size: CGFloat = .badgeS

    var body: some View {
        SymbolBadge(
            isDone ? "flame.fill" : "flame", color: .retroOrange, size: size,
            style: isDone ? .filled : .tinted)
    }
}

struct LevelHeader: View {
    let level: JourneySnapshot.Level
    let size: WidgetSize

    var body: some View {
        VStack(alignment: .leading, spacing: .space2XS) {
            WidgetTag(level.title.uppercased(), color: .retroOrange)
            Text("Level \(level.number)")
                .font(.widgetAmount(size))
                .fontDesign(.rounded)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

struct XPBar: View {
    let level: JourneySnapshot.Level
    var showsRemaining = false

    var body: some View {
        VStack(alignment: .leading, spacing: .space2XS) {
            HStack(alignment: .firstTextBaseline, spacing: .spaceXS) {
                if level.isMaximum {
                    Text("Highest level reached")
                } else {
                    Text("\(level.xpIntoLevel) of \(level.xpForNextLevel) XP")
                        .foregroundStyle(Color.retroOrange)
                    if showsRemaining {
                        Spacer(minLength: 0)
                        Text("\(level.xpToNext) XP to level \(level.number + 1)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .font(.caption2.weight(.semibold))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            UsageBar(ratio: level.progress, color: .retroOrange)
        }
    }
}

struct StreakCount: View {
    let streak: JourneySnapshot.Streak
    let date: Date

    var body: some View {
        let isDone = streak.isDone(on: date)
        HStack(spacing: .space2XS) {
            Image(systemName: isDone ? "flame.fill" : "flame")
            Text(verbatim: streak.current.formatted(.number.locale(.app)))
                .monospacedDigit()
        }
        .font(.subheadline.weight(.bold))
        .fontDesign(.rounded)
        .foregroundStyle(isDone ? Color.retroOrange : Color.secondary)
        .lineLimit(1)
    }
}

struct StreakRow: View {
    let streak: JourneySnapshot.Streak
    let date: Date
    var size: CGFloat = .badgeS

    var body: some View {
        let isDone = streak.isDone(on: date)
        HStack(spacing: .spaceS) {
            StreakFlame(isDone: isDone, size: size)
            VStack(alignment: .leading, spacing: .spaceHairline) {
                Text("\(streak.current) days")
                    .font(.widgetSecondary)
                    .fontDesign(.rounded)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(isDone ? "Today is done" : "Record something today to keep it going")
                    .font(.caption2)
                    .foregroundStyle(isDone ? Color.positive : Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }
}

struct MissionRow: View {
    let mission: JourneySnapshot.Mission
    let isCompact: Bool

    var body: some View {
        let color: Color = mission.isCompleted ? .positive : .retroOrange
        HStack(spacing: .spaceXS) {
            SymbolBadge(
                mission.isCompleted ? "checkmark" : mission.symbol, color: color,
                size: isCompact ? 18 : 24, style: mission.isCompleted ? .filled : .tinted)
            VStack(alignment: .leading, spacing: .spaceHairline) {
                HStack(alignment: .firstTextBaseline, spacing: .space2XS) {
                    Text(verbatim: mission.title)
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                    if !isCompact {
                        Text("+\(mission.xp) XP")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(mission.isCompleted ? Color.positive : .secondary)
                    }
                }
                HStack(spacing: .spaceXS) {
                    UsageBar(ratio: mission.progress, height: 4, color: color)
                    Text(verbatim: "\(mission.value)/\(mission.target)")
                        .font(.widgetRow.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct MissionList: View {
    let snapshot: JourneySnapshot
    let isCompact: Bool

    var body: some View {
        let isDone = snapshot.missionsDone == snapshot.missions.count
        VStack(alignment: .leading, spacing: isCompact ? .spaceXS : .spaceS) {
            HStack {
                WidgetLabel("This Week")
                Spacer(minLength: 0)
                WidgetTag(
                    "\(snapshot.missionsDone)/\(snapshot.missions.count)",
                    color: isDone ? .positive : .retroOrange)
            }
            ForEach(snapshot.missions) { MissionRow(mission: $0, isCompact: isCompact) }
        }
    }
}

struct ChallengeBlock: View {
    let challenge: JourneySnapshot.Challenge
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceXS) {
            HStack {
                WidgetLabel("Challenge")
                Spacer(minLength: 0)
                WidgetTag("+\(challenge.xp) XP", color: challenge.tint.color)
            }
            HStack(spacing: .spaceS) {
                SymbolBadge(challenge.symbol, color: challenge.tint.color, size: 28, style: .filled)
                Text(verbatim: challenge.title)
                    .font(.subheadline.weight(.bold))
                    .fontDesign(.rounded)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
            HStack(alignment: .firstTextBaseline, spacing: .spaceXS) {
                Text(verbatim: challenge.measure)
                    .font(.caption2.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(challenge.color)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                Text("\(challenge.daysLeft(at: date)) days left")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            UsageBar(ratio: challenge.progress, color: challenge.color, marker: challenge.elapsed)
            PaceLabel(challenge: challenge, font: .caption2)
        }
    }
}

struct PaceLabel: View {
    let challenge: JourneySnapshot.Challenge
    let font: Font

    var body: some View {
        if let paceTitle = challenge.paceTitle {
            Label {
                Text(verbatim: paceTitle)
            } icon: {
                Image(systemName: challenge.paceSymbol)
            }
            .font(font.weight(.semibold))
            .foregroundStyle(challenge.color)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
    }
}

struct ChallengeLine: View {
    let challenge: JourneySnapshot.Challenge

    var body: some View {
        HStack(spacing: .spaceXS) {
            Image(systemName: challenge.symbol)
                .font(.caption.weight(.bold))
                .foregroundStyle(challenge.tint.color)
            VStack(alignment: .leading, spacing: .space2XS) {
                Text(verbatim: challenge.title)
                    .font(.caption2.weight(.bold))
                    .lineLimit(1)
                UsageBar(ratio: challenge.progress, height: 4, color: challenge.color)
            }
        }
    }
}

struct MissionsLine: View {
    let snapshot: JourneySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: .space2XS) {
            HStack {
                WidgetLabel("This Week")
                Spacer(minLength: 0)
                Text(verbatim: "\(snapshot.missionsDone)/\(snapshot.missions.count)")
                    .font(.caption2.weight(.bold))
                    .monospacedDigit()
            }
            HStack(spacing: .space2XS) {
                ForEach(snapshot.missions) { mission in
                    UsageBar(
                        ratio: mission.progress,
                        height: 4, color: mission.isCompleted ? .positive : .retroOrange)
                }
            }
        }
    }
}

struct AchievementBlock: View {
    let achievement: JourneySnapshot.Achievement

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceXS) {
            WidgetLabel("Next Achievement")
            HStack(spacing: .spaceS) {
                SymbolBadge(achievement.symbol, color: .retroMustard, size: 28)
                VStack(alignment: .leading, spacing: .space2XS) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(verbatim: achievement.title)
                            .font(.caption.weight(.bold))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Text("+\(achievement.xp) XP")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: .spaceXS) {
                        UsageBar(ratio: achievement.progress, height: 4, color: .retroMustard)
                        Text(verbatim: "\(achievement.value)/\(achievement.target)")
                            .font(.widgetRow.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct Countdown: View {
    let deadline: Date

    init(to deadline: Date) {
        self.deadline = deadline
    }

    var body: some View {
        Text(timerInterval: min(Date.now, deadline)...deadline, countsDown: true)
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
            .lineLimit(1)
    }
}
