import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// The icon, title, and port number of a menu item for a listening port.
struct PortMenuItemLabel: View {
    let title: Text
    let port: ListeningPort

    var body: some View {
        // Menus hide item icons unless the label style asks for them.
        Label {
            title
        } icon: {
            Image(nsImage: icon)
        }
        .labelStyle(.titleAndIcon)
        // A menu item shows its badge at the trailing edge. Ports are
        // identifiers, so they have no digit grouping.
        .badge(Text(port.number.formatted(.number.grouping(.never))))
    }

    /// The icon of the app that contains the process's executable, such as a
    /// helper's parent app, or otherwise of the executable itself.
    private var icon: NSImage {
        guard let path = port.process.executablePath else {
            return NSWorkspace.shared.icon(for: .unixExecutable)
        }
        let app = path.range(of: ".app/").map { String(path[..<$0.upperBound]) }
        return NSWorkspace.shared.icon(forFile: app ?? path)
    }
}
