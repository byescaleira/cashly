import CashlyDomain
import CashlyResource
import SwiftUI

public struct ProfileIllustration: Identifiable, Hashable, Sendable {
    public enum Section: String, CaseIterable, Identifiable, Sendable {
        case classics, brazil, savers, ocean, farm, savanna, cold, tiny, birds, fantasy

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .classics: String(appLocalized: "Classics")
            case .brazil: String(appLocalized: "Brazil")
            case .savers: String(appLocalized: "Savers")
            case .ocean: String(appLocalized: "Ocean")
            case .farm: String(appLocalized: "Farm")
            case .savanna: String(appLocalized: "Savanna")
            case .cold: String(appLocalized: "Cold")
            case .tiny: String(appLocalized: "Tiny Friends")
            case .birds: String(appLocalized: "Birds")
            case .fantasy: String(appLocalized: "Fantasy")
            }
        }

        public var shopItem: ShopItem? {
            switch self {
            case .classics, .brazil, .savers: nil
            case .ocean: .avatarsOcean
            case .farm: .avatarsFarm
            case .savanna: .avatarsSavanna
            case .cold: .avatarsCold
            case .tiny: .avatarsTiny
            case .birds: .avatarsBirds
            case .fantasy: .avatarsFantasy
            }
        }

        public var illustrations: [ProfileIllustration] {
            ProfileIllustration.available.filter { $0.section == self }
        }

        public static func sections(of item: ShopItem) -> [Section] {
            item == .avatarsAll
                ? allCases.filter { $0.shopItem != nil } : allCases.filter { $0.shopItem == item }
        }
    }

    public static let perSection = 10

    public static let all: [ProfileIllustration] = Section.allCases.flatMap { section in
        (1...perSection).map {
            ProfileIllustration(
                id: section.rawValue + "-" + ($0 < 10 ? "0\($0)" : "\($0)"), section: section)
        }
    }

    public static let available = all.filter { CashlyResourceImage.contains($0.assetName) }

    public static let suggested = Section.classics.illustrations.first

    public let id: String
    public let section: Section

    private init(id: String, section: Section) {
        self.id = id
        self.section = section
    }

    public init?(id: String) {
        guard let match = Self.available.first(where: { $0.id == id }) else { return nil }
        self = match
    }

    public var assetName: String { "avatar-" + id }

    public var image: Image { CashlyResourceImage.avatar(assetName) }

    public var shopItem: ShopItem? { section.shopItem }

    public static func illustrations(of item: ShopItem) -> [ProfileIllustration] {
        Section.sections(of: item).flatMap(\.illustrations)
    }
}
