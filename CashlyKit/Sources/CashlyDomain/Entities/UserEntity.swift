//
//  UserEntity.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 31/08/25.
//

import SwiftData

@Model
public class UserEntity {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var photo: Data?
    
    public init(
        id: UUID,
        name: String,
        photo: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.photo = photo
    }
}
