import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct CurrencyScreen: View {
    @Environment(SettingsModel.self) private var settings
    @State private var query = ""

    var body: some View {
        @Bindable var settings = settings
        SettingsPage("Currency") {
            CurrencyHeroSection()
            if query.isEmpty {
                CurrencyListSection(title: "Suggested", codes: settings.suggestedCurrencies())
                CurrencyListSection(title: "All Currencies", codes: settings.otherCurrencies())
            } else {
                CurrencySearchSection(codes: settings.currencies(matching: query), query: query)
            }
        }
        #if !os(macOS)
            .searchable(text: $query, prompt: Text("Search Currencies"))
        #endif
        .sensoryFeedback(.selection, trigger: settings.currency)
        .sheet(item: $settings.currencyChoice) { CurrencyChoiceSheet(choice: $0) }
    }
}

private struct CurrencyHeroSection: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.appTint) private var appTint

    var body: some View {
        Section {
            HStack(spacing: .spaceM) {
                SymbolBadge("equal", color: .retroOlive, size: .badgeM)
                VStack(alignment: .leading, spacing: .spaceHairline) {
                    Text("Amounts aren't converted").font(.rowTitle)
                    Text(
                        "Changing the currency changes only the symbol. The numbers you recorded stay the same, and new records use the new currency."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, .space2XS)
        } header: {
            SettingsHero {
                Chip(settings.currency, color: appTint, shape: .capsule)
                Text(verbatim: settings.currencySample(settings.currency))
                    .font(.amountHero)
                    .foregroundStyle(Color.primary)
                    .amountLine()
                    .contentTransition(.opacity)
                Text(verbatim: settings.currencyName(settings.currency))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .animation(.smooth, value: settings.currency)
        }
    }
}

private struct CurrencyListSection: View {
    let title: LocalizedStringKey
    let codes: [String]

    var body: some View {
        if !codes.isEmpty {
            Section {
                ForEach(Array(codes.enumerated()), id: \.element) { index, code in
                    CurrencyRow(code: code).settingsReveal(index)
                }
            } header: {
                Text(title)
            }
        }
    }
}

private struct CurrencySearchSection: View {
    let codes: [String]
    let query: String

    var body: some View {
        Section {
            if codes.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                ForEach(codes, id: \.self) { CurrencyRow(code: $0) }
            }
        }
    }
}

private struct CurrencyRow: View {
    @Environment(SettingsModel.self) private var settings
    let code: String

    var body: some View {
        let isSelected = settings.currency == code
        Button {
            settings.choose(currency: code)
        } label: {
            HStack(spacing: .spaceM) {
                CurrencySymbolBadge(
                    symbol: settings.currencySymbol(code), size: .badgeS + .space2XS)
                VStack(alignment: .leading, spacing: .spaceHairline) {
                    Text(verbatim: settings.currencyName(code)).foregroundStyle(Color.primary)
                    Text(verbatim: "\(code) · \(settings.currencySample(code))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: .spaceS)
                SelectionMark(isSelected: isSelected)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct CurrencySymbolBadge: View {
    @Environment(\.appTint) private var appTint
    let symbol: String
    let size: CGFloat

    var body: some View {
        Text(verbatim: symbol)
            .font(size > .badgeL ? .titleMedium : .callout.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .padding(.horizontal, .space2XS)
            .foregroundStyle(appTint)
            .frame(width: size, height: size)
            .background(appTint.opacity(.opacityTint), in: .rect(cornerRadius: .radiusS))
            .accessibilityHidden(true)
    }
}
