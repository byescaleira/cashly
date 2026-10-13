import CashlyDomain
import Foundation
import Testing

struct CaptureTests {
    @Test func merchantKeysDropNoiseAccentsAndDigits() {
        #expect(MerchantMemory.key(for: "IFD*IFOOD 12345") == "ifood")
        #expect(MerchantMemory.key(for: "Padaria São João LTDA") == "padaria sao joao")
        #expect(MerchantMemory.key(for: "PAG*JoseSilva") == "josesilva")
        #expect(MerchantMemory.key(for: "UBER *TRIP 4F2") == "uber trip")
        #expect(MerchantMemory.key(for: "  Mercado   Livre S/A ") == "mercado livre")
        #expect(MerchantMemory.key(for: "4242") == "4242")
    }

    @Test func duplicatesShareOwnerAmountMerchantAndMinute() {
        let date = Date(timeIntervalSince1970: 1_790_000_000)
        let first = Capture(
            ownerID: "owner", money: Money(minorUnits: 3290), merchant: "IFD*IFOOD", date: date,
            source: .wallet)
        let sameMinute = Capture(
            ownerID: "owner", money: Money(minorUnits: 3290), merchant: "iFood 77",
            date: date.addingTimeInterval(20), source: .share)
        let nextMinute = Capture(
            ownerID: "owner", money: Money(minorUnits: 3290), merchant: "iFood",
            date: date.addingTimeInterval(60), source: .wallet)
        let otherOwner = Capture(
            ownerID: "friend", money: Money(minorUnits: 3290), merchant: "iFood", date: date,
            source: .wallet)
        #expect(first.isDuplicate(of: sameMinute))
        #expect(!first.isDuplicate(of: nextMinute))
        #expect(!first.isDuplicate(of: otherOwner))
        #expect(first.status == .pending)
    }
}
