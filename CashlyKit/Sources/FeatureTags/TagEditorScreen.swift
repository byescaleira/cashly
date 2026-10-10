import FeatureCore
import SwiftUI

public struct TagEditorScreen: View {
    @Environment(TagEditorModel.self) private var model

    public init() {}

    public var body: some View {
        @Bindable var model = model
        Form {
            TagIconHeader()
            TagNameSection()
            ColorSection(hex: $model.draft.color)
            IconSection(icon: $model.draft.icon, color: model.color)
        }
        .fontDesign(.rounded)
        .toolbar {
            ToolbarItem { UserMenu() }
            EditorActions(canSave: model.canSave, canRemove: model.canRemove) {
                await model.save()
            } remove: {
                await model.remove()
            }
        }
        .editorLifecycle(model.status) { await model.load() }
    }
}
