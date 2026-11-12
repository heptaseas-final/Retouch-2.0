import SwiftUI

struct MirrorStatusBanner: View {
    let status: MirrorStatus
    let onDismiss: () -> Void

    private let minTapTarget: CGFloat = 44

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(status.message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Close", systemImage: "xmark", action: onDismiss)
                .labelStyle(.iconOnly)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(minWidth: minTapTarget, minHeight: minTapTarget)
                .contentShape(Rectangle())
        }
        .padding(.leading, 16)
        .padding(.vertical, 4)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private var symbol: String {
        switch status.kind {
        case .error: "exclamationmark.triangle.fill"
        case .success: "checkmark.circle.fill"
        case .info: "info.circle.fill"
        }
    }

    private var tint: Color {
        switch status.kind {
        case .error: .yellow
        case .success: .green
        case .info: .white
        }
    }
}

#Preview {
    ZStack(alignment: .top) {
        Color.gray.ignoresSafeArea()
        VStack {
            MirrorStatusBanner(status: .notEnoughLight) {}
            MirrorStatusBanner(status: .enoughLight) {}
            MirrorStatusBanner(status: .cameraPaused) {}
        }
        .padding()
    }
}
