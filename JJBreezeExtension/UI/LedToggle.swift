import SwiftUI

struct LedToggle: View {
    @Bindable var param: ObservableAUParameter

    var body: some View {
        Button {
            param.boolValue.toggle()
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
                    .frame(width: 12, height: 12)
            }
            .frame(width: 34, height: 22)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(param.displayName)
        .accessibilityValue(param.boolValue ? "On" : "Off")
    }
}
