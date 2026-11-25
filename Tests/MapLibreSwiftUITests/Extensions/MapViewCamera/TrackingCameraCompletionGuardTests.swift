import MapLibre
import Mockable
import Testing
@testable import MapLibreSwiftUI

@MainActor
struct TrackingCameraCompletionGuardTests {
    let map = MockMLNMapViewRepresentable(policy: .relaxedVoid)

    init() {
        given(map).frame.willReturn(CGRect(x: 0, y: 0, width: 320, height: 240))
        given(map).setUserTrackingMode(.any, animated: .any, completionHandler: .any)
            .willProduce { _, _, completion in completion?() }
    }

    @Test("After location tracking finishes, a changed native tracking mode prevents a minimum pitch write")
    func skipChangedFollowMinimum() {
        given(map).userTrackingMode.willReturn(.none)

        map.apply(camera: .trackUserLocation(pitch: 30), animated: true, isCurrent: { true })

        verify(map).minimumPitch(newValue: .any).setCalled(0)
    }

    @Test("After location tracking finishes, a changed native tracking mode prevents a maximum pitch write")
    func skipChangedFollowMaximum() {
        given(map).userTrackingMode.willReturn(.none)

        map.apply(camera: .trackUserLocation(pitch: 30), animated: true, isCurrent: { true })

        verify(map).maximumPitch(newValue: .any).setCalled(0)
    }

    @Test("After location tracking finishes, an outdated camera request prevents a minimum pitch write")
    func skipStaleFollowMinimum() {
        given(map).userTrackingMode.willReturn(.follow)

        map.apply(camera: .trackUserLocation(pitch: 30), animated: true, isCurrent: { false })

        verify(map).minimumPitch(newValue: .any).setCalled(0)
    }

    @Test("After location tracking finishes, an outdated camera request prevents a maximum pitch write")
    func skipStaleFollowMaximum() {
        given(map).userTrackingMode.willReturn(.follow)

        map.apply(camera: .trackUserLocation(pitch: 30), animated: true, isCurrent: { false })

        verify(map).maximumPitch(newValue: .any).setCalled(0)
    }

    @Test("After location tracking finishes, an outdated camera request prevents a zoom write")
    func skipFollowZoom() {
        given(map).userTrackingMode.willReturn(.follow)

        map.apply(camera: .trackUserLocation(zoom: 14), animated: true, isCurrent: { false })

        verify(map).zoomLevel(newValue: .any).setCalled(0)
    }

    @Test("After heading tracking finishes, a changed native tracking mode prevents a minimum pitch write")
    func skipChangedHeadingMinimum() {
        given(map).userTrackingMode.willReturn(.none)

        map.apply(camera: .trackUserLocationWithHeading(pitch: 30), animated: true, isCurrent: { true })

        verify(map).minimumPitch(newValue: .any).setCalled(0)
    }

    @Test("After heading tracking finishes, a changed native tracking mode prevents a maximum pitch write")
    func skipChangedHeadingMaximum() {
        given(map).userTrackingMode.willReturn(.none)

        map.apply(camera: .trackUserLocationWithHeading(pitch: 30), animated: true, isCurrent: { true })

        verify(map).maximumPitch(newValue: .any).setCalled(0)
    }

    @Test("After heading tracking finishes, an outdated camera request prevents a minimum pitch write")
    func skipStaleHeadingMinimum() {
        given(map).userTrackingMode.willReturn(.followWithHeading)

        map.apply(camera: .trackUserLocationWithHeading(pitch: 30), animated: true, isCurrent: { false })

        verify(map).minimumPitch(newValue: .any).setCalled(0)
    }

    @Test("After heading tracking finishes, an outdated camera request prevents a maximum pitch write")
    func skipStaleHeadingMaximum() {
        given(map).userTrackingMode.willReturn(.followWithHeading)

        map.apply(camera: .trackUserLocationWithHeading(pitch: 30), animated: true, isCurrent: { false })

        verify(map).maximumPitch(newValue: .any).setCalled(0)
    }

    @Test("After heading tracking finishes, an outdated camera request prevents a zoom write")
    func skipHeadingZoom() {
        given(map).userTrackingMode.willReturn(.followWithHeading)

        map.apply(camera: .trackUserLocationWithHeading(zoom: 14), animated: true, isCurrent: { false })

        verify(map).zoomLevel(newValue: .any).setCalled(0)
    }

    @Test("After course tracking finishes, a changed native tracking mode prevents a minimum pitch write")
    func skipChangedCourseMinimum() {
        given(map).userTrackingMode.willReturn(.none)

        map.apply(camera: .trackUserLocationWithCourse(pitch: 30), animated: true, isCurrent: { true })

        verify(map).minimumPitch(newValue: .any).setCalled(0)
    }

    @Test("After course tracking finishes, a changed native tracking mode prevents a maximum pitch write")
    func skipChangedCourseMaximum() {
        given(map).userTrackingMode.willReturn(.none)

        map.apply(camera: .trackUserLocationWithCourse(pitch: 30), animated: true, isCurrent: { true })

        verify(map).maximumPitch(newValue: .any).setCalled(0)
    }

    @Test("After course tracking finishes, an outdated camera request prevents a minimum pitch write")
    func skipStaleCourseMinimum() {
        given(map).userTrackingMode.willReturn(.followWithCourse)

        map.apply(camera: .trackUserLocationWithCourse(pitch: 30), animated: true, isCurrent: { false })

        verify(map).minimumPitch(newValue: .any).setCalled(0)
    }

    @Test("After course tracking finishes, an outdated camera request prevents a maximum pitch write")
    func skipStaleCourseMaximum() {
        given(map).userTrackingMode.willReturn(.followWithCourse)

        map.apply(camera: .trackUserLocationWithCourse(pitch: 30), animated: true, isCurrent: { false })

        verify(map).maximumPitch(newValue: .any).setCalled(0)
    }

    @Test("After course tracking finishes, an outdated camera request prevents a zoom write")
    func skipCourseZoom() {
        given(map).userTrackingMode.willReturn(.followWithCourse)

        map.apply(camera: .trackUserLocationWithCourse(zoom: 14), animated: true, isCurrent: { false })

        verify(map).zoomLevel(newValue: .any).setCalled(0)
    }
}
