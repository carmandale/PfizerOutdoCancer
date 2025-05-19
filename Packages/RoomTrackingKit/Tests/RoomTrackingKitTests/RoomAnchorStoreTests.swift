import XCTest
import simd
@testable import RoomTrackingKit

final class RoomAnchorStoreTests: XCTestCase {
    func testSaveAndLoad() throws {
        let store = RoomAnchorStore(filename: "test_room_anchor.json")
        defer { try? store.delete() }

        let transform = simd_float4x4(diagonal: SIMD4<Float>(repeating: 1))
        try store.save(transform: transform)

        let loaded = try store.load()
        XCTAssertEqual(loaded, transform)
    }
}
