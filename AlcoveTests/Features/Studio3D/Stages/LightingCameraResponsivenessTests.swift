import RealityKit
import Testing
import UIKit
import SwiftUI
import simd
@testable import Alcove

@Suite("Lighting camera responsiveness") @MainActor
struct LightingCameraResponsivenessTests {
    @Test func mountedPreviewConnectsMenuCommandsAcrossRefreshAndRemount() async throws {
        let snapshot = LightingRoomSnapshot(room: SampleData.createStarterRoom())
        let controls = LightingCameraControls()
        var settings = LightingSimulationSettings()
        func preview(id: Int) -> some View {
            LightingRoomPreview(snapshot: snapshot, settings: settings, preset: .top,
                                cameraControls: controls)
                .id(id)
        }
        let host = UIHostingController(rootView: preview(id: 0))
        let windowScene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: windowScene)
        window.frame = CGRect(x: 0, y: 0, width: 1194, height: 834)
        window.rootViewController = host
        window.isHidden = false
        defer {
            controls.scene?.tearDown()
            window.isHidden = true
            window.rootViewController = nil
        }
        host.view.layoutIfNeeded()
        await flushCallbacks()
        let originalScene = try #require(controls.scene)

        for preset in ViewportPreset.allCases {
            controls.snap(to: preset, animated: false)
            settings.minuteOfDay += 10
            host.rootView = preview(id: 0)
            host.view.layoutIfNeeded()
            await flushCallbacks()
            #expect(controls.scene === originalScene)
            #expect(originalScene.cameraController.yaw == preset.targetYaw)
            #expect(originalScene.cameraController.pitch == preset.targetPitch)
        }

        // Selecting Reset Angle again must still work after a manual orbit.
        originalScene.cameraController.orbit(fromYaw: 0, pitch: 0.62, deltaX: 80, deltaY: 40)
        controls.snap(to: .dollhouse, animated: false)
        #expect(originalScene.cameraController.yaw == ViewportPreset.dollhouse.targetYaw)
        #expect(originalScene.cameraController.pitch == ViewportPreset.dollhouse.targetPitch)

