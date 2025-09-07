//
//  AddUserState.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 06/09/25.
//

import CashlyDomain
import RyzeUI

public struct AddUserState: CashlyState {
    public var isLoading: Bool
    public var id: String
    public var name: String
    public var photo: String?
    public var isNew: Bool
    public var error: CashlyError?
    
    public var canSave: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 &&
        URL(string: photo ?? "") != nil
    }
    
    public func photos(for gender: Int = .zero) -> [String] {
        ((gender == .zero ? 1 : 51) ... (gender == .zero ? 50 : 100)).map {
            "https://avatar.iran.liara.run/public/\($0)"
        }
    }
    
    public init(
        isLoading: Bool = true,
        id: String = UUID().uuidString,
        name: String = "",
        photo: String? = nil,
        isNew: Bool = true,
        error: CashlyError? = nil
    ) {
        self.isLoading = isLoading
        self.id = id
        self.name = name
        self.photo = photo
        self.isNew = isNew
        self.error = error
    }
}
