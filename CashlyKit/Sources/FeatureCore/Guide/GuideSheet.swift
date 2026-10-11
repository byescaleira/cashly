import CashlyDesignSystem
import SwiftUI

public struct GuideSheet<Page: View>: View {
    @State private var height: CGFloat = 560
    private let index: Int
    private let count: Int
    private let isWorking: Bool
    private let back: (() -> Void)?
    private let primary: GuideAction
    private let secondary: GuideAction?
    private let page: Page

    public init(
        index: Int, count: Int, isWorking: Bool = false, back: (() -> Void)? = nil,
        primary: GuideAction, secondary: GuideAction? = nil, @ViewBuilder page: () -> Page
    ) {
        self.index = index
        self.count = count
        self.isWorking = isWorking
        self.back = back
        self.primary = primary
        self.secondary = secondary
        self.page = page()
    }

    public var body: some View {
        VStack(spacing: 24) {
            GuideTopBar(index: index, count: count, back: isWorking ? nil : back)
            page
                .id(index)
                .transition(
                    .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
                        .combined(with: .opacity))
            GuideButtons(primary: primary, secondary: secondary, isWorking: isWorking)
        }
        .padding([.horizontal, .bottom], 24)
        .padding(.top, 16)
        .fontDesign(.rounded)
        .animation(.smooth, value: index)
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGFloat.self) {
            $0.size.height
        } action: {
            height = $0
        }
        .presentationDetents([.height(height)])
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled(isWorking)
    }
}

private struct GuideTopBar: View {
    let index: Int
    let count: Int
    let back: (() -> Void)?

    var body: some View {
        ZStack {
            HStack(spacing: 6) {
                ForEach(0..<count, id: \.self) { step in
                    Capsule()
                        .fill(step == index ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: step == index ? 18 : 6, height: 6)
                }
            }
            .accessibilityHidden(true)
            if let back {
                Button("Voltar", systemImage: "chevron.left", action: back)
                    .labelStyle(.iconOnly)
                    .buttonBorderShape(.circle)
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(height: 44)
    }
}

private struct GuideButtons: View {
    let primary: GuideAction
    let secondary: GuideAction?
    let isWorking: Bool

    var body: some View {
        VStack(spacing: 12) {
            Button(action: primary.perform) {
                ZStack {
                    Text(primary.title).opacity(isWorking ? 0 : 1)
                    if isWorking { ProgressView() }
                }
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
            }
            .prominentButton()
            .controlSize(.large)
            .disabled(!primary.isEnabled || isWorking)
            if let secondary {
                Button(secondary.title, action: secondary.perform)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .disabled(!secondary.isEnabled || isWorking)
            }
        }
    }
}
