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
        case .score:
            ScoreGuideScreen(onFinish: complete)
        case .tour, .budgets, .sharing:
            TutorialScreen(pages: guide.pages, onFinish: complete)
        }
    }

    private func complete() {
        Task { [session, guide] in await session.record(.guideCompleted, value: guide.rawValue) }
    }
}
