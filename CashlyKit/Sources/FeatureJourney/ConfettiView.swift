import SwiftUI

struct ConfettiView: View {
    private struct Piece {
        let x: Double
        let speed: Double
        let sway: Double
        let spin: Double
        let size: Double
        let color: Color
    }

    @State private var pieces: [Piece] = []
    @State private var start = Date.now
    @State private var isDone = false
    let colors: [Color]
    private let duration = 2.5
    private let count = 70

    var body: some View {
        TimelineView(.animation(paused: isDone)) { timeline in
            let time = timeline.date.timeIntervalSince(start)
            let progress = min(max(time / duration, 0), 1)
            Canvas { canvas, size in
                for piece in pieces {
                    var graphics = canvas
                    let sway = sin(time * piece.sway) * size.width * 0.04
                    graphics.translateBy(
                        x: size.width * piece.x + sway,
                        y: size.height * progress * piece.speed - piece.size * 2)
                    graphics.rotate(by: .radians(time * piece.spin))
                    graphics.opacity = 1 - progress * progress
                    let rect = CGRect(
                        x: -piece.size / 2, y: -piece.size / 4, width: piece.size,
                        height: piece.size / 2)
                    graphics.fill(Path(rect), with: .color(piece.color))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task {
            pieces = (0..<count).map { _ in
                Piece(
                    x: .random(in: 0...1), speed: .random(in: 0.7...1.4),
                    sway: .random(in: 2...5), spin: .random(in: -6...6),
                    size: .random(in: 6...12), color: colors.randomElement() ?? .primary)
            }
            start = .now
            try? await Task.sleep(for: .seconds(duration))
            isDone = true
        }
    }
}
