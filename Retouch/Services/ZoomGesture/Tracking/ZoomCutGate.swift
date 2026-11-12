import Foundation

nonisolated struct ZoomCutGate {
    enum Key: Equatable {
        case center
        case pinch
        case target(ZoomTarget)
    }

    let stableDelay: TimeInterval
    private(set) var accepted: Key?
    private var pending: Key?
    private var pendingSince: TimeInterval = 0

    init(stableDelay: TimeInterval) {
        self.stableDelay = stableDelay
    }

    mutating func accept(_ key: Key, isImmediate: Bool, now: TimeInterval) -> Bool {
        if key == accepted {
            pending = nil
            return true
        }
        if isImmediate || accepted == nil {
            accepted = key
            pending = nil
            return true
        }
        if key != pending {
            pending = key
            pendingSince = now
            return false
        }
        guard now - pendingSince >= stableDelay else { return false }
        accepted = key
        pending = nil
        return true
    }

    mutating func reset() {
        accepted = nil
        pending = nil
    }
}
