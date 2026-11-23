import RealityKit
import Testing
import UIKit
import simd
@testable import Alcove

@Suite("Lighting camera responsiveness") @MainActor
struct LightingCameraResponsivenessTests {
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
