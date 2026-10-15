import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct BackupImportScreen: View {
    @Environment(DataModel.self) private var data

    var body: some View {
        @Bindable var data = data
        GuideSheet(
            index: data.backupStep.rawValue, count: DataModel.BackupStep.allCases.count,
            isWorking: data.isWorking, back: back, primary: primary, secondary: secondary
        ) {
            switch data.backupStep {
            case .intro: BackupImportIntro()
            case .review: BackupImportReview()
            case .done: BackupImportDone()
            }
        }
        .fileImporter(isPresented: $data.isImporting, allowedContentTypes: [.json]) {
            data.read($0)
        }
        .errorAlert($data.error)
    }

    private var back: (() -> Void)? {
        guard data.backupStep == .review else { return nil }
        return { data.backupStep = .intro }
    }

    private var primary: GuideAction {
        switch data.backupStep {
        case .intro: GuideAction("Choose File") { data.isImporting = true }
        case .review:
            GuideAction("Import") {
                guard let file = data.pendingRestore else { return }
                Task { await data.restore(file) }
            }
        case .done: GuideAction("Done") { data.isRestoringBackup = false }
        }
    }

    private var secondary: GuideAction? {
        guard data.backupStep == .intro else { return nil }
        return GuideAction("Not Now") { data.isRestoringBackup = false }
    }
}

private struct BackupImportIntro: View {
    @Environment(DataModel.self) private var data

    var body: some View {
        GuidePage(
            title: "Import Backup",
            message:
                "Choose a Cashly backup file (.json). The file's records are added to the ones already on this device; nothing is deleted."
        ) {
            CashlyAnimationView(.file)
        } content: {
            if !data.savedBackups.isEmpty {
                GuideFeatureList {
                    ForEach(data.savedBackups.prefix(2)) { saved in
                        Button {
                            Task { await data.openSaved(saved) }
                        } label: {
                            SavedBackupRow(saved: saved, isLatest: saved == data.savedBackups.first)
                                .padding(.vertical, .spaceS)
                                .padding(.horizontal, .spaceL)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct BackupImportReview: View {
    @Environment(DataModel.self) private var data

    var body: some View {
        if let merge = data.pendingMerge {
            GuidePage(verbatim: merge.title, message: merge.message) {
                CashlyAnimationView(.file)
            } content: {
                GuideValueList(
                    merge.rows.map {
                        GuideValue(
                            $0.label, value: $0.value,
                            color: $0.isHighlighted ? .positive : .primary)
                    })
            }
        }
    }
}

private struct BackupImportDone: View {
    @Environment(DataModel.self) private var data

    var body: some View {
        if let merge = data.pendingMerge {
            GuidePage(verbatim: merge.doneTitle, message: merge.doneMessage) {
                CashlyAnimationView(.done)
            }
        }
    }
}
