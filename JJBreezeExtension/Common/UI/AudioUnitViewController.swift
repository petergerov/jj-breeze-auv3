import Combine
import CoreAudioKit
import os
import SwiftUI

private let log = Logger(subsystem: "com.gerov.jjbreeze.AUv3", category: "AudioUnitViewController")

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

    nonisolated public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        try DispatchQueue.main.sync {
            audioUnit = try JJBreezeAudioUnit(componentDescription: componentDescription, options: [])

            guard let audioUnit = self.audioUnit as? JJBreezeAudioUnit else {
                log.error("Unable to create JJBreezeAudioUnit")
                return audioUnit!
            }

            defer {
                DispatchQueue.main.async {
                    self.configureSwiftUIView(audioUnit: audioUnit)
                }
            }

            audioUnit.setupParameterTree(JJBreezeParameterSpecs.createAUParameterTree())

            self.observation = audioUnit.observe(\.allParameterValues, options: [.new]) { object, change in
                guard let tree = audioUnit.parameterTree else { return }
                for param in tree.allParameters { param.value = param.value }
            }

            guard audioUnit.parameterTree != nil else {
                log.error("Unable to access AU ParameterTree")
                return audioUnit
            }

            return audioUnit
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
