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
            title: prerequisite.title, description: prerequisite.description,
            actionTitle: prerequisite.actionTitle, action: openRoute
        ) {
            PrerequisiteExample(prerequisite: prerequisite)
        }
    }

    private func openRoute() {
        open(prerequisite.route, in: section)
    }
}
