import CashlyDomain
import FeatureCore
import Foundation

extension UserEditorModel {
    public var createsShared: Bool { draft.isNew && draft.isShared }
    public var showsSharing: Bool { draft.isShared }
    public var showsPeople: Bool { draft.isShared && !draft.isNew && sharing?.isEnabled == true }
    public var settingsURL: URL? { sharing?.settingsURL }
    public var canShare: Bool { sharing?.canCreate == true }
    public var showsAccountNotice: Bool {
        createsShared && sharing?.hasCheckedAccount == true && !canShare
    }
    public var canCopyCategories: Bool { createsShared && !sourceCategories.isEmpty }

    public var copyCategoriesTitle: String {
        guard let sourceName else { return String(appLocalized: "Copy My Categories") }
        return String(appLocalized: "Copy Categories from \(sourceName)")
    }

    public var copyCategoriesDetail: String {
        String(
            appLocalized: "\(sourceCategories.count) categories, without transactions or budgets.")
    }

    public func checkAccount() async {
        guard createsShared else { return }
        await sharing?.checkAccount()
    }
}
