import SwiftUI
import UIKit

struct LedToggle: View {
    @Bindable var param: ObservableAUParameter

    var body: some View {
        Button {
            param.boolValue.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            ZStack {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [GearTheme.metalMid, GearTheme.chassisBottom],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Capsule()
                    .stroke(GearTheme.chassisBottom.opacity(0.9), lineWidth: 1)

                Circle()
                    .fill(param.boolValue ? GearTheme.accent.opacity(0.30) : .clear)
                    .frame(width: 28, height: 28)

                Circle()
                    .fill(param.boolValue ? GearTheme.accent : Color(red: 0.21, green: 0.20, blue: 0.18))
                    .frame(width: 14, height: 14)
            }
            .frame(width: 52, height: 32)
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
            Text("BYP")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(isBypassed ? GearTheme.chassisBottom : GearTheme.textLight)
                .frame(minWidth: 44, minHeight: 32)
                .background(isBypassed ? GearTheme.accent : GearTheme.panelFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isBypassed ? GearTheme.accent : GearTheme.metalDark, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Bypass")
        .accessibilityValue(isBypassed ? "On" : "Off")
    }
}

struct LinkToggle: View {
    @Binding var isOn: Bool
    var title: String

    var body: some View {
        Button {
            isOn.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isOn ? "link" : "link.badge.plus")
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.4)
            }
            .foregroundStyle(isOn ? GearTheme.accent : GearTheme.textMuted)
            .padding(.horizontal, 8)
            .frame(minHeight: 32)
            .background(GearTheme.panelFill.opacity(0.01))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "Linked" : "Unlinked")
    }
}
