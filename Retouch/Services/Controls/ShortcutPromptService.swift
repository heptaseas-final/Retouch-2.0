import Foundation

protocol ShortcutPromptServicing: AnyObject {
    func recordOpen()
    func refreshControlState() async
    func shouldShow(_ context: ShortcutPromptContext) -> Bool
    func markShown()
    func dismissForever()
}

final class ShortcutPromptService: ShortcutPromptServicing {
    private let store: ShortcutPromptStoring
    private let controls: ControlPlacementServicing
    private let rule: ShortcutPromptRule
    private let now: () -> Date
    private var isControlAdded = false

    init(store: ShortcutPromptStoring, controls: ControlPlacementServicing,
         rule: ShortcutPromptRule = ShortcutPromptRule(), now: @escaping () -> Date = Date.init) {
        self.store = store
        self.controls = controls
        self.rule = rule
        self.now = now
    }

    func recordOpen() {
        store.history = rule.recordingOpen(store.history, at: now())
    }

    func refreshControlState() async {
        isControlAdded = await controls.isControlAdded(kind: ShortcutPromptConfig.controlKind)
    }

    func shouldShow(_ context: ShortcutPromptContext) -> Bool {
        rule.shouldShow(store.history, context: context, isControlAdded: isControlAdded, at: now())
    }

    func markShown() {
        store.history = rule.markingShown(store.history, at: now())
    }

    func dismissForever() {
        store.history.isDismissedForever = true
    }
}
