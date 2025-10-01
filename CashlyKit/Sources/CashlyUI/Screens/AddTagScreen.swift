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
            iconTagSection
        }
        .toolbar {
            ToolbarItemGroup {
                UserItemView()
                removeButton
                saveButton
            }
        }
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
    
    var iconTagSection: some View {
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
        .buttonStyle(.glassProminent)
        .disabled(!state.canSave)
        .cashly(tint: state.canSave ? .primary : .disabled)
    }
    
    @ViewBuilder
    var removeButton: some View {
        if !state.isNew && !state.isLoading {
            CashlyButton {
                action(.addTag(.remove))
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
        AddTagScreen()
    }
}

#Preview {
    NavigationView {
        AddTagScreen
            .cashlyPreview()
    }
}
