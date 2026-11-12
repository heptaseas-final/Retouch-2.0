import SwiftUI

struct MirrorView: View {
    @State private var viewModel: MirrorViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var pickerSwipe = PickerSwipe()
    @State private var lightDock: LightDock
    @Environment(\.isLargerButtons) private var isLargerButtons
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lightDrag: CGSize = .zero
    @State private var isDraggingLight = false
    @State private var screenFrame: CGRect = .zero
    @State private var dockSlotCenter: CGPoint = .zero
    @State private var isPickerFullWidth = false
    @State private var dockBeforeFullWidth: LightDock?
    private let showsControls: Bool
    private let onReplayTutorial: (() -> Void)?

    private static let whiteHex: UInt32 = 0xFFFFFF

    init(viewModel: MirrorViewModel, showsControls: Bool = true, onReplayTutorial: (() -> Void)? = nil) {
        _viewModel = State(initialValue: viewModel)
        _lightDock = State(initialValue: LightDock(viewModel.lightPlacement))
        self.showsControls = showsControls
        self.onReplayTutorial = onReplayTutorial
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if viewModel.permission == .denied {
                CameraPermissionDeniedView(onOpenSettings: viewModel.openSettings)
            } else {
                ZoomableCameraPreview(viewModel: viewModel, announcesZoom: showsControls)
                RingLightPanels(level: viewModel.ringLightLevel, color: edgeColor,
                                maxSideFraction: viewModel.ringLightWidth,
                                softness: viewModel.ringLightSoftness)
                    .ignoresSafeArea()
                cameraStateOverlay
                if showsControls {
                  VStack(spacing: 12) {
                      Spacer()
                      controls
                          .transition(.opacity)
                  }
                  sideLightButton
                  settingsButton
                }
            }
        }
        .pickerSwipe(pickerSwipe, isEnabled: showsControls && viewModel.permission != .denied && !isDraggingLight)
        .sensoryFeedback(.impact(weight: .medium), trigger: lightDock)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { screenFrame = $0 }
        .animation(.easeInOut, value: showsControls)
        .task { await viewModel.start() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: viewModel.refresh()
            case .background: viewModel.stop()
            default: break
            }
        }
        .onChange(of: viewModel.cameraState) { old, new in
            viewModel.cameraStateDidChange(from: old, to: new)
            announceCameraState(new)
        }
    }

    private func announceCameraState(_ state: CameraState) {
        switch state {
        case .failed: AccessibilityNotification.Announcement("Camera is not opened").post()
        case .reconnecting: AccessibilityNotification.Announcement("Reconnecting…").post()
        default: break
        }
    }

    @ViewBuilder
    private var settingsButton: some View {
        if let onReplayTutorial {
            VStack {
                HStack {
                    Spacer()
                    SettingsMenu(isLargerButtons: Binding(get: { viewModel.isLargerButtons }, set: setLargerButtons),
                                 lightPlacement: Binding(get: { lightDock.placement }, set: chooseLightPlacement),
                                 isBottomAvailable: !isPickerFullWidth) {
                        viewModel.select(.face)
                        viewModel.setLightMode(.off)
                        onReplayTutorial()
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .transition(.opacity)
        }
    }

    private var controls: some View {
        VStack {
            Spacer()
            CameraControls(
                part: Binding(get: { viewModel.selectedPart }, set: viewModel.select),
                lightMode: Binding(get: { viewModel.lightMode }, set: viewModel.setLightMode),
                swipe: pickerSwipe,
                isLightDocked: lightDock == .docked,
                lightOffset: lightDock == .docked ? lightDrag : .zero,
                onLightLiftDrag: liftDragChanged,
                onLightLiftEnd: liftEnded,
                lightMoveActions: moveActions(from: .docked),
                onLightSlotCenter: { dockSlotCenter = $0 },
                onPickerLayoutChange: pickerLayoutChanged
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var lightButtonSize: CGFloat {
        LargerButtons.controlSize(isLarger: isLargerButtons, typeSize: typeSize)
    }
    private static let sideMargin: CGFloat = 16
    private static let dockZoneHeight: CGFloat = 120

    @ViewBuilder
    private var sideLightButton: some View {
        if case let .side(edge) = lightDock {
            GeometryReader { geo in
                let size = lightButtonSize
                let half = Self.sideMargin + size / 2
                LightModeButton(mode: Binding(get: { viewModel.lightMode }, set: viewModel.setLightMode), size: size,
                                onLiftDrag: liftDragChanged, onLiftEnd: liftEnded,
                                moveActions: moveActions(from: lightDock))
                    .frame(height: size * 3, alignment: .bottom)
                    .position(x: edge == .trailing ? geo.size.width - half : half,
                              y: geo.size.height / 2 - size)
                    .offset(lightDrag)
            }
            .transition(.identity)
        }
    }

    private func moveActions(from current: LightDock) -> [(label: String, perform: () -> Void)] {
        let targets: [(dock: LightDock, name: String)] = [(.side(edge: .leading), "left"),
                                                          (.side(edge: .trailing), "right"), (.docked, "bottom")]
        return targets
            .filter { $0.dock != current && ($0.dock != .docked || !isPickerFullWidth) }
            .map { target in ("Move to \(target.name)", { moveByVoiceOver(to: target.dock, named: target.name, from: current) }) }
    }

    private func moveByVoiceOver(to target: LightDock, named name: String, from current: LightDock) {
        move(to: target, from: center(of: current))
        announceLightMoved(to: target)
    }

    private func announceLightMoved(to dock: LightDock) {
        var announcement = AttributedString("Light button moved to \(dock.placement.rawValue)")
        announcement.accessibilitySpeechAnnouncementPriority = .high
        AccessibilityNotification.Announcement(announcement).post()
    }

    private func chooseLightPlacement(_ placement: LightPlacement) {
        let target = LightDock(placement)
        guard target != lightDock, target != .docked || !isPickerFullWidth else { return }
        move(to: target, from: center(of: lightDock))
        announceLightMoved(to: target)
    }

    private func setLargerButtons(_ isOn: Bool) {
        withAnimation(.snappy) { viewModel.setLargerButtons(isOn) }
        if isOn { pickerLayoutChanged(true) }
    }

    private func pickerLayoutChanged(_ isFull: Bool) {
        guard isFull != isPickerFullWidth else { return }
        isPickerFullWidth = isFull
        if isFull {
            dockBeforeFullWidth = lightDock
            if lightDock == .docked {
                move(to: .side(edge: .leading), from: center(of: .docked))
                announceLightMoved(to: lightDock)
            }
        } else if let previous = dockBeforeFullWidth {
            dockBeforeFullWidth = nil
            guard previous != lightDock else { return }
            move(to: previous, from: center(of: lightDock))
            announceLightMoved(to: previous)
        }
    }

    private func sideCenter(_ edge: HorizontalEdge) -> CGPoint {
        let half = Self.sideMargin + lightButtonSize / 2
        return CGPoint(x: edge == .trailing ? screenFrame.maxX - half : screenFrame.minX + half, y: screenFrame.midY)
    }

    private func center(of dock: LightDock) -> CGPoint {
        switch dock {
        case .docked: dockSlotCenter
        case .side(let edge): sideCenter(edge)
        }
    }

    private func liftDragChanged(_ translation: CGSize) {
        isDraggingLight = true
        lightDrag = translation
    }

    private func liftEnded(_ translation: CGSize) {
        let start = center(of: lightDock)
        let drop = CGPoint(x: start.x + translation.width, y: start.y + translation.height)
        let draggedDown = translation.height > 60 && translation.height > abs(translation.width)
        let wantsDock = draggedDown || drop.y > screenFrame.maxY - Self.dockZoneHeight
        let target: LightDock = wantsDock && !isPickerFullWidth
            ? .docked
            : .side(edge: drop.x < screenFrame.midX ? .leading : .trailing)
        move(to: target, from: drop)
        isDraggingLight = false
    }

    private func move(to target: LightDock, from drop: CGPoint) {
        let destination = center(of: target)
        lightDock = target
        if !isPickerFullWidth { viewModel.setLightPlacement(target.placement) }
        guard !reduceMotion else { return lightDrag = .zero }
        lightDrag = CGSize(width: drop.x - destination.x, height: drop.y - destination.y)
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { lightDrag = .zero }
        }
    }

    private var edgeColor: Color {
        switch viewModel.filterColor {
        case .warm: LightColor.warm.color
        case .cool: LightColor.cool.color
        case .natural, nil: autoEdgeColor
        }
    }

    private var autoEdgeColor: Color {
        let zoomProgress = (viewModel.zoomState.scale - 1) / (LightingTuning.autoShiftFullScale - 1)
        let progress = max(Double(min(max(zoomProgress, 0), 1)), viewModel.closeness)
        let t = LightingTuning.autoShiftStrength * min(max(progress, 0), 1)
        let c = LightingTuning.blend(Self.whiteHex, LightingTuning.softBlue, t)
        return Color(red: c.r, green: c.g, blue: c.b)
    }

    @ViewBuilder
    private var cameraStateOverlay: some View {
        switch viewModel.cameraState {
        case .failed:
            VStack(spacing: 16) {
                Text("Camera is not opened")
                    .foregroundStyle(.white)
                Button("Try again", action: viewModel.retryCamera)
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
        case .reconnecting:
            VStack {
                Label("Reconnecting…", systemImage: "arrow.triangle.2.circlepath")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                Spacer()
            }
            .padding(.top)
        default:
            EmptyView()
        }
    }
}

enum LightDock: Equatable {
    case docked
    case side(edge: HorizontalEdge)

    init(_ placement: LightPlacement) {
        switch placement {
        case .bottom: self = .docked
        case .left: self = .side(edge: .leading)
        case .right: self = .side(edge: .trailing)
        }
    }

    var placement: LightPlacement {
        switch self {
        case .docked: .bottom
        case .side(.leading): .left
        case .side(.trailing): .right
        }
    }
}
