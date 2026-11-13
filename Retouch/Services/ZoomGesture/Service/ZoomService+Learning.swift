import CoreGraphics
import Foundation

nonisolated extension ZoomService {
    func pinchChanged(_ magnification: CGFloat) {
        stateQueue.async { [self] in
            if !pinchActive {
                pinchActive = true
                pinchBase = max(animator.displayedScale, 1)
                pinchStartScale = pinchBase
                let now = Date()
                pinchStartAuto = isGestureEnabled
                    && (autoZoomSince != nil || now.timeIntervalSince(lastAutoZoomEnd) < 3)
                let sideRecent = sideZoomSince.map { now.timeIntervalSince($0) <= ZoomTuning.sideCorrectionWindow } ?? false
                let sideJustEnded = sideZoomSince == nil
                    && now.timeIntervalSince(lastSideZoomEnd) < ZoomTuning.sideCorrectionAfterEnd
                    && lastSideZoomEnd.timeIntervalSince(lastSideZoomStart) <= ZoomTuning.sideCorrectionWindow
                pinchStartSide = isGestureEnabled && !pinchStartAuto && (sideRecent || sideJustEnded)
                pinchStartIdle = isGestureEnabled && !pinchStartAuto && !pinchStartSide && pinchBase < 1.2
            }
            pinchScale = min(max(pinchBase * magnification, 1), 3)
            publish(isGestureEnabled ? resolver.target : manualTarget)
        }
    }

    func pinchEnded() {
        stateQueue.async { [self] in
            learnFromPinch(finalScale: pinchScale)
            pinchActive = false
            pinchBase = pinchScale < 1.05 ? 1 : pinchScale
            pinchScale = pinchBase
            publish(isGestureEnabled ? resolver.target : manualTarget)
        }
    }

    func learnFromPinch(finalScale: CGFloat) {
        guard isGestureEnabled, pinchStartScale > 0 else { return }
        let now = Date()
        let ratio = finalScale / pinchStartScale
        let handUnwanted = pinchStartAuto && ratio < 0.85
        let sideUnwanted = pinchStartSide && ratio < 0.85
        let missed = pinchStartIdle && ratio > 1.25

        guard handUnwanted || sideUnwanted || missed else { return }
        guard now.timeIntervalSince(lastCorrection) >= 2 else { return }

        if handUnwanted {
            handProfile.learnUnwanted()
            handBank.apply(handProfile)
        } else if sideUnwanted {
            headPose.noteUnwantedSide()
        } else {
            handProfile.learnMissed()
            handBank.apply(handProfile)
        }
        lastCorrection = now
    }

    func saveProfileIfNeeded(now: Date) {
        guard now.timeIntervalSince(lastProfileCheck) >= 10 else { return }
        lastProfileCheck = now
        if headPose.profile != savedProfile {
            savedProfile = headPose.profile
            HeadProfileStore.save(savedProfile)
        }
        if handProfile != savedHandProfile {
            savedHandProfile = handProfile
            HandProfileStore.save(handProfile)
        }
        if pitchRecognizer.profile != savedPitchProfile {
            savedPitchProfile = pitchRecognizer.profile
            PitchProfileStore.save(savedPitchProfile)
        }
    }
}
