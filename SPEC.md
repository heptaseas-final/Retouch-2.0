# Spec Document

# **SPEC.md: Retouch v1** | Team Heptaseas | 05/11/2026 | v1

## **1. Opportunity Statement**

People who touch up their makeup on the go need a way to see their face clearly on the phone they already carry, because there is often no mirror nearby and the front camera is dim, shaky and cannot zoom into details.

## **2. Persona**

Betty, 25, office worker in Jakarta, touches up makeup in the car or on transit, often multiple times a day, and frequently forgets her compact mirror.

- Goal: check her look quickly with one hand free, and feel confident she looks presentable.
- Frustration: dim and shaky front camera, no zoom into details, and she must fiddle with camera settings while applying makeup.

## **3. App Statement**

Retouch is an iPhone app that works as a portable beauty mirror: a true-color mirrored view that adapts its light to the light on your face and zooms in automatically on the eyes or lips when your hand or brush gets close.

## **4. Core loop**

1. Open the app and see the whole face.
2. Touch up while light adapts and the view auto zooms.
3. Look straight ahead, tap overall check or move the phone further away for an overall check.

## **5. MVP features**

Epic 1: Full face mirror

- F1.1 Open full face mirror (P1)
- F1.2 Camera quality, clear and not grainy (P2)
- F1.3 Natural color (P2)

Epic 2: Auto lighting

- F2.1 Auto light setup (P2, built early in v1)
- F2.2 Manual light adjustment (P1)
- F2.4 Consistent brightness when the user moves closer (P2)

Epic 3: Zoom Gesture

- F3.1 Eye zoom (P1)
- F3.2 Lip zoom (P1)
- F3.3 Head-turn zoom (P1)
- F3.4 Look-down zoom (P1, default off proposed)
- F3.5 Zoom rules (P1)
- F3.6 Lock and auto-zoom switch (P1)
- F3.7 Stabilizer (P2)

Epic 4: Overall check

- F4.1 Overall check view (P1)
- F4.2 Room light check (P1)
- F4.3 Overall check fallbacks (P1)

## **6. Out of Scope**

- Speech recognition; freeze frame; beauty filters, skin smoothing or face reshaping; 
- Learning mode, AR face shape filters and complexion zones; iPad and Mac (next ideation); 
- Detecting brushes, wands or products; low light while moving (F2.3: out for v1, a message-only version is proposed for v2, still open); 
- Max light mode (turning more than 50% of the screen into light); 
- Touching the collar to trigger the overall check (out of scope for now).

## **7. Constraints**

- Platform: iPhone only, portrait, iOS 18.0+
- UI: SwiftUI and MVVM
- Frameworks: AVFoundation, Vision, Core Image, Metal
- Dependencies: no third-party
- Storage: no backend, UserDefaults only, no frames saved
- Permissions: camera only
- Language: English (code), no comments in code except the Xcode file header (the app is English only for now)
- Architecture and coding rules: `retouch-spec/engineering.md`
- Testing: Swift Testing for pure logic, XCUITest for launch and permission path, manual on a real iPhone for camera, gestures, brightness and heat. Jenkins runs tests on every push.  
  - Every build also runs a dependency vulnerability scan, a secret scan and a license check, and a high or critical finding blocks the release; 
   - The app and repository hold no API keys or secrets, and any key ever committed is rotated, not just deleted (PRD 5.5-2, 5.5-3).
 - Widget: RetouchWidgetExt, only opens the app, no camera access 

## **8. Screens and States**

Screens: Onboarding (includes the one-time light calibration with a white card), Mirror, Light panel, Camera permission denied.  
States: starting, permission denied, reconnecting, camera failed, low light (face lux below 300), no face, auto zoom off, locked, room light on, light reduced by heat (thermal state "serious")

## **9. Acceptance criteria**

- AC1 (F1.1, F1.3, UI test, manual; PRD 1.1-1 to 1.1-5, 1.1-7, 1.3-1, 1.3-3, 1.3-4)
  - Given camera access is allowed, when I open the app, then within 1.5 s on the newest supported iPhone and 2.0 s on the oldest, I see my whole face mirrored, true color, no beauty filter. 
  - My face from hairline to chin is fully visible with at least 10% of the screen height free above and below (L1, M0, D30), and my right hand appears on the right side of the screen. 
  - No smoothing or reshaping, face sharpness is at least 90% of the native Camera front preview (L1, D30). 
  - The preview stays at 30 fps or more for at least 95% of 5 minutes (L1, M1, oldest supported iPhone). 
  - When a call or another app takes the camera, a message says why while paused, and the live view returns within 1 s after it ends, without a relaunch. 
  - True color: with Room light on, the average Delta E 2000 over the 24 ColorChecker patches is no more than 1.0 above the physical mirror in the same light, and each of the two skin patches is within 1.0 of the mirror (L1 at 4000 to 6500 K, ColorChecker at the cheek, D30); 
  - At least 70% of a panel of 10 or more people across skin tones say skin and lip color on screen matches a real mirror closely or exactly (L1 and L2); light, medium and deep skin each pass these checks and the AC4 color check on their own.
