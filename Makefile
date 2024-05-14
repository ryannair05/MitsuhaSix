export THEOS_PACKAGE_SCHEME=rootless

FINALPACKAGE = 1

export ADDITIONAL_CFLAGS = -DTHEOS_LEAN_AND_MEAN -fobjc-arc -Wno-module-import-in-extern-c
export TARGET = iphone:17.0.2:15.0

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += Music Prefs Spotify Springboard

after-install::
	install.exec "killall -9 SpringBoard"
	
include $(THEOS_MAKE_PATH)/aggregate.mk