import Foundation
import WatchConnectivity

/// Receives timer state from the iPhone app and forwards watch button actions
/// back to the phone. Conforms to ObservableObject so SwiftUI views can react
/// to published state changes.
class WatchConnectivityReceiver: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchConnectivityReceiver()

    // Published timer state — drives the ContentView UI
    @Published var remaining: Int = 0
    @Published var paused: Bool = false
    @Published var isWork: Bool = true
    @Published var title: String = "Pomodoro"
    @Published var session: Int = 1
    @Published var totalSessions: Int = 4

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - Send actions to iPhone

    /// Sends a timer control action to the paired iPhone.
    /// "toggle" maps to pause/resume; "skip" advances to the next phase.
    func sendAction(_ action: String) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(["action": action], replyHandler: nil, errorHandler: nil)
    }

    // MARK: - WCSessionDelegate

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    /// Real-time message from iPhone (watch app is in foreground)
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        applyState(from: message)
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        applyState(from: message)
        replyHandler([:])
    }

    /// Background context update from iPhone (watch app was in background)
    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        applyState(from: applicationContext)
    }

    // MARK: - Private

    private func applyState(from message: [String: Any]) {
        guard (message["type"] as? String) == "timerState" else { return }
        DispatchQueue.main.async {
            if let v = message["remaining"] as? Int { self.remaining = v }
            if let v = message["paused"] as? Bool { self.paused = v }
            if let v = message["isWork"] as? Bool { self.isWork = v }
            if let v = message["title"] as? String { self.title = v }
            if let v = message["session"] as? Int { self.session = v }
            if let v = message["totalSessions"] as? Int { self.totalSessions = v }
        }
    }
}
