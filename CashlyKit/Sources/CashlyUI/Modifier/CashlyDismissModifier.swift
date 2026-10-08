import CashlyDomain
import CashlyPresentation
import FeatureCore
import SwiftUI

struct CashlyDismissModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    @Environment(MainViewModel.self) private var main
    var isSaved: Bool
    var selectedUserID: String? = nil
    func body(content: Content) -> some View {
        content.onChange(of: isSaved) {
            guard isSaved else { return }
            dismiss()
            Task {
                if let selectedUserID {
                    await main.selectUser(id: selectedUserID)
                } else {
                    await main.load()
                }
            }
        }
    }
}
extension View {
    public func cashlyErrorAlert(error: Binding<CashlyDomain.CashlyError?>) -> some View {
        alert(
            "Não foi possível concluir",
            isPresented: Binding(
                get: { error.wrappedValue != nil }, set: { if !$0 { error.wrappedValue = nil } }
            )
        ) {
            Button("OK", role: .cancel) { error.wrappedValue = nil }
        } message: {
            Text(error.wrappedValue?.localizedDescription ?? "")
        }
    }
}
