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


#import "ORKActiveStepViewController.h"

#import "ORKActiveStepTimer.h"
#import "ORKActiveStepTimerView.h"
#import "ORKActiveStepView.h"
#import "ORKNavigationContainerView.h"
#import "ORKStepHeaderView_Internal.h"
#import "ORKVerticalContainerView.h"
#import "ORKVoiceEngine.h"

#import "ORKActiveStepViewController_Internal.h"
#import "ORKStepViewController_Internal.h"
#import "ORKTaskViewController_Internal.h"
#import "ORKRecorder_Internal.h"

#import "ORKActiveStep_Internal.h"
#import "ORKResult.h"
#import "ORKTask.h"

#import "ORKAccessibility.h"
#import "ORKHelpers_Internal.h"
#import "ORKSkin.h"


@interface ORKLegacyActiveStepViewController () {
    ORKLegacyActiveStepView *_activeStepView;
    ORKLegacyActiveStepTimer *_activeStepTimer;

    NSArray *_recorderResults;
    
    SystemSoundID _alertSound;
    NSURL *_alertSoundURL;
    BOOL _hasSpokenHalfwayCountdown;
}

@property (nonatomic, strong) NSArray *recorders;

@end


@implementation ORKLegacyActiveStepViewController

- (instancetype)initWithStep:(ORKLegacyStep *)step {
    
    self = [super initWithStep:step];
    if (self) {
        _recorderResults = [NSArray new];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        _timerUpdateInterval = 1;
    }
    return self;
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    if (self.suspendIfInactive) {
        [self suspend];
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (self.suspendIfInactive) {
        [self resume];
    }
}

- (ORKLegacyActiveStep *)activeStep {
    NSAssert(self.step == nil || [self.step isKindOfClass:[ORKLegacyActiveStep class]], @"Step should be a subclass of an ORKLegacyActiveStep");
    return (ORKLegacyActiveStep *)self.step;
}

- (ORKLegacyActiveStepView *)activeStepView {
    return _activeStepView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _activeStepView = [[ORKLegacyActiveStepView alloc] initWithFrame:self.view.bounds];
    _activeStepView.translatesAutoresizingMaskIntoConstraints = NO;
    [_activeStepView setCustomView:_customView];
    [self updateContinueButtonItem];
    _activeStepView.headerView.learnMoreButtonItem = self.learnMoreButtonItem;
    _activeStepView.continueSkipContainer.skipButtonItem = self.skipButtonItem;
    _activeStepView.continueSkipContainer.continueEnabled = _finished;
    [self.view addSubview:_activeStepView];
    
    NSMutableArray *constraints = [NSMutableArray new];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[activeStepView]|"
                                                                             options:(NSLayoutFormatOptions)0
                                                                             metrics:nil
                                                                               views:@{@"activeStepView": _activeStepView}]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide][activeStepView]|"
                                                                             options:(NSLayoutFormatOptions)0
                                                                             metrics:nil
                                                                               views:@{@"activeStepView": _activeStepView,
                                                                                       @"topLayoutGuide": self.topLayoutGuide}]];
    [NSLayoutConstraint activateConstraints:constraints];
    
    [self prepareStep];
}

- (void)stepDidChange {
    [super stepDidChange];
    _activeStepView.activeStep = [self activeStep];
    [self updateContinueButtonItem];
    
    
    [self prepareStep];
}

- (UIView *)customViewContainer {
    __unused UIView *view = [self view];
    return _activeStepView.customViewContainer;
}

- (ORKLegacyTintedImageView *)imageView {
    __unused UIView *view = [self view];
    return _activeStepView.imageView;
}

