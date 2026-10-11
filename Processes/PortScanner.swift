import Darwin

/// Finds the TCP ports that processes are listening on, using `libproc`.
///
/// Without elevated privileges only the current user's processes can be
/// inspected, which are also the only ones the app is able to kill.
nonisolated enum PortScanner {
    /// Every listening port, in ascending order.
    static func listeningPorts() -> [ListeningPort] {
        allPIDs()
            .flatMap(listeningPorts(of:))
            .sorted { ($0.number, $0.process.pid) < ($1.number, $1.process.pid) }
    }

    static func startTime(of pid: pid_t) -> UInt64? {
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size else { return nil }
        return info.pbi_start_tvsec * 1_000_000 + info.pbi_start_tvusec
    }

    private static func allPIDs() -> [pid_t] {
        // The process table can grow between the two calls, so leave some headroom.
        let capacity = Int(max(0, proc_listallpids(nil, 0))) + 64
        return [pid_t](unsafeUninitializedCapacity: capacity) { buffer, count in
            let size = Int32(buffer.count * MemoryLayout<pid_t>.stride)
            count = Int(max(0, proc_listallpids(buffer.baseAddress, size)))
        }
    }

    private static func listeningPorts(of pid: pid_t) -> [ListeningPort] {
        let numbers = listeningPortNumbers(of: pid)
        guard !numbers.isEmpty, let startTime = startTime(of: pid) else { return [] }

        let path = string(capacity: 4 * Int(MAXPATHLEN)) { proc_pidpath(pid, $0, $1) }
        let process = RunningProcess(
            pid: pid,
            name: string(capacity: 2 * Int(MAXCOMLEN) + 1) { proc_name(pid, $0, $1) },
            executablePath: path.isEmpty ? nil : path,
            startTime: startTime
        )
        return numbers.map { ListeningPort(number: $0, process: process) }
    }

    /// A set, because a dual-stack server has an IPv4 and an IPv6 socket on the same port.
    private static func listeningPortNumbers(of pid: pid_t) -> Set<UInt16> {
        let stride = MemoryLayout<proc_fdinfo>.stride
        // Fails for processes owned by other users.
        let bytesNeeded = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, nil, 0)
        guard bytesNeeded > 0 else { return [] }

        let descriptors = [proc_fdinfo](unsafeUninitializedCapacity: Int(bytesNeeded) / stride) { buffer, count in
            let size = Int32(buffer.count * stride)
            count = Int(max(0, proc_pidinfo(pid, PROC_PIDLISTFDS, 0, buffer.baseAddress, size))) / stride
        }

        var numbers: Set<UInt16> = []
        for descriptor in descriptors where descriptor.proc_fdtype == PROX_FDTYPE_SOCKET {
            var socket = socket_fdinfo()
            let size = Int32(MemoryLayout<socket_fdinfo>.size)
            guard proc_pidfdinfo(pid, descriptor.proc_fd, PROC_PIDFDSOCKETINFO, &socket, size) == size,
                  socket.psi.soi_kind == SOCKINFO_TCP,
                  socket.psi.soi_proto.pri_tcp.tcpsi_state == TSI_S_LISTEN
            else { continue }
            // The kernel stores the port in network byte order.
            let port = socket.psi.soi_proto.pri_tcp.tcpsi_ini.insi_lport
            numbers.insert(UInt16(bigEndian: UInt16(truncatingIfNeeded: port)))
        }
        return numbers
    }

    /// Reads a string from a `libproc` call that fills a buffer and returns the length written.
    private static func string(capacity: Int, _ fill: (UnsafeMutableRawPointer?, UInt32) -> Int32) -> String {
        String(unsafeUninitializedCapacity: capacity) { buffer in
            Int(max(0, fill(buffer.baseAddress, UInt32(buffer.count))))
        }
    }
}
