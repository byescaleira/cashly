//
//  AddTagScreen.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 10/09/25.
//

import SwiftUI
import CashlyMock
import CashlyDomain
import CashlyPresentation

public struct AddTagScreen: CashlyView {
    @EnvironmentObject var store: CashlyStore<AddTagReducer, AddTagMiddleware>
    
    @Environment(\.addTagState) var state
    @Environment(\.action) var action
    @Environment(\.router) var router
    
    @State var category: CashlySymbolCategory = .random
    
    var initialState: AddTagState?
    
    public init(initialState: AddTagState? = nil) {
        self.initialState = initialState
    }
    
    public var body: some View {
        Form {
            infoSection
            nameSection
            iconCategorySection
            iconsSection
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                UserItemView()
                CashlySpacer()
                saveButton
                removeButton
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .onChange(of: state.isLoading) { setIcon() }
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
        action(.addTag(.fetch))
    }
    
    var infoSection: some View {
        Section {} header: {
            iconHeaderView
        }
    }
    
    var nameSection: some View {
        Section {
            TextField(
                "Enter the tag name",
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
        }
    }
    
    var iconsSection: some View {
        Section {
            
        } header: {
            LazyVGrid(
                columns: [.init(.adaptive(minimum: 60), spacing: 14)],
                spacing: 14
            ) {
                ForEach(category.symbols, id: \.self) { icon in
                    iconItemView(item: icon)
                }
            }
            .cashlyPadding(.horizontal, .negative(.medium))
        }
    }
    
    func iconItemView(item: String) -> some View {
        CashlyButton {
            store.state.icon = item
        } label: {
            CashlySymbol(item)
                .cashly(font: .system(size: 25))
                .cashly(color: item == state.icon ? .color(state.color) : .color(.gray))
                .frame(width: 60, height: 60)
                .cashly(background: item == state.icon ? .color(state.color.opacity(0.2)) : .color(.clear))
                .cashly(if: item != state.icon) {
                    $0.cashlyBackgroundItem()
                }
                .cashly(clip: .circle)
        }
        .buttonStyle(.plain)
    }
    
    var iconHeaderView: some View {
        CashlySymbol(state.icon, mode: .hierarchical)
            .cashly(font: .system(size: 50))
            .cashly(symbol: .variableColor.reversing.cumulative)
            .cashly(color: .color(state.color))
            .animation(.linear.speed(0.1).repeatForever(autoreverses: false), value: state.isLoading)
            .background(alignment: .center) {
                CashlySymbol("tag.fill")
                    .cashly(color: .color(state.color.opacity(0.3)))
                    .cashly(font: .system(size: 130))
            }
            .frame(width: 140, height: 140)
            .overlay(alignment: .bottom) {
                ColorPicker("", selection: $store.state.color)
                    .scaleEffect(1.5)
            }
            .frame(maxWidth: .infinity)
            .contentTransition(.symbolEffect(.replace))
            .cashlyPadding(.top, .medium)
    }
    
    var saveButton: some View {
        CashlyButton {
            action(.addTag(.save))
        } label: {
            CashlySymbol("checkmark")
        }
        .disabled(!state.canSave)
        .cashly(tint: .primary)
    }
    
    @ViewBuilder
    var removeButton: some View {
        if !state.isNew && !state.isLoading {
            CashlyButton {
                action(.addTag(.remove))
            } label: {
                CashlySymbol("trash")
            }
            .cashly(tint: .error)
        }
    }
    
    func setIcon() {
        guard !state.isLoading && state.isNew && state.icon.isEmpty else { return }
        store.state.icon = category.symbols.first ?? ""
    }
    
    public static var mock: some View {
        AddTagScreen()
    }
}

#Preview {
    NavigationView {
        AddTagScreen
            .cashlyPreview()
    }
}
