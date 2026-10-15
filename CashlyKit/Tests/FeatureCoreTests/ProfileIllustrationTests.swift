import CashlyDomain
import CashlyResource
import FeatureCore
import Foundation
import Testing

struct ProfileIllustrationTests {
    typealias Section = ProfileIllustration.Section

    @Test func sectionsFollowTheManifestOrder() {
        #expect(
            Section.allCases.map(\.rawValue) == [
                "classics", "brazil", "savers", "ocean", "farm", "savanna", "cold", "tiny",
                "birds", "fantasy",
            ])
        #expect(ProfileIllustration.all.count == Section.allCases.count * 10)
        #expect(ProfileIllustration.all.first?.id == "classics-01")
        #expect(ProfileIllustration.all.last?.id == "fantasy-10")
    }

    @Test func onlyIllustrationsWithAnImageAreOffered() {
        let available = ProfileIllustration.available
        #expect(
            available
                == ProfileIllustration.all.filter { CashlyResourceImage.contains($0.assetName) })
        #expect(available.count >= 99)
        #expect(Section.allCases.allSatisfy { !$0.illustrations.isEmpty })
        #expect(
            Section.allCases.flatMap(\.illustrations).count == available.count)
    }

    @Test func missingImageIsNeitherListedNorDecoded() throws {
        let missing = ProfileIllustration.all.filter { !CashlyResourceImage.contains($0.assetName) }
        for illustration in missing {
            #expect(ProfileIllustration(id: illustration.id) == nil)
            #expect(ProfilePhoto.illustration(illustration.id).illustration == nil)
        }
        let first = try #require(ProfileIllustration.available.first)
        #expect(ProfileIllustration(id: first.id) == first)
    }

    @Test func classicsBrazilAndSaversAreFree() {
        #expect(Section.allCases.filter { $0.shopItem == nil } == [.classics, .brazil, .savers])
        let paid = Section.allCases.compactMap(\.shopItem)
        #expect(paid.count == 7)
        #expect(Set(paid).count == 7)
        #expect(paid.allSatisfy { $0.group == .avatars && $0.kind == .nonConsumable })
        #expect(ShopCatalog.items(in: .avatars) == paid + [.avatarsAll])
    }

    @Test func allAvatarsUnlocksEveryPaidSection() {
        let shop = ShopAccess(owned: [.avatarsAll]) { _ in }
        #expect(Section.allCases.allSatisfy { shop.access(to: $0.shopItem).lockedItem == nil })
        #expect(shop.access(to: Section.ocean.shopItem) == .owned)
        #expect(shop.access(to: Section.classics.shopItem) == .included)
        #expect(Section.sections(of: .avatarsAll).count == 7)
        #expect(Section.sections(of: .avatarsBirds) == [.birds])
    }

    @Test func oneSectionDoesNotUnlockAnother() {
        let shop = ShopAccess(owned: [.avatarsOcean]) { _ in }
        #expect(shop.access(to: Section.ocean.shopItem) == .owned)
        #expect(shop.access(to: Section.farm.shopItem) == .locked(.avatarsFarm))
        #expect(!shop.owns(.avatarsAll))
    }

    @Test func everyIllustrationHasANameAndBackground() {
        let names = ProfileIllustration.all.map(\.name)
        #expect(Set(names).count == names.count)
        #expect(!names.contains("Illustration"))
        #expect(
            ProfileIllustration.all.allSatisfy {
                $0.background.count == 6 && $0.background.allSatisfy(\.isHexDigit)
            })
        #expect(ProfileIllustration.all.allSatisfy { ProfilePhoto.illustration($0.id).isValid })
    }

    @Test func packAccessLabels() {
        #expect(PackAccess.included.label(price: "R$ 9,90") == nil)
        #expect(PackAccess.owned.label(price: "R$ 9,90") == "Owned")
        #expect(PackAccess.locked(.avatarsFarm).label(price: "R$ 9,90") == "R$ 9,90")
        #expect(PackAccess.locked(.avatarsFarm).label(price: nil) == "Locked")
        let shop = ShopAccess(
            owned: [], price: { $0 == .avatarsFarm ? "R$ 9,90" : nil }, open: { _ in })
        #expect(shop.price(for: .avatarsFarm) == "R$ 9,90")
    }

    @Test func suggestedColorIsStableAndFromThePalette() {
        let color = ProfilePhoto.suggestedColor(for: "550e8400")
        #expect(ProfilePhoto.suggestedColor(for: "550e8400") == color)
        #expect(ProfilePhoto.suggested(for: "550e8400") == .initials(color: color.hex))
        #expect(Set(["a", "b", "c", "d", "e", "f"].map(ProfilePhoto.suggestedColor)).count > 1)
        #expect(RetroColor.default.hex == ProfilePhoto.defaultColor)
    }

    @Test func everyProfileSymbolIsUniqueAndNamed() {
        #expect(Set(ProfileSymbol.allCases.map(\.rawValue)).count == ProfileSymbol.allCases.count)
        #expect(ProfileSymbol.allCases.allSatisfy { !$0.name.isEmpty })
        #expect(
            ProfileSymbol.allCases.allSatisfy {
                ProfilePhoto.symbol($0.rawValue, color: "2E7D74").isValid
            })
    }
}
