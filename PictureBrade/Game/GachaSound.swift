//
//  GachaSound.swift
//  PictureBrade
//

import AVFoundation

/// ガチャの効果音。ぶつかったときの音と同じく、音声ファイルを使わずその場で合成する
enum GachaSound {
    /// カプセルがカタッと揺れる音
    static func rattle() {
        ImpactSound.shared.play { format in
            let pitch = Float.random(in: 0.9...1.15)
            return ImpactSound.render(duration: 0.07, format: format) { time, _ in
                // プラスチックがぶつかる、短く乾いた音
                let click = sin(2 * .pi * 1900 * pitch * time) * 0.6 + sin(2 * .pi * 3100 * pitch * time) * 0.3
                let noise = Float.random(in: -1...1) * 0.4
                return (click + noise) * exp(-time * 90) * 0.35
            }
        }
    }

    /// カプセルが開く前に、力がたまっていく音。いいものが出るときほど長く、高くのぼる
    static func charge(duration: Float, rarity: PartRarity) {
        ImpactSound.shared.play { format in
            let start: Float = 220
            let end: Float = rarity >= .superRare ? 1400 : 900
            var phase: Float = 0
            var shimmerPhase: Float = 0
            return ImpactSound.render(duration: duration, format: format) { time, sampleRate in
                let progress = min(1, time / duration)
                let frequency = start * pow(end / start, progress * progress)
                phase += 2 * .pi * frequency / sampleRate
                shimmerPhase += 2 * .pi * frequency * 1.5 / sampleRate
                // だんだん速くなるふるえ
                let tremolo = 0.6 + 0.4 * sin(2 * .pi * (6 + 18 * progress) * time)
                let tone = sin(phase) * 0.7 + sin(shimmerPhase) * (rarity >= .superRare ? 0.35 : 0.15)
                let swell = min(1, time / 0.1) * (0.25 + 0.75 * progress)
                return tone * tremolo * swell * 0.28
            }
        }
    }

    /// カプセルが割れる音。レアリティが高いほど和音が豪華になる
    static func burst(rarity: PartRarity) {
        ImpactSound.shared.play { format in
            // ド・ミ・ソ・ド…と重ねる音（半音の数）
            let chord: [Float] = switch rarity {
            case .normal: [0, 12]
            case .rare: [0, 4, 7, 12]
            case .superRare: [0, 4, 7, 12, 16]
            case .ultraRare: [0, 4, 7, 12, 16, 19, 24]
            }
            let base: Float = 523.25
            let duration: Float = rarity >= .superRare ? 1.6 : 0.9
            var whoosh = LowPass(cutoff: 2500, sampleRate: Float(format.sampleRate))
            return ImpactSound.render(duration: duration, format: format) { time, _ in
                // 「パーン」と割れるノイズ
                let pop = whoosh.process(Float.random(in: -1...1)) * exp(-time * 18) * 1.2
                var notes: Float = 0
                for (index, semitone) in chord.enumerated() {
                    // 下の音から少しずつずらして鳴らす（アルペジオ）
                    let onset = Float(index) * (rarity == .ultraRare ? 0.06 : 0.035)
                    guard time > onset else { continue }
                    let t = time - onset
                    let frequency = base * pow(2, semitone / 12)
                    let bell = sin(2 * .pi * frequency * t) + 0.3 * sin(2 * .pi * frequency * 2 * t) + 0.12 * sin(2 * .pi * frequency * 3 * t)
                    notes += bell * min(1, t / 0.004) * exp(-t * (rarity >= .superRare ? 2.2 : 3.5))
                }
                notes /= Float(chord.count).squareRoot() * 1.4
                return (pop * 0.35 + notes * 0.45)
            }
        }
    }

    /// パーツが1つ出てくる音。index が進むほど音が上がる。SR 以上はキラキラした音を足す
    static func reveal(index: Int, rarity: PartRarity) {
        ImpactSound.shared.play { format in
            let scale: [Float] = [0, 2, 4, 5, 7, 9, 11, 12, 14, 16]
            let frequency: Float = 880 * pow(2, scale[index % scale.count] / 12)
            let sparkle = rarity >= .superRare
            let duration: Float = sparkle ? 0.9 : 0.35
            // キラキラ音：ランダムな高さの小さな鈴をいくつか鳴らす
            let tinkles: [(onset: Float, frequency: Float)] = sparkle
                ? (0..<6).map { _ in (Float.random(in: 0.02...0.4), Float.random(in: 2400...4200)) }
                : []
            return ImpactSound.render(duration: duration, format: format) { time, _ in
                var value = (sin(2 * .pi * frequency * time) + 0.25 * sin(2 * .pi * frequency * 2.01 * time))
                    * min(1, time / 0.003) * exp(-time * 9) * 0.5
                for tinkle in tinkles where time > tinkle.onset {
                    let t = time - tinkle.onset
                    value += sin(2 * .pi * tinkle.frequency * t) * exp(-t * 14) * 0.18
                }
                return value * (rarity == .ultraRare ? 0.6 : 0.45)
            }
        }
    }
}

/// 高い音を削るフィルター（ノイズをやわらかい「シャッ」にする）
private struct LowPass {
    private let alpha: Float
    private var last: Float = 0

    init(cutoff: Float, sampleRate: Float) {
        let rc = 1 / (2 * Float.pi * cutoff)
        let dt = 1 / sampleRate
        alpha = dt / (rc + dt)
    }

    mutating func process(_ x: Float) -> Float {
        last += alpha * (x - last)
        return last
    }
}
