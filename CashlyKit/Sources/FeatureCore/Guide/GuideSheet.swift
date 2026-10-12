import CashlyDesignSystem
import SwiftUI

public struct GuideSheet<Page: View>: View {
    @State private var height: CGFloat = 560
    @State private var shownIndex = 0
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
                    .asymmetric(
                        insertion: .move(edge: index >= shownIndex ? .trailing : .leading)
                            .combined(with: .opacity),
                        removal: .opacity))
            GuideButtons(primary: primary, secondary: secondary, isWorking: isWorking)
        }
        .padding([.horizontal, .bottom], 24)
        .padding(.top, 16)
        .fontDesign(.rounded)
        .animation(.smooth, value: index)
        .onChange(of: index, initial: true) { shownIndex = index }
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGFloat.self) {
            $0.size.height
        } action: {
            height = $0
        }
        .presentationDetents([.height(height)])
        .presentationDragIndicator(.hidden)
        #if !os(visionOS)
            .presentationBackground(.sheetBackground)
        #endif
        #if os(iOS)
            .modifier(GuidePlacement())
        #endif
        .interactiveDismissDisabled(isWorking)
    }
}

#if os(iOS)
    private struct GuidePlacement: ViewModifier {
        @Environment(\.verticalSizeClass) private var verticalSizeClass

        func body(content: Content) -> some View {
            if UIDevice.current.userInterfaceIdiom == .pad {
                content
                    .presentationPlacement(.center)
                    .presentationSizing(.form.fitted(horizontal: false, vertical: true))
            } else if verticalSizeClass == .compact {
                content
                    .presentationPlacement(.trailing)
                    .presentationSizing(.form)
            } else {
                content
            }
        }
    }
#endif

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
                        .frame(width: step == index ? 20 : 10, height: 10)
                }
            }
            .accessibilityHidden(true)
            if let back {
                Button("Voltar", systemImage: "chevron.left", action: back)
                    .labelStyle(.iconOnly)
                    .buttonBorderShape(.circle)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
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
                    .font(.body.weight(.semibold))
                    .buttonStyle(.borderless)
                    .disabled(!secondary.isEnabled || isWorking)
            }
        }
    }
}
