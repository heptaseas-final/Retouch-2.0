import SwiftUI

struct CameraFailedView: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Can't open the camera")
                    .font(.headline)
                Text("Close other apps that use the camera, then try again.")
                    .font(.subheadline)
            }
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)
            Button("Try Again", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }
}
