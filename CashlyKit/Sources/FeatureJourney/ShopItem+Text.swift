import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

extension ShopItem {
    var outcome: String {
        switch self {
        case .proMonthly, .proYearly:
            String(appLocalized: "Insights, backups and the Gold collection")
        case .iconsAll: String(appLocalized: "Every icon, now and later")
        case .iconsFashion, .iconsCountries, .iconsSports, .iconsEighties, .iconsSummer,
            .iconsCarnival, .iconsJunina, .iconsHalloween, .iconsChristmas:
            String(appLocalized: "A new face for Cashly on your Home Screen")
        case .accentMetallic, .accentNeon: String(appLocalized: "Your accent, everywhere in Cashly")
        case .avatarsAll: String(appLocalized: "Every avatar, now and later")
        case .avatarsFarm, .avatarsOcean, .avatarsBirds, .avatarsJungle, .avatarsTiny,
            .avatarsFantasy, .avatarFrames:
            String(appLocalized: "Your profile, your way")
        case .sounds: String(appLocalized: "More delight when you save")
        case .freezes3, .freezes10: String(appLocalized: "Miss a day without losing your streak")
        case .streakRestore: String(appLocalized: "Get a lost streak back")
        case .challengeRerolls: String(appLocalized: "Change your mind about a challenge")
        }
    }

    var benefits: [ShopBenefit] {
        switch group {
        case .plans: []
        case .icons: iconBenefits
        case .avatars: avatarBenefits
        case .personalization: personalizationBenefits
        case .helps: helpBenefits
        }
    }

    private var iconBenefits: [ShopBenefit] {
        [
            ShopBenefit(
                symbol: "app.gift.fill", color: .retroOrange,
                title: self == .iconsAll
                    ? String(appLocalized: "Every pack in the shop, plus future packs")
                    : String(appLocalized: "Four icons, one per mood")),
            ShopBenefit(
                symbol: "gearshape.fill", color: .retroDenim,
                title: String(appLocalized: "Switch anytime in Settings › Icon")),
            ShopBenefit(
                symbol: "infinity", color: .retroOlive,
                title: String(appLocalized: "Yours for good, on all your devices")),
        ]
    }

    private var avatarBenefits: [ShopBenefit] {
        [
            ShopBenefit(
                symbol: "pawprint.fill", color: .retroBrown,
                title: self == .avatarsAll
                    ? String(appLocalized: "Every section in the shop, plus future ones")
                    : String(appLocalized: "A whole section of illustrated animals")),
            ShopBenefit(
                symbol: "person.crop.circle.fill", color: .retroOrange,
                title: String(appLocalized: "Pick one in Edit User › Illustration")),
            ShopBenefit(
                symbol: "infinity", color: .retroOlive,
                title: String(appLocalized: "Yours for good, on all your devices")),
        ]
    }

    private var personalizationBenefits: [ShopBenefit] {
        [
            ShopBenefit(
                symbol: "paintpalette.fill", color: .retroPlum,
                title: String(appLocalized: "Four accent colors for buttons, tabs and charts")),
            ShopBenefit(
                symbol: "gearshape.fill", color: .retroDenim,
                title: String(appLocalized: "Pick them in Settings › Accent Color")),
            ShopBenefit(
                symbol: "infinity", color: .retroOlive,
                title: String(appLocalized: "Yours for good, on all your devices")),
        ]
    }

    private var helpBenefits: [ShopBenefit] {
        [
            ShopBenefit(symbol: symbol, color: .retroTeal, title: detail),
            ShopBenefit(
                symbol: "person.crop.circle.fill", color: .retroDenim,
                title: String(appLocalized: "Credited to this profile right after buying")),
            ShopBenefit(
                symbol: "hourglass", color: .retroMustard,
                title: String(appLocalized: "Used up as you go, never expires")),
        ]
    }

    var quantity: String? {
        guard let count = credit?.count else { return nil }
        return count == 1
            ? String(appLocalized: "1 use") : String(appLocalized: "\(count) uses")
    }

    var animation: CashlyAnimation {
        switch self {
        case .freezes3, .freezes10: .shopFreeze
        case .streakRestore: .shopRestore
        case .challengeRerolls: .shopReroll
        default: group.animation
        }
    }
}

struct ShopBenefit: Identifiable {
    let symbol: String
    let color: Color
    let title: String

    var id: String { symbol + title }
}

extension ShopItem.Group {
    var title: String {
        switch self {
        case .plans: String(appLocalized: "Cashly Pro")
        case .icons: String(appLocalized: "App Icons")
        case .avatars: String(appLocalized: "Avatars")
        case .personalization: String(appLocalized: "Personalization")
        case .helps: String(appLocalized: "Journey Helps")
        }
    }

    var animation: CashlyAnimation {
        switch self {
        case .plans: .pro
        case .icons: .shopIcons
        case .avatars: .avatars
        case .personalization: .shopColors
        case .helps: .shopHelps
        }
    }
}
