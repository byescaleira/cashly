import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct EraseSection: View {
    @Environment(DataModel.self) private var data

    var body: some View {
        @Bindable var data = data
        Section {
            Button(role: .destructive) {
                data.startErase()
            } label: {
                IconRow(
                    "Delete All Data", detail: "You review everything before it's erased.",
                    symbol: "trash", color: .negative, titleColor: .negative)
            }
            .sheet(isPresented: $data.isErasing) { EraseScreen().environment(data) }
        }
    }
}

private struct EraseScreen: View {
    @Environment(DataModel.self) private var data
    @Environment(\.appTint) private var appTint

    var body: some View {
        @Bindable var data = data
        GuideSheet(
            index: data.eraseStep.rawValue, count: DataModel.EraseStep.allCases.count,
            isWorking: data.isWorking, back: back, primary: primary, secondary: secondary
        ) {
            switch data.eraseStep {
            case .review: EraseReviewPage()
            case .confirm: EraseConfirmPage()
            case .done:
                GuidePage(
                    title: "All Data Deleted",
                    message:
                        "Your records are gone. Appearance, language and other preferences were kept."
                ) {
                    CashlyAnimationView(.done)
                }
            }
        }
        .tint(data.eraseStep == .confirm ? Color.negative : appTint)
        .fileExporter(
            isPresented: $data.isExportingFromErase, document: data.document,
            contentType: data.exportType, defaultFilename: data.fileName,
            onCompletion: { result in Task { await data.finishExport(result) } }
        )
        .errorAlert($data.error)
    }

    private var back: (() -> Void)? {
        guard data.eraseStep == .confirm else { return nil }
        return { data.eraseStep = .review }
    }

    private var primary: GuideAction {
        switch data.eraseStep {
        case .review: GuideAction("Continue") { data.eraseStep = .confirm }
        case .confirm: GuideAction("Delete All Data") { Task { await data.eraseAll() } }
        case .done: GuideAction("Done") { data.closeErase() }
        }
    }

    private var secondary: GuideAction? {
        switch data.eraseStep {
        case .review:
            GuideAction("Export a Backup First", isEnabled: !data.exportedBeforeErase) {
                Task { await data.prepareExport() }
            }
        case .confirm: GuideAction("Cancel") { data.closeErase() }
        case .done: nil
        }
    }
}

private struct EraseReviewPage: View {
    @Environment(DataModel.self) private var data

    var body: some View {
        GuidePage(
            title: "Before You Delete",
            message:
                "Everything below leaves this device and, with iCloud on, your other devices too. Export a backup first if you might want it back."
        ) {
            CashlyAnimationView(.backup)
        } content: {
            TimelineView(.everyMinute) { context in
                let backup = data.eraseBackupState(now: context.date)
                GuideValueList([
                    GuideValue(data.eraseRecordsLabel, value: data.eraseRecordsText),
                    GuideValue(
                        data.eraseExtrasLabel, value: data.eraseExtrasText, color: .warning),
                    GuideValue(
                        data.eraseBackupLabel, value: backup.text,
                        color: backup.isSafe ? .positive : .negative),
                ])
            }
        }
    }
}

private struct EraseConfirmPage: View {
    @Environment(DataModel.self) private var data
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShaking = false

    var body: some View {
        GuidePage(
            title: "Delete Everything?",
            message: "This can't be undone. Cashly keeps nothing on a server to bring it back."
        ) {
            Image(systemName: "trash")
                .font(.icon(.xl, weight: .medium))
                .foregroundStyle(Color.negative)
                .frame(width: .medallion, height: .medallion)
                .background(Color.negative.opacity(.opacityFill), in: .circle)
                .symbolEffect(.wiggle, value: isShaking)
                .padding(.vertical, .spaceS)
                .task { if !reduceMotion { isShaking = true } }
        } content: {
            GuideFeatureList {
                GuideFeature(
                    title: data.eraseTotalText, detail: data.eraseCloudNote, color: .negative)
            }
        }
    }
}
