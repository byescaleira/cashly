import CashlyDesignSystem
import SwiftUI

#if os(iOS)
    struct WidgetControlSection: View {
        var body: some View {
            Section {
                HStack(spacing: .spaceL) {
                    ControlPreview()
                    VStack(alignment: .leading, spacing: .space2XS) {
                        Text("New Expense").font(.rowTitle)
                        Text(
                            "Opens Cashly on a new expense, from Control Center, the Lock Screen or the Action Button."
                        )
                        .font(.rowDetail)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, .spaceXS)
                .accessibilityElement(children: .combine)
            } header: {
                Text("Controls").sectionTitle()
            } footer: {
                Text(
                    "In Control Center, touch and hold an empty area and tap Add a Control. For the Action Button, open Settings › Action Button and choose Controls."
                )
            }
        }
    }

    private struct ControlPreview: View {
        @Environment(\.appTint) private var appTint
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @State private var isPressed = false

        var body: some View {
            Image(systemName: "plus.circle")
                .font(.icon(.l))
                .foregroundStyle(appTint)
                .symbolEffect(.bounce, options: .nonRepeating, value: isPressed)
                .frame(width: .badgeXL + .spaceS, height: .badgeXL + .spaceS)
                .background(Color.subtleFill, in: .circle)
                .task { if !reduceMotion { isPressed = true } }
                .accessibilityHidden(true)
        }
    }
#endif
