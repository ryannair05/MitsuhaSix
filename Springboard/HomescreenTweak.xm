#import "Tweak.h"
#import <MediaRemote/MediaRemote.h>

static MSHFConfig *mshConfig;

%group SBMediaHook
%hook SBMediaController

-(void)setNowPlayingInfo:(id)arg1 {
    %orig;
    MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef information) {
        if (information && CFDictionaryContainsKey(information, kMRMediaRemoteNowPlayingInfoArtworkData)) {
            [mshConfig colorizeView:[UIImage imageWithData:(__bridge NSData*)CFDictionaryGetValue(information, kMRMediaRemoteNowPlayingInfoArtworkData)]];
        }
    });
}
%end
%end

%hook SBIconController

%property (strong,nonatomic) MSHFView *mshfView;
%property (assign,nonatomic) BOOL mshfSurfaceVisible;

-(void)viewDidLoad {
    %orig;
    if (![mshConfig view]) {
        self.mshfView = [mshConfig initializeViewWithFrame:self.view.bounds];
    } else {
        self.mshfView = [mshConfig view];
    }
    
    [[self view] insertSubview:self.mshfView atIndex:1];

    self.mshfView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mshfView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [self.mshfView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [self.mshfView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [NSLayoutConstraint constraintWithItem:self.mshfView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:0.75 constant:0].active = YES;
}

-(void)viewIsAppearing:(BOOL)animated {
    %orig;
    if (!self.mshfSurfaceVisible) {
        self.mshfSurfaceVisible = YES;
        MSHFSetSpringBoardSurfaceVisible(self.mshfView, YES);
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    %orig;
    if (self.mshfSurfaceVisible) {
        self.mshfSurfaceVisible = NO;
        MSHFSetSpringBoardSurfaceVisible(self.mshfView, NO);
    }
}

-(void)dealloc {
    if (self.mshfSurfaceVisible) {
        self.mshfSurfaceVisible = NO;
        MSHFSetSpringBoardSurfaceVisible(self.mshfView, NO);
    }
    %orig;
}

%end

static void loadPrefs(CFNotificationCenterRef center, void *observer,
                      CFStringRef name, const void *object,
                      CFDictionaryRef userInfo) {
    [mshConfig reload];
}

%ctor{
    %init(SBMediaHook);

    mshConfig = [[MSHFConfig alloc] initWithAppName:@"HomeScreen"];
    if (!mshConfig.enabled) {
        return;
    }
    MSHFStartSpringBoardPlaybackCoordinator();
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(), NULL, loadPrefs,
        CFSTR("com.ryannair05.mitsuhasix/ReloadPrefs"), NULL,
        CFNotificationSuspensionBehaviorCoalesce);
    %init;
}
