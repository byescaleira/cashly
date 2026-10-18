import FeatureCore
import Testing

struct GuideAccessTests {
    @Test func onlyTheSpreadsheetImportNeedsPro() {
        #expect(Guide.importSpreadsheet.requiresPro)
        #expect(!Guide.free.contains(.importSpreadsheet))
        #expect(Guide.free.count == Guide.allCases.count - 1)
    }
}
