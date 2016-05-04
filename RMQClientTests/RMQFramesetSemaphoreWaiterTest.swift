import XCTest

class RMQFramesetSemaphoreWaiterTest: XCTestCase {
    
    func testTimeoutProducesError() {
        let waiter = RMQFramesetSemaphoreWaiter(syncTimeout: 0.1)
        let result = waiter.waitOn(RMQChannelOpenOk.self)

        XCTAssertNil(result.frameset)
        XCTAssertEqual(RMQError.ChannelWaitTimeout.rawValue, result.error.code)
        XCTAssertEqual("Timed out waiting for RMQChannelOpenOk.", result.error.localizedDescription)
    }

    func testIncorrectFramesetProducesError() {
        let waiter = RMQFramesetSemaphoreWaiter(syncTimeout: 10)
        let deliveredFrameset = RMQFrameset(channelNumber: 1, method: MethodFixtures.basicConsumeOk("foo"))

        dispatch_after(TestHelper.dispatchTimeFromNow(0.1), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            waiter.fulfill(deliveredFrameset)
        }
        let result = waiter.waitOn(RMQChannelOpenOk.self)

        XCTAssertEqual(deliveredFrameset, result.frameset)
        XCTAssertEqual(RMQError.ChannelIncorrectSyncMethod.rawValue, result.error.code)
        XCTAssertEqual("Expected RMQChannelOpenOk, got RMQBasicConsumeOk.", result.error.localizedDescription)
    }

    func testCorrectFramesetProducesFramesetAndNoError() {
        let waiter = RMQFramesetSemaphoreWaiter(syncTimeout: 10)
        let deliveredFrameset = RMQFrameset(channelNumber: 1, method: MethodFixtures.channelOpenOk())

        dispatch_after(TestHelper.dispatchTimeFromNow(0.1), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            waiter.fulfill(deliveredFrameset)
        }
        let result = waiter.waitOn(RMQChannelOpenOk.self)

        XCTAssertEqual(deliveredFrameset, result.frameset)
        XCTAssertNil(result.error)
    }
    
}
