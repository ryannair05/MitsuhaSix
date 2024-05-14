#import "Tweak.h"

static MSHFConfig *config = NULL;
static bool colorflow;

%group MitsuhaVisuals

%hook MusicArtworkComponentImageView

-(void)setImage:(id)arg1 {
    %orig;
    if ([config view] == NULL) return;

    NSString *musicString =  @"MusicApplication.NowPlayingContentView";

    MusicArtworkComponentImageView *me = (MusicArtworkComponentImageView *)self;

    if ([NSStringFromClass([me.superview class]) isEqualToString:musicString]) {
        if (colorflow && config.colorMode == 0) {
            CGColorRef color = [[[%c(ChromaFlowColorManager) sharedInstance] primaryColor] CGColor];
            [[config view] updateWaveColor:color subwaveColor:color];
        }
        else if (config.colorMode != 2) {
            [config colorizeView:me.image];
        }
    }
}

%end

%hook MusicNowPlayingControlsViewController
%property (retain,nonatomic) MSHFView *mshfView;

- (instancetype)init {
    
    self = %orig;

    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMitsuhaApplicationState:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMitsuhaApplicationState:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    
    return self;
}

%new
- (void)handleMitsuhaApplicationState:(NSNotification *)notification {
    if ([notification.name isEqualToString:UIApplicationDidBecomeActiveNotification]) {
        [[config view] start];
        
    } else {
        [[config view] stop];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    %orig;
}

-(void)viewDidLoad {
    %orig;

    if(colorflow) {
        self.view.subviews[3].clipsToBounds = 1;
        [config initializeViewWithFrame:CGRectMake(0, -150, self.view.frame.size.width, (self.view.frame.size.height / 2) - 100)];
        
        self.mshfView = [config view];
        [self.view.subviews[3] addSubview:[config view]];
        [self.view.subviews[3] sendSubviewToBack:[config view]];

        if(self.mshfView.superview == NULL) {
            self.mshfView = [config view];
            [self.view addSubview:[config view]];
            [self.view sendSubviewToBack:[config view]];
        }
    } else {
        CGSize const screenSize = [[UIScreen mainScreen] bounds].size;

        self.view.clipsToBounds = 1;

        if (![config view]) 
            self.mshfView = [config initializeViewWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
        
        [self.view addSubview:[config view]];
        [self.view sendSubviewToBack:[config view]];
    }
}

-(void)viewWillAppear:(BOOL)animated {
    %orig;
    [[config view] start];
    [config view].center = CGPointMake([config view].center.x, [config view].frame.size.height*2);
}

-(void)viewDidAppear:(BOOL)animated {
    %orig;
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:3.5 initialSpringVelocity:2.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        if(colorflow) {
            [config view].center = CGPointMake([config view].center.x, 150);
        } else {
            [config view].center = CGPointMake([config view].center.x, [config view].frame.size.height);
        }
    } completion:nil];
}

-(void)viewWillDisappear:(BOOL)animated {
    %orig;
    [[config view] stop];
}

%end

%end

%ctor{
    config = [[MSHFConfig alloc] initWithAppName:@"Music"];
    config.waveOffsetOffset = 70;
    if (config.enabled) {
        if ([%c(ChromaFlowColorManager) class]) {
            #ifdef THEOS_PACKAGE_INSTALL_PREFIX
                NSDictionary const *prefs = [[NSDictionary alloc] initWithContentsOfFile:@"/var/jb/var/mobile/Library/Preferences/com.ryannair05.chromaflow.plist"];
            #else
                NSDictionary const *prefs = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.ryannair05.chromaflow.plist"];
            #endif
            if ([[prefs objectForKey:@"colorMusic"]?:@TRUE boolValue]) {
                colorflow = TRUE;
            }
        }
        %init(MitsuhaVisuals, MusicArtworkComponentImageView = objc_getClass("MusicApplication.ArtworkComponentImageView"));
    }
}