import MapLibre
import Mockable
import Testing
@testable import MapLibreSwiftUI

@MainActor
struct TrackingCameraLayoutTests {
    let map = MockMLNMapViewRepresentable(policy: .relaxedVoid)
    let followCamera = MapViewCamera.trackUserLocation(
        pitch: 30, pitchRange: .freeWithinRange(minimum: 5, maximum: 45)
    )
    let headingCamera = MapViewCamera.trackUserLocationWithHeading(
        pitch: 30, pitchRange: .freeWithinRange(minimum: 5, maximum: 45)
    )
    let courseCamera = MapViewCamera.trackUserLocationWithCourse(
        pitch: 30, pitchRange: .freeWithinRange(minimum: 5, maximum: 45)
    )

    init() {
        given(map).frame.willReturn(.zero)
    }

    @Test("Before layout, location tracking does not center the map independently of tracking")
    func omitFollowCenter() {
        map.apply(camera: followCamera, animated: false)

        verify(map).setCenter(.any, zoomLevel: .any, direction: .any, animated: .any).called(0)
    }

    @Test("Before layout, location tracking applies pitch before restoring the minimum pitch limit")
    func restoreFollowMinimum() {
        var values: [Double] = []
        when(map).minimumPitch(newValue: .value(30)).performOnSet { values.append(30) }
        when(map).minimumPitch(newValue: .value(5)).performOnSet { values.append(5) }

        map.apply(camera: followCamera, animated: false)

        #expect(values == [30, 5])
        verify(map).minimumPitch(newValue: .any).setCalled(2)
    }

    @Test("Before layout, location tracking applies pitch before restoring the maximum pitch limit")
    func restoreFollowMaximum() {
        var values: [Double] = []
        when(map).maximumPitch(newValue: .value(30)).performOnSet { values.append(30) }
        when(map).maximumPitch(newValue: .value(45)).performOnSet { values.append(45) }

        map.apply(camera: followCamera, animated: false)

        #expect(values == [30, 45])
        verify(map).maximumPitch(newValue: .any).setCalled(2)
    }

    @Test("Before layout, heading tracking does not center the map independently of tracking")
    func omitHeadingCenter() {
        map.apply(camera: headingCamera, animated: false)

        verify(map).setCenter(.any, zoomLevel: .any, direction: .any, animated: .any).called(0)
    }

    @Test("Before layout, heading tracking applies pitch before restoring the minimum pitch limit")
    func restoreHeadingMinimum() {
        var values: [Double] = []
        when(map).minimumPitch(newValue: .value(30)).performOnSet { values.append(30) }
        when(map).minimumPitch(newValue: .value(5)).performOnSet { values.append(5) }

        map.apply(camera: headingCamera, animated: false)

        #expect(values == [30, 5])
        verify(map).minimumPitch(newValue: .any).setCalled(2)
    }

    @Test("Before layout, heading tracking applies pitch before restoring the maximum pitch limit")
    func restoreHeadingMaximum() {
        var values: [Double] = []
        when(map).maximumPitch(newValue: .value(30)).performOnSet { values.append(30) }
        when(map).maximumPitch(newValue: .value(45)).performOnSet { values.append(45) }

        map.apply(camera: headingCamera, animated: false)

        #expect(values == [30, 45])
        verify(map).maximumPitch(newValue: .any).setCalled(2)
    }

    @Test("Before layout, course tracking does not center the map independently of tracking")
    func omitCourseCenter() {
        map.apply(camera: courseCamera, animated: false)

        verify(map).setCenter(.any, zoomLevel: .any, direction: .any, animated: .any).called(0)
    }

    @Test("Before layout, course tracking applies pitch before restoring the minimum pitch limit")
    func restoreCourseMinimum() {
        var values: [Double] = []
        when(map).minimumPitch(newValue: .value(30)).performOnSet { values.append(30) }
        when(map).minimumPitch(newValue: .value(5)).performOnSet { values.append(5) }

        map.apply(camera: courseCamera, animated: false)

        #expect(values == [30, 5])
        verify(map).minimumPitch(newValue: .any).setCalled(2)
    }

    @Test("Before layout, course tracking applies pitch before restoring the maximum pitch limit")
    func restoreCourseMaximum() {
        var values: [Double] = []
        when(map).maximumPitch(newValue: .value(30)).performOnSet { values.append(30) }
        when(map).maximumPitch(newValue: .value(45)).performOnSet { values.append(45) }

        map.apply(camera: courseCamera, animated: false)

        #expect(values == [30, 45])
        verify(map).maximumPitch(newValue: .any).setCalled(2)
    }
}
