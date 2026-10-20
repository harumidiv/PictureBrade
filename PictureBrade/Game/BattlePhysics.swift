//
//  BattlePhysics.swift
//  PictureBrade
//

import simd

/// スタジアム上を回るコマ1つ分の状態。座標はスタジアム平面 (x, z) を SIMD2 の (x, y) で表す。
nonisolated struct TopState {
    enum Status: Equatable {
        case spinning
        case stopped   // スピンフィニッシュ
        case out       // オーバーフィニッシュ
    }

    let stats: BladeStats
    let radius: Float
    let mass: Float

    var position: SIMD2<Float>
    var velocity: SIMD2<Float> = .zero
    /// 回転の残量 0...1
    var spin: Float = 0
    /// 見た目上の回転角
    var angle: Float = 0
    var tilt: Float = 0
    var wobblePhase: Float = 0
    var status: Status = .spinning
    /// 場外に飛んだときの高さ
    var height: Float = 0
    var verticalVelocity: Float = 0
    var rushCooldown: Float = 0

    init(stats: BladeStats, position: SIMD2<Float>) {
        self.stats = stats
        self.radius = 0.13 + Float(stats.defense) * 0.03
        self.mass = 0.7 + Float(stats.defense) * 0.7
        self.position = position
    }

    var isActive: Bool { status == .spinning }
}

/// 衝突など、演出に使うイベント
nonisolated struct CollisionEvent {
    var point: SIMD2<Float>
    var strength: Float
    /// 壁（外周のレール）に当たったか。false ならコマ同士
    var isWall = false
}

nonisolated enum StadiumGeometry {
    static let radius: Float = 1.0
    /// すり鉢の深さ係数（高さ = bowl * r^2）
    static let bowl: Float = 0.2
    /// 場外ポケット（角度[rad]の中心）。プレイヤー側・相手側の真正面は避けて配置
    static let pocketAngles: [Float] = [0, 2 * .pi / 3, 4 * .pi / 3].map { $0 + .pi / 6 }
    static let pocketHalfWidth: Float = 0.2
    /// ポケットが外周を回る速さ[rad/s]（約21秒で1周。どこかのポケットが7秒ごとに同じ場所を通る）
    static let pocketRotationSpeed: Float = 0.3

    static func height(at r: Float) -> Float {
        bowl * min(r, radius) * min(r, radius)
    }

    /// rotation はポケットが回った角度
    static func isInPocket(_ position: SIMD2<Float>, rotation: Float = 0) -> Bool {
        let angle = atan2(position.y, position.x) - rotation
        return pocketAngles.contains { pocket in
            var diff = abs(angle - pocket).truncatingRemainder(dividingBy: 2 * .pi)
            if diff > .pi { diff = 2 * .pi - diff }
            return diff < pocketHalfWidth
        }
    }
}

