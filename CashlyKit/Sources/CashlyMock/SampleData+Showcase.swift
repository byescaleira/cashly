import CashlyDomain
import Foundation

extension SampleData {
    public static let salary = CashlyDomain.Category(
        id: "showcase-salary", user: owner, name: "Salary", color: "2A7069",
        icon: "briefcase.fill")

    public static var showcaseCategories: [CashlyDomain.Category] { categories + [salary] }

    public static func showcaseBudgets(today: Date = .now) -> [Budget] {
        let limits: [(category: Int, amount: Int64)] = [
            (3, 1_750_00), (0, 650_00), (1, 380_00), (2, 260_00), (5, 120_00), (6, 60_00),
            (7, 40_00), (8, 200_00),
        ]
        let current = YearMonth(today)
        return (0...11).flatMap { offset in
            let month = current.adding(months: -offset)
            return limits.map { limit in
                Budget(
                    id: "showcase-budget-\(month.rawValue)-\(limit.category)",
                    money: Money(minorUnits: limit.amount), category: categories[limit.category],
                    month: month, summary: "Monthly plan", currencyCode: "USD")
            }
        }
    }

    public static func showcaseTransactions(today: Date = .now) -> [CashlyDomain.Transaction] {
        let current = YearMonth(today)
        let day = CashlyCalendar.current.component(.day, from: today)
        return (0...11).flatMap { offset in
            let month = current.adding(months: -offset)
            return showcaseEntries(offset: offset).compactMap {
                entry -> CashlyDomain.Transaction? in
                let isCurrent = offset == 0
                guard entry.day <= month.dayCount, !isCurrent || entry.day <= day || entry.isBill
                else { return nil }
                let pending = isCurrent && entry.day > day
                let status: TransactionStatus =
                    pending ? (entry.isIncome ? .pendingToReceive : .pendingToPay) : .settled
                return showcaseTransaction(entry, month: month, status: status)
            }
        }
    }

    private struct ShowcaseEntry {
        var key: String
        var category: CashlyDomain.Category
        var day: Int
        var amount: Int64
        var summary: String
        var isBill = false
        var isIncome = false
        var friends: [(user: Int, status: TransactionStatus)] = []
    }

