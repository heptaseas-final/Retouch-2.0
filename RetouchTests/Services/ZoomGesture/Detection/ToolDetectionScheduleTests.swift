import Foundation
import Testing
@testable import Retouch

struct ToolDetectionScheduleTests {
    private let now = Date(timeIntervalSinceReferenceDate: 1000)

    private func context(isAutoZoom: Bool = true,
                         faceVisible: Bool = true,
                         handSeen: Bool = false,
                         zoomHolding: Bool = false,
                         thermalState: ProcessInfo.ThermalState = .nominal,
                         isLowPowerMode: Bool = false) -> ToolDetectionSchedule.Context {
        ToolDetectionSchedule.Context(isAutoZoom: isAutoZoom, faceVisible: faceVisible, handSeen: handSeen,
                                      zoomHolding: zoomHolding, thermalState: thermalState,
                                      isLowPowerMode: isLowPowerMode)
    }

    @Test func staysOffWhenAutoZoomIsOff() {
        #expect(ToolDetectionSchedule().interval(context(isAutoZoom: false), now: now) == nil)
    }

    @Test func staysOffWithoutFace() {
        #expect(ToolDetectionSchedule().interval(context(faceVisible: false), now: now) == nil)
    }

    @Test func staysOffWhenThermalStateIsSerious() {
        #expect(ToolDetectionSchedule().interval(context(thermalState: .serious), now: now) == nil)
        #expect(ToolDetectionSchedule().interval(context(thermalState: .critical), now: now) == nil)
    }

    @Test func probesWhenNothingIsNearTheFace() {
        let interval = ToolDetectionSchedule().interval(context(), now: now)
        #expect(interval == 1 / ToolDetectionTuning.probeRate)
    }

    @Test func runsActiveWhenHandIsSeen() {
        let interval = ToolDetectionSchedule().interval(context(handSeen: true), now: now)
        #expect(interval == 1 / ToolDetectionTuning.activeRate)
    }

    @Test func runsActiveWhileZoomIsHeld() {
        let interval = ToolDetectionSchedule().interval(context(zoomHolding: true), now: now)
        #expect(interval == 1 / ToolDetectionTuning.activeRate)
    }

    @Test func staysActiveBrieflyAfterToolIsSeen() {
        var schedule = ToolDetectionSchedule()
        schedule.noteToolSeen(at: now)
        let during = now.addingTimeInterval(ToolDetectionTuning.keepActiveAfterSeen - 0.1)
        let after = now.addingTimeInterval(ToolDetectionTuning.keepActiveAfterSeen + 0.1)
        #expect(schedule.interval(context(), now: during) == 1 / ToolDetectionTuning.activeRate)
        #expect(schedule.interval(context(), now: after) == 1 / ToolDetectionTuning.probeRate)
    }

    @Test func slowsDownWhenThermalStateIsFair() {
        let schedule = ToolDetectionSchedule()
        #expect(schedule.interval(context(thermalState: .fair), now: now) == 1 / ToolDetectionTuning.fairProbeRate)
        #expect(schedule.interval(context(handSeen: true, thermalState: .fair), now: now)
                == 1 / ToolDetectionTuning.fairActiveRate)
    }

    @Test func slowsDownInLowPowerMode() {
        let schedule = ToolDetectionSchedule()
        #expect(schedule.interval(context(isLowPowerMode: true), now: now) == 1 / ToolDetectionTuning.fairProbeRate)
    }
}
