import FeatureCore
import SwiftUI

struct DoneStep: View {
    @Environment(OnboardingModel.self) private var model

    var body: some View {
        GuidePage(
            .illustrationDone, title: "Tudo pronto, \(model.firstName)!",
            message: "Registre a primeira transação ou defina orçamentos em Metas."
        )
    }
}
