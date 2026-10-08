import CashlyData
import CashlyDomain
import CashlyMock
import Darwin
import Foundation
import SwiftData

@main
struct CashlyAudit {
    @MainActor static func main() async {
        do { try await run() } catch {
            print("DIAGNOSTIC_FAILED: \(error.localizedDescription)")
            exit(1)
        }
    }
    @MainActor static func run() async throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let command = arguments.first else {
            print(
                "create-legacy <store> | audit <store> | benchmark <count> | profile <store> | preview"
            )
            return
        }
        let january = try yearMonth(202601).startDate
        switch command {
        case "create-legacy":
            guard arguments.count == 2 else {
                throw CashlyError.invalidInput("Informe o arquivo de destino.")
            }
            let url = URL(filePath: arguments[1])
            guard !FileManager.default.fileExists(atPath: url.path) else {
                throw CashlyError.invalidInput("O arquivo já existe.")
            }
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let schema = Schema(CashlySchemaV1.models)
            let configuration = ModelConfiguration(
                schema: schema, url: url, cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: configuration)
            let context = ModelContext(container)
            for id in ["owner", "friend"] {
                context.insert(CashlySchemaV1.UserEntity(id: id, name: id, photo: "person"))
            }
            context.insert(
                CashlySchemaV1.CategoryEntity(
                    id: "category", user: "owner", name: "Mercado", color: "0099FF", icon: "cart"))
            context.insert(
                CashlySchemaV1.BudgetEntity(
                    id: "budget", amount: 100.01, category: "category", date: 202601,
                    summary: "Mensal"))
            context.insert(
                CashlySchemaV1.TagEntity(
                    id: "tag", user: "owner", name: "Feira", color: "0099FF", icon: "tag"))
            context.insert(
                CashlySchemaV1.ParticipantEntity(
                    id: "party", user: "friend", name: "friend", photo: "person", splitMode: 0,
                    splitValue: 2,
                    status: 0, transaction: "transaction"))
            context.insert(
                CashlySchemaV1.TransactionEntity(
                    id: "transaction", participants: ["party"], budget: "budget", amount: 100.01,
                    date: january.timeIntervalSince1970, summary: "Compra Feira",
                    status: 0, splitMode: 0, splitValue: 50.005, paymentsPlan: 3))
            try context.save()
            print(
                "LEGACY_CREATED users=2 categories=1 budgets=1 tags=1 transactions=1 participants=1 amount=100.01"
            )
        case "audit":
            guard arguments.count == 2 else {
                throw CashlyError.invalidInput("Informe o armazenamento legado.")
            }
            let original = URL(filePath: arguments[1])
            let folder = FileManager.default.temporaryDirectory.appending(
                path: "cashly-audit-" + UUID().uuidString)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let copied = folder.appending(path: original.lastPathComponent)
            for suffix in ["", "-wal", "-shm"] {
                let source = URL(filePath: original.path + suffix)
                if FileManager.default.fileExists(atPath: source.path) {
                    try FileManager.default.copyItem(
                        at: source, to: URL(filePath: copied.path + suffix))
                }
            }
            let database = try CashlyDatabase.open(cloudSync: false, storeURL: copied)
            let context = ModelContext(database.modelContainer)
            let users = try await database.repositories(for: nil).users.users()
            for user in users {
                let dashboard = database.repositories(for: user.id).dashboard
                let state = try await dashboard.load(query: .init())
                let training = try await dashboard.trainingData()
                print(
                    "MIGRATED user=\(user.id) transactions=\(state.totalTransactionCount) loaded=\(state.page.items.count) pending=\(state.overview.pendingReferences) ownerMinor=\(state.overview.expensesTotal.minorUnits) budgetMinor=\(state.overview.budgetsTotal.minorUnits)"
                )
                for record in training.transactions {
                    let shares = try record.participants.reduce(record.attributedMoney) {
                        try $0.adding(record.participantMoney(id: $1.id))
                    }
                    let installments = try (0..<(record.paymentsPlan ?? 1)).reduce(Money.zero) {
                        try $0.adding(
                            record.attributedMoney.installment(
                                at: $1, count: record.paymentsPlan ?? 1))
                    }
                    print(
                        "RECORD id=\(record.id) originalMinor=\(record.money.minorUnits) sharesMinor=\(shares.minorUnits) ownerInstallmentsMinor=\(installments.minorUnits) tagIDs=\(record.tagIDs.sorted())"
                    )
                }
            }
            print(
                "COUNTS users=\(try context.fetchCount(FetchDescriptor<UserEntity>())) categories=\(try context.fetchCount(FetchDescriptor<CategoryEntity>())) budgets=\(try context.fetchCount(FetchDescriptor<BudgetEntity>())) tags=\(try context.fetchCount(FetchDescriptor<TagEntity>())) transactions=\(try context.fetchCount(FetchDescriptor<TransactionEntity>())) participants=\(try context.fetchCount(FetchDescriptor<ParticipantEntity>()))"
            )
            print("AUDIT_COPY \(copied.path)")
        case "preview":
            let database = try await SampleDatabase.make()
            let users = try await database.repositories(for: nil).users.users()
            var count = 0
            for user in users {
                count += try await database.repositories(for: user.id).dashboard
                    .load(query: .init()).totalTransactionCount
            }
            print("PREVIEW users=\(users.count) transactions=\(count)")
        case "profile":
            guard arguments.count == 2,
                URL(filePath: arguments[1]).lastPathComponent == "benchmark.store"
            else {
                throw CashlyError.invalidInput(
                    "Profile aceita somente benchmark.store gerado pelo diagnóstico.")
            }
            let database = try CashlyDatabase.open(
                cloudSync: false, storeURL: URL(filePath: arguments[1]))
            let service = database.repositories(for: "a").dashboard
            let clock = ContinuousClock()
            var start = clock.now
            let state = try await service.overview(query: .init(month: try yearMonth(202601)))
            print(
                "PROFILE overview=\(start.duration(to: clock.now)) count=\(state.transactionCount)")
            start = clock.now
            let revision = try await service.datasetRevision()
            print(
                "PROFILE revision=\(start.duration(to: clock.now)) fingerprint=\(revision.prefix(8))"
            )
            start = clock.now
            let page = try await service.page(
                query: .init(month: try yearMonth(202601)), after: nil, limit: 50)
            print("PROFILE firstPage=\(start.duration(to: clock.now)) items=\(page.items.count)")
        case "benchmark":
            let count = arguments.count > 1 ? Int(arguments[1]) ?? 1000 : 1000
            guard (1...100_000).contains(count) else {
                throw CashlyError.invalidInput("Volume permitido: 1…100000.")
            }
            let folder = FileManager.default.temporaryDirectory.appending(
                path: "cashly-benchmark-" + UUID().uuidString)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let database = try CashlyDatabase.open(
                cloudSync: false, storeURL: folder.appending(path: "benchmark.store"))
            let context = ModelContext(database.modelContainer)
            for id in ["a", "b"] {
                context.insert(UserEntity(id: id, name: id, photo: "person"))
                context.insert(
                    CategoryEntity(
                        id: "category-" + id, user: id, name: "Mercado", color: "0099FF",
                        icon: "cart"))
            }
            for id in ["a", "b"] {
                let budget = BudgetEntity(
                    id: "budget-" + id, amount: 1000, category: "category-" + id, date: 202601,
                    summary: "Mensal")
                budget.ownerID = id
                budget.amountMinorUnits = 100000
                budget.amountSource = 1000
                context.insert(budget)
            }
            for index in 0..<count {
                let owner = index.isMultiple(of: 2) ? "a" : "b"
                let row = TransactionEntity(
                    id: String(format: "%08d", index), participants: [], budget: "budget-" + owner,
                    amount: 10.01,
                    date: january.timeIntervalSince1970 + Double(index % 10),
                    summary: "Compra", status: 0)
                row.dateSource = row.date
                row.paymentsPlanSource = row.paymentsPlan
                row.ownerID = owner
                row.amountMinorUnits = 1001
                row.amountSource = 10.01
                row.ownerMinorUnits = 1001
                row.tagsMigrated = true
                row.startMonthIndex = 2026 * 12
                row.endMonthIndex = 2026 * 12
                row.contentRevision = UUID().uuidString
                context.insert(row)
                if index % 1000 == 999 { try context.save() }
            }
            try context.save()
            let repositories = database.repositories(for: "a")
            let service = repositories.dashboard
            let clock = ContinuousClock()
            var start = clock.now
            let state = try await service.load(query: .init(month: try yearMonth(202601)))
            print(
                "BENCH count=\(count) dashboard=\(start.duration(to: clock.now)) pageItems=\(state.page.items.count) total=\(state.overview.transactionCount) totalMinor=\(state.overview.expensesTotal.minorUnits)"
            )
            start = clock.now
            let detail = try await repositories.transactions.transaction(id: "00000000")
            print("DETAIL elapsed=\(start.duration(to: clock.now)) id=\(detail?.id ?? "nil")")
            start = clock.now
            let page = try await service.page(
                query: .init(month: try yearMonth(202601)), after: state.page.nextCursor, limit: 50)
            print(
                "PAGE elapsed=\(start.duration(to: clock.now)) items=\(page.items.count) overlaps=\(Set(page.items.map(\.id)).intersection(state.page.items.map(\.id)).count)"
            )
            let denied = try await database.repositories(for: "b").transactions.transaction(
                id: "00000000")
            print("ISOLATION foreignDetail=\(denied == nil ? "hidden" : "visible")")
            let duplicate = BudgetEntity(
                id: "duplicate", amount: 1500, category: "category-a", date: 202601,
                summary: "Outra versão"
            )
            duplicate.ownerID = "a"
            duplicate.amountMinorUnits = 150000
            duplicate.amountSource = 1500
            context.insert(duplicate)
            try context.save()
            let before = try await service.overview(query: .init(month: try yearMonth(202601)))
            try await repositories.budgets.resolveConflict(keeping: "budget-a")
            let after = try await service.overview(query: .init(month: try yearMonth(202601)))
            let archived = try context.fetchCount(
                FetchDescriptor<BudgetEntity>(predicate: #Predicate { $0.mergedIntoID != "" }))
            print(
                "CONFLICT before=\(before.conflicts.count) after=\(after.conflicts.count) preservedAliases=\(archived) budgetMinor=\(after.budgetsTotal.minorUnits)"
            )
            print("BENCH_STORE \(folder.path)")
        default: throw CashlyError.invalidInput("Comando desconhecido.")
        }
    }

    static func yearMonth(_ rawValue: Int) throws -> YearMonth {
        guard let value = YearMonth(rawValue: rawValue) else {
            throw CashlyError.invalidInput("Competência inválida no diagnóstico.")
        }
        return value
    }
}
