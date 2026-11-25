import Mockable
import Testing
@testable import MapLibreSwiftUI

@MainActor
struct CameraCoordinatorLifetimeTests {
    let runner = MockCameraUpdateRunning(policy: .relaxedVoid)
    let map = MockMLNMapViewRepresentable(policy: .relaxedVoid)

    @Test("A queued state update finishes the runner after its coordinator is released")
    func finishReleasedStateOwner() throws {
        var coordinator: MapViewCoordinator<MLNMapViewController>? = .arrange(runner: runner)
        var update: (@MainActor () -> Void)?
        given(runner).run(.any).willProduce { update = $0 }
        coordinator?.applyCameraChangeFromStateUpdate(map, camera: .default())
        coordinator = nil

        let applyUpdate = try #require(update)
        applyUpdate()

        verify(runner).finish().called(1)
    }

    @Test("A queued gesture update finishes the runner after its coordinator is released")
    func finishReleasedGestureOwner() throws {
        var coordinator: MapViewCoordinator<MLNMapViewController>? = .arrange(runner: runner)
        var update: (@MainActor () -> Void)?
        given(runner).isRunning.willReturn(false)
        given(runner).run(.any).willProduce { update = $0 }
        coordinator?.applyCameraChangeFromGesture(map, reason: .gesturePan)
        coordinator = nil

        let applyUpdate = try #require(update)
        applyUpdate()

        verify(runner).finish().called(1)
    }
}
