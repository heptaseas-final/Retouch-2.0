import CoreGraphics
import Foundation

nonisolated struct ToolDetectionPlan {
    var interval: TimeInterval?
}

nonisolated extension ZoomService {
    func toolDetectionPlan() -> ToolDetectionPlan {
        guard toolDetector.isAvailable else { return ToolDetectionPlan(interval: nil) }
        let info = ProcessInfo.processInfo
        let context = ToolDetectionSchedule.Context(
            isAutoZoom: isGestureEnabled,
            faceVisible: lastFace != nil,
            handSeen: false,
            zoomHolding: inputMode.mode == .tool && (eyeFlow.isActive || lipFlow.isActive || noseFlow.isActive),
            thermalState: info.thermalState,
            isLowPowerMode: info.isLowPowerModeEnabled
        )
        return ToolDetectionPlan(interval: toolSchedule.interval(context, now: Date()))
    }

    func refreshTools(snap: DetectionSnapshot<ToolScan>?, converter: CoordinateConverter,
                      points: FacePoints, now: Date) {
        if let snap {
            let tracked = toolTracker.update(snap.value.detections, converter: converter,
                                             faceWidth: points.width,
                                             maxIntentSpeed: handBank.maxIntentSpeed, now: snap.timestamp)
            lastTools = tracked.compactMap { tool in
                guard let grip = gripVerifier.grip(of: tool, faceWidth: points.width, at: snap.timestamp)
                else { return nil }
                var held = tool
                held.grip = grip
                held.tipHint = gripVerifier.tipHint(of: tool, faceWidth: points.width, at: snap.timestamp)
                return held
            }
            lastToolTime = snap.timestamp
            toolsFromPose = false
            if let confirmed = lastTools.filter({ $0.confidence >= ToolDetectionTuning.triggerConfidence })
                .compactMap(\.grip).first {
                toolLatch.confirm(grip: confirmed, at: snap.timestamp)
            }
            if !lastTools.isEmpty { toolSchedule.noteToolSeen(at: snap.timestamp) }
            inputMode.note(InputModeGate.presence(of: lastTools, face: points), at: snap.timestamp)
        }
        applyLatchedPoseTool(faceWidth: points.width, now: now)
        let support = ZoomTuning.pitchEnabled && ZoomTuning.pitchHandSupportEnabled && pitchRecognizer.isLifted
        toolReading = ToolReadingGate(points: points, tools: lastTools, detectedAt: lastToolTime,
                                      enterDistance: handProfile.enterDistance,
                                      maxIntentSpeed: handBank.maxIntentSpeed,
                                      locked: FaceZone(target: resolver.target), support: support).read(now: now)
        if toolReading.isInZone { pacer.noteMotion(at: now) }
    }

    func dropHandState() {
        guard !hands.isEmpty || lastScan.handsSeen > 0 else { return }
        lastScan = HandScan()
        lastHand = nil
        hands = []
        handBank = makeHandBank()
    }

    func applyLatchedPoseTool(faceWidth: CGFloat, now: Date) {
        let pose = toolLatch.update(gripVerifier, faceWidth: faceWidth, now: now)
        let modelFresh = !toolsFromPose && !lastTools.isEmpty
            && now.timeIntervalSince(lastToolTime) <= ToolDetectionTuning.maxResultAge
        if let pose, !modelFresh {
            let pad = ToolDetectionTuning.poseToolPad * faceWidth
            let rect = CGRect(x: min(pose.grip.x, pose.tip.x), y: min(pose.grip.y, pose.tip.y),
                              width: abs(pose.grip.x - pose.tip.x), height: abs(pose.grip.y - pose.tip.y))
                .insetBy(dx: -pad, dy: -pad)
            var tool = TrackedTool(label: .brush, confidence: 1, rect: rect, speed: 0)
            tool.grip = pose.grip
            lastTools = [tool]
            lastToolTime = now
            toolsFromPose = true
        } else if pose == nil, toolsFromPose {
            lastTools = []
            toolsFromPose = false
        }
    }

    func toolDrivesInput(now: Date) -> Bool {
        (inputMode.mode == .tool || toolLatch.isLatched) && !lastTools.isEmpty
            && now.timeIntervalSince(lastToolTime) <= ToolDetectionTuning.maxResultAge
    }

    func updateInputMode(now: Date) {
        let zoomActive = eyeFlow.isActive || lipFlow.isActive || noseFlow.isActive
        let mode = inputMode.update(zoomActive: zoomActive, now: now)
        guard mode == .tool || toolLatch.isLatched, toolDrivesInput(now: now) else { return }
        dropHandState()
        eyeInput = EyeZoomFlow.Input()
        lipsInput = LipsZoomFlow.Input()
        noseInput = NoseZoomFlow.Input()
    }

    func clearToolState() {
        inputMode.reset()
        toolTracker.reset()
        gripVerifier.reset()
        toolLatch.reset()
        toolsFromPose = false
        lastTools = []
        lastToolTime = .distantPast
        toolReading = ToolZoneReading()
    }
}
