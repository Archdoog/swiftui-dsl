import MapLibre
import Mockable
import Testing
@testable import MapLibreSwiftUI

@MainActor
struct CameraCoordinatorCompletionTests {
    let runner = MockCameraUpdateGating(policy: .relaxedVoid)
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

    @Test("An idle event preserves the current tracking completion and its requested zoom")
    func preserveIdleCompletion() throws {
        let completeTracking = try arrangeTrackingCompletion()

        coordinator.handleMapIdle(map)
        completeTracking()

        verify(map).zoomLevel(newValue: .value(14)).setCalled(1)
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
