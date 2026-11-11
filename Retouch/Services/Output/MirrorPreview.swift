import SwiftUI

struct MirrorPreview: UIViewRepresentable {
    let renderer: MirrorRenderer
    var zoom = ZoomState()

    func makeUIView(context: Context) -> MetalLayerView {
        let view = MetalLayerView()
        view.renderer = renderer
        return view
    }

    func updateUIView(_ view: MetalLayerView, context: Context) {
        renderer.zoom = zoom
    }

    final class MetalLayerView: UIView {
        override class var layerClass: AnyClass { CAMetalLayer.self }
        var renderer: MirrorRenderer?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window == nil {
                renderer?.detach(layer as! CAMetalLayer)
            } else {
                setNeedsLayout()
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            let scale = window?.screen.scale ?? traitCollection.displayScale
            layer.contentsScale = scale
            renderer?.attach(layer as! CAMetalLayer,
                             drawableSize: CGSize(width: bounds.width * scale, height: bounds.height * scale))
        }
    }
}
