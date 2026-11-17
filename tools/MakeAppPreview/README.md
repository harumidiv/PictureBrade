# MakeAppPreview

iPhone の画面収録（縦向き）から、App Store 用の横向きプレビュー動画を作る macOS 用ツールです。
AVFoundation と Core Graphics だけで動くので、ffmpeg などは要りません。

## 使い方

リポジトリのルートで実行します。

```sh
tools/MakeAppPreview/run.sh ~/Desktop/画面収録.mp4 ~/Desktop/PhotoBlade_AppPreview_1920x886.mp4            # 通常のAppプレビュー枠
tools/MakeAppPreview/run.sh ~/Desktop/画面収録.mp4 ~/Desktop/PhotoBlade_AppPreview_1920x1280.mp4 1920 1280  # 3:2 の枠
```

出力は H.264・30fps、音声は AAC ステレオ 256kbps・48kHz です。

## 場面の構成を変える

`main.swift` の `segments` に、使う場面を上から順に書きます。秒数は **元の画面収録の秒数**です。

- `hitSeg(秒数, (1行目, 2行目))`: 当たった瞬間の前後を切り出す。当たった瞬間に白いフラッシュ・揺れ・ズーム・0.35倍のスロー・「ドカッ！」などの文字が入る。アリーナ部分だけを大きく見せる。
- `Segment(mode: .full, pieces: [n(開始秒, 長さ)], cap: ...)`: メニューや YOU WIN などを、画面全体のカードで見せる。
- 最後の `endCard: true` の場面がロゴの締めの画面。`Piece(... freeze: true)` でその秒の画面を止めて見せる。

いまの `segments` は 2026年11月17日 15:03 の画面収録（約224秒）に合わせた秒数です。撮り直したら秒数を合わせ直してください。

## 当たった瞬間の秒数を探す

```sh
swift tools/MakeAppPreview/FindHits.swift ~/Desktop/画面収録.mp4
```

音が急に大きくなった秒数を一覧で出します。ほとんどがブレードの当たった音です。メニューの効果音も混ざるので、出た秒数の画面を見て選んでください。

## 切り出し位置

- 元の動画は 1170×2532（iPhone の画面収録）を前提にしています。
- 画面全体のカードは、ステータスバーと録画中の赤い表示を隠すため、上から150px を切り取っています。
- バトルのアリーナは y=640〜1940 を切り出しています。端末が違って位置がずれたら `fullCrop` / `arenaCrop` を直してください。
