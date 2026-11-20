import WidgetKit

nonisolated protocol ControlPlacementServicing: Sendable {
    func isControlAdded(kind: String) async -> Bool
}

nonisolated final class ControlPlacementService: ControlPlacementServicing {
    func isControlAdded(kind: String) async -> Bool {
        guard let controls = try? await ControlCenter.shared.currentControls() else { return false }
        return controls.contains { $0.kind == kind }
    }
}
