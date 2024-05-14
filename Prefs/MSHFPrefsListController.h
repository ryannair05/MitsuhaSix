#import "MSHFAppPrefsListController.h"
#import <MitsuhaForever/MSHFJelloView.h>
#import <Preferences/PSHeaderFooterView.h>
#import <spawn.h>
#import <dlfcn.h>

#ifdef THEOS_PACKAGE_INSTALL_PREFIX
#define MSHFAppSpecifiersDirectory                                             \
  @"/var/jb/Library/PreferenceBundles/MitsuhaSixPrefs.bundle/Apps"
#else
#define MSHFAppSpecifiersDirectory                                             \
  @"/Library/PreferenceBundles/MitsuhaSixPrefs.bundle/Apps"
#endif

@interface MSHFPrefsListController : PSListController
@property (nonatomic, retain) UIView *headerView;
- (void)resetPrefs:(id)sender;
- (void)respring:(id)sender;
- (void)restartmsd:(id)sender;
@end

@interface MSHFTintedTableCell : PSTableCell
@end

@interface MSHFLinkTableCell : MSHFTintedTableCell {
  UIView *avatarView;
  UIImageView *avatarImageView;
}

@property (nonatomic, retain) UIImage *avatarImage;
@property (nonatomic, retain) NSURL *avatarURL;
- (void)loadAvatarIfNeeded;
- (BOOL)shouldShowAvatar;
@end

@interface MSHFTwitterCell : MSHFLinkTableCell {
	NSString *_user;
}
@end

@interface UIImage (Private)
+ (void)_loadImageFromURL:(NSURL *)arg1 completionHandler:(void (^)(UIImage *))arg2;
@end
