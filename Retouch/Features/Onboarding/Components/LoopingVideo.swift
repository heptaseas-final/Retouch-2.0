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
    var loops = true
    var onEnd: (() -> Void)?

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
        player.actionAtItemEnd = loops ? .none : .pause
        let coordinator = context.coordinator
        coordinator.onEnd = onEnd
        coordinator.endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification, object: item, queue: .main
        ) { [weak player, loops] _ in
            guard loops else {
                coordinator.onEnd?()
                return
            }
            player?.seek(to: .zero)
            player?.play()
        }
        view.playerLayer.player = player
        if !loops, !isPlaying { showLastFrame(of: player) }
        return view
    }

    private func showLastFrame(of player: AVPlayer) {
        guard let asset = player.currentItem?.asset else { return }
        Task { @MainActor in
            guard let duration = try? await asset.load(.duration) else { return }
            await player.seek(to: duration, toleranceBefore: .zero, toleranceAfter: .zero)
        }
    }

    func updateUIView(_ view: PlayerView, context: Context) {
        context.coordinator.onEnd = onEnd
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
        var onEnd: (() -> Void)?
    }

    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}
