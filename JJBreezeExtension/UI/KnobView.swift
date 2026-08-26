import SwiftUI
import AudioToolbox
import UIKit

struct KnobView: View {
    @Bindable var param: ObservableAUParameter
    var caption: String
    var skew: Float = 1
    var symmetric: Bool = false
    var helpText: String? = nil
    var linkedPeer: ObservableAUParameter? = nil
    var linkEnabled: Bool = false

    @State private var dragging = false
    @State private var startNormalized: Float = 0
    @State private var peerStart: Float = 0
    @State private var showValueEditor = false
    @State private var typedValue = ""
    @State private var showHelp = false

    private var range: SkewedRange {
        SkewedRange(min: param.min, max: param.max, skew: skew, symmetric: symmetric)
    }

    private var normalized: Float {
        range.toNormalized(param.value)
    }

    private var readout: String {
        JJBreezeAudioUnit.format(address: param.address, value: param.value)
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(caption)
                .font(.system(size: 11, weight: .bold, design: .default))
                .tracking(1.0)
                .foregroundStyle(GearTheme.textLight.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(minHeight: 16)
                .contentShape(Rectangle())
                .onLongPressGesture {
                    if helpText != nil {
                        showHelp = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }

            AnalogKnob(normalized: normalized, accent: GearTheme.accent)
                .aspectRatio(1, contentMode: .fit)
                // Capped so a host that hands us far more space than we
                // asked for (or ignores preferredContentSize entirely)
                // doesn't blow the knobs up to an absurd size — a real
                // hardware knob doesn't grow just because its rack panel
                // has more headroom.
                .frame(minWidth: 44, maxWidth: 96, minHeight: 44, maxHeight: 96)
                .contentShape(Rectangle())
                .gesture(dragGesture)
                .simultaneousGesture(TapGesture(count: 2).onEnded(resetToDefault))

            Button {
                typedValue = String(format: "%g", param.value)
                showValueEditor = true
            } label: {
                Text(readout)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(GearTheme.ledText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .frame(minHeight: 28)
                    .background(GearTheme.ledBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(GearTheme.metalDark, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(caption)
        .accessibilityValue(readout)
        .accessibilityHint(helpText ?? "Double-tap to reset. Drag vertically for coarse, horizontally for fine.")
        .accessibilityAdjustableAction { direction in
            let step: Float = 0.02
            let next = (normalized + (direction == .increment ? step : -step)).clamped01()
            applyNormalized(next, fromStart: normalized, peerStart: linkedPeer?.value ?? 0)
        }
        .sheet(isPresented: $showValueEditor) {
            valueEditor
        }
        .alert(caption, isPresented: $showHelp) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(helpText ?? "")
        }
    }

    private var valueEditor: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Range \(formatBound(param.min)) – \(formatBound(param.max))")
                    .font(.system(size: 13))
                    .foregroundStyle(GearTheme.textMuted)
                TextField("Value", text: $typedValue)
                    .keyboardType(.decimalPad)
                    .padding(10)
                    .background(GearTheme.panelFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(GearTheme.metalDark, lineWidth: 1)
                    )
                    .foregroundStyle(GearTheme.textLight)
                Spacer()
            }
            .padding(16)
            .background(GearTheme.chassisBottom)
            .navigationTitle(caption)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showValueEditor = false }
                        .foregroundStyle(GearTheme.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Set") { commitTypedValue() }
                        .foregroundStyle(GearTheme.accent)
                }
            }
        }
        .presentationDetents([.height(200), .medium])
        .tint(GearTheme.accent)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                if !dragging {
                    dragging = true
                    startNormalized = normalized
                    peerStart = linkedPeer?.value ?? 0
                    param.onEditingChanged(true)
                    linkedPeer?.onEditingChanged(true)
                }
                let vertical = Float(-value.translation.height)
                let horizontal = Float(value.translation.width)
                let fine = abs(horizontal) > abs(vertical) * 1.15
                let delta: Float
                if fine {
                    delta = horizontal / 900.0
                } else {
                    delta = vertical / 220.0
                }
                applyNormalized((startNormalized + delta).clamped01(), fromStart: startNormalized, peerStart: peerStart)
            }
            .onEnded { _ in
                param.onEditingChanged(false)
                linkedPeer?.onEditingChanged(false)
                dragging = false
            }
    }

    private func applyNormalized(_ next: Float, fromStart: Float, peerStart: Float) {
        let newValue = range.fromNormalized(next)
        let oldValue = range.fromNormalized(fromStart)
        param.value = newValue
        if linkEnabled, let peer = linkedPeer {
            let delta = newValue - oldValue
            peer.value = min(peer.max, max(peer.min, peerStart + delta))
        }
    }

    private func resetToDefault() {
        param.onEditingChanged(true)
        let old = param.value
        param.value = param.defaultValue
        if linkEnabled, let peer = linkedPeer {
            peer.onEditingChanged(true)
            peer.value = min(peer.max, max(peer.min, peer.value + (param.defaultValue - old)))
            peer.onEditingChanged(false)
        }
        param.onEditingChanged(false)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func commitTypedValue() {
        if let value = JJBreezeAudioUnit.parse(typedValue, address: param.address, min: param.min, max: param.max) {
            param.onEditingChanged(true)
            let old = param.value
            param.value = value
            if linkEnabled, let peer = linkedPeer {
                peer.onEditingChanged(true)
                peer.value = min(peer.max, max(peer.min, peer.value + (value - old)))
                peer.onEditingChanged(false)
            }
            param.onEditingChanged(false)
        }
        showValueEditor = false
    }

    private func formatBound(_ value: AUValue) -> String {
        JJBreezeAudioUnit.format(address: param.address, value: value)
    }
}

