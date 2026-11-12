import SwiftUI

struct ZoomableCameraPreview: View {
    let viewModel: MirrorViewModel
    var announcesZoom = true

    @State private var announcedTarget: ZoomTarget?

    private let announcementDelay: Duration = .milliseconds(800)

    var body: some View {
        GeometryReader { geo in
            MirrorPreview(renderer: viewModel.renderer, zoom: viewModel.zoomState)
                .frame(width: geo.size.width, height: geo.size.height)
                .onAppear { viewModel.setViewSize(geo.size) }
                .onChange(of: geo.size) { _, size in viewModel.setViewSize(size) }
        }
        .ignoresSafeArea()
        .gesture(
            MagnifyGesture()
                .onChanged { viewModel.pinchChanged($0.magnification) }
                .onEnded { _ in viewModel.pinchEnded() }
        )
        .accessibilityElement()
        .accessibilityLabel("Mirror")
        .accessibilityValue(viewModel.zoomTarget.spokenName)
        .task(id: viewModel.zoomTarget) { await announceWhenStable(viewModel.zoomTarget) }
    }

    private func announceWhenStable(_ target: ZoomTarget) async {
        guard let previous = announcedTarget else {
            announcedTarget = target
            return
        }
        guard target != previous, (try? await Task.sleep(for: announcementDelay)) != nil else { return }
        announcedTarget = target
        guard announcesZoom else { return }
        AccessibilityNotification.Announcement(target.zoomAnnouncement).post()
    }
}
