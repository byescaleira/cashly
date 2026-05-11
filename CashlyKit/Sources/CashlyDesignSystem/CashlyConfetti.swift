//
//  CashlyConfetti.swift
//  CashlyKit
//
//  Wave 5a'': Cashly-owned confetti overlay. Replaces RyzeConfettiModifier
//  with native SwiftUI. Used by cashlyConfetti(for:isActive:) in CashlyUI.
//

import SwiftUI

private struct CashlyConfettiPiece: View {
    @State private var animate = false
    private let xSpeed = Double.random(in: 0.7 ... 2)
    private let zSpeed = Double.random(in: 1 ... 3)
    private let anchor = CGFloat.random(in: 0 ... 1).rounded()

    var body: some View {
        Rectangle()
            .fill(
                [Color.orange, .green, .blue, .red, .yellow].randomElement() ?? .green
            )
            .frame(width: 9, height: 12)
            .onAppear { animate = true }
            .rotation3DEffect(
                .degrees(animate ? 360 : 0),
                axis: (x: 1, y: 0, z: 0)
            )
            .animation(
                .linear(duration: xSpeed).repeatForever(autoreverses: false),
                value: animate
            )
            .rotation3DEffect(
                .degrees(animate ? 360 : 0),
                axis: (x: 0, y: 0, z: 1),
                anchor: UnitPoint(x: anchor, y: anchor)
            )
            .animation(
                .linear(duration: zSpeed).repeatForever(autoreverses: false),
                value: animate
            )
    }
}

private struct CashlyConfettiContainer: View {
    let count: Int
    @State private var yPosition: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0 ..< count, id: \.self) { _ in
                    CashlyConfettiPiece()
                        .position(
                            x: CGFloat.random(in: 0 ... proxy.size.width),
                            y: yPosition != .zero ? CGFloat.random(in: 0 ... proxy.size.height) : yPosition
                        )
                }
            }
            .onAppear {
                yPosition = CGFloat.random(in: 0 ... proxy.size.height)
            }
        }
        .ignoresSafeArea()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CashlyConfettiModifier: ViewModifier {
    let amount: Int
    let seconds: Int
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive {
                    CashlyConfettiContainer(count: amount)
                }
            }
            .sensoryFeedback(.success, trigger: isActive)
            .animation(.linear, value: isActive)
    }
}

public extension View {
    func cashlyConfetti(amount: Int = 30, seconds: Int = 4, isActive: Bool) -> some View {
        modifier(CashlyConfettiModifier(amount: amount, seconds: seconds, isActive: isActive))
    }
}
