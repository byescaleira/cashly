import CashlyDomain
import FeatureCore
import SwiftUI

public struct ExternalImportScreen: View {
    @Environment(SessionModel.self) private var session
    private let preview: SpreadsheetPreview
    private let source: String
    private let onFinish: (Int?) -> Void

    public init(preview: SpreadsheetPreview, source: String, onFinish: @escaping (Int?) -> Void) {
        self.preview = preview
        self.source = source
        self.onFinish = onFinish
    }

    public var body: some View {
        ModelHost(SpreadsheetImportModel(session: session)) {
            ExternalImportContent(preview: preview, source: source, onFinish: onFinish)
        }
    }
}

private struct ExternalImportContent: View {
    @Environment(SpreadsheetImportModel.self) private var model
    let preview: SpreadsheetPreview
    let source: String
    let onFinish: (Int?) -> Void

    var body: some View {
        SpreadsheetImportScreen()
            .task { await model.reviewExternal(preview, source: source) }
            .onDisappear { onFinish(model.step == .done ? model.imported : nil) }
    }
}
