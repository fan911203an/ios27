#!/bin/bash
# build-macos.sh — 在 macOS 上构建 iPhone 14 Pro Max (arm64e, iOS 16) 可用的 .deb
# 需要: Xcode Command Line Tools, git, curl
# 用法: bash build-macos.sh
set -e

THEOS_DIR="$HOME/theos-roothide"
PROJ="$(cd "$(dirname "$0")" && pwd)"

echo "==> [1/3] 安装 roothide Theos fork（支持 arm64e new ABI）"
if [ ! -d "$THEOS_DIR" ]; then
    git clone --recursive https://github.com/roothide/theos.git "$THEOS_DIR"
    # 下载 iOS SDK（arm64e 需要 iPhoneOS 15+ SDK；用 git sparse-checkout 从 theos/sdks 检出）
    mkdir -p "$THEOS_DIR/sdks"
    if [ ! -d "$THEOS_DIR/sdks/iPhoneOS16.5.sdk" ]; then
        echo "==> 检出 iPhoneOS16.5.sdk（theos/sdks，约 230MB）"
        git clone --filter=blob:none --sparse https://github.com/theos/sdks.git /tmp/theos-sdks
        cd /tmp/theos-sdks
        git sparse-checkout set iPhoneOS16.5.sdk
        mv iPhoneOS16.5.sdk "$THEOS_DIR/sdks/"
        cd - >/dev/null && rm -rf /tmp/theos-sdks
    fi
fi

echo "==> [2/3] 构建（roothide scheme / arm64e / Apple ld64）"
export THEOS="$THEOS_DIR"
export THEOS_PACKAGE_SCHEME=roothide
export ARCHS=arm64e
cd "$PROJ"
make clean >/dev/null 2>&1 || true
make package FINALPACKAGE=1

DEB=$(ls packages/*.deb | head -1)
echo ""
echo "==> [3/3] 构建完成"
echo "产物: $PROJ/$DEB"
echo "这是真正的 arm64e (new ABI) 包，可直接在 Dopamine/roothide (arm64e 设备) 安装。"
echo ""
echo "请把这个 .deb 传到你的 iPhone 上用 Sileo/Zebra 安装，然后注销(Respring)。"
