import CashlyDesignSystem
import FeatureCore
import FeatureSettings
import SwiftUI

public struct UpdateRequiredScreen: View {
    @Environment(AppUpdateModel.self) private var update
    @Environment(SettingsModel.self) private var settings
    @Environment(\.openURL) private var openURL

    public init() {}

    public var body: some View {
        VStack(spacing: .spaceXL) {
            Spacer(minLength: 0)
            GuidePage(verbatim: update.requiredTitle, message: update.requiredMessage) {
                CashlyAnimationView(.launch, loops: true)
            }
            Spacer(minLength: 0)
            VStack(spacing: .spaceM) {
                if let url = update.appStoreURL {
                    Button("Update") { openURL(url) }.primaryButton()
                }
                if let data = settings.data {
                    DataExportMenu().environment(data)
                }
                if update.isSimulating {
                    Button("Stop Simulating") { update.simulate(nil) }
                        .font(.buttonLabel)
                        .buttonStyle(.borderless)
                }
            }
        }
        .frame(maxWidth: 440)
        .padding(.spaceXL)
        .fontDesign(.rounded)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.groupedBackground)
    }
}
