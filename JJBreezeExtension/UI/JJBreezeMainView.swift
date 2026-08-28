import SwiftUI

struct JJBreezeMainView: View {
    var parameterTree: ObservableAUParameterGroup
    var audioUnit: JJBreezeAudioUnit?

    @State private var linkPitch = false
    @State private var linkDelay = false
    @State private var isBypassed = false
    @State private var showPaywall = false
    @Bindable private var entitlement = EntitlementService.shared

    // Rack-panel geometry — matches the desktop design's headerHeight/
    // earWidth/footerStripHeight constants, scaled down for a
    // host-embedded extension view.
    private let earWidth: CGFloat = 18
    private let footerHeight: CGFloat = 12
    private let contentGutter: CGFloat = 12
    // Below this width the three columns don't have room to sit side by
    // side without crushing the knobs — fall back to stacking them, same
    // content, just a different arrangement.
    private let wideThreshold: CGFloat = 640

    var body: some View {
        GeometryReader { geo in
            let sideInset = earWidth + contentGutter

            ZStack(alignment: .bottom) {
                ChassisBackground()

                HStack(spacing: 0) {
                    RackEar().frame(width: earWidth)
                    Spacer(minLength: 0)
                    RackEar().frame(width: earWidth)
                }

                ScrollView(.vertical, showsIndicators: false) {
                    // Spacers above/below the panel content, plus a
                    // minHeight matching the full container: when the host
                    // gives more height than the panel needs, this centres
                    // it in the chassis rather than pinning it to the top
                    // and leaving a dead expanse of chassis below; when the
                    // host is short, the spacers collapse and it scrolls.
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        panelContent(width: geo.size.width)
                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: geo.size.height)
                }
                .frame(width: geo.size.width, height: geo.size.height)

                FooterRivetStrip()
                    .frame(width: geo.size.width, height: footerHeight)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear {
            isBypassed = audioUnit?.shouldBypassEffect ?? false
            Task {
                await entitlement.refresh()
                audioUnit?.applyLicenseFromStore()
            }
        }
        .onChange(of: isBypassed) { _, newValue in
            audioUnit?.shouldBypassEffect = newValue
        }
        .onReceive(NotificationCenter.default.publisher(for: .jjBreezeAccessChanged)) { _ in
            audioUnit?.applyLicenseFromStore()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(entitlement: entitlement, showsCloseWhenAllowed: true) {
                showPaywall = false
            }
            .presentationDetents([.large])
        }
    }

    // The panel's actual content — header, divider, sections, footer — at
    // its natural size for a given width, with no outer chassis/scrolling
    // wrapper. `body` embeds this inside the always-fills GeometryReader/
    // ScrollView above; `AudioUnitViewController` also hosts it standalone
    // to *measure* the height a host should be asked for via
    // `preferredContentSize`, so that initial request reflects this view's
    // real layout instead of a hand-tuned guess that drifts out of sync
    // with it.
    func panelContent(width: CGFloat) -> some View {
        let sideInset = earWidth + contentGutter
        return VStack(spacing: 0) {
            header
                .padding(.horizontal, sideInset)
                .padding(.top, 10)
                .padding(.bottom, 8)

            Rectangle()
                .fill(GearTheme.textLight.opacity(0.14))
                .frame(height: 1)
                .padding(.horizontal, sideInset)

            sectionsLayout(isWide: width >= wideThreshold)
                .padding(.horizontal, sideInset)
                .padding(.top, 12)
                .padding(.bottom, 8)

            versionFooter
                .padding(.horizontal, sideInset)
                .padding(.bottom, footerHeight + 6)
        }
        .frame(width: width)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("j.j.breeze")
                        .font(.custom("Georgia-BoldItalic", size: 20))
                        .foregroundStyle(GearTheme.textLight)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("STEREO MICRO-PITCH WIDENER")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(GearTheme.textMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }

                Spacer(minLength: 8)

                LevelMeterView(audioUnit: audioUnit)

                HStack(spacing: 6) {
                    Text("POWER")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(GearTheme.accent)
                    BypassToggle(isBypassed: $isBypassed)
                        .frame(width: 22, height: 38)
                }
            }

            PresetBar(audioUnit: audioUnit)

            if entitlement.accessState.bannerText != nil {
                AccessBanner(state: entitlement.accessState) {
                    showPaywall = true
                }
            }
        }
    }

    private var versionFooter: some View {
        Text(appVersionString)
            .font(.system(size: 9))
            .foregroundStyle(GearTheme.textMuted.opacity(0.55))
            .frame(maxWidth: .infinity)
    }

    private var appVersionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "v\(v)"
    }

    // MARK: - Sections (Shift / Vibrato / Warmth)

    private let columnSpacing: CGFloat = 20

    @ViewBuilder
    private func sectionsLayout(isWide: Bool) -> some View {
        if isWide {
            HStack(alignment: .top, spacing: columnSpacing) {
                shiftColumn
                vibratoColumn
                warmthColumn
            }
            // Drawn as an overlay, not as flexible-height siblings in the
            // HStack above — a plain Rectangle divider with no height of
            // its own is an unconstrained child that would otherwise make
            // the whole row report as flexible to its ancestors (stretching
            // to fill the scroll view instead of hugging its content). An
            // overlay is sized to the HStack's own resolved size without
            // feeding back into it, so it can't cause that.
            .overlay(alignment: .topLeading) {
                GeometryReader { g in
                    let colWidth = (g.size.width - columnSpacing * 2) / 3
                    Path { p in
                        for i in 1...2 {
                            let x = CGFloat(i) * colWidth + (CGFloat(i) - 0.5) * columnSpacing
                            p.move(to: CGPoint(x: x, y: 0))
                            p.addLine(to: CGPoint(x: x, y: g.size.height))
                        }
                    }
                    .stroke(GearTheme.textLight.opacity(0.14), lineWidth: 1)
                }
                .allowsHitTesting(false)
            }
        } else {
            VStack(spacing: 18) {
                shiftColumn
                vibratoColumn
                warmthColumn
            }
        }
    }

    private func sectionHeader(_ title: String, enabled: ObservableAUParameter) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(enabled.boolValue ? GearTheme.accent : GearTheme.textMuted)
            Spacer()
            LedToggle(param: enabled)
                .frame(width: 24, height: 40)
        }
    }

    // Shared by knob rows that need a link badge positioned between their
    // first two knobs — see linkBadge(isOn:title:) below.
    private let knobRowSpacing: CGFloat = 8

    private func knob(_ param: ObservableAUParameter, _ caption: String, skew: Float = 1,
                       symmetric: Bool = false, help: String? = nil,
                       peer: ObservableAUParameter? = nil, linked: Bool = false) -> some View {
        KnobView(param: param, caption: caption, skew: skew, symmetric: symmetric,
                 helpText: help, linkedPeer: peer, linkEnabled: linked)
            .frame(maxWidth: .infinity)
    }

    // Vertical distance from a knob row's top to the top edge of the knob
    // circles themselves — matches KnobView's caption (.frame(minHeight: 16))
    // plus its VStack's 6pt spacing before the knob. Keeps the link badge
    // aligned with the knobs' top edge rather than the row's own centre
    // (which sits lower, pulled down by the value chip below the knob).
    private let knobTopOffset: CGFloat = 30

    // Positions a LinkIconBadge in the gap between a row's first two knobs
    // (e.g. PITCH L/PITCH R) — an overlay rather than a real HStack sibling,
    // so it doesn't disturb the three knobs' otherwise-equal widths, and
    // (like the column dividers) can't leak flexible sizing into the row's
    // own layout the way a plain sibling view would.
    private func linkBadge(isOn: Binding<Bool>, title: String) -> some View {
        GeometryReader { g in
            let columnWidth = (g.size.width - knobRowSpacing * 2) / 3
            LinkIconBadge(isOn: isOn, title: title)
                .position(x: columnWidth + knobRowSpacing / 2, y: knobTopOffset)
        }
    }

    private var shiftColumn: some View {
        // Bound to a concretely-typed local rather than chaining
        // `parameterTree.shift.shiftOn.boolValue` inline — @dynamicMemberLookup
        // here only resolves reliably one hop at a time (see ObservableAUParameter.swift).
        let shiftOn: ObservableAUParameter = parameterTree.shift.shiftOn
        return VStack(alignment: .leading, spacing: 10) {
            sectionHeader("SHIFT", enabled: shiftOn)

            Group {
                HStack(spacing: knobRowSpacing) {
                    knob(parameterTree.shift.pitchL, "PITCH L", skew: 0.4, symmetric: true,
                         peer: parameterTree.shift.pitchR, linked: linkPitch)
                    knob(parameterTree.shift.pitchR, "PITCH R", skew: 0.4, symmetric: true,
                         peer: parameterTree.shift.pitchL, linked: linkPitch)
                    knob(parameterTree.shift.focus, "FOCUS", skew: 0.25,
                         help: "Crossover frequency. Frequencies below this stay dry; highs go through pitch and delay.")
                }
                .overlay { linkBadge(isOn: $linkPitch, title: "Pitch") }
                HStack(spacing: knobRowSpacing) {
                    knob(parameterTree.shift.delayL, "DELAY L", skew: 0.3,
                         help: "Left delay tap, 0–250 ms. Short times add width; around 110 ms is slapback.",
                         peer: parameterTree.shift.delayR, linked: linkDelay)
                    knob(parameterTree.shift.delayR, "DELAY R", skew: 0.3,
                         help: "Right delay tap, 0–250 ms. Short times add width; around 110 ms is slapback.",
                         peer: parameterTree.shift.delayL, linked: linkDelay)
                    knob(parameterTree.shift.mix, "MIX")
                }
                .overlay { linkBadge(isOn: $linkDelay, title: "Delay") }
            }
            .opacity(shiftOn.boolValue ? 1 : 0.42)
            // Blocks all touch input (drag, tap, long-press-for-help) to the
            // knobs and link toggles, not just the Button-based ones — a
            // disabled section shouldn't be editable, and .disabled() alone
            // wouldn't stop KnobView's raw .gesture()-based drag/long-press.
            .allowsHitTesting(shiftOn.boolValue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var vibratoColumn: some View {
        let vibratoOn: ObservableAUParameter = parameterTree.vibrato.vibratoOn
        return VStack(alignment: .leading, spacing: 10) {
            sectionHeader("VIBRATO", enabled: vibratoOn)

            HStack(spacing: 8) {
                knob(parameterTree.vibrato.vibratoRate, "RATE", skew: 0.4)
                knob(parameterTree.vibrato.vibratoDepth, "DEPTH")
                knob(parameterTree.vibrato.vibratoMix, "MIX")
            }
            .opacity(vibratoOn.boolValue ? 1 : 0.42)
            .allowsHitTesting(vibratoOn.boolValue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var warmthColumn: some View {
        let warmthOn: ObservableAUParameter = parameterTree.warmth.warmthOn
        return VStack(alignment: .leading, spacing: 10) {
            sectionHeader("WARMTH", enabled: warmthOn)

            Group {
                HStack(spacing: 8) {
                    knob(parameterTree.warmth.warmthTone, "TONE", skew: 0.3)
                    knob(parameterTree.warmth.warmthDrive, "DRIVE",
                         help: "Saturation amount in the warmth stage.")
                }
                HStack(spacing: 8) {
                    knob(parameterTree.warmth.warmthBody, "BODY",
                         help: "Low-shelf boost in the warmth stage. Adds weight without changing Tone.")
                    knob(parameterTree.warmth.warmthMix, "MIX")
                }
            }
            .opacity(warmthOn.boolValue ? 1 : 0.42)
            .allowsHitTesting(warmthOn.boolValue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
