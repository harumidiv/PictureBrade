//
//  ImpactSound.swift
//  PictureBrade
//

import AVFoundation

/// ぶつかったときの音。音声ファイルは使わず、毎回その場で合成して鳴らす
final class ImpactSound {
    static let shared = ImpactSound()

    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var nextPlayer = 0
    private let format: AVAudioFormat
    private var lastPlayTime: TimeInterval = 0
    private var isConfigured = false

    private enum SessionState {
        case inactive
        case activating
        case active
    }

    private var sessionState = SessionState.inactive

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    }

    /// strength はぶつかる速さ（だいたい 0.4〜4）。強いほど大きく、長く、ギラついた音になる
    /// style はストーリーの報酬で選べる音の種類
    func play(strength: Float, isWall: Bool, style: HitSound = .metal) {
        // 同時にたくさん鳴ると濁るので、短い間隔の連続ヒットは間引く
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastPlayTime > 0.04 else { return }
        lastPlayTime = now

        guard startIfNeeded() else { return }
        let intensity = min(max((strength - 0.3) / 2.7, 0), 1)
        let buffer: AVAudioPCMBuffer? = switch style {
        case .metal: Self.synthesize(intensity: intensity, isWall: isWall, format: format)
        case .taiko: Self.synthesizeTaiko(intensity: intensity, isWall: isWall, format: format)
        case .bell: Self.synthesizeBell(intensity: intensity, isWall: isWall, format: format)
        case .pop: Self.synthesizePop(intensity: intensity, isWall: isWall, format: format)
        case .boing: Self.synthesizeBoing(intensity: intensity, isWall: isWall, format: format)
        case .chiptune: Self.synthesizeChiptune(intensity: intensity, isWall: isWall, format: format)
        }
        guard let buffer else { return }
        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
    }

    /// オーディオセッションを先に有効にしておく（バトルの準備中などに呼ぶ）。
    /// 有効にする処理はメインスレッドを止めることがあるので、裏で行う
    func prepare() {
        guard sessionState == .inactive else { return }
        sessionState = .activating
        if #available(iOS 27.0, *) {
            let session = AVAudioSession.sharedInstance()
            // マナーモード（消音スイッチ）中でも鳴らす。ほかのアプリの音楽は止めずに混ぜて鳴らす
            try? session.setCategory(.playback, options: [.mixWithOthers])
            session.activate(options: []) { activated, _ in
                Task { @MainActor in ImpactSound.shared.sessionDidActivate(activated) }
            }
        } else {
            DispatchQueue.global(qos: .userInitiated).async {
                let session = AVAudioSession.sharedInstance()
                try? session.setCategory(.playback, options: [.mixWithOthers])
                let activated = (try? session.setActive(true)) != nil
                Task { @MainActor in ImpactSound.shared.sessionDidActivate(activated) }
            }
        }
    }

    private func sessionDidActivate(_ activated: Bool) {
        // 失敗したら次に鳴らすときにもう一度試す
        sessionState = activated ? .active : .inactive
        if activated { _ = startIfNeeded() }
    }

    private func startIfNeeded() -> Bool {
        guard sessionState == .active else {
            prepare()
            return false
        }
        if !isConfigured {
            for _ in 0..<6 {
                let player = AVAudioPlayerNode()
                engine.attach(player)
                engine.connect(player, to: engine.mainMixerNode, format: format)
                players.append(player)
            }
            engine.mainMixerNode.outputVolume = 0.9
            isConfigured = true
        }
        if !engine.isRunning {
            do { try engine.start() } catch { return false }
        }
        return true
    }

    // MARK: - 合成

    /// 戦いの衝撃音。4つの音を重ねて、最後に軽く歪ませる
    /// - 破裂音：叩いた瞬間の「バチッ」
    /// - 金属音：濁った金属どうしの「ガキッ」（2つの音を掛け合わせて、耳ざわりな成分を出す）
    /// - 重低音：強い衝突ほど大きい「ドスン」（音程が下がっていく低い音）
    /// - 破片音：あとに残る「ジャリッ」（帯域を絞ったノイズ）
    private static func synthesize(intensity: Float, isWall: Bool, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = Float(format.sampleRate)
        let duration: Float = 0.18 + 0.5 * intensity
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let samples = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frameCount

        // 毎回少しずつ変えて、同じ音の繰り返しに聞こえないようにする
        func vary(_ value: Float) -> Float { value * Float.random(in: 0.9...1.1) }

        // 金属音：耳ざわりな高さの組み合わせを、掛け合わせ（リング変調）で濁らせる。強いほど低く重い
        struct Clang {
            let carrier: Float
            let modulator: Float
            let gain: Float
            let decay: Float
        }
        let clangBase = vary(isWall ? 520 : 900 - 350 * intensity)
        let clangRatios: [Float] = [1, 1.47, 2.13, 2.89, 3.71]
        let clangTime: Float = isWall ? 0.05 + 0.06 * intensity : 0.06 + 0.16 * intensity
        let clangs: [Clang] = clangRatios.enumerated().map { index, ratio in
            Clang(
                carrier: 2 * .pi * clangBase * ratio / sampleRate,
                modulator: 2 * .pi * vary(clangBase * 0.71 * ratio) / sampleRate,
                gain: 1 / (1 + Float(index) * 0.5),
                decay: exp(-1 / (clangTime / (1 + Float(index) * 0.4) * sampleRate))
            )
        }
        let clangGain: Float = (isWall ? 0.35 : 0.7) / clangs.reduce(0) { $0 + $1.gain }

        // 重低音：140Hz から 45Hz まで一気に下がる「ドスン」
        let thumpGain: Float = (isWall ? 0.6 : 0.35) + 0.65 * intensity
        let thumpDecay = exp(-1 / ((0.06 + 0.14 * intensity) * sampleRate))
        let thumpStart = vary(140), thumpEnd: Float = 45
        let thumpSweep: Float = 0.05 * sampleRate

        // 破裂音：とても短い、全帯域のノイズ
        let crackDecay = exp(-1 / (0.006 * sampleRate))
        let crackGain: Float = 0.8 + 0.4 * intensity

        // 破片音：中高域に絞ったノイズが、強いほど長く残る
        var debris = BandPass(center: vary(isWall ? 1800 : 3200), q: 0.9, sampleRate: sampleRate)
        let debrisDecay = exp(-1 / ((0.025 + 0.08 * intensity) * sampleRate))
        let debrisGain: Float = (isWall ? 1.2 : 0.9) * (0.4 + 0.8 * intensity)

        var clangEnvelopes = [Float](repeating: 1, count: clangs.count)
        var thumpEnvelope: Float = 1, crackEnvelope: Float = 1, debrisEnvelope: Float = 1
        var thumpPhase: Float = 0
        // 強いほど強く歪ませて荒々しくする
        let drive: Float = 1.6 + 1.6 * intensity
        // 歪ませると小さい音が持ち上がって余韻がいつまでも残るので、歪ませる前に全体を減衰させる
        var master: Float = 1
        let masterDecay = exp(-1 / ((0.07 + 0.18 * intensity) * sampleRate))
        let loudness: Float = 0.35 + 0.5 * intensity
        let attackFrames = sampleRate * 0.0005

        for frame in 0..<Int(frameCount) {
            let time = Float(frame)

            var clang: Float = 0
            for (index, partial) in clangs.enumerated() {
                clang += sin(partial.carrier * time) * sin(partial.modulator * time) * partial.gain * clangEnvelopes[index]
                clangEnvelopes[index] *= partial.decay
            }
            clang *= clangGain

            let sweep = min(1, time / thumpSweep)
            let thumpFrequency = thumpStart + (thumpEnd - thumpStart) * sweep
            thumpPhase += 2 * .pi * thumpFrequency / sampleRate
            let thump = sin(thumpPhase) * thumpGain * thumpEnvelope
            thumpEnvelope *= thumpDecay

            let white = Float.random(in: -1...1)
            let crack = white * crackGain * crackEnvelope
            crackEnvelope *= crackDecay
            let shard = debris.process(white) * debrisGain * debrisEnvelope
            debrisEnvelope *= debrisDecay

            let mixed = (clang + thump + crack + shard) * master
            master *= masterDecay
            let attack = min(1, time / attackFrames)
            let release = min(1, (Float(frameCount) - time) / (sampleRate * 0.015))
            samples[frame] = tanh(mixed * drive) / tanh(drive) * loudness * attack * release
        }
        return buffer
    }
}

