import CashlyDomain
import FeatureCore
import Testing

@MainActor
struct ProAccessTests {
    @Test func proFeaturesNeedAnActivePlanOnlyWhenEnforced() {
        var presented = 0
        var performed = 0
        let free = ProAccess(entitlement: .expired(.now), isEnforced: true) { presented += 1 }
        free.perform { performed += 1 }
        #expect(!free.isPro)
        #expect((presented, performed) == (1, 0))
        let trial = ProAccess(entitlement: .trial(expires: .distantFuture), isEnforced: true) {
            presented += 1
        }
        trial.perform { performed += 1 }
        #expect(trial.isPro)
        #expect((presented, performed) == (1, 1))
        let relaxed = ProAccess(entitlement: .none, isEnforced: false) { presented += 1 }
        relaxed.perform { performed += 1 }
        #expect(relaxed.isPro)
        #expect((presented, performed) == (1, 2))
    }

    @Test func onHoldOpensTheSubscriptionInsteadOfThePaywall() {
        let navigation = CashlyNavigation()
        navigation.presentPro(isOnHold: true)
        #expect(navigation.isManagingSubscription)
        #expect(!navigation.isShowingPaywall)
        navigation.presentPro(isOnHold: false)
        #expect(navigation.isShowingPaywall)
        let access = ProAccess(entitlement: .expired(.now), isEnforced: true, isOnHold: true) {}
        #expect(access.isOnHold)
        #expect(!access.isPro)
    }
}