- (void)setCustomView:(UIView *)customView {
    _customView = customView;
    [_activeStepView setStepView:_customView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    ORKLegacy_Log_Debug(@"%@",self);

    [self.taskViewController setRegisteredScrollView:_activeStepView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    ORKLegacy_Log_Debug(@"%@",self);
    
    // Wait for animation complete 
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.started){
            // Should call resume instead of start when the task has been started.
            [self resume];
        } else if ([[self activeStep] shouldStartTimerAutomatically]) {
            [self start];
        }
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    ORKLegacy_Log_Debug(@"%@",self);
    
    [self suspend];
}

- (void)updateContinueButtonItem {
    _activeStepView.continueSkipContainer.continueButtonItem = self.continueButtonItem;
}

- (void)setContinueButtonItem:(UIBarButtonItem *)continueButtonItem {
    [super setContinueButtonItem:continueButtonItem];
    [self updateContinueButtonItem];
}

- (void)setLearnMoreButtonItem:(UIBarButtonItem *)learnMoreButtonItem {
    [super setLearnMoreButtonItem:learnMoreButtonItem];
    _activeStepView.headerView.learnMoreButtonItem = self.learnMoreButtonItem;
}

- (void)setSkipButtonItem:(UIBarButtonItem *)skipButtonItem {
    [super setSkipButtonItem:skipButtonItem];
    _activeStepView.continueSkipContainer.skipButtonItem = skipButtonItem;
}

- (void)setFinished:(BOOL)finished {
    _finished = finished;
    _activeStepView.continueSkipContainer.continueEnabled = finished;
}

- (ORKLegacyStepResult *)result {
    ORKLegacyStepResult *sResult = [super result];
    if (_recorderResults) {
        sResult.results = [sResult.results arrayByAddingObjectsFromArray:_recorderResults] ? : _recorderResults;
    }
    return sResult;
}

#pragma mark - transition

- (void)recordersDidChange {
}

- (void)recordersWillStart {
}

- (void)recordersWillStop {
}

- (void)prepareRecorders {
    // Stop any existing recorders
    [self recordersWillStop];
    for (ORKLegacyRecorder *recorder in self.recorders) {
        recorder.delegate = nil;
        [recorder stop];
    }
    NSMutableArray *recorders = [NSMutableArray array];
    
    for (ORKLegacyRecorderConfiguration * provider in self.activeStep.recorderConfigurations) {
        // If the outputDirectory is nil, recorders which require one will generate an error.
        // We start them anyway, because we don't know which recorders will require an outputDirectory.
        ORKLegacyRecorder *recorder = [provider recorderForStep:self.step
                                          outputDirectory:self.outputDirectory];
        recorder.configuration = provider;
        recorder.delegate = self;
        
        [recorders addObject:recorder];
    }
    self.recorders = recorders;
    
    [self recordersDidChange];
}

- (void)setOutputDirectory:(NSURL *)outputDirectory {
    [super setOutputDirectory:outputDirectory];
    [self prepareStep];
}

- (void)prepareStep {
    if (self.activeStep == nil) {
        return;
    }
    
    self.finished = [[self activeStep] startsFinished];
    
    ORKLegacy_Log_Debug(@"%@", self);
    _activeStepView.activeStep = self.activeStep;
    
    if ([self.activeStep hasCountDown]) {
        ORKLegacyActiveStepTimerView *timerView = [ORKLegacyActiveStepTimerView new];
        _activeStepView.activeCustomView = timerView;
    } else {
        _activeStepView.activeCustomView = nil;
    }
    _activeStepView.activeCustomView.activeStepViewController = self;
    [_activeStepView.activeCustomView resetStep:self];
    [self resetTimer];
    
    [self prepareRecorders];
}

- (void)startRecorders {
    [self recordersWillStart];
    // Start recorders
    for (ORKLegacyRecorder *recorder in self.recorders) {
        [recorder viewController:self willStartStepWithView:self.customViewContainer];
        [recorder start];
    }
}

- (void)stopRecorders {
    [self recordersWillStop];
    for (ORKLegacyRecorder *recorder in self.recorders) {
        [recorder stop];
    }
}

- (void)playSound {
    if (_alertSoundURL == nil) {
        _alertSoundURL = [NSURL URLWithString:@"/System/Library/Audio/UISounds/short_low_high.caf"];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)(_alertSoundURL), &_alertSound);
    }
    AudioServicesPlaySystemSound(_alertSound);
}

- (void)start {
    ORKLegacy_Log_Debug(@"%@",self);
    self.started = YES;
    [self startTimer];
    [_activeStepView.activeCustomView startStep:self];
    
    [self startRecorders];
    
    if (self.activeStep.shouldVibrateOnStart) {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    }
    
    if (self.activeStep.shouldPlaySoundOnStart) {
        [self playSound];
    }
    
    // Start speech
    if (self.activeStep.hasVoice && self.activeStep.spokenInstruction) {
        // Let VO speak "Step x of y" before the instruction.
        // If VO is not running, the text is spoken immediately.
        ORKLegacyAccessibilityPerformBlockAfterDelay(1.5, ^{
            [[ORKLegacyVoiceEngine sharedVoiceEngine] speakText:self.activeStep.spokenInstruction];
        });
    }
}

- (void)suspend {
    ORKLegacy_Log_Debug(@"%@",self);
    if (self.finished || !self.started) {
        return;
    }
    
    [_activeStepTimer pause];
    [_activeStepView.activeCustomView suspendStep:self];
    
    [self stopRecorders];
}

- (void)resume {
    ORKLegacy_Log_Debug(@"%@",self);
    if (self.finished || !self.started) {
        return;
    }
    
    [_activeStepTimer resume];
    [self prepareRecorders];
    [self startRecorders];
    [_activeStepView.activeCustomView resumeStep:self];
}

- (void)finish {
    ORKLegacy_Log_Debug(@"%@",self);
    if (self.finished) {
        return;
    }
    
    self.finished = YES;
    [_activeStepTimer pause];
    [_activeStepView.activeCustomView finishStep:self];
    [self stopRecorders];
    if (self.activeStep.shouldPlaySoundOnFinish) {
        [self playSound];
    }
    if (self.activeStep.shouldVibrateOnFinish) {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    }
    if (self.activeStep.hasVoice && self.activeStep.finishedSpokenInstruction) {
        [[ORKLegacyVoiceEngine sharedVoiceEngine] speakText:self.activeStep.finishedSpokenInstruction];
    }
    if (!self.activeStep.startsFinished) {
        if (self.activeStep.shouldContinueOnFinish) {
            [self goForward];
        }
    }
    [self stepDidFinish];
}

