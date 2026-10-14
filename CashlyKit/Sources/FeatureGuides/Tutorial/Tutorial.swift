import FeatureCore
import SwiftUI

struct TutorialPage: Identifiable {
    let id = UUID()
    let animation: CashlyAnimation
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    var steps: [GuideStep] = []
    var link: TutorialLink?
}

struct TutorialLink {
    let title: LocalizedStringKey
    let symbol: String
    let url: URL

    static var shortcuts: TutorialLink {
        TutorialLink(
            title: "Open Shortcuts", symbol: "square.stack.3d.up.fill",
            url: URL(string: "shortcuts://")!)
    }
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
        case .backTap: Self.backTapPages
        case .backups: Self.backupsPages
        case .privacy: Self.privacyPages
        case .importSpreadsheet, .score: []
        }
    }
}
