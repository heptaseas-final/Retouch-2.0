//
//  SplashVideo.swift
//  Retouch
//
//  Created by Gabriella Angelina Widjaja on 15/11/26.
//


import AVFoundation
import SwiftUI

struct SplashVideo: UIViewRepresentable {
    let name: String
    var fileExtension = "mov"
    var isStill = false
    var onEnd: () -> Void = {}

    private let stillOffset = CMTime(value: 1, timescale: 30)

    func makeUIView(context: Context) -> LoopingVideo.PlayerView {
        let view = LoopingVideo.PlayerView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        view.playerLayer.videoGravity = .resizeAspectFill

        guard let url = Bundle.main.url(forResource: name, withExtension: fileExtension) else {
            Task { @MainActor in onEnd() }
            return view
        }
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.isMuted = true
        player.preventsDisplaySleepDuringVideoPlayback = false
        view.playerLayer.player = player

        if isStill {
            Task { @MainActor in
                let duration = (try? await item.asset.load(.duration)) ?? .zero
                await player.seek(to: max(duration - stillOffset, .zero), toleranceBefore: .zero, toleranceAfter: .zero)
            }
        } else {
            context.coordinator.endObserver = NotificationCenter.default.addObserver(
                forName: AVPlayerItem.didPlayToEndTimeNotification, object: item, queue: .main
            ) { _ in onEnd() }
            player.play()
        }
        return view
    }

    func updateUIView(_ view: LoopingVideo.PlayerView, context: Context) {}

    static func dismantleUIView(_ view: LoopingVideo.PlayerView, coordinator: Coordinator) {
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
}