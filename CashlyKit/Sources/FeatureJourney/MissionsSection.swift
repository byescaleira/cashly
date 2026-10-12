import CashlyDesignSystem
import CashlyGame
import SwiftUI

struct MissionsSection: View {
    @Environment(JourneyModel.self) private var journey
    @Environment(\.appTint) private var appTint

    var body: some View {
        if let missions = journey.progress?.missions, !missions.isEmpty {
            let done = missions.filter(\.isCompleted).count
            let summary = "\(done)/\(missions.count)"
            Section {
                ForEach(missions, id: \.kind) { MissionRow(mission: $0) }
            } header: {
                HStack {
                    Text("This Week").sectionTitle()
                    Spacer()
                    Chip(summary, color: done == missions.count ? .positive : appTint)
                        .contentTransition(.numericText())
                }
            } footer: {
                Text(journey.missionsFooter)
            }
        }
    }
}

private struct MissionRow: View {
    @Environment(\.appTint) private var appTint
    let mission: Mission

    var body: some View {
        let color: Color = mission.isCompleted ? .positive : appTint
        HStack(spacing: .spaceM) {
            SymbolBadge(
                mission.isCompleted ? "checkmark" : mission.kind.symbol, color: color, size: .badgeM
            )
            .contentTransition(.symbolEffect(.replace))
            VStack(alignment: .leading, spacing: .spaceXS) {
                Text(mission.kind.title).font(.rowTitle)
                ProgressView(value: mission.progress)
                    .tint(color)
                    .animation(.smooth, value: mission.progress)
            }
            if mission.isCompleted {
                Chip("+\(Mission.xp) XP", color: .positive)
            } else {
                Text("\(min(mission.value, mission.kind.target))/\(mission.kind.target)")
                    .font(.footnote.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
        }
        .animation(.smooth, value: mission.isCompleted)
        .accessibilityElement(children: .combine)
        .sensoryFeedback(.success, trigger: mission.isCompleted) { _, isCompleted in isCompleted }
    }
}
