//
//  FilterItemView+DateMenu.swift
//  CashlyKit
//
//  Date filter sub-menu (month + year pickers + "Today" reset).
//

import SwiftUI
import CashlyResource

extension FilterItemView {
    @ViewBuilder
    var toggleDateMenu: some View {
        Menu {
            Toggle(isOn: store.cashlyBinding(\.filter).isFilteringByDate) {
                CashlyText(CashlyL10n.string("Filter by Date"))
            }

            if state.filter.isFilteringByDate {
                let months = Calendar.current.monthSymbols
                let currentYear = Date.now.string(with: .cashly(.year))?.int ?? .zero
                let years = ((currentYear - 5) ... (currentYear + 5))

                Divider()

                Menu {
                    Picker(selection: $month) {
                        ForEach(months, id: \.self) { month in
                            CashlyText(month.capitalized)
                                .tag(month)
                        }
                    } label: {
                        EmptyView()
                    }
                } label: {
                    CashlyText(state.filter.startDate.string(with: .cashly(.month))?.capitalized)
                }
                .onAppear {
                    month = month.isEmpty ? state.filter.startDate.string(with: .cashly(.month)) ?? "" : month
                    year = year == .zero ? state.filter.startDate.string(with: .cashly(.year))?.int ?? .zero : year
                }
                .onChange(of: month) { updateDate() }

                Menu {
                    Picker(selection: $year) {
                        ForEach(years, id: \.self) { year in
                            CashlyText(year.string)
                                .tag(year)
                        }
                    } label: {
                        EmptyView()
                    }
                } label: {
                    CashlyText(state.filter.startDate.string(with: .cashly(.year))?.capitalized)
                }
                .onChange(of: year) { updateDate() }

                if state.filter.startDate.timeIntervalSince1970.yearMonth != Date.now.timeIntervalSince1970.yearMonth {
                    Divider()

                    CashlyButton {
                        store.cashlyMutate(\.filter.startDate, .now)
                    } label: {
                        CashlyLabel(CashlyL10n.string("Today"), symbol: "location")
                    }
                }
            }
        } label: {
            CashlyLabel(CashlyL10n.string("Date"), symbol: "calendar")
        }
        .cashly(tint: .text)
    }

    func updateDate() {
        let month = month.date(with: .cashly(.month))?.string(with: .cashly(.numberMonth))?.int ?? 0
        let date = ((year * 100) + month).string.date(with: .cashly(.yearMonth)) ?? .now
        store.cashlyMutate(\.filter.startDate, date)
    }
}
