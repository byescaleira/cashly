import CashlyResource
import SwiftUI

struct WelcomeStep: View {
    var body: some View {
        StepLayout(
            title: "Boas-vindas ao Cashly",
            message:
                "Organize gastos, orçamentos e metas num só lugar, com seus dados guardados no aparelho."
        ) {
            CashlyResourceImage.illustrationWelcome.image.resizable().scaledToFit()
        } content: {
            EmptyView()
        }
    }
}
