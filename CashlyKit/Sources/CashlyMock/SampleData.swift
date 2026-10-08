import CashlyDomain
import Foundation

public enum SampleData {
    public static let users: [User] = [
        User(id: "550e8400-e29b-41d4-a716-446655440000", name: "Alice Johnson", photo: "58"),
        User(id: "123e4567-e89b-12d3-a456-426614174000", name: "Bruno Silva", photo: "41"),
        User(id: "9b2f6c4e-3c21-4e7b-9d45-b6d0d8d6faaa", name: "Carla Mendes", photo: "91"),
        User(id: "f47ac10b-58cc-4372-a567-0e02b2c3d479", name: "David Thompson", photo: "45"),
        User(id: "7c9e6679-7425-40de-944b-e07fc1f90ae7", name: "Emma Rossi", photo: "73"),
    ]

    public static let owner = users[3]

    public static let categories: [CashlyDomain.Category] = [
        CashlyDomain.Category(
            id: "1a2b3c4d-1111-2222-3333-444455556666", user: owner, name: "Groceries",
            color: "34C759",
            icon: "cart.fill"),
        CashlyDomain.Category(
            id: "2b3c4d5e-2222-3333-4444-555566667777", user: owner, name: "Restaurants",
            color: "FF9500",
            icon: "fork.knife"),
        CashlyDomain.Category(
            id: "3c4d5e6f-3333-4444-5555-666677778888", user: owner, name: "Transport",
            color: "007AFF",
            icon: "car.fill"),
        CashlyDomain.Category(
            id: "4d5e6f7a-4444-5555-6666-777788889999", user: owner, name: "Housing",
            color: "8E8E93",
            icon: "house.fill"),
        CashlyDomain.Category(
            id: "5e6f7a8b-5555-6666-7777-888899990000", user: owner, name: "Travel",
            color: "AF52DE",
            icon: "airplane"),
        CashlyDomain.Category(
            id: "6f7a8b9c-6666-7777-8888-999900001111", user: owner, name: "Health",
            color: "FF3B30",
            icon: "heart.fill"),
        CashlyDomain.Category(
            id: "7a8b9c0d-7777-8888-9999-000011112222", user: owner, name: "Entertainment",
            color: "FF2D55",
            icon: "film.fill"),
        CashlyDomain.Category(
            id: "8b9c0d1e-8888-9999-0000-111122223333", user: owner, name: "Education",
            color: "5856D6",
            icon: "book.fill"),
        CashlyDomain.Category(
            id: "9c0d1e2f-9999-0000-1111-222233334444", user: owner, name: "Clothing",
            color: "00C7BE",
            icon: "tshirt.fill"),
        CashlyDomain.Category(
            id: "0d1e2f3a-0000-1111-2222-333344445555", user: owner, name: "Gifts", color: "FFD60A",
            icon: "gift.fill"),
    ]

    public static let tags: [Tag] = [
        Tag(
            id: "973745e7-605f-4ff9-96c2-0cd7c0a3049e", user: owner, name: "Coffee",
            color: "FF9500",
            icon: "cup.and.saucer.fill"),
        Tag(
            id: "92c8399c-de09-4c24-8141-2b8d4f199ec7", user: owner, name: "Starbucks",
            color: "34C759",
            icon: "leaf.fill"),
        Tag(
            id: "598b48ad-1e29-4fdb-8899-47fa9ac7eddf", user: owner, name: "Nike", color: "007AFF",
            icon: "tshirt.fill"),
        Tag(
            id: "43d5de1b-be6f-4a6d-9565-18181a53aa88", user: owner, name: "Netflix",
            color: "FF2D55",
            icon: "film.fill"),
        Tag(
            id: "684b1864-3372-494a-b1c0-dfc4bafe2b65", user: owner, name: "Uber", color: "8E8E93",
            icon: "car.fill"),
        Tag(
            id: "66bd0e29-867a-4c1f-ad64-d2c61d006bfd", user: owner, name: "Apple", color: "5856D6",
            icon: "laptopcomputer.and.iphone"),
        Tag(
            id: "304b33e3-75f8-4a40-8331-09dc2de64c40", user: owner, name: "Amazon",
            color: "FF3B30",
            icon: "cart.fill"),
        Tag(
            id: "d892be08-6498-4788-885c-eec70db8bf6b", user: owner, name: "Gym", color: "AF52DE",
            icon: "dumbbell.fill"),
        Tag(
            id: "305db5d6-c78c-4152-9624-0dfcbaf7ff99", user: owner, name: "Spotify",
            color: "00C7BE",
            icon: "music.note.list"),
        Tag(
            id: "22ab9818-0e49-450f-9bdc-8481dcf17097", user: owner, name: "Zara", color: "FFD60A",
            icon: "bag.fill"),
    ]

