import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct CurrencyChoiceSheet: View {
    @Environment(SettingsModel.self) private var settings
    let choice: CurrencyChoice

    var body: some View {
        GuideSheet(
            index: 0, count: 1,
            primary: GuideAction(
                "Use \(settings.currencyName(choice.to))",
                isEnabled: !settings.isFetchingCorrection
            ) {
                Task { await settings.confirmCurrencyChoice() }
            },
            secondary: GuideAction("Cancel", isEnabled: !settings.isFetchingCorrection) {
                settings.cancelCurrencyChoice()
            }
        ) {
            GuidePage(
                title: "Switch to \(settings.currencyName(choice.to))?",
                message: "Amounts are shown converted"
            ) {
                CurrencySwapArt(choice: choice)
            } content: {
                GuideFeatureList {
                    ForEach(settings.choiceNotes(choice)) {
                        GuideFeature(title: $0.title, detail: $0.detail)
                    }
                }
                if settings.isFetchingCorrection {
                    ProgressView("Getting exchange rates…")
                }
            }
        }
        .interactiveDismissDisabled(settings.isFetchingCorrection)
    }
}

private struct CurrencySwapArt: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.appTint) private var appTint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSwapped = false
    let choice: CurrencyChoice

    var body: some View {
        VStack(spacing: .spaceL) {
            HStack(spacing: .spaceM) {
                CurrencySymbolBadge(symbol: settings.currencySymbol(choice.from), size: .badgeXL)
                    .opacity(isSwapped ? .opacitySoft : 1)
                Image(systemName: "arrow.right")
                    .font(.icon(.m, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .symbolEffect(.bounce, value: isSwapped)
                CurrencySymbolBadge(symbol: settings.currencySymbol(choice.to), size: .badgeXL)
                    .scaleEffect(isSwapped ? 1 : 0.8)
                    .opacity(isSwapped ? 1 : .opacitySoft)
            }
            Text(verbatim: settings.currencySample(isSwapped ? choice.to : choice.from))
                .font(.amountTitle)
                .foregroundStyle(isSwapped ? appTint : Color.primary)
                .contentTransition(.interpolate)
                .amountLine()
        }
        .task {
            guard !reduceMotion else {
                isSwapped = true
                return
            }
            try? await Task.sleep(for: .milliseconds(700))
            withAnimation(.bouncy) { isSwapped = true }
        }
    }
}
