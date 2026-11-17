#!/bin/zsh
# 画面収録の動画から、横向きの App プレビュー動画を書き出す。
# 使い方: tools/MakeAppPreview/run.sh <画面収録.mp4> <出力.mp4> [幅 1920] [高さ 886]
set -euo pipefail
cd "$(dirname "$0")/../.."

[ $# -ge 2 ] || { echo "使い方: $0 <画面収録.mp4> <出力.mp4> [幅] [高さ]"; exit 1; }
SRC="$1"; OUT="$2"; W="${3:-1920}"; H="${4:-886}"

BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

swiftc -O -o "$BUILD_DIR/render" tools/MakeAppPreview/main.swift 2>&1 | grep "error:" || true
[ -x "$BUILD_DIR/render" ] || { echo "ビルドに失敗しました"; exit 1; }
"$BUILD_DIR/render" "$SRC" "$OUT" "$W" "$H"
