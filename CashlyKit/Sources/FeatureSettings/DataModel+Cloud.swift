import CashlyDomain
import Foundation

extension DataModel {
    var activeFolder: BackupFolder {
        guard place == .iCloud, let cloudFolder else { return folder }
        return cloudFolder
    }

    var isUsingCloud: Bool { place == .iCloud && cloudFolder != nil }

    var placeDescription: String {
        isUsingCloud
            ? String(
                appLocalized:
                    "The 5 most recent are kept in iCloud Drive, in the Cashly › Backups folder.")
            : String(
                appLocalized:
                    "The 5 most recent are kept in Files, in the Cashly › Backups folder on this device."
            )
    }

    var cloudToggle: Bool {
        get { place == .iCloud }
        set { Task { await setPlace(newValue ? .iCloud : .device) } }
    }

    var isCloudToggleDisabled: Bool {
        isWorking || (cloudState != .available && place == .device)
    }

    var cloudFooter: String {
        switch (cloudState, place) {
        case (.checking, _):
            String(appLocalized: "Checking iCloud Drive.")
        case (.available, .iCloud):
            String(
                appLocalized:
                    "Backups go to iCloud Drive and show up in the Files app on your other devices."
            )
        case (.available, .device):
            String(
                appLocalized:
                    "Backups stay on this device only. Turn this on to keep a copy in iCloud Drive."
            )
        case (.unavailable, .iCloud):
            String(
                appLocalized:
                    "iCloud Drive isn't available. Check that you're signed in to iCloud and that iCloud Drive is turned on. Meanwhile, backups stay on this device."
            )
        case (.unavailable, .device):
            String(
                appLocalized:
                    "iCloud Drive isn't available. Sign in to iCloud and turn on iCloud Drive to keep backups there."
            )
        }
    }

    var placeTitle: String {
        isUsingCloud ? String(appLocalized: "iCloud Drive") : String(appLocalized: "This device")
    }

    var savedSymbol: String { isUsingCloud ? "icloud" : "internaldrive" }

    var cloudPath: String? { cloudFolder?.url.path(percentEncoded: false) }

    var localPath: String { folder.url.path(percentEncoded: false) }

    func loadBackups() async {
        cloudState = .checking
        cloudFolder = await cloud.resolve()
        cloudState = cloudFolder == nil ? .unavailable : .available
        await refreshSavedBackups()
    }

    func resolveCloud() async {
        guard place == .iCloud, cloudState == .checking else { return }
        await loadBackups()
    }

    func setPlace(_ newPlace: BackupPlace) async {
        place = newPlace
        defaults.set(newPlace.rawValue, forKey: Key.place)
        await refreshSavedBackups()
    }

    func refreshSavedBackups() async {
        let source = activeFolder
        let files = await Task.detached(priority: .utility) { (try? source.files()) ?? [] }.value
        savedBackups = files.map(SavedBackup.init(url:))
    }

    func openSaved(_ saved: SavedBackup) async {
        await perform {
            do {
                let data = try await Task.detached(priority: .userInitiated) {
                    try BackupFolder.read(saved.url)
                }.value
                try review(data)
            } catch let error as CashlyError {
                throw error
            } catch {
                throw CashlyError.invalidInput(String(appLocalized: "Couldn't read the file."))
            }
            isRestoringBackup = true
        }
    }
}
