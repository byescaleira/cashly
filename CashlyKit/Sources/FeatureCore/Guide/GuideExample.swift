import CashlyDesignSystem
import SwiftUI

public struct GuideExample<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(16)
            .frame(maxWidth: 420)
            .background(.groupedRow, in: .rect(cornerRadius: 22))
            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}
