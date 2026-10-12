import CashlyDesignSystem
import FeatureCore
import SwiftUI

public struct CategoryEditorScreen: View {
    @Environment(CategoryEditorModel.self) private var model

    public init() {}

    public var body: some View {
        @Bindable var model = model
        Form {
            CategoryIconHeader()
            CategoryNameSection()
            ColorSection(hex: $model.draft.color)
            IconSection(icon: $model.draft.icon, color: model.color)
        }
        .fontDesign(.rounded)
        .readableWidth()
        .toolbar {
            EditorActions(canSave: model.canSave, canRemove: model.canRemove) {
                await model.save()
            } remove: {
                await model.remove()
            }
        }
        .editorLifecycle(model.status) { await model.load() }
    }
}
