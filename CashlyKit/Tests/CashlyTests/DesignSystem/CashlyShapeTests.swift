//
//  CashlyShapeTests.swift
//  CashlyKit
//

import Testing
import SwiftUI
import CoreGraphics
import CashlyDesignSystem

@Suite("CashlyShape.path(in:)", .tags(.unit, .ui, .local))
struct CashlyShapeTests {
    private let rect = CGRect(x: 0, y: 0, width: 100, height: 50)

    @Test("capsule path matches SwiftUI Capsule path")
    func capsuleMatchesCapsule() {
        let cashly = CashlyShape.capsule.path(in: rect)
        let native = Capsule().path(in: rect)
        #expect(cashly.boundingRect == native.boundingRect)
    }

    @Test("circle path matches SwiftUI Circle path")
    func circleMatchesCircle() {
        let cashly = CashlyShape.circle.path(in: rect)
        let native = Circle().path(in: rect)
        #expect(cashly.boundingRect == native.boundingRect)
    }

    @Test("rounded(radius:) matches RoundedRectangle path")
    func roundedMatchesNative() {
        let cashly = CashlyShape.rounded(radius: 12).path(in: rect)
        let native = RoundedRectangle(cornerRadius: 12).path(in: rect)
        #expect(cashly.boundingRect == native.boundingRect)
    }

    @Test("rounded(radius: 0) is rectangular")
    func zeroRadiusIsRect() {
        let path = CashlyShape.rounded(radius: 0).path(in: rect)
        #expect(path.boundingRect.width == 100)
        #expect(path.boundingRect.height == 50)
    }
}
