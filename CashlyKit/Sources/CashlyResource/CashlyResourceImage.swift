//
//  CashlyResourceImage.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 02/09/25.
//

import RyzeFoundation

public enum CashlyResourceImage: String, RyzeResourceImage {
    case illustrationEmpty
    case illustrationNoData
    case illustrationPeople
    case illustrationEmptyTransaction
    
    public var resource: ImageResource {
        switch self {
        case .illustrationEmpty: return .illustrationEmpty
        case .illustrationNoData: return .illustrationNoData
        case .illustrationPeople: return .illustrationPeople
        case .illustrationEmptyTransaction: return .illustrationEmptyTransaction
        }
    }
    
    public static func avatar(id: String?) -> Image {
        guard let id else { return Image(systemName: "person.fill") }
        return Image("avatar\(id)", bundle: .module)
    }
    
    public var image: Image {
        Image(resource)
    }
}
