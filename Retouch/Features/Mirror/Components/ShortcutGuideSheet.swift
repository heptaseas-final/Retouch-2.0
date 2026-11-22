import SwiftUI

struct ShortcutGuideSheet: View {
    let onClose: () -> Void

    private static let controlCenterSteps = [
        "Swipe down from the top-right corner of the screen to open Control Center.",
        "Tap the Add button at the top left.",
        "Tap Add a Control, then search for Re-touch.",
        "Tap Open Re-touch to add it."
    ]

    private static let lockScreenSteps = [
        "On the Lock Screen, touch and hold until Customize appears.",
        "Tap Customize, then tap Lock Screen.",
        "Tap the Remove button on a control at the bottom of the screen.",
        "Tap the Add button, then tap Open Re-touch.",
        "Tap Done."
    ]

    private static let actionButtonSteps = [
        "Open Settings, then tap Action Button.",
        "Swipe to Controls, then tap Choose a Control.",
        "Search for Re-touch, then tap Open Re-touch."
    ]

    var body: some View {
        NavigationStack {
            List {
                steps(Self.controlCenterSteps, title: "Control Center")
                steps(Self.lockScreenSteps, title: "Lock Screen")
                steps(Self.actionButtonSteps, title: "Action Button",
                      footer: "Only on iPhone models with the Action button.")
            }
            .navigationTitle("Add Retouch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onClose)
                        .tint(Color.appMagenta)
                }
            }
        }
    }

    private func steps(_ items: [String], title: String, footer: String? = nil) -> some View {
        Section {
            ForEach(Array(items.enumerated()), id: \.offset) { index, step in
                Label {
                    Text(step)
                } icon: {
                    Text("\(index + 1)")
                        .font(.headline)
                        .foregroundStyle(Color.appMagenta)
                }
                .accessibilityElement(children: .combine)
            }
        } header: {
            Text(title)
        } footer: {
            if let footer { Text(footer) }
        }
    }
}

#Preview {
    ShortcutGuideSheet(onClose: {})
}
