import SwiftUI

struct ContentView: View {
    let hostModel: AudioUnitHostModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(hostModel.viewModel.title)
                        .font(.headline)
                    Text("AUv3 test host")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(red: 0.08, green: 0.08, blue: 0.09))

            if let viewController = hostModel.viewModel.viewController {
                AUViewControllerUI(viewController: viewController)
                    .background(Color.black)
            } else {
                ContentUnavailableView(
                    hostModel.viewModel.message,
                    systemImage: "waveform",
                    description: Text("Run this app on a device or simulator to register the plug-in, then reopen GarageBand, AUM, or Logic for iPad.")
                )
            }

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
                        .frame(minWidth: 90)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.88, green: 0.54, blue: 0.24))
            }
            .padding(12)
            .background(Color(red: 0.08, green: 0.08, blue: 0.09))
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
        .task {
            await hostModel.start()
        }
    }
}
