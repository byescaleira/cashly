import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import Foundation
import SwiftUI

public struct AddCategoryScreen: View {
    @State private var viewModel: CategoryViewModel

    var state: CategoryDraft { viewModel.draft }
    @Environment(\.open) var open
    @Environment(\.navigationSection) var section

    @State var category: CashlySymbolCategory = .food

    public init(draft: CategoryDraft, factory: CashlyPresentationFactory) {
        _viewModel = State(initialValue: factory.makeCategoryViewModel(draft: draft))
    }

    public var body: some View {
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
        .onChange(of: viewModel.isLoading) { setIcon() }
        .onChange(of: state.icon) { onChangeIcon() }
        .task { await handlerInitialState() }
        .cashlyDismissKeyboardOnScroll()
        .cashlyDismiss(isSaved: viewModel.isSaved)
        .cashlyErrorAlert(error: Binding(get: { viewModel.error }, set: { viewModel.error = $0 }))
        .disabled(viewModel.isLoading || viewModel.isSaved)
        .interactiveDismissDisabled(viewModel.isLoading)
        .environment(\.isLoading, viewModel.isLoading)
    }

    func handlerInitialState() async { await viewModel.load() }

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
        @Bindable var viewModel = viewModel
        Section {
            TextField(
                "Enter the category name",
                text: $viewModel.draft.name
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
                .cashly(tint: .color(state.color))
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
            viewModel.draft.icon = item
        } label: {
            CashlySymbol(item)
                .cashly(font: .system(size: 18))
                .cashly(color: item == state.icon ? .color(state.color) : .color(.gray))
                .frame(width: 40, height: 40)
                .cashly(
                    background: item == state.icon
                        ? .color(state.color.opacity(0.2)) : .color(.gray.opacity(0.2))
                )
                .cashly(clip: .circle)
                .overlay {
                    if item == state.icon {
                        Circle()
                            .stroke(state.color, lineWidth: 2)
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
        @Bindable var viewModel = viewModel
        CashlySymbol(state.icon, mode: .hierarchical)
            .cashly(font: .system(size: 50))
            .cashly(
                symbol: .bounce.byLayer,
                options: .repeat(.continuous).speed(0.1)
            )
            .cashly(color: .color(state.color))
            .frame(width: 120, height: 120)
            .cashly(background: .color(state.color.opacity(0.2)))
            .cashly(clip: .circle)
            .overlay {
                Circle()
                    .stroke(state.color, lineWidth: 5)
                    .cashlyPadding(.negative(.small))
            }
            .overlay(alignment: .bottomTrailing) {
                ColorPicker("", selection: $viewModel.draft.color)
                    .scaleEffect(1.5)
                    .cashlyPadding(.trailing, .large)
            }
            .frame(maxWidth: .infinity)
            .contentTransition(.symbolEffect(.replace))
            .cashlyPadding(.top, .medium)
    }

    var saveButton: some View {
        Button {
            Task { await viewModel.save() }
        } label: {
            CashlySymbol("checkmark")
        }
        .cashlyProminentButton()
        .accessibilityLabel("Salvar")
        .disabled(!viewModel.canSave)
        .cashly(tint: state.canSave ? .primary : .disabled)
    }

    @ViewBuilder
    var removeButton: some View {
        if !state.isNew && !viewModel.isLoading {
            Button {
                Task { await viewModel.remove() }
            } label: {
                CashlySymbol("trash")
            }
            .cashly(tint: .text)
        }
    }

    func setIcon() {
        guard !viewModel.isLoading && state.isNew && state.icon.isEmpty else { return }
        viewModel.draft.icon = category.symbols.first ?? ""
    }

}
