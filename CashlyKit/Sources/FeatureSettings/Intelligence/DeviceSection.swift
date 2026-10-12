import CashlyDomain
import SwiftUI

struct DeviceSection: View {
    private let status = DeviceStatus.current

    var body: some View {
        Section("This Device") {
            LabeledContent("Processors", value: status.processors.formatted(.number.locale(.app)))
            LabeledContent("Memory", value: status.memory)
            LabeledContent("Temperature", value: status.thermalState)
        }
    }
}
