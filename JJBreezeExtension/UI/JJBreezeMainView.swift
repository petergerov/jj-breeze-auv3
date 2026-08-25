import SwiftUI

struct JJBreezeMainView: View {
    var parameterTree: ObservableAUParameterGroup
    var audioUnit: JJBreezeAudioUnit?

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
                    VStack(spacing: 12) {
                        header
                        EffectSection(title: "SHIFT", enabled: parameterTree.shift.shiftOn) {
                            LazyVGrid(columns: threeColumns, spacing: 8) {
                                KnobView(param: parameterTree.shift.pitchL, caption: "PITCH L", skew: 0.4, symmetric: true)
                                KnobView(param: parameterTree.shift.pitchR, caption: "PITCH R", skew: 0.4, symmetric: true)
                                KnobView(param: parameterTree.shift.focus, caption: "FOCUS", skew: 0.25)
                                KnobView(param: parameterTree.shift.delayL, caption: "DELAY L")
                                KnobView(param: parameterTree.shift.delayR, caption: "DELAY R")
                                KnobView(param: parameterTree.shift.mix, caption: "MIX")
                            }
                        }
                        EffectSection(title: "SLAPBACK", enabled: parameterTree.slapback.slapOn) {
                            LazyVGrid(columns: threeColumns, spacing: 8) {
                                KnobView(param: parameterTree.slapback.slapTime, caption: "TIME")
                                KnobView(param: parameterTree.slapback.slapFeedback, caption: "FEEDBACK")
                                KnobView(param: parameterTree.slapback.slapMix, caption: "MIX")
                            }
                        }
                        EffectSection(title: "VIBRATO", enabled: parameterTree.vibrato.vibratoOn) {
                            LazyVGrid(columns: threeColumns, spacing: 8) {
                                KnobView(param: parameterTree.vibrato.vibratoRate, caption: "RATE", skew: 0.4)
                                KnobView(param: parameterTree.vibrato.vibratoDepth, caption: "DEPTH")
                                KnobView(param: parameterTree.vibrato.vibratoMix, caption: "MIX")
                            }
                        }
                        EffectSection(title: "WARMTH", enabled: parameterTree.warmth.warmthOn) {
                            LazyVGrid(columns: fourColumns, spacing: 8) {
                                KnobView(param: parameterTree.warmth.warmthTone, caption: "TONE", skew: 0.3)
                                KnobView(param: parameterTree.warmth.warmthDrive, caption: "DRIVE")
                                KnobView(param: parameterTree.warmth.warmthBody, caption: "BODY")
                                KnobView(param: parameterTree.warmth.warmthMix, caption: "MIX")
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: max(geo.size.height, 640))
                }
            }
        }
    }

    private var threeColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    }

    private var fourColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("J.J. BREEZE")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .tracking(2)
                .foregroundStyle(GearTheme.textLight)

            Text("STEREO WIDENER  ·  SLAPBACK  ·  VIBRATO  ·  WARMTH")
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .tracking(0.6)
                .foregroundStyle(GearTheme.textMuted)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Menu {
                ForEach(FactoryPresets.all, id: \.number) { preset in
                    Button(preset.name) {
                        audioUnit?.currentPreset = audioUnit?.factoryPresets?[preset.number]
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(audioUnit?.currentPreset?.name ?? "Default")
                        .font(.system(size: 12, weight: .semibold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(GearTheme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(GearTheme.panelFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(GearTheme.metalDark, lineWidth: 1)
                )
            }
            .padding(.top, 6)
        }
        .padding(.bottom, 4)
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
                    .foregroundStyle(GearTheme.accent)
                Spacer()
                LedToggle(param: enabled)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(GearTheme.accent.opacity(0.5))
                    .frame(height: 1)
                    .padding(.trailing, 42)
            }

            if enabled.boolValue {
                content()
            }
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
