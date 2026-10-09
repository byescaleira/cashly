import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct TopSpendingSection: View {
    @Environment(FinanceModel.self) private var finance
    @Environment(DashboardModel.self) private var dashboard

    var body: some View {
        @Bindable var dashboard = dashboard
        let transactions = finance.biggestTransactions
        if !transactions.isEmpty {
            Section {
                TabView(selection: $dashboard.highlightedTransaction) {
                    ForEach(transactions.enumerated(), id: \.offset) { index, transaction in
                        let color = Color(hex: transaction.category.color)
                        VStack(spacing: 8) {
                            Spacer()
                            Text(transaction.category.name.uppercased())
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(color)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(color.opacity(0.2), in: .capsule)
                            Text(dashboard.billing(of: transaction).formatted)
                                .font(.title.weight(.bold))
                                .foregroundStyle(Color.primary)
                            Text(transaction.summary).foregroundStyle(Color.secondary)
                            Spacer()
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 50)
                        .tag(index)
                    }
                }
                .frame(height: 170)
                .padding(.horizontal, -20)
                .animation(.bouncy, value: dashboard.highlightedTransaction)
                #if os(iOS)
                    .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
            } header: {
                HStack {
                    Text("Maiores gastos").sectionTitle()
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(transactions.indices, id: \.self) { index in
                            Circle()
                                .frame(width: 8, height: 8)
                                .foregroundStyle(
                                    index == dashboard.highlightedTransaction
                                        ? Color.accentColor : Color.primary.opacity(0.1))
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.secondary.opacity(0.2), in: .capsule)
                    .accessibilityHidden(true)
                }
            }
        }
    }
}
