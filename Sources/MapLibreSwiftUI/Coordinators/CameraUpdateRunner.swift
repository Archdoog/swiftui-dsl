@MainActor
final class CameraUpdateRunner: CameraUpdateRunning {
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
