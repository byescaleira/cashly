#if os(iOS)
    import ActivityKit

    public struct StreakActivityAttributes: ActivityAttributes, Sendable {
        public typealias ContentState = JourneySnapshot.StreakRisk

        public let id: String

        public init(id: String) {
            self.id = id
        }
    }
#endif
