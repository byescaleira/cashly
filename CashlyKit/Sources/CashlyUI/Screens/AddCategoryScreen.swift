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
    
    @State var category: CashlySymbolCategory = .random
    
    public init() {}
    
    public var body: some View {
        Form {
            infoSection
            nameSection
            iconSection
        }
        .onChange(of: state.isLoading) { setIcon() }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                CashlyHStack(spacing: .medium) {
                    saveButton
                    removeButton
                }
                .cashlyPadding()
                .cashlyPadding(.horizontal)
            }
        }
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
                .headerProminence(.increased)
        }
    }
    
    @ViewBuilder
    var iconSection: some View {
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
                    CashlyText(category.name)
                        .cashly(font: .body, weight: .semibold)
                }
                .cashly(tint: .color(state.color))
            }
        } header: {
            CashlyText("Icon")
                .headerProminence(.increased)
        }
        
        Section {
            LazyVGrid(columns: [.init(.adaptive(minimum: 50))], spacing: 16) {
                ForEach(category.symbols, id: \.self) { icon in
                    iconItemView(item: icon)
                }
            }
            .cashlyPadding()
        }
    }
    
    func iconItemView(item: String) -> some View {
        CashlyButton {
            store.state.icon = item
        } label: {
            CashlySymbol(item)
                .cashly(font: .system(size: 20))
                .cashly(color: item == state.icon ? .color(state.color) : .color(.gray))
                .frame(width: 45, height: 45)
                .cashly(background: item == state.icon ? .color(state.color.opacity(0.2)) : .backgroundSecondary)
                .cashly(clip: .circle)
        }
        .buttonStyle(.plain)
    }
    
    var iconHeaderView: some View {
        CashlySymbol(state.icon, mode: .hierarchical)
            .cashly(font: .system(size: 50))
            .cashly(color: .color(state.color))
            .frame(width: 120, height: 120)
            .cashly(background: .color(state.color.opacity(0.2)))
            .cashly(clip: .circle)
            .cashly(glass: .clear, in: .circle)
            .overlay(alignment: .bottomTrailing) {
                ColorPicker("", selection: $store.state.color)
                    .scaleEffect(1.3)
                    .cashlyPadding([.bottom, .trailing], .small)
            }
            .frame(maxWidth: .infinity)
            .contentTransition(.symbolEffect(.replace))
            .animation(.bouncy, value: state.icon)
    }
    
    var saveButton: some View {
        CashlyButton {
            action(.addCategory(.save))
        } label: {
            CashlyText(state.isNew ? "Create Category" : "Save Category")
                .cashly(font: .headline, weight: .semibold)
        }
        .disabled(!state.canSave)
        .cashly(tint: .color(state.color))
    }
    
    @ViewBuilder
    var removeButton: some View {
        if !state.isNew && !state.isLoading {
            Divider()
            CashlyButton {
                action(.addCategory(.remove))
            } label: {
                CashlySymbol("trash")
                    .cashly(font: .headline, weight: .bold)
            }
            .cashly(tint: .color(state.color))
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
    NavigationStack {
        AddCategoryScreen
            .mock
            .cashlyPreview()
    }
}
