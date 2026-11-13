import Foundation

protocol MirrorSettingsStoring: AnyObject {
    var isLargerButtons: Bool { get set }
    var lightPlacement: LightPlacement { get set }
}

final class MirrorSettingsStore: MirrorSettingsStoring {
    private enum Key {
        static let largerButtons = "mirror.largerButtons"
        static let lightPlacement = "mirror.lightPlacement"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isLargerButtons: Bool {
        get { defaults.bool(forKey: Key.largerButtons) }
        set { defaults.set(newValue, forKey: Key.largerButtons) }
    }

    var lightPlacement: LightPlacement {
        get { defaults.string(forKey: Key.lightPlacement).flatMap(LightPlacement.init(rawValue:)) ?? .bottom }
        set { defaults.set(newValue.rawValue, forKey: Key.lightPlacement) }
    }
}
