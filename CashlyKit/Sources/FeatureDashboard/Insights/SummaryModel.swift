import CashlyAnalytics
import CashlyAnalyticsAI
import CashlyDomain
import FeatureCore
import Foundation
import Observation

@MainActor @Observable
public final class SummaryModel {
    public typealias Narrate =
        @Sendable ([NarrationFact], String, Locale) async -> Result<Narration, NarrationError>

    public struct Line: Equatable, Identifiable {
        public let id: String
        public let section: String
        public let sentence: String
    }

    public struct Summary: Equatable {
        public let headline: String
        public let lines: [Line]
    }

    struct Key: Hashable {
        let facts: [NarrationFact]
        let context: String
        let locale: String
        let day: Date
    }

    private var narration: Narration?
    @ObservationIgnored private weak var insights: InsightsModel?
    @ObservationIgnored private let flags: FeatureFlags?
    @ObservationIgnored private let narrate: Narrate
    @ObservationIgnored private var cache: (key: Key, narration: Narration?)?

    public init(
        flags: FeatureFlags? = nil,
        narrate: @escaping Narrate = {
            await SystemNarrator.narrate(facts: $0, context: $1, locale: $2)
        }
    ) {
        self.flags = flags
        self.narrate = narrate
    }

    public struct Trigger: Hashable {
        let insights: InsightsModel.Key
        let isPro: Bool
        let isEnabled: Bool
    }

    public func trigger(_ insights: InsightsModel.Key, isPro: Bool) -> Trigger {
        Trigger(insights: insights, isPro: isPro, isEnabled: isEnabled)
    }

    public var isEnabled: Bool {
        flags?.isOn(.summary) ?? FeatureFlag.summary.defaultValue
    }

    public var summary: Summary? {
        guard isEnabled, let narration, let insights else { return nil }
        let shown = Dictionary(uniqueKeysWithValues: insights.shownFindings.map { ($0.id, $0) })
        let lines = narration.highlights.compactMap { highlight in
            shown[highlight.factID].map {
                Line(id: $0.id, section: insights.section(for: $0), sentence: highlight.sentence)
            }
        }
        return lines.isEmpty ? nil : Summary(headline: narration.headline, lines: lines)
    }

    public func load(from insights: InsightsModel, isPro: Bool) async {
        self.insights = insights
        let facts = NarrationFact.facts(from: insights.shownFindings)
        guard isEnabled, isPro, facts.count >= 2 else {
            narration = nil
            return
        }
        let key = Key(
            facts: facts, context: insights.narrationContext, locale: Locale.app.identifier,
            day: insights.day)
        if let cache, cache.key == key {
            narration = cache.narration
            return
        }
        let result = await narrate(facts, key.context, .app)
        guard !Task.isCancelled else { return }
        switch result {
        case .success(let value):
            narration = value
            cache = (key, value)
        case .failure(.rejected):
            narration = nil
            cache = (key, nil)
        case .failure:
            narration = nil
        }
    }
}
