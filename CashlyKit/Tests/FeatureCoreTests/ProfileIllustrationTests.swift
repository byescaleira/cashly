import CashlyDomain
import CashlyResource
import FeatureCore
import Foundation
import Testing

struct ProfileIllustrationTests {
    typealias Section = ProfileIllustration.Section

    @Test func sectionsFollowTheManifest() {
        #expect(
            Section.allCases.map(\.rawValue) == [
                "cats", "dogs", "forest", "farm", "ocean", "birds", "jungle", "tiny", "fantasy",
            ])
        #expect(Section.allCases.map(\.count) == [22, 22, 22, 22, 24, 22, 24, 22, 20])
        #expect(ProfileIllustration.all.count == 200)
        #expect(ProfileIllustration.all.first?.id == "cats-01")
        #expect(ProfileIllustration.all.last?.id == "fantasy-20")
        #expect(Set(ProfileIllustration.all.map(\.id)).count == 200)
    }

    @Test func listComesFromTheRealCatalog() {
        let available = ProfileIllustration.available
        #expect(
            available
                == ProfileIllustration.all.filter { CashlyResourceImage.contains($0.assetName) })
        #expect(available.count == ProfileIllustration.all.count)
        #expect(Section.allCases.allSatisfy { $0.illustrations.count == $0.count })
        #expect(!CashlyResourceImage.contains("avatar-cats-23"))
        #expect(ProfileIllustration(id: "cats-23") == nil)
        #expect(ProfileIllustration(id: "cats-01")?.section == .cats)
    }

    @Test func catsDogsAndForestAreFree() {
        #expect(Section.allCases.filter { $0.shopItem == nil } == [.cats, .dogs, .forest])
        let paid = Section.allCases.compactMap(\.shopItem)
        #expect(paid.count == 6)
        #expect(Set(paid).count == 6)
        #expect(paid.allSatisfy { $0.group == .avatars && $0.kind == .nonConsumable })
        #expect(ShopCatalog.items(in: .avatars) == paid + [.avatarsAll])
    }

    @Test func allAvatarsUnlocksEveryPaidSection() {
        let shop = ShopAccess(owned: [.avatarsAll]) { _ in }
        #expect(Section.allCases.allSatisfy { shop.access(to: $0.shopItem).lockedItem == nil })
        #expect(shop.access(to: Section.ocean.shopItem) == .owned)
        #expect(shop.access(to: Section.cats.shopItem) == .included)
        #expect(Section.sections(of: .avatarsAll).count == 6)
        #expect(Section.sections(of: .avatarsBirds) == [.birds])
        #expect(ProfileIllustration.illustrations(of: .avatarsJungle).count == 24)
    }

    @Test func oneSectionDoesNotUnlockAnother() {
        let shop = ShopAccess(owned: [.avatarsOcean]) { _ in }
        #expect(shop.access(to: Section.ocean.shopItem) == .owned)
        #expect(shop.access(to: Section.farm.shopItem) == .locked(.avatarsFarm))
        #expect(!shop.owns(.avatarsAll))
    }

    @Test func everyIllustrationIsAValidPhotoWithALabel() {
        #expect(ProfileIllustration.all.allSatisfy { ProfilePhoto.illustration($0.id).isValid })
        let label = ProfilePhoto.illustration("dogs-03").accessibilityLabel(initials: "AS")
        #expect(label.contains("3"))
        #expect(
            ProfilePhoto.initials(color: "2E7D74").accessibilityLabel(initials: "")
                == "Profile photo")
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