nonisolated enum BattlePhysics {
    static let fixedStep: Float = 1.0 / 120.0

    /// tops を dt 秒進める。発生した衝突を返す。
    static func step(_ tops: inout [TopState], dt: Float, pocketRotation: Float = 0) -> [CollisionEvent] {
        var events: [CollisionEvent] = []
        for i in tops.indices {
            if let wallHit = integrate(&tops[i], dt: dt, pocketRotation: pocketRotation) {
                events.append(wallHit)
            }
        }
        for i in tops.indices {
            for j in tops.indices where j > i {
                var a = tops[i], b = tops[j]
                if let event = collide(&a, &b) {
                    events.append(event)
                }
                tops[i] = a
                tops[j] = b
            }
        }
        return events
    }

    /// 1コマ分を進める。壁に強く当たったときはその衝突を返す
    private static func integrate(_ top: inout TopState, dt: Float, pocketRotation: Float) -> CollisionEvent? {
        let speedStat = Float(top.stats.speed)
        let staminaStat = Float(top.stats.stamina)
        top.rushCooldown = max(0, top.rushCooldown - dt)

        switch top.status {
        case .spinning:
            let r = simd_length(top.position)
            // すり鉢の傾斜で中央に引き寄せられる
            var acceleration = -top.position * 2.4
            // 回転による軸の滑りでスタジアムを周回する
            if r > 0.02 {
                let tangent = SIMD2<Float>(-top.position.y, top.position.x) / r
                acceleration += tangent * (0.35 + 0.6 * speedStat) * top.spin
            }
            // 摩擦
            acceleration -= top.velocity * (0.75 - 0.35 * speedStat)
            top.velocity += acceleration * dt
            top.position += top.velocity * dt

            // 回転の減衰（速く動くほど減りやすい）
            let decay = (0.03 + 0.05 * (1 - staminaStat)) * (1 + 0.25 * simd_length(top.velocity))
            top.spin = max(0, top.spin - decay * dt)

            top.angle += (10 + 32 * top.spin) * dt
            let targetTilt: Float = top.spin > 0.35 ? 0.03 : 0.03 + (0.35 - top.spin) * 1.1
            top.tilt += (targetTilt - top.tilt) * min(1, dt * 4)
            top.wobblePhase += (5 + 8 * (1 - top.spin)) * dt

            if top.spin <= 0.06 {
                top.status = .stopped
            }
            return resolveWall(&top, dt: dt, pocketRotation: pocketRotation)

        case .stopped:
            top.velocity -= top.position * 1.2 * dt
            top.velocity *= max(0, 1 - 2.5 * dt)
            top.position += top.velocity * dt
            top.angle += 4 * top.spin * dt
            top.spin = max(0, top.spin - 0.1 * dt)
            top.tilt += (1.15 - top.tilt) * min(1, dt * 5)

        case .out:
            top.position += top.velocity * dt
            top.verticalVelocity -= 6 * dt
            top.height += top.verticalVelocity * dt
            top.angle += 20 * top.spin * dt
            top.tilt += (1.3 - top.tilt) * min(1, dt * 2)
        }
        return nil
    }

    private static func resolveWall(_ top: inout TopState, dt: Float, pocketRotation: Float) -> CollisionEvent? {
        let r = simd_length(top.position)
        let limit = StadiumGeometry.radius - top.radius
        guard r > limit else { return nil }
        let normal = top.position / r
        let radialSpeed = simd_dot(top.velocity, normal)
        let overThreshold: Float = 2.6 + Float(top.stats.defense) * 1.0

        if (StadiumGeometry.isInPocket(top.position, rotation: pocketRotation) && radialSpeed > 0.9) || radialSpeed > overThreshold {
            top.status = .out
            top.height = StadiumGeometry.height(at: StadiumGeometry.radius)
            top.verticalVelocity = 0.8 + radialSpeed * 0.4
            top.velocity += normal * 0.4
            return nil
        }
        top.position = normal * limit
        // 重い（防御の高い）コマほど衝撃や摩擦の影響を受けにくい
        let vulnerability = 1.3 - 0.6 * Float(top.stats.defense)

        // 壁との擦れ：触れている間ずっと、縁が擦れて回転が奪われ、滑りも遅くなる
        let tangentialVelocity = top.velocity - normal * radialSpeed
        let scrapeSpeed = simd_length(tangentialVelocity)
        top.spin = max(0, top.spin - (0.08 + 0.06 * scrapeSpeed) * vulnerability * dt)
        top.velocity -= tangentialVelocity * min(1, 1.5 * dt)

        guard radialSpeed > 0 else { return nil }
        // 壁への衝突：ぶつかる勢いが強いほど回転を大きく失う
        top.velocity -= normal * radialSpeed * 1.5
        let impactLoss = (0.01 + 0.05 * radialSpeed) * vulnerability
        top.spin = max(0, top.spin - impactLoss)
        guard radialSpeed > 0.4 else { return nil }
        return CollisionEvent(point: normal * StadiumGeometry.radius, strength: radialSpeed, isWall: true)
    }

    private static func collide(_ a: inout TopState, _ b: inout TopState) -> CollisionEvent? {
        guard a.isActive, b.isActive else { return nil }
        let delta = b.position - a.position
        let distance = simd_length(delta)
        let minDistance = a.radius + b.radius
        guard distance < minDistance, distance > 0.0001 else { return nil }

        let normal = delta / distance
        // めり込みを解消
        let overlap = minDistance - distance
        let totalMass = a.mass + b.mass
        a.position -= normal * overlap * (b.mass / totalMass)
        b.position += normal * overlap * (a.mass / totalMass)

        let approachSpeed = simd_dot(a.velocity - b.velocity, normal)
        guard approachSpeed > 0 else { return nil }

        let attackA = Float(a.stats.attack), attackB = Float(b.stats.attack)
        let restitution = 0.5 + 0.5 * max(attackA, attackB)
        let impulse = (1 + restitution) * approachSpeed / (1 / a.mass + 1 / b.mass)
        // 回転しているコマ同士は強く弾き合う
        let spinKick = 0.45 * (a.spin + b.spin) * 0.5
        a.velocity -= normal * (impulse / a.mass + spinKick / a.mass)
        b.velocity += normal * (impulse / b.mass + spinKick / b.mass)

        let base: Float = 0.012 + 0.05 * approachSpeed
        let defenseA = Float(a.stats.defense) + 0.6
        let defenseB = Float(b.stats.defense) + 0.6
        let damageA: Float = base * (0.6 + attackB) / defenseA
        let damageB: Float = base * (0.6 + attackA) / defenseB
        a.spin = max(0, a.spin - damageA)
        b.spin = max(0, b.spin - damageB)

        return CollisionEvent(point: a.position + normal * a.radius, strength: approachSpeed)
    }
}
