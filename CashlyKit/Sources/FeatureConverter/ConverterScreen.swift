import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

public struct ConverterScreen: View {
    @Environment(ConverterModel.self) private var model

    public init() {}

    public var body: some View {
        Form {
            ConverterAmountHeader()
            ConverterCurrencySection()
            ConverterRateSection()
        }
        .fontDesign(.rounded)
        .readableWidth()
        .navigationTitle("Converter")
        #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { await model.loadCurrencies() }
        .task(id: model.from) { await model.load() }
    }
}

private struct ConverterAmountHeader: View {
    @Environment(ConverterModel.self) private var model
    @Environment(\.appTint) private var appTint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        @Bindable var model = model
        Section {
        } header: {
            VStack(spacing: .spaceS) {
                CurrencyField(amount: $model.amount, currencyCode: model.from)
                    .font(.amountInput)
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.center)
                    .tint(.clear)
                if model.isLoading && model.result == nil {
                    ProgressView()
                } else if model.result != nil {
                    Text(verbatim: model.resultText)
                        .font(.amountTitle)
                        .foregroundStyle(appTint)
                        .contentTransition(.numericText())
                        .animation(reduceMotion ? nil : .snappy, value: model.resultText)
                        .amountLine()
                        .accessibilityLabel("Converted Amount")
                        .accessibilityValue(model.resultText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spaceS)
        }
    }
}

private struct ConverterCurrencySection: View {
    @Environment(ConverterModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Section {
            NavigationLink {
                CurrencyPickerScreen(
                    "From", codes: model.currencies, suggested: model.suggested,
                    selection: model.from
                ) { model.choose(from: $0) }
            } label: {
                ConverterCurrencyRow(title: "From", code: model.from)
            }
            Button("Swap Currencies", systemImage: "arrow.up.arrow.down") {
                withAnimation(reduceMotion ? nil : .snappy) { model.swap() }
            }
            .sensoryFeedback(.selection, trigger: model.from)
            NavigationLink {
                CurrencyPickerScreen(
                    "To", codes: model.currencies, suggested: model.suggested,
                    selection: model.to
                ) { model.choose(to: $0) }
            } label: {
                ConverterCurrencyRow(title: "To", code: model.to)
            }
        }
    }
}

private struct ConverterCurrencyRow: View {
    let title: LocalizedStringKey
    let code: String

    var body: some View {
        HStack(spacing: .spaceM) {
            CurrencySymbolBadge(symbol: CurrencyText.symbol(code), size: .badgeS + .space2XS)
            VStack(alignment: .leading, spacing: .spaceHairline) {
                Text(title).font(.footnote).foregroundStyle(.secondary)
                Text(verbatim: CurrencyText.label(code))
                    .foregroundStyle(Color.primary)
            }
        }
    }
}

private struct ConverterRateSection: View {
    @Environment(ConverterModel.self) private var model

    var body: some View {
        Section {
            LabeledContent("Rate") {
                if let rate = model.rateText {
                    Text(rate)
                } else if model.isUnavailable {
                    Button("Try Again") { Task { await model.load() } }
                } else {
                    ProgressView()
                }
            }
            if let updated = model.updatedText {
                Text(updated).font(.footnote).foregroundStyle(.secondary)
            }
            if model.isUnavailable {
                Text("Couldn't get the latest rates. Check your connection and try again.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } footer: {
            ExchangeNotice()
        }
    }
}
