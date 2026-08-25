import Combine
import CoreAudioKit
import os
import SwiftUI

private let log = Logger(subsystem: "com.gerov.jjbreeze.AUv3", category: "AudioUnitViewController")

@objc(AudioUnitViewController)
@MainActor
public class AudioUnitViewController: AUViewController, AUAudioUnitFactory {
    var audioUnit: AUAudioUnit?
    var hostingController: HostingController<JJBreezeMainView>?
    private var observation: NSKeyValueObservation?

    public override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSize(width: 480, height: 760)
        guard let audioUnit else { return }
        configureSwiftUIView(audioUnit: audioUnit)
    }

    /// Must not `DispatchQueue.main.sync` when already on the main thread — that deadlocks
    /// the extension process and the host reports "Audio Unit failed to load".
    nonisolated public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        let unit = try JJBreezeAudioUnit(componentDescription: componentDescription, options: [])
        unit.setupParameterTree(JJBreezeParameterSpecs.createAUParameterTree())

        let attach = {
            MainActor.assumeIsolated {
                self.attach(unit)
            }
        }
        if Thread.isMainThread {
            attach()
        } else {
            DispatchQueue.main.sync(execute: attach)
        }
        return unit
    }

    private func attach(_ unit: JJBreezeAudioUnit) {
        audioUnit = unit
        observation = unit.observe(\.allParameterValues, options: [.new]) { _, _ in
            guard let tree = unit.parameterTree else { return }
            for param in tree.allParameters { param.value = param.value }
        }
        if isViewLoaded {
            configureSwiftUIView(audioUnit: unit)
        }
    }

    private func configureSwiftUIView(audioUnit: AUAudioUnit) {
        if let host = hostingController {
            host.removeFromParent()
            host.view.removeFromSuperview()
        }

        guard let observableParameterTree = audioUnit.observableParameterTree else { return }
        let breezeAU = audioUnit as? JJBreezeAudioUnit
        let content = JJBreezeMainView(parameterTree: observableParameterTree, audioUnit: breezeAU)
        let host = HostingController(rootView: content)
        self.addChild(host)
        host.view.frame = self.view.bounds
        self.view.addSubview(host.view)
        hostingController = host

        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            host.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        self.view.bringSubviewToFront(host.view)
    }
}
