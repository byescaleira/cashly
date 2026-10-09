import CashlyDomain
import CashlyPresentation
import FeatureCore
import SwiftUI

struct CashlyDismissModifier: ViewModifier {
    @Environment(\.close) private var close
    @Environment(SessionModel.self) private var session
    var isSaved: Bool
    func body(content: Content) -> some View {
        content.onChange(of: isSaved) {
            guard isSaved else { return }
            close()
            session.reload()
        }
    }
}
extension View {
    public func cashlyErrorAlert(error: Binding<CashlyDomain.CashlyError?>) -> some View {
        errorAlert(error)
    }
}