    private static func showcaseEntries(offset: Int) -> [ShowcaseEntry] {
        func vary(_ base: Int64, _ seed: Int, spread: Int64) -> Int64 {
            let mixed = (offset * 7_919 + seed * 104_729) % 1_000
            return base + (Int64(mixed) * spread * 2 / 1_000) - spread
        }
        var entries: [ShowcaseEntry] = [
            ShowcaseEntry(
                key: "salary", category: salary, day: 1, amount: 5_200_00, summary: "Salary",
                isIncome: true),
            ShowcaseEntry(
                key: "rent", category: categories[3], day: 1, amount: 1_450_00, summary: "Rent",
                isBill: true),
            ShowcaseEntry(
                key: "transit", category: categories[2], day: 2, amount: 90_00,
                summary: "Transit pass", isBill: true),
            ShowcaseEntry(
                key: "gym", category: categories[5], day: 5, amount: 45_00,
                summary: "Gym membership", isBill: true),
            ShowcaseEntry(
                key: "netflix", category: categories[6], day: 8, amount: 15_49, summary: "Netflix",
                isBill: true),
            ShowcaseEntry(
                key: "course", category: categories[7], day: 10, amount: 29_00,
                summary: "Spanish course", isBill: true),
            ShowcaseEntry(
                key: "spotify", category: categories[6], day: 14, amount: 11_99, summary: "Spotify",
                isBill: true),
            ShowcaseEntry(
                key: "power", category: categories[3], day: 20,
                amount: vary(82_00, 1, spread: 12_00),
                summary: "Electricity bill", isBill: true),
            ShowcaseEntry(
                key: "internet", category: categories[3], day: 24, amount: 59_99,
                summary: "Internet", isBill: true),
            ShowcaseEntry(
                key: "phone", category: categories[3], day: 27, amount: 35_00,
                summary: "Phone plan", isBill: true),
            ShowcaseEntry(
                key: "household", category: categories[3], day: 13,
                amount: vary(38_00, 2, spread: 14_00), summary: "Amazon household order"),
            ShowcaseEntry(
                key: "uber-1", category: categories[2], day: 6,
                amount: vary(21_00, 3, spread: 7_00),
                summary: "Uber to downtown"),
            ShowcaseEntry(
                key: "gas", category: categories[2], day: 12, amount: vary(46_00, 4, spread: 8_00),
                summary: "Gas"),
            ShowcaseEntry(
                key: "uber-2", category: categories[2], day: 16,
                amount: vary(18_00, 5, spread: 6_00),
                summary: "Uber home"),
            ShowcaseEntry(
                key: "uber-3", category: categories[2], day: 25,
                amount: vary(24_00, 6, spread: 8_00),
                summary: "Uber to the airport"),
        ]
        let groceries = ["Whole Foods", "Trader Joe's", "Farmers market", "Costco run"]
        for (index, day) in [3, 7, 11, 15, 19, 23, 27].enumerated() {
            entries.append(
                ShowcaseEntry(
                    key: "groceries-\(index)", category: categories[0], day: day,
                    amount: vary(84_00, 10 + index, spread: 28_00),
                    summary: groceries[index % groceries.count]))
        }
        let meals = [
            "Lunch with Bruno", "Ramen bar", "Pizza night", "Tacos", "Burger joint",
            "Dinner at Nonna's", "Thai takeout",
        ]
        for (index, day) in [4, 9, 13, 17, 21, 26, 29].enumerated() {
            entries.append(
                ShowcaseEntry(
                    key: "meal-\(index)", category: categories[1], day: day,
                    amount: vary(29_00, 20 + index, spread: 11_00), summary: meals[index]))
        }
        for (index, day) in [2, 8, 14, 22].enumerated() {
            entries.append(
                ShowcaseEntry(
                    key: "coffee-\(index)", category: categories[1], day: day,
                    amount: vary(5_25, 40 + index, spread: 75), summary: "Starbucks Coffee"))
        }
        if offset % 2 == 1 {
            entries.append(
                ShowcaseEntry(
                    key: "pharmacy", category: categories[5], day: 18,
                    amount: vary(24_00, 30, spread: 9_00), summary: "Pharmacy"))
        }
        if offset % 3 == 2 {
            entries.append(
                ShowcaseEntry(
                    key: "clothes", category: categories[8], day: 22,
                    amount: vary(78_00, 31, spread: 20_00), summary: "Zara jacket"))
        }
        switch offset {
        case 0:
            entries += [
                ShowcaseEntry(
                    key: "birthday-dinner", category: categories[1], day: 6, amount: 186_00,
                    summary: "Birthday dinner",
                    friends: [(0, .pendingToReceive), (1, .settled)]),
                ShowcaseEntry(
                    key: "sushi", category: categories[1], day: 12, amount: 96_40,
                    summary: "Sushi with Emma"),
                ShowcaseEntry(
                    key: "brunch", category: categories[1], day: 16, amount: 58_00,
                    summary: "Sunday brunch"),
                ShowcaseEntry(
                    key: "shoes", category: categories[8], day: 9, amount: 119_99,
                    summary: "Nike running shoes"),
            ]
        case 1:
            entries.append(
                ShowcaseEntry(
                    key: "concert", category: categories[6], day: 19, amount: 84_00,
                    summary: "Concert tickets"))
        case 2:
            entries.append(
                ShowcaseEntry(
                    key: "gift", category: categories[9], day: 11, amount: 65_00,
                    summary: "Birthday gift for Carla"))
        case 4:
            entries += [
                ShowcaseEntry(
                    key: "flight", category: categories[4], day: 8, amount: 642_00,
                    summary: "Flight to Lisbon"),
                ShowcaseEntry(
                    key: "hotel", category: categories[4], day: 15, amount: 480_00,
                    summary: "Hotel in Lisbon"),
            ]
        case 10:
            entries.append(
                ShowcaseEntry(
                    key: "holiday-gifts", category: categories[9], day: 18, amount: 210_00,
                    summary: "Holiday gifts"))
        default:
            break
        }
        return entries
    }

    private static func showcaseTransaction(
        _ entry: ShowcaseEntry, month: YearMonth, status: TransactionStatus
    ) -> CashlyDomain.Transaction {
        let id = "showcase-\(month.rawValue)-\(entry.key)"
        let date =
            CashlyCalendar.current.date(
                from: DateComponents(
                    year: month.year, month: month.month, day: entry.day, hour: 12 + entry.day % 8,
                    minute: (entry.day * 13) % 60)) ?? month.startDate
        let total = Money(minorUnits: entry.amount)
        var shares = entry.friends.enumerated().map { index, friend in
            Participant(
                id: "\(id)-friend-\(index)", user: users[friend.user], splitMode: .equal,
                splitValue: Double(entry.friends.count + 1), status: friend.status,
                transaction: id)
        }
        let allocation = try? TransactionAllocation.resolve(total: total, participants: shares)
        for index in shares.indices {
            shares[index].allocatedMoney = allocation?.participants[shares[index].id]
        }
        return CashlyDomain.Transaction(
            id: id, participants: shares, category: entry.category, money: total, date: date,
            summary: entry.summary, status: status, splitMode: shares.isEmpty ? nil : .equal,
            splitValue: shares.isEmpty ? nil : allocation?.owner.doubleValue, paymentsPlan: nil,
            ownerMoney: shares.isEmpty ? nil : allocation?.owner,
            tagIDs: Set(
                tags.filter { TagSuggestion.matches($0.name, in: entry.summary) }.map(\.id)),
            kind: entry.isIncome ? .income : .expense, currencyCode: "USD")
    }
}
