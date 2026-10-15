import CashlyDesignSystem
import CashlyDomain
import SwiftUI
import WidgetKit

nonisolated struct JourneyEntry: TimelineEntry {
    let date: Date
    let snapshot: JourneySnapshot?
}

nonisolated struct JourneyProvider: TimelineProvider {
    func placeholder(in context: Context) -> JourneyEntry {
        JourneyEntry(date: .now, snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (JourneyEntry) -> Void) {
        completion(JourneyEntry(date: .now, snapshot: context.isPreview ? .sample : .current()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<JourneyEntry>) -> Void) {
        let snapshot = JourneySnapshot.current()
        let calendar = Calendar.current
        let tomorrow =
            calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now)) ?? .now
        let entries = [
            JourneyEntry(date: .now, snapshot: snapshot),
            JourneyEntry(date: tomorrow, snapshot: snapshot),
        ]
        completion(Timeline(entries: entries, policy: .after(tomorrow)))
    }
}

struct JourneyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: JourneySnapshot.kind, provider: JourneyProvider()) { entry in
            JourneyView(entry: entry)
                .containerBackground(.background, for: .widget)
                .widgetURL(URL(string: "cashly://journey"))
        }
        .configurationDisplayName("Journey")
        .description("Level, streak, weekly missions and your challenge.")
        .supportedFamilies(journeyFamilies)
    }
}

private var journeyFamilies: [WidgetFamily] {
    #if os(iOS)
        [
            .systemSmall, .systemMedium, .systemLarge, .accessoryCircular,
            .accessoryRectangular, .accessoryInline,
        ]
    #else
        [.systemSmall, .systemMedium, .systemLarge]
    #endif
}

private struct JourneyView: View {
    let entry: JourneyEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            switch snapshot.status {
            case .active: JourneyLayout(snapshot: snapshot, date: entry.date)
            case .paused:
                JourneyMessage(
                    symbol: "pause.circle", title: "Journey Paused",
                    detail:
                        "Your progress is kept. Subscribe to keep earning XP, streaks and achievements."
                )
            case .hidden:
                JourneyMessage(
                    symbol: "trophy", title: "Journey Off",
                    detail: "Turn the Journey on in Cashly › Settings.")
            }
        } else {
            JourneyMessage(
                symbol: "trophy", title: "Journey", detail: "Open Cashly to start your journey.")
        }
    }
}

private struct JourneyLayout: View {
    @Environment(\.widgetFamily) private var family
    let snapshot: JourneySnapshot
    let date: Date

    var body: some View {
        switch family {
        #if os(iOS)
            case .accessoryCircular, .accessoryRectangular, .accessoryInline:
                LockScreenJourney(snapshot: snapshot, date: date)
        #endif
        case .systemMedium: MediumJourney(snapshot: snapshot, date: date)
        case .systemLarge: LargeJourney(snapshot: snapshot, date: date)
        default: SmallJourney(snapshot: snapshot, date: date)
        }
    }
}

private struct JourneyMessage: View {
    @Environment(\.widgetFamily) private var family
    let symbol: String
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        switch family {
        #if os(iOS)
            case .accessoryInline:
                Label {
                    Text(title)
                } icon: {
                    Image(systemName: symbol)
                }
            case .accessoryCircular:
                Image(systemName: symbol).font(.title2).widgetAccentable()
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: .space2XS) {
                    Label {
                        Text(title)
                    } icon: {
                        Image(systemName: symbol)
                    }
                    .font(.headline)
                    .widgetAccentable()
                    Text(detail).font(.caption).lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
        #endif
        default:
            JourneyNotice(symbol: symbol, title: title, detail: detail)
        }
    }
}

private struct LevelHeader: View {
    let level: JourneySnapshot.Level
    let font: Font

    var body: some View {
        VStack(alignment: .leading, spacing: .space2XS) {
            JourneyTag(level.title.uppercased(), color: .retroOrange)
            Text("Level \(level.number)")
                .font(font)
                .fontDesign(.rounded)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

private struct XPBar: View {
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
            JourneyBar(value: level.progress, color: .retroOrange)
        }
    }
}

private struct StreakCount: View {
    let streak: JourneySnapshot.Streak
    let date: Date

