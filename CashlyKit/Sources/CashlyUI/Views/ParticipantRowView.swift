import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import CashlyResource
import Foundation
import SwiftUI

struct ParticipantRowView: View {

    @Binding var participant: Participant
    var amount: Double

    var body: some View {
        CashlyHStack(spacing: .medium) {
            iconView
            contentView
            Spacer()
            splitValueView
                .contentTransition(.numericText())
        }
        .animation(.linear, value: amount)
    }

    var iconView: some View {
        CashlyResourceImage.avatar(id: participant.user.photo)
            .resizable()
            .scaledToFit()
            .frame(width: 50, height: 50)
            .overlay(alignment: .topTrailing) { transactionStatusView }
    }

    var contentView: some View {
        CashlyVStack(alignment: .leading, spacing: .extraSmall) {
            CashlyText(participant.user.name.capitalized)
                .cashly(font: .body, weight: .semibold)
                .cashly(color: .text)

            CashlyText(participant.status.summary)
                .cashly(font: .body)
                .cashly(color: .textSecondary)
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var transactionStatusView: some View {
        Menu {
            Picker(selection: $participant.status) {
                ForEach(TransactionStatus.allCases) {
                    CashlyText($0.summary)
                        .tag($0)
                }
            } label: {
                EmptyView()
            }
        } label: {
            CashlySymbol(participant.status.icon)
                .cashly(font: .caption2, weight: .bold)
                .cashly(color: .white)
                .cashlyPadding(.extraSmall)
                .cashly(background: .color(participant.status.color))
                .cashly(clip: .circle)
                .cashlyPadding(.negative(.extraSmall))
        }
    }

    @ViewBuilder
    var splitValueView: some View {
        switch participant.splitMode {
        case .equal: amountValueView
        case .fixedAmount: fixedAmountValueView
        case .percentage: percentageValueView
        case .payerBased: payerBasedValueView
        }
    }

    var amountValueView: some View {
        CashlyText(
            participant.allocatedMoney?.formatted
                ?? participant.splitMode.value(splitValue: participant.splitValue, amount: amount)?
                .currency())
    }

    var fixedAmountValueView: some View {
        CashlyCurrencyTextField(amount: $participant.splitValue)
            .cashly(font: .body, weight: .semibold)
            .cashly(color: .text)
            .cashly(alignment: .trailing)
    }

    var percentageValueView: some View {
        Menu {
            Picker(selection: $participant.splitValue) {
                ForEach(1...100, id: \.self) { value in
                    CashlyText((value.double / 100).double.percentage)
                        .tag(value.double / 100)
                }
            } label: {
                EmptyView()
            }
        } label: {
            CashlyVStack(alignment: .trailing, spacing: .extraSmall) {
                amountValueView
                CashlyHStack(spacing: .extraSmall) {
                    CashlyText(participant.splitValue.percentage)
                        .cashly(font: .body, weight: .semibold)
                        .cashly(color: .primary)
                    CashlySymbol("chevron.up.chevron.down")
                        .cashly(font: .caption, weight: .semibold)
                        .cashly(color: .primary)
                }
            }
        }
    }

    var payerBasedValueView: some View {
        CashlySymbol("checkmark.seal.text.page.fill")
            .cashly(font: .system(size: 30), weight: .semibold)
            .cashly(color: .color(.accentColor.opacity(0.75)))
    }

}
