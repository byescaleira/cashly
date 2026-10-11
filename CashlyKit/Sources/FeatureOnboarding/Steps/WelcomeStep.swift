import FeatureCore
import SwiftUI

struct WelcomeStep: View {
    var body: some View {
        GuidePage(
            .illustrationWelcome, title: "Boas-vindas ao Cashly",
            message:
                "Organize gastos, orçamentos e metas num só lugar, com seus dados guardados no aparelho."
        )
    }
}
