ARCHS = arm64 arm64e

export TARGET = iphone:17.0.2:14.8

include $(THEOS_MAKE_PATH)/common.mk

BUNDLE_NAME = MitsuhaSixPrefs
$(BUNDLE_NAME)_FILES = MSHFPrefsListController.m MSHFAppPrefsListController.m
$(BUNDLE_NAME)_INSTALL_PATH = /Library/PreferenceBundles
$(BUNDLE_NAME)_LIBRARIES = colorpicker mitsuhaforever
$(BUNDLE_NAME)_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/$(BUNDLE_NAME).plist$(ECHO_END)
