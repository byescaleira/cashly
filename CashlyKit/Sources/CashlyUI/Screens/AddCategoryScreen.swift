import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import FeatureCore
import Foundation
import SwiftUI

public struct AddCategoryScreen: View {
    @Environment(CategoryEditorModel.self) private var model

    var state: CategoryDraft { model.draft }

    var color: Color { Color(hex: state.color) }
    @Environment(\.open) var open
    @Environment(\.navigationSection) var section

    @State var category: CashlySymbolCategory = .food

    public init() {}

    public var body: some View {
        @Bindable var status = model.status
        Form {
            infoSection
            nameSection
            iconCategorySection
        }
        .toolbar {
            ToolbarItemGroup {
                removeButton
                saveButton
            }
        }
        .onChange(of: model.status.isBusy) { setIcon() }
        .onChange(of: state.icon) { onChangeIcon() }
        .task { await handlerInitialState() }
        .cashlyDismissKeyboardOnScroll()
        .cashlyDismiss(isSaved: model.status.isSaved)
        .cashlyErrorAlert(error: $status.error)
        .disabled(model.status.isBusy || model.status.isSaved)
        .interactiveDismissDisabled(model.status.isBusy)
        .environment(\.isLoading, model.status.isBusy)
    }

    func handlerInitialState() async { await model.load() }

    func onChangeIcon() {
        guard !state.isNew else { return }
        category =
            CashlySymbolCategory.allCases.first(where: {
                $0.symbols.contains(state.icon)
            }) ?? .food
    }

    var infoSection: some View {
        Section {
        } header: {
            iconHeaderView
        }
    }

    @ViewBuilder
    var nameSection: some View {
        @Bindable var model = model
        Section {
            TextField(
                "Enter the category name",
                text: $model.draft.name
            )
        } header: {
            CashlyText("Name")
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }

    @ViewBuilder
    var iconCategorySection: some View {
        Section {
            CashlyHStack {
                CashlyText("Category")

                Spacer()

                Menu {
                    Picker(selection: $category) {
                        ForEach(CashlySymbolCategory.allCases, id: \.self) {
                            CashlyText($0.name)
                                .tag($0)
                        }
                    } label: {
                        CashlyText(category.name)
                    }
                } label: {
                    CashlyHStack {
                        CashlyText(category.name)
                            .cashly(font: .body, weight: .semibold)
                        CashlySymbol("chevron.up.chevron.down")
                            .cashly(font: .footnote, weight: .semibold)
                    }
                }
                .cashly(tint: .color(color))
            }
        } header: {
            CashlyText("Icon")
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }

        Section {
            LazyVGrid(
                columns: [.init(.adaptive(minimum: 45, maximum: 45))], alignment: .leading,
                spacing: 16
            ) {
                ForEach(category.symbols, id: \.self) { icon in
                    iconItemView(item: icon)
                        .cashlyPadding()
                }
            }
        }
    }

    func iconItemView(item: String) -> some View {
        Button {
            model.draft.icon = item
        } label: {
            CashlySymbol(item)
                .cashly(font: .system(size: 18))
                .cashly(color: item == state.icon ? .color(color) : .color(.gray))
                .frame(width: 40, height: 40)
                .cashly(
                    background: item == state.icon
                        ? .color(color.opacity(0.2)) : .color(.gray.opacity(0.2))
                )
                .cashly(clip: .circle)
                .overlay {
                    if item == state.icon {
                        Circle()
                            .stroke(color, lineWidth: 2)
                            .frame(width: 45, height: 45)
                    }
                }
                .cashly(if: item == state.icon) {
                    $0.cashly(
                        symbol: .bounce.byLayer,
                        options: .repeat(.continuous).speed(0.1)
                    )
                }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    var iconHeaderView: some View {
        @Bindable var model = model
        CashlySymbol(state.icon, mode: .hierarchical)
            .cashly(font: .system(size: 50))
            .cashly(
                symbol: .bounce.byLayer,
                options: .repeat(.continuous).speed(0.1)
            )
            .cashly(color: .color(color))
            .frame(width: 120, height: 120)
            .cashly(background: .color(color.opacity(0.2)))
            .cashly(clip: .circle)
            .overlay {
                Circle()
                    .stroke(color, lineWidth: 5)
                    .cashlyPadding(.negative(.small))
            }
            .overlay(alignment: .bottomTrailing) {
                ColorPicker("", selection: $model.draft.color.hexColor)
                    .scaleEffect(1.5)
                    .cashlyPadding(.trailing, .large)
            }
            .frame(maxWidth: .infinity)
            .contentTransition(.symbolEffect(.replace))
            .cashlyPadding(.top, .medium)
    }

    var saveButton: some View {
        Button {
            Task { await model.save() }
        } label: {
            CashlySymbol("checkmark")
        }
        .cashlyProminentButton()
        .accessibilityLabel("Salvar")
        .disabled(!model.canSave)
        .cashly(tint: state.canSave ? .primary : .disabled)
    }

    @ViewBuilder
    var removeButton: some View {
        if !state.isNew && !model.status.isBusy {
            Button {
                Task { await model.remove() }
            } label: {
                CashlySymbol("trash")
            }
            .cashly(tint: .text)
        }
    }

    func setIcon() {
        guard !model.status.isBusy && state.isNew && state.icon.isEmpty else { return }
        model.draft.icon = category.symbols.first ?? ""
    }

}
