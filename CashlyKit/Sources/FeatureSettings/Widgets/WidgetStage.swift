import CashlyDesignSystem
import CashlyWidgetUI
import SwiftUI

struct WidgetStage: View {
    @Environment(WidgetsModel.self) private var widgets
    @Environment(\.appTint) private var appTint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let widget: CashlyWidget

    var body: some View {
        let preview = widgets.preview(for: widget)
        Group {
            switch preview {
            case .home(let size): HomeCanvas(widget: widget, size: size)
            case .lockScreen: LockScreenCanvas(widget: widget)
            }
        }
        .id(preview)
        .transition(.scale(scale: 0.94).combined(with: .opacity))
        .padding(.spaceL)
        .frame(maxWidth: .infinity)
        .background(stage(preview), in: .rect(cornerRadius: .radiusM, style: .continuous))
        .animation(reduceMotion ? nil : .smooth, value: preview)
        .animation(reduceMotion ? nil : .smooth, value: widgets.selectedChoice)
        .dynamicTypeSize(.large)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
    }

    private func stage(_ preview: WidgetPreview) -> AnyShapeStyle {
        preview == .lockScreen
            ? AnyShapeStyle(Color.black.gradient) : AnyShapeStyle(appTint.opacity(.opacityFill))
    }
}

private struct HomeCanvas: View {
    @Environment(WidgetsModel.self) private var widgets
    let widget: CashlyWidget
    let size: WidgetSize

    var body: some View {
        FittedCanvas(size: size.canvas) {
            CashlyWidgetView(widget, size: size, snapshot: widgets.snapshot)
                .padding(.spaceL)
                .frame(width: size.canvas.width, height: size.canvas.height)
                .background(.background, in: .rect(cornerRadius: .radiusL, style: .continuous))
        }
        .shadow(color: .black.opacity(.opacityFill), radius: 8, y: 3)
    }
}

private struct LockScreenCanvas: View {
    @Environment(WidgetsModel.self) private var widgets
    let widget: CashlyWidget

    var body: some View {
        let sizes = widgets.lockScreenSizes(for: widget)
        FittedCanvas(size: .lockScreen) {
            VStack(spacing: .spaceXS) {
                if sizes.contains(.inline) { Accessory(widget: widget, size: .inline) }
                Text(Date.now, format: .dateTime.hour().minute())
                    .font(.largeTitle.weight(.bold))
                    .fontDesign(.rounded)
                    .monospacedDigit()
                HStack(spacing: .spaceM) {
                    ForEach(sizes.filter { $0 != .inline }) { Accessory(widget: widget, size: $0) }
                }
            }
            .frame(width: CGSize.lockScreen.width, height: CGSize.lockScreen.height)
        }
        .foregroundStyle(.white)
        .environment(\.colorScheme, .dark)
    }
}

private struct Accessory: View {
    @Environment(WidgetsModel.self) private var widgets
    let widget: CashlyWidget
    let size: WidgetSize

    var body: some View {
        CashlyWidgetView(widget, size: size, snapshot: widgets.snapshot)
            .padding(size == .rectangular ? .spaceXS : 0)
            .frame(width: size.canvas.width, height: size.canvas.height)
            .background {
                switch size {
                case .circular: Circle().fill(.white.opacity(.opacityTint))
                case .rectangular:
                    RoundedRectangle(cornerRadius: .radiusS, style: .continuous)
                        .fill(.white.opacity(.opacityFill))
                default: Color.clear
                }
            }
    }
}

private struct FittedCanvas<Content: View>: View {
    let size: CGSize
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { proxy in
            content
                .frame(width: size.width, height: size.height)
                .scaleEffect(min(1, proxy.size.width / size.width), anchor: .topLeading)
        }
        .aspectRatio(size, contentMode: .fit)
        .frame(maxWidth: size.width)
    }
}

extension CGSize {
    fileprivate static let lockScreen = CGSize(width: 244, height: 170)
}
