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

typedef NS_ENUM(NSInteger, ORKLegacySpatialSpanStepState) {
    ORKLegacySpatialSpanStepStateInitial,
    ORKLegacySpatialSpanStepStatePlayback,
    ORKLegacySpatialSpanStepStateGameplay,
    ORKLegacySpatialSpanStepStateTimeout,
    ORKLegacySpatialSpanStepStateFailed,
    ORKLegacySpatialSpanStepStateSuccess,
    ORKLegacySpatialSpanStepStateRestart,
    ORKLegacySpatialSpanStepStateComplete,
    ORKLegacySpatialSpanStepStateStopped,
    ORKLegacySpatialSpanStepStatePaused
};

@class ORKLegacyState;

typedef void (^_ORKLegacyStateHandler)(ORKLegacyState *fromState, ORKLegacyState *_toState, id context);

// Poor man's state machine:
// Define entry and exit handlers for each state.
// Transitions are a free for all!
@interface ORKLegacyState : NSObject

+ (ORKLegacyState *)stateWithState:(NSInteger)state entryHandler:(_ORKLegacyStateHandler)entryHandler exitHandler:(_ORKLegacyStateHandler)exitHandler context:(id)context;

@property (nonatomic, assign) NSInteger state;

@property (nonatomic, weak) id context;

@property (nonatomic, copy) _ORKLegacyStateHandler entryHandler;
- (void)setEntryHandler:(_ORKLegacyStateHandler)entryHandler;

@property (nonatomic, copy) _ORKLegacyStateHandler exitHandler;
- (void)setExitHandler:(_ORKLegacyStateHandler)exitHandler;

@end


@implementation ORKLegacyState

+ (ORKLegacyState *)stateWithState:(NSInteger)state entryHandler:(_ORKLegacyStateHandler)entryHandler exitHandler:(_ORKLegacyStateHandler)exitHandler context:(id)context {
    ORKLegacyState *s = [ORKLegacyState new];
    s.state = state;
    s.entryHandler = entryHandler;
    s.exitHandler = exitHandler;
    s.context = context;
    return s;
}

@end


@interface ORKLegacySpatialSpanMemoryStepViewController () <ORKLegacySpatialSpanMemoryGameViewDelegate>

@end


@implementation ORKLegacySpatialSpanMemoryStepViewController {
    ORKLegacySpatialSpanMemoryContentView *_contentView;
    ORKLegacyState *_state;
    NSDictionary *_states;
    ORKLegacyGridSize _gridSize;
    
    ORKLegacySpatialSpanGameState *_currentGameState;
    UIBarButtonItem *_customLearnMoreButtonItem;
    UIBarButtonItem *_learnMoreButtonItem;
    
    // ORKLegacySpatialSpanMemoryGameRecord
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

- (ORKLegacySpatialSpanMemoryStep *)spatialSpanStep {
    return (ORKLegacySpatialSpanMemoryStep *)self.step;
}

- (instancetype)initWithStep:(ORKLegacyStep *)step {
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
        self.learnMoreButtonItem = [[UIBarButtonItem alloc] initWithTitle:ORKLegacyLocalizedString(@"BUTTON_COPYRIGHT", nil) style:UIBarButtonItemStylePlain target:self action:@selector(showCopyright)];
    }
    
    [super viewDidLoad];
    
    _contentView = [ORKLegacySpatialSpanMemoryContentView new];
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    _contentView.footerHidden = YES;
    _contentView.gameView.delegate = self;
    self.activeStepView.activeCustomView = _contentView;
    self.activeStepView.stepViewFillsAvailableSpace = NO;
    self.activeStepView.minimumStepHeaderHeight = ORKLegacyGetMetricForWindow(ORKLegacyScreenMetricMinimumStepHeaderHeightForMemoryGame, self.view.window);
    
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
        [self transitionToState:ORKLegacySpatialSpanStepStateInitial];
    }
    
    [self transitionToState:ORKLegacySpatialSpanStepStatePlayback];
}

