import CashlyDomain
import Foundation
import SwiftData

@Model
public class UserEntity {
    public var id: String = ""
    public var name: String = ""
    public var photo: String = ""
    @Attribute(.externalStorage) public var photoData: Data?

    public init(
        id: String,
        name: String,
        photo: String
    ) {
        self.id = id
        self.name = name
        self.photo = photo
    }
}
