/// A TCP port that a process is listening on.
nonisolated struct ListeningPort: Identifiable, Hashable, Sendable {
    let number: UInt16
    let process: RunningProcess

    var id: Self { self }
}