    var body: some View {
        let isDone = streak.isDone(on: date)
        HStack(spacing: .space2XS) {
            Image(systemName: isDone ? "flame.fill" : "flame")
            Text(verbatim: streak.current.formatted())
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(streak.current)))
        }
        .font(.subheadline.weight(.bold))
        .fontDesign(.rounded)
        .foregroundStyle(isDone ? Color.retroOrange : Color.secondary)
        .lineLimit(1)
    }
}

private struct StreakRow: View {
    let streak: JourneySnapshot.Streak
    let date: Date
    var size: CGFloat = .badgeS

    var body: some View {
        let isDone = streak.isDone(on: date)
        HStack(spacing: .spaceS) {
            StreakFlame(isDone: isDone, size: size)
            VStack(alignment: .leading, spacing: .spaceHairline) {
                Text("\(streak.current) days")
                    .font(.headline)
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

private struct ChallengeLine: View {
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
                JourneyBar(value: challenge.progress, color: challenge.color, height: 4)
            }
        }
    }
}

private struct MissionsLine: View {
    let snapshot: JourneySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: .space2XS) {
            HStack {
                JourneyLabel("This Week")
                Spacer(minLength: 0)
                Text(verbatim: "\(snapshot.missionsDone)/\(snapshot.missions.count)")
                    .font(.caption2.weight(.bold))
                    .monospacedDigit()
            }
            HStack(spacing: .space2XS) {
                ForEach(snapshot.missions) { mission in
                    JourneyBar(
                        value: mission.progress,
                        color: mission.isCompleted ? .positive : .retroOrange, height: 4)
                }
            }
        }
    }
}

private struct SmallJourney: View {
    let snapshot: JourneySnapshot
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceXS) {
            HStack(alignment: .top) {
                LevelHeader(level: snapshot.level, font: .title2.weight(.bold))
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
                LevelHeader(level: snapshot.level, font: .title.weight(.bold))
                XPBar(level: snapshot.level)
                Spacer(minLength: 0)
                StreakRow(streak: snapshot.streak, date: date)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: .spaceXS) {
                if let challenge = snapshot.challenge {
                    ChallengeBlock(challenge: challenge, snapshot: snapshot, date: date)
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
                LevelHeader(level: snapshot.level, font: .largeTitle.weight(.bold))
                Spacer(minLength: .spaceS)
                StreakRow(streak: snapshot.streak, date: date, size: .badgeM)
                    .fixedSize()
            }
            XPBar(level: snapshot.level, showsRemaining: true)
            MissionList(snapshot: snapshot, isCompact: false)
            Spacer(minLength: 0)
            if let challenge = snapshot.challenge {
                ChallengeBlock(challenge: challenge, snapshot: snapshot, date: date)
            } else if let achievement = snapshot.nextAchievement {
                AchievementBlock(achievement: achievement)
            }
        }
    }
}

private struct MissionList: View {
    let snapshot: JourneySnapshot
    let isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? .spaceXS : .spaceS) {
            HStack {
                JourneyLabel("This Week")
                Spacer(minLength: 0)
                JourneyTag(
                    "\(snapshot.missionsDone)/\(snapshot.missions.count)",
                    color: snapshot.missionsDone == snapshot.missions.count
                        ? .positive : .retroOrange)
            }
            ForEach(snapshot.missions) { mission in
                MissionRow(mission: mission, isCompact: isCompact)
            }
        }
    }
}

