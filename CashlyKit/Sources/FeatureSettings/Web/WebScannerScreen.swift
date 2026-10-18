#if os(iOS)
    import CashlyDesignSystem
    import SwiftUI
    import VisionKit

    struct WebScannerScreen: View {
        @Environment(WebSharingModel.self) private var web
        @Environment(\.scenePhase) private var scenePhase

        var body: some View {
            NavigationStack {
                Group {
                    if web.isCameraAvailable {
                        QRScanner { web.receive(scanned: $0) }
                            .ignoresSafeArea()
                            .overlay(alignment: .bottom) { ScanMessage() }
                    } else {
                        CameraUnavailableView()
                    }
                }
                .navigationTitle("Scan QR Code")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", systemImage: "xmark") { web.isScanning = false }
                    }
                }
            }
            .fontDesign(.rounded)
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { web.refreshCamera() }
            }
        }
    }

    private struct CameraUnavailableView: View {
        @Environment(WebSharingModel.self) private var web
        @Environment(\.openURL) private var openURL

        var body: some View {
            ContentUnavailableView {
                Label("Camera Unavailable", systemImage: "camera")
            } description: {
                Text("Allow camera access for Cashly in the Settings app to scan the code.")
            } actions: {
                if let url = web.settingsURL {
                    Button("Open Settings") { openURL(url) }
                        .primaryButton()
                }
            }
        }
    }

    private struct ScanMessage: View {
        @Environment(WebSharingModel.self) private var web

        var body: some View {
            if let message = web.scanMessage {
                Text(verbatim: message)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .padding(.spaceL)
                    .background(.sheetCard, in: .rect(cornerRadius: .radiusL))
                    .padding(.spaceXL)
                    .transition(.opacity)
                    .onAppear {
                        AccessibilityNotification.Announcement(message).post()
                    }
            }
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
