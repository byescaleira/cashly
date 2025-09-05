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
    
    public var resource: ImageResource {
        switch self {
        case .illustrationEmpty: return .illustrationEmpty
        case .illustrationNoData: return .illustrationNoData
        case .illustrationPeople: return .illustrationPeople
        }
    }
    
    public var image: Image {
        Image(resource)
    }
}
