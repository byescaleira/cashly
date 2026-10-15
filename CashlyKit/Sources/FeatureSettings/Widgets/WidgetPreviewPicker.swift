import CashlyDesignSystem
import CashlyWidgetUI
import SwiftUI

struct WidgetPreviewPicker: View {
    @Environment(WidgetsModel.self) private var widgets
    let widget: CashlyWidget

    var body: some View {
        let selection = widgets.preview(for: widget)
        FlowLayout(spacing: .spaceS) {
            ForEach(widgets.previews(for: widget)) { PreviewChip(widget: widget, preview: $0) }
        }
        .frame(maxWidth: .infinity)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

private struct PreviewChip: View {
    @Environment(WidgetsModel.self) private var widgets
    @Environment(\.appTint) private var appTint
    let widget: CashlyWidget
    let preview: WidgetPreview

    var body: some View {
        let isSelected = widgets.preview(for: widget) == preview
        Button {
            widgets.show(preview, for: widget)
        } label: {
            Chip(widgets.title(preview), color: isSelected ? appTint : .secondary, shape: .capsule)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
