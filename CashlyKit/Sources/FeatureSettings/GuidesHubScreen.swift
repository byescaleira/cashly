import CashlyDesignSystem
import FeatureCore
import SwiftUI

public struct GuidesHubScreen: View {
    @Environment(SessionModel.self) private var session

    public init() {}

    public var body: some View {
        ModelHost(GuidesModel(session: session)) { GuidesHub() }
    }
}

private struct GuidesHub: View {
    @Environment(GuidesModel.self) private var guides
    @Environment(SessionModel.self) private var session

    var body: some View {
        ScrollView {
            VStack(spacing: .spaceXL) {
                GuidesProgress()
                GuidesNext()
                ForEach(GuideCategory.allCases) { GuidesCategory(category: $0) }
            }
            .padding(.horizontal, .spaceInset)
            .padding(.vertical, .spaceL)
        }
        .readableWidth()
        .background(.groupedBackground)
        .fontDesign(.rounded)
        .navigationTitle("Guides")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .task(id: session.generation) { await guides.load() }
    }
}

private struct GuidesProgress: View {
    @Environment(GuidesModel.self) private var guides
    @Environment(\.appTint) private var appTint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFilled = false

    var body: some View {
        let animation: Animation? = reduceMotion ? nil : .smooth(duration: 1)
        VStack(alignment: .leading, spacing: .spaceS) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(guides.doneCount) of \(guides.total) guides done")
                    .font(.rowTitle)
                    .monospacedDigit()
                Spacer()
                Text(remaining).font(.rowDetail).foregroundStyle(.secondary)
            }
            .lineLimit(1)
            ProgressView(value: isFilled ? guides.fraction : 0)
                .tint(appTint)
                .animation(animation, value: isFilled)
                .animation(animation, value: guides.fraction)
            Text("Finish every guide to earn the Studious achievement.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.spaceL)
        .background(.groupedRow, in: .rect(cornerRadius: .radiusL))
        .accessibilityElement(children: .combine)
        .task { isFilled = true }
    }

    private var remaining: LocalizedStringKey {
        guides.isComplete ? "All done" : "About \(guides.remainingMinutes) min left"
    }
}

private struct GuidesNext: View {
    @Environment(GuidesModel.self) private var guides
    @Environment(\.showGuide) private var showGuide
    @Environment(\.appTint) private var appTint

    var body: some View {
        VStack(spacing: .spaceM) {
            if let next = guides.next {
                Chip("Next for you", color: appTint, shape: .capsule).textCase(.uppercase)
                CashlyAnimationView(next.animation).frame(maxWidth: 260)
                VStack(spacing: .spaceXS) {
                    Text(verbatim: next.title).font(.titleMedium)
                    Text(verbatim: next.subtitle).font(.body).foregroundStyle(.secondary)
                }
                Button("Start · \(next.minutes) min") { showGuide?(next) }
                    .primaryButton()
            } else {
                CashlyAnimationView(.done).frame(maxWidth: 260)
                VStack(spacing: .spaceXS) {
                    Text("Every guide done").font(.titleMedium)
                    Text("Come back whenever you want a refresher.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.spaceL)
        .background(.groupedRow, in: .rect(cornerRadius: .radiusL))
        .animation(.smooth, value: guides.next)
    }
}

private struct GuidesCategory: View {
    @Environment(GuidesModel.self) private var guides
    let category: GuideCategory

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceS) {
            HStack(alignment: .firstTextBaseline) {
                Text(verbatim: category.title).font(.headline)
                Spacer()
                Text(verbatim: "\(guides.doneCount(in: category))/\(guides.total(in: category))")
                    .font(.rowDetail)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal, .spaceS)
            ForEach(category.guides) { GuideCard(guide: $0) }
        }
    }
}

private struct GuideCard: View {
    @Environment(GuidesModel.self) private var guides
    @Environment(\.showGuide) private var showGuide
    @Environment(\.appTint) private var appTint
    @Environment(\.pro) private var pro
    let guide: Guide

    var body: some View {
        let isDone = guides.isDone(guide)
        Button {
            showGuide?(guide)
        } label: {
            HStack(spacing: .spaceM) {
                CashlyAnimationView(guide.animation, isStill: true)
                    .frame(width: 96)
                    .padding(.spaceXS)
                    .background(appTint.opacity(.opacityFill), in: .rect(cornerRadius: .radiusS))
                    .allowsHitTesting(false)
                VStack(alignment: .leading, spacing: .space2XS) {
                    Text(verbatim: guide.title).font(.rowTitle)
                    Text(verbatim: guide.subtitle).font(.rowDetail).foregroundStyle(.secondary)
                    Label("\(guide.minutes) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: .spaceS)
                if guide.requiresPro, !pro.isPro {
                    Chip("Pro", color: .retroMustard)
                } else {
                    GuideMark(isDone: isDone)
                }
            }
            .multilineTextAlignment(.leading)
            .padding(.spaceM)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .background(.groupedRow, in: .rect(cornerRadius: .radiusM))
        .accessibilityValue(value(isDone: isDone))
    }
}

extension GuideCard {
    fileprivate func value(isDone: Bool) -> Text {
        if guide.requiresPro, !pro.isPro { return Text("Requires Cashly Pro") }
        return isDone ? Text("Done") : Text(verbatim: "")
    }
}

private struct GuideMark: View {
    let isDone: Bool

    var body: some View {
        if isDone {
            Image(systemName: "checkmark.circle.fill")
                .font(.icon(.m, weight: .semibold))
                .foregroundStyle(Color.retroOlive)
        } else {
            Image(systemName: "chevron.forward")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }
}
