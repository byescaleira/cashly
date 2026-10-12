import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct CategoriesStep: View {
    @Environment(OnboardingModel.self) private var model

    var body: some View {
        GuidePage(
            title: "Escolha suas categorias",
            message: "Comece com estas e crie outras quando precisar."
        ) {
            EmptyView()
        } content: {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 64), spacing: .spaceS)], spacing: .spaceL
            ) {
                ForEach(CategorySuggestion.allCases) { suggestion in
                    SuggestionChoice(
                        suggestion: suggestion, isSelected: model.isSelected(suggestion)
                    ) {
                        model.toggle(suggestion)
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: model.suggestions)
        }
    }
}

private struct SuggestionChoice: View {
    let suggestion: CategorySuggestion
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: .spaceXS) {
                Image(systemName: suggestion.icon)
                    .font(.icon(.m, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.white : suggestion.color.color)
                    .frame(width: 48, height: 48)
                    .background(
                        isSelected
                            ? suggestion.color.color : suggestion.color.color.opacity(.opacityFill),
                        in: .circle)
                Text(suggestion.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
