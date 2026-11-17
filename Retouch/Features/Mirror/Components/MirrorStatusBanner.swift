import SwiftUI

struct MirrorStatusBanner: View {
    let status: MirrorStatus
    
    var body: some View {
        Text(status.message)
            .font(.subheadline)
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color.appInactive.opacity(0.8), in: Capsule())
    }
}

#Preview {
    ZStack(alignment: .top) {
        Color.gray.ignoresSafeArea()
        VStack {
            MirrorStatusBanner(status: .notEnoughLight)
            MirrorStatusBanner(status: .enoughLight)
            MirrorStatusBanner(status: .cameraPaused)
        }
        .padding()
    }
}
