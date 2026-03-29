import Foundation
import WatchConnectivity
import Flutter

/// Manages the WatchConnectivity session between the iPhone app and the
/// PomodoroWatch Watch App.
///
/// Responsibilities:
///  - Activates WCSession on startup.
///  - Forwards timer state (sent from Dart via pomodoro/watch channel) to the
///    paired Apple Watch using sendMessage (real-time when reachable) or
///    updateApplicationContext (background sync as fallback).
///  - Receives action messages ("toggle" / "skip") from the watch and invokes
///    the Flutter method channel so TimerActionBus can dispatch them.
class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()

    private var flutterChannel: FlutterMethodChannel?

    // MARK: - Setup

    func setup(flutterChannel: FlutterMethodChannel) {
        self.flutterChannel = flutterChannel
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Send timer state to watch

    func sendTimerState(
        remaining: Int,
        paused: Bool,
        isWork: Bool,
        title: String,
        session: Int,
        totalSessions: Int
    ) {
        guard WCSession.isSupported() else { return }
        let payload: [String: Any] = [
            "type": "timerState",
            "remaining": remaining,
            "paused": paused,
            "isWork": isWork,
            "title": title,
            "session": session,
            "totalSessions": totalSessions,
        ]
        let session = WCSession.default
        if session.activationState == .activated {
            if session.isReachable {
                // Real-time delivery when the watch app is in the foreground
                session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
            } else {
                // Background sync — watch reads this on next activation
                try? session.updateApplicationContext(payload)
            }
        }
    }

    // MARK: - WCSessionDelegate

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // Re-activate to support Apple Watch switching
        WCSession.default.activate()
    }

    /// Receives action messages from the watch ("toggle" / "skip") and forwards
    /// them to Dart via the pomodoro/watch channel so TimerActionBus can handle them.
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let action = message["action"] as? String else { return }
        DispatchQueue.main.async {
            self.flutterChannel?.invokeMethod("onWatchAction", arguments: ["action": action])
        }
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        self.session(session, didReceiveMessage: message)
        replyHandler([:])
    }
}
