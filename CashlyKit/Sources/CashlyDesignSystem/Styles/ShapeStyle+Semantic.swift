import SwiftUI

extension ShapeStyle where Self == Color {
    public static var positive: Color { .green }
    public static var negative: Color { .red }
    public static var warning: Color { .orange }
    public static var info: Color { .blue }
    public static var disabled: Color { .gray }
    public static var subtleFill: Color { Color.secondary.opacity(0.12) }
    public static var rowFill: Color { Color.secondary.opacity(0.08) }
}
