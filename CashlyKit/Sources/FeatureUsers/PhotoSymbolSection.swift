import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct PhotoSymbolSection: View {
    @Environment(UserEditorModel.self) private var model

    var body: some View {
        Section {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 44, maximum: 44), spacing: .spaceM)],
                spacing: .spaceM
            ) {
                ForEach(ProfileSymbol.allCases) { SymbolChoice(symbol: $0) }
            }
            .padding(.vertical, .spaceS)
            .sensoryFeedback(.selection, trigger: model.symbol)
        } header: {
            Text("Symbol").sectionTitle()
        } footer: {
            Text("Animals, nature, hobbies and food, in white over the color you pick.")
        }
    }
}

private struct SymbolChoice: View {
    @Environment(UserEditorModel.self) private var model
    let symbol: ProfileSymbol

    var body: some View {
        let isSelected = model.isSelected(symbol)
        let color = model.tint
        Button {
            model.select(symbol)
        } label: {
            Image(systemName: symbol.rawValue)
                .font(.icon(.m, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white : color)
                .frame(width: .badgeL, height: .badgeL)
                .background(
                    isSelected
                        ? AnyShapeStyle(color.gradient)
                        : AnyShapeStyle(color.opacity(.opacityTint)),
                    in: .circle
                )
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symbol.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
