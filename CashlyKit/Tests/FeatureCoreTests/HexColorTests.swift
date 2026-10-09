import CashlyDesignSystem
import SwiftUI
import Testing

struct HexColorTests {
    @Test(arguments: ["FF9500FF", "34C75980", "000000FF", "FFFFFFFF"])
    func hexSurvivesTheColor(hex: String) {
        #expect(Color(hex: hex).hex == hex)
    }

    @Test func sixDigitsGainOpacity() {
        #expect(Color(hex: "#5856D6").hex == "5856D6FF")
    }
}
