import AVFoundation
import AudioToolbox
import CoreAudioKit

public class JJBreezeAudioUnit: AUAudioUnit, @unchecked Sendable {
    var kernel = JJBreezeDSPKernel()
    var processHelper: AUProcessHelper?
    var inputBus = BufferedInputBus()

    private var outputBus: AUAudioUnitBus?
    private var _inputBusses: AUAudioUnitBusArray!
    private var _outputBusses: AUAudioUnitBusArray!
    private var _currentPreset: AUAudioUnitPreset?
    private let presetList: [AUAudioUnitPreset] = FactoryPresets.all.map(\.auPreset)

    @objc override init(componentDescription: AudioComponentDescription, options: AudioComponentInstantiationOptions) throws {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
        try super.init(componentDescription: componentDescription, options: options)

        outputBus = try AUAudioUnitBus(format: format)
        outputBus?.maximumChannelCount = 2

        inputBus.initialize(format, 2)

        _inputBusses = AUAudioUnitBusArray(audioUnit: self, busType: .input, busses: [inputBus.bus!])
        _outputBusses = AUAudioUnitBusArray(audioUnit: self, busType: .output, busses: [outputBus!])

        processHelper = AUProcessHelper(&kernel, &inputBus)
    }

    public override var inputBusses: AUAudioUnitBusArray { _inputBusses }
    public override var outputBusses: AUAudioUnitBusArray { _outputBusses }

    public override var channelCapabilities: [NSNumber] {
        [NSNumber(value: 2), NSNumber(value: 2)]
    }

    public override var canProcessInPlace: Bool { true }

    public override var latency: TimeInterval { 0.070 }
    public override var tailTime: TimeInterval { 0.35 }

    public override var maximumFramesToRender: AUAudioFrameCount {
        get { kernel.maximumFramesToRender() }
        set { kernel.setMaximumFramesToRender(newValue) }
    }

    public override var shouldBypassEffect: Bool {
        get { kernel.isBypassed() }
        set { kernel.setBypass(newValue) }
    }

    public override var internalRenderBlock: AUInternalRenderBlock {
        processHelper!.internalRenderBlock()
    }

    public override func allocateRenderResources() throws {
        let inputChannelCount = self.inputBusses[0].format.channelCount
        let outputChannelCount = self.outputBusses[0].format.channelCount

        if outputChannelCount != inputChannelCount {
            setRenderResourcesAllocated(false)
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioUnitErr_FailedInitialization), userInfo: nil)
        }

        inputBus.allocateRenderResources(self.maximumFramesToRender)
        kernel.setMusicalContextBlock(self.musicalContextBlock)
        kernel.initialize(Int32(inputChannelCount), Int32(outputChannelCount), outputBus!.format.sampleRate)
        processHelper?.setChannelCount(inputChannelCount, outputChannelCount)
        try super.allocateRenderResources()
    }

    public override func deallocateRenderResources() {
        kernel.deInitialize()
        super.deallocateRenderResources()
    }

    public override func supportedViewConfigurations(_ availableViewConfigurations: [AUAudioUnitViewConfiguration]) -> IndexSet {
        IndexSet(availableViewConfigurations.indices)
    }

    public override var factoryPresets: [AUAudioUnitPreset]? { presetList }

    public override var supportsUserPresets: Bool { true }

    public override var currentPreset: AUAudioUnitPreset? {
        get { _currentPreset }
        set {
            guard let preset = newValue else {
                _currentPreset = nil
                return
            }
            if preset.number >= 0 {
                applyFactoryPreset(preset.number)
            }
            _currentPreset = preset
        }
    }

    public func setupParameterTree(_ parameterTree: AUParameterTree) {
        self.parameterTree = parameterTree
        for param in parameterTree.allParameters {
            kernel.setParameter(param.address, param.value)
        }
        setupParameterCallbacks()
        currentPreset = presetList.first
    }

    func applyFactoryPreset(_ index: Int) {
        guard index >= 0, index < FactoryPresets.all.count, let tree = parameterTree else { return }
        let preset = FactoryPresets.all[index]
        func set(_ address: JJBreezeParameterAddress, _ value: AUValue) {
            tree.parameter(withAddress: address.rawValue)?.value = value
        }
        set(.pitchL, preset.pitchL)
        set(.pitchR, preset.pitchR)
        set(.delayL, preset.delayL)
        set(.delayR, preset.delayR)
        set(.focus, preset.focus)
        set(.mix, preset.mix)
        set(.vibratoRate, preset.vibratoRate)
        set(.vibratoDepth, preset.vibratoDepth)
        set(.vibratoMix, preset.vibratoMix)
        set(.warmthTone, preset.warmthTone)
        set(.warmthDrive, preset.warmthDrive)
        set(.warmthBody, preset.warmthBody)
        set(.warmthMix, preset.warmthMix)
        set(.shiftOn, preset.shiftOn ? 1 : 0)
        set(.vibratoOn, preset.vibratoOn ? 1 : 0)
        set(.warmthOn, preset.warmthOn ? 1 : 0)
    }

    private func setupParameterCallbacks() {
        parameterTree?.implementorValueObserver = { [weak self] param, value in
            self?.kernel.setParameter(param.address, value)
        }

        parameterTree?.implementorValueProvider = { [weak self] param in
            self?.kernel.getParameter(param.address) ?? 0
        }

        parameterTree?.implementorStringFromValueCallback = { param, valuePtr in
            let value = valuePtr?.pointee ?? param.value
            return JJBreezeAudioUnit.format(address: param.address, value: value)
        }
    }

    static func format(address: AUParameterAddress, value: AUValue) -> String {
        switch JJBreezeParameterAddress(rawValue: address) {
        case .pitchL, .pitchR:
            return String(format: "%.1f ct", value)
        case .delayL, .delayR, .vibratoDepth:
            return String(format: "%.1f ms", value)
        case .focus, .warmthTone:
            return String(format: "%.0f Hz", value)
        case .mix, .vibratoMix, .warmthDrive, .warmthBody, .warmthMix:
            return String(format: "%.0f %%", value)
        case .vibratoRate:
            return String(format: "%.2f Hz", value)
        case .shiftOn, .vibratoOn, .warmthOn:
            return value >= 0.5 ? "On" : "Off"
        default:
            return String(format: "%.2f", value)
        }
    }
}
