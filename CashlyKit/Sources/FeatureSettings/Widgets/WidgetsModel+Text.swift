import CashlyDomain
import CashlyWidgetUI
import Foundation

enum WidgetPreview: Hashable, Identifiable {
    case home(WidgetSize)
    case lockScreen

    var id: String {
        switch self {
        case .home(let size): size.rawValue
        case .lockScreen: "lockScreen"
        }
    }
}

extension WidgetsModel {
    func previews(for widget: CashlyWidget) -> [WidgetPreview] {
        let home = widget.sizes.filter { !$0.isAccessory }.map(WidgetPreview.home)
        return widget.sizes.contains(where: \.isAccessory) ? home + [.lockScreen] : home
    }

    func lockScreenSizes(for widget: CashlyWidget) -> [WidgetSize] {
        widget.sizes.filter(\.isAccessory)
    }

    func title(_ preview: WidgetPreview) -> String {
        switch preview {
        case .home(.small): String(appLocalized: "Small (widget)")
        case .home(.medium): String(appLocalized: "Medium (widget)")
        case .home: String(appLocalized: "Large (widget)")
        case .lockScreen: String(appLocalized: "Lock Screen")
        }
    }

    func title(_ widget: CashlyWidget) -> String {
        switch widget {
        case .budget: String(appLocalized: "One Budget")
        case .month: String(appLocalized: "This Month")
        case .budgets: String(appLocalized: "Budgets")
        case .bills: String(appLocalized: "Upcoming Bills")
        }
    }

    func detail(_ widget: CashlyWidget) -> String {
        switch widget {
        case .budget:
            String(appLocalized: "Spent, planned and what is left of the budget you pick below.")
        case .month:
            String(
                appLocalized:
                    "Spent, planned and what is left of the whole month, with a chart by category."
            )
        case .budgets:
            String(appLocalized: "Every budget of the month with its bar, side by side.")
        case .bills:
            String(appLocalized: "Pending bills by due date. Tap one to open it in Cashly.")
        }
    }

    func source(_ widget: CashlyWidget) -> String {
        widget.followsChoice
            ? String(appLocalized: "Uses your pick") : String(appLocalized: "No setup")
    }

    var sourceTitle: String {
        isSample ? String(appLocalized: "Example data") : snapshot.monthName
    }

    var updatedText: String? {
        guard let stored else { return nil }
        let relative = stored.generatedAt.formatted(
            .relative(presentation: .named).locale(.app))
        return String(appLocalized: "Updated \(relative)")
    }

    var choiceFooter: String {
        isSample
            ? String(appLocalized: "Your budgets show up here once Cashly has your month.")
            : String(
                appLocalized:
                    "Every One Budget widget, on the Home Screen and on the Lock Screen, follows this choice."
            )
    }

    var galleryFooter: String {
        String(appLocalized: "Widgets refresh every hour and whenever you open Cashly.")
    }

    var addSteps: [String] {
        #if os(macOS)
            [
                String(appLocalized: "Control-click the desktop and choose Edit Widgets."),
                String(appLocalized: "Search for Cashly in the widget gallery."),
                String(appLocalized: "Drag a widget to the desktop or to Notification Center."),
            ]
        #elseif os(visionOS)
            [
                String(appLocalized: "Open Widgets from the Home View."),
                String(appLocalized: "Search for Cashly in the widget gallery."),
                String(appLocalized: "Pick a widget and place it on a wall or a table."),
            ]
        #else
            [
                String(appLocalized: "Touch and hold an empty area of the Home Screen."),
                String(appLocalized: "Tap Edit, then Add Widget, and search for Cashly."),
                String(appLocalized: "Pick a widget and a size, then tap Add Widget."),
                String(
                    appLocalized:
                        "For the Lock Screen, touch and hold it, tap Customize and tap the area under the clock."
                ),
            ]
        #endif
    }
}
