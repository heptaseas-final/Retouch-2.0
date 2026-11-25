//
//  FaceLockInbox.swift
//  Retouch
//
//  Created by Retouch Team on 23/11/26.
//

import Foundation

nonisolated final class FaceLockInbox: @unchecked Sendable {
    private let lock = NSLock()
    private var sample: FaceLockSample?

    var latest: FaceLockSample? {
        lock.withLock { sample }
    }

    func post(_ sample: FaceLockSample?) {
        lock.withLock { self.sample = sample }
    }
}
