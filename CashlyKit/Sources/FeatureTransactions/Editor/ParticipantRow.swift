import CashlyDesignSystem
import CashlyDomain
import CashlyResource
import FeatureCore
import SwiftUI

struct ParticipantRow: View {
    @Binding var participant: Participant
    let amount: Double

    var body: some View {
        AdaptiveRow {
            CashlyResourceImage.avatar(id: participant.user.photo)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .overlay(alignment: .topTrailing) { StatusMenu(status: $participant.status) }
            VStack(alignment: .leading, spacing: .space2XS) {
                Text(participant.user.name.capitalized)
                    .font(.rowTitle)
                    .foregroundStyle(Color.primary)
                Text(participant.status.summary).foregroundStyle(Color.secondary)
            }
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            ShareValue(participant: $participant, amount: amount)
                .contentTransition(.numericText())
        }
        .animation(.linear, value: amount)
    }
}

private struct StatusMenu: View {
    @Binding var status: TransactionStatus

    var body: some View {
        Menu {
            Picker(selection: $status) {
                ForEach(TransactionStatus.allCases) { Text($0.summary).tag($0) }
            } label: {
                EmptyView()
            }
        } label: {
            Image(systemName: status.icon)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .padding(.space2XS)
                .background(status.color, in: .circle)
                .padding(-.space2XS)
        }
        .accessibilityLabel("Status: \(status.summary)")
    }
}

private struct ShareValue: View {
    @Environment(\.appTint) private var appTint

    @Binding var participant: Participant
    let amount: Double

    var body: some View {
        switch participant.splitMode {
        case .equal:
            allocated
        case .fixedAmount:
            CurrencyField(amount: $participant.splitValue)
                .font(.rowTitle)
                .multilineTextAlignment(.trailing)
        case .percentage:
            Menu {
                Picker(selection: $participant.splitValue) {
                    ForEach(1...100, id: \.self) { value in
                        Text(
                            (Double(value) / 100).formatted(.percent.precision(.fractionLength(0)))
                        )
                        .tag(Double(value) / 100)
                    }
                } label: {
                    EmptyView()
                }
            } label: {
                VStack(alignment: .trailing, spacing: .space2XS) {
                    allocated
                    HStack(spacing: .space2XS) {
                        Text(
                            participant.splitValue.formatted(.percent.precision(.fractionLength(0)))
                        )
                        .font(.buttonLabel)
                        Image(systemName: "chevron.up.chevron.down").font(
                            .caption.weight(.semibold))
                    }
                    .foregroundStyle(appTint)
                }
            }
        case .payerBased:
            Image(systemName: "checkmark.seal.text.page.fill")
                .font(.icon(.l, weight: .semibold))
                .foregroundStyle(appTint.opacity(.opacityStrong))
                .accessibilityLabel("Quem pagou")
        }
    }

    private var allocated: some View {
        Text(
            participant.allocatedMoney?.formatted
                ?? participant.splitMode.value(splitValue: participant.splitValue, amount: amount)?
                .formatted(.appCurrency) ?? ""
        )
        .amountLine()
    }
}
