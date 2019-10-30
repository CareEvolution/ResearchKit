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


#import "ORKSpatialSpanMemoryStepViewController.h"

#import "ORKActiveStepView.h"
#import "ORKSpatialSpanMemoryContentView.h"
#import "ORKVerticalContainerView_Internal.h"

#import "ORKActiveStepViewController_Internal.h"
#import "ORKStepViewController_Internal.h"
#import "ORKStepHeaderView_Internal.h"

#import "ORKActiveStep_Internal.h"
#import "ORKResult.h"
#import "ORKStep_Private.h"
#import "ORKSpatialSpanGame.h"
#import "ORKSpatialSpanGameState.h"
#import "ORKSpatialSpanMemoryStep.h"

#import "ORKHelpers_Internal.h"
#import "ORKSkin.h"

#import <QuartzCore/CABase.h>


static const NSTimeInterval MemoryGameActivityTimeout = 20;

typedef NS_ENUM(NSInteger, ORK1SpatialSpanStepState) {
    ORK1SpatialSpanStepStateInitial,
    ORK1SpatialSpanStepStatePlayback,
    ORK1SpatialSpanStepStateGameplay,
    ORK1SpatialSpanStepStateTimeout,
    ORK1SpatialSpanStepStateFailed,
    ORK1SpatialSpanStepStateSuccess,
    ORK1SpatialSpanStepStateRestart,
    ORK1SpatialSpanStepStateComplete,
    ORK1SpatialSpanStepStateStopped,
    ORK1SpatialSpanStepStatePaused
};

@class ORK1State;

typedef void (^_ORK1StateHandler)(ORK1State *fromState, ORK1State *_toState, id context);

// Poor man's state machine:
// Define entry and exit handlers for each state.
// Transitions are a free for all!
@interface ORK1State : NSObject

+ (ORK1State *)stateWithState:(NSInteger)state entryHandler:(_ORK1StateHandler)entryHandler exitHandler:(_ORK1StateHandler)exitHandler context:(id)context;

@property (nonatomic, assign) NSInteger state;

@property (nonatomic, weak) id context;

@property (nonatomic, copy) _ORK1StateHandler entryHandler;
- (void)setEntryHandler:(_ORK1StateHandler)entryHandler;

@property (nonatomic, copy) _ORK1StateHandler exitHandler;
- (void)setExitHandler:(_ORK1StateHandler)exitHandler;

@end


@implementation ORK1State

+ (ORK1State *)stateWithState:(NSInteger)state entryHandler:(_ORK1StateHandler)entryHandler exitHandler:(_ORK1StateHandler)exitHandler context:(id)context {
    ORK1State *s = [ORK1State new];
    s.state = state;
    s.entryHandler = entryHandler;
    s.exitHandler = exitHandler;
    s.context = context;
    return s;
}

@end


@interface ORK1SpatialSpanMemoryStepViewController () <ORK1SpatialSpanMemoryGameViewDelegate>

@end


@implementation ORK1SpatialSpanMemoryStepViewController {
    ORK1SpatialSpanMemoryContentView *_contentView;
    ORK1State *_state;
    NSDictionary *_states;
    ORK1GridSize _gridSize;
    
    ORK1SpatialSpanGameState *_currentGameState;
    UIBarButtonItem *_customLearnMoreButtonItem;
    UIBarButtonItem *_learnMoreButtonItem;
    
    // ORK1SpatialSpanMemoryGameRecord
    NSMutableArray *_gameRecords;
    NSTimeInterval _gameStartTime;
    NSInteger _lastRoundScore;
    
    NSInteger _playbackIndex;
    
    NSInteger _score;
    NSInteger _numberOfItems;
    
    NSInteger _gamesCounter;
    NSInteger _consecutiveGamesFailed;
    NSInteger _nextGameSequenceLength;
    
    NSTimer *_playbackTimer;
    NSTimer *_activityTimer;
}

- (ORK1SpatialSpanMemoryStep *)spatialSpanStep {
    return (ORK1SpatialSpanMemoryStep *)self.step;
}

- (instancetype)initWithStep:(ORK1Step *)step {
    self = [super initWithStep:step];
    if (self) {
        self.suspendIfInactive = YES;
    }
    return self;
}

#pragma mark Overrides

