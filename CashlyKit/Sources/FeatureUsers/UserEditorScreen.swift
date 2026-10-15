import CashlyDesignSystem
import FeatureCore
import SwiftUI

public struct UserEditorScreen: View {
    @Environment(UserEditorModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public var body: some View {
        @Bindable var model = model
        List {
            UserPhotoHeader()
            UserNameSection()
            PhotoStyleSection()
            if model.showsSymbols { PhotoSymbolSection() }
            if model.showsColors { ColorSection(hex: $model.photoColor) }
            if model.showsIllustrations {
                ForEach(model.illustrationSections) { IllustrationSection(section: $0) }
            }
        }
        .animation(reduceMotion ? nil : .smooth, value: model.style)
        .sensoryFeedback(.selection, trigger: model.illustration)
        .fontDesign(.rounded)
        .readableWidth()
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
