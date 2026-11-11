# Retouch engineering rules

Version: 1
Scope: all Swift code in `Retouch/` and `RetouchTests/`.
Precedence: SPEC.md (product) first, then this file, then general Swift defaults. Where this file conflicts with general guidance (comments, one type per file), this file wins.

## 1. Fixed constraints (from SPEC.md)

- iPhone, portrait, iOS 18.0+, SwiftUI, MVVM.
- AVFoundation, Vision, Core Image, Metal. No third-party dependency.
- UserDefaults only. No backend. Frames are never saved. Camera permission only.
- Build settings: default actor isolation is MainActor, Swift language mode 5.0. Do not change build settings or `project.yml` without asking.
- English identifiers and user-facing text. No comments (section 4).

## 2. Layers and the only call path

```
View -> ViewModel -> Service (protocol) -> Models
```

- View: layout and bindings. Calls ViewModel methods. Never touches a service, the container, or UserDefaults.
- ViewModel: one per screen, `@Observable final class`. Holds screen state, calls services. Gets services and shared stores through `init` as protocols.
- Service: camera, lighting, zoom, rendering. Protocol first. Heavy work off the main actor.
- Model: plain structs and enums. No UI, no services.
- Dependencies point one way. A lower layer never references a higher one.

Frame flow (off the main actor):
```
CameraSessionManager -> FramePipeline -+-> FrameForwarder -> ZoomService
                                       +-> LightingEngine -> Renderer
```
Result flow: `ZoomService -> ZoomStore (@Observable, main actor) -> ViewModel -> View`.

Wiring: `AppContainer` is the only place that creates services and stores, in dependency order (camera, lighting, pipeline, zoom). It also builds the ViewModels. Views receive their ViewModel through `init`. No `@Environment` for services.

## 3. Folder map and where things go

```
Retouch/
  App/                 RetouchApp, AppContainer, ContentView
  Models/              plain data types used by more than one layer
  Components/          UI used by 2+ features
  Extensions/          Color+App
  Features/
    Mirror/            Views/ ViewModels/ Components/
    Onboarding/        Views/ ViewModels/ Components/
  Services/
    Camera/ Lighting/ Output/
    ZoomGesture/       Detection/ Recognition/ Flows/ Tracking/ Geometry/ Profiles/
  Resources/
RetouchTests/          mirrors Retouch/, plus Fakes/
RetouchUITests/        launch and permission path only
RetouchWidgetExt/      outside this structure
```

Where does it go?

| I am adding | Put it in |
|---|---|
| Screen | `Features/<Feature>/Views/` |
| Screen state and logic | `Features/<Feature>/ViewModels/` |
| UI piece used by one feature | `Features/<Feature>/Components/` |
| UI piece used by 2+ features | `Components/` |
| Plain data type | `Models/` |
| Camera, light, zoom, render logic | `Services/<Domain>/` |
| Tuning numbers | the domain's `*Config` or `*Tuning` file |
| Persisted setting | a `*Store` type next to its service |
| Anything unclear | ask, do not create a new folder |

## 4. File rules

- One file, one responsibility, one primary type. File name equals the primary type name.
- Companion types may share the file: its Store, protocol, enum, view modifier, or small plain data types of the same domain without logic.
- Maximum 300 lines per file. Maximum 8 files per folder, then add a subfolder.
- No top-level folders beyond section 3. No `Helpers`, `Utils`, `Misc`, `Common`.
- No comments of any kind: no `//`, `///`, `/* */`, file headers, `MARK`, `TODO`, commented-out code. Names must explain the code.
- `#Preview` is allowed and uses inline sample data.

## 5. Naming

| Kind | Name |
|---|---|
| View | `<Name>View` in `Views/`. Components use plain nouns, e.g. `ZoomPartBar` |
| ViewModel | `<Name>ViewModel`. `OnboardingCoordinator` is the one allowed exception for a flow state machine |
| Service protocol / implementation | `<Name>Servicing` / `<Name>Service` |
| Constants | `<Name>Config` or `<Name>Tuning` |
| UserDefaults wrapper | `<Name>Store` |
| Tests / fakes | `<Type>Tests` / `Fake<Type>` |

## 6. Concurrency

