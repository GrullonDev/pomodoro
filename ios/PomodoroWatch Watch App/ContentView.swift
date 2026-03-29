import SwiftUI

struct ContentView: View {
    @EnvironmentObject var connectivity: WatchConnectivityReceiver

    private var timeString: String {
        let m = connectivity.remaining / 60
        let s = connectivity.remaining % 60
        return String(format: "%02d:%02d", m, s)
    }

    private var phaseColor: Color {
        connectivity.isWork ? Color.red.opacity(0.85) : Color.green.opacity(0.85)
    }

    var body: some View {
        VStack(spacing: 6) {
            // Phase label
            Text(connectivity.isWork ? "FOCUS" : "BREAK")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(phaseColor)
                .tracking(1.5)

            // Timer countdown
            Text(timeString)
                .font(.system(size: 38, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            // Session indicator
            Text("\(connectivity.session) / \(connectivity.totalSessions)")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Spacer(minLength: 4)

            // Controls
            HStack(spacing: 20) {
                // Pause / Resume
                Button {
                    connectivity.sendAction("toggle")
                } label: {
                    Image(systemName: connectivity.paused ? "play.fill" : "pause.fill")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered)
                .tint(phaseColor)

                // Skip
                Button {
                    connectivity.sendAction("skip")
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .containerBackground(Color.black, for: .watch)
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchConnectivityReceiver.shared)
}
