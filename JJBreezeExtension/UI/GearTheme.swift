import SwiftUI

/// The panel colourway, kept in sync with the JUCE plugin's
/// `GearPalette::Theme` (see ../jj-breeze/Source/PluginEditor.h). That build
/// picks its default via `JJ_BREEZE_DEFAULT_THEME`; this one has no theme
/// switcher, so the default colourway — "Slate": blue-grey chassis, dark
/// gunmetal knob caps, brass accent — is inlined here.
enum GearTheme {
    static let chassisTop = Color(red: 0x51 / 255, green: 0x61 / 255, blue: 0x6a / 255)
    static let chassisBottom = Color(red: 0x2c / 255, green: 0x36 / 255, blue: 0x3c / 255)
    static let panelFill = Color(red: 0x3a / 255, green: 0x46 / 255, blue: 0x4e / 255)
    static let metalLight = Color(red: 0x7d / 255, green: 0x81 / 255, blue: 0x84 / 255)
    static let metalMid = Color(red: 0x5c / 255, green: 0x61 / 255, blue: 0x64 / 255)
    static let metalDark = Color(red: 0x2a / 255, green: 0x2c / 255, blue: 0x2e / 255)
    static let accent = Color(red: 0xc9 / 255, green: 0x97 / 255, blue: 0x4a / 255)
    static let accentDim = Color(red: 0x7a / 255, green: 0x5b / 255, blue: 0x2c / 255)
    static let textLight = Color(red: 0xf2 / 255, green: 0xef / 255, blue: 0xe4 / 255)
    static let textMuted = Color(red: 0xaa / 255, green: 0xb0 / 255, blue: 0xac / 255)
    static let ledBackground = Color(red: 0x1a / 255, green: 0x17 / 255, blue: 0x12 / 255)
    static let ledText = Color(red: 0xe0 / 255, green: 0xb8 / 255, blue: 0x76 / 255)
}
