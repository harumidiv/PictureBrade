//
//  SceneBuilder.swift
//  PictureBrade
//

import Metal
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

    /// 外周レール（ポケット付き）の名前。BattleGame がこれを回してポケットを動かす
    static let pocketRimName = "pocketRim"

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
        // ポケットごと回せるように、レールはまとめて1つの親に付ける
        let rim = Entity()
        rim.name = pocketRimName
        stadium.addChild(rim)
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
            rim.addChild(segment)
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

    /// skin はストーリーの報酬で手に入る見た目の加工（自分のコマにだけ使う）
    static func makeBlade(image: UIImage, tint: RGBColor, radius: Float, skin: BladeSkin = .normal) async -> BladeModel {
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
            let size = radius * 2.5
            let face = ModelEntity(mesh: .generatePlane(width: size, height: size), materials: [faceMaterial(texture: texture, skin: skin)])
            face.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
            face.position.y = 0.024
            spinner.addChild(face)
        }

        return BladeModel(root: root, spinner: spinner, tipHeight: tipHeight)
    }

    /// コマの顔の材質。見た目の加工があれば Metal のシェーダーで描き、使えない環境ではそのままの画像にする
    private static func faceMaterial(texture: TextureResource, skin: BladeSkin) -> any RealityKit.Material {
        if let shaderName = skin.shaderFunctionName, let library = shaderLibrary {
            let shader = CustomMaterial.SurfaceShader(named: shaderName, in: library)
            if var material = try? CustomMaterial(surfaceShader: shader, lightingModel: .lit) {
                material.baseColor = .init(tint: .white, texture: .init(texture))
                material.opacityThreshold = 0.1
                material.faceCulling = .none
                return material
            }
        }
        var material = UnlitMaterial()
        material.color = .init(tint: .white, texture: .init(texture))
        material.opacityThreshold = 0.1
        material.faceCulling = .none
        return material
    }

    private static let shaderLibrary: MTLLibrary? = MTLCreateSystemDefaultDevice()?.makeDefaultLibrary()

    // MARK: - Effects

    /// ぶつかった瞬間の閃光
    static func makeSpark() -> ModelEntity {
        let material = UnlitMaterial(color: UIColor(red: 1, green: 0.95, blue: 0.7, alpha: 1))
        return ModelEntity(mesh: .generateSphere(radius: 0.05), materials: [material])
    }

    /// 火花1本ぶんの細長い棒（-Z 方向に伸びる。飛ぶ向きに向けて使う）
    private static let sparkStreakMesh = MeshResource.generateBox(size: [0.014, 0.014, 0.07])

    /// 火花の色。熱い白から、冷めるにつれてオレンジ・赤に変わる
    static let sparkMaterials: [UnlitMaterial] = [
        UIColor(red: 1, green: 1, blue: 0.9, alpha: 1),
        UIColor(red: 1, green: 0.9, blue: 0.4, alpha: 1),
        UIColor(red: 1, green: 0.6, blue: 0.15, alpha: 1),
        UIColor(red: 0.95, green: 0.3, blue: 0.05, alpha: 1),
    ].map { UnlitMaterial(color: $0) }

    static func makeSparkStreak() -> ModelEntity {
        ModelEntity(mesh: sparkStreakMesh, materials: [sparkMaterials[0]])
    }

    // MARK: - Glyph effects

    /// ハートやひらがななど、火花の代わりに飛び散る文字1つぶんの板（いつもカメラのほうを向けて使う）
    static let glyphMesh = MeshResource.generatePlane(width: 0.1, height: 0.1)

    /// エフェクトの文字を1つずつ画像にして材質にする（同じエフェクトは2回目から使い回す）
    @MainActor
    static func glyphMaterials(for effect: HitEffect) async -> [UnlitMaterial] {
        if let cached = glyphMaterialCache[effect] { return cached }
        let colors: [UIColor] = [.systemPink, .systemOrange, .systemYellow, .systemGreen, .systemTeal, .systemBlue, .systemPurple, .systemRed]
        var materials: [UnlitMaterial] = []
        for (index, glyph) in effect.glyphs.enumerated() {
            let color: UIColor = effect == .kanji ? [.systemRed, .systemOrange, .systemYellow][index % 3] : colors[index % colors.count]
            guard let cgImage = renderGlyph(glyph, color: effect.isTextGlyph ? color : nil).cgImage,
                  let texture = try? await TextureResource(image: cgImage, options: .init(semantic: .color)) else { continue }
            var material = UnlitMaterial()
            material.color = .init(tint: .white, texture: .init(texture))
            material.blending = .transparent(opacity: .init(floatLiteral: 1))
            material.faceCulling = .none
            materials.append(material)
        }
        glyphMaterialCache[effect] = materials
        return materials
    }

    @MainActor private static var glyphMaterialCache: [HitEffect: [UnlitMaterial]] = [:]

    /// color が nil なら絵文字としてそのまま描く。文字は白いふちを付けて太く描く
    static func renderGlyph(_ glyph: String, color: UIColor?) -> UIImage {
        let side: CGFloat = 128
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
            var attributes: [NSAttributedString.Key: Any]
            if let color {
                let base = UIFont.systemFont(ofSize: 92, weight: .black)
                let font = base.fontDescriptor.withDesign(.rounded).map { UIFont(descriptor: $0, size: 92) } ?? base
                attributes = [.font: font, .foregroundColor: color, .strokeColor: UIColor.white, .strokeWidth: -5.0]
            } else {
                attributes = [.font: UIFont.systemFont(ofSize: 96)]
            }
            let string = NSAttributedString(string: glyph, attributes: attributes)
            let bounds = string.boundingRect(with: CGSize(width: side * 2, height: side * 2), options: [.usesLineFragmentOrigin], context: nil)
            string.draw(at: CGPoint(x: (side - bounds.width) / 2, y: (side - bounds.height) / 2))
        }
    }
}

