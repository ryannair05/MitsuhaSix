#import "Tweak.h"
#import "PlaybackEligibility.h"

#import <MediaRemote/MediaRemote.h>
#import <notify.h>

@interface MSHFSpringBoardPlaybackCoordinator : NSObject
@property(nonatomic) BOOL playbackStateKnown;
@property(nonatomic) BOOL nowPlayingApplicationIsPlaying;
@property(nonatomic) BOOL displayActive;
@property(nonatomic) uint64_t playbackQueryGeneration;
@property(nonatomic) BOOL playbackLossPending;
@property(nonatomic) uint64_t playbackLossGeneration;
@property(nonatomic, strong) NSHashTable<MSHFView *> *visibleViews;
- (void)start;
- (void)setView:(MSHFView *)view visible:(BOOL)visible;
- (void)displayStateDidChange;
@end

static const NSTimeInterval MSHFPlaybackLossGraceDuration = 1.25;

static BOOL MSHFReadDisplayActive(void) {
    int token = 0;
    uint64_t state = 0;
    if (notify_register_check("com.apple.iokit.hid.displayStatus", &token) !=
        NOTIFY_STATUS_OK) {
        return NO;
    }
    uint32_t status = notify_get_state(token, &state);
    notify_cancel(token);
    return status == NOTIFY_STATUS_OK && state != 0;
}

static MSHFSpringBoardPlaybackCoordinator *MSHFPlaybackCoordinator(void) {
    static MSHFSpringBoardPlaybackCoordinator *coordinator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      coordinator = [[MSHFSpringBoardPlaybackCoordinator alloc] init];
    });
    return coordinator;
}

static void MSHFDisplayStatusChanged(CFNotificationCenterRef center,
                                     void *observer, CFStringRef name,
                                     const void *object,
                                     CFDictionaryRef userInfo) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [MSHFPlaybackCoordinator() displayStateDidChange];
    });
}

@implementation MSHFSpringBoardPlaybackCoordinator

- (instancetype)init {
    self = [super init];
    if (self) {
        _visibleViews = [NSHashTable weakObjectsHashTable];
        _displayActive = MSHFReadDisplayActive();
    }
    return self;
}

- (void)start {
    NSAssert(NSThread.isMainThread,
             @"Playback coordinator must be main-thread confined");
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      [[NSNotificationCenter defaultCenter]
          addObserver:self
             selector:@selector(nowPlayingStateDidChange:)
                 name:(__bridge NSString *)
                          kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification
               object:nil];
      MRMediaRemoteRegisterForNowPlayingNotifications(
          dispatch_get_main_queue());
      CFNotificationCenterAddObserver(
          CFNotificationCenterGetDarwinNotifyCenter(), NULL,
          MSHFDisplayStatusChanged,
          CFSTR("com.apple.iokit.hid.displayStatus"), NULL,
          CFNotificationSuspensionBehaviorCoalesce);
      [self queryPlaybackStateInvalidatingCache:YES];
    });
}

- (void)nowPlayingStateDidChange:(NSNotification *)notification {
    // MediaRemote's local notification is posted on its notification-client
    // queue even though registration requests main-queue callbacks. Keep the
    // coordinator's state and every MSHFView mutation main-thread confined.
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self nowPlayingStateDidChange:nil];
        });
        return;
    }
    [self queryPlaybackStateInvalidatingCache:NO];
}

- (void)cancelPendingPlaybackLoss {
    if (!self.playbackLossPending) {
        return;
    }
    self.playbackLossPending = NO;
    ++self.playbackLossGeneration;
}

- (void)commitPlaybackState:(BOOL)playing {
    [self cancelPendingPlaybackLoss];
    self.playbackStateKnown = YES;
    self.nowPlayingApplicationIsPlaying = playing;
    [self reevaluateVisibleViews];
}

