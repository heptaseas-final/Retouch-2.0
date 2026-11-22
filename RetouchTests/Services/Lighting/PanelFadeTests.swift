import Foundation
import Testing
@testable import Retouch

@MainActor
struct PanelFadeTests {
    private let frame: Float = 1.0 / 30
    private let fadeTime: Float = 0.25

    @Test func leavingManualInBrightRoomTurnsGlowOffAtOnce() {
        #expect(PanelFade.next(panel: 1, target: 0, dt: frame, fadeTime: fadeTime, isLeavingManual: true) == 0)
    }

    @Test func leavingManualInDarkRoomGoesStraightToAutoLevel() {
        #expect(PanelFade.next(panel: 1, target: 0.6, dt: frame, fadeTime: fadeTime, isLeavingManual: true) == 0.6)
    }

    @Test func autoRiseUsesFadeTime() {
        let next = PanelFade.next(panel: 0, target: 1, dt: fadeTime, fadeTime: fadeTime, isLeavingManual: false)
        #expect(abs(next - (1 - exp(-1))) < 0.000_1)
    }

    @Test func autoFallIsTwiceAsSlow() {
        let next = PanelFade.next(panel: 1, target: 0, dt: 2 * fadeTime, fadeTime: fadeTime, isLeavingManual: false)
        #expect(abs(next - exp(-1)) < 0.000_1)
    }

    @Test func autoAtTargetStaysThere() {
        #expect(PanelFade.next(panel: 0.5, target: 0.5, dt: frame, fadeTime: fadeTime, isLeavingManual: false) == 0.5)
    }
}
