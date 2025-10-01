//
//  AddCategoryScreen.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import SwiftUI
import CashlyMock
import CashlyDomain
import CashlyPresentation

public struct AddCategoryScreen: CashlyView {
    @EnvironmentObject var store: CashlyStore<AddCategoryReducer, AddCategoryMiddleware>
    
    @Environment(\.addCategoryState) var state
    @Environment(\.action) var action
    @Environment(\.router) var router
    
    @State var category: CashlySymbolCategory = .food
    
    var initialState: AddCategoryState?
    
    public init(initialState: AddCategoryState? = nil) {
        self.initialState = initialState
    }
    
    public var body: some View {
        Form {
            infoSection
            nameSection
            iconCategorySection
        }
        .toolbar {
            ToolbarItemGroup {
                UserItemView()
                removeButton
                saveButton
            }
        }
        .onChange(of: state.isLoading) { setIcon() }
        .onChange(of: state.icon) { onChangeIcon() }
        .task { await handlerInitialState() }
        .scrollDismissesKeyboard(.immediately)
        .cashlyDismiss(isSaved: state.isSaved)
        .environment(\.isLoading, state.isLoading)
    }
    
    func handlerInitialState() async {
        if let initialState {
            store.state = initialState
        }
        try? await Task.sleep(for: .seconds(0.5))
        action(.addCategory(.fetch))
    }
    
    func onChangeIcon() {
        guard !state.isNew else { return }
        category = CashlySymbolCategory.allCases.first(where: {
            $0.symbols.contains(state.icon)
        }) ?? .food
    }
    
    var infoSection: some View {
        Section {} header: {
            iconHeaderView
        }
    }
    
    var nameSection: some View {
        Section {
            TextField(
                "Enter the category name",
                text: $store.state.name
            )
        } header: {
            CashlyText("Name")
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }
    
    var iconCategorySection: some View {
        Section {
            CashlyHStack {
                CashlyText("Category")
                
                CashlySpacer()
                
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
        } footer: {
            CashlyHorizontalList { proxy in
                CashlyHStack(spacing: .zero) {
                    ForEach(category.symbols, id: \.self) { icon in
                        iconItemView(item: icon)
                            .cashlyPadding()
                    }
                }
                .onChange(of: state.icon) {
                    Task {
                        try await Task.sleep(for: .seconds(0.2))
                        withAnimation(.bouncy.speed(0.5)) {
                            proxy.scrollTo(state.icon, anchor: .center)
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(.horizontal, -40)
        }
    }
    
    func iconItemView(item: String) -> some View {
        CashlyButton {
            store.state.icon = item
        } label: {
            CashlySymbol(item)
                .cashly(font: .system(size: 18))
                .cashly(color: item == state.icon ? .color(state.color) : .color(.gray))
                .frame(width: 40, height: 40)
                .cashly(background: item == state.icon ? .color(state.color.opacity(0.2)) : .color(.gray.opacity(0.2)))
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
    
    var iconHeaderView: some View {
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
                ColorPicker("", selection: $store.state.color)
                    .scaleEffect(1.5)
                    .cashlyPadding(.trailing, .large )
            }
            .frame(maxWidth: .infinity)
            .contentTransition(.symbolEffect(.replace))
            .cashlyPadding(.top, .medium)
    }
    
    var saveButton: some View {
        CashlyButton {
            action(.addCategory(.save))
        } label: {
            CashlySymbol("checkmark")
        }
        .buttonStyle(.glassProminent)
        .disabled(!state.canSave)
        .cashly(tint: state.canSave ? .primary : .disabled)
    }
    
    @ViewBuilder
    var removeButton: some View {
        if !state.isNew && !state.isLoading {
            CashlyButton {
                action(.addCategory(.remove))
            } label: {
                CashlySymbol("trash")
            }
            .cashly(tint: .text)
        }
    }
    
    func setIcon() {
        guard !state.isLoading && state.isNew && state.icon.isEmpty else { return }
        store.state.icon = category.symbols.first ?? ""
    }
    
    public static var mock: some View {
        AddCategoryScreen()
    }
}

#Preview {
    NavigationView {
        AddCategoryScreen
            .cashlyPreview()
    }
}
