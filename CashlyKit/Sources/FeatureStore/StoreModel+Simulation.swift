import CashlyDomain
import FeatureCore
import Foundation

public enum SimulatedPlan: String, CaseIterable, Identifiable, Sendable {
    case real, free, trial, pro

    public var id: String { rawValue }
}

public enum StoreOverride {
    public static func entitlement(in defaults: UserDefaults = .standard) -> Entitlement? {
        StoreSimulation.stored(in: defaults)?.entitlement
    }
}

struct StoreSimulation: Equatable, Sendable {
    var plan: SimulatedPlan
    var expires: Date
    var owned: Set<ShopItem>

    var entitlement: Entitlement? {
        switch plan {
        case .real: nil
        case .free: Entitlement.none
        case .trial: .trial(expires: expires)
        case .pro: .active(expires: expires)
        }
    }

    static func stored(in defaults: UserDefaults) -> StoreSimulation? {
        #if DEBUG
            guard
                let plan = defaults.string(forKey: Key.plan).flatMap(SimulatedPlan.init(rawValue:))
            else { return nil }
            let owned = defaults.stringArray(forKey: Key.owned) ?? []
            return StoreSimulation(
                plan: plan,
                expires: defaults.object(forKey: Key.expires) as? Date ?? .distantFuture,
                owned: Set(owned.compactMap(ShopItem.init(rawValue:))))
        #else
            nil
        #endif
    }
}

#if DEBUG
    extension StoreSimulation {
        enum Key {
            static let plan = "cashly.developer.store.plan"
            static let expires = "cashly.developer.store.expires"
            static let owned = "cashly.developer.store.owned"
        }

        func save(to defaults: UserDefaults) {
            defaults.set(plan.rawValue, forKey: Key.plan)
            defaults.set(expires, forKey: Key.expires)
            defaults.set(owned.map(\.rawValue).sorted(), forKey: Key.owned)
        }

        static func clear(in defaults: UserDefaults) {
            for key in [Key.plan, Key.expires, Key.owned] { defaults.removeObject(forKey: key) }
        }
    }

    extension StoreModel {
        public static let simulatedItems = ShopItem.allCases.filter { $0.kind != .subscription }

        public var isSimulating: Bool { simulation != nil }

        public var simulatedPlan: SimulatedPlan {
            get { simulation?.plan ?? .real }
            set {
                guard newValue != .real else { return resetSimulation() }
                update {
                    $0.plan = newValue
                    $0.expires = newValue.expiry(from: .now)
                }
            }
        }

        public var simulationStatus: String {
            isSimulating
                ? String(appLocalized: "Simulating: \(simulatedPlan.title)")
                : String(appLocalized: "Showing the real StoreKit state.")
        }

        public var entitlementSummary: String {
            [entitlement.title, entitlement.detail].compactMap { $0 }.joined(separator: " · ")
        }

        public var simulatedOwnedSummary: String {
            let count = Self.simulatedItems.filter(owned.contains).count
            return String(appLocalized: "\(count) of \(Self.simulatedItems.count)")
        }

        public func simulate(_ item: ShopItem, owned: Bool) {
            update { if owned { $0.owned.insert(item) } else { $0.owned.remove(item) } }
        }

        public func resetSimulation() {
            simulation = nil
            StoreSimulation.clear(in: defaults)
        }

        private func update(_ change: (inout StoreSimulation) -> Void) {
            var updated =
                simulation
                ?? StoreSimulation(
                    plan: SimulatedPlan(storeEntitlement),
                    expires: storeEntitlement.expires ?? .distantFuture, owned: storeOwned)
            change(&updated)
            simulation = updated
            updated.save(to: defaults)
        }
    }

    extension SimulatedPlan {
        public var title: String {
            switch self {
            case .real: String(appLocalized: "Real (StoreKit)")
            case .free: String(appLocalized: "Free")
            case .trial: String(appLocalized: "Trial")
            case .pro: String(appLocalized: "Pro")
            }
        }

        init(_ entitlement: Entitlement) {
            self =
                switch entitlement {
                case .trial: .trial
                case .active: .pro
                case .none, .expired: .free
                }
        }

        func expiry(from date: Date) -> Date {
            switch self {
            case .trial: date.addingTimeInterval(3 * 86_400)
            case .pro: date.addingTimeInterval(30 * 86_400)
            case .free, .real: date
            }
        }
    }
#endif
