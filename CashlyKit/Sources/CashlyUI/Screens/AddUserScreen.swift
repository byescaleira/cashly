//
//  AddUserScreen.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 06/09/25.
//

import SwiftUI
#if DEBUG
import CashlyMock
#endif
import CashlyDomain
import CashlyResource
import CashlyPresentation

public struct AddUserScreen: CashlyView {
    @Environment(CashlyStore<AddUserReducer, AddUserMiddleware>.self) var store
    
    @Environment(\.addUserState) var state
    @Environment(\.action) var action
    @Environment(\.router) var router
    
    @State var gender: Int = .zero
    
    var initialState: AddUserState?
    
    public init(initialState: AddUserState? = nil) {
        self.initialState = initialState
    }
    
    public var body: some View {
        CashlyList {
            photoSection
            nameSection
            photosSection
        }
        .toolbar {
            ToolbarItemGroup {
                removeButton
                saveButton
            }
        }
        .onChange(of: state.isLoading) { updatePhoto() }
        .scrollDismissesKeyboard(.immediately)
        .cashlyDismiss(isSaved: state.isSaved)
        .task { await handlerInitialState() }
    }
    
    func handlerInitialState() async {
        if let initialState {
            store.state = initialState
        }
        try? await Task.sleep(for: .seconds(0.5))
        action(.addUser(.fetch))
    }
    
    func updatePhoto() {
        store.state.photo = state.photo ?? state.photos(for: gender).randomElement()
    }
    
    var photoSection: some View {
        Section {} header: {
            CashlyResourceImage.avatar(id: state.photo)
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .cashly(background: .secondary)
                .cashly(clip: .circle)
                .overlay(alignment: .bottomTrailing) { repeatButton }
                .frame(maxWidth: .infinity)
        }
    }
    
    var repeatButton: some View {
        CashlyButton {
            store.state.photo = state.photos(for: gender).randomElement()
        } label: {
            CashlySymbol("repeat")
                .cashly(font: .system(size: 20), weight: .bold)
        }
        .buttonStyle(.glassProminent)
    }
    
    var nameSection: some View {
        @Bindable var store = store
        return Section {
            TextField(
                "Enter the user name",
                text: $store.state.name
            )
        } header: {
            CashlyText("First & Last Name")
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }
    
    var photosSection: some View {
        Section {
            
        } header: {
            CashlyText("Photo")
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        } footer: {
            CashlyVStack(spacing: .extraLarge) {
                segmentedGenderView
                photosGridView
            }
            .cashlyPadding(.horizontal, .negative(.medium))
        }
    }
    
    var segmentedGenderView: some View {
        Picker(selection: $gender) {
            CashlyText("Male")
                .tag(0)
            CashlyText("Female")
                .tag(1)
        } label: {
            EmptyView()
        }
        .pickerStyle(.segmented)
        .controlSize(.large)
    }
    
    var photosGridView: some View {
        LazyVGrid(columns: [.init(.adaptive(minimum: 70), spacing: 14)], spacing: 14) {
            ForEach(state.photos(for: gender), id: \.self) { photo in
                CashlyButton {
                    store.state.photo = photo
                } label: {
                    CashlyResourceImage.avatar(id: photo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .overlay {
                            if state.photo == photo {
                                Circle()
                                    .stroke(Color.accentColor, lineWidth: 4)
                                    .cashlyPadding(.negative(.extraSmall))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    var saveButton: some View {
        CashlyButton {
            action(.addUser(.save))
        } label: {
            CashlySymbol("checkmark")
        }
        .buttonStyle(.glassProminent)
        .disabled(!state.canSave)
        .cashly(tint: .primary)
    }
    
    @ViewBuilder
    var removeButton: some View {
        if !state.isNew && !state.isLoading {
            CashlyButton {
                action(.addUser(.remove))
            } label: {
                CashlySymbol("trash")
            }
            .cashly(tint: .text)
        }
    }
    
    public static var mock: some View {
        AddUserScreen()
    }
}

#if DEBUG
#Preview {
    NavigationView {
        AddUserScreen
            .cashlyPreview()
    }
}
#endif
