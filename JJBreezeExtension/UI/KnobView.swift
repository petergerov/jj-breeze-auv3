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
                .frame(minWidth: 44, minHeight: 44)
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

private struct AnalogKnob: View {
    var normalized: Float
    var accent: Color

    private let startAngle = Angle.degrees(-135)
    private let endAngle = Angle.degrees(135)

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 4, dy: 4)
            let radius = min(rect.width, rect.height) / 2
            let centre = CGPoint(x: rect.midX, y: rect.midY)
            let angle = startAngle.radians + Double(normalized) * (endAngle.radians - startAngle.radians)

            for i in 0..<11 {
                let t = Double(i) / 10.0
                let tickAngle = startAngle.radians + t * (endAngle.radians - startAngle.radians)
                let major = (i == 0 || i == 10 || i == 5)
                let inner = CGPoint(x: centre.x + CGFloat(sin(tickAngle)) * radius * 0.88,
                                    y: centre.y - CGFloat(cos(tickAngle)) * radius * 0.88)
                let outer = CGPoint(x: centre.x + CGFloat(sin(tickAngle)) * radius,
                                    y: centre.y - CGFloat(cos(tickAngle)) * radius)
                var path = Path()
                path.move(to: inner)
                path.addLine(to: outer)
                context.stroke(path, with: .color(GearTheme.textMuted.opacity(major ? 0.85 : 0.45)),
                               lineWidth: major ? 1.6 : 1.0)
            }

            let arcRadius = radius * 0.82
            var track = Path()
            track.addArc(center: centre, radius: arcRadius, startAngle: startAngle - .degrees(90),
                         endAngle: endAngle - .degrees(90), clockwise: false)
            context.stroke(track, with: .color(GearTheme.metalDark.opacity(0.9)),
                           style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

            var valueArc = Path()
            valueArc.addArc(center: centre, radius: arcRadius, startAngle: startAngle - .degrees(90),
                            endAngle: Angle.radians(angle) - .degrees(90), clockwise: false)
            context.stroke(valueArc, with: .color(accent),
                           style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

            let skirtR = radius * 0.66
            let capR = skirtR * 0.80
            let shadow = CGRect(x: centre.x - skirtR + 1.5, y: centre.y - skirtR + 2.5, width: skirtR * 2, height: skirtR * 2)
            context.fill(Path(ellipseIn: shadow), with: .color(GearTheme.chassisBottom.opacity(0.55)))

            let skirt = CGRect(x: centre.x - skirtR, y: centre.y - skirtR, width: skirtR * 2, height: skirtR * 2)
            context.fill(Path(ellipseIn: skirt), with: .linearGradient(
                Gradient(colors: [GearTheme.metalMid, GearTheme.chassisBottom]),
                startPoint: CGPoint(x: skirt.minX, y: skirt.minY),
                endPoint: CGPoint(x: skirt.maxX, y: skirt.maxY)
            ))

            let cap = CGRect(x: centre.x - capR, y: centre.y - capR, width: capR * 2, height: capR * 2)
            context.fill(Path(ellipseIn: cap), with: .linearGradient(
                Gradient(colors: [GearTheme.metalLight, GearTheme.metalDark]),
                startPoint: CGPoint(x: cap.minX, y: cap.minY),
                endPoint: CGPoint(x: cap.maxX, y: cap.maxY)
            ))

            let pointerLength = capR * 0.82
            let tip = CGPoint(x: centre.x + CGFloat(sin(angle)) * pointerLength,
                              y: centre.y - CGFloat(cos(angle)) * pointerLength)
            var pointer = Path()
            pointer.move(to: centre)
            pointer.addLine(to: tip)
            context.stroke(pointer, with: .color(accent), style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
            context.fill(Path(ellipseIn: CGRect(x: tip.x - 2, y: tip.y - 2, width: 4, height: 4)), with: .color(accent))
        }
    }
}

private extension Float {
    func clamped01() -> Float { min(1, max(0, self)) }
}
