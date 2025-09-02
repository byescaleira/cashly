//
//  User.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 31/08/25.
//

public struct User: CashlyEntity, Sendable {
    public var id: UUID
    public var name: String
    public var photo: Data?
    
    public init(
        id: UUID,
        name: String,
        photo: Data?
    ) {
        self.id = id
        self.name = name
        self.photo = photo
    }
}
