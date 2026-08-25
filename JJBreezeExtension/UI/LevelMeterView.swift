import SwiftUI

struct LevelMeterView: View {
    let audioUnit: JJBreezeAudioUnit?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 20.0)) { context in
            let peaks = audioUnit?.takeMeterPeaks() ?? (0, 0)
            let env = Envelope.shared.tick(now: context.date, peaks: peaks)
            MeterBars(input: env.input, output: env.output)
        }
        .frame(width: 72, height: 32)
        .accessibilityHidden(true)
    }
}

private struct MeterBars: View {
    var input: Float
    var output: Float

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            meterRow(label: "IN", level: input)
            meterRow(label: "OUT", level: output)
        }
    }

    private func meterRow(label: String, level: Float) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(GearTheme.textMuted)
                .frame(width: 22, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(GearTheme.ledBackground)
                    Capsule()
                        .fill(GearTheme.accent)
                        .frame(width: max(2, geo.size.width * CGFloat(displayLevel(level))))
                }
            }
            .frame(height: 6)
        }
    }

    private func displayLevel(_ peak: Float) -> Float {
        let db = 20 * log10(max(peak, 0.000_1))
        return min(1, max(0, (db + 48) / 48))
    }
}

/// Holds decaying peak envelopes so the DSP can reset peaks each poll.
private final class Envelope: @unchecked Sendable {
    static let shared = Envelope()
    private var input: Float = 0
    private var output: Float = 0
    private var lastDate = Date.distantPast

    func tick(now: Date, peaks: (input: Float, output: Float)) -> (input: Float, output: Float) {
        // TimelineView may evaluate the view builder more than once per frame.
        // Only consume DSP peaks on a real time step.
        if now.timeIntervalSince(lastDate) > 0.02 {
            lastDate = now
            input = max(input * 0.72, peaks.input)
            output = max(output * 0.72, peaks.output)
        }
        return (input, output)
    }
}
