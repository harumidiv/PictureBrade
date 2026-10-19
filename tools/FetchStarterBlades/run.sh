#!/bin/zsh
# アプリ同梱用のコマ画像を Pexels から取得して PictureBrade/StarterBlades に書き出す。
# 使い方: tools/FetchStarterBlades/run.sh [--count 500] [--size 320] [--quality 0.8]
set -euo pipefail
cd "$(dirname "$0")/../.."

BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

swiftc -O -o "$BUILD_DIR/fetch" \
  tools/FetchStarterBlades/main.swift \
  PictureBrade/Models/Blade.swift \
  PictureBrade/Imaging/BladeAnalyzer.swift \
  2>&1 | grep -v "^$" || true

[ -x "$BUILD_DIR/fetch" ] || { echo "ビルドに失敗しました"; exit 1; }
"$BUILD_DIR/fetch" "$@"
