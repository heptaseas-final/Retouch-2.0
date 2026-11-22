import AVFoundation
import SwiftUI

struct ClipPlayer: UIViewRepresentable {
    let url: URL
    var isPlaying = true

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.load(url)
        return view
    }

    func updateUIView(_ view: PlayerView, context: Context) {
        view.setPlaying(isPlaying)
    }

    static func dismantleUIView(_ view: PlayerView, coordinator: ()) {
        view.unload()
    }

    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }

        private var player: AVQueuePlayer?
        private var looper: AVPlayerLooper?

        func load(_ url: URL) {
            guard let playerLayer = layer as? AVPlayerLayer else { return }
            let queue = AVQueuePlayer()
            queue.isMuted = true
            queue.preventsDisplaySleepDuringVideoPlayback = false
            looper = AVPlayerLooper(player: queue, templateItem: AVPlayerItem(url: url))
            playerLayer.videoGravity = .resizeAspect
            playerLayer.player = queue
            player = queue
        }

        func setPlaying(_ isPlaying: Bool) {
            if isPlaying { player?.play() } else { player?.pause() }
        }

        func unload() {
            player?.pause()
            looper = nil
            player = nil
            (layer as? AVPlayerLayer)?.player = nil
        }
    }
}
