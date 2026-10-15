import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct WidgetsHowToSection: View {
    @Environment(WidgetsModel.self) private var widgets
    @Environment(\.showGuide) private var showGuide
    @Environment(\.featureFlags) private var flags

    var body: some View {
        Section {
            ForEach(Array(widgets.addSteps.enumerated()), id: \.offset) { index, step in
                WidgetStepRow(number: index + 1, text: step)
            }
            if let showGuide, flags?.isOn(.guides) != false {
                WidgetGuideRow { showGuide(.widgets) }
            }
        } header: {
            Text("How to Add").sectionTitle()
        } footer: {
            Text(verbatim: widgets.galleryFooter)
        }
    }
}

private struct WidgetStepRow: View {
    @Environment(\.appTint) private var appTint
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: .spaceM) {
            Text(verbatim: "\(number)")
                .font(.chipLabel)
                .monospacedDigit()
                .foregroundStyle(appTint)
                .frame(width: .badgeS, height: .badgeS)
                .background(appTint.opacity(.opacityTint), in: .circle)
                .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + .space2XS }
            Text(verbatim: text)
        }
    }
}

private struct WidgetGuideRow: View {
    @Environment(\.appTint) private var appTint
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .spaceM) {
                CashlyAnimationView(.widgets, isStill: true)
                    .frame(width: .badgeXL * 1.5)
                    .padding(.spaceXS)
                    .background(appTint.opacity(.opacityFill), in: .rect(cornerRadius: .radiusS))
                VStack(alignment: .leading, spacing: .space2XS) {
                    Text(verbatim: Guide.widgets.title).font(.rowTitle)
                    Label("\(Guide.widgets.minutes) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: .spaceS)
                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
