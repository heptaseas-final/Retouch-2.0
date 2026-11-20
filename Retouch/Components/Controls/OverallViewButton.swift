import SwiftUI

struct OverallViewButton: View {
    @Binding var isOn: Bool
    var size: CGFloat = 46


    private let inset: CGFloat = 4
    private var circleSize: CGFloat { size - inset * 2 }

    var body: some View {
        Button { withAnimation(.snappy) { isOn.toggle() } } label: {
            Label("Overall view", systemImage: isOn ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                .labelStyle(.iconOnly)
                .font(.system(size: circleSize * 0.4, weight: .semibold))
                .foregroundStyle(isOn ? Color.white : Color.appMagenta)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: size, height: size)
                .background(isOn ? Color.appMagenta : Color.clear, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .controlGlass()
        .frame(width: size, height: size)
        .sensoryFeedback(.impact(weight: .light), trigger: isOn)
        .accessibilityInputLabels([Text("Overall view"), Text("Overall"), Text("Zoom out")])
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityAddTraits(.isToggle)
        .accessibilityHint(isOn ? "Returns to the normal mirror." : "Shows your whole camera view.")
    }
}

#Preview {
    @Previewable @State var isOn = false
    OverallViewButton(isOn: $isOn)
        .padding()
        .background(Color.gray)
}
