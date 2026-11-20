import Foundation

struct ShortcutPromptContext: Equatable {
    var isControlsVisible: Bool
    var hasStatus: Bool
    var faceSeenSeconds: TimeInterval
}

struct ShortcutPromptRule {
    var calendar: Calendar = .current

    func recordingOpen(_ history: ShortcutPromptHistory, at now: Date) -> ShortcutPromptHistory {
        var next = history
        next.openCount = isSameDay(history.openDay, as: now) ? history.openCount + 1 : 1
        next.openDay = now
        return next
    }

    func markingShown(_ history: ShortcutPromptHistory, at now: Date) -> ShortcutPromptHistory {
        var next = history
        next.lastShownDay = now
        return next
    }

    func shouldShow(_ history: ShortcutPromptHistory, context: ShortcutPromptContext,
                    isControlAdded: Bool, at now: Date) -> Bool {
        guard !history.isDismissedForever, !isControlAdded else { return false }
        guard context.isControlsVisible, !context.hasStatus,
              context.faceSeenSeconds >= ShortcutPromptConfig.faceSeenBeforePrompt else { return false }
        guard isSameDay(history.openDay, as: now),
              history.openCount >= ShortcutPromptConfig.dailyOpenThreshold else { return false }
        return !isSameDay(history.lastShownDay, as: now)
    }

    private func isSameDay(_ day: Date?, as now: Date) -> Bool {
        guard let day else { return false }
        return calendar.isDate(day, inSameDayAs: now)
    }
}
