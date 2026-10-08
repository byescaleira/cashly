import CashlyDesignSystem
import SwiftUI

struct CashlySystemMonitorView: View {
    var body: some View {
        Section("Device") {
            LabeledContent(
                "Processors", value: ProcessInfo.processInfo.activeProcessorCount.formatted())
            LabeledContent(
                "Physical Memory",
                value: ByteCountFormatter.string(
                    fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory),
                    countStyle: .memory))
            LabeledContent("Thermal State", value: thermalState)
        }
    }
    private var thermalState: String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: "Normal"
        case .fair: "Fair"
        case .serious: "Serious"
        case .critical: "Critical"
        @unknown default: "Unknown"
        }
    }
}
