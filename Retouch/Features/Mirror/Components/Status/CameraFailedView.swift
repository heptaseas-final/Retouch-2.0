import SwiftUI

struct CameraFailedView: View {
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Can't open the camera", systemImage: "video.slash.fill")
        } description: {
            Text("Close other apps that use the camera, then try again.")
        } actions: {
            Button("Try Again", action: onRetry)
                .glassButtonStyle(prominent: true)
                .controlSize(.large)
                .tint(.appMagenta)
        }
        .environment(\.colorScheme, .dark)
        .background(.black)
    }
}
