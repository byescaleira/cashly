//
//  Binding+Inverted.swift
//  Cashly
//
//  Tiny helper used by the root scene so the onboarding cover can be
//  driven by `!onboardingCompleted` via a real Binding instead of the
//  inverted-get/set hack the reviewer flagged in Wave D4.
//

import SwiftUI

extension Binding where Value == Bool {
    var inverted: Binding<Bool> {
        Binding(
            get: { !wrappedValue },
            set: { wrappedValue = !$0 }
        )
    }
}
