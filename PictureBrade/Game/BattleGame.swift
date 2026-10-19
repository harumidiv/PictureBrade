//
//  BattleGame.swift
//  PictureBrade
//

import Observation
import RealityKit
import SwiftUI
import UIKit

/// バトル1試合分の進行と 3D シーンの同期を担当する。
@Observable
final class BattleGame {
    enum Finish: Equatable {
        case spin
        case over

        var title: String {
            switch self {
            case .spin: "SPIN FINISH!"
            case .over: "OVER FINISH!"
            }
        }

        var points: Int {
            switch self {
            case .spin: 1
            case .over: 2
            }
        }
    }

    enum RoundResult: Equatable {
        case playerWins(Finish)
        case cpuWins(Finish)
        case draw
    }

    enum Phase: Equatable {
        case loading
        case aiming
        case battle
        case roundOver(RoundResult)
        case matchOver(playerWon: Bool)
    }

    enum Mode: Identifiable {
        /// 25体の文字を順に倒す
        case story
        /// ランダムな文字・絵文字と連戦する
        case endless

        var id: Self { self }
    }

    static let winningScore = 3
    static let maxDragDistance: CGFloat = 160

    let player: Blade
    private(set) var cpu: Blade
    let playerImage: UIImage
    private(set) var cpuImage: UIImage
    /// CPU の腕前 0...1
    private(set) var cpuSkill: Float

    private(set) var phase: Phase = .loading
    private(set) var playerScore = 0
    private(set) var cpuScore = 0
    private(set) var round = 1
    /// 連勝数（負けると 0 に戻る）
    private(set) var winStreak = 0
    /// 直前に負けたときの連勝記録
    private(set) var streakBeforeLoss = 0
    private(set) var playerSpin: Float = 0
    private(set) var cpuSpin: Float = 0
    private(set) var rushProgress: Float = 1

    @ObservationIgnored private var tops: [TopState] = []
    @ObservationIgnored private var models: [BladeModel] = []
    @ObservationIgnored private let worldRoot = Entity()
    @ObservationIgnored private let camera = PerspectiveCamera()
    @ObservationIgnored private let cameraBase: SIMD3<Float> = [0, 3.0, 2.4]
    @ObservationIgnored private var cameraShake: Float = 0
    @ObservationIgnored private var sparks: [(entity: ModelEntity, age: Float)] = []
    @ObservationIgnored private var accumulator: Float = 0
    @ObservationIgnored private var steering: SIMD2<Float> = .zero
    @ObservationIgnored private var finishDelay: Float = 0
    @ObservationIgnored private var pendingResult: RoundResult?
    @ObservationIgnored private var lastHapticTime: Float = 0
    @ObservationIgnored private var time: Float = 0
    @ObservationIgnored private var updateSubscription: EventSubscription?
    @ObservationIgnored private let haptics = UIImpactFeedbackGenerator(style: .heavy)

    private static let playerStart = SIMD2<Float>(0, 0.62)
    private static let cpuStart = SIMD2<Float>(0, -0.62)
    private static let playerIndex = 0
    private static let cpuIndex = 1

    let mode: Mode

    init(player: Blade, playerImage: UIImage, cpu: Blade, cpuImage: UIImage, cpuSkill: Float = 0.5, mode: Mode = .story) {
        self.mode = mode
        self.player = player
        self.cpu = cpu
        self.playerImage = playerImage
        self.cpuImage = cpuImage
        self.cpuSkill = cpuSkill
    }

    // MARK: - Scene setup

