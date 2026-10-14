import FeatureCore
import SwiftUI

struct TutorialPage: Identifiable {
    let id = UUID()
    let animation: CashlyAnimation
    let title: LocalizedStringKey
    let message: LocalizedStringKey
}

extension Guide {
    var pages: [TutorialPage] {
        switch self {
        case .tour: Self.tourPages
        case .recording: Self.recordingPages
        case .sharing: Self.sharingPages
        case .bills: Self.billsPages
        case .budgets: Self.budgetsPages
        case .insights: Self.insightsPages
        case .journey: Self.journeyPages
        case .widgets: Self.widgetsPages
        case .siri: Self.siriPages
        case .quickCapture: Self.capturePages
        case .backups: Self.backupsPages
        case .privacy: Self.privacyPages
        case .importSpreadsheet, .score: []
        }
    }
}
