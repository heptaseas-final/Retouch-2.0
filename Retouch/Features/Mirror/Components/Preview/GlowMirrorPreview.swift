import SwiftUI

struct GlowMirrorPreview: View, Animatable {
    let renderer: MirrorRenderer
    let zoom: ZoomState
    var shrink: CGFloat

    var animatableData: CGFloat {
        get { shrink }
        set { shrink = newValue }
    }

    var body: some View {
        MirrorPreview(renderer: renderer, zoom: GlowFrame.windowedZoom(zoom, shrink: shrink))
    }
}
