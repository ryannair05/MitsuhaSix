#import "Tweak.h"
#import <MediaRemote/MediaRemote.h>
#import <notify.h>

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

-(void)viewDidLoad {
    %orig;
    if (![mshConfig view]) 
        self.mshfView = [mshConfig initializeViewWithFrame:self.view.bounds];
    
    [[self view] insertSubview:self.mshfView atIndex:1];

    self.mshfView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mshfView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [self.mshfView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [self.mshfView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [NSLayoutConstraint constraintWithItem:self.mshfView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:0.75 constant:0].active = YES;
}

-(void)viewIsAppearing:(BOOL)animated {
    %orig;
    [self.mshfView start];
}

-(void)viewWillDisappear:(BOOL)animated {
    %orig;
    [self.mshfView stop];
}

%end

static void screenDisplayStatus(CFNotificationCenterRef center, void* o, CFStringRef name, const void* object, CFDictionaryRef userInfo) {
    [[mshConfig view] stop];
}

static void loadPrefs() {
    [mshConfig reload];
}

%ctor{
    mshConfig = [[MSHFConfig alloc] initWithAppName:@"HomeScreen"];
    %init(SBMediaHook);

    if(mshConfig.enabled){
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)screenDisplayStatus, CFSTR("com.apple.iokit.hid.displayStatus"), NULL, (CFNotificationSuspensionBehavior)kNilOptions);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("com.ryannair05.mitsuhasix/ReloadPrefs"), NULL, CFNotificationSuspensionBehaviorCoalesce);
        
        %init;
    }

}
