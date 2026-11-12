import SwiftUI

struct SettingsMenu: View {
    @Binding var isLargerButtons: Bool
    @Binding var lightPlacement: LightPlacement
    let isBottomAvailable: Bool
    var size: CGFloat = 54
    let onReplayTutorial: () -> Void

    @State private var pendingLargerButtons: Bool?

    private let glyphScale: CGFloat = 0.4
    private let menuCloseDelay: Duration = .milliseconds(400)

    var body: some View {
        Menu {
            Button("Replay Tutorial", systemImage: "play.fill", action: onReplayTutorial)
            Section("Customize Settings") {
                Toggle("Larger Buttons", systemImage: "arrow.down.left.and.arrow.up.right", isOn: largerButtonsSelection)
                ForEach(LightPlacement.allCases, id: \.self) { placement in
                    Toggle(placement.title, systemImage: placement.symbol, isOn: selection(placement))
                        .disabled(placement == .bottom && !isBottomAvailable)
                }
            }
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: size * glyphScale, weight: .bold))
                .foregroundStyle(Color.appMagenta)
                .frame(width: size, height: size)
                .glassStyle(in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .task(id: pendingLargerButtons) { await applyLargerButtonsAfterClose() }
        .accessibilityLabel("Settings")
        .accessibilityShowsLargeContentViewer {
            Label("Settings", systemImage: "gearshape.fill")
        }
    }

    private var largerButtonsSelection: Binding<Bool> {
        Binding(
            get: { pendingLargerButtons ?? isLargerButtons },
            set: { pendingLargerButtons = $0 }
        )
    }

    private func applyLargerButtonsAfterClose() async {
        guard let pending = pendingLargerButtons, (try? await Task.sleep(for: menuCloseDelay)) != nil else { return }
        isLargerButtons = pending
        pendingLargerButtons = nil
    }

    private func selection(_ placement: LightPlacement) -> Binding<Bool> {
        Binding(
            get: { lightPlacement == placement },
            set: { if $0 { lightPlacement = placement } }
        )
    }
}

#Preview {
    @Previewable @State var isLarger = true
    @Previewable @State var placement = LightPlacement.bottom
    ZStack(alignment: .topTrailing) {
        Color.gray.ignoresSafeArea()
        SettingsMenu(isLargerButtons: $isLarger, lightPlacement: $placement, isBottomAvailable: true) {}
            .padding()
    }
}