- (void)dealloc {
    AudioServicesDisposeSystemSoundID(_alertSound);
    NSNotificationCenter *nfc = [NSNotificationCenter defaultCenter];
    [nfc removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [nfc removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - timers

- (void)resetTimer {
    [_activeStepTimer reset];
    _activeStepTimer = nil;
}

- (void)startTimer {
    [self resetTimer];
    
    NSTimeInterval stepDuration = self.activeStep.stepDuration;
    
    if (stepDuration > 0) {
        ORKLegacyWeakTypeOf(self) weakSelf = self;
        _activeStepTimer = [[ORKLegacyActiveStepTimer alloc] initWithDuration:stepDuration
                                                        interval:_timerUpdateInterval
                                                         runtime:0
                                                         handler:^(ORKLegacyActiveStepTimer *timer, BOOL finished) {
                                                             ORKLegacyStrongTypeOf(self) strongSelf = weakSelf;
                                                             [strongSelf countDownTimerFired:timer finished:finished];
                                                         }];
        [_activeStepTimer resume];
    }
}

- (void)countDownTimerFired:(ORKLegacyActiveStepTimer *)timer finished:(BOOL)finished {
    if (finished) {
        [self finish];
    }
    NSInteger countDownValue = (NSInteger)round(timer.duration - timer.runtime);
    ORKLegacyActiveStepCustomView *customView = _activeStepView.activeCustomView;
    [customView updateDisplay:self];
    
    
    ORKLegacyVoiceEngine *voice = [ORKLegacyVoiceEngine sharedVoiceEngine];
    
    if (!finished && self.activeStep.shouldSpeakCountDown) {
        // Speak entire countdown if VO is running.
        if (UIAccessibilityIsVoiceOverRunning()) {
            [voice speakInt:countDownValue];
            return;
        }
        
        if (0 < countDownValue && countDownValue <= 3) {
            [voice speakInt:countDownValue];
        }
    }
    
    BOOL isHalfway = !_hasSpokenHalfwayCountdown && timer.runtime > timer.duration / 2.0;
    if (!finished && self.activeStep.shouldSpeakRemainingTimeAtHalfway && !UIAccessibilityIsVoiceOverRunning() && isHalfway) {
        _hasSpokenHalfwayCountdown = YES;
        NSString *text = [NSString localizedStringWithFormat:ORKLegacyLocalizedString(@"COUNTDOWN_SPOKEN_REMAINING_%@", nil), @(countDownValue)];
        [voice speakText:text];
    }
}

- (BOOL)timerActive {
    return (_activeStepTimer != nil);
}

- (NSTimeInterval)timeRemaining {
    if (_activeStepTimer == nil) {
        return self.activeStep.stepDuration;
    }
    return _activeStepTimer.duration - _activeStepTimer.runtime;
}

#pragma mark - action handlers

- (void)stepDidFinish {
}

#pragma mark - ORKLegacyRecorderDelegate

- (void)recorder:(ORKLegacyRecorder *)recorder didCompleteWithResult:(ORKLegacyResult *)result {
    _recorderResults = [_recorderResults arrayByAddingObject:result];
    [self notifyDelegateOnResultChange];
}

- (void)recorder:(ORKLegacyRecorder *)recorder didFailWithError:(NSError *)error {
    if (error) {
        ORKLegacyStrongTypeOf(self.delegate) strongDelegate = self.delegate;
        if ([strongDelegate respondsToSelector:@selector(stepViewController:recorder:didFailWithError:)]) {
            [strongDelegate stepViewController:self recorder:recorder didFailWithError:error];
        }
        
        // If the recorder returns an error indicating that file write failed, and the output directory was nil,
        // we consider it a fatal error and fail the step. Otherwise, developers might be confused to get
        // no output, just because they did not set an output directory.
        if ([error.domain isEqualToString:NSCocoaErrorDomain] &&
            error.code == NSFileWriteInvalidFileNameError &&
            self.outputDirectory == nil) {
            [strongDelegate stepViewControllerDidFail:self withError:error];
        }
    }
}

static NSString *const _ORKLegacyFinishedRestoreKey = @"finished";
static NSString *const _ORKLegacyRecorderResultsRestoreKey = @"recorderResults";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeBool:_finished forKey:_ORKLegacyFinishedRestoreKey];
    [coder encodeObject:_recorderResults forKey:_ORKLegacyRecorderResultsRestoreKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    self.finished = [coder decodeBoolForKey:_ORKLegacyFinishedRestoreKey];
    _recorderResults = [coder decodeObjectOfClass:[NSArray class] forKey:_ORKLegacyRecorderResultsRestoreKey];
}

@end
