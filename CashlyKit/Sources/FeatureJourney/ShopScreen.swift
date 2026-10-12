import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import FeatureStore
import SwiftUI

public struct ShopScreen: View {
    @Environment(StoreModel.self) private var store
    @State private var message: String?

    public init() {}

    public var body: some View {
        @Bindable var store = store
        AdaptiveList {
            ForEach(ShopItem.Group.allCases, id: \.self) { group in
                let items = ShopCatalog.items(in: group)
                if !items.isEmpty {
                    Section {
                        ForEach(items) { ShopRow(item: $0) }
                    } header: {
                        Text(group.title).sectionTitle()
                    } footer: {
                        if group == .helps {
                            Text("Helps are used up as you go and belong to this profile.")
                        }
                    }
                }
            }
            Section {
                Button("Restore Purchases", systemImage: "arrow.clockwise") {
                    Task { await restore() }
                }
                .font(.buttonLabel)
            } footer: {
                Text("Purchases belong to your Apple Account and work on all your devices.")
            }
        }
        .fontDesign(.rounded)
        .navigationTitle("Shop")
        .errorAlert($store.error)
        .alert("Restore Purchases", isPresented: isShowingMessage) {
        } message: {
            Text(message ?? "")
        }
    }

    private var isShowingMessage: Binding<Bool> {
        Binding(get: { message != nil }, set: { if !$0 { message = nil } })
    }

    private func restore() async {
        do {
            try await store.restore()
            message =
                store.owned.isEmpty
                ? String(appLocalized: "No purchases to restore on this Apple Account.")
                : String(appLocalized: "Your purchases are back.")
        } catch {
            store.error = error as? CashlyError
        }
    }
}
