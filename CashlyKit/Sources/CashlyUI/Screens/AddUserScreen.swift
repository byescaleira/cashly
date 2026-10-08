import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import CashlyResource
import FeatureCore
import Foundation
import SwiftUI

public struct AddUserScreen: View {
    @State private var viewModel: UserViewModel

    var state: UserDraft { viewModel.draft }
    @Environment(\.open) var open
    @Environment(\.navigationSection) var section

    @State var gender: Int = .zero

    public init(draft: UserDraft, factory: CashlyPresentationFactory) {
        _viewModel = State(initialValue: factory.makeUserViewModel(draft: draft))
    }

    public var body: some View {
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
        .onChange(of: viewModel.isLoading) { updatePhoto() }
        .cashlyDismissKeyboardOnScroll()
        .cashlyDismiss(isSaved: viewModel.isSaved, selectedUserID: state.isNew ? state.id : nil)
        .cashlyErrorAlert(error: Binding(get: { viewModel.error }, set: { viewModel.error = $0 }))
        .disabled(viewModel.isLoading || viewModel.isSaved)
        .interactiveDismissDisabled(viewModel.isLoading)
        .task { await handlerInitialState() }
    }

    func handlerInitialState() async { await viewModel.load() }

    func updatePhoto() {
        viewModel.draft.photo = state.photo ?? state.photos(for: gender).randomElement()
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
            viewModel.draft.photo = state.photos(for: gender).randomElement()
        } label: {
            CashlySymbol("repeat")
                .cashly(font: .system(size: 20), weight: .bold)
        }
        .cashlyProminentButton()
    }

    @ViewBuilder
    var nameSection: some View {
        @Bindable var viewModel = viewModel
        Section {
            TextField(
                "Enter the user name",
                text: $viewModel.draft.name
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
                    viewModel.draft.photo = photo
                } label: {
                    CashlyResourceImage.avatar(id: photo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .overlay {
                            if viewModel.draft.photo == photo {
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
            Task { await viewModel.save() }
        } label: {
            CashlySymbol("checkmark")
        }
        .cashlyProminentButton()
        .accessibilityLabel("Salvar")
        .disabled(!viewModel.canSave)
        .cashly(tint: .primary)
    }

    @ViewBuilder
    var removeButton: some View {
        if !state.isNew && !viewModel.isLoading {
            Button {
                Task { await viewModel.remove() }
            } label: {
                CashlySymbol("trash")
            }
            .cashly(tint: .text)
        }
    }

}