- (void)viewDidLoad {
    
    // Setup to always have a learn more button item but with an empty title
    BOOL usesDefaultCopyright = (self.learnMoreButtonItem == nil);
    if (usesDefaultCopyright) {
        self.learnMoreButtonItem = [[UIBarButtonItem alloc] initWithTitle:ORK1LocalizedString(@"BUTTON_COPYRIGHT", nil) style:UIBarButtonItemStylePlain target:self action:@selector(showCopyright)];
    }
    
    [super viewDidLoad];
    
    _contentView = [ORK1SpatialSpanMemoryContentView new];
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    _contentView.footerHidden = YES;
    _contentView.gameView.delegate = self;
    self.activeStepView.activeCustomView = _contentView;
    self.activeStepView.stepViewFillsAvailableSpace = NO;
    self.activeStepView.minimumStepHeaderHeight = ORK1GetMetricForWindow(ORK1ScreenMetricMinimumStepHeaderHeightForMemoryGame, self.view.window);
    
    [self resetUI];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleUserTap:)];
    [self.activeStepView addGestureRecognizer:tapGestureRecognizer];
    
    if (usesDefaultCopyright) {
        self.activeStepView.headerView.learnMoreButton.alpha = 0;
    }
}

- (void)stepDidChange {
    [super stepDidChange];
    
    [self initializeStates];
    
}

- (void)start {
    [super start];
    
    if (!_state) {
        [self transitionToState:ORK1SpatialSpanStepStateInitial];
    }
    
    [self transitionToState:ORK1SpatialSpanStepStatePlayback];
}

- (void)suspend {
    [super suspend];
    switch (_state.state) {
        case ORK1SpatialSpanStepStatePlayback:
        case ORK1SpatialSpanStepStateGameplay:
            [self transitionToState:ORK1SpatialSpanStepStatePaused];
            break;
        default:
            break;
    }
}

- (void)resume {
    [super resume];
}

- (void)finish {
    [super finish];
    [self transitionToState:ORK1SpatialSpanStepStateStopped];
}

- (ORK1StepResult *)result {
    ORK1StepResult *stepResult = [super result];
    
    // "Now" is the end time of the result, which is either actually now,
    // or the last time we were in the responder chain.
    NSDate *now = stepResult.endDate;
    
    NSMutableArray *results = [NSMutableArray arrayWithArray:stepResult.results];
    
    ORK1SpatialSpanMemoryResult *memoryResult = [[ORK1SpatialSpanMemoryResult alloc] initWithIdentifier:self.step.identifier];
    memoryResult.startDate = stepResult.startDate;
    memoryResult.endDate = now;
    
    NSMutableArray *records = [NSMutableArray new];
    
    __block NSInteger numberOfFailures = 0;
    __block NSInteger score = 0;
    // Only include valid records
    [_gameRecords enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ORK1SpatialSpanMemoryGameRecord *record = (ORK1SpatialSpanMemoryGameRecord *)obj;
        if (record.gameStatus != ORK1SpatialSpanMemoryGameStatusUnknown) {
            [records addObject:record];
            
            score += record.score;
            
            if (record.gameStatus != ORK1SpatialSpanMemoryGameStatusSuccess) {
                numberOfFailures++;
            }
        }
    }];
    
    memoryResult.score = score;
    memoryResult.numberOfFailures = numberOfFailures;
    memoryResult.numberOfGames = records.count;
    memoryResult.gameRecords = [records copy];
    
    [results addObject:memoryResult];
    stepResult.results = [results copy];
    
    return stepResult;
}

#pragma mark UpdateGameRecord

- (ORK1SpatialSpanMemoryGameRecord *)currentGameRecord {
    return _gameRecords ? _gameRecords.lastObject : nil;
}

- (void)createGameRecord {
    if (_gameRecords == nil) {
        _gameRecords = [NSMutableArray new];
    }
    
    ORK1SpatialSpanMemoryGameRecord *gameRecord = [ORK1SpatialSpanMemoryGameRecord new];
    gameRecord.seed = _currentGameState.game.seed;
    gameRecord.gameSize = _currentGameState.game.gameSize;
    
    NSMutableArray *targetSequence = [NSMutableArray new];
    [_currentGameState.game enumerateSequenceWithHandler:^(NSInteger step, NSInteger tileIndex, BOOL isLastStep, BOOL *stop) {
        [targetSequence addObject:@(tileIndex)];
    }];
    gameRecord.sequence = [targetSequence copy];
    [_gameRecords addObject:gameRecord];
    
    _lastRoundScore = _score;
}

