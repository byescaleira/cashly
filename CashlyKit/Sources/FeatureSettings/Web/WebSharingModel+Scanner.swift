import Foundation

#if os(iOS)
    import AVFoundation
    import UIKit
    import VisionKit
#endif

extension WebSharingModel {
    public var isScannerSupported: Bool {
        #if os(iOS)
            DataScannerViewController.isSupported
        #else
            false
        #endif
    }

    public var settingsURL: URL? {
        #if os(iOS)
            URL(string: UIApplication.openSettingsURLString)
        #else
            nil
        #endif
    }

    var cameraSettingsURL: URL? {
        isCameraAvailable ? nil : settingsURL
    }

    public func startScanning() async {
        #if os(iOS)
            if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
                _ = await AVCaptureDevice.requestAccess(for: .video)
            }
            refreshCamera()
            isScanning = true
        #endif
    }

    public func refreshCamera() {
        #if os(iOS)
            isCameraAvailable =
                AVCaptureDevice.authorizationStatus(for: .video) == .authorized
                && DataScannerViewController.isAvailable
        #endif
    }
}