// MARK: - 報酬の音

extension ImpactSound {
    /// duration 秒ぶんの空のバッファを作り、render で1サンプルずつ埋める（time は秒）。
    /// 最後は短くフェードアウトさせて、プツッと切れないようにする
    fileprivate static func render(
        duration: Float, format: AVAudioFormat, _ sample: (_ time: Float, _ sampleRate: Float) -> Float
    ) -> AVAudioPCMBuffer? {
        let sampleRate = Float(format.sampleRate)
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let samples = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frameCount
        let releaseFrames = sampleRate * 0.015
        for frame in 0..<Int(frameCount) {
            let release = min(1, (Float(frameCount) - Float(frame)) / releaseFrames)
            samples[frame] = sample(Float(frame) / sampleRate, sampleRate) * release
        }
        return buffer
    }

    /// 太鼓：低く沈む「ドン」に、皮を叩く「パン」を重ねる
    fileprivate static func synthesizeTaiko(intensity: Float, isWall: Bool, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let base = (isWall ? 130 : 95 - 25 * intensity) * Float.random(in: 0.95...1.05)
        let duration: Float = 0.25 + 0.35 * intensity
        let decay: Float = 1 / (0.09 + 0.2 * intensity)
        let loudness: Float = 0.45 + 0.45 * intensity
        var phase: Float = 0
        var skin = BandPass(center: isWall ? 900 : 600, q: 1.2, sampleRate: Float(format.sampleRate))
        return render(duration: duration, format: format) { time, sampleRate in
            // 叩いた直後は少し高く、すぐ下がる
            let frequency = base * (1 + 0.6 * exp(-time * 40))
            phase += 2 * .pi * frequency / sampleRate
            let body = sin(phase) * exp(-time * decay)
            let slap = skin.process(Float.random(in: -1...1)) * exp(-time * 70) * (isWall ? 2.5 : 1.6)
            return tanh((body + slap) * 1.8) * loudness
        }
    }

