import Darwin

/// A process that is currently running.
nonisolated struct RunningProcess: Hashable, Sendable {
    let pid: pid_t
    let name: String
    /// `nil` when the executable has been moved or deleted since launch.
    let executablePath: String?
    /// When the process was launched, in microseconds since the epoch. Tells
    /// this process apart from a later one that was given the same PID.
    let startTime: UInt64
}
