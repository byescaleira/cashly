import CashlyDomain
import CashlyResource
import Foundation

extension Tag {
    public static var mock: Tag {
        mocks.first
            ?? Tag(id: "preview-tag", user: .mock, name: "Mercado", color: "34C759", icon: "cart")
    }

    public static var mocks: [Tag] {
        let tags: [Tag] = (try? CashlyResourceFile.tags.decoded()) ?? []
        return tags.sorted(by: \.name)
    }
}
