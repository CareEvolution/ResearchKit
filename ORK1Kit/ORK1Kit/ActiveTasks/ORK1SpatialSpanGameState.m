/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "ORK1SpatialSpanGameState.h"

#import "ORK1SpatialSpanGame.h"

#import "ORK1Helpers_Internal.h"


@implementation ORK1SpatialSpanGameState {
    NSMutableArray *_plays;
    ORK1SpatialSpanTargetState *_states;
}

+ (instancetype)new {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)initWithGame:(ORK1SpatialSpanGame *)game {
    self = [super init];
    if (self) {
        _game = game;
        _plays = [NSMutableArray array];
        
        _states = calloc([_game gameSize], sizeof(ORK1SpatialSpanTargetState));
        if (_states == NULL) {
            self = nil;
        }
    }
    return self;
}

- (void)dealloc {
    if (_states != NULL) {
        free(_states);
        _states = NULL;
    }
}

- (void)reset {
    const NSInteger gameSize = [_game gameSize];
    for (NSInteger tileIndex = 0; tileIndex < gameSize; tileIndex++) {
        _states[tileIndex] = ORK1SpatialSpanTargetStateQuiescent;
    }
    [_plays removeAllObjects];
    _complete = NO;
}

/// Enumerate all tiles, indicating the state of each tile at this point in the game.
- (void)enumerateTilesWithHandler:(void (^)(NSInteger tileIndex, ORK1SpatialSpanTargetState state, BOOL *stop))handler {
    const NSInteger gameSize = [_game gameSize];
    BOOL stop = NO;
    for (NSInteger tileIndex = 0; tileIndex < gameSize; tileIndex++) {
        handler(tileIndex, _states[tileIndex], &stop);
        if (stop) break;
    }
}

/// User tapped a tile. Returns YES if it was the correct next tile.
- (ORK1SpatialSpanResult)playTileIndex:(NSInteger)tileIndex {
    if (_states[tileIndex] != ORK1SpatialSpanTargetStateQuiescent) {
        return ORK1SpatialSpanResultIgnore;
    }
    
    NSInteger sequencePosition = _plays.count;
    BOOL correct = ([_game tileIndexForStep:sequencePosition] == tileIndex);
    _states[tileIndex] = correct ? ORK1SpatialSpanTargetStateCorrect : ORK1SpatialSpanTargetStateIncorrect;
    if (correct) {
        [_plays addObject:@(tileIndex)];
    }
    if (_plays.count >= [_game sequenceLength]) {
        _complete = YES;
    }
    
    return correct ? ORK1SpatialSpanResultCorrect : ORK1SpatialSpanResultIncorrect;
}

- (NSInteger)currentStepIndex {
    return _plays.count;
}

- (NSInteger)lastSuccessfulTileIndex {
    if (!_plays.count) {
        return NSNotFound;
    }
    return ((NSNumber *)_plays.lastObject).integerValue;
}

@end
