import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import CashlyResource
import FeatureCore
import Foundation
import SwiftUI

public struct AddUserScreen: View {
    @Environment(UserEditorModel.self) private var model

    var state: UserDraft { model.draft }
    @Environment(\.open) var open
    @Environment(\.navigationSection) var section

    @State var gender: Int = .zero

    public init() {}

    public var body: some View {
        @Bindable var status = model.status
        List {
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
        .onChange(of: model.status.isBusy) { updatePhoto() }
        .cashlyDismissKeyboardOnScroll()
        .cashlyDismiss(isSaved: model.status.isSaved, selectedUserID: state.isNew ? state.id : nil)
        .cashlyErrorAlert(error: $status.error)
        .disabled(model.status.isBusy || model.status.isSaved)
        .interactiveDismissDisabled(model.status.isBusy)
        .task { await handlerInitialState() }
    }

    func handlerInitialState() async { await model.load() }

    func updatePhoto() {
        model.draft.photo = state.photo ?? state.photos(for: gender).randomElement()
    }

    var photoSection: some View {
        Section {
        } header: {
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
        Button {
            model.draft.photo = state.photos(for: gender).randomElement()
        } label: {
            CashlySymbol("repeat")
                .cashly(font: .system(size: 20), weight: .bold)
        }
        .cashlyProminentButton()
    }

    @ViewBuilder
    var nameSection: some View {
        @Bindable var model = model
        Section {
            TextField(
                "Enter the user name",
                text: $model.draft.name
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
                Button {
                    model.draft.photo = photo
                } label: {
                    CashlyResourceImage.avatar(id: photo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .overlay {
                            if model.draft.photo == photo {
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
        Button {
            Task { await model.save() }
        } label: {
            CashlySymbol("checkmark")
        }
        .cashlyProminentButton()
        .accessibilityLabel("Salvar")
        .disabled(!model.canSave)
        .cashly(tint: .primary)
    }

    @ViewBuilder
    var removeButton: some View {
        if !state.isNew && !model.status.isBusy {
            Button {
                Task { await model.remove() }
            } label: {
                CashlySymbol("trash")
            }
            .cashly(tint: .text)
        }
    }

}
