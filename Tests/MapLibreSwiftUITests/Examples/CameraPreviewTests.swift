import SnapshotTesting
import XCTest
@testable import MapLibreSwiftUI

final class CameraPreviewTests: XCTestCase {
    @available(iOS 16.4, *)
    func testCameraPreview() async {
        await assertView {
            CameraDirectManipulationPreview(
                styleURL: URL(string: "https://demotiles.maplibre.org/style.json")!
            )
        }
    }
}
