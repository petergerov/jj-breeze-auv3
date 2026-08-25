import Foundation
import AVFoundation
import CoreAudioKit
import os
@preconcurrency import AVFAudio

private let log = Logger(subsystem: "com.gerov.jjbreeze", category: "PlayEngine")

extension AVAudioUnit {
    @MainActor
    func loadAudioUnitViewController() async -> ViewController? {
        let unit = auAudioUnit
        let viewController = await unit.requestViewController()
        if viewController == nil {
            let genericViewController = AUGenericViewController()
            genericViewController.auAudioUnit = unit
            return genericViewController
        }
        return viewController
    }
}

@MainActor
@Observable
public class SimplePlayEngine {
    enum Source: String, CaseIterable, Identifiable {
        case loop = "Demo Loop"
        case microphone = "Microphone"
        var id: String { rawValue }
    }

    private(set) var avAudioUnit: AVAudioUnit?
    /// Created only when the user hits Play, after the audio session is active.
    private var engine: AVAudioEngine?
    private let player = AVAudioPlayerNode()
    private var demoBuffer: AVAudioPCMBuffer?
    private(set) var isPlaying = false
    var source: Source = .loop

    private let graphFormat = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!

    public init() {
        demoBuffer = Self.makeDemoBuffer(sampleRate: graphFormat.sampleRate)
    }

    func initComponent(type: String, subType: String, manufacturer: String) async -> ViewController? {
        reset()
        configureSession(for: .loop)

        let description = AudioComponentDescription(
            componentType: type.fourCharCode ?? kAudioUnitType_Effect,
            componentSubType: subType.fourCharCode ?? 0,
            componentManufacturer: manufacturer.fourCharCode ?? 0,
            componentFlags: 0,
            componentFlagsMask: 0
        )

        do {
            let audioUnit = try await AVAudioUnit.instantiate(with: description, options: .loadOutOfProcess)
            self.avAudioUnit = audioUnit
            return await audioUnit.loadAudioUnitViewController()
        } catch {
            log.error("AU instantiate failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    func startPlaying() async {
        guard let avAudioUnit, !isPlaying else { return }

        if source == .microphone {
            let granted = await AVAudioApplication.requestRecordPermission()
            guard granted else {
                log.error("Microphone permission denied")
                return
            }
        }

        guard let engine = makeEngine() else { return }
        guard wireGraph(engine: engine, avAudioUnit: avAudioUnit) else { return }
        guard startEngine(engine) else { return }

        switch source {
        case .loop:
            player.stop()
            if let demoBuffer {
                await player.scheduleBuffer(demoBuffer, at: nil, options: .loops)
            }
            player.play()
        case .microphone:
            break
        }
        isPlaying = true
    }

    func stopPlaying() {
        guard isPlaying else { return }
        teardownEngine()
    }

    func setSource(_ newSource: Source) {
        let wasPlaying = isPlaying
        if wasPlaying { teardownEngine() }
        source = newSource
        if wasPlaying {
            Task { await startPlaying() }
        }
    }

    func reset() {
        teardownEngine()
        avAudioUnit = nil
    }

    /// Session first, then force-create `outputNode` before mixer/attach/prepare.
    private func makeEngine() -> AVAudioEngine? {
        teardownEngine()
        configureSession(for: source)

        let engine = AVAudioEngine()
        // Accessing outputNode creates the hardware I/O unit. mainMixerNode / prepare()
        // will assert if this is skipped (AVAudioEngineGraph Initialize).
        _ = engine.outputNode
        self.engine = engine
        return engine
    }

    private func wireGraph(engine: AVAudioEngine, avAudioUnit: AVAudioUnit) -> Bool {
        let output = engine.outputNode
        let mixer = engine.mainMixerNode

        if !engine.attachedNodes.contains(player) {
            engine.attach(player)
        }
        if !engine.attachedNodes.contains(avAudioUnit) {
            engine.attach(avAudioUnit)
        }

        engine.disconnectNodeInput(mixer)
        engine.disconnectNodeOutput(player)
        engine.disconnectNodeOutput(avAudioUnit)

        let hw = output.outputFormat(forBus: 0)
        let ioFormat: AVAudioFormat
        if hw.sampleRate > 0, hw.channelCount > 0 {
            ioFormat = hw
        } else {
            ioFormat = graphFormat
        }

        switch source {
        case .loop:
            engine.connect(player, to: avAudioUnit, format: graphFormat)
            engine.connect(avAudioUnit, to: mixer, format: graphFormat)
            engine.connect(mixer, to: output, format: ioFormat)
        case .microphone:
            let input = engine.inputNode
            let inputFormat = input.outputFormat(forBus: 0)
            guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
                log.error("Microphone format is not ready")
                return false
            }
            engine.connect(input, to: avAudioUnit, format: inputFormat)
            engine.connect(avAudioUnit, to: mixer, format: inputFormat)
            engine.connect(mixer, to: output, format: ioFormat)
        }
        return true
    }

    private func startEngine(_ engine: AVAudioEngine) -> Bool {
        var exception: NSError?
        var startError: Error?
        let ok = JJRunCatchingException({
            engine.prepare()
            do {
                try engine.start()
            } catch {
                startError = error
            }
        }, &exception)

        if let exception {
            log.error("AVAudioEngine exception: \(exception.localizedDescription, privacy: .public)")
            teardownEngine()
            return false
        }
        if let startError {
            log.error("AVAudioEngine start failed: \(startError.localizedDescription, privacy: .public)")
            teardownEngine()
            return false
        }
        if !ok || !engine.isRunning {
            log.error("AVAudioEngine did not start")
            teardownEngine()
            return false
        }
        return true
    }

    private func teardownEngine() {
        player.stop()
        if let engine {
            if engine.isRunning {
                engine.stop()
            }
            if engine.attachedNodes.contains(player) {
                engine.disconnectNodeOutput(player)
                engine.detach(player)
            }
            if let avAudioUnit, engine.attachedNodes.contains(avAudioUnit) {
                engine.disconnectNodeOutput(avAudioUnit)
                engine.detach(avAudioUnit)
            }
            engine.reset()
        }
        engine = nil
        isPlaying = false
    }

    private func configureSession(for source: Source) {
        let session = AVAudioSession.sharedInstance()
        do {
            switch source {
            case .loop:
                try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            case .microphone:
                try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            }
            try session.setActive(true)
        } catch {
            log.error("Audio session failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func makeDemoBuffer(sampleRate: Double) -> AVAudioPCMBuffer? {
        let seconds = 4.0
        let frames = AVAudioFrameCount(seconds * sampleRate)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let left = buffer.floatChannelData?[0],
              let right = buffer.floatChannelData?[1]
        else { return nil }

        buffer.frameLength = frames
        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            let env = 0.28 + 0.08 * sin(2 * Double.pi * 0.25 * t)
            let tone = sin(2 * Double.pi * 220 * t) * 0.55
                + sin(2 * Double.pi * 330 * t) * 0.22
                + sin(2 * Double.pi * 440 * t) * 0.10
            left[i] = Float(tone * env)
            right[i] = Float((sin(2 * Double.pi * 220.7 * t) * 0.55
                              + sin(2 * Double.pi * 329.4 * t) * 0.22
                              + sin(2 * Double.pi * 441.2 * t) * 0.10) * env)
        }
        return buffer
    }
}
