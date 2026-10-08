import Charts
import SwiftUI

extension View {
    func chartScrolling(visible length: Double, count: Int) -> some View {
        modifier(ChartScrolling(length: length, count: count))
    }
}

private struct ChartScrolling: ViewModifier {
    let length: Double
    let count: Int

    @ViewBuilder func body(content: Content) -> some View {
        if Double(count) > length {
            content.chartScrollableAxes(.horizontal).chartXVisibleDomain(length: length)
        } else {
            content
        }
    }
}
