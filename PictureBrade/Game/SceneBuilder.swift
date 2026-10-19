//
//  SceneBuilder.swift
//  PictureBrade
//

import RealityKit
import UIKit

/// コマの 3D モデル。root を動かし、spinner を回転させる。
struct BladeModel {
    let root: Entity
    let spinner: Entity
    /// 先端（軸）の高さ。root.y = スタジアム高さ + tipHeight
    let tipHeight: Float
}

enum SceneBuilder {
    // MARK: - Stadium

    static func makeStadium() -> Entity {
        let stadium = Entity()

        // すり鉢状の床
        var floorMaterial = PhysicallyBasedMaterial()
        floorMaterial.baseColor = .init(tint: UIColor(red: 0.2, green: 0.35, blue: 0.85, alpha: 1))
        floorMaterial.roughness = 0.35
        floorMaterial.metallic = 0.2
        floorMaterial.faceCulling = .none
        // 自前メッシュはライトだけだと暗く沈むので、ほんのり自己発光させる
        floorMaterial.emissiveColor = .init(color: UIColor(red: 0.1, green: 0.2, blue: 0.55, alpha: 1))
        floorMaterial.emissiveIntensity = 0.8
        if let bowl = try? makeBowlMesh() {
            stadium.addChild(ModelEntity(mesh: bowl, materials: [floorMaterial]))
        }

        // 同心円のライン
        var lineMaterial = UnlitMaterial(color: UIColor(red: 0.35, green: 0.75, blue: 1, alpha: 1))
        lineMaterial.faceCulling = .none
        for ringRadius: Float in [0.35, 0.7] {
            let segments = 72
            for i in 0..<segments {
                let angle = Float(i) / Float(segments) * 2 * .pi
                let segment = ModelEntity(
                    mesh: .generateBox(width: 0.02, height: 0.01, depth: ringRadius * 2 * .pi / Float(segments) * 1.05),
                    materials: [lineMaterial]
                )
                segment.position = [cos(angle) * ringRadius, StadiumGeometry.height(at: ringRadius) + 0.006, sin(angle) * ringRadius]
                segment.orientation = simd_quatf(angle: -angle, axis: [0, 1, 0])
                stadium.addChild(segment)
            }
        }

        // 外周のレール（ポケット部分は空ける）
        var railMaterial = PhysicallyBasedMaterial()
        railMaterial.baseColor = .init(tint: UIColor(white: 0.85, alpha: 1))
        railMaterial.metallic = 0.8
        railMaterial.roughness = 0.25
        let pocketMaterial = UnlitMaterial(color: UIColor(red: 1, green: 0.25, blue: 0.3, alpha: 1))
        let rimRadius = StadiumGeometry.radius + 0.03
        let rimHeight = StadiumGeometry.height(at: StadiumGeometry.radius)
        let segments = 96
        let baseBottom: Float = -0.3
        for i in 0..<segments {
            let angle = Float(i) / Float(segments) * 2 * .pi
            let point = SIMD2<Float>(cos(angle), sin(angle))
            let inPocket = StadiumGeometry.isInPocket(point)
            // 台座の底(baseBottom)から立ち上がる外壁。ポケット部分はすり鉢の縁の高さまで
            let top = inPocket ? rimHeight + 0.005 : rimHeight + 0.09
            let segment = ModelEntity(
                mesh: .generateBox(width: 0.06, height: top - baseBottom, depth: rimRadius * 2 * .pi / Float(segments) * 1.02),
                materials: [inPocket ? pocketMaterial : railMaterial]
            )
            segment.position = [point.x * rimRadius, (top + baseBottom) / 2, point.y * rimRadius]
            segment.orientation = simd_quatf(angle: -angle, axis: [0, 1, 0])
            stadium.addChild(segment)
        }

        // 台座と床
        var baseMaterial = PhysicallyBasedMaterial()
        baseMaterial.baseColor = .init(tint: UIColor(white: 0.12, alpha: 1))
        baseMaterial.roughness = 0.6
        // すり鉢の底より下に置く（上に出るとすり鉢を覆い隠してしまう）
        let base = ModelEntity(mesh: .generateCylinder(height: 0.28, radius: StadiumGeometry.radius + 0.08), materials: [baseMaterial])
        base.position.y = baseBottom + 0.14 - 0.01
        stadium.addChild(base)

        var groundMaterial = PhysicallyBasedMaterial()
        groundMaterial.baseColor = .init(tint: UIColor(red: 0.06, green: 0.05, blue: 0.1, alpha: 1))
        groundMaterial.roughness = 0.9
        let ground = ModelEntity(mesh: .generatePlane(width: 12, depth: 12), materials: [groundMaterial])
        ground.position.y = baseBottom
        stadium.addChild(ground)

        // 背景（暗い空のドーム）
        var skyMaterial = UnlitMaterial(color: UIColor(red: 0.07, green: 0.05, blue: 0.16, alpha: 1))
        skyMaterial.faceCulling = .none
        stadium.addChild(ModelEntity(mesh: .generateSphere(radius: 20), materials: [skyMaterial]))

        return stadium
    }

