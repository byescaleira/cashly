import CashlyDesignSystem
import SwiftUI

struct MoneyRainView: View {
    private struct Piece {
        let isBill: Bool
        let x: Double
        let delay: Double
        let speed: Double
        let sway: Double
        let spin: Double
        let size: Double
    }

    @State private var pieces: [Piece] = []
    @State private var start = Date.now
    @State private var isDone = false
    private let duration = 2.5
    private let count = 60

    var body: some View {
        TimelineView(.animation(paused: isDone)) { timeline in
            let time = timeline.date.timeIntervalSince(start)
            Canvas { canvas, size in
                for piece in pieces { draw(piece, at: time, in: canvas, size: size) }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task {
            pieces = (0..<count).map { index in
                Piece(
                    isBill: index.isMultiple(of: 3), x: .random(in: 0.04...0.96),
                    delay: .random(in: 0...0.9), speed: .random(in: 0.8...1.3),
                    sway: .random(in: 1.5...3.5), spin: .random(in: 3...7),
                    size: .random(in: 18...28))
            }
            start = .now
            try? await Task.sleep(for: .seconds(duration))
            isDone = true
        }
    }

    private func draw(_ piece: Piece, at time: Double, in canvas: GraphicsContext, size: CGSize) {
        let local = time - piece.delay
        guard local > 0 else { return }
        let progress = min(local / (duration - piece.delay), 1)
        var graphics = canvas
        graphics.translateBy(
            x: size.width * piece.x + sin(local * piece.sway) * size.width * 0.05,
            y: (size.height + piece.size * 4) * progress * piece.speed - piece.size * 2)
        graphics.opacity = 1 - pow(progress, 3)
        if piece.isBill {
            drawBill(in: &graphics, piece: piece, time: local)
        } else {
            drawCoin(in: &graphics, piece: piece, time: local, progress: progress)
        }
    }

    private func drawCoin(
        in graphics: inout GraphicsContext, piece: Piece, time: Double, progress: Double
    ) {
        let turn = cos(time * piece.spin)
        graphics.scaleBy(x: max(abs(turn), 0.12), y: 1)
        let radius = piece.size / 2
        let face = CGRect(x: -radius, y: -radius, width: piece.size, height: piece.size)
        graphics.fill(
            Path(ellipseIn: face),
            with: .linearGradient(
                Gradient(colors: [.retroCream, .retroMustard]),
                startPoint: CGPoint(x: -radius, y: -radius), endPoint: CGPoint(x: radius, y: radius)
            ))
        graphics.stroke(
            Path(ellipseIn: face.insetBy(dx: radius * 0.3, dy: radius * 0.3)),
            with: .color(.retroBrown.opacity(.opacitySoft)), lineWidth: .spaceHairline)
        if turn > 0.5, progress < 0.6 {
            graphics.draw(
                Text(Image(systemName: "dollarsign"))
                    .font(.icon(.xs, weight: .black))
                    .foregroundStyle(Color.retroBrown),
                at: .zero)
        }
    }

    private func drawBill(in graphics: inout GraphicsContext, piece: Piece, time: Double) {
        graphics.rotate(by: .radians(sin(time * piece.spin * 0.5) * 0.6))
        graphics.scaleBy(x: 1, y: max(abs(cos(time * piece.spin * 0.7)), 0.25))
        let rect = CGRect(
            x: -piece.size, y: -piece.size / 2, width: piece.size * 2, height: piece.size)
        graphics.fill(
            Path(roundedRect: rect, cornerRadius: piece.size / 8), with: .color(.retroOlive))
        graphics.stroke(
            Path(
                roundedRect: rect.insetBy(dx: piece.size / 8, dy: piece.size / 8),
                cornerRadius: piece.size / 12),
            with: .color(.white.opacity(.opacitySoft)), lineWidth: .spaceHairline)
        let seal = piece.size * 0.28
        graphics.fill(
            Path(ellipseIn: CGRect(x: -seal, y: -seal, width: seal * 2, height: seal * 2)),
            with: .color(.white.opacity(.opacitySoft)))
    }
}
