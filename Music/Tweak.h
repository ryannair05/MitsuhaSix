//
//  Tweak.h
//  Mitsuha 6
//
//  Created by Ryan Nair on 12/27/23.
//  Copyright © 2023 Ryan Nair. All rights reserved.
//

#import <MitsuhaForever/MSHFConfig.h>

@interface MusicArtworkComponentImageView : UIImageView
@end

@interface MusicNowPlayingControlsViewController : UIViewController
@property(retain, nonatomic) MSHFView *mshfView;
@end

@interface ChromaFlowColorManager : NSObject
@property(nonatomic, strong) UIColor *primaryColor;
+ (instancetype)sharedInstance;
@end