    /// 鈴：かん高い金属の倍音が「チリーン」と長めに響く
    fileprivate static func synthesizeBell(intensity: Float, isWall: Bool, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let base = (isWall ? 1500 : 2100 - 500 * intensity) * Float.random(in: 0.94...1.06)
        let partials: [(ratio: Float, gain: Float, decay: Float)] = [
            (1, 1, 3.5), (2.76, 0.5, 6), (5.4, 0.3, 10), (8.93, 0.15, 16),
        ]
        let duration: Float = 0.4 + 0.5 * intensity
        let loudness: Float = 0.22 + 0.25 * intensity
        // 2つ並べて少しずらし、鈴らしく揺らす
        let detune: Float = 1.004
        return render(duration: duration, format: format) { time, _ in
            var value: Float = 0
            for partial in partials {
                let frequency = base * partial.ratio
                let ring = sin(2 * .pi * frequency * time) + sin(2 * .pi * frequency * detune * time)
                value += ring * 0.5 * partial.gain * exp(-time * partial.decay)
            }
            let attack = min(1, time / 0.002)
            return value / 1.95 * loudness * attack
        }
    }

    /// ポップ：音程が上がる短い「ポンッ」（泡がはじけるような音）
    fileprivate static func synthesizePop(intensity: Float, isWall: Bool, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let start = (isWall ? 300 : 420) * Float.random(in: 0.85...1.2)
        let end = start * (2.2 + intensity)
        let duration: Float = 0.09 + 0.07 * intensity
        let loudness: Float = 0.45 + 0.35 * intensity
        var phase: Float = 0
        return render(duration: duration, format: format) { time, sampleRate in
            let progress = min(1, time / 0.035)
            phase += 2 * .pi * (start + (end - start) * progress) / sampleRate
            let envelope = min(1, time / 0.002) * exp(-time * 38)
            return sin(phase) * envelope * loudness
        }
    }

    /// びよーん：バネのように音程がゆれながら下がっていく
    fileprivate static func synthesizeBoing(intensity: Float, isWall: Bool, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let base = (isWall ? 260 : 190) * Float.random(in: 0.9...1.1)
        let duration: Float = 0.3 + 0.3 * intensity
        let loudness: Float = 0.35 + 0.35 * intensity
        let wobbleRate: Float = 14 + 6 * intensity
        var phase: Float = 0
        return render(duration: duration, format: format) { time, sampleRate in
            let wobble = 1 + 0.45 * exp(-time * 6) * sin(2 * .pi * wobbleRate * time)
            let frequency = base * wobble * (1 + 0.8 * exp(-time * 25))
            phase += 2 * .pi * frequency / sampleRate
            // 少しだけ倍音を足して、ゴムっぽい音にする
            let tone = sin(phase) + 0.3 * sin(2 * phase)
            let envelope = min(1, time / 0.003) * exp(-time * (5 - 2 * intensity))
            return tone / 1.3 * envelope * loudness
        }
    }

    /// ピコピコ：レトロゲーム風の矩形波で、2音を素早く鳴らす
    fileprivate static func synthesizeChiptune(intensity: Float, isWall: Bool, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        // 半音単位でずらして、毎回ちがうメロディーに聞こえるようにする
        let semitone = Float(Int.random(in: -2...2))
        let first = (isWall ? 523 : 784) * pow(2, semitone / 12)
        let second = first * (intensity > 0.5 ? 2 : 1.5)
        let step: Float = 0.045
        let duration: Float = step * 2 + 0.03 + 0.08 * intensity
        let loudness: Float = 0.16 + 0.14 * intensity
        var phase: Float = 0
        return render(duration: duration, format: format) { time, sampleRate in
            let frequency = time < step ? first : second
            phase += frequency / sampleRate
            let square: Float = fract(phase) < 0.5 ? 1 : -1
            let envelope = time < step * 2 ? 1 : exp(-(time - step * 2) * 30)
            return square * envelope * loudness
        }
    }
}

private func fract(_ value: Float) -> Float { value - floor(value) }

/// 帯域通過フィルター（指定した高さのあたりだけを通す）
private struct BandPass {
    private let b0: Float, b2: Float, a1: Float, a2: Float
    private var x1: Float = 0, x2: Float = 0, y1: Float = 0, y2: Float = 0

    init(center: Float, q: Float, sampleRate: Float) {
        let omega = 2 * Float.pi * center / sampleRate
        let alpha = sin(omega) / (2 * q)
        let a0 = 1 + alpha
        b0 = alpha / a0
        b2 = -alpha / a0
        a1 = -2 * cos(omega) / a0
        a2 = (1 - alpha) / a0
    }

    mutating func process(_ x: Float) -> Float {
        let y = b0 * x + b2 * x2 - a1 * y1 - a2 * y2
        x2 = x1; x1 = x
        y2 = y1; y1 = y
        return y
    }
}
