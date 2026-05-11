//
//  CashlyPreviewTests.swift
//  CashlyKit
//
//  Smoke-test the two `cashlyPreview()` helpers from CashlyMock.
//  Only verifies they construct without crash — the visual side is
//  covered by ScreenSnapshotTests.
//

import SwiftUI
import Testing
import CashlyDesignSystem
import CashlyMock

@MainActor
@Suite("cashlyPreview helpers", .tags(.unit, .ui, .local))
struct CashlyPreviewTests {

    @Test("instance cashlyPreview() builds for any View")
    func instanceVariant() {
        let preview = Text("hi").cashlyPreview()
        _ = preview
    }

    @Test("static cashlyPreview() builds for CashlyView conformers")
    func staticVariant() {
        // Use a small TestView conforming to CashlyView; mocked() default
        // returns EmptyView() so the static helper should compose without
        // crashing.
        _ = TestView.cashlyPreview()
    }
}

private struct TestView: CashlyView {
    static func mocked() -> some View { EmptyView() }
    var body: some View { EmptyView() }
}
