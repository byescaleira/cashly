import Foundation

public struct TransactionAllocation: Sendable {
    public let owner: Money
    public let participants: [String: Money]
    public static func resolve(total: Money, participants: [Participant]) throws -> Self {
        guard total.minorUnits > 0, Set(participants.map(\.id)).count == participants.count else {
            throw CashlyError.onSave
        }
        guard !participants.isEmpty else { return Self(owner: total, participants: [:]) }
        let ordered = participants.sorted { $0.id < $1.id }
        if ordered.allSatisfy({ $0.splitMode == .equal }) {
            guard ordered.allSatisfy({ $0.splitValue == Double(ordered.count + 1) }) else {
                throw CashlyError.onSave
            }
            let shares = try total.divided(into: ordered.count + 1)
            return Self(
                owner: shares[0],
                participants: Dictionary(
                    uniqueKeysWithValues: ordered.enumerated().map {
                        ($0.element.id, shares[$0.offset + 1])
                    })
            )
        }
        if ordered.allSatisfy({ $0.splitMode == .percentage }) {
            let ratios = try ordered.map { participant -> Decimal in
                guard participant.splitValue.isFinite, (0...1).contains(participant.splitValue),
                    let value = Decimal(
                        string: String(participant.splitValue),
                        locale: Locale(identifier: "en_US_POSIX"))
                else { throw CashlyError.onSave }
                return value
            }
            let sum = ratios.reduce(Decimal.zero, +)
            guard sum <= 1 else {
                throw CashlyError.invalidInput(
                    String(appLocalized: "The percentages add up to more than 100%."))
            }
            let exact = ([1 - sum] + ratios).map { Decimal(total.minorUnits) * $0 }
            var values = exact.map { amount -> Int64 in
                var amount = amount
                var whole = Decimal()
                NSDecimalRound(&whole, &amount, 0, .down)
                return NSDecimalNumber(decimal: whole).int64Value
            }
            let remainder = total.minorUnits - values.reduce(0, +)
            let priority = exact.indices.sorted { a, b in
                let af = exact[a] - Decimal(values[a])
                let bf = exact[b] - Decimal(values[b])
                return af == bf ? a < b : af > bf
            }
            guard remainder >= 0, remainder <= Int64(values.count) else { throw CashlyError.onSave }
            for index in priority.prefix(Int(remainder)) { values[index] += 1 }
            return Self(
                owner: Money(minorUnits: values[0]),
                participants: Dictionary(
                    uniqueKeysWithValues: ordered.enumerated().map {
                        ($0.element.id, Money(minorUnits: values[$0.offset + 1]))
                    }))
        }
        var shares: [String: Money] = [:]
        var sum = Money.zero
        for participant in ordered {
            guard participant.splitValue.isFinite, participant.splitValue >= 0 else {
                throw CashlyError.onSave
            }
            let share: Money
            switch participant.splitMode {
            case .fixedAmount: share = try Money(validating: participant.splitValue)
            case .payerBased: share = .zero
            case .percentage:
                guard participant.splitValue <= 1 else { throw CashlyError.onSave }
                let ratio =
                    Decimal(
                        string: String(participant.splitValue),
                        locale: Locale(identifier: "en_US_POSIX"))
                    ?? 0
                var value = Decimal(total.minorUnits) * ratio
                var rounded = Decimal()
                NSDecimalRound(&rounded, &value, 0, .plain)
                share = Money(minorUnits: NSDecimalNumber(decimal: rounded).int64Value)
            case .equal:
                throw CashlyError.invalidInput(
                    String(appLocalized: "An equal split must apply to every profile."))
            }
            guard share.minorUnits >= 0 else { throw CashlyError.onSave }
            shares[participant.id] = share
            sum = try sum.adding(share)
        }
        guard sum <= total else {
            throw CashlyError.invalidInput(
                String(appLocalized: "The shares add up to more than the transaction amount."))
        }
        return Self(owner: try total.subtracting(sum), participants: shares)
    }
}
