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
                      pitchL: 300, pitchR: 300, delayL: 15, delayR: 15, focus: 150, mix: 50,
                      vibratoRate: 1.2, vibratoDepth: 3.0, vibratoMix: 0,
                      warmthTone: 3500, warmthDrive: 20, warmthBody: 0, warmthMix: 0,
                      shiftOn: true, vibratoOn: false, warmthOn: false),
        FactoryPreset(number: 1, name: "JJ Cale Vocal",
                      pitchL: 4, pitchR: -4, delayL: 8, delayR: 10, focus: 300, mix: 18,
                      vibratoRate: 1.2, vibratoDepth: 3.0, vibratoMix: 0,
                      warmthTone: 3500, warmthDrive: 20, warmthBody: 0, warmthMix: 0,
                      shiftOn: true, vibratoOn: false, warmthOn: false),
        FactoryPreset(number: 2, name: "Cajun Moon Vocal",
                      pitchL: 0, pitchR: 0, delayL: 15, delayR: 15, focus: 150, mix: 0,
                      vibratoRate: 1.1, vibratoDepth: 3.5, vibratoMix: 15,
                      warmthTone: 2800, warmthDrive: 25, warmthBody: 0, warmthMix: 70,
                      shiftOn: false, vibratoOn: true, warmthOn: true),
        FactoryPreset(number: 3, name: "JJ Dark Vocal",
                      pitchL: -300, pitchR: -300, delayL: 15, delayR: 15, focus: 25, mix: 100,
                      vibratoRate: 1.1, vibratoDepth: 3.5, vibratoMix: 15,
                      warmthTone: 2800, warmthDrive: 25, warmthBody: 70, warmthMix: 70,
                      shiftOn: true, vibratoOn: true, warmthOn: true),
        FactoryPreset(number: 4, name: "JJ Dark Vocal (Up)",
                      pitchL: 300, pitchR: 300, delayL: 15, delayR: 15, focus: 25, mix: 100,
                      vibratoRate: 1.1, vibratoDepth: 3.5, vibratoMix: 15,
                      warmthTone: 2800, warmthDrive: 25, warmthBody: 0, warmthMix: 70,
                      shiftOn: true, vibratoOn: true, warmthOn: true),
        FactoryPreset(number: 5, name: "Octave Width",
                      pitchL: -1200, pitchR: 0, delayL: 15, delayR: 15, focus: 25, mix: 55,
                      vibratoRate: 1.2, vibratoDepth: 3.0, vibratoMix: 0,
                      warmthTone: 3500, warmthDrive: 20, warmthBody: 0, warmthMix: 0,
                      shiftOn: true, vibratoOn: false, warmthOn: false),
        FactoryPreset(number: 6, name: "Deep Baritone",
                      pitchL: -700, pitchR: -700, delayL: 15, delayR: 15, focus: 25, mix: 100,
                      vibratoRate: 1.1, vibratoDepth: 3.5, vibratoMix: 0,
                      warmthTone: 2500, warmthDrive: 35, warmthBody: 85, warmthMix: 80,
                      shiftOn: true, vibratoOn: false, warmthOn: true)
    ]
}
