import CashlyDomain
import Foundation

struct DeviceStatus {
    let processors: Int
    let memory: String
    let thermalState: String

    static var current: DeviceStatus {
        let info = ProcessInfo.processInfo
        return DeviceStatus(
            processors: info.activeProcessorCount,
            memory: ByteCountFormatter.string(
                fromByteCount: Int64(info.physicalMemory), countStyle: .memory),
            thermalState: title(for: info.thermalState))
    }

    private static func title(for state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: String(appLocalized: "Normal")
        case .fair: String(appLocalized: "Moderate")
        case .serious: String(appLocalized: "High")
        case .critical: String(appLocalized: "Critical")
        @unknown default: String(appLocalized: "Unknown")
        }
    }
}