- (void)updateGameRecordTargetRects {
    ORK1SpatialSpanMemoryGameRecord *record = [self currentGameRecord];
    NSArray *tileViews = _contentView.gameView.tileViews;
    NSMutableArray *targetRects = [NSMutableArray new];
    for (UIView *tileView in tileViews) {
        CGRect rect = [self.view convertRect:tileView.frame fromView:tileView.superview];
        [targetRects addObject:[NSValue valueWithCGRect:rect]];
    }
    record.targetRects = [targetRects copy];
    NSAssert(tileViews.count == 0 || tileViews.count == record.gameSize, nil);
}

- (void)updateGameRecordOnStartingGamePlay {
    _gameStartTime = CACurrentMediaTime();
}

- (void)handleUserTap:(UITapGestureRecognizer *)tapRecognizer {
    if (_state.state != ORK1SpatialSpanStepStateGameplay) {
        return;
    }
    [self updateGameRecordOnTouch:-1 location:[tapRecognizer locationInView: self.view]];
}

- (void)updateGameRecordOnTouch:(NSInteger)targetIndex location:(CGPoint)location {
    ORK1SpatialSpanMemoryGameTouchSample *sample = [ORK1SpatialSpanMemoryGameTouchSample new];
    
    sample.timestamp = CACurrentMediaTime() - _gameStartTime;
    sample.location = location;
    sample.targetIndex = targetIndex;
    
    ORK1SpatialSpanMemoryGameRecord *record = [self currentGameRecord];
    
    NSAssert(record, nil);
    
    NSInteger currentStep = 0;
    
    for (ORK1SpatialSpanMemoryGameTouchSample *aSample in record.touchSamples) {
        if (aSample.isCorrect) {
            currentStep++;
        }
    }
    
    sample.correct = (targetIndex == [_currentGameState.game tileIndexForStep:currentStep]);
    
    NSMutableArray *sampleArray = [NSMutableArray arrayWithArray:record.touchSamples];
    
    [sampleArray addObject:sample];
    
    record.touchSamples = [sampleArray copy];
}

- (void)updateGameRecordOnSuccess {
    [self currentGameRecord].gameStatus = ORK1SpatialSpanMemoryGameStatusSuccess;
}

- (void)updateGameRecordOnFailure {
    [self currentGameRecord].gameStatus = ORK1SpatialSpanMemoryGameStatusFailure;
}

- (void)updateGameRecordOnTimeout {
    [self currentGameRecord].gameStatus = ORK1SpatialSpanMemoryGameStatusTimeout;
}

- (void)updateGameRecordScore {
    [self currentGameRecord].score = _score - _lastRoundScore;
}

- (void)updateGameRecordOnPause {
    [self currentGameRecord].gameStatus = ORK1SpatialSpanMemoryGameStatusUnknown;
}

#pragma mark ORK1SpatialSpanStepStateInitial

- (ORK1GridSize)gridSizeForSpan:(NSInteger)span {
    NSInteger numberOfGridEntriesDesired = span * 2;
    NSInteger value = (NSInteger)ceil(sqrt(numberOfGridEntriesDesired));
    value = MAX(value, 2);
    value = MIN(value, 6);
    return (ORK1GridSize){value,value};
}

- (void)resetGameAndUI {
    _score = 0;
    _numberOfItems = 0;
    _gamesCounter = 0;
    _consecutiveGamesFailed = 0;
    ORK1SpatialSpanMemoryStep *step = [self spatialSpanStep];
    _nextGameSequenceLength = step.initialSpan;
    
    [self resetForNewGame];
}

- (void)resetUI {
    _contentView.numberOfItems = _score;
    _contentView.score = _numberOfItems;
    _contentView.footerHidden = YES;
    _contentView.buttonItem = nil;
    _contentView.gameView.gridSize = _gridSize;
    
    _contentView.gameView.customTargetImage = [[self spatialSpanStep] customTargetImage];
}

- (void)resetForNewGame {
    [self.activeStepView updateTitle:self.step.title text:self.step.text];
    
    _numberOfItems = 0;
    
    NSInteger sequenceLength = _nextGameSequenceLength;
    _gridSize = [self gridSizeForSpan:sequenceLength];
    
    ORK1SpatialSpanGame *game = [[ORK1SpatialSpanGame alloc] initWithGameSize:_gridSize.width * _gridSize.height sequenceLength:sequenceLength seed:0];
    ORK1SpatialSpanGameState *gameState = [[ORK1SpatialSpanGameState alloc] initWithGame:game];
    
    _currentGameState = gameState;
    
    [self createGameRecord];
    
    [self resetUI];
}