    func setUp(content: inout RealityViewCameraContent) async {
        content.camera = .virtual
        content.add(worldRoot)

        camera.camera.fieldOfViewInDegrees = 60
        camera.look(at: [0, 0, 0.1], from: cameraBase, relativeTo: nil)
        worldRoot.addChild(camera)

        let sun = DirectionalLight()
        sun.light.intensity = 4000
        sun.shadow = DirectionalLightComponent.Shadow(maximumDistance: 6, depthBias: 2)
        sun.look(at: .zero, from: [1.5, 4, 2], relativeTo: nil)
        worldRoot.addChild(sun)

        let fill = PointLight()
        fill.light.intensity = 60_000
        fill.light.attenuationRadius = 8
        fill.position = [-1.5, 2, -1]
        worldRoot.addChild(fill)

        worldRoot.addChild(SceneBuilder.makeStadium())

        tops = [
            TopState(stats: player.stats, position: Self.playerStart),
            TopState(stats: cpu.stats, position: Self.cpuStart),
        ]
        let playerModel = await SceneBuilder.makeBlade(image: playerImage, tint: player.tint, radius: tops[0].radius)
        let cpuModel = await SceneBuilder.makeBlade(image: cpuImage, tint: cpu.tint, radius: tops[1].radius)
        models = [playerModel, cpuModel]
        models.forEach { worldRoot.addChild($0.root) }

        updateSubscription = content.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            self?.update(dt: Float(event.deltaTime))
        }
        resetRound()
    }

    // MARK: - Input

    /// 引っ張った方向の逆に打ち出す（スリングショット）。drag は画面座標の移動量。
    func launch(drag: CGSize) {
        guard phase == .aiming else { return }
        let power = Self.power(for: drag)
        guard power > 0.1 else { return }
        let pull = SIMD2<Float>(Float(drag.width), Float(drag.height))
        let direction = -simd_normalize(pull)

        tops[Self.playerIndex].velocity = direction * (0.6 + 2.2 * power)
        tops[Self.playerIndex].spin = 0.55 + 0.45 * power

        // CPU は中央方向へランダムな角度で打ち出す。腕前が高いほど強く、まっすぐ狙う
        let cpuPower = Float.random(in: (0.55 + 0.3 * cpuSkill)...(0.85 + 0.15 * cpuSkill))
        let spread = 0.9 - 0.5 * cpuSkill
        let cpuAngle = Float.random(in: -spread...spread)
        let toCenter = SIMD2<Float>(sin(cpuAngle), cos(cpuAngle))
        tops[Self.cpuIndex].velocity = toCenter * (0.6 + 2.2 * cpuPower)
        tops[Self.cpuIndex].spin = 0.55 + 0.45 * cpuPower

        phase = .battle
        haptics.impactOccurred(intensity: CGFloat(power))
    }

    static func power(for drag: CGSize) -> Float {
        Float(min(1, hypot(drag.width, drag.height) / maxDragDistance))
    }

    /// バトル中のドラッグでコマを少しだけ操作できる
    func steer(drag: CGSize?) {
        guard let drag else {
            steering = .zero
            return
        }
        let vector = SIMD2<Float>(Float(drag.width), Float(drag.height)) / Float(Self.maxDragDistance)
        let length = simd_length(vector)
        steering = length > 1 ? vector / length : vector
    }

    func rush() {
        guard phase == .battle else { return }
        rush(from: Self.playerIndex, to: Self.cpuIndex)
    }

    func nextRound() {
        guard case .roundOver = phase else { return }
        round += 1
        resetRound()
    }

    /// 試合後、同じ自分のコマのまま次の相手と戦う（連戦・やり直し）
    func challengeNext(cpu nextCPU: Blade, image: UIImage, skill: Float) async {
        guard case .matchOver = phase else { return }
        phase = .loading
        cpu = nextCPU
        cpuImage = image
        cpuSkill = skill

        models[Self.cpuIndex].root.removeFromParent()
        let radius = TopState(stats: nextCPU.stats, position: Self.cpuStart).radius
        let model = await SceneBuilder.makeBlade(image: image, tint: nextCPU.tint, radius: radius)
        models[Self.cpuIndex] = model
        worldRoot.addChild(model.root)

        playerScore = 0
        cpuScore = 0
        round = 1
        resetRound()
    }

    func restartMatch() {
        playerScore = 0
        cpuScore = 0
        round = 1
        resetRound()
    }

    private func rush(from attacker: Int, to target: Int) {
        guard tops[attacker].isActive, tops[attacker].rushCooldown <= 0 else { return }
        let delta = tops[target].position - tops[attacker].position
        guard simd_length(delta) > 0.01 else { return }
        let attack = Float(tops[attacker].stats.attack)
        tops[attacker].velocity += simd_normalize(delta) * (1.6 + attack)
        tops[attacker].spin = max(0, tops[attacker].spin - 0.05)
        tops[attacker].rushCooldown = 3
    }

    private func resetRound() {
        tops[Self.playerIndex] = TopState(stats: player.stats, position: Self.playerStart)
        tops[Self.cpuIndex] = TopState(stats: cpu.stats, position: Self.cpuStart)
        tops[Self.cpuIndex].rushCooldown = 2
        pendingResult = nil
        finishDelay = 0
        steering = .zero
        accumulator = 0
        phase = .aiming
        syncEntities()
    }

    // MARK: - Update loop

    private func update(dt rawDt: Float) {
        let dt = min(rawDt, 1.0 / 20.0)
        time += dt

        switch phase {
        case .loading:
            return
        case .aiming:
            // 発射前はコマを浮かせてゆっくり回す
            for i in tops.indices {
                tops[i].angle += 1.5 * dt
            }
        case .battle, .roundOver, .matchOver:
            simulate(dt: dt)
        }
        updateEffects(dt: dt)
        syncEntities()
        updateHUD()
    }

    private func simulate(dt: Float) {
        if phase == .battle {
            applySteering(dt: dt)
            runCPU(dt: dt)
        }
        accumulator += dt
        while accumulator >= BattlePhysics.fixedStep {
            accumulator -= BattlePhysics.fixedStep
            let events = BattlePhysics.step(&tops, dt: BattlePhysics.fixedStep)
            events.forEach(handleCollision)
        }
        if phase == .battle {
            checkFinish(dt: dt)
        }
    }

    private func applySteering(dt: Float) {
        guard tops[Self.playerIndex].isActive, simd_length(steering) > 0.05 else { return }
        tops[Self.playerIndex].velocity += steering * 2.0 * dt
        tops[Self.playerIndex].spin = max(0, tops[Self.playerIndex].spin - 0.01 * dt)
    }

    private func runCPU(dt: Float) {
        let cpuTop = tops[Self.cpuIndex]
        guard cpuTop.isActive, cpuTop.rushCooldown <= 0 else { return }
        // 攻撃型ほど積極的に突進する
        let rushChancePerSecond = 0.1 + Float(cpu.stats.attack) * 0.4 + cpuSkill * 0.4
        if Float.random(in: 0...1) < rushChancePerSecond * dt {
            rush(from: Self.cpuIndex, to: Self.playerIndex)
        }
    }

    private func checkFinish(dt: Float) {
        if pendingResult == nil {
            let playerFinish = finish(for: tops[Self.playerIndex])
            let cpuFinish = finish(for: tops[Self.cpuIndex])
            switch (playerFinish, cpuFinish) {
            case (nil, nil):
                return
            case (let finish?, nil):
                pendingResult = .cpuWins(finish)
            case (nil, let finish?):
                pendingResult = .playerWins(finish)
            case (_?, _?):
                pendingResult = .draw
            }
            finishDelay = 1.2
            haptics.impactOccurred(intensity: 1)
        }
        finishDelay -= dt
        guard finishDelay <= 0, let result = pendingResult else { return }

        switch result {
        case .playerWins(let finish): playerScore += finish.points
        case .cpuWins(let finish): cpuScore += finish.points
        case .draw: break
        }
        if playerScore >= Self.winningScore || cpuScore >= Self.winningScore {
            let playerWon = playerScore >= Self.winningScore
            if !playerWon { streakBeforeLoss = winStreak }
            winStreak = playerWon ? winStreak + 1 : 0
            phase = .matchOver(playerWon: playerWon)
        } else {
            phase = .roundOver(result)
        }
    }

    private func finish(for top: TopState) -> Finish? {
        switch top.status {
        case .spinning: nil
        case .stopped: .spin
        case .out: .over
        }
    }

    private func handleCollision(_ event: CollisionEvent) {
        let spark = SceneBuilder.makeSpark()
        let y = StadiumGeometry.height(at: simd_length(event.point)) + 0.05
        spark.position = [event.point.x, y, event.point.y]
        spark.scale = .init(repeating: 0.2 + min(event.strength, 3) * 0.4)
        worldRoot.addChild(spark)
        sparks.append((spark, 0))

        cameraShake = max(cameraShake, min(event.strength * 0.02, 0.06))
        if time - lastHapticTime > 0.08 {
            lastHapticTime = time
            haptics.impactOccurred(intensity: CGFloat(min(1, 0.3 + event.strength * 0.3)))
        }
    }

    private func updateEffects(dt: Float) {
        for index in sparks.indices.reversed() {
            sparks[index].age += dt
            let entity = sparks[index].entity
            if sparks[index].age > 0.18 {
                entity.removeFromParent()
                sparks.remove(at: index)
            } else {
                entity.scale *= 1 + dt * 6
            }
        }

        cameraShake = max(0, cameraShake - dt * 0.25)
        let offset = SIMD3<Float>(
            .random(in: -1...1), .random(in: -1...1), .random(in: -1...1)
        ) * cameraShake
        camera.position = cameraBase + offset
    }

    private func syncEntities() {
        for (top, model) in zip(tops, models) {
            let r = simd_length(top.position)
            let baseHeight: Float
            switch top.status {
            case .out:
                baseHeight = top.height
            default:
                baseHeight = StadiumGeometry.height(at: r)
            }
            let hover: Float = phase == .aiming ? 0.25 + 0.02 * sin(time * 3) : 0
            model.root.position = [top.position.x, baseHeight + model.tipHeight + hover, top.position.y]

            let wobbleAxis = SIMD3<Float>(cos(top.wobblePhase), 0, sin(top.wobblePhase))
            model.root.orientation = simd_quatf(angle: top.tilt, axis: wobbleAxis)
            model.spinner.orientation = simd_quatf(angle: -top.angle, axis: [0, 1, 0])
        }
    }

    private func updateHUD() {
        let newPlayerSpin = tops[Self.playerIndex].spin
        let newCpuSpin = tops[Self.cpuIndex].spin
        let newRush = 1 - tops[Self.playerIndex].rushCooldown / 3
        // 細かい変化で SwiftUI を毎フレーム更新しないよう間引く
        if abs(newPlayerSpin - playerSpin) > 0.005 { playerSpin = newPlayerSpin }
        if abs(newCpuSpin - cpuSpin) > 0.005 { cpuSpin = newCpuSpin }
        if abs(newRush - rushProgress) > 0.02 || (newRush >= 1 && rushProgress < 1) { rushProgress = newRush }
    }
}
extension BattleGame: Identifiable {}
