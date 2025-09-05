//
//  User.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 31/08/25.
//

public struct User: CashlyEntity, Sendable {
    public var id: String
    public var name: String
    public var photo: String
    
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
