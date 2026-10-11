import AppKit
import SwiftUI

/// The contents of the menu bar extra's menu.
struct ProcessMenu: View {
    /// Fits the longest process names next to their ports, so that the menu
    /// keeps the same width whatever it lists.
    static let minimumWidth: CGFloat = 340

    let monitor: ProcessMonitor

    var body: some View {
        Section("Kill Process") {
            if monitor.listeningPorts.isEmpty {
                Text("No Listening Ports")
            } else {
                ForEach(monitor.listeningPorts) { port in
                    PortMenuItem(port: port, monitor: monitor)
                }
            }
        }

        Button("Quit Processes") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
