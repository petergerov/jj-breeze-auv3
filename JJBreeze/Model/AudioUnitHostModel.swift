import SwiftUI
import AudioToolbox
import AVFAudio
import UIKit

@MainActor
@Observable
class AudioUnitHostModel {
    private let playEngine = SimplePlayEngine()
    var viewModel = AudioUnitViewModel()
    var isPlaying: Bool { playEngine.isPlaying }
    var source: SimplePlayEngine.Source { playEngine.source }
    var audioUnitCrashed = false

    let type = "aufx"
    let subType = "Jjbz"
    let manufacturer = "Grov"

    private var didStart = false

    init() {}

    /// Load the AUv3 after the scene is active. The host engine is not created until Play.
    func start() async {
        guard !didStart else { return }
        didStart = true
        await waitUntilActive()

        let viewController = await playEngine.initComponent(
            type: type,
            subType: subType,
            manufacturer: manufacturer
        )

        viewModel = AudioUnitViewModel(
            showAudioControls: true,
            title: "Gerov: jj-breeze",
            message: viewController == nil
                ? "Audio Unit failed to load. Build and run this app once so iOS can register the AUv3 extension."
                : "Loaded AUv3",
            viewController: viewController
        )
    }

    private func waitUntilActive() async {
        if UIApplication.shared.applicationState == .active { return }
        for await _ in NotificationCenter.default.notifications(named: UIApplication.didBecomeActiveNotification) {
            break
        }
    }

    func startPlaying() async { await playEngine.startPlaying() }
    func stopPlaying() { playEngine.stopPlaying() }
    func setSource(_ source: SimplePlayEngine.Source) { playEngine.setSource(source) }
}
