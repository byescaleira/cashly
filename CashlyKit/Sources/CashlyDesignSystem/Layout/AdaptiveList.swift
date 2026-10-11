import SwiftUI

public struct AdaptiveList<Content: View>: View {
    private let columnWidth: CGFloat
    private let content: Content
    @State private var columns = 1

    public init(columnWidth: CGFloat = 320, @ViewBuilder content: () -> Content) {
        self.columnWidth = columnWidth
        self.content = content()
    }

    public var body: some View {
        Group {
            if columns > 1 {
                ScrollView {
                    Group(sections: content) { sections in
                        HStack(alignment: .top, spacing: GroupedMetrics.columnSpacing) {
                            ForEach(0..<columns, id: \.self) { column in
                                LazyVStack(spacing: GroupedMetrics.sectionSpacing) {
                                    ForEach(sections.column(column, of: columns)) {
                                        GroupedSection(section: $0)
                                    }
                                }
                            }
                        }
                        .padding(GroupedMetrics.margin)
                    }
                }
                .background(.groupedBackground)
                .environment(\.isGroupedColumn, true)
            } else {
                List { content }
            }
        }
        .onGeometryChange(for: Int.self) { [columnWidth] proxy in
            GroupedMetrics.columns(in: proxy.size.width, columnWidth: columnWidth)
        } action: {
            columns = $0
        }
    }
}

extension SectionCollection {
    fileprivate func column(_ column: Int, of count: Int) -> [SectionConfiguration] {
        enumerated().filter { $0.offset % count == column }.map(\.element)
    }
}

extension GroupedMetrics {
    fileprivate static func columns(in width: CGFloat, columnWidth: CGFloat) -> Int {
        let available = width - margin * 2
        let fit = (available + columnSpacing) / (columnWidth + columnSpacing)
        return max(1, Int(fit))
    }
}