#pragma mark ORK1SpatialSpanStepStatePlayback

- (void)applyTargetState:(ORK1SpatialSpanTargetState)targetState toSequenceIndex:(NSInteger)index duration:(NSTimeInterval)duration {
    ORK1SpatialSpanGame *game = _currentGameState.game;
    if (index == NSNotFound || index < 0 || index >= game.sequenceLength ) {
        return;
    }
    
    NSInteger tileIndex = [game tileIndexForStep:index];
    ORK1SpatialSpanMemoryGameView *gameView = _contentView.gameView;
    [gameView setState:targetState forTileIndex:tileIndex animated:YES];
    if (duration > 0 && targetState != ORK1SpatialSpanTargetStateQuiescent) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self applyTargetState:ORK1SpatialSpanTargetStateQuiescent toSequenceIndex:index duration:0];
        });
    }
}

- (void)playbackNextItem {
    const NSInteger sequenceLength = _currentGameState.game.sequenceLength;
    if (_playbackIndex >= sequenceLength) {
        [self transitionToState:ORK1SpatialSpanStepStateGameplay];
    } else {
        ORK1SpatialSpanMemoryStep *step = [self spatialSpanStep];
        
        NSInteger index = _playbackIndex;
        NSInteger previousIndex = index - 1;
        if (step.requireReversal) {
            // Play the indexes in reverse order when we require reversal. The participant
            // is then required to tap the sequence in the forward direction, which
            // appears as a reversal to them.
            index = sequenceLength - 1 - index;
            previousIndex = sequenceLength - 1 - previousIndex;
        }
        
        // Make sure the previous step *is *cleared
        [self applyTargetState:ORK1SpatialSpanTargetStateQuiescent toSequenceIndex:previousIndex duration:0];
        
        // The active display should be visible for half the timer interval
        [self applyTargetState:ORK1SpatialSpanTargetStateActive toSequenceIndex:index duration:(step.playSpeed / 2)];
    }
    _playbackIndex++;
}

- (void)startPlayback {
    _playbackIndex = 0;
    _contentView.footerHidden = YES;
    _contentView.buttonItem = nil;
    ORK1SpatialSpanMemoryStep *step = [self spatialSpanStep];
    NSString *title = [NSString localizedStringWithFormat:ORK1LocalizedString(@"MEMORY_GAME_PLAYBACK_TITLE_%@", nil), step.customTargetPluralName ? : ORK1LocalizedString(@"SPATIAL_SPAN_MEMORY_TARGET_PLURAL", nil)];
    
    [self.activeStepView updateTitle:title text:nil];
    
    [_contentView.gameView resetTilesAnimated:NO];
    
    _playbackTimer = [NSTimer scheduledTimerWithTimeInterval:step.playSpeed target:self selector:@selector(playbackNextItem) userInfo:nil repeats:YES];
}

- (void)finishPlayback {
    [_playbackTimer invalidate];
    _playbackTimer = nil;
}

#pragma mark ORK1SpatialSpanStepStateGameplay

- (void)setNumberOfItems:(NSInteger)numberOfItems {
    _numberOfItems = numberOfItems;
    [_contentView setNumberOfItems:_numberOfItems];
}

- (void)setScore:(NSInteger)score {
    _score = score;
    [_contentView setScore:_score];
    [self updateGameRecordScore];
}

- (void)activityTimeout {
    [self transitionToState:ORK1SpatialSpanStepStateTimeout];
}

- (void)resetActivityTimer {
    [_activityTimer invalidate];
    _activityTimer = nil;
    
    _activityTimer = [NSTimer scheduledTimerWithTimeInterval:MemoryGameActivityTimeout target:self selector:@selector(activityTimeout) userInfo:nil repeats:NO];
}

