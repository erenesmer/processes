import AppKit
import SwiftUI

@main
struct ProcessesApp: App {
    @State private var monitor = ProcessMonitor()

    var body: some Scene {
        MenuBarExtra {
            ProcessMenu(monitor: monitor)
        } label: {
            Label("Processes", systemImage: "ev.plug.dc.chademo.fill")
                .onReceive(NotificationCenter.default.publisher(for: NSMenu.didBeginTrackingNotification)) { notification in
                    // The menu's items are built right after this notification,
                    // and main actor tasks don't run while a menu is open, so
                    // the list is reloaded synchronously. A scan takes a few
                    // milliseconds.
                    monitor.refresh()

                    // SwiftUI can't size a menu, so the width is set on the menu itself.
                    (notification.object as? NSMenu)?.minimumWidth = ProcessMenu.minimumWidth
                }
        }
    }
}
