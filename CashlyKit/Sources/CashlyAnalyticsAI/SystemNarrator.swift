import CashlyAnalytics
import Foundation
import FoundationModels

@Generable
struct GeneratedSummary {
    @Guide(description: "One short sentence about the month as a whole, with no numbers.")
    var headline: String

    @Guide(
        description: "The two or three most useful facts to point out, most important first.",
        .count(2...3))
    var highlights: [GeneratedHighlight]
}

@Generable
struct GeneratedHighlight {
    @Guide(description: "The number of the fact in the list, starting at 1.")
    var fact: Int

    @Guide(description: "One short, friendly sentence about this fact, with no numbers.")
    var sentence: String
}

public enum SystemNarrator {
    public static func isAvailable(for locale: Locale) -> Bool {
        let model = SystemLanguageModel.default
        return model.isAvailable && model.supportsLocale(locale)
    }

    public static func narrate(facts: [NarrationFact], context: String, locale: Locale) async
        -> Result<Narration, NarrationError>
    {
        guard facts.count >= 2, isAvailable(for: locale) else { return .failure(.unavailable) }
        let language =
            Locale(identifier: "en").localizedString(forIdentifier: locale.identifier) ?? "English"
        let session = LanguageModelSession(
            instructions: NarrationPrompt.instructions(language: language))
        let summary: GeneratedSummary
        do {
            summary = try await session.respond(
                to: NarrationPrompt.prompt(facts: facts, context: context),
                generating: GeneratedSummary.self,
                options: GenerationOptions(samplingMode: .greedy)
            ).content
        } catch {
            return .failure(.failed)
        }
        guard
            let narration = NarrationCheck.validate(
                headline: summary.headline,
                items: summary.highlights.map { ($0.fact, $0.sentence) }, facts: facts)
        else {
            return .failure(.rejected)
        }
        return .success(narration)
    }
}
