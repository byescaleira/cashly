import CashlyDomain
import FeatureCore
import Testing

@MainActor
struct ProAccessTests {
    @Test func writesNeedAnActivePlanOnlyWhenEnforced() {
        var presented = 0
        var performed = 0
        let locked = ProAccess(entitlement: .expired(.now), isEnforced: true) { presented += 1 }
        locked.perform { performed += 1 }
        #expect(!locked.canWrite)
        #expect((presented, performed) == (1, 0))
        let trial = ProAccess(entitlement: .trial(expires: .distantFuture), isEnforced: true) {
            presented += 1
        }
        trial.perform { performed += 1 }
        #expect(trial.canWrite)
        #expect((presented, performed) == (1, 1))
        let relaxed = ProAccess(entitlement: .none, isEnforced: false) { presented += 1 }
        relaxed.perform { performed += 1 }
        #expect(relaxed.canWrite)
        #expect((presented, performed) == (1, 2))
    }

    @Test func onlyEditorsRequirePro() {
        #expect(Route.addTransaction(id: nil).requiresPro)
        #expect(Route.addUser(id: "u").requiresPro)
        #expect(!Route.budgets.requiresPro)
        #expect(!Route.shop.requiresPro)
    }
}
