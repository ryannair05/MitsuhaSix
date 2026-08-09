#import "Tweak.h"
#import <MediaRemote/MediaRemote.h>
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
%property (assign,nonatomic) BOOL mshfSurfaceVisible;

-(void)viewDidLoad {
    %orig;

    if (![SBconfig view]) {
        self.mshfView = [SBconfig initializeViewWithFrame:CGRectZero];
    } else {
        self.mshfView = [SBconfig view];
    }

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
    if (self.mshfSurfaceVisible) {
        self.mshfSurfaceVisible = NO;
        MSHFSetSpringBoardSurfaceVisible(self.mshfView, NO);
    }
    [self.nowPlayingViewController.artworkView removeObserver:self forKeyPath:@"artworkImage"];
    %orig;
}

-(void)viewIsAppearing:(BOOL)animated {
    %orig;
    if (!self.mshfSurfaceVisible) {
        self.mshfSurfaceVisible = YES;
        MSHFSetSpringBoardSurfaceVisible(self.mshfView, YES);
    }
}

-(void)viewDidDisappear:(BOOL)animated{
    %orig;
    if (self.mshfSurfaceVisible) {
        self.mshfSurfaceVisible = NO;
        MSHFSetSpringBoardSurfaceVisible(self.mshfView, NO);
    }
}
%end

%end

%group ios13SBLS

%hook CSFixedFooterViewController

%property (strong,nonatomic) MSHFView *mshfView;
%property (assign,nonatomic) BOOL mshfSurfaceVisible;

-(void)viewDidLoad {
    %orig;
    if (![SBLSconfig view]) {
        self.mshfView = [SBLSconfig initializeViewWithFrame:CGRectZero];
    } else {
        self.mshfView = [SBLSconfig view];
    }
    
    [self.view insertSubview:self.mshfView atIndex:0];
    
    self.mshfView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mshfView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [self.mshfView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [self.mshfView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [NSLayoutConstraint constraintWithItem:self.mshfView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:0.75 constant:0].active = YES;
}

-(void)viewWillAppear:(BOOL)animated{
    %orig;
    if (!self.mshfSurfaceVisible) {
        self.mshfSurfaceVisible = YES;
        MSHFSetSpringBoardSurfaceVisible(self.mshfView, YES);
    }
}

-(void)viewDidDisappear:(BOOL)animated{
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

%end

%ctor{
    NSMutableDictionary *lockScreenPrefs = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *springboardPrefs = [[NSMutableDictionary alloc] init];
    lockScreenPrefs[@"application"] = @"LockScreen";
    springboardPrefs[@"application"] = @"Springboard";
    NSUserDefaults *defaults = [[NSUserDefaults alloc]
        initWithSuiteName:@"com.ryannair05.mitsuhasix"];
    NSDictionary *allPrefs = [defaults dictionaryRepresentation];
    for (NSString *key in allPrefs) {
        if ([key hasPrefix:@"MSHFLockScreen"]) {
            NSString *newKey = [key substringFromIndex:14];
            NSString *lowerCaseKey = [[[newKey substringToIndex:1]
                lowercaseString]
                stringByAppendingString:[newKey substringFromIndex:1]];
            lockScreenPrefs[lowerCaseKey] = allPrefs[key];
        } else if ([key hasPrefix:@"MSHFSpringboard"]) {
            NSString *newKey = [key substringFromIndex:15];
            NSString *lowerCaseKey = [[[newKey substringToIndex:1]
                lowercaseString]
                stringByAppendingString:[newKey substringFromIndex:1]];
            springboardPrefs[lowerCaseKey] = allPrefs[key];
        }
    }

    SBLSconfig = [[MSHFConfig alloc] initWithDictionary:lockScreenPrefs];
    SBconfig = [[MSHFConfig alloc] initWithDictionary:springboardPrefs];

    if (SBLSconfig.enabled || SBconfig.enabled) {
        MSHFStartSpringBoardPlaybackCoordinator();
    }

    if (SBLSconfig.enabled) {
        %init(ios13SBLS);
    }
    if (SBconfig.enabled) {
        %init(ios15SB);
    } else if (SBLSconfig.enabled && SBLSconfig.colorMode == 0) {
        %init(MitsuhaVisualsNotification);
    }
}
