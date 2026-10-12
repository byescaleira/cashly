import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct BackupScheduleSection: View {
    @Environment(DataModel.self) private var data
    @Environment(\.appTint) private var appTint

    var body: some View {
        @Bindable var data = data
        Section {
            Toggle("Automatic Backup", isOn: $data.autoBackupToggle)
                .tint(.positive)
            Button {
                Task { await data.backUpNow() }
            } label: {
                IconRow("Back Up Now", symbol: "clock.arrow.circlepath", color: appTint)
            }
        } header: {
            Text("Backup")
        } footer: {
            Text(data.autoBackupFooter)
        }
    }
}

struct BackupCloudSection: View {
    @Environment(DataModel.self) private var data

    var body: some View {
        @Bindable var data = data
        Section {
            Toggle("Save Backups to iCloud Drive", isOn: $data.cloudToggle)
                .tint(.positive)
                .disabled(data.isCloudToggleDisabled)
            LabeledContent("iCloud Drive", value: data.cloudState.title)
        } footer: {
            Text(data.cloudFooter)
        }
    }
}

struct SavedBackupsSection: View {
    @Environment(DataModel.self) private var data
    @Environment(\.pro) private var pro

    var body: some View {
        if !data.savedBackups.isEmpty {
            Section {
                ForEach(data.savedBackups) { saved in
                    Button {
                        pro.perform { Task { await data.openSaved(saved) } }
                    } label: {
                        IconRow(
                            verbatim: saved.title, symbol: data.savedSymbol, color: .companion)
                    }
                }
            } header: {
                Text("Saved Backups")
            } footer: {
                Text("Tap a backup to review its records before importing.")
            }
        }
    }
}
