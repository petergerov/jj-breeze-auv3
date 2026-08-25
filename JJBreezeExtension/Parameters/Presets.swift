import Foundation
import AudioToolbox

struct FactoryPreset: Sendable {
    let number: Int
    let name: String
    let pitchL: AUValue
    let pitchR: AUValue
    let delayL: AUValue
    let delayR: AUValue
    let focus: AUValue
    let mix: AUValue
    let vibratoRate: AUValue
    let vibratoDepth: AUValue
    let vibratoMix: AUValue
    let warmthTone: AUValue
    let warmthDrive: AUValue
    let warmthBody: AUValue
    let warmthMix: AUValue
    let shiftOn: Bool
    let vibratoOn: Bool
    let warmthOn: Bool

    var auPreset: AUAudioUnitPreset {
        let preset = AUAudioUnitPreset()
        preset.number = number
        preset.name = name
        return preset
    }
}

enum FactoryPresets {
    static let all: [FactoryPreset] = [
        FactoryPreset(number: 0, name: "Default",
                      pitchL: 300, pitchR: 300, delayL: 27, delayR: 37, focus: 20, mix: 13,
                      vibratoRate: 1.2, vibratoDepth: 3.0, vibratoMix: 15,
                      warmthTone: 3500, warmthDrive: 20, warmthBody: 0, warmthMix: 20,
                      shiftOn: true, vibratoOn: true, warmthOn: true),
        FactoryPreset(number: 1, name: "Stereo Width",
                      pitchL: 300, pitchR: -300, delayL: 23, delayR: 37, focus: 20, mix: 18,
                      vibratoRate: 1.2, vibratoDepth: 2.5, vibratoMix: 10,
                      warmthTone: 3500, warmthDrive: 18, warmthBody: 0, warmthMix: 15,
                      shiftOn: true, vibratoOn: true, warmthOn: true),
        FactoryPreset(number: 2, name: "JJ Cale Cajun Moon Vocal",
                      pitchL: 300, pitchR: 300, delayL: 27, delayR: 37, focus: 20, mix: 13,
                      vibratoRate: 1.2, vibratoDepth: 3.0, vibratoMix: 15,
                      warmthTone: 3500, warmthDrive: 20, warmthBody: 0, warmthMix: 20,
                      shiftOn: true, vibratoOn: true, warmthOn: true),
        FactoryPreset(number: 3, name: "JJ Dark Vocal",
                      pitchL: -300, pitchR: -300, delayL: 17, delayR: 27, focus: 25, mix: 15,
                      vibratoRate: 1.1, vibratoDepth: 3.5, vibratoMix: 15,
                      warmthTone: 2800, warmthDrive: 25, warmthBody: 0, warmthMix: 20,
                      shiftOn: true, vibratoOn: true, warmthOn: true),
        FactoryPreset(number: 5, name: "Octave Width",
                      pitchL: -1200, pitchR: 0, delayL: 15, delayR: 30, focus: 25, mix: 20,
                      vibratoRate: 1.2, vibratoDepth: 3.0, vibratoMix: 0,
                      warmthTone: 3500, warmthDrive: 20, warmthBody: 0, warmthMix: 0,
                      shiftOn: true, vibratoOn: false, warmthOn: false),
        FactoryPreset(number: 6, name: "Deep Baritone",
                      pitchL: -700, pitchR: -700, delayL: 15, delayR: 15, focus: 25, mix: 20,
                      vibratoRate: 1.1, vibratoDepth: 3.5, vibratoMix: 0,
                      warmthTone: 2500, warmthDrive: 35, warmthBody: 10, warmthMix: 20,
                      shiftOn: true, vibratoOn: false, warmthOn: true)
    ]
}

enum JJBreezePresetError: LocalizedError {
    case emptyName
    case persistFailed
    case notFound

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Enter a preset name."
        case .persistFailed:
            return "Could not save the preset on this device."
        case .notFound:
            return "That preset is no longer on this device."
        }
    }
}
