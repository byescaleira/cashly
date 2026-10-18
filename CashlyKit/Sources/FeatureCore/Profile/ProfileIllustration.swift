import CashlyDomain
import CashlyResource
import SwiftUI

public struct ProfileIllustration: Identifiable, Hashable, Sendable {
    public enum Section: String, CaseIterable, Identifiable, Sendable {
        case cats, dogs, forest, farm, ocean, birds, jungle, tiny, fantasy, gold

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .cats: String(appLocalized: "Cats")
            case .dogs: String(appLocalized: "Dogs")
            case .forest: String(appLocalized: "Forest")
            case .farm: String(appLocalized: "Farm")
            case .ocean: String(appLocalized: "Ocean")
            case .birds: String(appLocalized: "Birds")
            case .jungle: String(appLocalized: "Jungle")
            case .tiny: String(appLocalized: "Tiny Friends")
            case .fantasy: String(appLocalized: "Fantasy")
            case .gold: String(appLocalized: "Gold")
            }
        }

        public var count: Int {
            switch self {
            case .ocean, .jungle: 24
            case .fantasy, .gold: 20
            case .cats, .dogs, .forest, .farm, .birds, .tiny: 22
            }
        }

        public var shopItem: ShopItem? {
            switch self {
            case .cats, .dogs, .forest, .gold: nil
            case .farm: .avatarsFarm
            case .ocean: .avatarsOcean
            case .birds: .avatarsBirds
            case .jungle: .avatarsJungle
            case .tiny: .avatarsTiny
            case .fantasy: .avatarsFantasy
            }
        }

        public var isProOnly: Bool { self == .gold }

        public var illustrations: [ProfileIllustration] {
            ProfileIllustration.available.filter { $0.section == self }
        }

        public static func sections(of item: ShopItem) -> [Section] {
            item == .avatarsAll
                ? allCases.filter { $0.shopItem != nil } : allCases.filter { $0.shopItem == item }
        }
    }

    public static let all: [ProfileIllustration] = Section.allCases.flatMap { section in
        (1...section.count).map { ProfileIllustration(section: section, number: $0) }
    }

    public static let available = all.filter { CashlyResourceImage.contains($0.assetName) }

    public static let suggested = Section.cats.illustrations.first

    public let section: Section
    public let number: Int

    private init(section: Section, number: Int) {
        self.section = section
        self.number = number
    }

    public init?(id: String) {
        guard let match = Self.available.first(where: { $0.id == id }) else { return nil }
        self = match
    }

    public var id: String {
        section.rawValue + "-" + (number < 10 ? "0\(number)" : "\(number)")
    }

    public var assetName: String { "avatar-" + id }

    public var image: Image { CashlyResourceImage.avatar(assetName) }

    public var name: String { String(appLocalized: "Avatar \(number) of \(section.title)") }

    public var shopItem: ShopItem? { section.shopItem }

    public static func illustrations(of item: ShopItem) -> [ProfileIllustration] {
        Section.sections(of: item).flatMap(\.illustrations)
    }
}