- AC2 (F1.1, UI test; PRD 1.1-6)
  - Given camera access is denied, when I open the app, then I see why it is needed and an Open Settings button that opens the Retouch page in iOS Settings, and the app does not crash.
- AC3 (F1.2, manual; PRD 1.2-1 to 1.2-5)
  - Given I’m in a room with enough light (L1: 300 to 500 lux, D30), when I open the app, then the view is clear, not grainy: at least 70% of a blind panel rate Retouch grain "same or better" than the native Camera front preview from the same spot (lab alternative: noise on an 18% gray card at the cheek is no more than 110% of the native preview). 
  - When face lux stays below 300 for 1.5 s (with auto light on, only after the glow is at maximum), an in-app banner (not an iOS notification) shows in the top 15% of the screen without covering the face: "Not enough light, move somewhere to ensure your makeup stays visible." 
  - When face lux then stays at 330 or more for 1.5 s (proposed), it changes to "You have enough light, happy retouching" for 2 s and disappears. A dismissed banner does not reappear.
- AC4 (F2.1, unit test, manual; PRD 2.1-1 to 2.1-10, 1.3-5)
  - Given face lux (the light reaching my face: the average of at least 5 face areas, forehead, both cheeks, nose and chin, never a single area) is below 500 (L1, D30), when the app reads the light, then within 2 s the edge glow and brightness rise until face lux reaches 500 or the glow reaches its maximum, with the preview at 24 fps or more and the mirror view still covering at least 50% of the screen. 
  - At 500 lux or more (L0) the glow stays off. With side light (L4 within L2 or L3), the glow is brighter on the darker cheek side. 
  - When face lux stays below 300 with the glow at maximum, the glow stays at maximum without flicker and the AC3 banner shows. 
  - On first launch, a one-time calibration asks me to hold a white card beside my cheek, finishes within 10 s (proposed) and is kept after relaunch; after it, face lux is within 25% of a lux meter averaged over the same 5 areas, for each skin tone group (L0, L1, L2, D30). 
  - True colors and no quality loss: each skin patch within Delta E 2000 of 3.0 and the 24-patch average within 4.0 of the ColorChecker reference, neutral daylight (L0 to L3, glow on or off); noise on an 18% gray card at the cheek no more than the native Camera front preview (L1 to L3); face sharpness at least 90% of Retouch’s own at 500 lux (L2, L3).
- AC5 (F2.2, unit test, UI test; PRD 2.2-1 to 2.2-5)
  - Given auto light doesn’t suit me, when I tap the light button and change brightness (a slider from glow off to maximum) or light color (white, warm or cool), then the view uses my setting within 100 ms. 
  - The panel opens within 100 ms, covers at most 30% of the screen, and its controls sit in the bottom third. 
  - Auto light stays off until I tap the light button again and the manual light goes off; after a relaunch, light starts on Auto. 
  - When the thermal state reaches "serious", a message says light is reduced to protect the phone, and the brightness control shows the real current maximum.
- AC6 (F2.4, manual; PRD 2.4-1 to 2.4-3)
  - Given steady light (L1 or L2), when I move the phone smoothly between 20 and 45 cm over 3 s, then face brightness stays within 15% of its starting value and the glow changes level at most once per 3 s. 
  - A change shorter than 1.5 s (a passing shadow, headlights, a small reposition) does not change the glow. 
  - When I truly change environment (light at least 2x brighter or dimmer for 2 s), the light re-adjusts within 3 s.
