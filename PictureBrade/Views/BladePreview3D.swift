//
//  BladePreview3D.swift
//  PictureBrade
//

import RealityKit
import SwiftUI
import UIKit

/// カメラの向き。装備画面で選んでいる種類によって、見やすい向きに切り替える
enum PreviewAngle {
    /// 真上から（見た目の加工がよく見える）
    case top
    /// 斜め上から（ボディのトゲがよく見える）
    case oblique
    /// 真横から（シャフトの形がよく見える）
    case side
}

/// 装備画面の上に出す、コマの 3D プレビュー（回さずに止めておく）。
/// バトルと同じモデル（SceneBuilder.makeBlade）を使うので、ボディのトゲやシャフトの形がそのまま見える
struct BladePreview3D: View {
    let image: UIImage?
    let tint: RGBColor
    let equipment: Equipment
    var skin: BladeSkin = .normal
    var aura: AuraTier = .none
    var angle: PreviewAngle = .oblique

    @State private var scene = BladePreviewScene()

    /// 見た目が変わったときだけモデルを作り直す
    private struct ModelKey: Hashable {
        let equipment: Equipment
        let skin: BladeSkin
        let aura: AuraTier
    }

    var body: some View {
        RealityView { content in
            scene.setUp(content: &content, angle: angle)
        }
        .onChange(of: angle) { _, angle in
            scene.setAngle(angle)
        }
        .task(id: ModelKey(equipment: equipment, skin: skin, aura: aura)) {
            guard let image else { return }
            await scene.show(image: image, tint: tint, equipment: equipment, skin: skin, aura: aura)
        }
    }
}

/// 3D プレビューのシーン。コマを置いて、向きに合わせてカメラを動かす
@MainActor
final class BladePreviewScene {
    private let root = Entity()
    private let camera = PerspectiveCamera()
    private var model: BladeModel?
    private var updateSubscription: EventSubscription?
    /// 付け替えたときにポンと跳ねる演出の残り時間
    private var popTime: Float = 0
    private var angle = PreviewAngle.oblique
    /// コマを止めておく向き（真上からは写真がまっすぐ、ほかはトゲが重ならないよう少し回す）
    private var restingTurn: Float = 0
    /// バトルでの大きさとだいたい同じにする
    private static let radius: Float = 0.145

    func setUp(content: inout RealityViewCameraContent, angle: PreviewAngle) {
        content.camera = .virtual
        content.add(root)

        camera.camera.fieldOfViewInDegrees = 30
        camera.transform = Self.cameraTransform(for: angle)
        root.addChild(camera)
        self.angle = angle
        restingTurn = Self.restingTurn(for: angle)

        let sun = DirectionalLight()
        sun.light.intensity = 4000
        sun.look(at: .zero, from: [0.6, 1.5, 1], relativeTo: nil)
        root.addChild(sun)
        let fill = PointLight()
        fill.light.intensity = 20_000
        fill.light.attenuationRadius = 4
        fill.position = [-0.6, 0.6, 0.4]
        root.addChild(fill)

        // 足元の小さなステージと、暗い背景
        var stageMaterial = PhysicallyBasedMaterial()
        stageMaterial.baseColor = .init(tint: UIColor(red: 0.2, green: 0.35, blue: 0.85, alpha: 1))
        stageMaterial.emissiveColor = .init(color: UIColor(red: 0.1, green: 0.2, blue: 0.55, alpha: 1))
        stageMaterial.emissiveIntensity = 0.8
        stageMaterial.roughness = 0.35
        let stage = ModelEntity(mesh: .generateCylinder(height: 0.02, radius: 0.3), materials: [stageMaterial])
        stage.position.y = -0.01
        root.addChild(stage)
        let rim = ModelEntity(mesh: .generateCylinder(height: 0.012, radius: 0.32), materials: [UnlitMaterial(color: UIColor(red: 0.35, green: 0.75, blue: 1, alpha: 1))])
        rim.position.y = -0.012
        root.addChild(rim)

        var skyMaterial = UnlitMaterial(color: UIColor(red: 0.08, green: 0.05, blue: 0.18, alpha: 1))
        skyMaterial.faceCulling = .none
        root.addChild(ModelEntity(mesh: .generateSphere(radius: 6), materials: [skyMaterial]))

        updateSubscription = content.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            self?.update(dt: Float(event.deltaTime))
        }
    }

    func show(image: UIImage, tint: RGBColor, equipment: Equipment, skin: BladeSkin, aura: AuraTier) async {
        let newModel = await SceneBuilder.makeBlade(image: image, tint: tint, radius: Self.radius, skin: skin, equipment: equipment)
        if let aura = SceneBuilder.makeAura(tier: aura, radius: Self.radius, tipHeight: newModel.tipHeight) {
            newModel.root.addChild(aura)
        }
        // 2回目以降（付け替えたとき）はポンと跳ねさせる
        if model != nil { popTime = 0.35 }
        model?.root.removeFromParent()
        root.addChild(newModel.root)
        model = newModel
        update(dt: 0)
    }

    /// カメラをなめらかに別の向きへ動かす
    func setAngle(_ angle: PreviewAngle) {
        self.angle = angle
        camera.move(to: Self.cameraTransform(for: angle), relativeTo: root, duration: 0.45, timingFunction: .easeInOut)
    }

    private static func restingTurn(for angle: PreviewAngle) -> Float {
        angle == .top ? 0 : -0.3
    }

    /// 向きごとのカメラの位置。見る場所の高さはコマの中心あたり（床から 0.03〜0.05）
    private static func cameraTransform(for angle: PreviewAngle) -> Transform {
        let helper = Entity()
        switch angle {
        case .top:
            // 写真の上が画面の上になるよう、奥（-Z）を上にする
            helper.look(at: [0, 0.06, 0], from: [0, 0.9, 0], upVector: [0, 0, -1], relativeTo: nil)
        case .oblique:
            helper.look(at: [0, 0.045, 0], from: [0, 0.25, 0.72], relativeTo: nil)
        case .side:
            // シャフトがよく見えるよう、床すれすれの高さから少し寄って見る
            helper.look(at: [0, 0.05, 0], from: [0, 0.05, 0.62], relativeTo: nil)
        }
        return helper.transform
    }

    private func update(dt: Float) {
        guard let model else { return }
        popTime = max(0, popTime - dt)
        // カメラと同じくらいの速さで、止めておく向きへ回す
        let target = Self.restingTurn(for: angle)
        restingTurn += (target - restingTurn) * min(1, dt * 7)
        let pop = popTime > 0 ? sin(popTime / 0.35 * .pi) * 0.06 : 0
        model.root.position = [0, model.tipHeight + pop, 0]
        // 回さずに止めておく
        model.root.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
        model.spinner.orientation = simd_quatf(angle: restingTurn, axis: [0, 1, 0])
    }
}
