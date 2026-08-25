import SwiftUI

struct ContentView: View {
    let hostModel: AudioUnitHostModel

    var body: some View {
        VStack(spacing: 0) {
            header
            editor
            if let playbackError = hostModel.playbackError {
                Text(playbackError)
                    .font(.footnote)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.85))
            } else if hostModel.viewModel.viewController != nil, !hostModel.isPlaying {
                Text("Tap Play to hear the effect. Knobs do nothing until audio is running. For your own tracks, open this app once, then load Gerov: jj-breeze in GarageBand or Logic.")
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.92, green: 0.86, blue: 0.72))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.22, green: 0.16, blue: 0.08))
            }
            transport
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
        .task {
            await hostModel.start()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("jj-breeze")
                    .font(.headline)
                Text(hostModel.isPlaying ? "Playing through the effect" : "Standalone player")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if hostModel.isPlaying {
                Label("ON AIR", systemImage: "waveform")
                    .font(.caption.bold())
                    .foregroundStyle(Color(red: 0.88, green: 0.54, blue: 0.24))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(red: 0.08, green: 0.08, blue: 0.09))
    }

    @ViewBuilder
    private var editor: some View {
        if hostModel.isLoading {
            VStack(spacing: 12) {
                ProgressView()
                Text("Loading effect…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        } else if let viewController = hostModel.viewModel.viewController {
            AUViewControllerUI(viewController: viewController)
                .background(Color.black)
        } else {
            ContentUnavailableView(
                "Effect did not load",
                systemImage: "waveform",
                description: Text(hostModel.viewModel.message)
            )
        }
    }

    private var transport: some View {
        HStack(spacing: 16) {
            Picker("Source", selection: Binding(
                get: { hostModel.source },
                set: { hostModel.setSource($0) }
            )) {
                ForEach(SimplePlayEngine.Source.allCases) { source in
                    Text(source.rawValue).tag(source)
                }
            }
            .pickerStyle(.segmented)

            Button {
                Task {
                    if hostModel.isPlaying {
                        hostModel.stopPlaying()
                    } else {
                        await hostModel.startPlaying()
                    }
                }
            } label: {
                Label(hostModel.isPlaying ? "Stop" : "Play", systemImage: hostModel.isPlaying ? "stop.fill" : "play.fill")
                    .frame(minWidth: 100)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.88, green: 0.54, blue: 0.24))
            .disabled(hostModel.viewModel.viewController == nil || hostModel.isLoading)
        }
        .padding(12)
        .background(Color(red: 0.08, green: 0.08, blue: 0.09))
    }
}
