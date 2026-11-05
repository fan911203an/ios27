export THEOS ?= /opt/theos
THEOS_PACKAGE_SCHEME = roothide
ARCHS = arm64e
TARGET = iphone:clang:16.5:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = iOS27Animations
iOS27Animations_FILES = Tweak.x AnimHome.x AnimLockscreen.x AnimIsland.x Helpers.m
iOS27Animations_CFLAGS = -fobjc-arc
iOS27Animations_LDFLAGS = -lroothide

include $(THEOS)/makefiles/tweak.mk
