import CashlyDomain
import Foundation

public struct UpdateRequiredError: Error, LocalizedError, CustomLocalizedStringResourceConvertible {
    public init() {}

    public var localizedStringResource: LocalizedStringResource {
        "Update Cashly in the App Store to keep using it. Your data is safe."
    }

    public var errorDescription: String? {
        String(appLocalized: "Update Cashly in the App Store to keep using it. Your data is safe.")
    }
}
