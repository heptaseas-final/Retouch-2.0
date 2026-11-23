//
//  ZoomOnboardingSignals.swift
//  Retouch
//

import Observation
import SwiftUI

protocol OnboardingSignalSource: AnyObject {
    var onSignal: ((OnboardingTrigger) -> Void)? { get set }
}

@Observable
final class ZoomOnboardingSignals: OnboardingSignalSource {
    @ObservationIgnored var onSignal: ((OnboardingTrigger) -> Void)?
    private let zoomedInRatio: CGFloat = 0.8

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

    func setOverallOnly(_ isOn: Bool) {
        zoom.setOverallOnly(isOn)
    }

    func setLightMode(_ mode: LightMode) {
        lighting.setLightMode(mode)
    }

    func resetToDefaults() {
        zoom.setOverallOnly(false)
        zoom.setGestureEnabled(true)
        lighting.setAuto(true)
    }

    private func handle(_ tracking: ZoomTracking, _ zoom: ZoomState) {
        guard tracking.target != .fullFace, tracking.target != .overall else {
            didSendHandNearEye = false
            didSendZoomedIn = false
            return
        }
        if !didSendHandNearEye {
            didSendHandNearEye = true
            onSignal?(.handNearEye)
        }
        if !didSendZoomedIn, zoom.scale >= tracking.target.zoomScale * zoomedInRatio {
            didSendZoomedIn = true
            onSignal?(.zoomedIn)
        }
    }
}
