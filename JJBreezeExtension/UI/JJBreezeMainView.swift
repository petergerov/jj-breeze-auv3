import SwiftUI

struct JJBreezeMainView: View {
    var parameterTree: ObservableAUParameterGroup
    var audioUnit: JJBreezeAudioUnit?

    @State private var linkPitch = true
    @State private var linkDelay = true
    @State private var isBypassed = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [GearTheme.chassisTop, GearTheme.chassisBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        header
                        EffectSection(title: "SHIFT", enabled: parameterTree.shift.shiftOn) {
                            HStack {
                                LinkToggle(isOn: $linkPitch, title: "PITCH")
                                LinkToggle(isOn: $linkDelay, title: "DELAY")
                                Spacer()
                            }
                            LazyVGrid(columns: threeColumns, spacing: 10) {
                                KnobView(
                                    param: parameterTree.shift.pitchL,
                                    caption: "PITCH L",
                                    skew: 0.4,
                                    symmetric: true,
                                    linkedPeer: parameterTree.shift.pitchR,
                                    linkEnabled: linkPitch
                                )
                                KnobView(
                                    param: parameterTree.shift.pitchR,
                                    caption: "PITCH R",
                                    skew: 0.4,
                                    symmetric: true,
                                    linkedPeer: parameterTree.shift.pitchL,
                                    linkEnabled: linkPitch
                                )
                                KnobView(
                                    param: parameterTree.shift.focus,
                                    caption: "FOCUS",
                                    skew: 0.25,
                                    helpText: "Crossover frequency. Frequencies below this stay dry; highs go through pitch and delay."
                                )
                                KnobView(param: parameterTree.shift.delayL, caption: "DELAY L", skew: 0.3, linkedPeer: parameterTree.shift.delayR, linkEnabled: linkDelay)
                                KnobView(param: parameterTree.shift.delayR, caption: "DELAY R", skew: 0.3, linkedPeer: parameterTree.shift.delayL, linkEnabled: linkDelay)
                                KnobView(param: parameterTree.shift.mix, caption: "MIX")
                            }
                        }
                        EffectSection(title: "VIBRATO", enabled: parameterTree.vibrato.vibratoOn) {
                            LazyVGrid(columns: threeColumns, spacing: 10) {
                                KnobView(param: parameterTree.vibrato.vibratoRate, caption: "RATE", skew: 0.4)
                                KnobView(param: parameterTree.vibrato.vibratoDepth, caption: "DEPTH")
                                KnobView(param: parameterTree.vibrato.vibratoMix, caption: "MIX")
                            }
                        }
                        EffectSection(title: "WARMTH", enabled: parameterTree.warmth.warmthOn) {
                            LazyVGrid(columns: threeColumns, spacing: 10) {
                                KnobView(param: parameterTree.warmth.warmthTone, caption: "TONE", skew: 0.3)
                                KnobView(
                                    param: parameterTree.warmth.warmthDrive,
                                    caption: "DRIVE",
                                    helpText: "Saturation amount in the warmth stage."
                                )
                                KnobView(
                                    param: parameterTree.warmth.warmthBody,
                                    caption: "BODY",
                                    helpText: "Low-shelf boost in the warmth stage. Adds weight without changing Tone."
                                )
                                KnobView(param: parameterTree.warmth.warmthMix, caption: "MIX")
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(minHeight: max(geo.size.height, 560))
                }
            }
        }
        .onAppear {
            isBypassed = audioUnit?.shouldBypassEffect ?? false
        }
        .onChange(of: isBypassed) { _, newValue in
            audioUnit?.shouldBypassEffect = newValue
        }
    }

    private var threeColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("J.J.BREEZE")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .tracking(1.2)
                    .foregroundStyle(GearTheme.textLight)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                LevelMeterView(audioUnit: audioUnit)
                BypassToggle(isBypassed: $isBypassed)
            }

            PresetBar(audioUnit: audioUnit)
        }
    }
}

private struct EffectSection<Content: View>: View {
    let title: String
    @Bindable var enabled: ObservableAUParameter
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(enabled.boolValue ? GearTheme.accent : GearTheme.textMuted)
                Spacer()
                LedToggle(param: enabled)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(GearTheme.accent.opacity(enabled.boolValue ? 0.5 : 0.2))
                    .frame(height: 1)
                    .padding(.trailing, 60)
            }

            content()
                .opacity(enabled.boolValue ? 1 : 0.42)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(GearTheme.panelFill)
                .shadow(color: GearTheme.chassisBottom.opacity(0.6), radius: 2, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(GearTheme.chassisBottom.opacity(0.9), lineWidth: 1)
        )
    }
}
