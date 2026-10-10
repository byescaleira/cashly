import FeatureCore
import Testing

struct RetroColorTests {
    @Test func paletteHasUniqueNamedColors() {
        let colors = RetroColor.allCases
        #expect(colors.count >= 20)
        #expect(Set(colors.map(\.hex)).count == colors.count)
        #expect(Set(colors.map(\.name)).count == colors.count)
        #expect(colors.allSatisfy { $0.hex.count == 6 && UInt32($0.hex, radix: 16) != nil })
    }

    @Test(arguments: ["#C2602A", "c2602a", "C2602AFF"])
    func hexFindsTheColor(hex: String) {
        #expect(RetroColor(hex: hex) == .burntOrange)
    }

    @Test func unknownHexIsCustom() {
        #expect(RetroColor(hex: "0099FF") == nil)
        #expect(RetroColor.name(for: "0099FF") == "Personalizada")
        #expect(RetroColor.name(for: RetroColor.mustard.hex) == "Mostarda")
    }
}
