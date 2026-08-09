#import "Tweak.h"

%group MitsuhaVisuals

MSHFConfig *config = NULL;

%hook MPNowPlayingInfoCenterArtworkContext

- (void)setArtworkData:(NSData *)data {

	%orig;
    [config colorizeView:[UIImage imageWithData:data]];
}
%end

%hook SPTVideoDisplayView
- (void)refreshVideoRect {
    %orig;

    AVPlayer *displayView = [self player];
    AVAsset *asset = displayView.currentItem.asset;

    AVAssetImageGenerator* generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    CGImageRef copiedImage = [generator copyCGImageAtTime:CMTimeMake(0, 1)
                                                actualTime:nil
                                                     error:nil];
    if (copiedImage) {
        UIImage *image = [UIImage imageWithCGImage:copiedImage];
        CGImageRelease(copiedImage);
        [config colorizeView:image];
    }
}

%end

%hook SPTNowPlayingViewController

%property (retain,nonatomic) MSHFView *mshfview;


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

-(void)viewDidLoad{
    %orig;

    SPTNowPlayingViewController *controller =
        (SPTNowPlayingViewController *)self;
    if (![config view]) [config initializeViewWithFrame:CGRectMake(0, config.waveOffset, controller.view.bounds.size.width, controller.view.bounds.size.height)];
    controller.mshfview = [config view];
    [controller.mshfview setUserInteractionEnabled:NO];

    [controller.view insertSubview:controller.mshfview atIndex:1];

    controller.mshfview.translatesAutoresizingMaskIntoConstraints = NO;
    [controller.mshfview.leadingAnchor constraintEqualToAnchor:controller.view.leadingAnchor].active = YES;
    [controller.mshfview.trailingAnchor constraintEqualToAnchor:controller.view.trailingAnchor].active = YES;
    [controller.mshfview.bottomAnchor constraintEqualToAnchor:controller.view.bottomAnchor].active = YES;
    [controller.mshfview.heightAnchor constraintEqualToConstant:controller.mshfview.frame.size.height].active = YES;

}

// -(void)viewWillAppear:(BOOL)animated{
//     [[config view] start];
//     %orig;
// }

-(void)viewDidAppear:(BOOL)animated{
    %orig;
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:3.5 initialSpringVelocity:2.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        
        [config view].center = CGPointMake([config view].center.x, [config view].frame.size.height/2 + config.waveOffset);
        
    } completion:nil];
    
    // [[config view] resetWaveLayers];
     [[config view] start];

    if (config.colorMode == 1) {
        [config colorizeView:nil];
    }
    
}

-(void)viewDidDisappear:(BOOL)animated{
    %orig;
    [[config view] stop];
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:3.5 initialSpringVelocity:2.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [config view].center = CGPointMake([config view].center.x, [config view].frame.size.height + config.waveOffset);
    } completion:^(BOOL finished){
    }];
}

%end

%hook SPTNowPlayingCarouselAreaViewController

static CGFloat originalCenterY = 0;

-(void)viewWillAppear:(BOOL)animated{
    %orig;
    
    CGPoint center = self.view.coverArtView.center;
    
    self.view.coverArtView.alpha = 0;
    self.view.coverArtView.center = CGPointMake(center.x, originalCenterY);
}

-(void)viewDidAppear:(BOOL)animated{
    %orig;
    
    CGPoint center = self.view.coverArtView.center;
    
    if(originalCenterY == 0){
        originalCenterY = center.y;
    }
    
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:3.5 initialSpringVelocity:2.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.view.coverArtView.alpha = 1.0;
        self.view.coverArtView.center = CGPointMake(center.x, originalCenterY * 0.8);
    } completion:^(BOOL finished){
        if(self.view.coverArtView.center.y != originalCenterY * 0.8){    //  For some reason I can't explain
            [UIView animateWithDuration:0.25 delay:0.0 usingSpringWithDamping:3.5 initialSpringVelocity:2.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.view.coverArtView.center = CGPointMake(center.x, originalCenterY * 0.8);
            } completion:nil];
        }
    }];
}

-(void)viewWillDisappear:(BOOL)animated{
    %orig;
    
    CGPoint center = self.view.coverArtView.center;
    
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:3.5 initialSpringVelocity:2.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.view.coverArtView.alpha = 0;
        self.view.coverArtView.center = CGPointMake(center.x, originalCenterY);
    } completion:nil];
}

%end
%end

%ctor{
    config = [[MSHFConfig alloc] initWithAppName:@"Spotify"];
    
    if(config.enabled){
        config.waveOffsetOffset = 520;

        Class nowPlayingViewControllerClass =
            objc_getClass("NowPlaying_ViewImpl.NowPlayingViewController");
        if (!nowPlayingViewControllerClass) {
            nowPlayingViewControllerClass =
                objc_getClass("SPTNowPlayingViewController");
        }
        %init(MitsuhaVisuals,
              SPTNowPlayingViewController = nowPlayingViewControllerClass);
    }
}
