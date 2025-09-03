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
            iconCategorySection
            iconsSection
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
                    CashlyText(category.name)
                        .cashly(font: .body, weight: .semibold)
                }
                .cashly(tint: .color(state.color))
            }
        } header: {
            CashlyText("Icon")
                .headerProminence(.increased)
        }
    }
    
    var iconsSection: some View {
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
                .cashly(background: item == state.icon ? .color(state.color.opacity(0.2)) : .color(.clear))
                .cashly(clip: .circle)
        }
        .buttonStyle(.plain)
    }
    
    var iconHeaderView: some View {
        CashlySymbol(state.icon, mode: .hierarchical)
            .cashly(font: .system(size: 50))
            .cashly(symbol: .variableColor.reversing.cumulative)
            .cashly(color: .color(state.color))
            .frame(width: 120, height: 120)
            .cashly(background: .color(state.color.opacity(0.2)))
            .cashly(clip: .circle)
            .overlay {
                Circle()
                    .stroke(state.color, lineWidth: 5)
            }
            .animation(.linear.speed(0.1).repeatForever(autoreverses: false), value: state.isLoading)
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
            CashlyText(state.isNew ? "Create" : "Save")
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
    AddCategoryScreen
        .mock
        .cashlyPreview()
}
