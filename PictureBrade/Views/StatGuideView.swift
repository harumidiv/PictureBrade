//
//  StatGuideView.swift
//  PictureBrade
//

import SwiftUI

/// コマを作る画面で、形や色と性能の関係を図で説明する
struct StatGuideView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("形で性能が決まる！")
                .font(.headline)
                .foregroundStyle(.white)
            StatGuideRow(
                label: "攻撃", color: .red, effect: "当てて削る\n弾き飛ばす",
                low: "ツルツル", high: "トゲトゲ"
            ) { isHigh in
                if isHigh {
                    StarShape(points: 9, innerRatio: 0.5).fill(.red)
                } else {
                    Circle().fill(.red.opacity(0.6))
                }
            }
            StatGuideRow(
                label: "防御", color: .blue, effect: "重くて\n飛ばされない",
                low: "小さい", high: "大きい"
            ) { isHigh in
                Ellipse()
                    .fill(isHigh ? .blue : .blue.opacity(0.6))
                    .frame(width: isHigh ? 44 : 18, height: isHigh ? 38 : 22)
            }
            StatGuideRow(
                label: "持久", color: .green, effect: "長く\n回り続ける",
                low: "隙間あり", high: "円盤"
            ) { isHigh in
                SpinningSilhouette(isDisc: isHigh)
            }
            StatGuideRow(
                label: "機動", color: .yellow, effect: "速く\n動き回る",
                low: "くすんだ色", high: "鮮やかな色"
            ) { isHigh in
                StarShape(points: 5, innerRatio: 0.75)
                    .fill(isHigh
                        ? AnyShapeStyle(AngularGradient(colors: [.red, .yellow, .green, .cyan, .purple, .red], center: .center))
                        : AnyShapeStyle(Color.gray.opacity(0.7)))
            }
            Divider().overlay(.white.opacity(0.2))
            RoughCutNote()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.06)))
    }
}

/// 「低い形 → 高い形」と、バトルでの効果を1行で見せる
private struct StatGuideRow<Figure: View>: View {
    let label: String
    let color: Color
    let effect: String
    let low: String
    let high: String
    @ViewBuilder let figure: (_ isHigh: Bool) -> Figure

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 40, height: 24)
                .background(Capsule().fill(color.opacity(0.75)))
            sample(isHigh: false, caption: low)
            Image(systemName: "arrow.right")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.5))
            sample(isHigh: true, caption: high)
            Text(effect)
                .font(.caption2.bold())
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func sample(isHigh: Bool, caption: String) -> some View {
        VStack(spacing: 2) {
            figure(isHigh)
                .frame(width: 46, height: 46)
            Text(caption)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(isHigh ? 0.9 : 0.55))
                .lineLimit(1)
                .fixedSize()
        }
        .frame(width: 58)
    }
}

/// 回したときに描く円（点線）と、その中の形。隙間が多いほど空気をかき回して持久が下がる
private struct SpinningSilhouette: View {
    let isDisc: Bool
    @State private var angle: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(.green.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
            Group {
                if isDisc {
                    Circle().fill(.green).padding(3)
                } else {
                    Capsule().fill(.green.opacity(0.6)).frame(width: 12, height: 40)
                }
            }
            .rotationEffect(.degrees(angle))
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                angle = 360
            }
        }
    }
}

/// 被写体が見つからず丸く切り抜かれたコマは性能ダウンすることを伝える
private struct RoughCutNote: View {
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(colors: [.teal.opacity(0.7), .green.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 44, height: 34)
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.7))
                    .offset(y: 5)
                Circle()
                    .strokeBorder(.orange, style: StrokeStyle(lineWidth: 2, dash: [3, 2]))
                    .frame(width: 32, height: 32)
            }
            .frame(width: 46, height: 46)
            Image(systemName: "arrow.right")
                .font(.caption.bold())
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("切り抜けないと丸になって性能ダウン！")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
                Text("被写体がはっきり写った写真を選ぶと本気の性能に")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// トゲの数と深さを指定できる星形
struct StarShape: Shape {
    var points: Int
    /// 内側の頂点の半径（外側に対する比）。1に近いほど丸い
    var innerRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio
        var path = Path()
        for i in 0..<(points * 2) {
            let radius = i.isMultiple(of: 2) ? outer : inner
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let point = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

#Preview {
    StatGuideView()
        .padding()
        .background(Theme.background)
}
