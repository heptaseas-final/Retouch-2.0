import SwiftUI

struct MirrorStatusBanner: View {
    let status: MirrorStatus
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .foregroundStyle(.white)
                .accessibilityHidden(true)
            Text(status.message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Close", systemImage: "xmark", action: onDismiss)
                .labelStyle(.iconOnly)
                .font(.subheadline.weight(.bold))
                .glassButtonStyle()
                .buttonBorderShape(.circle)
                .controlSize(.large)
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
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
