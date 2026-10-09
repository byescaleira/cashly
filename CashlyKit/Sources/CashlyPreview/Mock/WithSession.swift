import FeatureCore
import SwiftUI

struct WithSession<Content: View>: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(IntelligenceModel.self) private var intelligence
    let content: (SessionModel, FinanceModel, IntelligenceModel) -> Content

    var body: some View {
        content(session, finance, intelligence)
    }
}
