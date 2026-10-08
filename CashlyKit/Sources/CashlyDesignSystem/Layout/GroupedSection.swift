import SwiftUI

enum GroupedMetrics {
    static let margin: CGFloat = 20
    static let columnSpacing: CGFloat = 20
    static let sectionSpacing: CGFloat = 24
    static let rowInset: CGFloat = 20
    static let rowHeight: CGFloat = 44
    static let cornerRadius: CGFloat = 26
}

struct GroupedSection: View {
    let section: SectionConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !section.header.isEmpty {
                VStack(alignment: .leading) { section.header }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, GroupedMetrics.rowInset)
            }
            if !section.content.isEmpty {
                VStack(spacing: 0) {
                    ForEach(section.content) { row in
                        row
                            .padding(.horizontal, GroupedMetrics.rowInset)
                            .padding(.vertical, 11)
                            .frame(
                                maxWidth: .infinity, minHeight: GroupedMetrics.rowHeight,
                                alignment: .leading)
                        if row.id != section.content.last?.id {
                            Divider().padding(.leading, GroupedMetrics.rowInset)
                        }
                    }
                }
                .background(.groupedRow, in: .rect(cornerRadius: GroupedMetrics.cornerRadius))
            }
            if !section.footer.isEmpty {
                VStack(alignment: .leading) { section.footer }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, GroupedMetrics.rowInset)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
