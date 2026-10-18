import FeatureCore

extension Guide {
    static var backupsPages: [TutorialPage] {
        [
            TutorialPage(
                animation: .file, title: "Backups",
                message:
                    "A backup is one file with profiles, categories, tags, budgets and transactions. Turn on Automatic Backup, or save copies to iCloud Drive."
            ),
            TutorialPage(
                animation: .backup, title: "Sync with iCloud",
                message:
                    "With Sync on, every device signed in to your Apple Account shows the same months. Nothing leaves your iCloud."
            ),
            TutorialPage(
                animation: .connect, title: "Connect Claude Code",
                message:
                    "In Settings › Claude Code, allow access and connect from your Mac. Claude can read your months and send transactions, always with your approval."
            ),
        ]
    }

    static var privacyPages: [TutorialPage] {
        [
            TutorialPage(
                animation: .privacy, title: "Lock Cashly",
                message:
                    "Turn on the lock in Settings › Privacy. Cashly asks for Face ID whenever it comes back to the front and hides its content in the app switcher."
            ),
            TutorialPage(
                animation: .discreet, title: "Discreet Mode",
                message:
                    "Discreet Mode blurs every amount until you turn it off. Handy on the train or when you show the app to someone."
            ),
            TutorialPage(
                animation: .backup, title: "Your Data Stays Yours",
                message:
                    "Everything lives on your device and in your iCloud. No account, no servers, no third parties. Export a backup anytime."
            ),
        ]
    }
}