    /// 高さ = bowl * r^2 のすり鉢メッシュ
    private static func makeBowlMesh() throws -> MeshResource {
        let rings = 24
        let segments = 72
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        for ring in 0...rings {
            let r = StadiumGeometry.radius * Float(ring) / Float(rings)
            let y = StadiumGeometry.height(at: r)
            let slope = 2 * StadiumGeometry.bowl * r
            for segment in 0..<segments {
                let angle = Float(segment) / Float(segments) * 2 * .pi
                let direction = SIMD3<Float>(cos(angle), 0, sin(angle))
                positions.append([direction.x * r, y, direction.z * r])
                normals.append(simd_normalize(SIMD3<Float>(0, 1, 0) - direction * slope))
            }
        }
        for ring in 0..<rings {
            for segment in 0..<segments {
                let next = (segment + 1) % segments
                let a = UInt32(ring * segments + segment)
                let b = UInt32(ring * segments + next)
                let c = UInt32((ring + 1) * segments + segment)
                let d = UInt32((ring + 1) * segments + next)
                indices += [a, c, b, b, c, d]
            }
        }
        var descriptor = MeshDescriptor(name: "bowl")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.primitives = .triangles(indices)
        return try MeshResource.generate(from: [descriptor])
    }

    // MARK: - Blade

    static func makeBlade(image: UIImage, tint: RGBColor, radius: Float) async -> BladeModel {
        let root = Entity()
        let spinner = Entity()
        root.addChild(spinner)
        let tipHeight: Float = 0.06

        // 軸（先端）
        var tipMaterial = PhysicallyBasedMaterial()
        tipMaterial.baseColor = .init(tint: UIColor(white: 0.9, alpha: 1))
        tipMaterial.metallic = 1.0
        tipMaterial.roughness = 0.2
        let tip = ModelEntity(mesh: .generateCone(height: tipHeight, radius: radius * 0.16), materials: [tipMaterial])
        tip.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])
        tip.position.y = -tipHeight / 2
        spinner.addChild(tip)

        // 土台のディスク（画像の平均色）
        var discMaterial = PhysicallyBasedMaterial()
        discMaterial.baseColor = .init(tint: tint.uiColor)
        discMaterial.metallic = 0.7
        discMaterial.roughness = 0.3
        let disc = ModelEntity(mesh: .generateCylinder(height: 0.02, radius: radius * 0.35), materials: [discMaterial])
        disc.position.y = 0.01
        spinner.addChild(disc)

        // メタルのリング
        let ring = ModelEntity(mesh: .generateCylinder(height: 0.012, radius: radius * 0.42), materials: [tipMaterial])
        ring.position.y = 0.004
        spinner.addChild(ring)

        // 切り抜き画像（これがコマの「顔」）
        if let cgImage = image.cgImage,
           let texture = try? await TextureResource(image: cgImage, options: .init(semantic: .color)) {
            var imageMaterial = UnlitMaterial()
            imageMaterial.color = .init(tint: .white, texture: .init(texture))
            imageMaterial.opacityThreshold = 0.1
            imageMaterial.faceCulling = .none
            let size = radius * 2.5
            let face = ModelEntity(mesh: .generatePlane(width: size, height: size), materials: [imageMaterial])
            face.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
            face.position.y = 0.024
            spinner.addChild(face)
        }

        return BladeModel(root: root, spinner: spinner, tipHeight: tipHeight)
    }

    // MARK: - Effects

    static func makeSpark() -> ModelEntity {
        let material = UnlitMaterial(color: UIColor(red: 1, green: 0.9, blue: 0.4, alpha: 1))
        return ModelEntity(mesh: .generateSphere(radius: 0.05), materials: [material])
    }
}
