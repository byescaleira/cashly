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
                    .illustrationBackup, title: "Importar backup",
                    message:
                        "Escolha um arquivo de backup do Cashly (.json). Os registros do arquivo são somados aos que já estão no aparelho; nada é apagado."
                )
            case .review:
                GuidePage(
                    .illustrationReview, title: "Confira o backup",
                    message: LocalizedStringKey(
                        data.pendingRestore.map(data.description(of:)) ?? ""))
            case .done:
                GuidePage(
                    .illustrationDone, title: "Backup importado",
                    message: "Os registros já aparecem no app.")
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
        case .intro: GuideAction("Escolher arquivo") { data.isImporting = true }
        case .review:
            GuideAction("Importar") {
                guard let file = data.pendingRestore else { return }
                Task { await data.restore(file) }
            }
        case .done: GuideAction("Concluir") { data.isRestoringBackup = false }
        }
    }

    private var secondary: GuideAction? {
        guard data.backupStep == .intro else { return nil }
        return GuideAction("Agora não") { data.isRestoringBackup = false }
    }
}
