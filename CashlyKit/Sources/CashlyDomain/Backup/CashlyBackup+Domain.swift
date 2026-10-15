import Foundation

extension CashlyBackup {
    public init(
        users: [User], categories: [Category], tags: [Tag], budgets: [Budget],
        transactions: [Transaction], exportedAt: Date = .now
    ) {
        format = Self.format
        version = Self.version
        currency = Money.currencyCode
        self.exportedAt = exportedAt
        self.users = users.map {
            UserRecord(id: $0.id, name: $0.name, photo: $0.photo.encoded, photoData: $0.photo.data)
        }
        self.categories = categories.map {
            LabelRecord(
                id: $0.id, userID: $0.user.id, name: $0.name, color: $0.color, icon: $0.icon)
        }
        self.tags = tags.map {
            LabelRecord(
                id: $0.id, userID: $0.user.id, name: $0.name, color: $0.color, icon: $0.icon)
        }
        self.budgets = budgets.map {
            BudgetRecord(
                id: $0.id, categoryID: $0.category.id, month: $0.month.rawValue,
                amount: $0.money.minorUnits, summary: $0.summary)
        }
        self.transactions = transactions.map(TransactionRecord.init)
    }

    public func entities() throws -> BackupEntities {
        let users = try index(
            users.map {
                User(
                    id: $0.id, name: $0.name,
                    photo: ProfilePhoto(encoded: $0.photo, data: $0.photoData))
            })
        let categories = try index(
            categories.map {
                Category(
                    id: $0.id, user: try require(users[$0.userID]), name: $0.name, color: $0.color,
                    icon: $0.icon)
            })
        let tags = try tags.map {
            Tag(
                id: $0.id, user: try require(users[$0.userID]), name: $0.name, color: $0.color,
                icon: $0.icon)
        }
        let budgets = try budgets.map {
            Budget(
                id: $0.id, money: Money(minorUnits: $0.amount),
                category: try require(categories[$0.categoryID]),
                month: try require(YearMonth(rawValue: $0.month)), summary: $0.summary)
        }
        let transactions = try transactions.map { try $0.transaction(users, categories) }
        return BackupEntities(
            users: users.values.sorted { $0.id < $1.id },
            categories: categories.values.sorted { $0.id < $1.id }, tags: tags, budgets: budgets,
            transactions: transactions)
    }

    public var recordCount: Int {
        users.count + categories.count + tags.count + budgets.count + transactions.count
    }

    private func index<Value: Identifiable>(_ values: [Value]) throws -> [String: Value]
    where Value.ID == String {
        try Dictionary(values.map { ($0.id, $0) }) { _, _ in
            throw CashlyError.invalidInput(
                String(appLocalized: "The backup has duplicate records."))
        }
    }
}

extension CashlyBackup.TransactionRecord {
    init(_ transaction: Transaction) {
        id = transaction.id
        categoryID = transaction.category.id
        kind = transaction.kind.rawValue
        amount = transaction.money.minorUnits
        date = transaction.date
        summary = transaction.summary
        status = transaction.status.rawValue
        splitMode = transaction.splitMode?.rawValue
        splitValue = transaction.participants.isEmpty ? nil : transaction.splitValue
        paymentsPlan = transaction.paymentsPlan
        tagIDs = transaction.tagIDs.sorted()
        participants = transaction.participants.map {
            CashlyBackup.ParticipantRecord(
                id: $0.id, userID: $0.user.id, splitMode: $0.splitMode.rawValue,
                splitValue: $0.splitValue, status: $0.status.rawValue)
        }
    }

    func transaction(_ users: [String: User], _ categories: [String: Category]) throws
        -> Transaction
    {
        let participants = try participants.map {
            Participant(
                id: $0.id, user: try require(users[$0.userID]),
                splitMode: try require(TransactionSplitMode(rawValue: $0.splitMode)),
                splitValue: $0.splitValue,
                status: try require(TransactionStatus(rawValue: $0.status)), transaction: id)
        }
        return Transaction(
            id: id, participants: participants, category: try require(categories[categoryID]),
            money: Money(minorUnits: amount), date: date, summary: summary,
            status: try require(TransactionStatus(rawValue: status)),
            splitMode: try splitMode.map { try require(TransactionSplitMode(rawValue: $0)) },
            splitValue: splitValue, paymentsPlan: paymentsPlan, tagIDs: Set(tagIDs),
            kind: try require(TransactionKind(rawValue: kind)))
    }
}

private func require<Value>(_ value: Value?) throws -> Value {
    guard let value else {
        throw CashlyError.invalidInput(
            String(appLocalized: "The backup has incomplete references."))
    }
    return value
}