- (void)startGameplay {
    [self setNumberOfItems:0];
    
    // Update the target rects here, since layout will be complete by this point.
    [self updateGameRecordTargetRects];
    
    _contentView.footerHidden = NO;
    _contentView.buttonItem = nil;
    ORK1SpatialSpanMemoryStep *step = [self spatialSpanStep];
    NSString *pluralItemName = step.customTargetPluralName ? : ORK1LocalizedString(@"SPATIAL_SPAN_MEMORY_TARGET_PLURAL", nil);
    NSString *standaloneItemName = step.customTargetPluralName ? : ORK1LocalizedString(@"SPATIAL_SPAN_MEMORY_TARGET_STANDALONE", nil);
    _contentView.capitalizedPluralItemDescription = [standaloneItemName capitalizedStringWithLocale:[NSLocale currentLocale]];
    NSString *titleFormat = step.requireReversal ?  ORK1LocalizedString(@"MEMORY_GAME_GAMEPLAY_REVERSE_TITLE_%@", nil) : ORK1LocalizedString(@"MEMORY_GAME_GAMEPLAY_TITLE_%@", nil);
    NSString *title = [NSString stringWithFormat:titleFormat, pluralItemName];
    [self.activeStepView updateTitle:title text:nil];
    
    [self resetActivityTimer];
    
    // Ensure tiles are all reset at this point
    [_currentGameState reset];
    [_contentView.gameView resetTilesAnimated:NO];
    [_contentView setScore:_score];
    [_contentView setNumberOfItems:_numberOfItems];
    
    [self updateGameRecordOnStartingGamePlay];
}

- (void)finishGameplay {
    [_activityTimer invalidate];
    _activityTimer = nil;
}

- (void)gameView:(ORK1SpatialSpanMemoryGameView *)gameView didTapTileWithIndex:(NSInteger)tileIndex recognizer:(UITapGestureRecognizer *)recognizer {
    if (_state.state != ORK1SpatialSpanStepStateGameplay) {
        return;
    }
    
    [self updateGameRecordOnTouch:tileIndex location:[recognizer locationInView:self.view]];
    
    ORK1SpatialSpanResult result = [_currentGameState playTileIndex:tileIndex];
    switch (result) {
        case ORK1SpatialSpanResultIgnore:
            break;
            
        case ORK1SpatialSpanResultCorrect:
            [gameView setState:ORK1SpatialSpanTargetStateCorrect forTileIndex:tileIndex animated:YES];
            NSInteger stepIndex = [_currentGameState currentStepIndex];
            
            [self setNumberOfItems:_numberOfItems + 1];
            [self setScore:_score + (round(log2(stepIndex)) + 1) * 5];
            
            [self resetActivityTimer];
            if ([_currentGameState isComplete]) {
                [self transitionToState:ORK1SpatialSpanStepStateSuccess];
            }
            break;
            
        case ORK1SpatialSpanResultIncorrect:
            [gameView setState:ORK1SpatialSpanTargetStateIncorrect forTileIndex:tileIndex animated:YES];
            [self transitionToState:ORK1SpatialSpanStepStateFailed];
            break;
    }
}

#pragma mark ORK1SpatialSpanStepStateSuccess

- (void)updateGameCountersForSuccess:(BOOL)success {
    ORK1SpatialSpanMemoryStep *step = [self spatialSpanStep];
    if (success) {
        NSInteger sequenceLength = [_currentGameState.game sequenceLength];
        [self setScore:_score + (round(log2(sequenceLength)) + 1) * 5];
        _gamesCounter++;
        _consecutiveGamesFailed = 0;
        _nextGameSequenceLength = MIN(_nextGameSequenceLength + 1, step.maximumSpan);
    } else {
        _gamesCounter++;
        _consecutiveGamesFailed++;
        _nextGameSequenceLength = MAX(_nextGameSequenceLength - 1, step.minimumSpan);
    }
}

- (void)continueAction {
    ORK1SpatialSpanMemoryStep *step = [self spatialSpanStep];
    if (_gamesCounter < step.maximumTests && _consecutiveGamesFailed < step.maximumConsecutiveFailures) {
        // Generate a new game
        [self transitionToState:ORK1SpatialSpanStepStateRestart];
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
    } else {
        [self finish];
    }
}

- (void)showSuccess {
    [self updateGameRecordOnSuccess];
    
    [self updateGameCountersForSuccess:YES];
    if ([self finishIfCompletedGames]) {
        return;
    }
    
    [self.activeStepView updateTitle:ORK1LocalizedString(@"MEMORY_GAME_COMPLETE_TITLE", nil) text:ORK1LocalizedString(@"MEMORY_GAME_COMPLETE_MESSAGE", nil)];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _contentView.buttonItem = [[UIBarButtonItem alloc] initWithTitle:ORK1LocalizedString(@"BUTTON_NEXT", nil) style:UIBarButtonItemStylePlain target:self action:@selector(continueAction)];
    });
}

