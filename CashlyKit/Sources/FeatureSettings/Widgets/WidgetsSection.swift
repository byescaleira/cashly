import CashlyDesignSystem
import CashlyWidgetUI
import FeatureCore
import SwiftUI

struct WidgetsSection: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        ModelHost(WidgetsModel(settings: settings)) { WidgetsContent() }
    }
}

private struct WidgetsContent: View {
    @Environment(WidgetsModel.self) private var widgets

    var body: some View {
        WidgetsHeroSection()
        WidgetChoiceSection()
        ForEach(widgets.gallery) { WidgetGallerySection(widget: $0) }
        #if os(iOS)
            WidgetControlSection()
        #endif
        WidgetsHowToSection()
    }
}

private struct WidgetsHeroSection: View {
    @Environment(WidgetsModel.self) private var widgets

    var body: some View {
        Section {
            VStack(spacing: .spaceM) {
                WidgetStatus()
                WidgetStage(widget: .budget)
                WidgetPreviewPicker(widget: .budget)
            }
            .padding(.vertical, .spaceS)
            .task { widgets.load() }
        } header: {
            WidgetSectionHeader(widget: .budget)
        } footer: {
            Text(verbatim: widgets.detail(.budget))
        }
    }
}

private struct WidgetStatus: View {
    @Environment(WidgetsModel.self) private var widgets
    @Environment(\.appTint) private var appTint

    var body: some View {
        HStack(spacing: .spaceS) {
            Chip(
                widgets.sourceTitle, color: widgets.isSample ? .secondary : appTint, shape: .capsule
            )
            if let updated = widgets.updatedText {
                Text(verbatim: updated)
                    .font(.rowDetail)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct WidgetGallerySection: View {
    @Environment(WidgetsModel.self) private var widgets
    let widget: CashlyWidget

    var body: some View {
        Section {
            VStack(spacing: .spaceM) {
                WidgetStage(widget: widget)
                WidgetPreviewPicker(widget: widget)
            }
            .padding(.vertical, .spaceS)
        } header: {
            WidgetSectionHeader(widget: widget)
        } footer: {
            Text(verbatim: widgets.detail(widget))
        }
    }
}

private struct WidgetSectionHeader: View {
    @Environment(WidgetsModel.self) private var widgets
    @Environment(\.appTint) private var appTint
    let widget: CashlyWidget

    var body: some View {
        HStack(alignment: .center) {
            Label {
                Text(verbatim: widgets.title(widget)).sectionTitle()
            } icon: {
                Image(systemName: widget.symbol).foregroundStyle(appTint)
            }
            Spacer(minLength: .spaceS)
            Chip(
                widgets.source(widget), color: widget.followsChoice ? appTint : .secondary,
                shape: .capsule)
        }
        .textCase(nil)
    }
}
