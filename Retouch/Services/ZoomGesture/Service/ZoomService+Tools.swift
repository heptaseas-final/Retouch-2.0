import CoreGraphics
import Foundation

nonisolated struct ToolDetectionPlan {
    var interval: TimeInterval?
    var pausesHands: Bool
}

nonisolated extension ZoomService {
    func toolDetectionPlan() -> ToolDetectionPlan {
        guard toolDetector.isAvailable else { return ToolDetectionPlan(interval: nil, pausesHands: false) }
        let info = ProcessInfo.processInfo
        let context = ToolDetectionSchedule.Context(
            isAutoZoom: isGestureEnabled,
            faceVisible: lastFace != nil,
            handSeen: lastScan.handsSeen > 0 || !hands.isEmpty,
            zoomHolding: eyeFlow.isActive || lipFlow.isActive,
            thermalState: info.thermalState,
            isLowPowerMode: info.isLowPowerModeEnabled
        )
        return ToolDetectionPlan(interval: toolSchedule.interval(context, now: Date()),
                                 pausesHands: toolReading.isInZone)
    }

    func refreshTools(snap: DetectionSnapshot<ToolScan>?, converter: CoordinateConverter,
                      points: FacePoints, now: Date) {
        if let snap {
            lastTools = toolTracker.update(snap.value.detections, converter: converter,
                                           faceWidth: points.width,
                                           maxIntentSpeed: handBank.maxIntentSpeed, now: snap.timestamp)
            lastToolTime = snap.timestamp
            if !lastTools.isEmpty { toolSchedule.noteToolSeen(at: snap.timestamp) }
        }
        let support = ZoomTuning.pitchEnabled && ZoomTuning.pitchHandSupportEnabled && pitchRecognizer.isLifted
        toolReading = ToolReadingGate(points: points, tools: lastTools, detectedAt: lastToolTime,
                                      enterDistance: handProfile.enterDistance,
                                      maxIntentSpeed: handBank.maxIntentSpeed,
                                      noseActive: noseFlow.isActive, support: support).read(now: now)
        if toolReading.isInZone {
            pacer.noteMotion(at: now)
            dropHandState()
        }
    }

    func dropHandState() {
        guard !hands.isEmpty || lastScan.handsSeen > 0 else { return }
        lastScan = HandScan()
        lastHand = nil
        hands = []
        handBank = makeHandBank()
    }

    func clearToolState() {
        toolTracker.reset()
        lastTools = []
        lastToolTime = .distantPast
        toolReading = ToolZoneReading()
    }
}
