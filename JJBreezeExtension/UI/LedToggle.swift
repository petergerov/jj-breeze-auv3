import SwiftUI
import UIKit

/// A physical-style rocker/slide switch — a vertical slot with a lever that
/// sits at the top (on) or bottom (off), glowing accent-coloured when on.
/// Matches the rack-panel design's IN/OUT and POWER switches; LedToggle and
/// BypassToggle below both draw one of these, just bound to different state.
struct RockerSwitch: View {
    var isOn: Bool
    var accent: Color = GearTheme.accent

    private let slotAspect: CGFloat = 17.0 / 30.0 // width / height

    var body: some View {
        GeometryReader { geo in
            let slot = slotSize(in: geo.size)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: slot.width * 0.18)
                    .fill(LinearGradient(
                        colors: [GearTheme.ledBackground.opacity(0.95), GearTheme.chassisBottom],
                        startPoint: .top, endPoint: .bottom))
                    .frame(width: slot.width, height: slot.height)

                lever(in: slot)
            }
            .frame(width: slot.width, height: slot.height)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }

    private func slotSize(in full: CGSize) -> CGSize {
        var height = full.height
        var width = height * slotAspect
        if width > full.width {
            width = full.width
            height = width / slotAspect
        }
        return CGSize(width: width, height: height)
    }

    @ViewBuilder
    private func lever(in slot: CGSize) -> some View {
        let margin = slot.width * 0.15
        let leverWidth = slot.width - margin * 2
        let leverHeight = slot.height * 0.43
        let leverTop = isOn ? slot.height * 0.08 : slot.height * (1 - 0.43 - 0.08)

        ZStack(alignment: .topLeading) {
            if isOn {
                let expand = slot.width * 0.56
                RoundedRectangle(cornerRadius: leverHeight / 2)
                    .fill(accent.opacity(0.4))
                    .frame(width: leverWidth + expand, height: leverHeight + expand)
                    .offset(x: margin - expand / 2, y: leverTop - expand / 2)
            }

            RoundedRectangle(cornerRadius: leverWidth * 0.2)
                .fill(LinearGradient(
                    colors: [Color(red: 0xef / 255, green: 0xe9 / 255, blue: 0xdb / 255),
                             Color(red: 0xa9 / 255, green: 0xa0 / 255, blue: 0x8c / 255)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: leverWidth, height: leverHeight)
                .offset(x: margin, y: leverTop)
        }
        .frame(width: slot.width, height: slot.height, alignment: .topLeading)
    }
}

struct LedToggle: View {
    @Bindable var param: ObservableAUParameter

    var body: some View {
        Button {
            param.boolValue.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            RockerSwitch(isOn: param.boolValue)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(param.displayName)
        .accessibilityValue(param.boolValue ? "On" : "Off")
    }
}

struct BypassToggle: View {
    @Binding var isBypassed: Bool

    var body: some View {
        Button {
            isBypassed.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            // Drawn state is the inverse of the flag — a power switch reads
            // on when the effect is actually processing, i.e. not bypassed.
            RockerSwitch(isOn: !isBypassed)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Power")
        .accessibilityValue(isBypassed ? "Off" : "On")
    }
}

/// A small round link/unlink badge sitting in the gap between a pair of
/// knobs (e.g. PITCH L/PITCH R) rather than in a separate row above them —
/// toggles whether dragging one of the pair moves the other by the same
/// amount (see KnobView's linkedPeer/linkEnabled).
struct LinkIconBadge: View {
    @Binding var isOn: Bool
    var title: String

    var body: some View {
        Button {
            isOn.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Image(systemName: isOn ? "link" : "link.badge.plus")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(isOn ? GearTheme.accent : GearTheme.textMuted)
                .frame(width: 22, height: 22)
                .background(Circle().fill(GearTheme.panelFill))
                .overlay(
                    Circle().stroke(isOn ? GearTheme.accent.opacity(0.6) : GearTheme.metalDark, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) link")
        .accessibilityValue(isOn ? "Linked" : "Unlinked")
    }
}
