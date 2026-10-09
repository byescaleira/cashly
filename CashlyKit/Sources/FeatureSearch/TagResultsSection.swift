import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct TagResultsSection: View {
    @Environment(SearchModel.self) private var search
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        if !search.tags.isEmpty {
            Section("Tags") {
                ForEach(search.tags) { tag in
                    Button {
                        open(.addTag(id: tag.id), in: section)
                    } label: {
                        Label {
                            Text(tag.name.capitalized).foregroundStyle(Color.primary)
                        } icon: {
                            Image(systemName: tag.icon).foregroundStyle(Color(hex: tag.color))
                        }
                    }
                }
            }
        }
    }
}
