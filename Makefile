PACKAGE_VERSION = 1.6.1

ifeq ($(SIMULATOR),1)
	TARGET = simulator:clang:latest:9.0
	ARCHS = x86_64 i386
else
	TARGET = iphone:clang:latest:9.0
	ARCHS = armv7 arm64
endif

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = EmojiPortPSReal
EmojiPortPSReal_FILES = TweakReal.xm UIKBTreeHack.xm
EmojiPortPSReal_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries/EmojiPort
EmojiPortPSReal_EXTRA_FRAMEWORKS = CydiaSubstrate
EmojiPortPSReal_LIBRARIES = EmojiLibrary
EmojiPortPSReal_USE_SUBSTRATE = 1

include $(THEOS_MAKE_PATH)/library.mk

ifneq ($(SIMULATOR),1)
TWEAK_NAME = EmojiPortPS
EmojiPortPS_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk
endif

ifeq ($(SIMULATOR),1)
setup:: clean all
	@rm -f /opt/simject/EmojiPortPS.dylib
	@cp -v $(THEOS_OBJ_DIR)/$(LIBRARY_NAME).dylib /opt/simject/EmojiPortPS.dylib
	@cp -v $(PWD)/EmojiPortPS.plist /opt/simject
endif
