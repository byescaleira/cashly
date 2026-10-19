#if os(iOS)
    import CashlyDesignSystem
    import FeatureCore
    import SwiftUI
    import VisionKit

    struct WebScannerScreen: View {
        @Environment(WebSharingModel.self) private var web
        @Environment(\.scenePhase) private var scenePhase
        @Environment(\.openURL) private var openURL

        var body: some View {
            GuideSheet(index: 0, count: 1, primary: primary, secondary: secondary) {
                GuidePage(verbatim: web.scannerTitle, message: web.scannerMessage) {
                    if web.isCameraAvailable {
                        ScannerSlot()
                    } else {
                        CashlyAnimationView(.web)
                    }
                }
            }
            .sensoryFeedback(.warning, trigger: web.scanMessage) { _, new in new != nil }
            .onChange(of: web.scanMessage) { _, message in
                if let message { AccessibilityNotification.Announcement(message).post() }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { web.refreshCamera() }
            }
        }

        private var primary: GuideAction {
            guard let url = web.cameraSettingsURL else {
                return GuideAction("Cancel") { web.isScanning = false }
            }
            return GuideAction("Open Settings") { openURL(url) }
        }

        private var secondary: GuideAction? {
            web.cameraSettingsURL.map { _ in GuideAction("Cancel") { web.isScanning = false } }
        }
    }

    private struct ScannerSlot: View {
        @Environment(WebSharingModel.self) private var web

        var body: some View {
            QRScanner { web.receive(scanned: $0) }
                .background(Color.secondary.opacity(.opacityFill))
                .aspectRatio(4 / 3, contentMode: .fit)
                .clipShape(.rect(cornerRadius: .radiusL))
        }
    }

    private struct QRScanner: UIViewControllerRepresentable {
        let onScan: (String) -> Void

        func makeUIViewController(context: Context) -> DataScannerViewController {
            let scanner = DataScannerViewController(
                recognizedDataTypes: [.barcode(symbologies: [.qr])], qualityLevel: .balanced,
                recognizesMultipleItems: false, isHighFrameRateTrackingEnabled: false,
                isHighlightingEnabled: true)
            scanner.delegate = context.coordinator
            return scanner
        }

        func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
            context.coordinator.onScan = onScan
            if !scanner.isScanning { try? scanner.startScanning() }
        }

        static func dismantleUIViewController(
            _ scanner: DataScannerViewController, coordinator: Coordinator
        ) {
            scanner.stopScanning()
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(onScan: onScan)
        }

        @MainActor
        final class Coordinator: NSObject, DataScannerViewControllerDelegate {
            var onScan: (String) -> Void

            init(onScan: @escaping (String) -> Void) {
                self.onScan = onScan
            }

            func dataScanner(
                _ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem],
                allItems: [RecognizedItem]
            ) {
                for case .barcode(let code) in addedItems {
                    if let payload = code.payloadStringValue {
                        onScan(payload)
                        return
                    }
                }
            }

            func dataScanner(
                _ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem
            ) {
                if case .barcode(let code) = item, let payload = code.payloadStringValue {
                    onScan(payload)
                }
            }
        }
    }
#endif
