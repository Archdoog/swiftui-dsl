import CoreLocation
import MapLibre
import MapLibreSwiftDSL
import SwiftUI

@available(iOS 16.4, *)
struct CameraDirectManipulationPreview: View {
    @State private var camera = MapViewCamera.center(Self.france, zoom: 4)
    @State private var locationManager = StaticLocationManager(initialLocation: CLLocation(
        coordinate: Self.france,
        altitude: 0,
        horizontalAccuracy: 1,
        verticalAccuracy: 1,
        course: 45,
        speed: 10,
        timestamp: Date()
    ))

    let styleURL: URL
    var onStyleLoaded: (() -> Void)?

    var body: some View {
        MapView(styleURL: styleURL, camera: $camera, locationManager: locationManager)
            .onMapStyleLoaded { _ in
                print("Style Loaded")
                onStyleLoaded?()
            }
            .sheet(isPresented: .constant(true)) {
                cameraControls
                    .presentationDetents([.height(250)])
                    .presentationDragIndicator(.hidden)
                    .presentationBackgroundInteraction(.enabled)
                    .interactiveDismissDisabled()
            }
    }

    private var cameraControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                cameraButton("France", camera: .center(Self.france, zoom: 4))
                cameraButton("Closer", camera: .center(Self.france, zoom: 5))
                cameraButton("Tilt", camera: .center(Self.france, zoom: 5, pitch: 60, direction: 45))
                cameraButton("Follow", camera: .trackUserLocation(zoom: 5))
                cameraButton("Heading", camera: .trackUserLocationWithHeading(zoom: 5))
                cameraButton("Course", camera: .trackUserLocationWithCourse(zoom: 5))
                cameraButton("Fit bounds", camera: .boundingBox(MLNCoordinateBounds(
                    sw: CLLocationCoordinate2D(latitude: 41, longitude: -5),
                    ne: CLLocationCoordinate2D(latitude: 51.2, longitude: 9.7)
                )))
                cameraButton("Showcase", camera: .showcase(shapeCollection: MLNShapeCollection(shapes: [
                    MLNPolylineFeature(coordinates: [
                        CLLocationCoordinate2D(latitude: 48.4, longitude: -4.5),
                        CLLocationCoordinate2D(latitude: 48.6, longitude: 7.8),
                        CLLocationCoordinate2D(latitude: 43.3, longitude: 5.4),
                    ]),
                ])))
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)

            Text(String(describing: camera.state))
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .padding()
    }

    private static let france = CLLocationCoordinate2D(latitude: 46.6, longitude: 2.2)

    private func cameraButton(_ title: String, camera target: MapViewCamera) -> some View {
        Button {
            camera = target
        } label: {
            Text(title)
                .frame(maxWidth: .infinity, minHeight: 30)
        }
    }
}

@available(iOS 16.4, *)
#Preview("Camera controls") {
    CameraDirectManipulationPreview(styleURL: demoTilesURL)
        .ignoresSafeArea(.all)
}

struct CameraShowcasePolylinePreview: View {
    let styleURL: URL

    private let waypoints: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 47.3769, longitude: 8.5417), // Zurich
        CLLocationCoordinate2D(latitude: 47.0502, longitude: 8.3093), // Lucerne
        CLLocationCoordinate2D(latitude: 46.9479, longitude: 7.4446), // Bern
    ]

    private var showcaseShapeCollection: MLNShapeCollection {
        MLNShapeCollection(shapes: [MLNPolylineFeature(coordinates: waypoints)])
    }

    private var showcaseCamera: MapViewCamera {
        .showcase(
            shapeCollection: showcaseShapeCollection,
            edgePadding: .init(top: 80, left: 24, bottom: 120, right: 24)
        )
    }

    var body: some View {
        MapView(styleURL: styleURL, camera: .constant(showcaseCamera)) {
            let polylineSource = ShapeSource(identifier: "camera-showcase-polyline") {
                MLNPolylineFeature(coordinates: waypoints)
            }

            LineStyleLayer(identifier: "camera-showcase-polyline-line", source: polylineSource)
                .lineCap(.round)
                .lineJoin(.round)
                .lineColor(.systemBlue)
                .lineWidth(4)
        }
    }
}

#Preview("Camera Showcase Polyline") {
    CameraShowcasePolylinePreview(styleURL: demoTilesURL)
        .ignoresSafeArea(.all)
}