#pragma mark ORK1SpatialSpanStepStateFailed

- (void)tryAgainAction {
    // Restart with a new, shorter game
    [self transitionToState:ORK1SpatialSpanStepStateRestart];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (BOOL)finishIfCompletedGames {
    ORK1SpatialSpanMemoryStep *step = [self spatialSpanStep];
    if (_consecutiveGamesFailed >= step.maximumConsecutiveFailures || _gamesCounter >= step.maximumTests) {
        [self transitionToState:ORK1SpatialSpanStepStateComplete];
        return YES;
    }
    return NO;
}

- (void)showFailed {
    [self updateGameRecordOnFailure];
    
    [self updateGameCountersForSuccess:NO];
    if ([self finishIfCompletedGames]) {
        return;
    }
    [self.activeStepView updateTitle:ORK1LocalizedString(@"MEMORY_GAME_FAILED_TITLE", nil) text:ORK1LocalizedString(@"MEMORY_GAME_FAILED_MESSAGE", nil)];
    
    _contentView.buttonItem = [[UIBarButtonItem alloc] initWithTitle:ORK1LocalizedString(@"BUTTON_NEXT", nil) style:UIBarButtonItemStylePlain target:self action:@selector(tryAgainAction)];
}

#pragma mark ORK1SpatialSpanStepStateTimeout

- (void)showTimeout {
    [self updateGameRecordOnTimeout];
    
    [self updateGameCountersForSuccess:NO];
    if ([self finishIfCompletedGames]) {
        return;
    }
    
    [self.activeStepView updateTitle:ORK1LocalizedString(@"MEMORY_GAME_TIMEOUT_TITLE", nil) text:ORK1LocalizedString(@"MEMORY_GAME_TIMEOUT_MESSAGE", nil)];
    
    _contentView.buttonItem = [[UIBarButtonItem alloc] initWithTitle:ORK1LocalizedString(@"BUTTON_NEXT", nil) style:UIBarButtonItemStylePlain target:self action:@selector(tryAgainAction)];
}

#pragma mark ORK1SpatialSpanStepStateComplete

- (void)showComplete {
    [self.activeStepView updateTitle:ORK1LocalizedString(@"MEMORY_GAME_COMPLETE_TITLE", nil) text:nil];
    
    // Show the copyright
    self.activeStepView.headerView.learnMoreButton.alpha = 1;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _contentView.buttonItem = [[UIBarButtonItem alloc] initWithTitle:ORK1LocalizedString(@"BUTTON_NEXT", nil) style:UIBarButtonItemStylePlain target:self action:@selector(continueAction)];
    });
}

