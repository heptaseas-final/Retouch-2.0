import Foundation

struct MirrorStatusAdvisor {
    private(set) var current: MirrorStatus?
    private var since: [MirrorStatus: TimeInterval] = [:]
    private var shownUntil: [MirrorStatus: TimeInterval] = [:]
    private var spent: Set<MirrorStatus> = []
    private var dismissed: Set<MirrorStatus> = []
    private var hadLowLight = false

    mutating func update(_ input: MirrorStatusInput, now: TimeInterval) -> MirrorStatus? {
        if current == .notEnoughLight || current == .moveCloserInLowLight { hadLowLight = true }
        let conditions = conditions(for: input)
        for status in MirrorStatus.allCases {
            if conditions.contains(status) {
                since[status] = since[status] ?? now
            } else {
                since[status] = nil
                if (shownUntil[status] ?? 0) <= now { spent.remove(status) }
            }
        }
        current = MirrorStatus.allCases.first { !dismissed.contains($0) && isActive($0, now: now) }
        return current
    }

    mutating func dismiss() {
        guard let current else { return }
        dismissed.insert(current)
        shownUntil[current] = nil
        self.current = nil
    }

    private func conditions(for input: MirrorStatusInput) -> Set<MirrorStatus> {
        typealias Config = MirrorStatusConfig
        let isLowLight = input.faceLux.map { $0 < Config.lowLux } ?? false
        let ratio = input.faceWidthRatio
        var result: Set<MirrorStatus> = []
        if input.isCameraPaused { result.insert(.cameraPaused) }
        if input.isHeatLimited { result.insert(.phoneWarm) }
        if isLowLight, input.isLightAtLimit { result.insert(.notEnoughLight) }
        if isLowLight, let ratio, ratio < Config.closeEnoughRatio { result.insert(.moveCloserInLowLight) }
        if let ratio, input.zoomScale >= Config.zoomedScale, ratio < Config.tooFarRatio { result.insert(.tooFar) }
        if let ratio, input.zoomScale < Config.fullViewScale, ratio > Config.faceTooWideRatio { result.insert(.faceTooWide) }
        if hadLowLight, let lux = input.faceLux, lux >= Config.enoughLux { result.insert(.enoughLight) }
        return result
    }

    private mutating func isActive(_ status: MirrorStatus, now: TimeInterval) -> Bool {
        if let until = shownUntil[status], now < until { return true }
        guard let start = since[status], now - start >= status.dwell else { return false }
        guard let displayTime = status.displayTime else { return true }
        guard !spent.contains(status) else { return false }
        spent.insert(status)
        shownUntil[status] = now + displayTime
        if status == .enoughLight { hadLowLight = false }
        return true
    }
}
