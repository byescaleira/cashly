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
    @Environment(\.mainState) var mainState
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
        .toolbar {
            ToolbarItem(placement: .navigation) { userItem }
            ToolbarItem { saveButton }
            ToolbarItem { removeButton }
        }
        .onChange(of: state.isLoading) { setIcon() }
        .task { action(.addCategory(.fetch)) }
        .environment(\.isLoading, state.isLoading)
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
                    CashlyText(category.name)
                        .cashly(font: .body, weight: .semibold)
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
                    .cashlyPadding(.negative(.small))
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
    
    @ViewBuilder
    var userItem: some View {
        if let user = state.user {
            Menu {
                Picker(selection: $store.state.user) {
                    ForEach(mainState.users) {
                        CashlyAsyncImage($0.photo) { image in
                            image
                        } placeholder: {
                            ProgressView()
                                .cashly(tint: .textSecondary)
                        }
                        .cashly(clip: .circle)
                        .tag($0)
                    }
                } label: {
                    EmptyView()
                }
                .pickerStyle(.palette)
            } label: {
                CashlyAsyncImage(user.photo) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .cashly(clip: .circle)
                } placeholder: {
                    ProgressView()
                        .cashly(tint: .textSecondary)
                }
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
        }
    }
    
    var saveButton: some View {
        CashlyButton {
            action(.addCategory(.save))
        } label: {
            CashlySymbol("checkmark")
                .cashly(font: .headline, weight: .bold)
        }
        .disabled(!state.canSave)
        .cashly(tint: .primary)
    }
    
    @ViewBuilder
    var removeButton: some View {
        if !state.isNew && !state.isLoading {
            CashlyButton {
                action(.addCategory(.remove))
            } label: {
                CashlySymbol("trash")
                    .cashly(font: .headline, weight: .bold)
            }
            .cashly(tint: .error)
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
            .mock
            .cashlyPreview()
    }
}
