# Spec Document 📑

# **SPEC.md: Retouch v1** | Team Heptaseas | 05/11/2026 | v1

## **1. Opportunity Statement**

People who touch up their makeup on the go need a way to see their face clearly on the phone they already carry, because there is often no mirror nearby and the front camera is dim, shaky and cannot zoom into details.

## **2. Persona**

Betty, 25, office worker in Jakarta, touches up makeup in the car or on transit and carries no compact mirror.

- Goal: check her look quickly with one hand free, and feel confident she looks presentable.
- Frustration: dim and shaky front camera, no zoom into details, and she must fiddle with camera settings while applying makeup.

## **3. App Statement**

Retouch is an iPhone app that works as a portable beauty mirror: a true-color mirrored view that adapts its light to the room and zooms in automatically on the eyes or lips when your hand or brush gets close.

## **4. Core loop**

1. Open the app and see the whole face.
2. Touch up while light adapts and the view auto zooms.
3. Step back for an overall check.

## **5. MVP features**

Epic 1: Full face mirror

- F1.1 Open full face mirror (P1)
- F1.2 Camera quality, clear and not grainy (P2)
- F1.3 Natural color (P2)

Epic 2: Auto lighting

- F2.1 Auto light setup (P2)
- F2.2 Manual light adjustment (P1)
- F2.4 Consistent brightness when the user moves closer (P2)

Epic 3: Zoom Gesture

- F3.1 Eye zoom (P1)
- F3.2 Lip zoom (P1)
- F3.3 Head-turn zoom (P1)
- F3.4 Look-down zoom (P1)
- F3.5 Zoom rules (P1)
- F3.6 Pin and auto-zoom switch (P1)
- F3.7 Stabilizer (P2)

Epic 4: Overall check

- F4.1 Overall check view (P1)
- F4.2 Room light check (P1)
- F4.3 Overall check fallbacks (P1)

## **6. Out of Scope**

Speech recognition, freeze frame, beauty filters or face reshaping, learning mode and AR face shape filters, low light while moving (F2.3), widget.

## **7. Constraints**

- Platform: iPhone only, portrait, iOS 18.0+
- UI: SwiftUI and MVVM
- Frameworks: AVFoundation, Vision, Core Image, Metal
- Dependencies: no third-party
- Storage: no backend, UserDefaults only, no frames saved
- Permissions: camera only
- Language: English (code), no comments in code
- Architecture and coding rules: `retouch-spec/engineering.md`
- Testing: Swift Testing for pure logic, XCUITest for launch and permission path, manual on a real iPhone for camera, gestures, brightness and heat. Jenkins runs tests on every push.

## **8. Screens and States**

Screens: Onboarding, Mirror, Light panel, Camera permission denied.  
States: starting, permission denied, reconnecting, camera failed, low light, no face, auto zoom off.

## **9. Acceptance criteria**

- AC1 (F1.1, UI test, manual): Given camera access is allowed, when I open the app, then I see my whole face mirrored, true color, no beauty filter.
- AC2 (F1.1, UI test): Given camera access is denied, when I open the app, then I see why it is needed and an Open Settings button, and the app does not crash.
- AC3 (F1.2, manual): Given I’m in a room with enough light \[TBD\], when I open the app, then the view is clear, not grainy.
- AC4 (F2.1, unit test, manual): Given a dark place, when the app reads the light, then edge glow and brightness rise until my face reaches the minimum brightness \[TBD\], with true colors.
- AC5 (F2.2, unit test, UI test): Given auto light doesn’t suit me, when I change brightness or warmth, then the view uses my setting.
- AC6 (F2.4, manual): Given I move closer or away, when lux changes because of my movement, then brightness stays consistent, but adapts if I truly change environment.
- AC7 (F3.1 to F3.2, unit test, manual): Given auto zoom is on, when a fingertip or brush stays near my eye or mouth for the dwell time \[TBD\], then the view zooms smoothly and zooms out after my hand leaves.
- AC8 (F3.3 to F3.4, unit test, manual): Given auto zoom is on, when I turn my head or look down and hold it, then the view zooms slightly on that side or the forehead, and a hand at the eye or lips always wins.
- AC9 (F3.5, unit test): Given auto zoom is on, when my hand only passes by or I gesture within the cooldown \[TBD\], then the view does not change.
- AC10 (F3.6, unit test, UI test): Given the view is zoomed, when I tap pin, then the zoom stays until I tap again. When I tap auto-zoom, gestures stop changing the zoom.
- AC11 (F3.7, manual): Given a tremor or moving vehicle, when I use the mirror, then the zoom stays stable.
- AC12 (F4.1, F4.3, UI test, manual): Given the view is zoomed, when I tap overall check or put the product down, then the view zooms out to the widest view, with a hint if my face still fills it.
- AC13 (F4.2, UI test, manual): Given corrections are on, when I turn on Room light, then all corrections turn off, and they return when I turn it off.
- AC14 (unit test, manual): Given brightness was raised, when the app leaves the foreground or closes, then my original brightness is restored.

## **10. Definition of Done**

Runs on a real iPhone (iOS 18+), all tests pass in Jenkins, manual criteria ticked, nothing from out of scope added.

## **11. Open Questions**

Blocks the build:

- Minimum brightness for auto lighting, dwell time, cooldown, head-turn angle.
- Zoom out time: PRD says 2 s in the feature list but 3 s in the AC, the code uses about 1.2 s.

Does not block:

- Are room light switch and overall check built? They are not in the TSD.
- Look-down zoom is P1 in PRD but disabled in code.
- Negative flows still TBD for several features.
- App language (Bahasa and English) and launch country.
- Does the camera see a product being put down?
- How to keep the phone from heating up?

### **12. Notes for the agent**

Before writing any code, read `retouch-spec/engineering.md` (structure, call order, naming, rules). This spec says what to build, that file says how.

Propose a plan first, list assumptions, ask instead of guessing, one task at a time with tests, and add nothing outside this spec. Ask for the current version of any file you will change and never guess its contents.
