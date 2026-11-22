import SwiftUI

struct ShortcutPromptPopover: View {
    let onShowGuide: () -> Void
    let onDismissForever: () -> Void

    private static let width: CGFloat = 300
    private static let horizontalPadding: CGFloat = 20
    private static let verticalPadding: CGFloat = 20
    private static let buttonSpacing: CGFloat = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Open re-touch faster")
                .font(.headline)
            Text("Add re-touch to your lock screen or control center.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: Self.buttonSpacing) {
                Button(action: onShowGuide) {
                    label("Show me")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.appMagenta)
                Button(action: onDismissForever) {
                    label("Don't show again")
                }
                .buttonStyle(.bordered)
                .tint(Color.appInactive)
            }
        }
        .padding(.horizontal, Self.horizontalPadding)
        .padding(.vertical, Self.verticalPadding)
        .frame(width: Self.width, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .presentationCompactAdaptation(.popover)
    }

    private func label(_ title: String) -> some View {
        Text(title)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    ShortcutPromptPopover(onShowGuide: {}, onDismissForever: {})
}
