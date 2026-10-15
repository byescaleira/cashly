#if os(iOS)
    import ActivityKit
    import CashlyDomain
    import Foundation

    @MainActor
    public enum JourneyActivities {
        public static func sync(now: Date = .now, defaults: UserDefaults = .standard) async {
            await sync(try? JourneySnapshotStore.shared?.read(), now: now, defaults: defaults)
        }

        public static func sync(
            _ snapshot: JourneySnapshot?, now: Date = .now, defaults: UserDefaults = .standard
        ) async {
            let isEnabled = JourneySnapshot.isLiveActivityEnabled(defaults)
            let risk = isEnabled ? snapshot?.streakRisk(at: now) : nil
            let ending = isEnabled && risk == nil ? snapshot?.challengeEndingToday(at: now) : nil
            await reconcile(
                risk.map { StreakActivityAttributes(id: $0.id) }, state: risk,
                staleDate: risk?.deadline)
            await reconcile(
                ending.map {
                    ChallengeActivityAttributes(
                        id: $0.id, currencyCode: snapshot?.currencyCode ?? "")
                }, state: ending, staleDate: ending?.ends
            ) { snapshot?.finishedChallenge(id: $0) }
        }

        nonisolated private static func reconcile<Attributes: JourneyActivity>(
            _ attributes: Attributes?, state: Attributes.ContentState?, staleDate: Date?,
            final: @Sendable (String) -> Attributes.ContentState? = { _ in nil }
        ) async {
            let running = Activity<Attributes>.activities
            for activity in running {
                if let attributes, let state, activity.attributes.id == attributes.id {
                    if activity.content.state != state {
                        await activity.update(ActivityContent(state: state, staleDate: staleDate))
                    }
                } else {
                    let last = final(activity.attributes.id)
                    await activity.end(
                        last.map { ActivityContent(state: $0, staleDate: nil) },
                        dismissalPolicy: last == nil ? .immediate : .default)
                }
            }
            guard let attributes, let state, ActivityAuthorizationInfo().areActivitiesEnabled,
                !running.contains(where: { $0.attributes.id == attributes.id })
            else { return }
            _ = try? Activity.request(
                attributes: attributes, content: ActivityContent(state: state, staleDate: staleDate)
            )
        }
    }

    protocol JourneyActivity: ActivityAttributes, Sendable where ContentState: Sendable {
        var id: String { get }
    }

    extension StreakActivityAttributes: JourneyActivity {}
    extension ChallengeActivityAttributes: JourneyActivity {}
#endif
