//
//  ZoomStoreTests.swift
//  Retouch
//
//  Created by Davin P on 18/11/26.
//

import Observation
import Testing
@testable import Retouch

private final class ChangeFlag: @unchecked Sendable {
    var didChange = false
}

@MainActor
struct ZoomStoreTests {
    @Test func targetStartsAtFullFace() {
        #expect(ZoomStore().target == .fullFace)
    }

    @Test func trackingUpdateSetsTarget() {
        let store = ZoomStore()
        store.update(ZoomTracking(target: .lips))
        #expect(store.target == .lips)
        #expect(store.tracking.target == .lips)
    }

    @Test func sameTargetDoesNotNotifyObservers() {
        let store = ZoomStore()
        let flag = ChangeFlag()
        withObservationTracking { _ = store.target } onChange: { flag.didChange = true }
        store.update(ZoomTracking(target: .fullFace))
        #expect(!flag.didChange)
    }

    @Test func newTargetNotifiesObservers() {
        let store = ZoomStore()
        let flag = ChangeFlag()
        withObservationTracking { _ = store.target } onChange: { flag.didChange = true }
        store.update(ZoomTracking(target: .nose))
        #expect(flag.didChange)
    }

    @Test func listenersStillReceiveEveryTrackingUpdate() {
        let store = ZoomStore()
        var count = 0
        store.addTrackingListener { _, _ in count += 1 }
        store.update(ZoomTracking(target: .lips))
        store.update(ZoomTracking(target: .lips))
        #expect(count == 2)
    }
}
