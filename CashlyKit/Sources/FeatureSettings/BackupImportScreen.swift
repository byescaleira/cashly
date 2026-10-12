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
            case .intro:
                GuidePage(
                    title: "Import Backup",
                    message:
                        "Choose a Cashly backup file (.json). The file's records are added to the ones already on this device; nothing is deleted."
                ) {
                    CashlyAnimationView(.file)
                }
            case .review:
                GuidePage(
                    title: "Review the Backup",
                    message: LocalizedStringKey(
                        data.pendingRestore.map(data.description(of:)) ?? "")
                ) {
                    CashlyAnimationView(.file)
                }
            case .done:
                GuidePage(
                    title: "Backup Imported", message: "The records already show up in the app."
                ) {
                    CashlyAnimationView(.done)
                }
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
