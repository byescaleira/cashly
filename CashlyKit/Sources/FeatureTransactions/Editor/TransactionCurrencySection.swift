import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct TransactionCurrencySection: View {
    @Environment(TransactionEditorModel.self) private var model

    var body: some View {
        Section {
            if let estimate = model.estimateDescription {
                Label {
                    Text(estimate).font(.footnote).privacySensitive()
                } icon: {
                    Image(systemName: "arrow.left.arrow.right").foregroundStyle(.secondary)
                }
            } else {
                PaidCurrencyLink()
                if model.draft.isForeign { ExchangeRateRow() }
            }
        } header: {
            Text("Currency").sectionTitle()
        } footer: {
            if model.showsExchangeNotice { ExchangeNotice() }
        }
    }
}

private struct PaidCurrencyLink: View {
    @Environment(TransactionEditorModel.self) private var model
    @Environment(\.pro) private var pro

    var body: some View {
        NavigationLink {
            CurrencyPickerScreen(
                "Paid In", codes: model.paidCurrencies, suggested: model.suggestedPaidCurrencies,
                locked: model.lockedPaidCurrencies(with: pro),
                lockedReason: "Paying in other currencies needs Cashly Pro.",
                selection: model.draft.paidCurrency
            ) { model.selectPaidCurrency($0, pro: pro) }
        } label: {
            LabeledContent("Paid In") {
                Text(verbatim: CurrencyText.label(model.draft.paidCurrency))
            }
        }
    }
}

private struct ExchangeRateRow: View {
    @Environment(TransactionEditorModel.self) private var model

    var body: some View {
        LabeledContent("Rate") {
            if let rate = model.rateDescription {
                Text(rate).multilineTextAlignment(.trailing)
            } else if model.rateFailed {
                Button("Try Again") { Task { await model.updateRate() } }
            } else {
                ProgressView()
            }
        }
        if model.rateFailed {
            Text("Couldn't get the rate for this date. Check your connection and try again.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
