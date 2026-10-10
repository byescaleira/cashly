import FeatureCore
import SwiftUI

struct CategoryIconHeader: View {
    @Environment(CategoryEditorModel.self) private var model

    var body: some View {
        Section {
        } header: {
            Image(systemName: model.draft.icon)
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 50))
                .symbolEffect(.bounce.byLayer, options: .repeat(.continuous).speed(0.1))
                .foregroundStyle(model.color)
                .frame(width: 120, height: 120)
                .background(model.color.opacity(0.2), in: .circle)
                .overlay { Circle().stroke(model.color, lineWidth: 5).padding(-8) }
                .animation(.default, value: model.draft.color)
                .frame(maxWidth: .infinity)
                .contentTransition(.symbolEffect(.replace))
                .padding(.top, 16)
        }
    }
}
