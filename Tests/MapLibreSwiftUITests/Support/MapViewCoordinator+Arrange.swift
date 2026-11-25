import MapLibre
import SwiftUI
@testable import MapLibreSwiftUI

@MainActor
extension MapViewCoordinator where T == MLNMapViewController {
    static func arrange(
        runner: any CameraUpdateRunning,
        camera: Binding<MapViewCamera> = .constant(.default())
    ) -> MapViewCoordinator<MLNMapViewController> {
        MapViewCoordinator(
            parent: MapView(styleURL: URL(fileURLWithPath: "/map-style.json"), camera: camera),
            onGesture: { _, _ in },
            onViewProxyChanged: { _ in },
            proxyUpdateMode: .onFinish,
            cameraUpdates: runner
        )
    }
}