- (void)showCopyright {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:ORK1LocalizedString(@"MEMORY_GAME_COPYRIGHT_TEXT", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:ORK1LocalizedString(@"BUTTON_OK", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark ORK1SpatialSpanStepStateRestart

- (void)doRestart {
    [self resetForNewGame];
    dispatch_async(dispatch_get_main_queue(), ^{
        // Dispatch, so we don't do this in the middle of a state transition
        if (_state.state == ORK1SpatialSpanStepStateRestart) {
            [self transitionToState:ORK1SpatialSpanStepStatePlayback];
        }
    });
}

- (void)showPausedFromState:(ORK1State *)fromState {
    [self updateGameRecordOnPause];
    
    // Do not update game counters - doesn't count as a game.
    
    [_activityTimer invalidate]; _activityTimer = nil;
    [_playbackTimer invalidate]; _playbackTimer = nil;
    
    [self resetForNewGame];
    [self.activeStepView updateTitle:ORK1LocalizedString(@"MEMORY_GAME_PAUSED_TITLE", nil) text:ORK1LocalizedString(@"MEMORY_GAME_PAUSED_MESSAGE", nil)];
    _contentView.buttonItem = [[UIBarButtonItem alloc] initWithTitle:ORK1LocalizedString(@"BUTTON_NEXT", nil) style:UIBarButtonItemStylePlain target:self action:@selector(continueAction)];
}

#pragma mark State machine

- (void)initializeStates {
    NSMutableDictionary *states = [NSMutableDictionary dictionary];
    
    states[@(ORK1SpatialSpanStepStateInitial)] = [ORK1State stateWithState:ORK1SpatialSpanStepStateInitial
                                                            entryHandler:^(ORK1State *from, ORK1State *to, ORK1SpatialSpanMemoryStepViewController *this) {
                                                                [this resetGameAndUI];
                                                            }
                                                             exitHandler:nil context:self];
    
    states[@(ORK1SpatialSpanStepStatePlayback)] = [ORK1State stateWithState:ORK1SpatialSpanStepStatePlayback
                                                             entryHandler:^(ORK1State *from, ORK1State *to, ORK1SpatialSpanMemoryStepViewController *this) {
                                                                 [this startPlayback];
                                                             }
                                                              exitHandler:^(ORK1State *from, ORK1State *to, ORK1SpatialSpanMemoryStepViewController *this) {
                                                                  [this finishPlayback];
                                                              } context:self];
    
    states[@(ORK1SpatialSpanStepStateGameplay)] = [ORK1State stateWithState:ORK1SpatialSpanStepStateGameplay
                                                             entryHandler:^(ORK1State *from, ORK1State *to, ORK1SpatialSpanMemoryStepViewController *this) {
                                                                 [this startGameplay];
                                                             }
                                                              exitHandler:^(ORK1State *from, ORK1State *to, ORK1SpatialSpanMemoryStepViewController *this) {
                                                                  [this finishGameplay];
                                                              } context:self];
    
    states[@(ORK1SpatialSpanStepStateSuccess)] = [ORK1State stateWithState:ORK1SpatialSpanStepStateSuccess
                                                            entryHandler:^(ORK1State *from, ORK1State *to, ORK1SpatialSpanMemoryStepViewController *this) {
                                                                [this showSuccess];
                                                            }
                                                             exitHandler:nil context:self];
    
    states[@(ORK1SpatialSpanStepStateFailed)] = [ORK1State stateWithState:ORK1SpatialSpanStepStateFailed
                                                           entryHandler:^(ORK1State *from, ORK1State *to, ORK1SpatialSpanMemoryStepViewController *this) {
                                                               [this showFailed];
                                                           }
                                                            exitHandler:nil context:self];
    
    states[@(ORK1SpatialSpanStepStateTimeout)] = [ORK1State stateWithState:ORK1SpatialSpanStepStateTimeout
                                                            entryHandler:^(ORK1State *from, ORK1State *to, ORK1SpatialSpanMemoryStepViewController *this) {
                                                                [this showTimeout];
                                                            }
                                                             exitHandler:nil context:self];
    
    states[@(ORK1SpatialSpanStepStateRestart)] = [ORK1State stateWithState:ORK1SpatialSpanStepStateRestart
                                                            entryHandler:^(ORK1State *from, ORK1State *to, ORK1SpatialSpanMemoryStepViewController *this) {
                                                                [this doRestart];
                                                            }
                                                             exitHandler:nil context:self];
    
    states[@(ORK1SpatialSpanStepStateComplete)] = [ORK1State stateWithState:ORK1SpatialSpanStepStateComplete
                                                             entryHandler:^(ORK1State *from, ORK1State *to, ORK1SpatialSpanMemoryStepViewController *this) {
                                                                 [this showComplete];
                                                             } exitHandler:nil context:self];
    
    states[@(ORK1SpatialSpanStepStateStopped)] = [ORK1State stateWithState:ORK1SpatialSpanStepStateStopped
                                                            entryHandler:nil
                                                             exitHandler:nil
                                                                 context:self];
    
    states[@(ORK1SpatialSpanStepStatePaused)] = [ORK1State stateWithState:ORK1SpatialSpanStepStatePaused
                                                           entryHandler:^(ORK1State *from, ORK1State *to, ORK1SpatialSpanMemoryStepViewController *this) {
                                                               [this showPausedFromState:from];
                                                           } exitHandler:nil context:self];
    
    _states = states;
    
    [self transitionToState:ORK1SpatialSpanStepStateInitial];
}

- (void)transitionToState:(ORK1SpatialSpanStepState)state {
    ORK1State *stateObject = _states[@(state)];
    
    ORK1State *oldState = _state;
    if (oldState.exitHandler != nil) {
        oldState.exitHandler(oldState, stateObject, oldState.context);
    }
    _state = stateObject;
    if (stateObject.entryHandler) {
        stateObject.entryHandler(oldState, stateObject, stateObject.context);
    }
}

@end
