import SwiftUI

struct OverallViewButton: View {
    @Binding var isOn: Bool
    var size: CGFloat = 46

    @Environment(\.isEnabled) private var isEnabled

    private let inset: CGFloat = 4
    private var circleSize: CGFloat { size - inset * 2 }

    var body: some View {
        Button { withAnimation(.snappy) { isOn.toggle() } } label: {
            Label("Overall view", systemImage: isOn ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                .labelStyle(.iconOnly)
                .font(.system(size: circleSize * 0.4, weight: .semibold))
                .foregroundStyle(isOn ? Color.white : Color.appMagenta)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: size, height: size)
                .background {
                    if isOn {
                        Circle().fill(Color.appMagenta)
                    } else {
                        Color.clear.controlGlass()
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .frame(width: size, height: size)
        .sensoryFeedback(.impact(weight: .light), trigger: isOn)
        .accessibilityInputLabels([Text("Overall view"), Text("Overall"), Text("Zoom out")])
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityAddTraits(.isToggle)
        .accessibilityHint(hint)
    }

    private var hint: String {
        guard isEnabled else { return "Not available while recording." }
        return isOn ? "Returns to the normal mirror." : "Shows your whole camera view."
    }
}

#Preview {
    @Previewable @State var isOn = false
    OverallViewButton(isOn: $isOn)
        .padding()
        .background(Color.gray)
}
