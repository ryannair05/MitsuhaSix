#ifndef MSHF_PLAYBACK_ELIGIBILITY_H
#define MSHF_PLAYBACK_ELIGIBILITY_H

#include <stdbool.h>
#include <stdint.h>

typedef struct {
    bool surfaceVisible;
    bool displayActive;
    bool playbackStateKnown;
    bool nowPlayingApplicationIsPlaying;
} MSHFPlaybackEligibilityState;

static inline bool MSHFPlaybackEligibilityAllowsAudio(
    MSHFPlaybackEligibilityState state) {
    return state.surfaceVisible && state.displayActive &&
           state.playbackStateKnown &&
           state.nowPlayingApplicationIsPlaying;
}

static inline bool MSHFPlaybackQueryGenerationIsCurrent(
    uint64_t currentGeneration, uint64_t completedGeneration) {
    return currentGeneration == completedGeneration;
}

#endif
