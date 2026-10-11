import SwiftUI

/// A menu item that kills the process behind a listening port when chosen,
/// or force kills it while Option is held.
struct PortMenuItem: View {
    let port: ListeningPort
    let monitor: ProcessMonitor

    var body: some View {
        Button {
            monitor.kill(port.process)
        } label: {
            PortMenuItemLabel(title: Text(port.process.name), port: port)
        }
        .modifierKeyAlternate(.option) {
            Button {
                monitor.kill(port.process, force: true)
            } label: {
                PortMenuItemLabel(title: Text("Force Kill \(port.process.name)"), port: port)
            }
        }
    }
}
