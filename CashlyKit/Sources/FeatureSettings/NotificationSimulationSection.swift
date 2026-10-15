#if DEBUG
    import CashlyDesignSystem
    import FeatureCore
    import SwiftUI

    struct NotificationSimulationSection: View {
        var body: some View {
            ModelHost(NotificationSimulation()) { NotificationSimulationRows() }
        }
    }

    private struct NotificationSimulationRows: View {
        @Environment(NotificationSimulation.self) private var simulation
        @Environment(SessionModel.self) private var session: SessionModel?
        @Environment(\.appTint) private var appTint

        var body: some View {
            @Bindable var simulation = simulation
            Section {
                if simulation.status == .notDetermined {
                    Button {
                        Task { await simulation.requestPermission() }
                    } label: {
                        IconRow("Allow Notifications", symbol: "bell.badge", color: appTint)
                    }
                } else if simulation.status == .denied, let url = simulation.settingsURL {
                    Link(destination: url) {
                        IconRow("Open Notification Settings", symbol: "gear", color: .companion)
                    }
                }
                ForEach(SimulatedNotification.allCases) { kind in
                    NotificationSimulationRow(kind: kind)
                }
            } header: {
                Text("Simulate Notifications")
            } footer: {
                Text(simulation.footer)
            }
            .task(id: session?.loadKey) {
                await simulation.load(user: session?.user, repositories: session?.repositories)
            }
            .errorAlert($simulation.error)
        }
    }

    private struct NotificationSimulationRow: View {
        @Environment(NotificationSimulation.self) private var simulation
        let kind: SimulatedNotification

        var body: some View {
            Button {
                Task { await simulation.simulate(kind) }
            } label: {
                HStack(spacing: .spaceM) {
                    SymbolBadge(kind.symbol, color: kind.color, size: .badgeM)
                    VStack(alignment: .leading, spacing: .spaceHairline) {
                        Text(kind.title).font(.rowTitle)
                        Text(simulation.detail(of: kind))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if simulation.scheduled == kind {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.positive)
                    }
                }
                .contentShape(.rect)
            }
            .tint(Color.primary)
            .disabled(!simulation.canSimulate(kind))
            .accessibilityElement(children: .combine)
        }
    }

    extension SimulatedNotification {
        fileprivate var color: Color {
            switch self {
            case .bill: .retroDenim
            case .budgetWarning: .warning
            case .budgetOver: .negative
            case .weekly: .retroTeal
            case .planning: .retroOlive
            case .capture: .retroOrange
            }
        }
    }
#endif
