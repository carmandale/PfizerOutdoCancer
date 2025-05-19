import Testing
@testable import RoomTrackingKit

struct RoomTrackingManagerTests {
    @Test func managerInitialState() {
        let manager = RoomTrackingManager()
        #expect(manager.roomAnchorUpdateHandler == nil)
        #expect(manager.stateChangeHandler == nil)
    }
}
