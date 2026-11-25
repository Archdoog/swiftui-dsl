import MapLibre
import Mockable
import SwiftUI
import Testing
@testable import MapLibreSwiftUI

@MainActor
struct CameraCoordinatorSchedulingTests {
    let runner = MockCameraUpdateGating(policy: .relaxedVoid)
    let map = MockMLNMapViewRepresentable(policy: .relaxedVoid)
    let coordinator: MapViewCoordinator<MLNMapViewController>

    init() {
        coordinator = .arrange(runner: runner)
    }

    @Test("The first camera state schedules one map update")
    func scheduleFirstCamera() {
        coordinator.applyCameraChangeFromStateUpdate(map, camera: .default())
        verify(runner).run(.any).called(1)
    }

    @Test("An unchanged camera state does not schedule another map update")
    func skipUnchangedCamera() {
        coordinator.applyCameraChangeFromStateUpdate(map, camera: .default())
        coordinator.applyCameraChangeFromStateUpdate(map, camera: .default())
        verify(runner).run(.any).called(1)
    }

    @Test("A changed camera state schedules a replacement update")
    func replaceChangedCamera() {
        coordinator.applyCameraChangeFromStateUpdate(map, camera: .default())
        coordinator.applyCameraChangeFromStateUpdate(map, camera: .trackUserLocation())
        verify(runner).run(.any).called(2)
    }

    @Test("A viewport change reapplies an unchanged camera")
    func reframeUnchangedCamera() {
        coordinator.applyCameraChangeFromStateUpdate(map, camera: .default())
        coordinator.applyCameraChangeFromStateUpdate(map, camera: .default(), reframing: true)
        verify(runner).run(.any).called(2)
    }

    @Test("A viewport change preserves camera tracking that MapLibre already handles")
    func preserveNativeTracking() {
        given(map).userTrackingMode.willReturn(.follow)
        coordinator.applyCameraChangeFromStateUpdate(map, camera: .trackUserLocation())
        coordinator.applyCameraChangeFromStateUpdate(map, camera: .trackUserLocation(), reframing: true)
        verify(runner).run(.any).called(1)
    }

    @Test("A viewport change restarts tracking when the native map has stopped tracking")
    func restartStoppedTracking() {
        given(map).userTrackingMode.willReturn(.none)
        coordinator.applyCameraChangeFromStateUpdate(map, camera: .trackUserLocation())
        coordinator.applyCameraChangeFromStateUpdate(map, camera: .trackUserLocation(), reframing: true)
        verify(runner).run(.any).called(2)
    }

    @Test("Scheduling a replacement leaves task cancellation to the camera runner")
    func delegateReplacement() {
        coordinator.applyCameraChangeFromStateUpdate(map, camera: .default())
        coordinator.applyCameraChangeFromStateUpdate(map, camera: .trackUserLocation())
        verify(runner).cancel().called(0)
    }

    @Test("Explicit camera cancellation cancels the pending runner update")
    func cancelRunner() {
        coordinator.cancelCameraUpdate()
        verify(runner).cancel().called(1)
    }

    @Test("A gesture does not schedule camera work while an update is pending")
    func skipGestureWhileRunning() {
        given(runner).isRunning.willReturn(true)
        coordinator.applyCameraChangeFromGesture(map, reason: .gesturePan)
        verify(runner).run(.any).called(0)
    }

    @Test("A gesture schedules camera work when the runner is idle")
    func scheduleIdleGesture() {
        given(runner).isRunning.willReturn(false)
        coordinator.applyCameraChangeFromGesture(map, reason: .gesturePan)
        verify(runner).run(.any).called(1)
    }

    @Test("An idle event finishes camera work before it notifies the observer")
    func finishBeforeObserver() {
        var events: [String] = []
        when(runner).finish().perform { events.append("finish") }
        coordinator.onMapIdle = { _ in events.append("observer") }
        coordinator.handleMapIdle(map)
        #expect(events == ["finish", "observer"])
    }

    @Test("The scheduled operation applies the camera with the requested animation setting")
    func applyScheduledCamera() {
        given(map).frame.willReturn(.zero)
        given(runner).run(.any).willProduce { update in update() }
        coordinator.applyCameraChangeFromStateUpdate(map, camera: .default(), animated: false)
        verify(map).setCenter(.any, zoomLevel: .any, direction: .any, animated: .value(false)).called(1)
    }

    @Test("An unchanged showcase camera does not schedule another map update")
    func skipUnchangedShowcase() {
        let camera = MapViewCamera.showcase(shapeCollection: MLNShapeCollection(shapes: []))
        coordinator.applyCameraChangeFromStateUpdate(map, camera: camera)
        coordinator.applyCameraChangeFromStateUpdate(map, camera: camera)
        verify(runner).run(.any).called(1)
    }

    @Test("The gesture operation writes the native camera values and change reason to the binding")
    func writeGestureCamera() {
        var camera = MapViewCamera.default()
        let coordinator = MapViewCoordinator<MLNMapViewController>.arrange(
            runner: runner,
            camera: Binding(get: { camera }, set: { camera = $0 })
        )
        let coordinate = CLLocationCoordinate2D(latitude: 12, longitude: 23)
        given(runner).isRunning.willReturn(false)
        given(runner).run(.any).willProduce { update in update() }
        given(map).minimumPitch.willReturn(5)
        given(map).maximumPitch.willReturn(45)
        given(map).centerCoordinate.willReturn(coordinate)
        given(map).zoomLevel.willReturn(14)
        given(map).camera.willReturn(MLNMapCamera(lookingAtCenter: coordinate, altitude: 100, pitch: 30, heading: 20))
        given(map).direction.willReturn(20)
        coordinator.applyCameraChangeFromGesture(map, reason: .gesturePan)
        #expect(camera == .center(coordinate, zoom: 14, pitch: 30,
                                  pitchRange: .freeWithinRange(minimum: 5, maximum: 45), direction: 20,
                                  reason: .gesturePan))
    }
}
