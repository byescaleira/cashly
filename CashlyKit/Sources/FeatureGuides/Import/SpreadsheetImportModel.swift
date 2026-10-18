import CashlyDomain
import FeatureCore
import Foundation
import Observation

@MainActor @Observable
public final class SpreadsheetImportModel {
    public enum Step: Int, CaseIterable, Sendable {
        case format, columns, file, review, done
    }

    public var step = Step.format
    public var isPickingFile = false
    public var isSharingTemplate = false
    public private(set) var preview: SpreadsheetPreview?
    public private(set) var fileName = ""
    public private(set) var newCategories: [String] = []
    public private(set) var newTags: [String] = []
    public private(set) var imported = 0
    public private(set) var isWorking = false
    public private(set) var isExternal = false
    public var error: CashlyError?
    @ObservationIgnored private let session: SessionModel
    @ObservationIgnored private var categories: [CashlyDomain.Category] = []
    @ObservationIgnored private var tags: [Tag] = []

    public init(session: SessionModel) {
        self.session = session
    }

    public var canGoBack: Bool {
        !isExternal && (step == .columns || step == .file || step == .review)
    }
    public var canImport: Bool { !(preview?.rows.isEmpty ?? true) }

    public func back() {
        switch step {
        case .columns: step = .format
        case .file: step = .columns
        case .review: step = .file
        case .format, .done: break
        }
    }

    public func read(_ result: Result<URL, any Error>) async {
        do {
            let url = try result.get()
            let isScoped = url.startAccessingSecurityScopedResource()
            defer { if isScoped { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            guard
                let text = String(data: data, encoding: .utf8)
                    ?? String(data: data, encoding: .isoLatin1)
            else {
                throw CashlyError.invalidInput(String(appLocalized: "This file isn't CSV text."))
            }
            await load(text, fileName: url.lastPathComponent)
        } catch {
            self.error =
                error as? CashlyError
                ?? .invalidInput(String(appLocalized: "Couldn't read the file."))
        }
    }

    public func load(_ text: String, fileName: String) async {
        await review(SpreadsheetParser.parse(text), source: fileName)
    }

    public func reviewExternal(_ preview: SpreadsheetPreview, source: String) async {
        isExternal = true
        await review(preview, source: source)
    }

    private func review(_ preview: SpreadsheetPreview, source fileName: String) async {
        do {
            let snapshot = try await session.repositories.dashboard.snapshot(month: nil)
            categories = snapshot.categories
            tags = snapshot.tags
            self.preview = preview
            self.fileName = fileName
            newCategories = preview.newCategories(existing: categories.map(\.name))
            newTags = preview.newTags(existing: tags.map(\.name))
            step = .review
        } catch {
            self.error = error as? CashlyError ?? .onFetch
        }
    }

    public func importRows() async {
        guard let preview, let user = session.user else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            let repositories = session.repositories
            var categoryByKey = Dictionary(
                categories.map { (SpreadsheetParser.key($0.name), $0) },
                uniquingKeysWith: { first, _ in first })
            var tagByKey = Dictionary(
                tags.map { (SpreadsheetParser.key($0.name), $0) },
                uniquingKeysWith: { first, _ in first })
            let palette = RetroColor.allCases
            for (offset, name) in newCategories.enumerated() {
                let category = CashlyDomain.Category(
                    id: UUID().uuidString, user: user, name: name,
                    color: palette[(offset * 5) % palette.count].hex, icon: "square.grid.2x2.fill")
                try await repositories.categories.save(category)
                categoryByKey[SpreadsheetParser.key(name)] = category
            }
            for name in newTags {
                let tag = Tag(
                    id: UUID().uuidString, user: user, name: name, color: RetroColor.default.hex,
                    icon: "tag.fill")
                try await repositories.tags.save(tag)
                tagByKey[SpreadsheetParser.key(name)] = tag
            }
            for row in preview.rows {
                guard let category = categoryByKey[SpreadsheetParser.key(row.category)] else {
                    continue
                }
                let transaction = CashlyDomain.Transaction(
                    id: UUID().uuidString, participants: [], category: category, money: row.money,
                    date: row.date, summary: row.summary, status: row.status, splitMode: nil,
                    splitValue: nil, paymentsPlan: row.installments > 1 ? row.installments : nil,
                    tagIDs: Set(row.tags.compactMap { tagByKey[SpreadsheetParser.key($0)]?.id }),
                    kind: row.kind)
                try await repositories.transactions.save(transaction)
                imported += 1
            }
            await session.record(.spreadsheetImported)
            session.reload()
            step = .done
        } catch {
            self.error = error as? CashlyError ?? .onSave
        }
    }
}