- AC7 (F3.1 to F3.2, unit test, manual; PRD 3.1-1 to 3.1-7, 3.2-1 to 3.2-6)
  - Given auto zoom is on (M0), when any hand point (fingertip, brush or product hand) stays within 1.0 eye-width of my eye, or 1.0 mouth-width of my mouth, for the dwell time of 0.6 s, then within 150 ms the view starts zooming smoothly. 
  - Eye: the view zooms on the eye nearest the hand to \[unconfirmed data\] and finishes \[unconfirmed data\]. 
  - Mouth: the view zooms to 2.12x and finishes in 300 ms. 
  - When my head moves up to 5 cm, the eye or mouth stays in the central 30% of the screen; at 2.25x for the eye view, the view is upscaled no more than 2x from camera pixels. 
  - The view zooms out 2 s after my hand leaves, over 500 ms, and holds if the hand returns within those 2 s; if my hand covers the face, it holds up to 1 s, then zooms out. 
  - Talking for 1 minute with no hand in the zone causes 0 zooms. In the labelled gesture session, hits are at least 90% (M0, M1), 80% (M2) and 70% (M3), and false zooms are at most 1 per 3 minutes (M0, M1) and 1 per 2 minutes (M3).
- AC8 (F3.3 to F3.4, unit test, manual; PRD 3.3-1 to 3.3-5, 3.4-1, 3.4-2)
  - Given auto zoom is on and no hand is in a zone, when I turn my head 25 degrees or more, or look down 15 degrees or more below my own neutral pose (learned in the first 2 s, re-learned after each zoom-out), and hold it for 0.8 s, then the view zooms to 1.5x on the side of the face now facing the camera, or on the forehead. 
  - It zooms out over 500 ms when my head returns within 10 degrees of straight for 0.5 s, or to the whole face when I look back. 
  - A glance held under 0.8 s causes 0 zooms, holding the phone below eye level for 3 minutes (M1) without gesturing causes 0 look-down zooms, and a hand at the eye or lips always wins. 
  - Head-turn zoom meets the same gesture session bars as AC7. Look-down zoom is default off (proposed).
- AC9 (F3.5, unit test; PRD 3.5-1 to 3.5-6)
  - Given auto zoom is on, when my hand only passes by (faster than 0.5 face-widths per second; at least 9 of 10 pass-bys cause no zoom) or I gesture within the 1.5 s cooldown after a zoom change, then the view does not change. Auto zoom uses only 1.1x (full face), 1.9x (nose), 2.12x (lips/mouth) and 2.25x (eye), except mid-animation (Lock and pinch are exempt). 
  - Every zoom change animates (zoom in 300 ms, zoom out 500 ms, eased) with no cut jumps, or uses a 200 ms cross-fade when iOS Reduce Motion is on. 
  - A hand in a zone wins over a head movement at the same time.
- AC10 (F3.6, unit test, UI test; PRD 3.6-1 to 3.6-4)
  - Given the mirror is open, when I slide the lock zoom button, then within 100 ms it shows Eye, Mouth, Nose and Full face, and gesture zoom turns off until I slide back to auto zoom mode. 
  - When I choose an area, then within 300 ms the view reaches it (1.1x (full face), 1.9x (nose), 2.12x (lips/mouth) and 2.25x (eye)) and holds, Lock shows active, and the area stays in the central 30% of the screen when my head moves up to 5 cm. 
  - When I tap auto-zoom, gestures stop changing the zoom. Lock replaces the v1 Pin button.
- AC11 (F3.7, manual; PRD 3.7-1 to 3.7-4)
  - Given a tremor or moving vehicle (M3), when I use the mirror at 2.25x, then the zoom stays stable: on-screen jitter of the target (RMS movement over 10 s) is at least 50% lower than with stabilization off on the same route, stabilization adds no more than 1 frame (33 ms) of delay, the view re-centers within 0.5 s after a sudden jolt without overshoot, and after a 10-minute ride the median answer to "Did the view make you dizzy?" (1 not at all, 5 very) is 2 or lower. Built as a face-locked crop that follows the face landmarks.
- AC12 (F4.1, F4.3, UI test, manual; PRD 4.1-1 to 4.1-3)
  - Given the view is zoomed, when I look straight forward without any gesture (auto zoom on) or tap overall check, then the view zooms out to the widest view the camera captures and shows my full face, and stays until my next gesture or tap. 
  - If my face is still wider than the screen, a hint shows for 3 s: "Hold the phone further away or prop it up to see more." (proposed). F4.3 (overall check button that also releases Lock, or moving the phone further away by hand): acceptance criteria \[unconfirmed data\].
