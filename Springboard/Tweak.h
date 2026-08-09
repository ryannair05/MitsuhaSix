//
//  Tweak.h
//  Mitsuha2
//
//  Created by c0ldra1n on 12/10/17.
//  Copyright © 2017 c0ldra1n. All rights reserved.
//


#import <MitsuhaForever/MSHFConfig.h>

#define ChromaflowDylibFile                                                    \
  @"/var/jb/Library/MobileSubstrate/DynamicLibraries/chromaflow.dylib"

/// Starts the SpringBoard-only MediaRemote/display eligibility coordinator.
FOUNDATION_EXPORT void MSHFStartSpringBoardPlaybackCoordinator(void);

/// Reports surface visibility. Playback eligibility remains coordinator-owned.
FOUNDATION_EXPORT void MSHFSetSpringBoardSurfaceVisible(MSHFView *view,
                                                        BOOL visible);

@interface ChromaFlowColorManager : NSObject
@property(nonatomic, strong) UIColor *primaryColor;
@end

@interface MRUArtworkView : UIView
@property (nonatomic,retain) UIImage * artworkImage;
@end

@interface MRUNowPlayingViewController : UIViewController
@property (nonatomic,readonly) MRUArtworkView * artworkView;
@end

@interface MRUCoverSheetViewController : UIViewController
@property (nonatomic,retain) MRUNowPlayingViewController *nowPlayingViewController;
@property(retain, nonatomic) MSHFView *mshfView;
@property(nonatomic) BOOL mshfSurfaceVisible;
@end

@interface CSMediaControlsViewController : UIViewController
@property(retain, nonatomic) MSHFView *mshfView;
@end

@interface MRPlatterViewController : UIViewController
@property(retain, nonatomic) MSHFView *mshfView;
@end



@interface MediaControlsInteractionRecognizer : UIGestureRecognizer
@end

@interface CSFixedFooterViewController : UIViewController

@property(strong, nonatomic) MSHFView *mshfView;
@property(nonatomic) BOOL mshfSurfaceVisible;

@end

@interface MRUControlCenterViewController : UIViewController
@property (nonatomic,retain) MSHFView * mshfView;     
@end

@interface MRUControlCenterView : UIView
@property (nonatomic, strong, readwrite) UIView *contentView;
@end

@interface SBIconController : UIViewController
@property (nonatomic,retain) MSHFView * mshfView;     
@property(nonatomic) BOOL mshfSurfaceVisible;
@end
