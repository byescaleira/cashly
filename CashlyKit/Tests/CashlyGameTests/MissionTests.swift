import Foundation
import Testing

@testable import CashlyGame

struct MissionTests {
    @Test func weeklyMissionsAreDeterministicAndVaried() {
        for week in 0..<200 {
            let kinds = Mission.kinds(forWeek: week, seed: 42)
            #expect(kinds == Mission.kinds(forWeek: week, seed: 42))
            #expect(kinds.count == Mission.perWeek)
            #expect(Set(kinds).count == kinds.count)
            #expect(!(kinds.contains(.recordFive) && kinds.contains(.recordTen)))
            #expect(!(kinds.contains(.trackFourDays) && kinds.contains(.trackSixDays)))
        }
    }

    @Test func differentUsersGetDifferentWeeks() {
        let first = (0..<20).map { Mission.kinds(forWeek: $0, seed: Mission.seed("a")) }
        let second = (0..<20).map { Mission.kinds(forWeek: $0, seed: Mission.seed("b")) }
        #expect(first != second)
    }

    @Test func missionsMeasureTheCurrentWeek() {
        var game = GameFixture(today: 15)
        game.track(days: 12...15)
        for day in 12...14 { game.spend(500, day: day) }
        let missions = game.progress.missions
        #expect(missions.count == Mission.perWeek)
        for mission in missions {
            switch mission.kind {
            case .recordFive, .recordTen: #expect(mission.value == 3)
            case .trackFourDays, .trackSixDays: #expect(mission.value == 4)
            case .noSpendDay: #expect(mission.value == 4)
            default: #expect(mission.value == 0)
            }
        }
    }
}
