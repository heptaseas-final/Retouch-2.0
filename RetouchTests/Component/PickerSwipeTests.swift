import Testing
@testable import Retouch

@MainActor
struct PickerSwipeTests {
    @Test func updateStartsDragging() {
        let swipe = PickerSwipe()
        swipe.update(30)
        #expect(swipe.isDragging)
        #expect(swipe.translation == 30)
    }

    @Test func endPublishesPredictedRelease() {
        let swipe = PickerSwipe()
        swipe.update(30)
        swipe.end(predicted: 80)
        #expect(swipe.release?.predicted == 80)
    }

    @Test func endWithoutDragIsIgnored() {
        let swipe = PickerSwipe()
        swipe.end(predicted: 50)
        #expect(swipe.release == nil)
    }

    @Test func finishResetsEverything() {
        let swipe = PickerSwipe()
        swipe.update(30)
        swipe.end(predicted: 80)
        swipe.finish()
        #expect(!swipe.isDragging)
        #expect(swipe.translation == 0)
        #expect(swipe.release == nil)
    }

    @Test func cancelStopsDragging() {
        let swipe = PickerSwipe()
        swipe.update(20)
        swipe.cancel()
        #expect(!swipe.isDragging)
    }
}