    public static let budgets: [Budget] = [
        budget(
            "a1b2c3d4-1111-2222-3333-444455556666", 120.5, category: 0, date: 1_735_787_400,
            "Weekly grocery shopping at the local supermarket including fruits, vegetables, and dairy products"
        ),
        budget(
            "b2c3d4e5-2222-3333-4444-555566667777", 45.9, category: 1, date: 1_735_880_700,
            "Dinner with friends at a nearby Italian restaurant, including drinks and appetizers"),
        budget(
            "c3d4e5f6-3333-4444-5555-666677778888", 60.0, category: 2, date: 1_735_966_500,
            "Monthly gas refill for the car and toll charges during daily commute"),
        budget(
            "d4e5f607-4444-5555-6666-777788889999", 850.0, category: 3, date: 1_735_795_200,
            "Monthly rent payment for the apartment including water and maintenance fees"),
        budget(
            "e5f60718-5555-6666-7777-888899990000", 300.0, category: 4, date: 1_736_552_400,
            "Flight booking to New York for business trip, including baggage fee"),
        budget(
            "f6071829-6666-7777-8888-999900001111", 75.25, category: 5, date: 1_736_076_000,
            "Purchase of prescription medications and vitamins at the pharmacy"),
        budget(
            "0718293a-7777-8888-9999-000011112222", 120.0, category: 6, date: 1_736_235_600,
            "Movie night tickets for friends, including popcorn and drinks"),
        budget(
            "18293a4b-8888-9999-0000-111122223333", 200.0, category: 7, date: 1_735_971_000,
            "Subscription for online courses and learning materials for skill improvement"),
        budget(
            "293a4b5c-9999-0000-1111-222233334444", 90.0, category: 8, date: 1_736_136_000,
            "Purchase of new shoes and casual clothes for upcoming events"),
        budget(
            "3a4b5c6d-0000-1111-2222-333344445555", 150.0, category: 9, date: 1_736_305_200,
            "Birthday present for a friend, including gift wrapping and card"),
    ]

    public static let transactions: [CashlyDomain.Transaction] = [
        transaction(
            "t1a2b3c4-1111-2222-3333-444455556666", 23.15, category: 0, date: 1_735_787_400,
            "Weekly grocery shopping", status: 0,
            participants: [
                ("11111111-aaaa-4bbb-cccc-1234567890ab", 0, 2),
                ("22222222-bbbb-4ccc-dddd-1234567890ab", 1, 0),
            ]),
        transaction(
            "t2b3c4d5-2222-3333-4444-555566667777", 61.7, category: 1, date: 1_735_787_400,
            "Dinner with friends", status: 3,
            participants: [("33333333-cccc-4ddd-eeee-1234567890ab", 2, 2)]),
        transaction(
            "t3c4d5e6-3333-4444-5555-666677778888", 116.23, category: 2, date: 1_735_966_500,
            "Monthly gas refill", status: 2, participants: []),
        transaction(
            "t4d5e6f7-4444-5555-6666-777788889999", 455.72, category: 3, date: 1_735_795_200,
            "Monthly rent payment", status: 0,
            participants: [("55555555-eeee-4fff-aaaa-1234567890ab", 4, 0)]),
        transaction(
            "t5e6f708-5555-6666-7777-888899990000", 381.48, category: 4, date: 1_736_552_400,
            "Flight to New York", status: 3, participants: []),
        transaction(
            "t6f70819-6666-7777-8888-999900001111", 25.13, category: 5, date: 1_736_076_000,
            "Pharmacy purchase", status: 2, participants: []),
        transaction(
            "t7a8192b-7777-8888-9999-000011112222", 250.22, category: 6, date: 1_736_235_600,
            "Movie night tickets", status: 0, participants: []),
        transaction(
            "t8b9203c-8888-9999-0000-111122223333", 200.0, category: 7, date: 1_735_971_000,
            "Online course subscription", status: 3, participants: []),
        transaction(
            "t9c0314d-9999-0000-1111-222233334444", 68.89, category: 8, date: 1_736_136_000,
            "New shoes purchase", status: 2, participants: []),
        transaction(
            "t10d1425-0000-1111-2222-333344445555", 140.52, category: 9, date: 1_736_305_200,
            "Birthday present", status: 0, participants: []),
    ]

    private static func money(_ amount: Double) -> Money {
        Money(minorUnits: Int64((amount * 100).rounded()))
    }

    private static func budget(
        _ id: String, _ amount: Double, category: Int, date: TimeInterval, _ summary: String
    ) -> Budget {
        Budget(
            id: id, money: money(amount), category: categories[category],
            month: YearMonth(Date(timeIntervalSince1970: date)), summary: summary)
    }

    private static func transaction(
        _ id: String, _ amount: Double, category: Int, date: TimeInterval, _ summary: String,
        status: Int, participants: [(id: String, user: Int, status: Int)]
    ) -> CashlyDomain.Transaction {
        let total = money(amount)
        var shares = participants.map {
            Participant(
                id: $0.id, user: users[$0.user], splitMode: .equal,
                splitValue: Double(participants.count + 1),
                status: TransactionStatus(rawValue: $0.status) ?? .settled, transaction: id)
        }
        let allocation = try? TransactionAllocation.resolve(total: total, participants: shares)
        for index in shares.indices {
            shares[index].allocatedMoney = allocation?.participants[shares[index].id]
        }
        return CashlyDomain.Transaction(
            id: id, participants: shares, category: categories[category], money: total,
            date: Date(timeIntervalSince1970: date), summary: summary,
            status: TransactionStatus(rawValue: status) ?? .settled,
            splitMode: shares.isEmpty ? nil : .equal,
            splitValue: shares.isEmpty ? nil : allocation?.owner.doubleValue, paymentsPlan: nil,
            ownerMoney: shares.isEmpty ? nil : allocation?.owner,
            tagIDs: Set(tags.filter { TagSuggestion.matches($0.name, in: summary) }.map(\.id)))
    }
}
