import MapLibre
import Mockable
import Testing
@testable import MapLibreSwiftUI

@MainActor
struct CameraCoordinatorIdentityTests {
    let runner = MockCameraUpdateRunning(policy: .relaxedVoid)
    let map = MockMLNMapViewRepresentable(policy: .relaxedVoid)
    private let callbacks = CameraCallbacks()
    let coordinator: MapViewCoordinator<MLNMapViewController>

    init() {
        coordinator = .arrange(runner: runner)
        given(runner).run(.any).willProduce { [weak callbacks] in callbacks?.update = $0 }
        given(map).frame.willReturn(CGRect(x: 0, y: 0, width: 320, height: 240))
        given(map).userTrackingMode.willReturn(.follow)
        given(map).setUserTrackingMode(.any, animated: .any, completionHandler: .any)
            .willProduce { [weak callbacks] _, _, completion in callbacks?.completion = completion }
    }

    @Test("A replacement camera request prevents the old tracking completion from writing its zoom")
    func rejectReplacedCompletion() throws {
        let completeTracking = try arrangeTrackingCompletion()

        coordinator.applyCameraChangeFromStateUpdate(map, camera: .trackUserLocation(zoom: 15))
        completeTracking()

        verify(map).zoomLevel(newValue: .value(14)).setCalled(0)
    }

    @Test("An idle event preserves the current tracking completion and its requested zoom")
    func preserveIdleCompletion() throws {
        let completeTracking = try arrangeTrackingCompletion()

        coordinator.handleMapIdle(map)
        completeTracking()

        verify(map).zoomLevel(newValue: .value(14)).setCalled(1)
    }

    @Test("Explicit cancellation prevents the current tracking completion from writing its zoom")
    func rejectCanceledCompletion() throws {
        let completeTracking = try arrangeTrackingCompletion()

        coordinator.cancelCameraUpdate()
        completeTracking()

        verify(map).zoomLevel(newValue: .value(14)).setCalled(0)
    }

    @Test("An accepted gesture prevents the previous tracking completion from writing its zoom")
    func rejectCompletionAfterGesture() throws {
        let completeTracking = try arrangeTrackingCompletion()
        given(runner).isRunning.willReturn(false)

        coordinator.applyCameraChangeFromGesture(map, reason: .gesturePan)
        completeTracking()

        verify(map).zoomLevel(newValue: .value(14)).setCalled(0)
    }

    @Test("An ignored gesture preserves the current tracking completion and its requested zoom")
    func preserveIgnoredGesture() throws {
        let completeTracking = try arrangeTrackingCompletion()
        given(runner).isRunning.willReturn(true)

        coordinator.applyCameraChangeFromGesture(map, reason: .gesturePan)
        completeTracking()

        verify(map).zoomLevel(newValue: .value(14)).setCalled(1)
    }

    private func arrangeTrackingCompletion() throws -> () -> Void {
        coordinator.applyCameraChangeFromStateUpdate(map, camera: .trackUserLocation(zoom: 14))
        let applyUpdate = try #require(callbacks.update)
        applyUpdate()
        return try #require(callbacks.completion)
    }
}

@MainActor
private final class CameraCallbacks {
    var update: (@MainActor () -> Void)?
    var completion: (() -> Void)?
}
