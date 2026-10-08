import CashlyDesignSystem
import SwiftUI

public struct EditorActions: ToolbarContent {
    private let canSave: Bool
    private let canRemove: Bool
    private let save: @MainActor () async -> Void
    private let remove: @MainActor () async -> Void

    public init(
        canSave: Bool, canRemove: Bool, save: @escaping @MainActor () async -> Void,
        remove: @escaping @MainActor () async -> Void
    ) {
        self.canSave = canSave
        self.canRemove = canRemove
        self.save = save
        self.remove = remove
    }

    public var body: some ToolbarContent {
        ToolbarItemGroup {
            if canRemove {
                Button("Excluir", systemImage: "trash") { Task { await remove() } }
                    .tint(.primary)
            }
            Button("Salvar", systemImage: "checkmark") { Task { await save() } }
                .prominentButton()
                .disabled(!canSave)
                .tint(canSave ? .accentColor : .disabled)
        }
    }
}
