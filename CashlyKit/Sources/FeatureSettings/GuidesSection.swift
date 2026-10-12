import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct GuidesSection: View {
    @Environment(\.showGuide) private var showGuide
    @Environment(\.featureFlags) private var flags
    @Environment(\.appTint) private var appTint

    var body: some View {
        if let showGuide, flags?.isOn(.guides) != false {
            Section {
                ForEach(Array(Guide.allCases.enumerated()), id: \.element) { index, guide in
                    Button {
                        showGuide(guide)
                    } label: {
                        IconRow(
                            verbatim: guide.title, detail: guide.subtitle,
                            symbol: guide.systemImage,
                            color: index.isMultiple(of: 2) ? appTint : .companion)
                    }
                }
            } footer: {
                Text("Revisit how each part of Cashly works whenever you like.")
            }
        }
    }
}
