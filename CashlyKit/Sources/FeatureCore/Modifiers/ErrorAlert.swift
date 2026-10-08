import CashlyDomain
import SwiftUI

extension View {
    public func errorAlert(_ error: Binding<CashlyError?>) -> some View {
        alert(
            "Não foi possível concluir",
            isPresented: Binding(
                get: { error.wrappedValue != nil }, set: { if !$0 { error.wrappedValue = nil } })
        ) {
            Button("OK", role: .cancel) { error.wrappedValue = nil }
        } message: {
            Text(error.wrappedValue?.localizedDescription ?? "")
        }
    }
}
