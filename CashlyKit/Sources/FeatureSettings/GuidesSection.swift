import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct GuidesSection: View {
    @Environment(\.showGuide) private var showGuide
    @Environment(\.appTint) private var appTint

    var body: some View {
        if let showGuide {
            Section {
                ForEach(Guide.allCases) { guide in
                    Button {
                        showGuide(guide)
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(guide.title).foregroundStyle(Color.primary)
                                Text(guide.subtitle).font(.footnote).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: guide.systemImage).foregroundStyle(appTint)
                        }
                    }
                    .tint(Color.primary)
                }
            } header: {
                Text("Guias")
            }
        }
    }
}