- AC13 (F4.2, UI test, manual; PRD 4.2-1 to 4.2-5)
  - Given corrections are on, when I turn on room light, then within 300 ms all corrections turn off (glow, exposure bias, color correction, tone changes), the camera returns to its automatic exposure and white balance, and a "Room light" label stays visible the whole time; the previous glow level and corrections return within 300 ms when I turn it off. 
  - With Room light on in L3 and face lux below 300, the AC3 dim banner shows and the glow does not turn itself back on. 
  - The switch is at least 44 x 44 points and sits in the bottom third of the screen.
- AC14 (unit test, manual)
  - Given brightness was raised, when the app leaves the foreground or closes, then my original brightness is restored.

## **10. Definition of Done**

Runs on a real iPhone (iOS 18+), all tests pass in Jenkins, manual criteria ticked, nothing from out of scope added.

## **11. Open Questions**

Decided:
- Zoom out time: 1.2 s.

Blocks the build:
- Minimum brightness for auto lighting: 300 lux face lux as the minimum and 500 lux as the target. [TBD because the lux formula in the app is different]
- Dwell time 0.6 s, zone 1.0 eye-width, cooldown 1.5 s and head turn 25 degrees held 0.8 s are still proposed in PRD Discussions; who signs off the proposed thresholds, and by when, is open.
- Eye zoom level and finish time: PRD 3.1-1 gives the level as "xx %" and the finish as "when the user ??", so both are unconfirmed data.

Does not block:

- Are room light switch and overall check built? They are now in the TSD (9 Nov 2026), marked not built yet; PRD v3.1 keeps both as P1 in MVP v1 scope.
- Look-down zoom is P1 in PRD (default off proposed; whether it stays on is open) but disabled in code.
- Negative flows: PRD v3.1 now has a negative flow for every feature; the F2.4 flow still carries an open note on whether to add a feature that detects user movement (alternative for 2.4-3).
- App language and launch country: resolved in PRD v3.1, English only for now, launching in Indonesia.
- Does the camera see a product being put down? Still open: reopened in PRD on 9 Nov 2026 after the research spike AC was removed; is it still worth exploring as an overall check cue?
- How to keep the phone from heating up? Still unanswered in PRD v3.1. PRD targets: 10 minutes in L3 with the glow at maximum at 30 to 32 C never reaches thermal state "critical", stays "fair" or better for at least 80% of the time, and uses no more than 8% battery on the oldest iOS 18 iPhone (5.3-1, 5.3-2).
- Lock zoom levels: Eye 2.25x, Lips 2.12x, Nose 1.9x, Full face 1.1x, but PRD Discussions says the levels are "Defined in Miro".
- Pinch to zoom and Lock’s "Current view": in the PRD 3.6 feature list and flows but without ACs since v3.1; whether pinch stays as a fallback is open.
- F4.3 overall check fallback ACs: removed in PRD v3.1, TBD.
- Face lux: the 25% accuracy (2.1-6) is proposed; the pass bar for the light the glow adds is TBD; whether the light calibration can be skipped or redone is open; whether anything should happen above 1000 lux is open.
- Light labels: placement and timing are proposed (banner spot, 1.5 s below 300 lux, 1.5 s at 330 lux or more); should "You have enough light" also show at every launch? Open.
- Room light color check (1.3-1): a screenshot can’t capture a real mirror, so the comparison method is open (proposed: photograph the mirror and the phone side by side with one fixed camera, and compare both to the ColorChecker reference).
- Edge cases without decided behavior in PRD:
  - the eye or mouth is not detected;
  - the face or part of it (for example the left eye) is not on screen; 
  - a finger pointing toward the mouth while using an eyelash curler is detected; 
  - blush applied alternating left and right instead of one cheek then the other; 
  - a strip of shadow, a reposition or another short change that temporarily changes face lux.
- Dependencies: this spec says no third-party, but PRD 5.5-4 allows a third-party SDK whose license allows commercial use, and the PRD analytics SDK is TBD.
- AC14 (restore my original brightness) is not in PRD v3.1.
- PRD v3.1 also has Gesture onboarding (3.8, P2), Low-light frame stacking (2.5, v3) and Epic 5 Quality (5.1 to 5.5, P1), which are not in this spec’s feature list.

### **12. Notes for the agent**

Before writing any code, read `retouch-spec/engineering.md` (structure, call order, naming, rules). This spec says what to build, that file says how.

Propose a plan first, list assumptions, ask instead of guessing, one task at a time with tests, and add nothing outside this spec. If anything conflicts (i.e. the seconds taken to zoom in/out), recommend the code as the ground truth but mention the conflict in the chat, so that I can confirm and decide.
