import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct AppUpdateSection: View {
    @Environment(AppUpdateModel.self) private var update: AppUpdateModel?
    @Environment(\.appTint) private var appTint

    var body: some View {
        if let update {
            @Bindable var update = update
            Section {
                Picker("Simulate", selection: $update.simulation) {
                    Text("Off").tag(UpdateState?.none)
                    Text("Update recommended").tag(UpdateState?.some(.recommended))
                    Text("Update required").tag(UpdateState?.some(.required))
                }
                LabeledContent("Installed", value: update.installedValue)
                LabeledContent("Remote State", value: update.remoteStateValue)
                LabeledContent("Remote Policy", value: update.policyValue)
                LabeledContent("Last Checked") {
                    TimelineView(.everyMinute) { Text(verbatim: update.checkedValue(now: $0.date)) }
                }
                Button {
                    Task { await update.refresh(force: true) }
                } label: {
                    IconRow("Check Now", symbol: "arrow.clockwise", color: appTint)
                }
                .disabled(update.isChecking)
            } header: {
                Text("App Updates").sectionTitle()
            } footer: {
                Text("Development builds never block. Simulate a state to see its screen.")
            }
        }
    }
}
