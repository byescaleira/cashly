import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct SummarySection: View {
    @Environment(SummaryModel.self) private var summaryModel

    var body: some View {
        Group {
            if let summary = summaryModel.summary {
                ProOnly {
                    Section {
                        VStack(alignment: .leading, spacing: .spaceHairline) {
                            Text(summary.headline).font(.rowTitle)
                            Text("Written on this device by Apple Intelligence")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        ForEach(summary.lines) { SummaryLine(line: $0) }
                    } header: {
                        Text("Cashly Summary").sectionTitle()
                    } footer: {
                        Text("Each sentence comes from a fact in the section named above it.")
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

private struct SummaryLine: View {
    let line: SummaryModel.Line

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceHairline) {
            Text(line.section).font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            Text(line.sentence)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
