//
//  CashlyResourceImage.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 02/09/25.
//

import RyzeFoundation

public enum CashlyResourceImage: String, RyzeResourceImage {
    case illustrationEmpty
    
    public var resource: ImageResource {
        switch self {
        case .illustrationEmpty: return .illustrationEmpty
        }
    }
    
    public var image: Image {
        Image(resource)
    }
}
