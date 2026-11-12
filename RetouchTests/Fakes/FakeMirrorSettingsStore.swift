@testable import Retouch

final class FakeMirrorSettingsStore: MirrorSettingsStoring {
    var isLargerButtons = false
    var lightPlacement: LightPlacement = .bottom
}