private struct MissionRow: View {
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
                    JourneyBar(value: mission.progress, color: color, height: 4)
                    Text(verbatim: "\(mission.value)/\(mission.target)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct ChallengeBlock: View {
    let challenge: JourneySnapshot.Challenge
    let snapshot: JourneySnapshot
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceXS) {
            HStack {
                JourneyLabel("Challenge")
                Spacer(minLength: 0)
                JourneyTag("+\(challenge.xp) XP", color: challenge.tint.color)
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
            ChallengeFigures(challenge: challenge, date: date)
            JourneyBar(value: challenge.progress, color: challenge.color, marker: challenge.elapsed)
            if let paceTitle = challenge.paceTitle {
                Label {
                    Text(verbatim: paceTitle)
                } icon: {
                    Image(systemName: challenge.paceSymbol)
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(challenge.color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
        }
    }
}

private struct AchievementBlock: View {
    let achievement: JourneySnapshot.Achievement

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceXS) {
            JourneyLabel("Next Achievement")
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
                        JourneyBar(value: achievement.progress, color: .retroMustard, height: 4)
                        Text(verbatim: "\(achievement.value)/\(achievement.target)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#if os(iOS)
    private struct LockScreenJourney: View {
        @Environment(\.widgetFamily) private var family
        let snapshot: JourneySnapshot
        let date: Date

        var body: some View {
            let streak = snapshot.streak
            let flame = streak.isDone(on: date) ? "flame.fill" : "flame"
            switch family {
            case .accessoryCircular:
                VStack(spacing: .spaceHairline) {
                    Image(systemName: flame).font(.caption.weight(.bold)).widgetAccentable()
                    Text(verbatim: streak.current.formatted())
                        .font(.headline.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    JourneyBar(
                        value: snapshot.challenge?.progress ?? snapshot.level.progress,
                        color: .primary, height: 4
                    )
                    .frame(width: 34)
                }
            case .accessoryInline:
                Label {
                    Text(
                        "\(Text("\(streak.current) days")) · \(Text("Level \(snapshot.level.number)"))"
                    )
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
                    Image(systemName: flame).widgetAccentable()
                    Text(verbatim: snapshot.streak.current.formatted())
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
                        JourneyBar(value: challenge.progress, color: .primary, height: 5)
                        Text(verbatim: challenge.shortMeasure(currencyCode: snapshot.currencyCode))
                            .font(.footnote.monospacedDigit())
                            .lineLimit(1)
                    }
                } else {
                    Text(verbatim: snapshot.level.title).font(.footnote).lineLimit(1)
                    Spacer(minLength: 0)
                    HStack(spacing: .spaceS) {
                        JourneyBar(value: snapshot.level.progress, color: .primary, height: 5)
                        Text(verbatim: "\(snapshot.missionsDone)/\(snapshot.missions.count)")
                            .font(.footnote.monospacedDigit())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
#endif

extension JourneySnapshot {
    nonisolated static func current() -> JourneySnapshot? {
        try? JourneySnapshotStore.shared?.read()
    }
}

#Preview("Small", as: .systemSmall) {
    JourneyWidget()
} timeline: {
    JourneyEntry(date: .now, snapshot: .sample)
    JourneyEntry(date: .now, snapshot: .sample.withoutChallenge)
}

#Preview("Medium", as: .systemMedium) {
    JourneyWidget()
} timeline: {
    JourneyEntry(date: .now, snapshot: .sample)
    JourneyEntry(date: .now, snapshot: .sample.withoutChallenge)
    JourneyEntry(date: .now, snapshot: .sample.with(status: .paused))
}

#Preview("Large", as: .systemLarge) {
    JourneyWidget()
} timeline: {
    JourneyEntry(date: .now, snapshot: .sample)
    JourneyEntry(date: .now, snapshot: .sample.withoutChallenge)
    JourneyEntry(date: .now, snapshot: nil)
}

#if os(iOS)
    #Preview("Rectangular", as: .accessoryRectangular) {
        JourneyWidget()
    } timeline: {
        JourneyEntry(date: .now, snapshot: .sample)
        JourneyEntry(date: .now, snapshot: .sample.withoutChallenge)
    }

    #Preview("Circular", as: .accessoryCircular) {
        JourneyWidget()
    } timeline: {
        JourneyEntry(date: .now, snapshot: .sample)
    }

    #Preview("Inline", as: .accessoryInline) {
        JourneyWidget()
    } timeline: {
        JourneyEntry(date: .now, snapshot: .sample)
    }
#endif
