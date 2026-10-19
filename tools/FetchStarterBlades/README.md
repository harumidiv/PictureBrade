# FetchStarterBlades

Pexels API で人物写真を取得し、Vision で被写体を切り抜いて、アプリ同梱用のファイター（コマ）を作る macOS 用ツールです。

## 使い方

1. `Config/Secrets.xcconfig` に Pexels の APIキーを書く（`Config/Secrets.xcconfig.example` 参照）
2. リポジトリのルートで実行する

```sh
tools/FetchStarterBlades/run.sh            # 500件・320px
tools/FetchStarterBlades/run.sh --count 100 --size 320 --quality 0.8
```

出力先は `PictureBrade/StarterBlades/` です。

- `pexels-<写真ID>.heic`: 切り抜き済みのコマ画像（透過HEIC）
- `starter-blades.json`: ステータスと撮影者クレジットを含む一覧ファイル

Xcode のフォルダ同期により、ここに置いたファイルはそのままアプリに同梱されます。

## 画質について

- 出力サイズの初期値は 320px です。アプリ内の最大表示サイズ（カード 84pt × 3x ≒ 252px）より大きくして、ぼやけを防いでいます。
- 被写体の長辺が出力サイズに満たない写真は、拡大するとぼやけるため採用しません。
- 縮小は高品質補間で行い、HEIC（品質 0.8）で保存します。

## 不採用になる写真

- 被写体が見つからない写真
- 3人以上が写っている写真
- 被写体が小さすぎる写真（拡大するとぼやけるため）
- 被写体が画面の端で大きく見切れている写真

## 注意

Pexels の利用規約は、許可のない大量・体系的なコピーを禁止しています（第8条）。このツールの実行は、その点を理解した上で行ってください。また API のレート制限は 200リクエスト/時です。このツールが呼ぶ検索APIは20〜30回程度です（画像本体は images.pexels.com から取得します）。
