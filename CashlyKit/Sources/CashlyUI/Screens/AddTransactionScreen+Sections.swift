//
//  AddTransactionScreen+Sections.swift
//  CashlyKit
//
//  Form sections split out from AddTransactionScreen.swift.
//

import SwiftUI
import CashlyResource
import CashlyDomain
import PhotosUI

extension AddTransactionScreen {
    var photosPickerBinding: Binding<PhotosPickerItem?> {
        Binding(
            get: { photoPickerItem },
            set: { newItem in
                photoPickerItem = newItem
                Task { await persistPickedAttachment(item: newItem) }
            }
        )
    }

    @MainActor
    func persistPickedAttachment(item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        // Drop the prior receipt if the user picked a replacement.
        if let oldPath = state.attachmentPath {
            await attachmentStorage.remove(path: oldPath)
        }
        guard let newPath = try? await attachmentStorage.save(
            data: data,
            suggestedExtension: "jpg"
        ) else { return }
        attachmentImageData = data
        store.cashlyMutate(\.attachmentPath, newPath)
    }

    @MainActor
    func detachReceipt() {
        if let path = state.attachmentPath {
            Task { await attachmentStorage.remove(path: path) }
        }
        attachmentImageData = nil
        photoPickerItem = nil
        store.cashlyMutate(\.attachmentPath, nil)
    }

    var attachmentPreviewImage: Image? {
        #if canImport(UIKit)
        guard let data = attachmentImageData,
              let uiImage = UIImage(data: data)
        else { return nil }
        return Image(uiImage: uiImage)
        #else
        return nil
        #endif
    }

    var attachmentSection: some View {
        Section {
            PhotosPicker(
                selection: photosPickerBinding,
                matching: .images
            ) {
                CashlyLabel(
                    state.attachmentPath == nil
                        ? CashlyL10n.string("Attach receipt")
                        : CashlyL10n.string("Replace receipt"),
                    symbol: "paperclip"
                )
            }
            if let preview = attachmentPreviewImage {
                preview
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(.rect(cornerRadius: 8))
                CashlyButton {
                    detachReceipt()
                } label: {
                    CashlyLabel(CashlyL10n.string("Remove receipt"), symbol: "trash")
                }
                .cashly(tint: .color(.red))
            }
        } header: {
            CashlyText(CashlyL10n.string("Receipt"))
        }
    }

    var kindSection: some View {
        Section {
            Picker(selection: store.cashlyBinding(\.kind)) {
                ForEach(TransactionKind.allCases, id: \.self) { kind in
                    Text(verbatim: kind.localizedSummary).tag(kind)
                }
            } label: {
                CashlyLabel(CashlyL10n.string("Type"), symbol: "arrow.left.arrow.right")
            }
            #if os(iOS)
            .pickerStyle(.segmented)
            #endif
            if state.needsReview {
                CashlyHStack(spacing: .extraSmall) {
                    CashlySymbol("exclamationmark.triangle.fill")
                        .cashly(color: .color(.orange))
                    CashlyText(CashlyL10n.string("Needs review"))
                        .cashly(color: .color(.orange))
                        .cashly(font: .caption, weight: .semibold)
                }
            }
        }
    }

    var amountSection: some View {
        return Section {} header: {
            CashlyVStack(spacing: .small) {
                transactionStatusView
                splitValueView

                CashlyVStack(spacing: .zero) {
                    CashlyCurrencyTextField(amount: store.cashlyBinding(\.amount))
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .cashly(alignment: .center)
                        .cashly(font: .system(size: 40), weight: .black)
                        .cashly(tint: .color(.clear))

                    if state.installmentIsOn, state.amount > .zero {
                        let value = state.amount / state.installmentPlan.double
                        let description = "\(state.installmentPlan)x payments of \(value.currency() ?? "")"
                        CashlyText(description)
                            .cashly(font: .callout, weight: .medium)
                            .cashly(color: .textSecondary)
                            .contentTransition(.numericText())
                            .animation(.bouncy, value: state.amount)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .cashlyPadding(.vertical, .small)
        }
    }

    var summarySection: some View {
        return Section {
            TextField(
                "Provide a summary of your transaction",
                text: store.cashlyBinding(\.summary),
                axis: .vertical
            )
        } header: {
            CashlyText(CashlyL10n.string("Summary"))
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }

    var categoriesSection: some View {
        Section {
            categoriesView
            EmptyCategoryView()
            EmptyBudgetView(budgets: state.budgets)
        } header: {
            CashlyHStack {
                CashlyText(CashlyL10n.string("Categories"))
                    .cashly(font: .title3, weight: .semibold)
                    .cashly(color: .text)
                CashlySpacer()
                CategoryVariationView(
                    category: state.category,
                    amount: state.amount
                )
            }
        } footer: {
            if let category = state.category {
                let remaining = mainState.categoryRemainingAmount(category: category) - state.amount
                let description = remaining < .zero ? "You’ve exceeded the planned budget in the \(category.name.capitalized) category by \((remaining * -1).currency() ?? "")" : "You’re \(remaining.currency() ?? "") away from reaching the planned budget in the \(category.name.capitalized) category."
                CashlyText(description)
                    .contentTransition(.numericText(value: remaining))
                    .animation(.bouncy, value: state.amount)
            }
        }
    }

    var dateSection: some View {
        return Section {
            DatePicker(
                state.date.string(with: .cashly(.weekDay)) ?? "",
                selection: store.cashlyBinding(\.date),
                displayedComponents: .hourAndMinute.union(.date)
            )
            .datePickerStyle(.compact)
            .cashly(tint: .primary)
        } header: {
            CashlyText(CashlyL10n.string("Date"))
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }

    @ViewBuilder
    var selectedParticipantsSection: some View {
        if !state.participants.isEmpty {
            Section {
                splitModeView
            } header: {
                CashlyText(CashlyL10n.string("Participants"))
                    .cashly(font: .title3, weight: .semibold)
                    .cashly(color: .text)
            } footer: {
                CashlyText(state.splitMode?.description)
            }

            participantsView
        }
    }

    var installmentSection: some View {
        return Section {
            Toggle(isOn: store.cashlyBinding(\.installmentIsOn)) {
                CashlyText(CashlyL10n.string("Enable installments"))
            }

            if state.installmentIsOn {
                Picker(selection: store.cashlyBinding(\.installmentPlan)) {
                    ForEach(1 ... 21, id: \.self) {
                        let value = $0.string + "x"
                        CashlyText(value)
                            .tag($0)
                    }
                } label: {
                    CashlyText(CashlyL10n.string("Number of installments"))
                }
            }
        } header: {
            CashlyText(CashlyL10n.string("Installment"))
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }
}
