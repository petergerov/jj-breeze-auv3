import SwiftUI

/// Chassis backdrop: a top-lit gradient plus a faint brushed-aluminium
/// grain, matching the desktop rack-panel design's chassis paint.
struct ChassisBackground: View {
    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            context.fill(Path(rect), with: .linearGradient(
                Gradient(colors: [GearTheme.chassisTop, GearTheme.chassisBottom]),
                startPoint: CGPoint(x: rect.midX, y: rect.minY),
                endPoint: CGPoint(x: rect.midX, y: rect.maxY)))

            // Deterministic grain so it doesn't flicker on every redraw.
            var rng = SeededGenerator(seed: 12345)
            var y: CGFloat = 0
            while y < rect.height {
                let alpha = Double.random(in: 0...0.035, using: &rng)
                var line = Path()
                line.move(to: CGPoint(x: rect.minX, y: y))
                line.addLine(to: CGPoint(x: rect.maxX, y: y))
                context.stroke(line, with: .color(.white.opacity(alpha)), lineWidth: 1)
                y += 3
            }
        }
        .allowsHitTesting(false)
    }
}

/// Simple deterministic PRNG (splitmix64-style) — only used to make the
/// chassis grain pattern stable across redraws, not for anything security-
/// or audio-relevant.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// A rack-mount ear: a vertical brushed-metal strip carrying two mounting
/// bolts, flanking the panel's left/right edges.
struct RackEar: View {
    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            context.fill(Path(rect), with: .linearGradient(
                Gradient(colors: [GearTheme.metalMid, GearTheme.metalDark]),
                startPoint: CGPoint(x: rect.midX, y: rect.minY),
                endPoint: CGPoint(x: rect.midX, y: rect.maxY)))

            let boltRadius = size.width * 0.17
            drawBolt(&context, at: CGPoint(x: rect.midX, y: rect.height * 0.28), radius: boltRadius)
            drawBolt(&context, at: CGPoint(x: rect.midX, y: rect.height * 0.72), radius: boltRadius)
        }
        .allowsHitTesting(false)
    }

    private func drawBolt(_ context: inout GraphicsContext, at centre: CGPoint, radius: CGFloat) {
        let rect = CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect), with: .radialGradient(
            Gradient(colors: [GearTheme.metalLight, GearTheme.metalDark]),
            center: CGPoint(x: centre.x - radius * 0.3, y: centre.y - radius * 0.4),
            startRadius: 0, endRadius: radius * 1.4))
        context.stroke(Path(ellipseIn: rect), with: .color(GearTheme.chassisBottom.opacity(0.5)), lineWidth: 1)
    }
}

/// The perforated base strip along the bottom edge, like the rivet line on
/// a real rack unit. Drawn on top of everything else (including the rack
/// ears), same as the desktop design's paint order.
struct FooterRivetStrip: View {
    var rivetCount: Int = 16

    var body: some View {
        ZStack {
            Rectangle().fill(Color.black.opacity(0.12))
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                ForEach(0..<rivetCount, id: \.self) { _ in
                    Circle()
                        .fill(GearTheme.textLight.opacity(0.18))
                        .frame(width: 3, height: 3)
                    Spacer(minLength: 0)
                }
            }
        }
        .allowsHitTesting(false)
    }
}
