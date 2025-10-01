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
    case illustrationTransaction
    case illustrationTag
    
    public var resource: ImageResource {
        switch self {
        case .illustrationEmpty: return .illustrationEmpty
        case .illustrationNoData: return .illustrationNoData
        case .illustrationPeople: return .illustrationPeople
        case .illustrationTransaction: return .illustrationTransaction
        case .illustrationTag: return .illustrationTag
        }
    }
    
    public static func avatar(id: String?) -> Image {
        guard let id else { return Image(systemName: "person.crop.circle.dashed") }
        return Image("avatar\(id)", bundle: .module)
    }
    
    public var image: Image {
        Image(resource)
    }
}
