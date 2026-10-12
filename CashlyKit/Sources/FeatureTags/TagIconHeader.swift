import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct TagIconHeader: View {
    @Environment(TagEditorModel.self) private var model

    var body: some View {
        Section {
        } header: {
            Image(systemName: model.draft.icon)
                .symbolRenderingMode(.hierarchical)
                .font(.icon(.xl))
                .symbolEffect(.bounce.byLayer, options: .repeat(.continuous).speed(0.1))
                .foregroundStyle(model.color)
                .background {
                    Image(systemName: "tag.fill")
                        .font(.icon(.hero))
                        .foregroundStyle(model.color.opacity(.opacitySoft))
                }
                .frame(width: 140, height: 140)
                .animation(.default, value: model.draft.color)
                .frame(maxWidth: .infinity)
                .contentTransition(.symbolEffect(.replace))
                .padding(.top, .spaceL)
        }
    }
}
