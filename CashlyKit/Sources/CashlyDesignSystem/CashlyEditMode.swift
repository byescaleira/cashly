//
//  CashlyEditMode.swift
//  CashlyKit
//
//  Cross-platform edit-mode abstraction. SwiftUI's `EditMode` is
//  iOS/visionOS-only — using it directly breaks the macOS build.
//  Screens carry a `CashlyEditMode` @State and mirror it into
//  SwiftUI's `editMode` environment on platforms where that exists.
//

import SwiftUI

public enum CashlyEditMode: Sendable, Equatable {
    case inactive
    case transient
    case active

    public var isEditing: Bool {
        self == .active || self == .transient
    }
}

#if os(iOS) || os(visionOS)
public extension CashlyEditMode {
    var swiftUI: EditMode {
        switch self {
        case .inactive: return .inactive
        case .transient: return .transient
        case .active: return .active
        }
    }

    init(_ editMode: EditMode) {
        switch editMode {
        case .inactive: self = .inactive
        case .transient: self = .transient
        case .active: self = .active
        @unknown default: self = .inactive
        }
    }
}
#endif

public extension View {
    /// Binds `cashlyEditMode` to SwiftUI's `editMode` environment on
    /// platforms where that environment exists. No-op on macOS.
    func cashlyEditMode(_ binding: Binding<CashlyEditMode>) -> some View {
        #if os(iOS) || os(visionOS)
        return self.environment(
            \.editMode,
            Binding(
                get: { binding.wrappedValue.swiftUI },
                set: { binding.wrappedValue = CashlyEditMode($0) }
            )
        )
        #else
        return self
        #endif
    }
}
