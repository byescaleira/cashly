import SwiftUI

struct DeviceSection: View {
    private let status = DeviceStatus.current

    var body: some View {
        Section("Aparelho") {
            LabeledContent("Processadores", value: status.processors.formatted())
            LabeledContent("Memória", value: status.memory)
            LabeledContent("Temperatura", value: status.thermalState)
        }
    }
}
