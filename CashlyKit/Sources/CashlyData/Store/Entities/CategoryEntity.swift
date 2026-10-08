import CashlyDomain
import Foundation
import SwiftData

@Model
public class CategoryEntity {
    #Index<CategoryEntity>([\.user, \.id])
    public var id: String = ""
    public var name: String = ""
    public var user: String = ""
    public var color: String = ""
    public var icon: String = ""

    public init(
        id: String,
        user: String,
        name: String,
        color: String,
        icon: String
    ) {
        self.id = id
        self.user = user
        self.name = name
        self.color = color
        self.icon = icon
    }
}
