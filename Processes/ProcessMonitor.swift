import Darwin
import Foundation
import Observation
import os

/// The source of truth for the listening ports shown in the menu.
@Observable
final class ProcessMonitor {
    private(set) var listeningPorts: [ListeningPort] = []

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Processes", category: "ProcessMonitor")

    func refresh() {
        listeningPorts = PortScanner.listeningPorts()
    }

    /// Asks `process` to terminate, or kills it outright when `force` is set.
    func kill(_ process: RunningProcess, force: Bool = false) {
        // `process` comes from a snapshot, so make sure its PID hasn't since
        // been handed to a different process.
        guard PortScanner.startTime(of: process.pid) == process.startTime else { return }

        if Darwin.kill(process.pid, force ? SIGKILL : SIGTERM) != 0 {
            let reason = String(cString: strerror(errno))
            logger.error("Couldn't kill \(process.name, privacy: .public) (\(process.pid)): \(reason, privacy: .public)")
        }
    }
}