        // Returning from AR creates a new viewport; commands must target its coordinator.
        host.rootView = preview(id: 1)
        host.view.layoutIfNeeded()
        await flushCallbacks()
        let replacement = try #require(controls.scene)
        #expect(replacement !== originalScene)
        controls.snap(to: .back, animated: false)
        #expect(replacement.cameraController.yaw == ViewportPreset.back.targetYaw)
        #expect(replacement.cameraController.pitch == ViewportPreset.back.targetPitch)
    }

    private func makeScene() -> (LightingRoomScene, ARView, [LightFixture]) {
        let room = MockRoomGenerator.generateBedroomOfficeCombo()
        let kinds: [LightKind] = [.ceilingLight, .pendantLight, .wallLight]
        let fixtures = (0..<24).map { index in
            LightFixture(name: "Stress light \(index)", layer: .ambient,
                         positionX: Double(index % 4) - 1.5,
                         positionZ: Double(index / 4) * 0.5 - 1.25,
                         kind: kinds[index % kinds.count])
        }
        let scene = LightingRoomScene(snapshot: LightingRoomSnapshot(room: room, fixtures: fixtures))
        let view = ARView(frame: CGRect(x: 0, y: 0, width: 1194, height: 834),
                          cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.scene.addAnchor(scene.root)
        scene.apply(LightingSimulationSettings(), preset: .front, in: view)
        scene.setSelection(Set(fixtures.map(\.id)))
        return (scene, view, fixtures)
    }

    private func flushCallbacks() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume(returning: ()) }
        }
    }

    @Test func staleWorkspaceRefreshesCannotCancelLatestCameraAnimation() async throws {
        let (scene, view, _) = makeScene()
        defer { LightingRoomPreview.dismantleUIView(view, coordinator: scene) }
        scene.snapToViewport(.back)
        let animation = try #require(scene.cameraController.animationTask)
        var settings = LightingSimulationSettings()
        for step in 0..<60 {
            settings.showsLightFixtures = step.isMultiple(of: 2)
            // Simulate a queued workspace refresh captured before the Back command.
            scene.refresh(settings, preset: .front, placementMode: false, backgroundColor: .clear, in: view)
            scene.updateFrame(in: view, deltaTime: 1.0 / 120)
            await Task.yield()
        }
        await animation.value
        #expect(scene.cameraController.yaw == ViewportPreset.back.targetYaw)
        #expect(scene.cameraController.pitch == ViewportPreset.back.targetPitch)
        #expect(scene.cameraController.animationTask == nil)
        #expect(scene.backgroundUpdateCount == 1)
    }

    @Test func unchangedWorkspaceRefreshesDoNotReconfigureRealityKitBackground() {
        let (scene, view, _) = makeScene()
        defer { LightingRoomPreview.dismantleUIView(view, coordinator: scene) }
        let settings = LightingSimulationSettings()
        for _ in 0..<120 {
            scene.refresh(settings, preset: .front, placementMode: false,
                          backgroundColor: UIColor(white: 0, alpha: 0), in: view)
        }
        #expect(scene.backgroundUpdateCount == 1)
        scene.refresh(settings, preset: .front, placementMode: false, backgroundColor: .white, in: view)
        #expect(scene.backgroundUpdateCount == 2)
        scene.tearDown()
        scene.refresh(settings, preset: .left, placementMode: false, backgroundColor: .clear, in: view)
        #expect(scene.backgroundUpdateCount == 2)
    }

    @Test func onlyPlacementTransitionsMaySynchronizeTheDeclarativeCameraPreset() {
        let (scene, view, _) = makeScene()
        defer { LightingRoomPreview.dismantleUIView(view, coordinator: scene) }
        let settings = LightingSimulationSettings()
        scene.snapToViewport(.left, animated: false)
        scene.refresh(settings, preset: .front, placementMode: false, backgroundColor: .clear, in: view)
        #expect(scene.cameraController.yaw == ViewportPreset.left.targetYaw)
        scene.refresh(settings, preset: .right, placementMode: true, backgroundColor: .clear, in: view)
        #expect(scene.cameraController.yaw == ViewportPreset.top.targetYaw)
        #expect(scene.cameraController.pitch == ViewportPreset.top.targetPitch)
        scene.refresh(settings, preset: .left, placementMode: false, backgroundColor: .clear, in: view)
        #expect(scene.cameraController.yaw == ViewportPreset.left.targetYaw)
    }

    @Test func placementAllowsCameraSnapsAndPreservesThemAcrossRefreshes() {
        let (scene, view, _) = makeScene()
        defer { LightingRoomPreview.dismantleUIView(view, coordinator: scene) }
        let settings = LightingSimulationSettings()
        scene.refresh(settings, preset: .top, placementMode: true, backgroundColor: .clear, in: view)

        for preset in [ViewportPreset.left, .right, .front, .back, .top] {
            scene.snapToViewport(preset, animated: false)
            scene.refresh(settings, preset: .top, placementMode: true, backgroundColor: .clear, in: view)
            #expect(scene.isPlacementMode)
            #expect(scene.cameraController.yaw == preset.targetYaw)
            #expect(scene.cameraController.pitch == preset.targetPitch)
        }
    }

    @Test func renderCallbacksDeferAndCoalesceHeaderChangesAndCancelOnDismissal() async {
        let (scene, view, _) = makeScene()
        defer { view.scene.anchors.removeAll() }
        var delivered: [Bool] = []
        scene.onHeaderOverlap = { delivered.append($0) }
        scene.updateViewportProjection(in: view)
        scene.setPlacementMode(true)
        scene.apply(LightingSimulationSettings(), preset: .top, in: view)
        scene.updateViewportProjection(in: view)
        #expect(delivered.isEmpty)
        await flushCallbacks()
        #expect(delivered == [false])
        scene.setPlacementMode(false)
        scene.cameraController.distance = 1
        scene.snapToViewport(.front, animated: false)
        scene.updateViewportProjection(in: view)
        scene.tearDown()
        await flushCallbacks()
        #expect(delivered == [false])
        #expect(view.subviews.compactMap { $0 as? UIImageView }.isEmpty)
    }

    @Test func manySelectedLightsBoundOverlayWorkAndIdleFramesDoNoProjection() {
        let (scene, view, fixtures) = makeScene()
        defer { LightingRoomPreview.dismantleUIView(view, coordinator: scene) }
        scene.updateFrame(in: view, deltaTime: 1.0 / 120)
        #expect(view.subviews.compactMap { $0 as? UIImageView }.count == fixtures.count)
        let baseline = scene.overlayProjectionPassCount
        for _ in 0..<120 { scene.updateFrame(in: view, deltaTime: 1.0 / 120) }
        #expect(scene.overlayProjectionPassCount == baseline)
        for step in 1...120 {
            scene.cameraController.yaw = Float(step) * 0.01
            scene.snapToViewport(step.isMultiple(of: 2) ? .left : .right, animated: false)
            scene.updateFrame(in: view, deltaTime: 1.0 / 120)
        }
        #expect(scene.overlayProjectionPassCount - baseline <= 31)
        #expect(scene.cameraController.yaw == ViewportPreset.left.targetYaw)
        let stopped = scene.overlayProjectionPassCount
        scene.tearDown()
        scene.updateFrame(in: view, deltaTime: 1)
        #expect(scene.overlayProjectionPassCount == stopped)
    }

    @Test func rapidAnimatedPresetsFinishAtLatestSelectionAndReleaseAnimationTask() async throws {
        let (scene, view, fixtures) = makeScene()
        defer { LightingRoomPreview.dismantleUIView(view, coordinator: scene) }
        let lights = try fixtures.map { fixture in
            try #require(scene.root.findEntity(named: "LightingFixture-\(fixture.id)"))
        }
        for preset in ViewportPreset.allCases + ViewportPreset.allCases.reversed() {
            scene.snapToViewport(preset)
            scene.apply(LightingSimulationSettings(), preset: preset, in: view, animated: true)
            scene.updateFrame(in: view, deltaTime: 1.0 / 60)
            await Task.yield()
        }
        scene.snapToViewport(.back)
        let finalAnimation = try #require(scene.cameraController.animationTask)
        await finalAnimation.value
        #expect(scene.cameraController.yaw == ViewportPreset.back.targetYaw)
        #expect(scene.cameraController.pitch == ViewportPreset.back.targetPitch)
        #expect(scene.cameraController.animationTask == nil)
        for light in lights { #expect(scene.root.findEntity(named: light.name) === light) }
    }

    @Test func fixtureEditsReuseCapturedRoomGeometryAndCompass() {
        let room = SampleData.createStarterRoom()
        room.compassOrientation = RoomCompassOrientation(magneticForwardBearingDegrees: 75)
        let base = LightingRoomSnapshot(room: room)
        let fixture = LightFixture(name: "Edited light", layer: .ambient, kind: .ceilingLight)
        let updated = LightingRoomSnapshot(base: base, fixtures: [fixture])
        #expect(updated.furnishings.map(\.id) == base.furnishings.map(\.id))
        #expect(updated.furnishings.map(\.position) == base.furnishings.map(\.position))
        #expect(updated.compassOrientation == base.compassOrientation)
        #expect(updated.planSnapshot == base.planSnapshot)
        #expect(updated.fixtures.map(\.id) == [fixture.id])
        #expect(base.fixtures.isEmpty)
    }
}
