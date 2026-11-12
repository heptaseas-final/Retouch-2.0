import SwiftUI

struct GuidedFocus: ViewModifier {
    let guide: String?

    @AccessibilityFocusState private var isFocused: Bool
    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceOverOn

    private let focusDelay: Duration = .milliseconds(300)

    func body(content: Content) -> some View {
        content
            .accessibilityFocused($isFocused)
            .task(id: guide) { await guideIfNeeded() }
    }

    private func guideIfNeeded() async {
        guard let guide, isVoiceOverOn, (try? await Task.sleep(for: focusDelay)) != nil else { return }
        if isFocused {
            var announcement = AttributedString(guide)
            announcement.accessibilitySpeechAnnouncementPriority = .low
            AccessibilityNotification.Announcement(announcement).post()
        } else {
            isFocused = true
        }
    }
}
