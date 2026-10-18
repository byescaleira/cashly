import CashlyDesignSystem
import CashlyDomain
import SwiftUI

extension ShopItem {
    public var title: String {
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

    public var detail: String {
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

    public var symbol: String {
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

    public var color: Color {
        switch group {
        case .plans: .retroMustard
        case .icons: .retroOrange
        case .avatars: .retroBrown
        case .personalization: .retroPlum
        case .helps: .retroTeal
        }
    }
}
