import SwiftUI

public struct MissingDataView: View {
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section
    private let prerequisite: Prerequisite

    public init(_ prerequisite: Prerequisite) {
        self.prerequisite = prerequisite
    }

    public var body: some View {
        EmptyStateView(
            image: prerequisite.image, title: prerequisite.title,
            description: prerequisite.description, actionTitle: prerequisite.actionTitle
        ) {
            open(prerequisite.route, in: section)
        }
    }
}
