import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import FeatureCore
import Foundation
import SwiftUI

struct EmptyUserView: View {
    @Environment(\.isLoading) var isLoading
    @Environment(SessionModel.self) var session
    @Environment(\.open) var open
    @Environment(\.navigationSection) var section

    @ViewBuilder
    var body: some View {
        if session.users.isEmpty,
            !isLoading
        {
            Section {
                ZStack {
                    if session.users.isEmpty {
                        CashlyCardView(
                            image: .illustrationPeople,
                            title: "No Users Yet",
                            subtitle:
                                "Users let you share and manage your finances as a team. Add your first user to start collaborating.",
                            buttonTitle: "Add User"
                        ) {
                            open(.addUser(id: nil), in: section)
                        }
                        .cashlyPadding(.medium)
                    }
                }
                .animation(.bouncy, value: session.users.isEmpty)
            } header: {
                CashlyText("Users")
                    .cashly(font: .title3, weight: .semibold)
                    .cashly(color: .text)
            }
            .transition(.scale)
        }
    }

}
