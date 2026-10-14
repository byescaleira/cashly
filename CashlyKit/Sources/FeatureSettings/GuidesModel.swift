import CashlyDomain
import FeatureCore
import Observation

@MainActor @Observable
public final class GuidesModel {
    public private(set) var done: Set<Guide> = []
    public private(set) var hasLoaded = false
    @ObservationIgnored private let session: SessionModel

    public init(session: SessionModel) {
        self.session = session
    }

    public var total: Int { Guide.allCases.count }

    public var doneCount: Int { done.count }

    public var fraction: Double { total > 0 ? Double(doneCount) / Double(total) : 0 }

    public var isComplete: Bool { doneCount >= total }

    public var next: Guide? { Guide.allCases.first { !done.contains($0) } }

    public var remainingMinutes: Int {
        Guide.allCases.filter { !done.contains($0) }.reduce(0) { $0 + $1.minutes }
    }

    public func isDone(_ guide: Guide) -> Bool { done.contains(guide) }

    public func doneCount(in category: GuideCategory) -> Int {
        category.guides.filter(done.contains).count
    }

    public func load() async {
        let events = (try? await session.repositories.game.events()) ?? []
        done = Set(
            events.filter { $0.kind == .guideCompleted }.compactMap { Guide(rawValue: $0.value) })
        hasLoaded = true
    }
}
