import Foundation
import Testing
@testable import Retouch

struct ShortcutPromptRuleTests {
    private let rule: ShortcutPromptRule = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Jakarta") ?? .current
        return ShortcutPromptRule(calendar: calendar)
    }()

    private let morning = Date(timeIntervalSince1970: 1_795_658_400)
    private var evening: Date { morning.addingTimeInterval(10 * 3600) }
    private var nextMorning: Date { morning.addingTimeInterval(24 * 3600) }
    private let ready = ShortcutPromptContext(isControlsVisible: true, hasStatus: false, faceSeenSeconds: 3)

    private func opened(_ times: Int, at date: Date) -> ShortcutPromptHistory {
        (0..<times).reduce(ShortcutPromptHistory()) { history, _ in rule.recordingOpen(history, at: date) }
    }

    @Test func countsOpensOnTheSameDay() {
        let history = rule.recordingOpen(opened(2, at: morning), at: evening)
        #expect(history.openCount == 3)
    }

    @Test func countStartsOverOnANewDay() {
        let history = rule.recordingOpen(opened(3, at: morning), at: nextMorning)
        #expect(history.openCount == 1)
    }

    @Test func showsOnThirdOpenWhenReady() {
        #expect(!rule.shouldShow(opened(2, at: morning), context: ready, isControlAdded: false, at: morning))
        #expect(rule.shouldShow(opened(3, at: morning), context: ready, isControlAdded: false, at: morning))
    }

    @Test func showsOnlyOncePerDay() {
        let shown = rule.markingShown(opened(4, at: morning), at: morning)
        #expect(!rule.shouldShow(shown, context: ready, isControlAdded: false, at: evening))
        let tomorrow = (0..<3).reduce(shown) { history, _ in rule.recordingOpen(history, at: nextMorning) }
        #expect(rule.shouldShow(tomorrow, context: ready, isControlAdded: false, at: nextMorning))
    }

    @Test func staysHiddenAfterDismissedForever() {
        var history = opened(3, at: morning)
        history.isDismissedForever = true
        #expect(!rule.shouldShow(history, context: ready, isControlAdded: false, at: morning))
    }

    @Test func staysHiddenWhenControlIsAdded() {
        #expect(!rule.shouldShow(opened(3, at: morning), context: ready, isControlAdded: true, at: morning))
    }

    @Test func waitsUntilControlsFaceAndStatusAreReady() {
        let history = opened(3, at: morning)
        let hidden = ShortcutPromptContext(isControlsVisible: false, hasStatus: false, faceSeenSeconds: 3)
        let busy = ShortcutPromptContext(isControlsVisible: true, hasStatus: true, faceSeenSeconds: 3)
        let early = ShortcutPromptContext(isControlsVisible: true, hasStatus: false, faceSeenSeconds: 1)
        for context in [hidden, busy, early] {
            #expect(!rule.shouldShow(history, context: context, isControlAdded: false, at: morning))
        }
    }
}