// MARK: - Aura

extension SceneBuilder {
    static let auraName = "aura"

    /// 連勝したコマの足元から立ちのぼるオーラ。コマの root に付ける（回転はしない）
    static func makeAura(tier: AuraTier, radius: Float, tipHeight: Float) -> Entity? {
        guard tier != .none else { return nil }
        let aura = Entity()
        aura.name = auraName
        // root の高さは「床 + 軸の長さ」なので、床の位置まで下げる
        aura.position.y = -tipHeight

        // 足元の光の輪
        if let cgImage = auraGlowImage.cgImage,
           let texture = try? TextureResource(image: cgImage, options: .init(semantic: .color)) {
            var glowMaterial = UnlitMaterial()
            glowMaterial.color = .init(tint: tier.isRainbow ? .white : tier.uiColor, texture: .init(texture))
            glowMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.9))
            glowMaterial.faceCulling = .none
            let size = radius * 3.2
            let glow = ModelEntity(mesh: .generatePlane(width: size, depth: size), materials: [glowMaterial])
            glow.position.y = 0.004
            aura.addChild(glow)
        }

        // 立ちのぼる炎（Metal のシェーダーで描く。使えない環境ではうっすら光る筒にする）
        if let mesh = auraTubeMesh {
            let flame = ModelEntity(mesh: mesh, materials: [flameMaterial(tier: tier)])
            flame.scale = [radius * 1.15, tier.flameHeight, radius * 1.15]
            aura.addChild(flame)
        }
        return aura
    }

    private static func flameMaterial(tier: AuraTier) -> any RealityKit.Material {
        if let library = MTLCreateSystemDefaultDevice()?.makeDefaultLibrary() {
            let shader = CustomMaterial.SurfaceShader(named: "bladeAura", in: library)
            if var material = try? CustomMaterial(surfaceShader: shader, lightingModel: .lit) {
                material.custom.value = tier.shaderParameter
                material.blending = .transparent(opacity: .init(floatLiteral: 1))
                material.faceCulling = .none
                return material
            }
        }
        var material = UnlitMaterial(color: tier.uiColor)
        material.blending = .transparent(opacity: .init(floatLiteral: 0.25))
        material.faceCulling = .none
        return material
    }

    /// 半径1・高さ1（y = 0〜1）のふたのない筒
    private static let auraTubeMesh: MeshResource? = {
        let segments = 48
        let rows = 6
        var positions: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        for row in 0...rows {
            let y = Float(row) / Float(rows)
            for segment in 0...segments {
                let angle = Float(segment) / Float(segments) * 2 * .pi
                positions.append([cos(angle), y, sin(angle)])
            }
        }
        let stride = UInt32(segments + 1)
        for row in 0..<UInt32(rows) {
            for segment in 0..<UInt32(segments) {
                let a = row * stride + segment
                let b = a + 1
                let c = a + stride
                let d = c + 1
                indices += [a, c, b, b, c, d]
            }
        }
        var descriptor = MeshDescriptor(name: "auraTube")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(positions.map { simd_normalize(SIMD3($0.x, 0, $0.z)) })
        descriptor.primitives = .triangles(indices)
        return try? MeshResource.generate(from: [descriptor])
    }()

    /// 中心が明るく、外に向かって消えていく白い円（色は材質の tint で付ける）
    private static let auraGlowImage: UIImage = {
        let side: CGFloat = 256
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { context in
            let colors = [UIColor.white.withAlphaComponent(0.9).cgColor, UIColor.white.withAlphaComponent(0.35).cgColor, UIColor.white.withAlphaComponent(0).cgColor]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 0.45, 1]) else { return }
            let center = CGPoint(x: side / 2, y: side / 2)
            context.cgContext.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: side / 2, options: [])
        }
    }()
}

extension BladeSkin {
    /// BladeSkinShaders.metal の関数名
    var shaderFunctionName: String? {
        switch self {
        case .normal: nil
        case .gold: "bladeSkinGold"
        case .neon: "bladeSkinNeon"
        case .rainbow: "bladeSkinRainbow"
        case .pixel: "bladeSkinPixel"
        case .hologram: "bladeSkinHologram"
        }
    }
}
