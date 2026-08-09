THEOS_DEVICE_IP = 192.168.1.177

export THEOS_PACKAGE_SCHEME=rootless

FINALPACKAGE = 1

export ADDITIONAL_CFLAGS = -DTHEOS_LEAN_AND_MEAN -fobjc-arc -fno-ptrauth-objc-class-ro
export TARGET = iphone:26.5:15.0

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += Music Prefs Spotify Springboard

after-install::
	install.exec "killall -9 SpringBoard"
	
include $(THEOS_MAKE_PATH)/aggregate.mk
