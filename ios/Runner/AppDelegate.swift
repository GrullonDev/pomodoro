import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        setupWatchChannel(engineBridge: engineBridge)
    }

    // MARK: - Watch channel

    private func setupWatchChannel(engineBridge: FlutterImplicitEngineBridge) {
        let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PomodoroWatchPlugin")
        let channel = FlutterMethodChannel(
            name: "pomodoro/watch",
            binaryMessenger: registrar.messenger()
        )

        // Handle Dart → native calls
        channel.setMethodCallHandler { call, result in
            guard call.method == "syncState",
                  let args = call.arguments as? [String: Any]
            else {
                result(FlutterMethodNotImplemented)
                return
            }
            WatchSessionManager.shared.sendTimerState(
                remaining: args["remaining"] as? Int ?? 0,
                paused: args["paused"] as? Bool ?? false,
                isWork: args["isWork"] as? Bool ?? true,
                title: args["title"] as? String ?? "Pomodoro",
                session: args["session"] as? Int ?? 1,
                totalSessions: args["totalSessions"] as? Int ?? 1
            )
            result(nil)
        }

        // Start WatchConnectivity and give it the channel so it can relay watch
        // action taps back to Dart (onWatchAction → TimerActionBus)
        WatchSessionManager.shared.setup(flutterChannel: channel)
    }
}
