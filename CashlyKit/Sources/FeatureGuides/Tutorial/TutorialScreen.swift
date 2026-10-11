import FeatureCore
import SwiftUI

struct TutorialScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    let pages: [TutorialPage]

    var body: some View {
        let isLast = index == pages.count - 1
        GuideSheet(
            index: index, count: pages.count, back: index > 0 ? { index -= 1 } : nil,
            primary: GuideAction(isLast ? "Concluir" : "Continuar") {
                if isLast { dismiss() } else { index += 1 }
            },
            secondary: isLast ? nil : GuideAction("Pular") { dismiss() }
        ) {
            TutorialPageView(page: pages[index])
        }
    }
}

private struct TutorialPageView: View {
    let page: TutorialPage

    var body: some View {
        switch page.artwork {
        case .illustration(let image):
            GuidePage(image, title: page.title, message: page.message)
        case .example(let example):
            GuidePage(title: page.title, message: page.message) {
                TutorialExampleView(example: example)
            }
        }
    }
}
