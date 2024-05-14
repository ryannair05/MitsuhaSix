//
//  Tweak.h
//  Mitsuha
//
//  Created by c0ldra1n on 2/17/17.
//  Copyright © 2017 c0ldra1n. All rights reserved.
//

#import <MitsuhaForever/MSHFConfig.h>
#import <AVKit/AVKit.h>

@interface SPTNowPlayingCoverArtImageView : UIImageView
-(void)setImage:(UIImage *)image;
-(void)readjustWaveColor;

@end

@interface SPTNowPlayingContentCell : UIView

@property(retain, nonatomic) UIImage *cellContentRepresentation;

@end

@interface SPTNowPlayingCoverArtView : UIView

@end

@interface SPTNowPlayingCarouselContentUnitView : UIView

@property(retain, nonatomic) SPTNowPlayingCoverArtView *coverArtView; // @synthesize coverArtView=_coverArtView;

@end

@interface SPTNowPlayingCarouselAreaViewController : UIViewController

@property(retain, nonatomic) SPTNowPlayingCarouselContentUnitView *view; // @dynamic view;

@end

@interface SPTNowPlayingModel : NSObject
- (void)player:(id)arg1 stateDidChange:(id)arg2 fromState:(id)arg3;
- (void)updateWithPlayerState:(id)arg1;

-(void)applyColorChange;

@end

@interface SPTNowPlayingViewController : UIViewController
@property (retain,nonatomic) MSHFView *mshfview;
@end

@interface SPTVideoDisplayView : UIView
@property (nonatomic, strong, readwrite) AVPlayer *player;
@property(nonatomic) _Bool playbackReady;
@end