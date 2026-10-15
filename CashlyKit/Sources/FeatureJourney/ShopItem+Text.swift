import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

extension ShopItem {
    var title: String {
        switch self {
        case .proMonthly: String(appLocalized: "Cashly Pro Monthly")
        case .proYearly: String(appLocalized: "Cashly Pro Yearly")
        case .iconsFashion: String(appLocalized: "Fashion Icons")
        case .iconsCountries: String(appLocalized: "Country Icons")
        case .iconsSports: String(appLocalized: "Sports Icons")
        case .iconsEighties: String(appLocalized: "’80s Icons")
        case .iconsSummer: String(appLocalized: "Summer Icons")
        case .iconsCarnival: String(appLocalized: "Carnival Icons")
        case .iconsJunina: String(appLocalized: "Festa Junina Icons")
        case .iconsHalloween: String(appLocalized: "Halloween Icons")
        case .iconsChristmas: String(appLocalized: "Christmas Icons")
        case .iconsAll: String(appLocalized: "All Icons")
        case .accentMetallic: String(appLocalized: "Metallic Colors")
        case .accentNeon: String(appLocalized: "Neon Colors")
        case .avatarsFarm: String(appLocalized: "Farm Avatars")
        case .avatarsOcean: String(appLocalized: "Ocean Avatars")
        case .avatarsBirds: String(appLocalized: "Bird Avatars")
        case .avatarsJungle: String(appLocalized: "Jungle Avatars")
        case .avatarsTiny: String(appLocalized: "Tiny Friends Avatars")
        case .avatarsFantasy: String(appLocalized: "Fantasy Avatars")
        case .avatarsAll: String(appLocalized: "All Avatars")
        case .avatarFrames: String(appLocalized: "Avatar Frames")
        case .sounds: String(appLocalized: "Sounds")
        case .freezes3: String(appLocalized: "3 Streak Freezes")
        case .freezes10: String(appLocalized: "10 Streak Freezes")
        case .streakRestore: String(appLocalized: "Streak Restore")
        case .challengeRerolls: String(appLocalized: "3 Challenge Rerolls")
        }
    }

    var detail: String {
        switch self {
        case .proMonthly: String(appLocalized: "Everything in Cashly, billed monthly.")
        case .proYearly: String(appLocalized: "Everything in Cashly, billed yearly.")
        case .iconsFashion, .iconsCountries, .iconsSports, .iconsEighties, .iconsSummer,
            .iconsCarnival, .iconsJunina, .iconsHalloween, .iconsChristmas:
            String(appLocalized: "Four app icons to choose from in Settings.")
        case .iconsAll: String(appLocalized: "Every icon pack, including the ones still to come.")
        case .accentMetallic: String(appLocalized: "Gold, silver, bronze and copper accent colors.")
        case .accentNeon: String(appLocalized: "Four neon accent colors.")
        case .avatarsFarm, .avatarsOcean, .avatarsBirds, .avatarsJungle, .avatarsTiny,
            .avatarsFantasy:
            String(appLocalized: "Illustrated animals for your profile photo.")
        case .avatarsAll:
            String(appLocalized: "Every avatar section, including the ones still to come.")
        case .avatarFrames: String(appLocalized: "Six frames for your avatar.")
        case .sounds: String(appLocalized: "Sounds and haptics when you save and complete.")
        case .freezes3, .freezes10:
            String(appLocalized: "Each freeze covers one missed day on its own.")
        case .streakRestore: String(appLocalized: "Bring back a streak lost in the last 48 hours.")
        case .challengeRerolls:
            String(appLocalized: "Start another challenge in the same month.")
        }
    }

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
            ShopBenefit(symbol: helpSymbol, color: .retroTeal, title: detail),
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

    var symbol: String {
        switch group {
        case .plans: "crown.fill"
        case .icons: "app.gift.fill"
        case .avatars: "pawprint.fill"
        case .personalization: "paintpalette.fill"
        case .helps: helpSymbol
        }
    }

    private var helpSymbol: String {
        switch self {
        case .freezes3, .freezes10: "snowflake"
        case .streakRestore: "arrow.counterclockwise"
        default: "flag.2.crossed.fill"
        }
    }

    var color: Color {
        switch group {
        case .plans: .retroMustard
        case .icons: .retroOrange
        case .avatars: .retroBrown
        case .personalization: .retroPlum
        case .helps: .retroTeal
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
