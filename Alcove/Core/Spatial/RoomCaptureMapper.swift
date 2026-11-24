import Foundation
import SwiftData
import simd

/// Maps RoomPlan `CapturedRoomPayload` 1:1 into Alcove's dual-layout `Room` model,
/// preserving exact scanned positions, rotations, dimensions, walls, and openings without merging or snapping.
public final class RoomCaptureMapper: Sendable {

    public init() {}

    public func mapToRoom(payload: CapturedRoomPayload, roomName: String = "Scanned Room",
                          compassOrientation: RoomCompassOrientation? = nil) -> Room {
        let roomHeight = Double(max(2.2, payload.roomHeight))

        let snapshot: RoomPlanSnapshot? = payload.walls.isEmpty
            ? nil
            : RoomPlanSnapshot(
                walls: payload.walls,
                openings: payload.openings,
                floorLevel: payload.floorLevel,
                floorPolygonWorldPoints: payload.floorPolygonWorldPoints
            )

        let bounds = RoomPlanBounds(
            snapshot: snapshot,
            fallbackWidth: payload.roomWidth,
            fallbackLength: payload.roomLength
        )
        let roomWidth = Double(max(1.0, bounds.width))
        let roomLength = Double(max(1.0, bounds.length))

        var furnitures: [Furniture] = []
        for obj in payload.objects {
            let posX: Float
            let posZ: Float
            let yaw: Float

            if let snapshot {
                let local = snapshot.localCoordinates(worldX: obj.position.x, worldZ: obj.position.z)
                posX = local.x
                posZ = local.y
                yaw = snapshot.localYaw(obj.rotationYaw)
            } else {
                posX = obj.position.x
                posZ = obj.position.z
                yaw = obj.rotationYaw
            }

            let objWidth = Double(max(0.20, obj.dimensions.x))
            let objLength = Double(max(0.20, obj.dimensions.z))
            let objHeight = Double(max(0.20, obj.dimensions.y))
            // RoomPlan object position.y is bounding-box center; Alcove furniture rests with feet at y = 0 (or elevated if surface-mounted).
            let bottomY = Double(max(0.0, (obj.position.y - obj.dimensions.y / 2.0) - payload.floorLevel))
            let groundedY = bottomY < 0.15 ? 0.0 : bottomY

            let mapped = Self.mapCategoryAndName(
                rawCategory: obj.rawCategory,
                width: objWidth,
                length: objLength,
                height: objHeight
            )

            let furniture = Furniture(
                name: mapped.name,
                category: mapped.category,
                positionX: Double(posX),
                positionY: groundedY,
                positionZ: Double(posZ),
                rotationYaw: Double(yaw),
                width: objWidth,
                length: objLength,
                height: objHeight,
                isArchived: false,
                isUserAdded: false
            )
            furnitures.append(furniture)
        }

        let baseline = Layout(
            name: "Original Scan",
            isBaseline: true,
            furnitures: furnitures
        )
        let working = baseline.createCopy(name: "Working Layout", isBaseline: false)

        let room = Room(
            name: roomName,
            dimensionsWidth: roomWidth,
            dimensionsLength: roomLength,
            dimensionsHeight: roomHeight,
            baselineLayout: baseline,
            workingLayout: working
        )
        room.planSnapshot = snapshot
        room.compassOrientation = compassOrientation?.alignedToRoom(yawRadians: snapshot?.yawRadians ?? 0)
        baseline.room = room
        working.room = room

        return room
    }

    private static func mapCategoryAndName(
        rawCategory: String,
        width: Double,
        length: Double,
        height: Double
    ) -> (category: FurnitureCategory, name: String) {
        switch rawCategory.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "bed":
            return (.bed, "Bed")
        case "desk":
            return (.table, "Work Desk")
        case "table":
            if max(width, length) <= 0.65 {
                return (.table, "Nightstand")
            }
            if height <= 0.55 {
                return (.table, "Coffee Table")
            }
            return (.table, "Table")
        case "chair":
            if max(width, length) >= 0.75 {
                return (.seating, "Armchair")
            }
            return (.seating, "Chair")
        case "sofa":
            let span = max(width, length)
            if span < 1.15 { return (.seating, "Armchair") }
            if span < 1.85 { return (.seating, "2-Seater Sofa") }
            return (.seating, "3-Seater Sofa")
        case "storage", "closet":
            if min(width, length) <= 0.42 && height >= 1.25 {
                return (.storage, "Bookshelf")
            }
            if height <= 1.05 {
                return (.storage, "Low Dresser")
            }
            return (.storage, "Wardrobe")
        case "refrigerator":
            return (.storage, "Fridge")
        case "lamp", "lighting":
            return (.lighting, "Floor Lamp")
        case "television":
            return (.storage, "TV Stand")
        case "fireplace":
            return (.decor, "Fireplace")
        default:
            return (.other, rawCategory.capitalized)
        }
    }
}