- Default isolation is MainActor. Do not add `@MainActor` to Views or ViewModels.
- Per-frame or heavy work (camera, Vision, Metal, trackers, recognizers, flows, resolver, filters, geometry) is `nonisolated` or an actor. Protocols used by such types are `nonisolated` too.
- Hop to the main actor only to publish state to a store or ViewModel.
- Use async/await and `Task.sleep(for:)`. No `DispatchQueue` in new code. Only the existing AVFoundation capture queues in `CameraSessionManager` keep GCD.
- Cancel tasks on disappear. Use `[weak self]` in tasks that outlive their owner.
- Per frame: no new allocations, drop frames when behind.

## 7. Dependency injection

- Services and stores are created only in `AppContainer`.
- A ViewModel takes protocols in `init`. A View never creates a ViewModel's dependencies.
- No singletons, no `.shared`, no global mutable state.
- A service never creates another service. It receives it in `init`.

## 8. Config and storage

- Tuning numbers live only in `LightingConfig`, `ZoomTuning`, `GlassConfig` or a new `<Domain>Config`. Never inline a magic number elsewhere.
- UserDefaults is touched only inside `*Store` types.

## 9. Tests

- Swift Testing. Test structs that touch ViewModels are `@MainActor`.
- ViewModels are tested with `Fake<Protocol>` types in `RetouchTests/Fakes/`. Fakes and mocks never live in production code.
- Changing zoom, lighting or other pure logic requires a test for the change.
- XCUITest only for launch and the permission path.
- Camera, gestures, brightness and heat are checked manually on a real iPhone. Say so in the report. Never claim something was verified when it was not.

## 10. Conflict rules

Hotspots (everyone edits them, so edit minimally):

| File | Rule |
|---|---|
| `App/AppContainer.swift` | Append-only: one line per service, one factory method per ViewModel. Never reorder. Ask who owns it |
| `App/ContentView.swift` | Append-only: one route per feature |
| `Features/Mirror/ViewModels/MirrorViewModel.swift` | Smallest diff. If it passes 300 lines, propose a split |
| `Services/ZoomGesture/ZoomService.swift` | Smallest diff. New behavior goes in its own file |
| `*Config.swift`, `ZoomTuning.swift` | State old and new value and which acceptance criterion it affects |
| `project.yml`, build settings | Do not edit without asking |

- A new feature touches only its own folder, one line in `AppContainer`, and one route in `ContentView`.
- Do not reformat, rename, reorder or move code you are not changing. No whole-file rewrites to change a few lines.
- If someone else may be editing the same file, ask before starting.
- One task, one branch, one small PR. Moves and logic changes never share a commit. After a structural merge everyone pulls and rebases.

## 11. How the agent works

1. Ask for the files you need (SKILL.md, step 1). Do not guess.
2. Classify the task and read the matching playbook.
3. Send a short plan: full file paths, assumptions, open questions. Wait for approval.
4. Implement only what was approved.
5. Run the self-check (section 14).
6. Report: files changed, what was not verified, what to check on a real iPhone.

## 12. Forbidden

- New top-level folders, generic helper folders.
- Singletons, `.shared`, global mutable state.
- A View or ViewModel creating a service. A service touching a View or ViewModel.
- A feature importing another feature.
- `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject`.
- `DispatchQueue` in new code, `Task.sleep(nanoseconds:)`.
- Comments of any kind, commented-out code.
- Third-party packages, new permissions, saving frames, backend calls.
- Debug overlays, log screens, mock types in production code.
- Force unwrap and force `try`.
- Editing `project.yml`, build settings, or `RetouchWidgetExt/OpenRetouchIntent.swift` (shared with the app target, do not move or rename).
- Fixing unrelated issues inside the same change.

## 13. Known exceptions

- `Services/Camera/CameraSessionManager.swift` is 453 lines. Do not add code to it. Extra camera behavior goes in `CameraService` or a new file. A split is planned as its own PR.
- The widget target is outside this structure.

## 14. Self-check before answering

1. Is every new file in the folder the placement table says?
2. One responsibility and one primary type per file, under 300 lines?
3. Call path respected: View, ViewModel, Service, Model?
4. Dependencies injected through `init`, created only in `AppContainer`?
5. Heavy or per-frame work off the main actor?
6. No magic numbers, no comments, no forbidden items?
7. Only files the task needs were touched?
8. Tests added or updated for logic and ViewModels?
9. Report lists what was not verified?
