import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct TransactionRow: View {
    let transaction: CashlyDomain.Transaction

    var body: some View {
        HStack(spacing: 16) {
            AdaptiveRow {
                TransactionIcon(transaction: transaction)
                TransactionSummary(transaction: transaction)
                TransactionAmounts(transaction: transaction)
            }
            Image(systemName: "chevron.forward").foregroundStyle(.disabled)
        }
    }
}

private struct TransactionSummary: View {
    let transaction: CashlyDomain.Transaction

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(transaction.summary)
            HStack {
                Text(transaction.date.formatted(.dateTime.hour().minute()))
                ParticipantDots(participants: transaction.participants)
            }
            .foregroundStyle(Color.secondary)
        }
        .font(.callout)
        .lineLimit(3)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TransactionAmounts: View {
    @Environment(TransactionListModel.self) private var list
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let transaction: CashlyDomain.Transaction

    var body: some View {
        VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: 4) {
            if !transaction.participants.isEmpty {
                Text(list.billing(of: transaction).formatted)
            } else if let plan = transaction.paymentsPlan {
                HStack(spacing: 4) {
                    Text("\(plan)x").foregroundStyle(Color.secondary)
                    Text(list.billing(of: transaction).formatted)
                }
            }
            Text(transaction.money.formatted)
                .foregroundStyle(
                    transaction.isSplitOrInstallment ? Color.secondary : Color.primary)
        }
        .font(.callout.weight(.semibold))
        .amountLine()
        .fixedSize(horizontal: !dynamicTypeSize.isAccessibilitySize, vertical: false)
    }
}

private struct TransactionIcon: View {
    let transaction: CashlyDomain.Transaction

    var body: some View {
        let color = Color(hex: transaction.category.color)
        Image(systemName: transaction.category.icon)
            .font(.system(size: 18))
            .foregroundStyle(color)
            .frame(width: 40, height: 40)
            .background(color.opacity(0.2), in: .circle)
            .overlay(alignment: .bottomTrailing) {
                if transaction.status != .settled {
                    Image(systemName: transaction.status.icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(transaction.status.color, in: .circle)
                        .padding([.bottom, .trailing], -4)
                        .accessibilityLabel(transaction.status.summary)
                }
            }
    }
}

private struct ParticipantDots: View {
    let participants: [Participant]

    var body: some View {
        if !participants.isEmpty {
            HStack(spacing: 0) {
                ForEach(participants) { participant in
                    Circle()
                        .fill(participant.status.color)
                        .frame(width: 10, height: 10)
                        .padding(.trailing, 2)
                }
            }
            .accessibilityHidden(true)
        }
    }
}

extension CashlyDomain.Transaction {
    fileprivate var isSplitOrInstallment: Bool { !participants.isEmpty || paymentsPlan != nil }
}
