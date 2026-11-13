import Testing
@testable import Retouch

struct ZoomCutGateTests {
    @Test func firstGoalIsAcceptedRightAway() {
        var gate = ZoomCutGate(stableDelay: 0.3)
        let accepted = gate.accept(.center, isImmediate: false, now: 0)
        #expect(accepted)
    }

    @Test func autoTargetWaitsUntilStable() {
        var gate = ZoomCutGate(stableDelay: 0.3)
        _ = gate.accept(.center, isImmediate: false, now: 0)
        let first = gate.accept(.target(.leftEye), isImmediate: false, now: 1)
        let early = gate.accept(.target(.leftEye), isImmediate: false, now: 1.2)
        let stable = gate.accept(.target(.leftEye), isImmediate: false, now: 1.31)
        #expect(!first && !early && stable)
        #expect(gate.accepted == .target(.leftEye))
    }

    @Test func flickeringTargetRestartsTheWait() {
        var gate = ZoomCutGate(stableDelay: 0.3)
        _ = gate.accept(.center, isImmediate: false, now: 0)
        _ = gate.accept(.target(.leftEye), isImmediate: false, now: 1)
        _ = gate.accept(.target(.lips), isImmediate: false, now: 1.2)
        let back = gate.accept(.target(.leftEye), isImmediate: false, now: 1.35)
        #expect(!back)
        #expect(gate.accepted == .center)
    }

    @Test func pinchAndManualSelectionAreImmediate() {
        var gate = ZoomCutGate(stableDelay: 0.3)
        _ = gate.accept(.center, isImmediate: false, now: 0)
        let pinch = gate.accept(.pinch, isImmediate: true, now: 0.01)
        let manual = gate.accept(.target(.nose), isImmediate: true, now: 0.02)
        #expect(pinch && manual)
    }

    @Test func returningToTheAcceptedGoalCancelsThePendingOne() {
        var gate = ZoomCutGate(stableDelay: 0.3)
        _ = gate.accept(.center, isImmediate: false, now: 0)
        _ = gate.accept(.target(.lips), isImmediate: false, now: 1)
        let back = gate.accept(.center, isImmediate: false, now: 1.1)
        let lips = gate.accept(.target(.lips), isImmediate: false, now: 1.45)
        #expect(back && !lips)
    }
}