- (void)suspend {
    [super suspend];
    switch (_state.state) {
        case ORKLegacySpatialSpanStepStatePlayback:
        case ORKLegacySpatialSpanStepStateGameplay:
            [self transitionToState:ORKLegacySpatialSpanStepStatePaused];
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
    [self transitionToState:ORKLegacySpatialSpanStepStateStopped];
}

- (ORKLegacyStepResult *)result {
    ORKLegacyStepResult *stepResult = [super result];
    
    // "Now" is the end time of the result, which is either actually now,
    // or the last time we were in the responder chain.
    NSDate *now = stepResult.endDate;
    
    NSMutableArray *results = [NSMutableArray arrayWithArray:stepResult.results];
    
    ORKLegacySpatialSpanMemoryResult *memoryResult = [[ORKLegacySpatialSpanMemoryResult alloc] initWithIdentifier:self.step.identifier];
    memoryResult.startDate = stepResult.startDate;
    memoryResult.endDate = now;
    
    NSMutableArray *records = [NSMutableArray new];
    
    __block NSInteger numberOfFailures = 0;
    __block NSInteger score = 0;
    // Only include valid records
    [_gameRecords enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ORKLegacySpatialSpanMemoryGameRecord *record = (ORKLegacySpatialSpanMemoryGameRecord *)obj;
        if (record.gameStatus != ORKLegacySpatialSpanMemoryGameStatusUnknown) {
            [records addObject:record];
            
            score += record.score;
            
            if (record.gameStatus != ORKLegacySpatialSpanMemoryGameStatusSuccess) {
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

- (ORKLegacySpatialSpanMemoryGameRecord *)currentGameRecord {
    return _gameRecords ? _gameRecords.lastObject : nil;
}

- (void)createGameRecord {
    if (_gameRecords == nil) {
        _gameRecords = [NSMutableArray new];
    }
    
    ORKLegacySpatialSpanMemoryGameRecord *gameRecord = [ORKLegacySpatialSpanMemoryGameRecord new];
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
    ORKLegacySpatialSpanMemoryGameRecord *record = [self currentGameRecord];
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
    if (_state.state != ORKLegacySpatialSpanStepStateGameplay) {
        return;
    }
    [self updateGameRecordOnTouch:-1 location:[tapRecognizer locationInView: self.view]];
}

- (void)updateGameRecordOnTouch:(NSInteger)targetIndex location:(CGPoint)location {
    ORKLegacySpatialSpanMemoryGameTouchSample *sample = [ORKLegacySpatialSpanMemoryGameTouchSample new];
    
    sample.timestamp = CACurrentMediaTime() - _gameStartTime;
    sample.location = location;
    sample.targetIndex = targetIndex;
    
    ORKLegacySpatialSpanMemoryGameRecord *record = [self currentGameRecord];
    
    NSAssert(record, nil);
    
    NSInteger currentStep = 0;
    
    for (ORKLegacySpatialSpanMemoryGameTouchSample *aSample in record.touchSamples) {
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
    [self currentGameRecord].gameStatus = ORKLegacySpatialSpanMemoryGameStatusSuccess;
}

- (void)updateGameRecordOnFailure {
    [self currentGameRecord].gameStatus = ORKLegacySpatialSpanMemoryGameStatusFailure;
}

- (void)updateGameRecordOnTimeout {
    [self currentGameRecord].gameStatus = ORKLegacySpatialSpanMemoryGameStatusTimeout;
}

- (void)updateGameRecordScore {
    [self currentGameRecord].score = _score - _lastRoundScore;
}

- (void)updateGameRecordOnPause {
    [self currentGameRecord].gameStatus = ORKLegacySpatialSpanMemoryGameStatusUnknown;
}

#pragma mark ORKLegacySpatialSpanStepStateInitial

- (ORKLegacyGridSize)gridSizeForSpan:(NSInteger)span {
    NSInteger numberOfGridEntriesDesired = span * 2;
    NSInteger value = (NSInteger)ceil(sqrt(numberOfGridEntriesDesired));
    value = MAX(value, 2);
    value = MIN(value, 6);
    return (ORKLegacyGridSize){value,value};
}

- (void)resetGameAndUI {
    _score = 0;
    _numberOfItems = 0;
    _gamesCounter = 0;
    _consecutiveGamesFailed = 0;
    ORKLegacySpatialSpanMemoryStep *step = [self spatialSpanStep];
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
    
    ORKLegacySpatialSpanGame *game = [[ORKLegacySpatialSpanGame alloc] initWithGameSize:_gridSize.width * _gridSize.height sequenceLength:sequenceLength seed:0];
    ORKLegacySpatialSpanGameState *gameState = [[ORKLegacySpatialSpanGameState alloc] initWithGame:game];
    
    _currentGameState = gameState;
    
    [self createGameRecord];
    
    [self resetUI];
}

#pragma mark ORKLegacySpatialSpanStepStatePlayback

- (void)applyTargetState:(ORKLegacySpatialSpanTargetState)targetState toSequenceIndex:(NSInteger)index duration:(NSTimeInterval)duration {
    ORKLegacySpatialSpanGame *game = _currentGameState.game;
    if (index == NSNotFound || index < 0 || index >= game.sequenceLength ) {
        return;
    }
    
    NSInteger tileIndex = [game tileIndexForStep:index];
    ORKLegacySpatialSpanMemoryGameView *gameView = _contentView.gameView;
    [gameView setState:targetState forTileIndex:tileIndex animated:YES];
    if (duration > 0 && targetState != ORKLegacySpatialSpanTargetStateQuiescent) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self applyTargetState:ORKLegacySpatialSpanTargetStateQuiescent toSequenceIndex:index duration:0];
        });
    }
}

- (void)playbackNextItem {
    const NSInteger sequenceLength = _currentGameState.game.sequenceLength;
    if (_playbackIndex >= sequenceLength) {
        [self transitionToState:ORKLegacySpatialSpanStepStateGameplay];
    } else {
        ORKLegacySpatialSpanMemoryStep *step = [self spatialSpanStep];
        
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
        [self applyTargetState:ORKLegacySpatialSpanTargetStateQuiescent toSequenceIndex:previousIndex duration:0];
        
        // The active display should be visible for half the timer interval
        [self applyTargetState:ORKLegacySpatialSpanTargetStateActive toSequenceIndex:index duration:(step.playSpeed / 2)];
    }
    _playbackIndex++;
}

- (void)startPlayback {
    _playbackIndex = 0;
    _contentView.footerHidden = YES;
    _contentView.buttonItem = nil;
    ORKLegacySpatialSpanMemoryStep *step = [self spatialSpanStep];
    NSString *title = [NSString localizedStringWithFormat:ORKLegacyLocalizedString(@"MEMORY_GAME_PLAYBACK_TITLE_%@", nil), step.customTargetPluralName ? : ORKLegacyLocalizedString(@"SPATIAL_SPAN_MEMORY_TARGET_PLURAL", nil)];
    
    [self.activeStepView updateTitle:title text:nil];
    
    [_contentView.gameView resetTilesAnimated:NO];
    
    _playbackTimer = [NSTimer scheduledTimerWithTimeInterval:step.playSpeed target:self selector:@selector(playbackNextItem) userInfo:nil repeats:YES];
}

- (void)finishPlayback {
    [_playbackTimer invalidate];
    _playbackTimer = nil;
}

#pragma mark ORKLegacySpatialSpanStepStateGameplay

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
    [self transitionToState:ORKLegacySpatialSpanStepStateTimeout];
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
    ORKLegacySpatialSpanMemoryStep *step = [self spatialSpanStep];
    NSString *pluralItemName = step.customTargetPluralName ? : ORKLegacyLocalizedString(@"SPATIAL_SPAN_MEMORY_TARGET_PLURAL", nil);
    NSString *standaloneItemName = step.customTargetPluralName ? : ORKLegacyLocalizedString(@"SPATIAL_SPAN_MEMORY_TARGET_STANDALONE", nil);
    _contentView.capitalizedPluralItemDescription = [standaloneItemName capitalizedStringWithLocale:[NSLocale currentLocale]];
    NSString *titleFormat = step.requireReversal ?  ORKLegacyLocalizedString(@"MEMORY_GAME_GAMEPLAY_REVERSE_TITLE_%@", nil) : ORKLegacyLocalizedString(@"MEMORY_GAME_GAMEPLAY_TITLE_%@", nil);
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

- (void)gameView:(ORKLegacySpatialSpanMemoryGameView *)gameView didTapTileWithIndex:(NSInteger)tileIndex recognizer:(UITapGestureRecognizer *)recognizer {
    if (_state.state != ORKLegacySpatialSpanStepStateGameplay) {
        return;
    }
    
    [self updateGameRecordOnTouch:tileIndex location:[recognizer locationInView:self.view]];
    
    ORKLegacySpatialSpanResult result = [_currentGameState playTileIndex:tileIndex];
    switch (result) {
        case ORKLegacySpatialSpanResultIgnore:
            break;
            
        case ORKLegacySpatialSpanResultCorrect:
            [gameView setState:ORKLegacySpatialSpanTargetStateCorrect forTileIndex:tileIndex animated:YES];
            NSInteger stepIndex = [_currentGameState currentStepIndex];
            
            [self setNumberOfItems:_numberOfItems + 1];
            [self setScore:_score + (round(log2(stepIndex)) + 1) * 5];
            
            [self resetActivityTimer];
            if ([_currentGameState isComplete]) {
                [self transitionToState:ORKLegacySpatialSpanStepStateSuccess];
            }
            break;
            
        case ORKLegacySpatialSpanResultIncorrect:
            [gameView setState:ORKLegacySpatialSpanTargetStateIncorrect forTileIndex:tileIndex animated:YES];
            [self transitionToState:ORKLegacySpatialSpanStepStateFailed];
            break;
    }
}

#pragma mark ORKLegacySpatialSpanStepStateSuccess

- (void)updateGameCountersForSuccess:(BOOL)success {
    ORKLegacySpatialSpanMemoryStep *step = [self spatialSpanStep];
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
    ORKLegacySpatialSpanMemoryStep *step = [self spatialSpanStep];
    if (_gamesCounter < step.maximumTests && _consecutiveGamesFailed < step.maximumConsecutiveFailures) {
        // Generate a new game
        [self transitionToState:ORKLegacySpatialSpanStepStateRestart];
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
    
    [self.activeStepView updateTitle:ORKLegacyLocalizedString(@"MEMORY_GAME_COMPLETE_TITLE", nil) text:ORKLegacyLocalizedString(@"MEMORY_GAME_COMPLETE_MESSAGE", nil)];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _contentView.buttonItem = [[UIBarButtonItem alloc] initWithTitle:ORKLegacyLocalizedString(@"BUTTON_NEXT", nil) style:UIBarButtonItemStylePlain target:self action:@selector(continueAction)];
    });
}

#pragma mark ORKLegacySpatialSpanStepStateFailed

- (void)tryAgainAction {
    // Restart with a new, shorter game
    [self transitionToState:ORKLegacySpatialSpanStepStateRestart];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (BOOL)finishIfCompletedGames {
    ORKLegacySpatialSpanMemoryStep *step = [self spatialSpanStep];
    if (_consecutiveGamesFailed >= step.maximumConsecutiveFailures || _gamesCounter >= step.maximumTests) {
        [self transitionToState:ORKLegacySpatialSpanStepStateComplete];
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
    [self.activeStepView updateTitle:ORKLegacyLocalizedString(@"MEMORY_GAME_FAILED_TITLE", nil) text:ORKLegacyLocalizedString(@"MEMORY_GAME_FAILED_MESSAGE", nil)];
    
    _contentView.buttonItem = [[UIBarButtonItem alloc] initWithTitle:ORKLegacyLocalizedString(@"BUTTON_NEXT", nil) style:UIBarButtonItemStylePlain target:self action:@selector(tryAgainAction)];
}

#pragma mark ORKLegacySpatialSpanStepStateTimeout

- (void)showTimeout {
    [self updateGameRecordOnTimeout];
    
    [self updateGameCountersForSuccess:NO];
    if ([self finishIfCompletedGames]) {
        return;
    }
    
    [self.activeStepView updateTitle:ORKLegacyLocalizedString(@"MEMORY_GAME_TIMEOUT_TITLE", nil) text:ORKLegacyLocalizedString(@"MEMORY_GAME_TIMEOUT_MESSAGE", nil)];
    
    _contentView.buttonItem = [[UIBarButtonItem alloc] initWithTitle:ORKLegacyLocalizedString(@"BUTTON_NEXT", nil) style:UIBarButtonItemStylePlain target:self action:@selector(tryAgainAction)];
}

#pragma mark ORKLegacySpatialSpanStepStateComplete

- (void)showComplete {
    [self.activeStepView updateTitle:ORKLegacyLocalizedString(@"MEMORY_GAME_COMPLETE_TITLE", nil) text:nil];
    
    // Show the copyright
    self.activeStepView.headerView.learnMoreButton.alpha = 1;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _contentView.buttonItem = [[UIBarButtonItem alloc] initWithTitle:ORKLegacyLocalizedString(@"BUTTON_NEXT", nil) style:UIBarButtonItemStylePlain target:self action:@selector(continueAction)];
    });
}

- (void)showCopyright {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:ORKLegacyLocalizedString(@"MEMORY_GAME_COPYRIGHT_TEXT", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:ORKLegacyLocalizedString(@"BUTTON_OK", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark ORKLegacySpatialSpanStepStateRestart

- (void)doRestart {
    [self resetForNewGame];
    dispatch_async(dispatch_get_main_queue(), ^{
        // Dispatch, so we don't do this in the middle of a state transition
        if (_state.state == ORKLegacySpatialSpanStepStateRestart) {
            [self transitionToState:ORKLegacySpatialSpanStepStatePlayback];
        }
    });
}

- (void)showPausedFromState:(ORKLegacyState *)fromState {
    [self updateGameRecordOnPause];
    
    // Do not update game counters - doesn't count as a game.
    
    [_activityTimer invalidate]; _activityTimer = nil;
    [_playbackTimer invalidate]; _playbackTimer = nil;
    
    [self resetForNewGame];
    [self.activeStepView updateTitle:ORKLegacyLocalizedString(@"MEMORY_GAME_PAUSED_TITLE", nil) text:ORKLegacyLocalizedString(@"MEMORY_GAME_PAUSED_MESSAGE", nil)];
    _contentView.buttonItem = [[UIBarButtonItem alloc] initWithTitle:ORKLegacyLocalizedString(@"BUTTON_NEXT", nil) style:UIBarButtonItemStylePlain target:self action:@selector(continueAction)];
}

#pragma mark State machine

- (void)initializeStates {
    NSMutableDictionary *states = [NSMutableDictionary dictionary];
    
    states[@(ORKLegacySpatialSpanStepStateInitial)] = [ORKLegacyState stateWithState:ORKLegacySpatialSpanStepStateInitial
                                                            entryHandler:^(ORKLegacyState *from, ORKLegacyState *to, ORKLegacySpatialSpanMemoryStepViewController *this) {
                                                                [this resetGameAndUI];
                                                            }
                                                             exitHandler:nil context:self];
    
    states[@(ORKLegacySpatialSpanStepStatePlayback)] = [ORKLegacyState stateWithState:ORKLegacySpatialSpanStepStatePlayback
                                                             entryHandler:^(ORKLegacyState *from, ORKLegacyState *to, ORKLegacySpatialSpanMemoryStepViewController *this) {
                                                                 [this startPlayback];
                                                             }
                                                              exitHandler:^(ORKLegacyState *from, ORKLegacyState *to, ORKLegacySpatialSpanMemoryStepViewController *this) {
                                                                  [this finishPlayback];
                                                              } context:self];
    
    states[@(ORKLegacySpatialSpanStepStateGameplay)] = [ORKLegacyState stateWithState:ORKLegacySpatialSpanStepStateGameplay
                                                             entryHandler:^(ORKLegacyState *from, ORKLegacyState *to, ORKLegacySpatialSpanMemoryStepViewController *this) {
                                                                 [this startGameplay];
                                                             }
                                                              exitHandler:^(ORKLegacyState *from, ORKLegacyState *to, ORKLegacySpatialSpanMemoryStepViewController *this) {
                                                                  [this finishGameplay];
                                                              } context:self];
    
    states[@(ORKLegacySpatialSpanStepStateSuccess)] = [ORKLegacyState stateWithState:ORKLegacySpatialSpanStepStateSuccess
                                                            entryHandler:^(ORKLegacyState *from, ORKLegacyState *to, ORKLegacySpatialSpanMemoryStepViewController *this) {
                                                                [this showSuccess];
                                                            }
                                                             exitHandler:nil context:self];
    
    states[@(ORKLegacySpatialSpanStepStateFailed)] = [ORKLegacyState stateWithState:ORKLegacySpatialSpanStepStateFailed
                                                           entryHandler:^(ORKLegacyState *from, ORKLegacyState *to, ORKLegacySpatialSpanMemoryStepViewController *this) {
                                                               [this showFailed];
                                                           }
                                                            exitHandler:nil context:self];
    
    states[@(ORKLegacySpatialSpanStepStateTimeout)] = [ORKLegacyState stateWithState:ORKLegacySpatialSpanStepStateTimeout
                                                            entryHandler:^(ORKLegacyState *from, ORKLegacyState *to, ORKLegacySpatialSpanMemoryStepViewController *this) {
                                                                [this showTimeout];
                                                            }
                                                             exitHandler:nil context:self];
    
    states[@(ORKLegacySpatialSpanStepStateRestart)] = [ORKLegacyState stateWithState:ORKLegacySpatialSpanStepStateRestart
                                                            entryHandler:^(ORKLegacyState *from, ORKLegacyState *to, ORKLegacySpatialSpanMemoryStepViewController *this) {
                                                                [this doRestart];
                                                            }
                                                             exitHandler:nil context:self];
    
    states[@(ORKLegacySpatialSpanStepStateComplete)] = [ORKLegacyState stateWithState:ORKLegacySpatialSpanStepStateComplete
                                                             entryHandler:^(ORKLegacyState *from, ORKLegacyState *to, ORKLegacySpatialSpanMemoryStepViewController *this) {
                                                                 [this showComplete];
                                                             } exitHandler:nil context:self];
    
    states[@(ORKLegacySpatialSpanStepStateStopped)] = [ORKLegacyState stateWithState:ORKLegacySpatialSpanStepStateStopped
                                                            entryHandler:nil
                                                             exitHandler:nil
                                                                 context:self];
    
    states[@(ORKLegacySpatialSpanStepStatePaused)] = [ORKLegacyState stateWithState:ORKLegacySpatialSpanStepStatePaused
                                                           entryHandler:^(ORKLegacyState *from, ORKLegacyState *to, ORKLegacySpatialSpanMemoryStepViewController *this) {
                                                               [this showPausedFromState:from];
                                                           } exitHandler:nil context:self];
    
    _states = states;
    
    [self transitionToState:ORKLegacySpatialSpanStepStateInitial];
}

- (void)transitionToState:(ORKLegacySpatialSpanStepState)state {
    ORKLegacyState *stateObject = _states[@(state)];
    
    ORKLegacyState *oldState = _state;
    if (oldState.exitHandler != nil) {
        oldState.exitHandler(oldState, stateObject, oldState.context);
    }
    _state = stateObject;
    if (stateObject.entryHandler) {
        stateObject.entryHandler(oldState, stateObject, stateObject.context);
    }
}

@end
