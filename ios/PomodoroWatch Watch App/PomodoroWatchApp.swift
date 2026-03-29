import SwiftUI

@main
struct PomodoroWatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(WatchConnectivityReceiver.shared)
        }
    }
}
