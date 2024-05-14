#import "Tweak.h"
#import <MediaRemote/MediaRemote.h>
#import <notify.h>
#import <dlfcn.h>
#import <objc/runtime.h>

static MSHFConfig *SBconfig = NULL;
static MSHFConfig *SBLSconfig = NULL;

%group MitsuhaVisualsNotification

%hook SBMediaController

-(void)setNowPlayingInfo:(NSDictionary *)arg1 {
    %orig;

    MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef information) {
        if (information && CFDictionaryContainsKey(information, kMRMediaRemoteNowPlayingInfoArtworkData)) {
            UIImage *imageToColor = [UIImage imageWithData:(__bridge NSData*)CFDictionaryGetValue(information, kMRMediaRemoteNowPlayingInfoArtworkData)];

            [SBLSconfig colorizeView:imageToColor];
        }
    });
}

%end

%end 

%group ios15SB
%hook MRUCoverSheetViewController

%property (retain,nonatomic) MSHFView *mshfView;

-(void)viewDidLoad {
    %orig;

    if (![SBconfig view]) 
        self.mshfView = [SBconfig initializeViewWithFrame:CGRectZero];

    [self.view insertSubview:self.mshfView atIndex:0];

    // Unfortunately, this causes the top view to be clipped so it is not sufficient
    // self.mshfView.layer.cornerRadius = 18;
    // self.mshfView.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    // self.mshfView.layer.masksToBounds = true;
    self.mshfView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mshfView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [self.mshfView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [self.mshfView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [self.mshfView.topAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;

    MRUArtworkView *artworkView = self.nowPlayingViewController.artworkView;
    [artworkView addObserver:self forKeyPath:@"artworkImage" options:NSKeyValueObservingOptionNew context:NULL];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"artworkImage"]) {
        UIImage *imageToColor = change[NSKeyValueChangeNewKey];
        if ([imageToColor isKindOfClass:[UIImage class]]) {
            [SBconfig colorizeView:imageToColor];
            [SBLSconfig colorizeView:imageToColor];
        }
    }
    else {
        %orig;
    }
}

-(void)dealloc {
    [self.nowPlayingViewController.artworkView removeObserver:self forKeyPath:@"artworkImage"];
    %orig;
}

-(void)viewIsAppearing:(BOOL)animated {
    %orig;
    [[SBconfig view] start];
}

-(void)viewDidDisappear:(BOOL)animated{
    %orig;
    [[SBconfig view] stop];
}

- (void)didReceiveInteraction:(MediaControlsInteractionRecognizer *)arg1 {
    %orig;
    
    if (arg1.state == UIGestureRecognizerStateEnded) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if ([[%c(SBMediaController) sharedInstance] isPlaying]) {
                [[SBconfig view] start];
                [[SBLSconfig view] start];
            }
            else {
                [[SBconfig view] stop];
                [[SBLSconfig view] start];
            }
        });
    }
}
%end

%end

%group ios13SBLS

%hook CSFixedFooterViewController

%property (strong,nonatomic) MSHFView *mshfView;

-(void)viewDidLoad {
    %orig;
    if (![SBLSconfig view]) 
        self.mshfView = [SBLSconfig initializeViewWithFrame:CGRectZero];
    
    [self.view insertSubview:self.mshfView atIndex:0];
    
    self.mshfView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mshfView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [self.mshfView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [self.mshfView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [NSLayoutConstraint constraintWithItem:self.mshfView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:0.75 constant:0].active = YES;
}

-(void)viewWillAppear:(BOOL)animated{
    %orig;
    [self.mshfView start];
}

-(void)viewDidDisappear:(BOOL)animated{
    %orig;
    [self.mshfView stop];
}

%end

%end

static void screenDisplayStatus(CFNotificationCenterRef center, void* o, CFStringRef name, const void* object, CFDictionaryRef userInfo) {
    uint64_t state;
    if ([[%c(SBMediaController) sharedInstance] isPlaying]) {
        int token;
        notify_register_check("com.apple.iokit.hid.displayStatus", &token);
        notify_get_state(token, &state);
        notify_cancel(token);
    }
    else {
        state = false;
    }
    if (SBLSconfig.enabled) {
        if (state) {
            [[SBLSconfig view] start];
        } else {
            [[SBLSconfig view] stop];
        }
    }
    if (SBconfig.enabled) {
        if (state) {
            [[SBconfig view] start];
        } else {
            [[SBconfig view] stop];
        }
    }
}

%ctor{
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)screenDisplayStatus, (CFStringRef)@"com.apple.iokit.hid.displayStatus", NULL, (CFNotificationSuspensionBehavior)kNilOptions);

    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.ryannair05.mitsuhasix"];
    NSMutableDictionary *lockScreenPrefs = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *springboardPrefs = [[NSMutableDictionary alloc] init];
    lockScreenPrefs[@"application"] = @"LockScreen";
    springboardPrefs[@"application"] = @"Springboard";
    NSDictionary *allPrefs = [defaults dictionaryRepresentation];
    for (NSString *key in allPrefs) {
        if ([key hasPrefix:@"MSHFLockScreen"]) {
            NSString *newKey = [key substringFromIndex:14];
            NSString *lowerCaseKey = [[[newKey substringToIndex:1] lowercaseString] stringByAppendingString:[newKey substringFromIndex:1]];

            lockScreenPrefs[lowerCaseKey] = allPrefs[key];
        }
        else if ([key hasPrefix:@"MSHFSpringboard"]) {
            NSString *newKey = [key substringFromIndex:15];
            NSString *lowerCaseKey = [[[newKey substringToIndex:1] lowercaseString] stringByAppendingString:[newKey substringFromIndex:1]];

            springboardPrefs[lowerCaseKey] = allPrefs[key];
        }
    }

    SBLSconfig = [[MSHFConfig alloc] initWithDictionary:lockScreenPrefs];
    SBconfig = [[MSHFConfig alloc] initWithDictionary:springboardPrefs];

    if (SBLSconfig.enabled) {
        %init(ios13SBLS);
    }

    if (SBconfig.enabled){
        %init(ios15SB);
    }
    else if (SBLSconfig.enabled && SBLSconfig.colorMode == 0) {
        %init(MitsuhaVisualsNotification);
    }
}