import FeatureCore
import SwiftUI

public struct UserEditorScreen: View {
    @Environment(UserEditorModel.self) private var model

    public init() {}

    public var body: some View {
        List {
            UserPhotoHeader()
            UserNameSection()
            AvatarSection()
        }
        .fontDesign(.rounded)
        .toolbar {
            EditorActions(canSave: model.canSave, canRemove: model.canRemove) {
                await model.save()
            } remove: {
                await model.remove()
            }
        }
        .editorLifecycle(model.status, selecting: model.userToSelect) { await model.load() }
    }
}
