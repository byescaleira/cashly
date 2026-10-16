import CashlyDomain
import FeatureCore
import Foundation

extension TransactionEditorModel {
    public var rateRequest: RateRequest {
        RateRequest(
            currency: draft.paidCurrency, day: ExchangeTable.day(for: draft.date),
            isForeign: draft.isForeign && !draft.isEstimated)
    }

    public var suggestedPaidCurrencies: [String] {
        var codes = [draft.currencyCode]
        if let local = Locale.current.currency?.identifier, !codes.contains(local) {
            codes.append(local)
        }
        if let saved = draft.exchange?.currencyCode, !codes.contains(saved) { codes.append(saved) }
        return codes
    }

    public var amountInput: Double {
        get { usesPaidAmount ? draft.paidAmount : draft.amount }
        set {
            if usesPaidAmount { draft.paidAmount = newValue } else { draft.amount = newValue }
        }
    }

    public var inputCurrency: String {
        usesPaidAmount ? draft.paidCurrency : draft.currencyCode
    }

    public var isAmountLocked: Bool { draft.isEstimated }

    public var showsExchangeNotice: Bool { draft.isForeign || draft.isEstimated }

    public var canEditParticipants: Bool { draft.kind == .expense && !draft.isEstimated }

    public var realAmount: String? {
        guard usesPaidAmount else { return nil }
        return "≈ \(draft.amount.formatted(.currency(code: draft.currencyCode).locale(.app)))"
    }

    private var usesPaidAmount: Bool { draft.isForeign && !draft.isEstimated }

    public func lockedPaidCurrencies(with pro: ProAccess) -> Set<String> {
        pro.isPro ? [] : Set(paidCurrencies).subtracting([draft.currencyCode])
    }

    public func selectPaidCurrency(_ code: String, pro: ProAccess) {
        if code == draft.currencyCode {
            choosePaidCurrency(code)
        } else {
            pro.perform { choosePaidCurrency(code) }
        }
    }

    public var rateDescription: String? {
        guard draft.isForeign, let rate = draft.rate, let date = draft.rateDate else { return nil }
        let day = date.formatted(.dateTime.day().month(.abbreviated).year().locale(.app))
        return String(
            appLocalized:
                "\(CurrencyText.rate(rate, from: draft.paidCurrency, to: draft.currencyCode)) on \(day)"
        )
    }

    public var estimateDescription: String? {
        guard let estimate = draft.estimate else { return nil }
        return CurrencyText.estimate(estimate) + " "
            + String(
                appLocalized: "The amount, installments and participants can't be changed here.")
    }

    public func loadPaidCurrencies() async {
        guard let codes = try? await rates.currencies(), !codes.isEmpty else { return }
        paidCurrencies = Array(Set(codes).union(suggestedPaidCurrencies)).sorted()
    }

    public func choosePaidCurrency(_ code: String) {
        guard code != draft.paidCurrency, !draft.isEstimated else { return }
        if draft.isForeign {
            if code == draft.currencyCode { draft.amount = draft.paidAmount }
        } else {
            draft.paidAmount = draft.amount
        }
        draft.paidCurrency = code
        draft.rate = nil
        draft.rateDate = nil
        rateFailed = false
        if !draft.isForeign { updateShares() }
    }

    public func updateRate() async {
        guard rateRequest.isForeign else { return }
        if let exchange = keptExchange {
            draft.rate = exchange.rate
            draft.rateDate = exchange.date
            convertPaidAmount()
            return
        }
        isFetchingRate = true
        defer { isFetchingRate = false }
        rateFailed = false
        draft.rate = nil
        draft.rateDate = nil
        let request = rateRequest
        do {
            let table = try await rates.table(base: draft.paidCurrency, on: draft.date)
            guard request == rateRequest else { return }
            guard let rate = table.rate(to: draft.currencyCode) else {
                throw CashlyError.onFetch
            }
            draft.rate = rate
            draft.rateDate = table.date ?? draft.date
            convertPaidAmount()
        } catch is CancellationError {
        } catch {
            guard request == rateRequest else { return }
            draft.rate = nil
            draft.rateDate = nil
            rateFailed = true
        }
    }

    public func convertPaidAmount() {
        guard draft.isForeign, !draft.isEstimated else { return }
        guard let rate = draft.rate, let paid = try? Money(validating: draft.paidAmount),
            let real = try? paid.converted(by: rate)
        else {
            draft.amount = .zero
            return
        }
        draft.amount = real.doubleValue
    }
}

public struct RateRequest: Hashable, Sendable {
    let currency: String
    let day: String
    let isForeign: Bool
}
