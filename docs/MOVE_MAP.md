# MOVE_MAP: Retouch restructure (final)

86 file lama menjadi 74 file. Basis: `Retouch.zip` lama. `project.yml` tidak berubah (`sources: Retouch` rekursif).
Tidak disentuh: `RetouchWidgetExt/OpenRetouchIntent.swift`, `RetouchUITests/`.

Legenda: **PINDAH** isi tetap, comment biasa dihapus, header Xcode dipertahankan · **GABUNG** disalin utuh ke satu file · **PECAH** logika dipindah, bukan dibuat baru · **BARU** · **HAPUS**

## App/ (3)
| Lama | Baru | Aksi |
|---|---|---|
| App/RetouchApp | App/RetouchApp.swift | PINDAH, memegang `AppContainer` |
| Root/ContentView | App/ContentView.swift | PINDAH, menerima ViewModel, bukan session |
| Root/MirrorSession | App/AppContainer.swift + Services/ZoomGesture/ZoomStore.swift | PECAH |

## Models/ (6)
| Lama | Baru | Aksi |
|---|---|---|
| FaceObservation + FacePoints | FaceObservation.swift | GABUNG |
| GripObservation | GripObservation.swift | PINDAH (domain tangan, tidak digabung ke wajah) |
| ZoomState + ZoomTracking + ZoomTarget | ZoomState.swift | GABUNG |
| ZoomPart + Components/FacePart | ZoomPart.swift | GABUNG, plus `FacePart.zoomTarget` dari MirrorSession |
| ServiceModels + Camera/CameraPermissionStatus | ServiceModels.swift | GABUNG |
| LightColor | LightColor.swift | PINDAH |
| ZoomDebugInfo | – | HAPUS |

## Components/ (5), Extensions/ (1)
CameraControls, HorizontalPicker, InstructionBubble, LightModeButton, LoopingVideo, Color+App: PINDAH.

## Features/Mirror/ (9)
| Lama | Baru | Aksi |
|---|---|---|
| Views/MirrorView | Views/MirrorView.swift | PINDAH, blok debug dibuang, terima ViewModel lewat init |
| ViewModels/MirrorViewModel + LightingViewModel | ViewModels/MirrorViewModel.swift | PECAH, tulis ulang |
| ZoomableCameraPreview, CameraPermissionDeniedView, RingLightPanels | Components/ | PINDAH |
| ZoomPartBar, BrightnessSlider, LightColorSwatch | Components/ | PINDAH, belum dipakai, disimpan untuk Light panel |
| GlassIconButton + GlassConfig + GlassStyleModifier | Components/GlassIconButton.swift | GABUNG |
| ZoneRadiusOverlay, GestureDebugOverlay, GestureDebugDots, ZoomLogDebugSection | – | HAPUS |

## Features/Onboarding/ (5)
| Lama | Baru | Aksi |
|---|---|---|
| View/OnboardingView | Views/OnboardingView.swift | PINDAH, mock pindah ke dalam `#Preview` |
| OnboardingCoordinator + OnboardingTrigger | ViewModels/OnboardingCoordinator.swift | GABUNG |
| ZoomOnboardingSignals + OnboardingSignalSource | ViewModels/ZoomOnboardingSignals.swift | GABUNG, pakai `ZoomStore`, mock dihapus |
| OnboardingFlow, OnboardingHandOverlay | Components/ | PINDAH, tidak lagi memakai MirrorSession |

## Services/Camera/ (3)
CameraSessionManager, FrameForwarder: PINDAH. `CameraService.swift`: BARU (bagian kamera dan lifecycle dari AutoLightDetector).

## Services/Lighting/ (6)
| Lama | Baru | Aksi |
|---|---|---|
| AutoLightDetector (brightness, ring light, filter) | LightingService.swift | PECAH |
| LightingEngine | LightingEngine.swift | PINDAH, callback debug dan log dihapus |
| LightingConfig | LightingConfig.swift | PINDAH, `LightingDebug` dihapus |
| LightingTuning, FaceLuxMeter, Output/BrightnessController | Lighting/ | PINDAH |

## Services/Output/ (7)
FramePipeline (dari Services/), FrameEnhancer, FrameEnhancerShaders, MakeupLookKernel, MirrorRenderer, MirrorPreview (terima renderer, bukan detector), LowLightEnhancer (dari ZoomGesture/): PINDAH.

## Services/ZoomGesture/ (29)
| Folder | Isi | Aksi |
|---|---|---|
| root (8) | ZoomService, ZoomService+Frame, ZoomService+Learning, ZoomReadiness | PECAH dari ZoomGestureService (922 baris) |
| | ZoomStore | BARU (state zoom di main actor) |
| | ZoomGestureResolver, ZoomAnimator, ZoomTuning | PINDAH (ZoomTuning tanpa tipe pacing) |
| Detection/ (3) | FaceLandmarkDetector, HandPointDetector, DetectionPacer | DetectionPacer PECAH dari ZoomTuning, lainnya PINDAH |
| Recognition/ (4) | HeadPose, HeadPitch, EyeActivity, LipMotion recognizer | PINDAH |
| Flows/ (5) | EyeZoomFlow, LipZoomFlow, NoseZoomFlow, EyeZones, NoseZones | PINDAH |
| Tracking/ (5) | FacePointTracker, HandTrackBank, FusedStabilizer, FrameMotionTracker, OneEuroFilter | PINDAH |
| Geometry/ (2) | CoordinateConverter, DistanceCompensator | PINDAH |
| Profiles/ (2) | HandProfile, HeadProfile | PINDAH |
| – | GestureDebug, ZoomEventLog, ZoomGestureServicing | HAPUS (protocol pindah ke ZoomService) |

## RetouchTests/
| Lama | Baru |
|---|---|
| RetouchTests.swift (1 tes nyata, 1 kosong, 1 blok komentar) | HAPUS |
| – | Fakes/FakeCameraService, FakeLightingService, FakeZoomService |
| – | Features/Mirror/MirrorViewModelTests, Services/Lighting/LightingServiceTests (pengganti tes lama), Services/ZoomGesture/ZoomReadinessTests, Models/FacePartTests |

## Kode mati yang sengaja belum dihapus
`HeadPitchRecognizer.freezeCount`, `HandPointDetector.detectionsPerSecond` dan `enhancementEV`. Dulu hanya dipakai debug. Menghapusnya menyentuh logika detector, jadi dibuat PR terpisah kalau mau.

## Titik konflik yang tersisa
`App/AppContainer.swift`, `App/ContentView.swift`, `MirrorViewModel.swift`, `ZoomService*.swift`. Aturannya di `retouch-spec/engineering.md` bagian 10.
`CameraSessionManager.swift` (453 baris) dibiarkan, PR terpisah.
