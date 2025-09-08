//
//  AddUserScreen.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 06/09/25.
//

import SwiftUI
import CashlyMock
import CashlyDomain
import CashlyPresentation

public struct AddUserScreen: CashlyView {
    @EnvironmentObject var store: CashlyStore<AddUserReducer, AddUserMiddleware>
    
    @Environment(\.addUserState) var state
    @Environment(\.action) var action
    
    @State var gender: Int = .zero
    
    public var body: some View {
        CashlyList {
            photoSection
            nameSection
            photosSection
        }
        .toolbar {
            ToolbarItem { saveButton }
            ToolbarItem { removeButton }
        }
        .task { setStartPhoto() }
    }
    
    func setStartPhoto() {
        store.state.photo = state.photo ?? state.photos(for: gender).randomElement()
    }
    
    var photoSection: some View {
        Section {} header: {
            CashlyAsyncImage(state.photo) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
                    .cashly(tint: .textSecondary)
            }
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
        Section {
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
                    CashlyAsyncImage(photo) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                            .cashly(tint: .textSecondary)
                    }
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
                .cashly(font: .headline, weight: .bold)
        }
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
                    .cashly(font: .headline, weight: .bold)
            }
            .cashly(tint: .error)
        }
    }
    
    public static var mock: some View {
        AddUserScreen()
    }
}

#Preview {
    NavigationView {
        AddUserScreen
            .cashlyPreview()
    }
}