/// A knurled-metal rack-hardware knob: a fixed 7-tick printed scale, a
/// rotating cap with a straight pointer and jewel tip — matches the
/// desktop design's RetroLookAndFeel::drawRotarySlider exactly, proportions
/// scaled from its 78px reference knob to whatever size this one is.
private struct AnalogKnob: View {
    var normalized: Float
    var accent: Color

    private let startAngle = -135.0 * .pi / 180.0
    private let endAngle = 135.0 * .pi / 180.0

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 3, dy: 3)
            let diameter = min(rect.width, rect.height)
            let radius = diameter / 2
            let centre = CGPoint(x: rect.midX, y: rect.midY)
            let px = diameter / 78.0 // scales the fixed-px details below
            let angle = startAngle + Double(normalized) * (endAngle - startAngle)

            // Soft cast shadow behind the whole knob.
            let shadow = CGRect(x: centre.x - radius + 2 * px, y: centre.y - radius + 3 * px,
                                 width: diameter, height: diameter)
            context.fill(Path(ellipseIn: shadow), with: .color(GearTheme.chassisBottom.opacity(0.3)))

            // Fixed 7-tick scale (-135/-90/-45/0/45/90/135) — printed on the
            // panel, doesn't rotate with the knob.
            for i in 0..<7 {
                let t = Double(i) / 6.0
                let tickAngle = startAngle + t * (endAngle - startAngle)
                let major = i % 3 == 0
                let outer = CGPoint(x: centre.x + CGFloat(sin(tickAngle)) * radius * 0.99,
                                    y: centre.y - CGFloat(cos(tickAngle)) * radius * 0.99)
                let inner = CGPoint(x: centre.x + CGFloat(sin(tickAngle)) * radius * 0.89,
                                    y: centre.y - CGFloat(cos(tickAngle)) * radius * 0.89)
                var path = Path()
                path.move(to: inner)
                path.addLine(to: outer)
                context.stroke(path, with: .color(major ? GearTheme.textLight.opacity(0.85) : GearTheme.textMuted.opacity(0.5)),
                               lineWidth: (major ? 2.6 : 2.0) * px)
            }

            // Skirt (74% of the knob's diameter).
            let skirtR = radius * 0.74
            let skirt = CGRect(x: centre.x - skirtR, y: centre.y - skirtR, width: skirtR * 2, height: skirtR * 2)
            context.fill(Path(ellipseIn: skirt), with: .radialGradient(
                Gradient(colors: [GearTheme.metalMid, GearTheme.chassisBottom]),
                center: CGPoint(x: centre.x - skirtR * 0.32, y: centre.y - skirtR * 0.44),
                startRadius: 0, endRadius: skirtR * 1.4))

            // Cap (66% of the skirt's diameter), rotating with the value.
            let capR = skirtR * 0.66
            var rotated = context
            rotated.translateBy(x: centre.x, y: centre.y)
            rotated.rotate(by: .radians(angle))
            rotated.translateBy(x: -centre.x, y: -centre.y)

            let cap = CGRect(x: centre.x - capR, y: centre.y - capR, width: capR * 2, height: capR * 2)
            rotated.fill(Path(ellipseIn: cap), with: .linearGradient(
                Gradient(colors: [GearTheme.metalLight, GearTheme.metalDark]),
                startPoint: CGPoint(x: centre.x - capR * 0.5, y: centre.y - capR * 0.6),
                endPoint: CGPoint(x: centre.x + capR * 0.6, y: centre.y + capR * 0.7)))

            // Pointer + jewel tip, defined centre-relative (i.e. in the
            // cap's unrotated frame) and drawn through the same rotated
            // context so both rotate together with the cap.
            let pointerWidth = 3.0 * px
            let pointerNear = -0.32 * capR, pointerFar = -0.8 * capR
            let pointerRect = CGRect(x: centre.x - pointerWidth / 2, y: centre.y + pointerFar,
                                      width: pointerWidth, height: pointerNear - pointerFar)
            rotated.fill(Path(roundedRect: pointerRect, cornerRadius: pointerWidth * 0.4),
                         with: .color(GearTheme.textLight))

            let jewel = CGPoint(x: centre.x, y: centre.y - 0.84 * capR)
            let jewelD = 5.0 * px
            rotated.fill(Path(ellipseIn: CGRect(x: jewel.x - jewelD * 1.2, y: jewel.y - jewelD * 1.2,
                                                 width: jewelD * 2.4, height: jewelD * 2.4)),
                         with: .color(accent.opacity(0.55)))
            rotated.fill(Path(ellipseIn: CGRect(x: jewel.x - jewelD / 2, y: jewel.y - jewelD / 2,
                                                 width: jewelD, height: jewelD)),
                         with: .color(accent))
        }
    }
}

private extension Float {
    func clamped01() -> Float { min(1, max(0, self)) }
}
