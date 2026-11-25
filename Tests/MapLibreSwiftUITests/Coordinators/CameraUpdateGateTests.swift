import Testing
@testable import MapLibreSwiftUI

@MainActor
struct CameraUpdateGateTests {
    let runner = CameraUpdateGate()

    @Test("Starting a camera update marks work pending before the task executes")
    func markPending() {
        defer { runner.cancel() }

        runner.run {}

        #expect(runner.isRunning)
    }

    @Test("An idle event before execution preserves the queued camera update")
    func preserveQueuedWork() throws {
        runner.run {}
        let task = try #require(runner.task)
        defer { runner.cancel(); task.cancel() }

        runner.finish()

        #expect(runner.isRunning)
    }

    @Test("A queued camera update still executes after an early idle event")
    func executeAfterEarlyIdle() async throws {
        defer { runner.cancel() }
        var updated = false
        runner.run { updated = true }

        runner.finish()

        try await waitForCameraEvent { updated }
    }

    @Test("A queued replacement still executes after the previous update reports idle")
    func executeReplacement() async throws {
        defer { runner.cancel() }
        var started = false
        runner.run { started = true }
        try await waitForCameraEvent { started }
        var replacementUpdated = false
        runner.run { replacementUpdated = true }

        runner.finish()

        try await waitForCameraEvent { replacementUpdated }
    }

    @Test("Finishing a running camera update completes its pending task")
    func completeRunningWork() async throws {
        defer { runner.cancel() }
        var started = false
        runner.run { started = true }
        let task = try #require(runner.task)
        try await waitForCameraEvent { started }

        runner.finish()

        try await waitForCameraCompletion(task, runner: runner)
    }

    @Test("Finishing a running camera update clears its running state")
    func clearFinishedState() async throws {
        defer { runner.cancel() }
        var started = false
        runner.run { started = true }
        try await waitForCameraEvent { started }

        runner.finish()

        #expect(!runner.isRunning)
    }

    @Test("Canceling a queued camera update prevents its operation from executing")
    func cancelQueuedWork() async throws {
        defer { runner.cancel() }
        var updated = false
        runner.run { updated = true }
        let task = try #require(runner.task)

        runner.cancel()
        try await waitForCameraCompletion(task, runner: runner)

        #expect(!updated)
    }

    @Test("Canceling a running camera update completes its pending task")
    func completeCanceledWork() async throws {
        defer { runner.cancel() }
        var started = false
        runner.run { started = true }
        let task = try #require(runner.task)
        try await waitForCameraEvent { started }

        runner.cancel()

        try await waitForCameraCompletion(task, runner: runner)
    }

    @Test("Canceling a running camera update clears its running state")
    func clearCanceledState() async throws {
        defer { runner.cancel() }
        var started = false
        runner.run { started = true }
        try await waitForCameraEvent { started }

        runner.cancel()

        #expect(!runner.isRunning)
    }

    @Test("A replacement cancels the previous camera task before it queues the next task")
    func cancelPreviousTask() {
        defer { runner.cancel() }
        runner.run {}
        let previous = runner.task

        runner.run {}

        #expect(previous?.isCancelled == true)
    }

    @Test("A replacement completes the previous running camera task")
    func completePreviousWork() async throws {
        defer { runner.cancel() }
        var started = false
        runner.run { started = true }
        let previous = try #require(runner.task)
        try await waitForCameraEvent { started }

        runner.run {}

        try await waitForCameraCompletion(previous, runner: runner)
    }

    @Test("An early idle event preserves the queued replacement task")
    func preserveReplacement() async throws {
        defer { runner.cancel() }
        var started = false
        runner.run { started = true }
        try await waitForCameraEvent { started }
        runner.run {}
        let replacement = try #require(runner.task)
        defer { replacement.cancel() }

        runner.finish()

        #expect(runner.isRunning)
    }

    @Test("Repeated idle events safely complete the same camera update")
    func finishTwice() async throws {
        defer { runner.cancel() }
        var started = false
        runner.run { started = true }
        let task = try #require(runner.task)
        try await waitForCameraEvent { started }

        runner.finish()
        runner.finish()

        try await waitForCameraCompletion(task, runner: runner)
    }

    @Test("Repeated cancellation safely completes the same camera update")
    func cancelTwice() async throws {
        defer { runner.cancel() }
        var started = false
        runner.run { started = true }
        let task = try #require(runner.task)
        try await waitForCameraEvent { started }

        runner.cancel()
        runner.cancel()

        try await waitForCameraCompletion(task, runner: runner)
    }

    @Test("An update can finish its task because the runner installs its continuation before execution")
    func finishInsideUpdate() async throws {
        defer { runner.cancel() }
        runner.run { runner.finish() }
        let task = try #require(runner.task)

        try await waitForCameraCompletion(task, runner: runner)
    }
}

@MainActor
private func waitForCameraEvent(_ event: () -> Bool) async throws {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: .seconds(2))
    while !event() {
        try #require(clock.now < deadline, "The camera update did not complete.")
        try await Task.sleep(for: .milliseconds(1))
    }
}

@MainActor
private func waitForCameraCompletion(_ task: Task<Void, Never>, runner: CameraUpdateGate) async throws {
    var completed = false
    let observation = Task {
        await task.value
        completed = true
    }
    defer { observation.cancel() }
    do {
        try await waitForCameraEvent { completed }
    } catch {
        runner.cancel()
        task.cancel()
        throw error
    }
}
