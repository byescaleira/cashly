import CashlyDesignSystem
import CashlyGame
import SwiftUI

struct MissionsSection: View {
    @Environment(JourneyModel.self) private var journey
    @Environment(\.appTint) private var appTint

    var body: some View {
        if let missions = journey.progress?.missions, !missions.isEmpty {
            let isDone = journey.missionsDone == missions.count
            Section {
                ForEach(missions.enumerated(), id: \.element.kind) { index, mission in
                    MissionRow(mission: mission).cascade(index)
                }
            } header: {
                HStack {
                    Text("This Week").sectionTitle()
                    Spacer()
                    Chip(
                        "\(journey.missionsDone)/\(missions.count)",
                        color: isDone ? .positive : appTint
                    )
                    .contentTransition(.numericText())
                }
            } footer: {
                Text(journey.missionsFooter)
            }
        }
    }
}

private struct MissionRow: View {
    @Environment(JourneyModel.self) private var journey
    @Environment(\.appTint) private var appTint
    let mission: Mission

    var body: some View {
        let color: Color = mission.isCompleted ? .positive : appTint
        HStack(spacing: .spaceM) {
            SymbolBadge(
                mission.isCompleted ? "checkmark" : mission.kind.symbol, color: color,
                size: .badgeM,
                style: mission.isCompleted ? .filled : .tinted
            )
            .contentTransition(.symbolEffect(.replace))
            VStack(alignment: .leading, spacing: .spaceXS) {
                HStack(alignment: .firstTextBaseline, spacing: .spaceS) {
                    Text(mission.kind.title)
                        .font(.rowTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Chip("+\(Mission.xp) XP", color: mission.isCompleted ? .positive : .secondary)
                        .fixedSize()
                }
                HStack(spacing: .spaceS) {
                    FillingBar(value: mission.progress, color: color)
                    Text(journey.valueCaption(of: mission))
                        .font(.footnote.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
            }
        }
        .animation(.smooth, value: mission.isCompleted)
        .accessibilityElement(children: .combine)
        .sensoryFeedback(.success, trigger: mission.isCompleted) { _, isCompleted in isCompleted }
    }
}
