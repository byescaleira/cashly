#if os(iOS)
    import ActivityKit

    public struct ChallengeActivityAttributes: ActivityAttributes, Sendable {
        public typealias ContentState = JourneySnapshot.Challenge

        public let id: String
        public let currencyCode: String

        public init(id: String, currencyCode: String) {
            self.id = id
            self.currencyCode = currencyCode
        }
    }
#endif
