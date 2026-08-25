import Foundation
import AVFoundation
import CoreAudioKit
import AudioToolbox
import SwiftUI
import os
@preconcurrency import AVFAudio

private let log = Logger(subsystem: "com.gerov.jjbreeze", category: "PlayEngine")

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
    private(set) var lastError: String?
    var source: Source = .loop

    private let graphFormat = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!

    public init() {
        demoBuffer = Self.makeDemoBuffer(sampleRate: graphFormat.sampleRate)
    }

    func initComponent(type: String, subType: String, manufacturer: String) async -> ViewController? {
        reset()
        configureSession(for: .loop)

        // Do not instantiate aufx/Jjbz/Grov here. That is the AUv3 appex; loading your
        // own extension from the containing app fails on device even when GarageBand works.
        // The standalone player uses a private in-process subclass instead.
        var local = AudioComponentDescription()
        local.componentType = kAudioUnitType_Effect
        local.componentSubType = "JjbH".fourCharCode ?? 0
        local.componentManufacturer = "Grov".fourCharCode ?? 0
        local.componentFlags = 0
        local.componentFlagsMask = 0

        AUAudioUnit.registerSubclass(
            JJBreezeAudioUnit.self,
            as: local,
            name: "jj-breeze standalone",
            version: 1
        )

        do {
            let audioUnit = try await AVAudioUnit.instantiate(with: local, options: [])
            return finishLoadInProcess(audioUnit)
        } catch {
            lastError = "Could not start the built-in effect: \(error.localizedDescription)"
            log.error("Standalone AU failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private func finishLoadInProcess(_ audioUnit: AVAudioUnit) -> ViewController? {
        guard let breeze = audioUnit.auAudioUnit as? JJBreezeAudioUnit else {
            lastError = "Built-in effect did not load in-process."
            return nil
        }
        avAudioUnit = audioUnit
        lastError = nil
        if breeze.parameterTree == nil {
            breeze.setupParameterTree(JJBreezeParameterSpecs.createAUParameterTree())
        }
        guard let tree = breeze.observableParameterTree else {
            lastError = "Effect parameters failed to load."
            return nil
        }
        let host = HostingController(rootView: JJBreezeMainView(parameterTree: tree, audioUnit: breeze))
        host.view.backgroundColor = .black
        return host
    }

    func startPlaying() async {
        lastError = nil
        guard let avAudioUnit else {
            lastError = "The effect is not loaded yet."
            return
        }
        guard !isPlaying else { return }

        if source == .microphone {
            let granted = await AVAudioApplication.requestRecordPermission()
            guard granted else {
                lastError = "Microphone access is off. Use Demo, or allow the mic in Settings."
                return
            }
        }

        guard let engine = makeEngine() else {
            lastError = lastError ?? "Could not start the audio engine."
            return
        }
        guard wireGraph(engine: engine, avAudioUnit: avAudioUnit) else {
            lastError = lastError ?? "Could not connect the effect to audio."
            teardownEngine()
            return
        }
        guard startEngine(engine) else { return }

        switch source {
        case .loop:
            player.stop()
            if let demoBuffer {
                await player.scheduleBuffer(demoBuffer, at: nil, options: .loops)
            } else {
                lastError = "Demo audio is missing."
                teardownEngine()
                return
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
        if isPlaying { teardownEngine() }
        source = newSource
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
                lastError = "Microphone is not ready. Unplug accessories and try again."
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
            lastError = "Audio engine failed: \(exception.localizedDescription)"
            log.error("AVAudioEngine exception: \(exception.localizedDescription, privacy: .public)")
            teardownEngine()
            return false
        }
        if let startError {
            lastError = "Audio engine failed: \(startError.localizedDescription)"
            log.error("AVAudioEngine start failed: \(startError.localizedDescription, privacy: .public)")
            teardownEngine()
            return false
        }
        if !ok || !engine.isRunning {
            lastError = "Audio engine did not start. Check the silent switch and volume."
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
            lastError = "Audio session failed: \(error.localizedDescription)"
            log.error("Audio session failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Short plucked notes so width, delay, vibrato and warmth are obvious.
    private static func makeDemoBuffer(sampleRate: Double) -> AVAudioPCMBuffer? {
        let seconds = 8.0
        let frames = AVAudioFrameCount(seconds * sampleRate)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let left = buffer.floatChannelData?[0],
              let right = buffer.floatChannelData?[1]
        else { return nil }

        buffer.frameLength = frames
        let notes = [220.0, 277.2, 329.6, 246.9, 220.0, 196.0, 220.0, 329.6]
        let noteLength = sampleRate * (seconds / Double(notes.count))

        for i in 0..<Int(frames) {
            let noteIndex = min(notes.count - 1, Int(Double(i) / noteLength))
            let tNote = Double(i) - Double(noteIndex) * noteLength
            let freq = notes[noteIndex]
            let env = Float(exp(-tNote / sampleRate * 3.2))
            let pluck = Float(tNote < sampleRate * 0.004 ? (1.0 - tNote / (sampleRate * 0.004)) * 0.15 : 0)
            let tone = sin(2 * Double.pi * freq * (Double(i) / sampleRate)) * 0.55
                + sin(2 * Double.pi * freq * 2 * (Double(i) / sampleRate)) * 0.18
                + sin(2 * Double.pi * freq * 3 * (Double(i) / sampleRate)) * 0.07
            let sample = (Float(tone) + pluck) * env * 0.85
            left[i] = sample
            right[i] = (Float(sin(2 * Double.pi * (freq * 1.003) * (Double(i) / sampleRate))) * 0.55
                        + Float(sin(2 * Double.pi * freq * 2.01 * (Double(i) / sampleRate))) * 0.18)
                * env * 0.85 + pluck * env
        }
        return buffer
    }
}
