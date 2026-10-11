import FeatureCore
import SwiftUI

public struct GuideScreen: View {
    @Environment(SessionModel.self) private var session
    private let guide: Guide

    public init(_ guide: Guide) {
        self.guide = guide
    }

    public var body: some View {
        switch guide {
        case .importSpreadsheet:
            ModelHost(SpreadsheetImportModel(session: session)) { SpreadsheetImportScreen() }
        case .tour, .budgets, .sharing:
            TutorialScreen(pages: guide.pages)
        }
    }
}