- (void)schedulePlaybackLossConfirmation {
    if (self.playbackLossPending) {
        return;
    }
    self.playbackLossPending = YES;
    uint64_t lossGeneration = ++self.playbackLossGeneration;
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW,
                      (int64_t)(MSHFPlaybackLossGraceDuration * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
          if (!self.playbackLossPending ||
              self.playbackLossGeneration != lossGeneration) {
              return;
          }
          MRMediaRemoteGetNowPlayingApplicationIsPlaying(
              dispatch_get_main_queue(), ^(Boolean playing) {
                if (!self.playbackLossPending ||
                    self.playbackLossGeneration != lossGeneration) {
                    return;
                }
                [self commitPlaybackState:playing];
              });
        });
}

- (void)queryPlaybackStateInvalidatingCache:(BOOL)invalidateCache {
    NSAssert(NSThread.isMainThread,
             @"Playback queries must be main-thread confined");
    if (invalidateCache) {
        [self cancelPendingPlaybackLoss];
        self.playbackStateKnown = NO;
        [self reevaluateVisibleViews];
    }
    uint64_t generation = ++self.playbackQueryGeneration;
    MRMediaRemoteGetNowPlayingApplicationIsPlaying(
        dispatch_get_main_queue(), ^(Boolean playing) {
          if (!MSHFPlaybackQueryGenerationIsCurrent(
                  self.playbackQueryGeneration, generation)) {
              return;
          }
          if (playing || !self.playbackStateKnown ||
              !self.nowPlayingApplicationIsPlaying) {
              [self commitPlaybackState:playing];
          } else {
              [self schedulePlaybackLossConfirmation];
          }
        });
}

- (void)displayStateDidChange {
    NSAssert(NSThread.isMainThread,
             @"Display state must be main-thread confined");
    BOOL displayActive = MSHFReadDisplayActive();
    if (!displayActive) {
        self.displayActive = NO;
        [self cancelPendingPlaybackLoss];
        self.playbackStateKnown = NO;
        ++self.playbackQueryGeneration;
        [self reevaluateVisibleViews];
        return;
    }
    self.displayActive = YES;
    [self queryPlaybackStateInvalidatingCache:YES];
}

- (void)setView:(MSHFView *)view visible:(BOOL)visible {
    NSAssert(NSThread.isMainThread,
             @"Surface visibility must be main-thread confined");
    if (!view) {
        return;
    }
    if (!visible) {
        [view stop];
        [self.visibleViews removeObject:view];
        return;
    }

    BOOL hadVisibleViews = self.visibleViews.count != 0;
    if (![self.visibleViews containsObject:view]) {
        [self.visibleViews addObject:view];
    }
    if (!hadVisibleViews) {
        [self queryPlaybackStateInvalidatingCache:YES];
    } else {
        [self reevaluateView:view];
    }
}

- (void)reevaluateVisibleViews {
    for (MSHFView *view in self.visibleViews.allObjects) {
        [self reevaluateView:view];
    }
}

- (void)reevaluateView:(MSHFView *)view {
    MSHFPlaybackEligibilityState state = {
        .surfaceVisible = true,
        .displayActive = self.displayActive,
        .playbackStateKnown = self.playbackStateKnown,
        .nowPlayingApplicationIsPlaying =
            self.nowPlayingApplicationIsPlaying,
    };
    BOOL eligible = MSHFPlaybackEligibilityAllowsAudio(state);
    if (eligible) {
        [view start];
    } else {
        [view stop];
    }
}

@end

void MSHFStartSpringBoardPlaybackCoordinator(void) {
    void (^start)(void) = ^{
      [MSHFPlaybackCoordinator() start];
    };
    if (NSThread.isMainThread) {
        start();
    } else {
        dispatch_async(dispatch_get_main_queue(), start);
    }
}

void MSHFSetSpringBoardSurfaceVisible(MSHFView *view, BOOL visible) {
    if (!NSThread.isMainThread) {
        __weak MSHFView *weakView = view;
        dispatch_async(dispatch_get_main_queue(), ^{
          [MSHFPlaybackCoordinator() setView:weakView visible:visible];
        });
        return;
    }
    [MSHFPlaybackCoordinator() setView:view visible:visible];
}
