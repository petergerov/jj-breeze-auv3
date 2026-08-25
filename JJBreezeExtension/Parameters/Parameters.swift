import Foundation
import AudioToolbox

let JJBreezeParameterSpecs = ParameterTreeSpec {
    ParameterGroupSpec(identifier: "shift", name: "Shift") {
        ParameterSpec(address: .pitchL, identifier: "pitchL", name: "Pitch L",
                      units: .cents, valueRange: -1200.0...1200.0, defaultValue: 300.0, unitName: "ct")
        ParameterSpec(address: .pitchR, identifier: "pitchR", name: "Pitch R",
                      units: .cents, valueRange: -1200.0...1200.0, defaultValue: 300.0, unitName: "ct")
        ParameterSpec(address: .delayL, identifier: "delayL", name: "Delay L",
                      units: .milliseconds, valueRange: 0.0...40.0, defaultValue: 15.0, unitName: "ms")
        ParameterSpec(address: .delayR, identifier: "delayR", name: "Delay R",
                      units: .milliseconds, valueRange: 0.0...40.0, defaultValue: 15.0, unitName: "ms")
        ParameterSpec(address: .focus, identifier: "focus", name: "Focus",
                      units: .hertz, valueRange: 20.0...10_000.0, defaultValue: 150.0, unitName: "Hz")
        ParameterSpec(address: .mix, identifier: "mix", name: "Mix",
                      units: .percent, valueRange: 0.0...100.0, defaultValue: 50.0, unitName: "%")
        ParameterSpec(address: .shiftOn, identifier: "shiftOn", name: "Shift On",
                      units: .boolean, valueRange: 0.0...1.0, defaultValue: 1.0)
    }
    ParameterGroupSpec(identifier: "vibrato", name: "Vibrato") {
        ParameterSpec(address: .vibratoRate, identifier: "vibratoRate", name: "Vibrato Rate",
                      units: .hertz, valueRange: 0.1...8.0, defaultValue: 1.2, unitName: "Hz")
        ParameterSpec(address: .vibratoDepth, identifier: "vibratoDepth", name: "Vibrato Depth",
                      units: .milliseconds, valueRange: 0.0...8.0, defaultValue: 3.0, unitName: "ms")
        ParameterSpec(address: .vibratoMix, identifier: "vibratoMix", name: "Vibrato Mix",
                      units: .percent, valueRange: 0.0...100.0, defaultValue: 0.0, unitName: "%")
        ParameterSpec(address: .vibratoOn, identifier: "vibratoOn", name: "Vibrato On",
                      units: .boolean, valueRange: 0.0...1.0, defaultValue: 0.0)
    }
    ParameterGroupSpec(identifier: "warmth", name: "Warmth") {
        ParameterSpec(address: .warmthTone, identifier: "warmthTone", name: "Warmth Tone",
                      units: .hertz, valueRange: 500.0...12_000.0, defaultValue: 3500.0, unitName: "Hz")
        ParameterSpec(address: .warmthDrive, identifier: "warmthDrive", name: "Warmth Drive",
                      units: .percent, valueRange: 0.0...100.0, defaultValue: 20.0, unitName: "%")
        ParameterSpec(address: .warmthBody, identifier: "warmthBody", name: "Warmth Body",
                      units: .percent, valueRange: 0.0...100.0, defaultValue: 0.0, unitName: "%")
        ParameterSpec(address: .warmthMix, identifier: "warmthMix", name: "Warmth Mix",
                      units: .percent, valueRange: 0.0...100.0, defaultValue: 0.0, unitName: "%")
        ParameterSpec(address: .warmthOn, identifier: "warmthOn", name: "Warmth On",
                      units: .boolean, valueRange: 0.0...1.0, defaultValue: 0.0)
    }
}

extension ParameterSpec {
    init(
        address: JJBreezeParameterAddress,
        identifier: String,
        name: String,
        units: AudioUnitParameterUnit,
        valueRange: ClosedRange<AUValue>,
        defaultValue: AUValue,
        unitName: String? = nil,
        flags: AudioUnitParameterOptions = [.flag_IsWritable, .flag_IsReadable],
        valueStrings: [String]? = nil,
        dependentParameters: [NSNumber]? = nil
    ) {
        var resolvedFlags = flags
        if units != .boolean {
            resolvedFlags.insert(.flag_CanRamp)
        }
        self.init(
            address: address.rawValue,
            identifier: identifier,
            name: name,
            units: units,
            valueRange: valueRange,
            defaultValue: defaultValue,
            unitName: unitName,
            flags: resolvedFlags,
            valueStrings: valueStrings,
            dependentParameters: dependentParameters
        )
    }
}

enum AudioUnitIdentity {
    static let type = "aufx"
    static let subtype = "Jjbz"
    static let manufacturer = "Grov"
    static let componentName = "Gerov: jj-breeze"
}
