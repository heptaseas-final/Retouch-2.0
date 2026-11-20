@testable import Retouch

@MainActor
final class FakeShortcutPromptService: ShortcutPromptServicing {
    var shouldShowResult = false
    private(set) var openCount = 0
    private(set) var shownCount = 0
    private(set) var isDismissedForever = false
    private(set) var lastContext: ShortcutPromptContext?

    func recordOpen() { openCount += 1 }

    func refreshControlState() async {}

    func shouldShow(_ context: ShortcutPromptContext) -> Bool {
        lastContext = context
        return shouldShowResult
    }

    func markShown() { shownCount += 1 }

    func dismissForever() { isDismissedForever = true }
}
