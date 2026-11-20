import SwiftUI

struct ZoomableCameraPreview: View {
    let viewModel: MirrorViewModel
    var announcesZoom = true

    @State private var announcedTarget: ZoomTarget?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let announcementDelay: Duration = .milliseconds(800)

    var body: some View {
        GeometryReader { geo in
            GlowMirrorPreview(renderer: viewModel.renderer, zoom: viewModel.zoomState,
                              shrink: GlowFrame.zoomShrink(in: geo.size, progress: viewModel.glowProgress,
                                                           isOverall: viewModel.zoomTarget == .overall))
                .animation(GlowFrame.overallAnimation, value: viewModel.zoomTarget == .overall)
                .transaction { if reduceMotion { $0.animation = nil } }
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
        .onChange(of: reduceMotion, initial: true) { _, isOn in viewModel.setReduceMotion(isOn) }
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
