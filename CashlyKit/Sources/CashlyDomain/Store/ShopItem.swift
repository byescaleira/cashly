public enum ShopItem: String, CaseIterable, Identifiable, Sendable {
    case proMonthly = "cashly.pro.monthly"
    case proYearly = "cashly.pro.yearly"
    case iconsFashion = "cashly.icons.fashion"
    case iconsCountries = "cashly.icons.countries"
    case iconsSports = "cashly.icons.sports"
    case iconsEighties = "cashly.icons.eighties"
    case iconsSummer = "cashly.icons.summer"
    case iconsCarnival = "cashly.icons.carnival"
    case iconsJunina = "cashly.icons.junina"
    case iconsHalloween = "cashly.icons.halloween"
    case iconsChristmas = "cashly.icons.christmas"
    case iconsAll = "cashly.icons.all"
    case accentMetallic = "cashly.accent.metallic"
    case accentNeon = "cashly.accent.neon"
    case avatarsFarm = "cashly.avatars.farm"
    case avatarsOcean = "cashly.avatars.ocean"
    case avatarsBirds = "cashly.avatars.birds"
    case avatarsJungle = "cashly.avatars.jungle"
    case avatarsTiny = "cashly.avatars.tiny"
    case avatarsFantasy = "cashly.avatars.fantasy"
    case avatarsAll = "cashly.avatars.all"
    case avatarFrames = "cashly.avatar.frames"
    case celebrations = "cashly.celebrations"
    case sounds = "cashly.sounds"
    case freezes3 = "cashly.freeze.3"
    case freezes10 = "cashly.freeze.10"
    case streakRestore = "cashly.streak.restore"
    case challengeRerolls = "cashly.challenge.reroll"

    public enum Kind: Sendable {
        case subscription, nonConsumable, consumable
    }

    public enum Group: CaseIterable, Sendable {
        case plans, icons, avatars, personalization, helps
    }

    public var id: String { rawValue }

    public var group: Group {
        switch self {
        case .proMonthly, .proYearly: .plans
        case .iconsFashion, .iconsCountries, .iconsSports, .iconsEighties, .iconsSummer,
            .iconsCarnival, .iconsJunina, .iconsHalloween, .iconsChristmas, .iconsAll:
            .icons
        case .avatarsFarm, .avatarsOcean, .avatarsBirds, .avatarsJungle, .avatarsTiny,
            .avatarsFantasy, .avatarsAll:
            .avatars
        case .accentMetallic, .accentNeon, .avatarFrames, .celebrations, .sounds:
            .personalization
        case .freezes3, .freezes10, .streakRestore, .challengeRerolls: .helps
        }
    }

    public var kind: Kind {
        switch group {
        case .plans: .subscription
        case .icons, .avatars, .personalization: .nonConsumable
        case .helps: .consumable
        }
    }

    public var isAvailable: Bool {
        switch self {
        case .avatarFrames, .celebrations, .sounds: false
        default: true
        }
    }

    public var credit: ShopCredit? {
        switch self {
        case .freezes3: .freezes(3)
        case .freezes10: .freezes(10)
        case .streakRestore: .streakRestore
        case .challengeRerolls: .challengeRerolls(3)
        default: nil
        }
    }
}

public enum ShopCredit: Hashable, Sendable {
    case freezes(Int)
    case streakRestore
    case challengeRerolls(Int)

    public var eventKind: GameEvent.Kind {
        switch self {
        case .freezes: .freezesCredited
        case .streakRestore: .streakRestored
        case .challengeRerolls: .rerollsCredited
        }
    }

    public var count: Int {
        switch self {
        case .freezes(let count), .challengeRerolls(let count): count
        case .streakRestore: 1
        }
    }
}

public enum ShopCatalog {
    public static let plans = ShopItem.allCases.filter { $0.group == .plans }
    public static let items = ShopItem.allCases.filter { $0.group != .plans && $0.isAvailable }

    public static func items(in group: ShopItem.Group) -> [ShopItem] {
        ShopItem.allCases.filter { $0.group == group && $0.isAvailable }
    }

    public static func owns(_ item: ShopItem, in owned: Set<ShopItem>) -> Bool {
        owned.contains(item) || (item.group == .icons && owned.contains(.iconsAll))
            || (item.group == .avatars && owned.contains(.avatarsAll))
    }
}
