import CashlyDesignSystem
import CashlyDomain
import SwiftUI

extension JourneySnapshot.Tint {
    var color: Color {
        switch self {
        case .orange: .retroOrange
        case .olive: .retroOlive
        case .teal: .retroTeal
        case .denim: .retroDenim
        case .mustard: .retroMustard
        case .rust: .retroRust
        }
    }
}

extension JourneySnapshot.Challenge {
    var color: Color { tone.color }

    var paceSymbol: String {
        switch pace {
        case .steady: "checkmark.circle"
        case .fast: "hare"
        case .over: "exclamationmark.triangle"
        case nil: "hourglass"
        }
    }

    func shortMeasure(currencyCode: String) -> String {
        switch unit {
        case .money:
            (Decimal(value) / 100).formatted(
                .currency(code: currencyCode).precision(.fractionLength(0)))
        case .score: value.formatted()
        case .days, .count: "\(min(value, target))/\(target)"
        }
    }
}

struct JourneyLabel: View {
    let key: LocalizedStringKey

    init(_ key: LocalizedStringKey) {
        self.key = key
    }

    var body: some View {
        Text(key)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .lineLimit(1)
    }
}

struct JourneyTag: View {
    let text: String
    let color: Color

    init(_ text: String, color: Color) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(verbatim: text)
            .font(.caption2.weight(.heavy))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, .spaceXS)
            .padding(.vertical, .spaceHairline)
            .background(color.opacity(.opacityTint), in: .rect(cornerRadius: .space2XS))
    }
}

struct JourneyBar: View {
    let value: Double
    let color: Color
    var height: CGFloat = 6
    var marker: Double?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(color)
                    .frame(width: proxy.size.width * min(max(value, 0), 1))
                if let marker {
                    Capsule()
                        .fill(Color.primary.opacity(.opacityStrong))
                        .frame(width: .spaceHairline, height: height + .space2XS)
                        .offset(x: proxy.size.width * min(max(marker, 0), 1) - 1)
                }
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

struct StreakFlame: View {
    let isDone: Bool
    var size: CGFloat = .badgeS

    var body: some View {
        SymbolBadge(
            isDone ? "flame.fill" : "flame", color: .retroOrange, size: size,
            style: isDone ? .filled : .tinted)
    }
}

struct ChallengeFigures: View {
    let challenge: JourneySnapshot.Challenge
    let date: Date
    var font: Font = .caption2

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: .spaceXS) {
            Text(verbatim: challenge.measure)
                .font(font.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(challenge.color)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
            DaysLeft(challenge: challenge, date: date)
                .font(font)
                .foregroundStyle(.secondary)
        }
        .lineLimit(1)
    }
}

struct DaysLeft: View {
    let challenge: JourneySnapshot.Challenge
    let date: Date

    var body: some View {
        Label {
            Text("\(challenge.daysLeft(at: date)) days left")
        } icon: {
            Image(systemName: "hourglass")
        }
        .labelStyle(DaysLeftStyle())
    }
}

private struct DaysLeftStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: .spaceHairline) {
            configuration.icon
            configuration.title
        }
    }
}

struct JourneyNotice: View {
    let symbol: String
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        VStack(spacing: .spaceXS) {
            SymbolBadge(symbol, color: .retroMustard, size: .badgeM)
            Text(title).font(.subheadline.weight(.bold)).fontDesign(.rounded)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
