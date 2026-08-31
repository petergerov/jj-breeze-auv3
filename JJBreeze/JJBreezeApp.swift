import SwiftUI

@main
struct JJBreezeApp: App {
    private let hostModel = AudioUnitHostModel()

    var body: some Scene {
        WindowGroup {
            ContentView(hostModel: hostModel)
                .preferredColorScheme(.dark)
        }
    }
}
