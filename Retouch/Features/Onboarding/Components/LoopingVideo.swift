//
//  LoopingVideo.swift
//  Retouch
//

import AVFoundation
import SwiftUI

struct LoopingVideo: UIViewRepresentable {
    let name: String
    var fileExtension = "mov"
    var isPlaying = true

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.backgroundColor = .clear
        view.isOpaque = false
        view.playerLayer.videoGravity = .resizeAspect
        view.playerLayer.pixelBufferAttributes = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

        guard let url = Bundle.main.url(forResource: name, withExtension: fileExtension) else { return view }
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.isMuted = true
        player.preventsDisplaySleepDuringVideoPlayback = false
        player.actionAtItemEnd = .none
        context.coordinator.endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification, object: item, queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ view: PlayerView, context: Context) {
        if isPlaying {
            view.playerLayer.player?.play()
        } else {
            view.playerLayer.player?.pause()
        }
    }

    static func dismantleUIView(_ view: PlayerView, coordinator: Coordinator) {
        view.playerLayer.player?.pause()
        if let observer = coordinator.endObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        coordinator.endObserver = nil
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var endObserver: NSObjectProtocol?
    }

    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}
