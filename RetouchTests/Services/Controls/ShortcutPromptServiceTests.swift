import Foundation
import Testing
@testable import Retouch

@MainActor
struct ShortcutPromptServiceTests {
    nonisolated private final class StubControls: ControlPlacementServicing {
        let isAdded: Bool
        init(isAdded: Bool) { self.isAdded = isAdded }
        func isControlAdded(kind: String) async -> Bool { isAdded && kind == ShortcutPromptConfig.controlKind }
    }

    private let defaults: UserDefaults = {
        let name = "ShortcutPromptServiceTests.\(UUID().uuidString)"
        return UserDefaults(suiteName: name) ?? .standard
    }()

    private let ready = ShortcutPromptContext(isControlsVisible: true, hasStatus: false, faceSeenSeconds: 3)
    private let now = Date(timeIntervalSince1970: 1_795_658_400)

    private func makeService(isControlAdded: Bool = false) -> ShortcutPromptService {
        ShortcutPromptService(store: ShortcutPromptStore(defaults: defaults),
                              controls: StubControls(isAdded: isControlAdded),
                              now: { [now] in now })
    }

    private func openThreeTimes(_ service: ShortcutPromptService) {
        for _ in 0..<ShortcutPromptConfig.dailyOpenThreshold { service.recordOpen() }
    }

    @Test func showsAfterThreeOpensAndOnlyOncePerDay() {
        let service = makeService()
        openThreeTimes(service)
        #expect(service.shouldShow(ready))
        service.markShown()
        #expect(!service.shouldShow(ready))
    }

    @Test func dismissForeverIsSavedAcrossLaunches() {
        let first = makeService()
        openThreeTimes(first)
        first.dismissForever()
        #expect(!makeService().shouldShow(ready))
    }

    @Test func hidesWhenControlIsAdded() async {
        let service = makeService(isControlAdded: true)
        openThreeTimes(service)
        await service.refreshControlState()
        #expect(!service.shouldShow(ready))
    }
}
