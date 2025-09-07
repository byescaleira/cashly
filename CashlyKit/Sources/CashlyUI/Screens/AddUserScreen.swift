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
            .frame(width: 130, height: 130)
            .cashly(background: .secondary)
            .cashly(clip: .circle)
            .overlay(alignment: .bottomTrailing) {
                repeatButton
            }
            .frame(maxWidth: .infinity)
            .cashlyPadding(.top, .medium)
        }
    }
    
    var repeatButton: some View {
        CashlyButton {
            store.state.photo = state.photos(for: gender).randomElement()
        } label: {
            CashlySymbol("repeat")
                .cashly(font: .system(size: 20), weight: .bold)
                .cashly(color: .white)
                .frame(width: 45, height: 45)
                .cashly(glass: .clear.tint(Color.accentColor.opacity(0.8)), in: .circle)
        }
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
            CashlyVStack(spacing: .large) {
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
                .cashly(glass: .clear, in: .capsule)
                
                LazyVGrid(columns: [.init(.adaptive(minimum: 70), spacing: 12)], spacing: 12) {
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
                            .opacity(photo == state.photo ? 1 : 0.4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .cashlyPadding()
        } header: {
            CashlyText("Photo")
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }
    
    public static var mock: some View {
        AddUserScreen()
    }
}

#Preview {
    AddUserScreen
        .cashlyPreview()
}
