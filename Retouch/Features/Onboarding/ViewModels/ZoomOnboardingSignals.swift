//
//  ZoomOnboardingSignals.swift
//  Retouch
//

import Observation
import SwiftUI

protocol OnboardingSignalSource: AnyObject {
    var onSignal: ((OnboardingTrigger) -> Void)? { get set }
    var eyeAnchor: CGPoint? { get }
}

@Observable
final class ZoomOnboardingSignals: OnboardingSignalSource {
    @ObservationIgnored var onSignal: ((OnboardingTrigger) -> Void)?
    private(set) var eyeAnchor: CGPoint? = ZoomOnboardingSignals.defaultEyeAnchor
    static let defaultEyeAnchor = CGPoint(x: 0.62, y: 0.38)
    private let zoomedInScale: CGFloat = 1.8

    @ObservationIgnored private let store: ZoomStore
    @ObservationIgnored private let zoom: ZoomServicing
    @ObservationIgnored private let lighting: LightingServicing
    @ObservationIgnored private var listener: UUID?
    @ObservationIgnored private var didSendHandNearEye = false
    @ObservationIgnored private var didSendZoomedIn = false

    init(store: ZoomStore, zoom: ZoomServicing, lighting: LightingServicing) {
        self.store = store
        self.zoom = zoom
        self.lighting = lighting
    }

    func connect() {
        guard listener == nil else { return }
        didSendHandNearEye = false
        didSendZoomedIn = false
        listener = store.addTrackingListener { [weak self] tracking, zoom in
            self?.handle(tracking, zoom)
        }
    }

    func disconnect() {
        if let listener { store.removeTrackingListener(listener) }
        listener = nil
    }

    func select(_ part: FacePart) {
        zoom.select(part)
    }

    func setLightMode(_ mode: LightMode) {
        lighting.setLightMode(mode)
    }

    func resetToDefaults() {
        zoom.setGestureEnabled(true)
        lighting.setAuto(true)
    }

    private func handle(_ tracking: ZoomTracking, _ zoom: ZoomState) {
        if let eye = Self.normalized(tracking.face.rightEye ?? tracking.face.leftEye, in: tracking.viewSize) {
            eyeAnchor = eye
        }

        let onEye = tracking.target == .leftEye || tracking.target == .rightEye
        guard onEye else {
            didSendHandNearEye = false
            didSendZoomedIn = false
            return
        }
        if !didSendHandNearEye {
            didSendHandNearEye = true
            onSignal?(.handNearEye)
        }
        if !didSendZoomedIn, zoom.scale >= zoomedInScale {
            didSendZoomedIn = true
            onSignal?(.zoomedIn)
        }
    }

    private static func normalized(_ point: CGPoint?, in size: CGSize) -> CGPoint? {
        guard let point, size.width > 0, size.height > 0 else { return nil }
        return CGPoint(x: min(max(point.x / size.width, 0), 1),
                       y: min(max(point.y / size.height, 0), 1))
    }
}
