import Vision
import QuartzCore

nonisolated final class HandPointDetector: @unchecked Sendable {
    private let pinchMax: CGFloat = 0.5
    private let minJointConfidence: Float = 0.25

    private let request: VNDetectHumanHandPoseRequest = {
        let r = VNDetectHumanHandPoseRequest()
        r.maximumHandCount = 2
        return r
    }()
    private let queue = DispatchQueue(label: "zoom.hand")
    private let lock = NSLock()
    private let lowLight = LowLightEnhancer()
    private var busy = false
    private var gate = RateGate()
    private var cache = HandScan()
    private var cacheTime = Date.distantPast
    private var sequence = 0
    private var doneCount = 0
    private var windowStart = CACurrentMediaTime()
    private var rate = 0
    private var generation = 0
    private struct PoseMemory {
        var wrist: CGPoint
        var two: Bool
        var three: Bool
        var holding: Bool
        var time: TimeInterval
    }
    private var poseMemory: [PoseMemory] = []
    private let pinch2Max = ZoomTuning.lipsPose2Max
    private let tipJoints: [VNHumanHandPoseObservation.JointName] =
        [.thumbTip, .indexTip, .middleTip, .ringTip, .littleTip]
    private let fingerJoints: [(tip: VNHumanHandPoseObservation.JointName, mcp: VNHumanHandPoseObservation.JointName)] =
        [(.indexTip, .indexMCP), (.middleTip, .middleMCP), (.ringTip, .ringMCP), (.littleTip, .littleMCP)]

    var snapshot: DetectionSnapshot<HandScan> {
        lock.withLock { DetectionSnapshot(value: cache, sequence: sequence, timestamp: cacheTime) }
    }

    var latest: HandScan { lock.withLock { cache } }
    var detectionsPerSecond: Int { lock.withLock { rate } }
    var enhancementEV: Double { ZoomTuning.handLowLightEnabled ? lowLight.currentEV : 0 }

    func submit(_ pixelBuffer: CVPixelBuffer, minInterval: TimeInterval = 0) {
        let mediaNow = CACurrentMediaTime()
        let gen = lock.withLock { () -> Int? in
            if busy || !gate.allow(now: mediaNow, interval: minInterval) { return nil }
            busy = true
            return generation
        }
        guard let gen else { return }

        let stamp = Date()
        let aspect = CGFloat(CVPixelBufferGetHeight(pixelBuffer)) / CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        nonisolated(unsafe) let buffer = pixelBuffer
        queue.async { [self] in
            let scan = detect(buffer, aspect: aspect)
            lock.withLock {
                if gen == generation {
                    cache = scan
                    cacheTime = stamp
                    sequence += 1
                }
                busy = false
                doneCount += 1
                let now = CACurrentMediaTime()
                if now - windowStart >= 1 {
                    rate = doneCount
                    doneCount = 0
                    windowStart = now
                }
            }
        }
    }

    func reset() {
        lock.withLock {
            cache = HandScan()
            poseMemory = []
            generation += 1
        }
    }

    private func detect(_ pixelBuffer: CVPixelBuffer, aspect: CGFloat) -> HandScan {
        let enhancer: LowLightEnhancer? = ZoomTuning.handLowLightEnabled ? lowLight : nil
        let handler = AnalysisImage.handler(for: pixelBuffer, enhancer: enhancer)
        try? handler.perform([request])
        var scan = HandScan()
        guard let results = request.results else { return scan }
        scan.handsSeen = results.count

        let dark = ZoomTuning.handDarkRelaxEnabled
            && (enhancer?.currentEV ?? 0) >= ZoomTuning.handDarkEVThreshold
        let jointMin: Float = dark ? ZoomTuning.handDarkJointConfidence : minJointConfidence
        let baseMin: Float = dark ? ZoomTuning.handDarkBaseConfidence : 0.2

        func scaled(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x * aspect, y: p.y) }
        func unscaled(_ p: CGPoint) -> CGPoint {
            CGPoint(x: min(max(p.x / aspect, 0), 1), y: min(max(p.y, 0), 1))
        }
        func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }

        let nowT = CACurrentMediaTime()
        let memory: [PoseMemory] = ZoomTuning.poseKeepEnabled
            ? lock.withLock { poseMemory }.filter { nowT - $0.time <= ZoomTuning.poseKeepMaxAge }
            : []
        var newMemory: [PoseMemory] = []
        defer { lock.withLock { poseMemory = newMemory } }

        typealias FingerState = (tip: CGPoint, mcp: CGPoint, ext: CGFloat)

        func toolTip(_ obs: VNHumanHandPoseObservation, wrist w: CGPoint, size: CGFloat,
                     fingers: [FingerState], pinch: CGPoint?) -> (tip: CGPoint, base: CGPoint, mode: String)? {
            let fist = fingers.count >= 4 && fingers.allSatisfy { $0.ext <= ZoomTuning.toolFistMaxExt }
            if fist, let im = try? obs.recognizedPoint(.indexMCP), let lm = try? obs.recognizedPoint(.littleMCP),
               im.confidence >= jointMin * 0.5, lm.confidence >= jointMin * 0.5 {
                let a = scaled(im.location), b = scaled(lm.location)
                let d = dist(a, b)
                if d > 0.001 {
                    let r = size * ZoomTuning.toolReachFist
                    return (CGPoint(x: a.x + (a.x - b.x) / d * r, y: a.y + (a.y - b.y) / d * r), a, "F")
                }
            }
            guard let g = pinch else { return nil }
            let len = dist(g, w)
            guard len > 0.001 else { return (g, g, "Pn") }
            let r = size * ZoomTuning.toolTipReach
            return (CGPoint(x: g.x + (g.x - w.x) / len * r, y: g.y + (g.y - w.y) / len * r), g, "Pn")
        }

        for obs in results {
            for joint in tipJoints {
                if let p = try? obs.recognizedPoint(joint), p.confidence >= jointMin {
                    scan.fingertips.append(CGPoint(x: min(max(p.location.x, 0), 1),
                                                   y: min(max(p.location.y, 0), 1)))
                }
            }

            var ptWrist: CGPoint?
            var ptSize: CGFloat = 0
            if let wr = try? obs.recognizedPoint(.wrist), wr.confidence >= jointMin * 0.5 {
                let w = scaled(wr.location)
                ptWrist = w
                if let mp = try? obs.recognizedPoint(.middleMCP), mp.confidence >= jointMin * 0.5 {
                    ptSize = dist(w, scaled(mp.location))
                }
            }
            var fingers: [FingerState] = []
            if let w = ptWrist, ptSize > 0.01 {
                for f in fingerJoints {
                    guard let tp = try? obs.recognizedPoint(f.tip), let mp = try? obs.recognizedPoint(f.mcp),
                          tp.confidence >= jointMin, mp.confidence >= jointMin * 0.5 else { continue }
                    let mcpS = scaled(mp.location)
                    let mcpLen = dist(w, mcpS)
                    guard mcpLen > ptSize * 0.3 else { continue }
                    let tipS = scaled(tp.location)
                    fingers.append((tip: tipS, mcp: mcpS, ext: dist(w, tipS) / mcpLen))
                }
            }

            guard let thumb = try? obs.recognizedPoint(.thumbTip),
                  let index = try? obs.recognizedPoint(.indexTip),
                  let wrist = try? obs.recognizedPoint(.wrist),
                  let palm = try? obs.recognizedPoint(.middleMCP) else { continue }
            let middle = try? obs.recognizedPoint(.middleTip)

            let tS = scaled(thumb.location)
            let iS = scaled(index.location)
            let wS = scaled(wrist.location)
            let palmS = scaled(palm.location)
            let handSize = dist(wS, palmS)
            guard handSize > 0.01 else { continue }

            let prev: PoseMemory? = memory
                .filter { $0.two || $0.three || $0.holding }
                .min { dist(wS, $0.wrist) < dist(wS, $1.wrist) }
                .flatMap { dist(wS, $0.wrist) <= handSize * ZoomTuning.poseKeepRadius ? $0 : nil }
            let keepF = ZoomTuning.poseKeepFactor
            let jKeep = min(jointMin, ZoomTuning.poseKeepJointConfidence)
            let bKeep = min(baseMin, ZoomTuning.poseKeepBaseConfidence)

            let ratio2 = dist(tS, iS) / handSize
            let conf2 = min(thumb.confidence, index.confidence)
            if ratio2 < (scan.pinchRatio2 ?? .infinity) { scan.pinchRatio2 = ratio2 }

            var ratio3: CGFloat?
            var conf3: Float = 0
            var mS: CGPoint?
            if let middle {
                let m = scaled(middle.location)
                mS = m
                ratio3 = max(dist(tS, iS), dist(tS, m), dist(iS, m)) / handSize
                conf3 = min(conf2, middle.confidence)
                if let r3 = ratio3, r3 < (scan.pinchRatio ?? .infinity) {
                    scan.pinchRatio = r3
                    scan.confidence = conf3
                }
            }

            let keep3 = prev?.three == true
            let keep2 = prev?.two == true
            let keepHold = prev?.holding == true

            let baseStrict = wrist.confidence > baseMin && palm.confidence > baseMin
            let baseRelaxed = wrist.confidence > bKeep && palm.confidence > bKeep

            let three3Strict = baseStrict && (ratio3 ?? .infinity) <= pinchMax && conf3 >= jointMin
            let three3Keep = keep3 && baseRelaxed && (ratio3 ?? .infinity) <= pinchMax * keepF && conf3 >= jKeep
            let two2Strict = baseStrict && ratio2 <= pinch2Max && conf2 >= jointMin
            let two2Keep = keep2 && baseRelaxed && ratio2 <= pinch2Max * keepF && conf2 >= jKeep

            func evalHolding(relaxed: Bool) -> Bool {
                guard relaxed ? baseRelaxed : baseStrict else { return false }
                let jH = relaxed ? jKeep : jointMin
                let curlMax = relaxed ? ZoomTuning.gripCurlKeepMax : ZoomTuning.gripCurlMax
                let straightMin = relaxed ? ZoomTuning.gripStraightKeepMin : ZoomTuning.gripStraightMin
                let thumbMax = relaxed ? ZoomTuning.gripThumbKeepMax : ZoomTuning.gripThumbMax
                var known = 0, curled = 0, straight = 0
                for fj in fingerJoints {
                    guard let tp = try? obs.recognizedPoint(fj.tip), let mp = try? obs.recognizedPoint(fj.mcp),
                          tp.confidence >= jH, mp.confidence >= jH else { continue }
                    let mcpLen = dist(wS, scaled(mp.location))
                    guard mcpLen > handSize * 0.3 else { continue }
                    let ext = dist(wS, scaled(tp.location)) / mcpLen
                    known += 1
                    if ext <= curlMax { curled += 1 }
                    else if ext >= straightMin { straight += 1 }
                }
                let thumbGap = min(dist(tS, iS), mS.map { dist(tS, $0) } ?? .infinity) / handSize
                return conf2 >= jH && known >= 3 && straight == 0
                    && curled >= ZoomTuning.gripMinCurled && thumbGap <= thumbMax
            }
            let holdStrict = evalHolding(relaxed: false)
            let holdKeep = keepHold && evalHolding(relaxed: true)

            let three = three3Strict || three3Keep
            let two = two2Strict || two2Keep
            let holding = holdStrict || holdKeep
            guard three || two || holding else {
                if ZoomTuning.fingerPointEnabled {
                    if index.confidence >= jointMin {
                        scan.points.append(PointObservation(point: unscaled(iS), mode: "J"))
                    } else if let middle, middle.confidence >= jointMin, let mS {
                        scan.points.append(PointObservation(point: unscaled(mS), mode: "Jm"))
                    }
                }
                continue
            }
            let kept = !(three3Strict || two2Strict || holdStrict)
            newMemory.append(PoseMemory(wrist: wS, two: two, three: three, holding: holding, time: nowT))

            let g: CGPoint
            if three || !two, let mS {
                g = CGPoint(x: (tS.x + iS.x + mS.x) / 3, y: (tS.y + iS.y + mS.y) / 3)
            } else {
                g = CGPoint(x: (tS.x + iS.x) / 2, y: (tS.y + iS.y) / 2)
            }
            guard let tool = toolTip(obs, wrist: wS, size: handSize, fingers: fingers, pinch: g) else { continue }
            let tipS = tool.tip
            scan.grips.append(GripObservation(grip: unscaled(g), tip: unscaled(tipS),
                                              twoFinger: two, threeFinger: three, holding: holding,
                                              mode: tool.mode, base: unscaled(tool.base), kept: kept))
        }
        return scan
    }
}
