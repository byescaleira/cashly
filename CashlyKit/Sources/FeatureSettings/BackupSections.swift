import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct BackupScheduleSection: View {
    @Environment(DataModel.self) private var data
    @Environment(\.appTint) private var appTint

    var body: some View {
        @Bindable var data = data
        Section {
            Toggle(isOn: $data.autoBackupToggle) { AutoBackupLabel() }
                .tint(.positive)
            if data.autoBackup {
                TimelineView(.everyMinute) { context in
                    if let schedule = data.backupSchedule(now: context.date) {
                        BackupWeek(schedule: schedule)
                    }
                }
            }
            Button {
                Task { await data.backUpNow() }
            } label: {
                IconRow("Back Up Now", symbol: "clock.arrow.circlepath", color: appTint)
            }
        } header: {
            Text("Backup").sectionTitle()
        } footer: {
            Text(verbatim: data.autoBackupFooter)
        }
    }
}

private struct BackupWeek: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFilled = false
    let schedule: DataModel.BackupSchedule

    var body: some View {
        let animation: Animation? = reduceMotion ? nil : .smooth(duration: 1)
        VStack(spacing: .spaceS) {
            HStack(alignment: .firstTextBaseline) {
                BackupMoment(caption: "Last", value: schedule.last, alignment: .leading)
                Spacer(minLength: .spaceM)
                BackupMoment(caption: "Next", value: schedule.next, alignment: .trailing)
            }
            ProgressView(value: isFilled ? schedule.fraction : 0)
                .tint(.positive)
                .animation(animation, value: isFilled)
                .animation(animation, value: schedule.fraction)
                .accessibilityHidden(true)
        }
        .padding(.vertical, .space2XS)
        .task { isFilled = true }
    }
}

private struct BackupMoment: View {
    let caption: LocalizedStringKey
    let value: String
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: alignment, spacing: .spaceHairline) {
            Text(caption).font(.caption).foregroundStyle(.secondary)
            Text(verbatim: value).font(.callout.weight(.semibold))
        }
        .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
        .accessibilityElement(children: .combine)
    }
}

struct BackupCloudSection: View {
    @Environment(DataModel.self) private var data

    var body: some View {
        @Bindable var data = data
        Section {
            Toggle(isOn: $data.cloudToggle) {
                HStack(spacing: .spaceS) {
                    CloudBackupLabel()
                    Chip(data.cloudState.title, color: data.cloudState.color)
                }
            }
            .tint(.positive)
            .disabled(data.isCloudToggleDisabled)
        } footer: {
            Text(verbatim: data.cloudFooter)
        }
    }
}

struct SavedBackupsSection: View {
    @Environment(DataModel.self) private var data

    var body: some View {
        if !data.savedBackups.isEmpty {
            Section {
                ForEach(data.savedBackups) { saved in
                    Button {
                        Task { await data.openSaved(saved) }
                    } label: {
                        SavedBackupRow(saved: saved, isLatest: saved == data.savedBackups.first)
                    }
                }
            } header: {
                Text("Saved Backups").sectionTitle()
            } footer: {
                Text("Tap a backup to review its records before importing.")
            }
        }
    }
}

struct SavedBackupRow: View {
    @Environment(DataModel.self) private var data
    let saved: SavedBackup
    let isLatest: Bool

    var body: some View {
        HStack(spacing: .spaceS) {
            IconRow(
                verbatim: saved.title, detail: saved.detail(now: .now), symbol: data.savedSymbol,
                color: .companion)
            if isLatest { Chip("Latest", color: .positive) }
        }
    }
}

extension CloudDriveState {
    fileprivate var color: Color {
        switch self {
        case .checking: .secondary
        case .available: .positive
        case .unavailable: .warning
        }
    }
}

struct AutoBackupLabel: View {
    var body: some View {
        IconRow("Automatic Backup", symbol: "calendar.badge.clock", color: RetroColor.slate.color)
    }
}

struct CloudBackupLabel: View {
    var body: some View {
        IconRow("Save to iCloud Drive", symbol: "icloud", color: RetroColor.sky.color)
    }
}
