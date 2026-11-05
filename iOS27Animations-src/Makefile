# iOS 27 Animations — roothide 越狱版
# 使用 roothide/theos fork 的 roothide 打包方案 (THEOS_PACKAGE_SCHEME=roothide)
# THEOS 用 ?= 以便 macOS/GitHub Actions 通过环境变量覆盖

export THEOS ?= /home/user/.theos-roothide
export THEOS_PACKAGE_SCHEME = roothide
export ARCHS = arm64e
export TARGET = iphone:clang:16.5:15.0
export SYSROOT = $(THEOS)/sdks/iPhoneOS16.5.sdk

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

# ---- 主 Tweak ----
TWEAK_NAME = iOS27Animations
iOS27Animations_FILES = Tweak.x AnimHome.x AnimLockscreen.x AnimIsland.x Helpers.m
iOS27Animations_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
iOS27Animations_FRAMEWORKS = UIKit QuartzCore CoreGraphics Foundation

# Linux 上 clang 默认调 GNU ld 无法链 Mach-O，必须 -fuse-ld=lld；
# macOS 的 Apple clang 自带 ld64，绝不能指定 lld（否则找 lld 失败）
ifeq ($(shell uname -s),Linux)
iOS27Animations_LDFLAGS += -fuse-ld=lld
endif
iOS27Animations_LDFLAGS += -lroothide

# 设置面板为纯 plist（PreferenceLoader 内联 specifiers，无需编译的 arm64e Bundle 二进制）

include $(THEOS_MAKE_PATH)/tweak.mk
