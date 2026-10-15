import CashlyDomain
import Foundation
import Testing

struct BackupFormatTests {
    private let owner = User(id: "owner", name: "Perfil")
    private let friend = User(id: "friend", name: "Amigo")

    private func sample() throws -> CashlyBackup {
        let category = Category(id: "c", user: owner, name: "Geral", color: "0099FF", icon: "cart")
        let tag = Tag(id: "t", user: owner, name: "Viagem", color: "FF9900", icon: "airplane")
        let month = try #require(YearMonth(rawValue: 202_601))
        let budget = Budget(
            id: "b", money: Money(minorUnits: 50_000), category: category, month: month,
            summary: "Mercado")
        let participant = Participant(
            id: "p", user: friend, splitMode: .equal, splitValue: 2, status: .pendingToReceive,
            transaction: "x")
        let transaction = Transaction(
            id: "x", participants: [participant], category: category,
            money: Money(minorUnits: 10_001), date: Date(timeIntervalSince1970: 1_767_225_600),
            summary: "Jantar", status: .settled, splitMode: .equal, splitValue: 50.01,
            paymentsPlan: 3, tagIDs: ["t"])
        return CashlyBackup(
            users: [owner, friend], categories: [category], tags: [tag], budgets: [budget],
            transactions: [transaction], exportedAt: Date(timeIntervalSince1970: 1_767_225_600))
    }

    @Test func encodedBackupReadsBackTheSameRecords() throws {
        let backup = try sample()
        let decoded = try CashlyBackup(data: backup.encoded())
        #expect(decoded == backup)
        #expect(decoded.recordCount == 6)
        let entities = try decoded.entities()
        let transaction = try #require(entities.transactions.first)
        #expect(transaction.money == Money(minorUnits: 10_001))
        #expect(transaction.participants.first?.user == friend)
        #expect(transaction.tagIDs == ["t"])
        #expect(transaction.paymentsPlan == 3)
        #expect(entities.budgets.first?.user == owner)
    }

    @Test func missingReferenceIsRejected() throws {
        var backup = try sample()
        backup.users.removeAll { $0.id == "friend" }
        #expect(throws: CashlyError.invalidInput("The backup has incomplete references.")) {
            try backup.entities()
        }
    }

    @Test func profilePhotosTravelInsideTheBackup() throws {
        let ana = User(id: "ana", name: "Ana", photo: .illustration("dogs-03"))
        let bia = User(id: "bia", name: "Bia", photo: .symbol("cat.fill", color: "B23A48"))
        let backup = CashlyBackup(
            users: [ana, bia], categories: [], tags: [], budgets: [], transactions: [])
        let decoded = try CashlyBackup(data: backup.encoded())
        #expect(decoded.users.first { $0.id == "ana" }?.photo == "illustration:dogs-03")
        #expect(try decoded.entities().users == [ana, bia])
    }

    @Test func oldAvatarNumbersOpenWithInitials() throws {
        let json = """
            {"format":"cashly-backup","version":1,"currency":"BRL",\
            "exportedAt":"2026-10-01T12:00:00Z",\
            "users":[{"id":"ana","name":"Ana Souza","photo":"58"}],\
            "categories":[],"tags":[],"budgets":[],"transactions":[]}
            """
        let backup = try CashlyBackup(data: Data(json.utf8))
        let user = try #require(backup.entities().users.first)
        #expect(user.photo == .default)
        #expect(user.initials == "AS")
    }

    @Test func otherFilesAndNewerVersionsAreRejected() throws {
        #expect(throws: CashlyError.invalidInput("This file isn't a Cashly backup.")) {
            try CashlyBackup(data: Data("{\"name\":\"x\"}".utf8))
        }
        var backup = try sample()
        backup.version = CashlyBackup.version + 1
        let data = try backup.encoded()
        #expect(throws: CashlyError.self) { try CashlyBackup(data: data) }
    }
}
