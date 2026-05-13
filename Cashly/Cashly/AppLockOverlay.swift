//
//  AppLockOverlay.swift
//  Cashly
//
//  Full-screen lock surface drawn whenever AppLock requires
//  re-authentication. Shown before the user authenticates and on
//  background → foreground re-entry. Renders blurred chrome behind
//  it so even quick app-switcher snapshots don't leak transaction
//  amounts.
//

import SwiftUI
import CashlyResource

struct AppLockOverlay: View {
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThickMaterial)
                .ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(CashlyL10n.string("Cashly is locked"))
                    .font(.title2.weight(.semibold))
                Button {
                    onUnlock()
                } label: {
                    Label(
                        CashlyL10n.string("Unlock"),
                        systemImage: "faceid"
                    )
                    .font(.body.weight(.semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(CashlyL10n.string("Cashly is locked"))
    }
}
