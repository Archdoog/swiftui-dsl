#if MapLibreDeveloper
    import Mockable
#endif

/// Tracks pending camera work so the coordinator can suppress camera feedback into the binding.
#if MapLibreDeveloper
    @Mockable
#endif
protocol CameraUpdateGating: AnyObject {
    /// Whether an update is queued or has started and awaits completion.
    @MainActor var isRunning: Bool { get }

    /// Replaces the current update and schedules its replacement on the main actor.
    ///
    /// The gate becomes busy immediately and stays busy after the closure returns.
    /// Call `finish()` when the map becomes idle, or `cancel()` to release the gate.
    ///
    /// - Parameter update: The camera operation to execute unless canceled before execution.
    @MainActor func run(_ update: @escaping @MainActor () -> Void)

    /// Releases the gate if the current update has started.
    ///
    /// An idle event before execution leaves the queued update pending.
    @MainActor func finish()

    /// Releases the gate and prevents a queued update from executing.
    ///
    /// Does not stop a camera animation that has already started.
    @MainActor func cancel()
}

/// Holds the camera feedback gate across deferred execution and the wait for map idle.
@MainActor
final class CameraUpdateGate: CameraUpdateGating {
    /// The pending task, or `nil` when the gate is idle.
    private(set) var task: Task<Void, Never>?
    private var continuation: CheckedContinuation<Void, Never>?

    var isRunning: Bool {
        task != nil
    }

    func run(_ update: @escaping @MainActor () -> Void) {
        cancel()
        task = Task {
            await withCheckedContinuation { continuation in
                guard !Task.isCancelled else {
                    continuation.resume()
                    return
                }
                self.continuation = continuation
                update()
            }
        }
    }

    func finish() {
        guard let continuation else { return }
        self.continuation = nil
        task = nil
        continuation.resume()
    }

    func cancel() {
        task?.cancel()
        task = nil
        let continuation = continuation
        self.continuation = nil
        continuation?.resume()
    }
}
