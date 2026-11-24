import RealityKit
import UIKit
import simd

/// Procedural architectural 3D geometry builder for Alcove furniture entities in RealityKit.
/// Constructs realistic multi-part meshes (frames, legs, cushions, pulls, shades) in pure code.
@MainActor
public struct ProceduralFurnitureBuilder {

    // MARK: - Reusable Materials
    private static let walnutWood = SimpleMaterial(
        color: UIColor(red: 0.42, green: 0.28, blue: 0.18, alpha: 1.0),
        roughness: 0.40,
        isMetallic: false
    )

    private static let oakWood = SimpleMaterial(
        color: UIColor(red: 0.72, green: 0.58, blue: 0.42, alpha: 1.0),
        roughness: 0.45,
        isMetallic: false
    )

    private static let whiteLacquer = SimpleMaterial(
        color: UIColor(red: 0.94, green: 0.94, blue: 0.93, alpha: 1.0),
        roughness: 0.22,
        isMetallic: false
    )

    private static let mattressFabric = SimpleMaterial(
        color: UIColor(red: 0.95, green: 0.95, blue: 0.93, alpha: 1.0),
        roughness: 0.85,
        isMetallic: false
    )

    private static let pillowFabric = SimpleMaterial(
        color: UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0),
        roughness: 0.80,
        isMetallic: false
    )

    private static let duvetFabric = SimpleMaterial(
        color: UIColor(red: 0.25, green: 0.33, blue: 0.48, alpha: 1.0),
        roughness: 0.80,
        isMetallic: false
    )

    private static let charcoalFabric = SimpleMaterial(
        color: UIColor(red: 0.22, green: 0.24, blue: 0.27, alpha: 1.0),
        roughness: 0.70,
        isMetallic: false
    )

    private static let darkMetal = SimpleMaterial(
        color: UIColor(red: 0.16, green: 0.16, blue: 0.18, alpha: 1.0),
        roughness: 0.35,
        isMetallic: true
    )

    private static let brushedBrass = SimpleMaterial(
        color: UIColor(red: 0.84, green: 0.70, blue: 0.38, alpha: 1.0),
        roughness: 0.25,
        isMetallic: true
    )

    private static let brushedAluminum = SimpleMaterial(
        color: UIColor(red: 0.84, green: 0.85, blue: 0.86, alpha: 1.0),
        roughness: 0.20,
        isMetallic: true
    )

    private static let mirrorGlass = SimpleMaterial(
        color: UIColor(red: 0.88, green: 0.91, blue: 0.94, alpha: 1.0),
        roughness: 0.06,
        isMetallic: true
    )

    private static let screenGlass = SimpleMaterial(
        color: UIColor(red: 0.08, green: 0.09, blue: 0.11, alpha: 1.0),
        roughness: 0.12,
        isMetallic: false
    )

    private static let warmBeigeFabric = SimpleMaterial(
        color: UIColor(red: 0.86, green: 0.82, blue: 0.75, alpha: 1.0),
        roughness: 0.78,
        isMetallic: false
    )

    private static let sageAccentFabric = SimpleMaterial(
        color: UIColor(red: 0.46, green: 0.55, blue: 0.49, alpha: 1.0),
        roughness: 0.75,
        isMetallic: false
    )

    private static let terracottaBook = SimpleMaterial(
        color: UIColor(red: 0.74, green: 0.38, blue: 0.27, alpha: 1.0),
        roughness: 0.6,
        isMetallic: false
    )

    private static let navyBook = SimpleMaterial(
        color: UIColor(red: 0.20, green: 0.27, blue: 0.42, alpha: 1.0),
        roughness: 0.6,
        isMetallic: false
    )

    private static let creamBook = SimpleMaterial(
        color: UIColor(red: 0.93, green: 0.89, blue: 0.80, alpha: 1.0),
        roughness: 0.6,
        isMetallic: false
    )

    private static let glowingShade = UnlitMaterial(
        color: UIColor(red: 1.0, green: 0.96, blue: 0.86, alpha: 1.0)
    )

    // MARK: - Main Dispatcher

    /// Builds a detailed multi-part Entity corresponding to the furniture item.
    public static func buildDetailedEntity(for item: Furniture) -> Entity {
        buildDetailedEntity(name: item.name, category: item.category,
                            dimensions: [Float(item.width), Float(item.height), Float(item.length)])
    }

    /// Builds the same geometry from a value snapshot without retaining SwiftData models.
    public static func buildDetailedEntity(name: String, category: FurnitureCategory,
                                          dimensions: SIMD3<Float>) -> Entity {
        let root = Entity()
        root.name = "DetailedModel"

        let w = dimensions.x
        let l = dimensions.z
        let h = dimensions.y

        let lowered = name.lowercased()
        func has(_ keys: String...) -> Bool { keys.contains { lowered.contains($0) } }

        switch category {
        case .bed:
            root.addChild(buildBed(width: w, length: l, height: h))
        case .table:
            if has("vanity") {
                root.addChild(buildVanity(width: w, length: l, height: h))
            } else if has("coffee") || (h <= 0.50 && max(w, l) >= 0.75) {
                root.addChild(buildCoffeeTable(width: w, length: l, height: h))
            } else if has("nightstand") || l < 0.6 {
                root.addChild(buildNightstand(width: w, length: l, height: h))
            } else {
                root.addChild(buildDesk(width: w, length: l, height: h))
            }
        case .seating:
            if has("ottoman") || h <= 0.52 {
                root.addChild(buildOttoman(width: w, length: l, height: h))
            } else if has("3-seater", "3 seater", "three") || (has("sofa") && w >= 1.85) {
                root.addChild(buildSofa(width: w, length: l, height: h, seatCount: 3))
            } else if has("2-seater", "2 seater", "two", "sofa") || w >= 1.25 {
                root.addChild(buildSofa(width: w, length: l, height: h, seatCount: 2))
            } else if has("accent") {
                root.addChild(buildAccentChair(width: w, length: l, height: h))
            } else if has("armchair") || (w >= 0.72 && l >= 0.72) {
                root.addChild(buildArmchair(width: w, length: l, height: h))
            } else {
                root.addChild(buildErgonomicChair(width: w, length: l, height: h))
            }
        case .storage:
            if has("nightstand") {
                root.addChild(buildNightstand(width: w, length: l, height: h))
            } else if has("bookshelf", "bookcase") {
                root.addChild(buildBookshelf(width: w, length: l, height: h))
            } else if has("tv", "console", "media") {
                root.addChild(buildTVStand(width: w, length: l, height: h))
            } else if has("fridge", "refrigerator") {
                root.addChild(buildFridge(width: w, length: l, height: h))
            } else {
                root.addChild(buildWardrobeCupboard(width: w, length: l, height: h))
            }
        case .lighting:
            root.addChild(buildFloorLamp(width: w, length: l, height: h))
        case .decor:
            if has("mirror") {
                root.addChild(buildFullLengthMirror(width: w, length: l, height: h))
            } else if has("tv", "console") {
                root.addChild(buildTVStand(width: w, length: l, height: h))
            } else {
                root.addChild(buildGenericBox(width: w, length: l, height: h))
            }
        default:
            root.addChild(buildGenericBox(width: w, length: l, height: h))
        }

        return root
    }

    // MARK: - 1. Detailed Bed

    private static func buildBed(width w: Float, length l: Float, height h: Float) -> Entity {
        let bed = Entity()
        bed.name = "Bed"

        // 1. Headboard against back edge (Z < 0)
        let headboardH = h
        let headboardThickness: Float = 0.08
        let headboardMesh = MeshResource.generateBox(
            size: SIMD3<Float>(w, headboardH, headboardThickness),
            cornerRadius: 0.01
        )
        let headboard = ModelEntity(mesh: headboardMesh, materials: [walnutWood])
        headboard.position = SIMD3<Float>(0, headboardH / 2.0, -l / 2.0 + (headboardThickness / 2.0))
        bed.addChild(headboard)

        // 2. Bed Base Platform (Wood)
        let platformH: Float = 0.16
        let legH: Float = 0.10
        let platformL = l - headboardThickness - 0.02
        let platformMesh = MeshResource.generateBox(
            size: SIMD3<Float>(w, platformH, platformL),
            cornerRadius: 0.01
        )
        let platform = ModelEntity(mesh: platformMesh, materials: [walnutWood])
        platform.position = SIMD3<Float>(0, legH + (platformH / 2.0), (headboardThickness / 2.0))
        bed.addChild(platform)

        // 3. Four Bed Legs
        let legMesh = MeshResource.generateCylinder(height: legH, radius: 0.03)
        let legOffsets: [(Float, Float)] = [
            (-w / 2.0 + 0.08, -l / 2.0 + 0.14),
            (w / 2.0 - 0.08, -l / 2.0 + 0.14),
            (-w / 2.0 + 0.08, l / 2.0 - 0.08),
            (w / 2.0 - 0.08, l / 2.0 - 0.08)
        ]
        for (x, z) in legOffsets {
            let leg = ModelEntity(mesh: legMesh, materials: [darkMetal])
            leg.position = SIMD3<Float>(x, legH / 2.0, z)
            bed.addChild(leg)
        }

        // 4. Plush Mattress (Inset slightly)
        let mattressH: Float = 0.22
        let mattressW = w - 0.08
        let mattressL = platformL - 0.04
        let mattressMesh = MeshResource.generateBox(
            size: SIMD3<Float>(mattressW, mattressH, mattressL),
            cornerRadius: 0.03
        )
        let mattress = ModelEntity(mesh: mattressMesh, materials: [mattressFabric])
        let mattressY = legH + platformH + (mattressH / 2.0)
        mattress.position = SIMD3<Float>(0, mattressY, (headboardThickness / 2.0))
        bed.addChild(mattress)

        // 5. Twin Pillows
        let pillowW: Float = (mattressW / 2.0) - 0.08
        let pillowL: Float = 0.38
        let pillowH: Float = 0.12
        let pillowMesh = MeshResource.generateBox(
            size: SIMD3<Float>(pillowW, pillowH, pillowL),
            cornerRadius: 0.03
        )
        let pillowY = mattressY + (mattressH / 2.0) + (pillowH / 2.0) - 0.02
        let pillowZ = -l / 2.0 + headboardThickness + (pillowL / 2.0) + 0.06

        let leftPillow = ModelEntity(mesh: pillowMesh, materials: [pillowFabric])
        leftPillow.position = SIMD3<Float>(-pillowW / 2.0 - 0.03, pillowY, pillowZ)
        leftPillow.orientation = simd_quatf(angle: -0.12, axis: SIMD3<Float>(1, 0, 0))
        bed.addChild(leftPillow)

        let rightPillow = ModelEntity(mesh: pillowMesh, materials: [pillowFabric])
        rightPillow.position = SIMD3<Float>(pillowW / 2.0 + 0.03, pillowY, pillowZ)
        rightPillow.orientation = simd_quatf(angle: -0.12, axis: SIMD3<Float>(1, 0, 0))
        bed.addChild(rightPillow)

        // 6. Folded Duvet / Bedspread (Covering lower 60%)
        let duvetL = mattressL * 0.62
        let duvetH: Float = 0.04
        let duvetMesh = MeshResource.generateBox(
            size: SIMD3<Float>(mattressW + 0.02, duvetH, duvetL),
            cornerRadius: 0.02
        )
        let duvet = ModelEntity(mesh: duvetMesh, materials: [duvetFabric])
        let duvetZ = (l / 2.0) - (duvetL / 2.0) - 0.02
        duvet.position = SIMD3<Float>(0, mattressY + (mattressH / 2.0) + (duvetH / 2.0), duvetZ)
        bed.addChild(duvet)

        return bed
    }

    // MARK: - 2. Detailed Home Office Desk

    private static func buildDesk(width w: Float, length l: Float, height h: Float) -> Entity {
        let desk = Entity()
        desk.name = "Desk"

        let topThickness: Float = 0.035
        let legH = h - topThickness

        // 1. Walnut Desktop Slab
        let topMesh = MeshResource.generateBox(
            size: SIMD3<Float>(w, topThickness, l),
            cornerRadius: 0.008
        )
        let top = ModelEntity(mesh: topMesh, materials: [walnutWood])
        top.position = SIMD3<Float>(0, h - (topThickness / 2.0), 0)
        desk.addChild(top)

        // 2. Four Cylindrical Metal Legs
        let legRadius: Float = 0.02
        let legMesh = MeshResource.generateCylinder(height: legH, radius: legRadius)
        let insetX = w / 2.0 - 0.06
        let insetZ = l / 2.0 - 0.06
        let legPositions: [(Float, Float)] = [
            (-insetX, -insetZ),
            (insetX, -insetZ),
            (-insetX, insetZ),
            (insetX, insetZ)
        ]
        for (x, z) in legPositions {
            let leg = ModelEntity(mesh: legMesh, materials: [darkMetal])
            leg.position = SIMD3<Float>(x, legH / 2.0, z)
            desk.addChild(leg)
        }

        // 3. Back Modesty Panel (Strengthens structural silhouette)
        let modestyH: Float = 0.22
        let modestyThickness: Float = 0.016
        let modestyMesh = MeshResource.generateBox(
            size: SIMD3<Float>(w - 0.16, modestyH, modestyThickness),
            cornerRadius: 0.005
        )
        let modesty = ModelEntity(mesh: modestyMesh, materials: [darkMetal])
        modesty.position = SIMD3<Float>(0, h - topThickness - (modestyH / 2.0) - 0.04, -insetZ)
        desk.addChild(modesty)

        // 4. Felt Desk Mat
        let matW: Float = min(0.70, w - 0.20)
        let matL: Float = min(0.38, l - 0.15)
        let matMesh = MeshResource.generateBox(
            size: SIMD3<Float>(matW, 0.004, matL),
            cornerRadius: 0.005
        )
        let mat = ModelEntity(mesh: matMesh, materials: [charcoalFabric])
        mat.position = SIMD3<Float>(0, h + 0.002, 0.02)
        desk.addChild(mat)

        // 5. Aluminum Laptop Slab
        let laptopMesh = MeshResource.generateBox(
            size: SIMD3<Float>(0.30, 0.012, 0.21),
            cornerRadius: 0.004
        )
        let laptop = ModelEntity(mesh: laptopMesh, materials: [brushedAluminum])
        laptop.position = SIMD3<Float>(0, h + 0.01, 0.02)
        desk.addChild(laptop)

        return desk
    }

    // MARK: - 3. Detailed Ergonomic Desk Chair

    private static func buildErgonomicChair(width w: Float, length l: Float, height h: Float) -> Entity {
        let chair = Entity()
        chair.name = "Chair"

        // 1. Five-Star Caster Base
        let baseHubRadius: Float = 0.04
        let baseHubH: Float = 0.04
        let hubMesh = MeshResource.generateCylinder(height: baseHubH, radius: baseHubRadius)
        let hub = ModelEntity(mesh: hubMesh, materials: [darkMetal])
        hub.position = SIMD3<Float>(0, 0.05, 0)
        chair.addChild(hub)

        // 5 Radiating Spokes
        let spokeMesh = MeshResource.generateBox(size: SIMD3<Float>(0.03, 0.02, 0.24), cornerRadius: 0.005)
        for i in 0..<5 {
            let angle = (Float(i) / 5.0) * Float.pi * 2.0
            let spoke = ModelEntity(mesh: spokeMesh, materials: [darkMetal])
            spoke.position = SIMD3<Float>(sin(angle) * 0.12, 0.04, cos(angle) * 0.12)
            spoke.orientation = simd_quatf(angle: angle, axis: SIMD3<Float>(0, 1, 0))
            chair.addChild(spoke)
        }

        // 2. Pneumatic Gas Lift Column
        let columnH: Float = 0.38
        let columnMesh = MeshResource.generateCylinder(height: columnH, radius: 0.025)
        let column = ModelEntity(mesh: columnMesh, materials: [darkMetal])
        column.position = SIMD3<Float>(0, 0.05 + (columnH / 2.0), 0)
        chair.addChild(column)

        // 3. Contoured Seat Cushion
        let seatY: Float = 0.45
        let seatMesh = MeshResource.generateBox(
            size: SIMD3<Float>(0.48, 0.07, 0.46),
            cornerRadius: 0.02
        )
        let seat = ModelEntity(mesh: seatMesh, materials: [charcoalFabric])
        seat.position = SIMD3<Float>(0, seatY, 0.02)
        chair.addChild(seat)

        // 4. Ergonomic Backrest
        let backrestH: Float = 0.44
        let backrestMesh = MeshResource.generateBox(
            size: SIMD3<Float>(0.44, backrestH, 0.035),
            cornerRadius: 0.02
        )
        let backrest = ModelEntity(mesh: backrestMesh, materials: [charcoalFabric])
        backrest.position = SIMD3<Float>(0, seatY + 0.05 + (backrestH / 2.0), -0.19)
        backrest.orientation = simd_quatf(angle: 0.08, axis: SIMD3<Float>(1, 0, 0))
        chair.addChild(backrest)

        // 5. Minimalist Loop Armrests
        let armMesh = MeshResource.generateBox(size: SIMD3<Float>(0.04, 0.18, 0.22), cornerRadius: 0.01)
        let leftArm = ModelEntity(mesh: armMesh, materials: [darkMetal])
        leftArm.position = SIMD3<Float>(-0.24, seatY + 0.10, 0.02)
        chair.addChild(leftArm)

        let rightArm = ModelEntity(mesh: armMesh, materials: [darkMetal])
        rightArm.position = SIMD3<Float>(0.24, seatY + 0.10, 0.02)
        chair.addChild(rightArm)

        return chair
    }

    // MARK: - 4. Detailed Wardrobe Cupboard

    private static func buildWardrobeCupboard(width w: Float, length l: Float, height h: Float) -> Entity {
        let wardrobe = Entity()
        wardrobe.name = "Wardrobe"

        let plinthH: Float = 0.08
        let bodyH = h - plinthH

        // 1. Recessed Base Plinth
        let plinthMesh = MeshResource.generateBox(
            size: SIMD3<Float>(w - 0.04, plinthH, l - 0.04),
            cornerRadius: 0.005
        )
        let plinth = ModelEntity(mesh: plinthMesh, materials: [darkMetal])
        plinth.position = SIMD3<Float>(0, plinthH / 2.0, 0)
        wardrobe.addChild(plinth)

        // 2. White Lacquer Main Body
        let bodyMesh = MeshResource.generateBox(
            size: SIMD3<Float>(w, bodyH, l),
            cornerRadius: 0.015
        )
        let body = ModelEntity(mesh: bodyMesh, materials: [whiteLacquer])
        let bodyY = plinthH + (bodyH / 2.0)
        body.position = SIMD3<Float>(0, bodyY, 0)
        wardrobe.addChild(body)

        // 3. Center Door Division Seam (Shadow Groove)
        let seamMesh = MeshResource.generateBox(
            size: SIMD3<Float>(0.006, bodyH - 0.04, 0.008),
            cornerRadius: 0.001
        )
        let seam = ModelEntity(mesh: seamMesh, materials: [darkMetal])
        seam.position = SIMD3<Float>(0, bodyY, (l / 2.0) + 0.002)
        wardrobe.addChild(seam)

        // 4. Two Brushed Aluminum Vertical Handles
        let handleH: Float = 0.28
        let handleRadius: Float = 0.009
        let handleMesh = MeshResource.generateCylinder(height: handleH, radius: handleRadius)

        let leftHandle = ModelEntity(mesh: handleMesh, materials: [brushedAluminum])
        leftHandle.position = SIMD3<Float>(-0.035, bodyY, (l / 2.0) + 0.02)
        wardrobe.addChild(leftHandle)

        let rightHandle = ModelEntity(mesh: handleMesh, materials: [brushedAluminum])
        rightHandle.position = SIMD3<Float>(0.035, bodyY, (l / 2.0) + 0.02)
        wardrobe.addChild(rightHandle)

        return wardrobe
    }

    // MARK: - 5. Detailed Nightstand

    private static func buildNightstand(width w: Float, length l: Float, height h: Float) -> Entity {
        let nightstand = Entity()
        nightstand.name = "Nightstand"

        let legH: Float = 0.12
        let bodyH = h - legH

        // 1. Four Slim Angled Brass Legs
        let legMesh = MeshResource.generateCylinder(height: legH, radius: 0.015)
        let insetX = w / 2.0 - 0.05
        let insetZ = l / 2.0 - 0.05
        let legPositions: [(Float, Float)] = [
            (-insetX, -insetZ),
            (insetX, -insetZ),
            (-insetX, insetZ),
            (insetX, insetZ)
        ]
        for (x, z) in legPositions {
            let leg = ModelEntity(mesh: legMesh, materials: [brushedBrass])
            leg.position = SIMD3<Float>(x, legH / 2.0, z)
            nightstand.addChild(leg)
        }

        // 2. Walnut Two-Drawer Cabinet
        let bodyMesh = MeshResource.generateBox(
            size: SIMD3<Float>(w, bodyH, l),
            cornerRadius: 0.01
        )
        let body = ModelEntity(mesh: bodyMesh, materials: [walnutWood])
        let bodyY = legH + (bodyH / 2.0)
        body.position = SIMD3<Float>(0, bodyY, 0)
        nightstand.addChild(body)

        // 3. Two Drawer Pulls (Horizontal Brass Bars)
        let pullMesh = MeshResource.generateBox(
            size: SIMD3<Float>(0.08, 0.012, 0.015),
            cornerRadius: 0.002
        )
        let topPull = ModelEntity(mesh: pullMesh, materials: [brushedBrass])
        topPull.position = SIMD3<Float>(0, bodyY + (bodyH * 0.22), (l / 2.0) + 0.01)
        nightstand.addChild(topPull)

        let bottomPull = ModelEntity(mesh: pullMesh, materials: [brushedBrass])
        bottomPull.position = SIMD3<Float>(0, bodyY - (bodyH * 0.22), (l / 2.0) + 0.01)
        nightstand.addChild(bottomPull)

        // 4. Bedside Table Lamp
        let lampBaseMesh = MeshResource.generateCylinder(height: 0.015, radius: 0.05)
        let lampBase = ModelEntity(mesh: lampBaseMesh, materials: [brushedBrass])
        let tableTopY = legH + bodyH
        lampBase.position = SIMD3<Float>(0, tableTopY + 0.0075, 0)
        nightstand.addChild(lampBase)

        let lampStemMesh = MeshResource.generateCylinder(height: 0.14, radius: 0.008)
        let lampStem = ModelEntity(mesh: lampStemMesh, materials: [brushedBrass])
        lampStem.position = SIMD3<Float>(0, tableTopY + 0.08, 0)
        nightstand.addChild(lampStem)

        let lampShadeMesh = MeshResource.generateCylinder(height: 0.11, radius: 0.075)
        let lampShade = ModelEntity(mesh: lampShadeMesh, materials: [glowingShade])
        lampShade.position = SIMD3<Float>(0, tableTopY + 0.18, 0)
        nightstand.addChild(lampShade)

        return nightstand
    }

    // MARK: - 6. Detailed Floor Lamp

    private static func buildFloorLamp(width w: Float, length l: Float, height h: Float) -> Entity {
        let lamp = Entity()
        lamp.name = "FloorLamp"

        // 1. Heavy Circular Brass Base
        let baseH: Float = 0.025
        let baseRadius: Float = min(w, l) / 2.0 - 0.02
        let baseMesh = MeshResource.generateCylinder(height: baseH, radius: baseRadius)
        let base = ModelEntity(mesh: baseMesh, materials: [brushedBrass])
        base.position = SIMD3<Float>(0, baseH / 2.0, 0)
        lamp.addChild(base)

        // 2. Slender Brass Pole
        let poleH = h - 0.28
        let poleMesh = MeshResource.generateCylinder(height: poleH, radius: 0.012)
        let pole = ModelEntity(mesh: poleMesh, materials: [brushedBrass])
        pole.position = SIMD3<Float>(0, baseH + (poleH / 2.0), 0)
        lamp.addChild(pole)

        // 3. Glowing Translucent Drum Shade
        let shadeH: Float = 0.26
        let shadeRadius: Float = baseRadius + 0.02
        let shadeMesh = MeshResource.generateCylinder(height: shadeH, radius: shadeRadius)
        let shade = ModelEntity(mesh: shadeMesh, materials: [glowingShade])
        let shadeY = h - (shadeH / 2.0)
        shade.position = SIMD3<Float>(0, shadeY, 0)
        lamp.addChild(shade)

        // 4. Functional Warm Point Light inside the shade
        let light = PointLight()
        light.name = "LampBulb"
        light.light.color = UIColor(red: 1.0, green: 0.92, blue: 0.80, alpha: 1.0)
        light.light.intensity = 850
        light.light.attenuationRadius = 3.8
        light.position = SIMD3<Float>(0, shadeY, 0)
        lamp.addChild(light)

        return lamp
    }

    // MARK: - Shared Part Helper

    private static func part(
        _ size: SIMD3<Float>,
        at position: SIMD3<Float>,
        material: Material,
        radius: Float = 0.008
    ) -> ModelEntity {
        let mesh = MeshResource.generateBox(size: size, cornerRadius: min(radius, min(size.x, min(size.y, size.z)) / 2.0))
        let model = ModelEntity(mesh: mesh, materials: [material])
        model.position = position
        return model
    }

    // MARK: - 7. Bookshelf

    private static func buildBookshelf(width w: Float, length l: Float, height h: Float) -> Entity {
        let shelf = Entity()
        shelf.name = "Bookshelf"
        let t: Float = 0.025
        let backT: Float = 0.012

        shelf.addChild(part([t, h, l], at: [-w / 2 + t / 2, h / 2, 0], material: walnutWood))
        shelf.addChild(part([t, h, l], at: [w / 2 - t / 2, h / 2, 0], material: walnutWood))
        shelf.addChild(part([w - 2 * t, h - 0.02, backT], at: [0, h / 2 + 0.01, -l / 2 + backT / 2], material: oakWood))
        shelf.addChild(part([w, t, l], at: [0, h - t / 2, 0], material: walnutWood))
        shelf.addChild(part([w - 2 * t, t, l], at: [0, 0.08, 0], material: walnutWood))

        let levels = 4
        let innerBottom: Float = 0.08 + t / 2
        let innerTop = h - t
        let step = (innerTop - innerBottom) / Float(levels + 1)
        let bookMaterials: [Material] = [terracottaBook, navyBook, creamBook, sageAccentFabric, brushedBrass]
        for i in 1...levels {
            let y = innerBottom + step * Float(i)
            shelf.addChild(part([w - 2 * t, t, l - backT], at: [0, y, backT / 2], material: walnutWood))
        }
        // Book clusters sit on the bottom plate and on each intermediate shelf.
        for i in 0...levels {
            let baseY = i == 0 ? innerBottom : innerBottom + step * Float(i) + t / 2
            let room = step - 0.02
            let bookH = max(0.12, min(0.30, room * 0.8))
            var x = -w / 2 + t + 0.05
            var idx = i
            while x < w / 2 - t - 0.12 {
                let bw: Float = 0.03 + Float((idx * 7) % 3) * 0.012
                let bh = bookH * (0.8 + Float((idx * 5) % 3) * 0.1)
                shelf.addChild(part([bw, bh, min(0.22, l - 0.08)],
                                    at: [x, baseY + bh / 2, 0.0],
                                    material: bookMaterials[idx % bookMaterials.count], radius: 0.003))
                x += bw + 0.004
                idx += 1
                if idx % 6 == 0 { x += 0.12 }
            }
        }
        return shelf
    }

    // MARK: - 8. Vanity

    private static func buildVanity(width w: Float, length l: Float, height h: Float) -> Entity {
        let vanity = Entity()
        vanity.name = "Vanity"
        let tableH = min(0.76, h * 0.58)
        let topT: Float = 0.035
        let legH = tableH - topT - 0.14
        let legMesh = MeshResource.generateCylinder(height: max(0.05, legH), radius: 0.015)
        for (x, z) in [(-1, -1), (1, -1), (-1, 1), (1, 1)] as [(Float, Float)] {
            let leg = ModelEntity(mesh: legMesh, materials: [brushedBrass])
            leg.position = [x * (w / 2 - 0.05), max(0.05, legH) / 2, z * (l / 2 - 0.05)]
            vanity.addChild(leg)
        }
        vanity.addChild(part([w - 0.04, 0.14, l - 0.04], at: [0, legH + 0.07, 0], material: whiteLacquer, radius: 0.01))
        vanity.addChild(part([w, topT, l], at: [0, tableH - topT / 2, 0], material: walnutWood))
        for dx in [-w / 4, w / 4] {
            vanity.addChild(part([0.10, 0.012, 0.015], at: [dx, legH + 0.07, l / 2 - 0.015], material: brushedBrass, radius: 0.002))
        }
        // Arched mirror rising from the back edge
        let mirrorH = max(0.2, h - tableH - 0.04)
        let mirrorW = min(w - 0.2, 0.7)
        let frameZ = -l / 2 + 0.03
        let mirrorCenterY = tableH + 0.04 + mirrorH / 2
        vanity.addChild(part([mirrorW + 0.04, mirrorH + 0.04, 0.02], at: [0, mirrorCenterY, frameZ], material: brushedBrass, radius: 0.01))
        vanity.addChild(part([mirrorW, mirrorH, 0.01], at: [0, mirrorCenterY, frameZ + 0.013], material: mirrorGlass, radius: 0.004))
        // Small stool-like tray on top
        vanity.addChild(part([0.18, 0.012, 0.12], at: [w / 4, tableH + 0.006, 0.02], material: brushedBrass, radius: 0.004))
        return vanity
    }

    // MARK: - 9. Coffee Table

    private static func buildCoffeeTable(width w: Float, length l: Float, height h: Float) -> Entity {
        let table = Entity()
        table.name = "CoffeeTable"
        let topT: Float = 0.04
        let legH = h - topT
        let legMesh = MeshResource.generateCylinder(height: legH, radius: 0.022)
        for (x, z) in [(-1, -1), (1, -1), (-1, 1), (1, 1)] as [(Float, Float)] {
            let leg = ModelEntity(mesh: legMesh, materials: [darkMetal])
            leg.position = [x * (w / 2 - 0.06), legH / 2, z * (l / 2 - 0.06)]
            table.addChild(leg)
        }
        table.addChild(part([w, topT, l], at: [0, h - topT / 2, 0], material: oakWood, radius: 0.015))
        table.addChild(part([w - 0.16, 0.02, l - 0.16], at: [0, 0.12, 0], material: walnutWood, radius: 0.005))
        // Decorative book stack + tray
        table.addChild(part([0.26, 0.03, 0.19], at: [-w / 4, h + 0.015, 0], material: navyBook, radius: 0.004))
        table.addChild(part([0.22, 0.025, 0.16], at: [-w / 4, h + 0.0425, 0], material: terracottaBook, radius: 0.004))
        table.addChild(part([0.20, 0.015, 0.14], at: [w / 5, h + 0.0075, 0.02], material: brushedBrass, radius: 0.004))
        return table
    }

    // MARK: - 10. Sofa (2 or 3 seats)

    private static func buildSofa(width w: Float, length l: Float, height h: Float, seatCount: Int) -> Entity {
        let sofa = Entity()
        sofa.name = "Sofa"
        let legH: Float = 0.08
        let armW: Float = 0.14
        let baseH: Float = 0.20
        let seatH: Float = 0.14
        let backT: Float = 0.20

        let legMesh = MeshResource.generateCylinder(height: legH, radius: 0.02)
        for (x, z) in [(-1, -1), (1, -1), (-1, 1), (1, 1)] as [(Float, Float)] {
            let leg = ModelEntity(mesh: legMesh, materials: [walnutWood])
            leg.position = [x * (w / 2 - 0.08), legH / 2, z * (l / 2 - 0.08)]
            sofa.addChild(leg)
        }
        sofa.addChild(part([w, baseH, l], at: [0, legH + baseH / 2, 0], material: charcoalFabric, radius: 0.03))
        // Backrest
        let backH = h - legH - baseH
        sofa.addChild(part([w, backH, backT], at: [0, legH + baseH + backH / 2, -l / 2 + backT / 2], material: charcoalFabric, radius: 0.04))
        // Armrests
        let armH = max(0.12, backH * 0.55)
        for x: Float in [-1, 1] {
            sofa.addChild(part([armW, armH, l - backT], at: [x * (w / 2 - armW / 2), legH + baseH + armH / 2, backT / 2], material: charcoalFabric, radius: 0.04))
        }
        // Seat + back cushions
        let innerW = w - 2 * armW
        let cushionW = innerW / Float(seatCount)
        let cushionL = l - backT - 0.02
        for i in 0..<seatCount {
            let x = -innerW / 2 + cushionW * (Float(i) + 0.5)
            sofa.addChild(part([cushionW - 0.01, seatH, cushionL], at: [x, legH + baseH + seatH / 2, backT / 2 + 0.01], material: warmBeigeFabric, radius: 0.04))
            let bcH = max(0.18, backH * 0.85)
            let bc = part([cushionW - 0.02, bcH, 0.12], at: [x, legH + baseH + seatH + bcH / 2 - 0.02, -l / 2 + backT + 0.04], material: warmBeigeFabric, radius: 0.04)
            bc.orientation = simd_quatf(angle: -0.18, axis: [1, 0, 0])
            sofa.addChild(bc)
        }
        // Throw pillows
        for x: Float in [-1, 1] {
            let pillow = part([0.34, 0.34, 0.10], at: [x * (innerW / 2 - 0.20), legH + baseH + seatH + 0.20, -l / 2 + backT + 0.14], material: sageAccentFabric, radius: 0.04)
            pillow.orientation = simd_quatf(angle: -0.25, axis: [1, 0, 0])
            sofa.addChild(pillow)
        }
        return sofa
    }

    // MARK: - 11. Armchair (Cozy Enclosed Lounge Silhouette)

    private static func buildArmchair(width w: Float, length l: Float, height h: Float) -> Entity {
        let chair = Entity()
        chair.name = "Armchair"
        let legH: Float = 0.14
        let armW: Float = 0.12
        let baseH: Float = 0.16
        let backT: Float = 0.16

        let legMesh = MeshResource.generateCylinder(height: legH, radius: 0.02)
        for (x, z) in [(-1, -1), (1, -1), (-1, 1), (1, 1)] as [(Float, Float)] {
            let leg = ModelEntity(mesh: legMesh, materials: [oakWood])
            leg.position = [x * (w / 2 - 0.09), legH / 2, z * (l / 2 - 0.09)]
            chair.addChild(leg)
        }
        chair.addChild(part([w, baseH, l], at: [0, legH + baseH / 2, 0], material: sageAccentFabric, radius: 0.03))
        let backH = h - legH - baseH
        chair.addChild(part([w, backH, backT], at: [0, legH + baseH + backH / 2, -l / 2 + backT / 2], material: sageAccentFabric, radius: 0.04))
        let armH = max(0.12, backH * 0.5)
        for x: Float in [-1, 1] {
            chair.addChild(part([armW, armH, l - backT], at: [x * (w / 2 - armW / 2), legH + baseH + armH / 2, backT / 2], material: sageAccentFabric, radius: 0.04))
        }
        let seatW = w - 2 * armW - 0.02
        chair.addChild(part([seatW, 0.12, l - backT - 0.02], at: [0, legH + baseH + 0.06, backT / 2 + 0.01], material: warmBeigeFabric, radius: 0.04))
        let recline = part([seatW, max(0.2, backH * 0.8), 0.10], at: [0, legH + baseH + 0.12 + max(0.2, backH * 0.8) / 2 - 0.02, -l / 2 + backT + 0.03], material: warmBeigeFabric, radius: 0.04)
        recline.orientation = simd_quatf(angle: -0.2, axis: [1, 0, 0])
        chair.addChild(recline)
        let lumbar = part([0.30, 0.20, 0.08], at: [0.0, legH + baseH + 0.12 + 0.16, -l / 2 + backT + 0.12], material: terracottaBook, radius: 0.03)
        lumbar.orientation = simd_quatf(angle: -0.25, axis: [1, 0, 0])
        chair.addChild(lumbar)
        return chair
    }

    // MARK: - 11b. Accent Chair (Mid-Century Open Walnut Frame Silhouette)

    private static func buildAccentChair(width w: Float, length l: Float, height h: Float) -> Entity {
        let chair = Entity()
        chair.name = "AccentChair"
        let legH: Float = 0.34
        let armY: Float = 0.58
        let frameT: Float = 0.04
        let seatW = max(0.46, w - 0.14)
        let seatL = max(0.46, l - 0.12)
        let sideX = seatW / 2 + frameT / 2 + 0.01

        // 1. Open Mid-Century Walnut Side Frames (Legs + Arm Rails)
        for x: Float in [-sideX, sideX] {
            chair.addChild(part([frameT, legH, frameT], at: [x, legH / 2, l / 2 - 0.08], material: walnutWood, radius: 0.008))
            chair.addChild(part([frameT, armY, frameT], at: [x, armY / 2, -l / 2 + 0.08], material: walnutWood, radius: 0.008))
            chair.addChild(part([frameT, armY - legH, frameT], at: [x, (legH + armY) / 2, l / 2 - 0.08], material: walnutWood, radius: 0.008))
            chair.addChild(part([frameT + 0.015, 0.035, l - 0.10], at: [x, armY, 0], material: walnutWood, radius: 0.01))
            chair.addChild(part([frameT, 0.04, l - 0.12], at: [x, legH - 0.02, 0], material: walnutWood, radius: 0.006))
        }
        // Front & back wooden seat support rails
        chair.addChild(part([seatW, 0.045, frameT], at: [0, legH - 0.02, l / 2 - 0.10], material: walnutWood, radius: 0.006))
        chair.addChild(part([seatW, 0.045, frameT], at: [0, legH - 0.02, -l / 2 + 0.10], material: walnutWood, radius: 0.006))

        // 2. Crisp Floating Seat Cushion
        let seatCushion = part([seatW, 0.10, seatL], at: [0, legH + 0.04, 0.02], material: terracottaBook, radius: 0.03)
        seatCushion.orientation = simd_quatf(angle: -0.06, axis: [1, 0, 0])
        chair.addChild(seatCushion)

        // 3. Reclined Backrest Cushion & Exposed Wood Spine
        let backH = max(0.32, h - legH - 0.08)
        let backCenterY = legH + 0.08 + backH / 2
        let backCenterZ = -l / 2 + 0.14
        let backCushion = part([seatW - 0.02, backH, 0.10], at: [0, backCenterY, backCenterZ], material: terracottaBook, radius: 0.035)
        backCushion.orientation = simd_quatf(angle: -0.22, axis: [1, 0, 0])
        chair.addChild(backCushion)

        let backSpine = part([seatW - 0.10, backH * 0.85, 0.025], at: [0, backCenterY - 0.02, backCenterZ - 0.06], material: walnutWood, radius: 0.006)
        backSpine.orientation = simd_quatf(angle: -0.22, axis: [1, 0, 0])
        chair.addChild(backSpine)

        return chair
    }

    // MARK: - 12. Ottoman

    private static func buildOttoman(width w: Float, length l: Float, height h: Float) -> Entity {
        let ottoman = Entity()
        ottoman.name = "Ottoman"
        let legH: Float = min(0.10, h * 0.3)
        let legMesh = MeshResource.generateCylinder(height: legH, radius: 0.025)
        for (x, z) in [(-1, -1), (1, -1), (-1, 1), (1, 1)] as [(Float, Float)] {
            let leg = ModelEntity(mesh: legMesh, materials: [walnutWood])
            leg.position = [x * (w / 2 - 0.07), legH / 2, z * (l / 2 - 0.07)]
            ottoman.addChild(leg)
        }
        let rimH: Float = 0.08
        ottoman.addChild(part([w - 0.02, rimH, l - 0.02], at: [0, legH + rimH / 2, 0], material: oakWood, radius: 0.02))
        let cushionH = h - legH - rimH
        ottoman.addChild(part([w, cushionH, l], at: [0, legH + rimH + cushionH / 2, 0], material: warmBeigeFabric, radius: min(0.06, cushionH / 2)))
        // Tufting buttons
        for (x, z) in [(-1, -1), (1, -1), (-1, 1), (1, 1)] as [(Float, Float)] {
            ottoman.addChild(part([0.025, 0.01, 0.025], at: [x * w / 5, h, z * l / 5], material: brushedBrass, radius: 0.004))
        }
        return ottoman
    }

    // MARK: - 13. TV Stand (console + flatscreen)

    private static func buildTVStand(width w: Float, length l: Float, height h: Float) -> Entity {
        let stand = Entity()
        stand.name = "TVStand"
        let consoleH = min(0.52, h * 0.45)
        let legH: Float = 0.10
        let bodyH = consoleH - legH
        let legMesh = MeshResource.generateCylinder(height: legH, radius: 0.02)
        for (x, z) in [(-1, -1), (1, -1), (-1, 1), (1, 1)] as [(Float, Float)] {
            let leg = ModelEntity(mesh: legMesh, materials: [brushedBrass])
            leg.position = [x * (w / 2 - 0.08), legH / 2, z * (l / 2 - 0.06)]
            stand.addChild(leg)
        }
        stand.addChild(part([w, bodyH, l], at: [0, legH + bodyH / 2, 0], material: walnutWood, radius: 0.012))
        // Door seams + handles
        for x in [-w / 6, w / 6] as [Float] {
            stand.addChild(part([0.006, bodyH - 0.06, 0.006], at: [x, legH + bodyH / 2, l / 2 + 0.002], material: darkMetal, radius: 0.001))
        }
        for x in [-w / 6 - 0.06, w / 6 + 0.06] as [Float] {
            stand.addChild(part([0.012, 0.12, 0.015], at: [x, legH + bodyH / 2, l / 2 + 0.01], material: brushedBrass, radius: 0.002))
        }
        // Flatscreen TV
        let tvH = max(0.42, h - consoleH - 0.06)
        let tvW = min(w - 0.1, tvH * 1.78)
        stand.addChild(part([0.30, 0.012, 0.18], at: [0, consoleH + 0.006, 0], material: darkMetal, radius: 0.004))
        stand.addChild(part([0.04, 0.05, 0.03], at: [0, consoleH + 0.037, 0], material: darkMetal, radius: 0.004))
        let panelY = consoleH + 0.06 + tvH / 2
        stand.addChild(part([tvW, tvH, 0.025], at: [0, panelY, 0], material: charcoalFabric, radius: 0.006))
        stand.addChild(part([tvW - 0.03, tvH - 0.03, 0.006], at: [0, panelY, 0.014], material: screenGlass, radius: 0.003))
        return stand
    }

    // MARK: - 14. Full-Length Mirror

    private static func buildFullLengthMirror(width w: Float, length l: Float, height h: Float) -> Entity {
        let mirror = Entity()
        mirror.name = "FullLengthMirror"
        let tilt = Entity()
        tilt.name = "MirrorTilt"
        let frameT: Float = 0.032
        let border: Float = 0.038
        let tiltMag: Float = 0.06
        let panelH = h - 0.015
        let pivotZ: Float = max(0.05, l * 0.30)

        // Tilted mirror frame (bottom sits slightly forward at +Z, top leans back toward -Z).
        tilt.addChild(part([w, panelH, frameT], at: [0, panelH / 2 + 0.015, 0], material: walnutWood, radius: 0.01))
        let glass = part([w - 2 * border, panelH - 2 * border, 0.006], at: [0, panelH / 2 + 0.015, frameT / 2 + 0.002], material: mirrorGlass, radius: 0.003)
        glass.name = "MirrorGlass"
        tilt.addChild(glass)
        tilt.addChild(part([w + 0.01, 0.015, frameT + 0.005], at: [0, panelH + 0.015, 0], material: brushedBrass, radius: 0.004))

        // Hinge block fixed strictly behind (-Z) the mirror frame backing.
        let hingeLocalY = panelH * 0.72
        let hingeLocalZ = -(frameT / 2 + 0.018)
        tilt.addChild(part([w * 0.55, 0.03, 0.02], at: [0, hingeLocalY, -(frameT / 2 + 0.008)], material: brushedBrass, radius: 0.004))

        tilt.position = [0, 0, pivotZ]
        tilt.orientation = simd_quatf(angle: -tiltMag, axis: [1, 0, 0])
        mirror.addChild(tilt)

        // Compute world (mirror-local) hinge coordinate behind the frame so the easel legs never touch or cross the glass.
        let hingeY = hingeLocalY * cos(tiltMag) + hingeLocalZ * sin(tiltMag)
        let hingeZ = pivotZ - hingeLocalY * sin(tiltMag) + hingeLocalZ * cos(tiltMag)
        let footY: Float = 0.012
        let footZ: Float = -l / 2 + 0.025
        let dy = hingeY - footY
        let dz = hingeZ - footZ
        let legLen = hypot(dy, dz)
        let legAngle = atan2(dz, dy)
        let midY = (hingeY + footY) / 2
        let midZ = (hingeZ + footZ) / 2

        let easelOffsetX = max(0.08, w * 0.28)
        for x: Float in [-easelOffsetX, easelOffsetX] {
            let leg = part([0.028, legLen, 0.022], at: [x, midY, midZ], material: walnutWood, radius: 0.004)
            leg.name = "MirrorEaselLeg"
            leg.orientation = simd_quatf(angle: legAngle, axis: [1, 0, 0])
            mirror.addChild(leg)
        }
        let braceT: Float = 0.28
        let braceY = footY + braceT * dy
        let braceZ = footZ + braceT * dz
        let brace = part([easelOffsetX * 2, 0.026, 0.022], at: [0, braceY, braceZ], material: walnutWood, radius: 0.004)
        brace.name = "MirrorEaselBrace"
        brace.orientation = simd_quatf(angle: legAngle, axis: [1, 0, 0])
        mirror.addChild(brace)

        return mirror
    }

    // MARK: - 15. Fridge

    private static func buildFridge(width w: Float, length l: Float, height h: Float) -> Entity {
        let fridge = Entity()
        fridge.name = "Fridge"
        let plinthH: Float = 0.05
        let bodyH = h - plinthH
        fridge.addChild(part([w - 0.06, plinthH, l - 0.08], at: [0, plinthH / 2, 0], material: darkMetal, radius: 0.004))
        fridge.addChild(part([w, bodyH, l], at: [0, plinthH + bodyH / 2, 0], material: brushedAluminum, radius: 0.02))
        let freezerH = bodyH * 0.30
        let fridgeDoorH = bodyH - freezerH - 0.02
        let frontZ = l / 2 + 0.004
        fridge.addChild(part([w - 0.03, 0.008, 0.006], at: [0, plinthH + fridgeDoorH + 0.01, frontZ], material: darkMetal, radius: 0.001))
        for (hy, hh) in [(plinthH + fridgeDoorH + 0.10, 0.28), (plinthH + fridgeDoorH - 0.12, 0.40)] as [(Float, Float)] {
            fridge.addChild(part([0.02, hh, 0.03], at: [w / 2 - 0.08, hy, l / 2 + 0.025], material: darkMetal, radius: 0.006))
        }
        return fridge
    }

    // MARK: - Generic Fallback

    private static func buildGenericBox(width w: Float, length l: Float, height h: Float) -> Entity {
        let mesh = MeshResource.generateBox(size: SIMD3<Float>(w, h, l), cornerRadius: 0.02)
        let model = ModelEntity(mesh: mesh, materials: [oakWood])
        model.position = SIMD3<Float>(0, h / 2.0, 0)
        return model
    }
}
