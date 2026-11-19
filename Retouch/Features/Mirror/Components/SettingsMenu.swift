import SwiftUI

struct SettingsMenu: View {
    @Binding var isLargerButtons: Bool
    @Binding var lightPlacement: LightPlacement
    let onReplayTutorial: () -> Void

    @State private var pendingLargerButtons: Bool?

    private let menuCloseDelay: Duration = .milliseconds(400)

    var body: some View {
        Menu {
            Button("Replay Tutorial", systemImage: "play.fill", action: onReplayTutorial)
            Section("Customize Settings") {
                Toggle("Larger Buttons", systemImage: "arrow.down.left.and.arrow.up.right", isOn: largerButtonsSelection)
            }
            Section("Light Button") {
                ForEach(LightPlacement.allCases, id: \.self) { placement in
                    Toggle(placement.title, systemImage: placement.symbol, isOn: selection(placement))
                }
            }
        } label: {
            Label("Settings", systemImage: "gearshape.fill")
                .labelStyle(.iconOnly)
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .lightOnGlassSystems()
        }
        .tint(Color.appMagenta)
        .task(id: pendingLargerButtons) { await applyLargerButtonsAfterClose() }
    }

    private var largerButtonsSelection: Binding<Bool> {
        Binding(
            get: { pendingLargerButtons ?? isLargerButtons },
            set: { pendingLargerButtons = $0 }
        )
    }

    private func selection(_ placement: LightPlacement) -> Binding<Bool> {
        Binding(
            get: { lightPlacement == placement },
            set: { if $0 { lightPlacement = placement } }
        )
    }

    private func applyLargerButtonsAfterClose() async {
        guard let pending = pendingLargerButtons, (try? await Task.sleep(for: menuCloseDelay)) != nil else { return }
        isLargerButtons = pending
        pendingLargerButtons = nil
    }
}

#Preview {
    @Previewable @State var isLarger = true
    @Previewable @State var placement = LightPlacement.bottom
    ZStack(alignment: .topTrailing) {
        Color.gray.ignoresSafeArea()
        SettingsMenu(isLargerButtons: $isLarger, lightPlacement: $placement) {}
            .padding()
    }
}
