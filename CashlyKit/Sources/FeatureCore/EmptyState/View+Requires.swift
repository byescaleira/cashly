import CashlyDesignSystem
import SwiftUI

extension View {
    public func requires(_ prerequisites: Prerequisite...) -> some View {
        modifier(PrerequisiteGate(prerequisites: prerequisites))
    }
}

private struct PrerequisiteGate: ViewModifier {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(\.isLoading) private var isLoading
    let prerequisites: [Prerequisite]

    func body(content: Content) -> some View {
        if !isLoading,
            let missing = prerequisites.first(where: {
                $0.isMissing(session: session, finance: finance)
            })
        {
            MissingDataView(missing)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.groupedBackground)
        } else {
            content
        }
    }
}
