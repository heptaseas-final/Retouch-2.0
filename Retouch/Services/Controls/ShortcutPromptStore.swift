import Foundation

struct ShortcutPromptHistory: Equatable {
    var openDay: Date?
    var openCount = 0
    var lastShownDay: Date?
    var isDismissedForever = false
}

protocol ShortcutPromptStoring: AnyObject {
    var history: ShortcutPromptHistory { get set }
}

final class ShortcutPromptStore: ShortcutPromptStoring {
    private enum Key {
        static let openDay = "shortcutPrompt.openDay"
        static let openCount = "shortcutPrompt.openCount"
        static let lastShownDay = "shortcutPrompt.lastShownDay"
        static let isDismissedForever = "shortcutPrompt.isDismissedForever"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var history: ShortcutPromptHistory {
        get {
            ShortcutPromptHistory(openDay: defaults.object(forKey: Key.openDay) as? Date,
                                  openCount: defaults.integer(forKey: Key.openCount),
                                  lastShownDay: defaults.object(forKey: Key.lastShownDay) as? Date,
                                  isDismissedForever: defaults.bool(forKey: Key.isDismissedForever))
        }
        set {
            defaults.set(newValue.openDay, forKey: Key.openDay)
            defaults.set(newValue.openCount, forKey: Key.openCount)
            defaults.set(newValue.lastShownDay, forKey: Key.lastShownDay)
            defaults.set(newValue.isDismissedForever, forKey: Key.isDismissedForever)
        }
    }
}
