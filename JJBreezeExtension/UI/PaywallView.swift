import StoreKit
import SwiftUI

struct PaywallView: View {
    @Bindable var entitlement: EntitlementService
    var showsCloseWhenAllowed = false
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)

            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color(red: 0.88, green: 0.54, blue: 0.24))
                .padding(.bottom, 4)

            Text("jj-breeze")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(.white)

            Text("Stereo micro-pitch widener with vibrato and warmth.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            VStack(alignment: .leading, spacing: 10) {
                bullet("7 days full access — free")
                bullet("Then unlock once — no subscription")
                bullet("Works in GarageBand, Logic for iPad, and AUM")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)

            if let message = entitlement.lastError {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 12) {
                if entitlement.accessState == .trialNotStarted {
                    Button {
                        Task { await entitlement.startTrial() }
                    } label: {
                        Text("Start 7-day free trial")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.88, green: 0.54, blue: 0.24))
                    .disabled(entitlement.isPurchasing || entitlement.trialProduct == nil)
                }

                Group {
                    if entitlement.accessState == .trialNotStarted {
                        Button {
                            Task { await entitlement.purchaseUnlock() }
                        } label: {
                            Text("Unlock forever — \(unlockLabel)")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button {
                            Task { await entitlement.purchaseUnlock() }
                        } label: {
                            Text(unlockLabel)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .tint(Color(red: 0.88, green: 0.54, blue: 0.24))
                .disabled(entitlement.isPurchasing || entitlement.unlockProduct == nil)

                Button("Restore purchases") {
                    Task { await entitlement.restorePurchases() }
                }
                .font(.footnote)
                .disabled(entitlement.isPurchasing)
            }
            .padding(.horizontal, 24)

            Text("After the trial, audio passes through dry until you unlock. The editor stays available.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer(minLength: 0)

            if showsCloseWhenAllowed, entitlement.isEffectAllowed, let onDismiss {
                Button("Continue") { onDismiss() }
                    .font(.footnote)
                    .padding(.bottom, 8)
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .task {
            await entitlement.loadProducts()
            await entitlement.refresh()
        }
        .onChange(of: entitlement.isEffectAllowed) { _, allowed in
            if allowed, showsCloseWhenAllowed {
                onDismiss?()
            }
        }
    }

    private var unlockLabel: String {
        entitlement.unlockProduct?.displayPrice ?? "$2.99"
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
    }
}

/// Compact banner for the plugin header when trial is active or expired.
struct AccessBanner: View {
    let state: AccessState
    var onUnlock: () -> Void

    var body: some View {
        if let text = state.bannerText {
            HStack(spacing: 8) {
                Text(text)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(GearTheme.ledText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 4)
                if case .unlocked = state {
                    EmptyView()
                } else {
                    Button(state == .trialNotStarted ? "Start trial" : "Unlock", action: onUnlock)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(GearTheme.accent)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(GearTheme.ledBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(GearTheme.metalDark, lineWidth: 1)
            )
        }
    }
}
