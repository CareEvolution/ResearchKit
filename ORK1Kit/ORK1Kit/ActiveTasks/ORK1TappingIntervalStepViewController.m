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


#import "ORK1TappingIntervalStepViewController.h"

#import "ORK1ActiveStepTimer.h"
#import "ORK1RoundTappingButton.h"
#import "ORK1TappingContentView.h"
#import "ORK1VerticalContainerView.h"

#import "ORK1ActiveStepViewController_Internal.h"
#import "ORK1StepViewController_Internal.h"

#import "ORK1ActiveStepView.h"
#import "ORK1Result.h"
#import "ORK1Step.h"

#import "ORK1Helpers_Internal.h"


@interface ORK1TappingIntervalStepViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSMutableArray *samples;

@end


@implementation ORK1TappingIntervalStepViewController {
    ORK1TappingContentView *_tappingContentView;
    NSTimeInterval _tappingStart;
    BOOL _expired;
    
    CGRect _buttonRect1;
    CGRect _buttonRect2;
    CGSize _viewSize;
    
    NSUInteger _hitButtonCount;
    
    UIGestureRecognizer *_touchDownRecognizer;
}

- (instancetype)initWithStep:(ORK1Step *)step {
    self = [super initWithStep:step];
    if (self) {
        self.suspendIfInactive = YES;
    }
    return self;
}

- (void)initializeInternalButtonItems {
    [super initializeInternalButtonItems];
    
    // Don't show next button
    self.internalContinueButtonItem = nil;
    self.internalDoneButtonItem = nil;
    self.internalSkipButtonItem.title = ORK1LocalizedString(@"TAPPING_SKIP_TITLE", nil);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tappingStart = 0;
    
    _touchDownRecognizer = [UIGestureRecognizer new];
    _touchDownRecognizer.delegate = self;
    [self.view addGestureRecognizer:_touchDownRecognizer];
    
    self.activeStepView.stepViewFillsAvailableSpace = YES;
    
    self.timerUpdateInterval = 0.1;
    
    _expired = NO;
    
    _tappingContentView = [[ORK1TappingContentView alloc] init];
    _tappingContentView.hasSkipButton = self.step.optional;
    self.activeStepView.activeCustomView = _tappingContentView;
    
    [_tappingContentView.tapButton1 addTarget:self action:@selector(buttonPressed:forEvent:) forControlEvents:UIControlEventTouchDown];
    [_tappingContentView.tapButton2 addTarget:self action:@selector(buttonPressed:forEvent:) forControlEvents:UIControlEventTouchDown];
    [_tappingContentView.tapButton1 addTarget:self action:@selector(buttonReleased:forEvent:) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];
    [_tappingContentView.tapButton2 addTarget:self action:@selector(buttonReleased:forEvent:) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    _buttonRect1 = [self.view convertRect:_tappingContentView.tapButton1.bounds fromView:_tappingContentView.tapButton1];
    _buttonRect2 = [self.view convertRect:_tappingContentView.tapButton2.bounds fromView:_tappingContentView.tapButton2];
    _viewSize = self.view.frame.size;
}

- (ORK1StepResult *)result {
    ORK1StepResult *sResult = [super result];
    
    // "Now" is the end time of the result, which is either actually now,
    // or the last time we were in the responder chain.
    NSDate *now = sResult.endDate;
    
    NSMutableArray *results = [NSMutableArray arrayWithArray:sResult.results];
    
    ORK1TappingIntervalResult *tappingResult = [[ORK1TappingIntervalResult alloc] initWithIdentifier:self.step.identifier];
    tappingResult.startDate = sResult.startDate;
    tappingResult.endDate = now;
    tappingResult.buttonRect1 = _buttonRect1;
    tappingResult.buttonRect2 = _buttonRect2;
    tappingResult.stepViewSize = _viewSize;
    
    tappingResult.samples = _samples;
    
    [results addObject:tappingResult];
    sResult.results = [results copy];
    
    return sResult;
}

- (void)receiveTouch:(UITouch *)touch onButton:(ORK1TappingButtonIdentifier)buttonIdentifier {
    if (_expired || self.samples == nil) {
        return;
    }
    
    NSTimeInterval mediaTime = touch.timestamp;
    
    if (_tappingStart == 0) {
        _tappingStart = mediaTime;
    }
    
    CGPoint location = [touch locationInView:self.view];
    
    // Add new sample
    mediaTime = mediaTime-_tappingStart;
    
    ORK1TappingSample *sample = [[ORK1TappingSample alloc] init];
    sample.buttonIdentifier = buttonIdentifier;
    sample.location = location;
    sample.duration = 0;
    sample.timestamp = mediaTime;

    [self.samples addObject:sample];
    
    if (buttonIdentifier == ORK1TappingButtonIdentifierLeft || buttonIdentifier == ORK1TappingButtonIdentifierRight) {
        _hitButtonCount++;
    }
    // Update label
    [_tappingContentView setTapCount:_hitButtonCount];
}

- (void)releaseTouch:(UITouch *)touch onButton:(ORK1TappingButtonIdentifier)buttonIdentifier {
    if (self.samples == nil) {
        return;
    }
    NSTimeInterval mediaTime = touch.timestamp;
    
    // Take last sample for buttonIdentifier, and fill duration
    ORK1TappingSample *sample = [self lastSampleWithEmptyDurationForButton:buttonIdentifier];
    sample.duration = mediaTime - sample.timestamp - _tappingStart;
}

- (ORK1TappingSample *)lastSampleWithEmptyDurationForButton:(ORK1TappingButtonIdentifier)buttonIdentifier{
    NSEnumerator *enumerator = [self.samples reverseObjectEnumerator];
    for (ORK1TappingSample *sample in enumerator) {
        if (sample.buttonIdentifier == buttonIdentifier && sample.duration == 0) {
            return sample;
        }
    }
    return nil;
}

- (void)fillSampleDurationIfAnyButtonPressed {
    /*
     * Because we will not able to get UITouch from UIButton, we will use systemUptime.
     * Documentation for -[UITouch timestamp] tells:
     * The value of this property is the time, in seconds, since system startup the touch either originated or was last changed.
     * For a definition of the time-since-boot value, see the description of the systemUptime method of the NSProcessInfo class.
     */
    NSTimeInterval mediaTime = [[NSProcessInfo processInfo] systemUptime];
    
    ORK1TappingSample *tapButton1LastSample = [self lastSampleWithEmptyDurationForButton:ORK1TappingButtonIdentifierLeft];
    if (tapButton1LastSample) {
        tapButton1LastSample.duration = mediaTime - tapButton1LastSample.timestamp - _tappingStart;
    }
    
    ORK1TappingSample *tapButton2LastSample = [self lastSampleWithEmptyDurationForButton:ORK1TappingButtonIdentifierRight];
    if (tapButton2LastSample) {
        tapButton2LastSample.duration = mediaTime - tapButton2LastSample.timestamp - _tappingStart;
    }
}

- (void)stepDidFinish {
    [super stepDidFinish];
    
    // If user didn't release touch from button, fill manually duration for last sample
    [self fillSampleDurationIfAnyButtonPressed];
    
    _expired = YES;
    [_tappingContentView finishStep:self];
    [self goForward];
}

- (void)countDownTimerFired:(ORK1ActiveStepTimer *)timer finished:(BOOL)finished {
    CGFloat progress = finished ? 1 : (timer.runtime / timer.duration);
    [_tappingContentView setProgress:progress animated:YES];
    [super countDownTimerFired:timer finished:finished];
}

- (void)start {
    [super start];
    self.skipButtonItem = nil;
    [_tappingContentView setProgress:0.001 animated:NO];
}

#pragma mark buttonAction

- (IBAction)buttonPressed:(id)button forEvent:(UIEvent *)event {
    
    if (self.samples == nil) {
        // Start timer on first touch event on button
        _samples = [NSMutableArray array];
        _hitButtonCount = 0;
        [self start];
    }
    
    NSInteger index = (button == _tappingContentView.tapButton1) ? ORK1TappingButtonIdentifierLeft : ORK1TappingButtonIdentifierRight;
    
    if ( _tappingContentView.lastTappedButton == index ) {
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, ORK1LocalizedString(@"TAP_BUTTON_TITLE", nil));
    }
    _tappingContentView.lastTappedButton = index;
    
    [self receiveTouch:[[event touchesForView:button] anyObject] onButton:index];
}

- (IBAction)buttonReleased:(id)button forEvent:(UIEvent *)event {
    ORK1TappingButtonIdentifier index = (button == _tappingContentView.tapButton1) ? ORK1TappingButtonIdentifierLeft : ORK1TappingButtonIdentifierRight;
    
    [self releaseTouch:[[event touchesForView:button] anyObject] onButton:index];
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGPoint location = [touch locationInView:self.view];

    BOOL shouldReceive = !(CGRectContainsPoint(_buttonRect1, location) || CGRectContainsPoint(_buttonRect2, location));
    
    if (shouldReceive && touch.phase == UITouchPhaseBegan) {
        [self receiveTouch:touch onButton:ORK1TappingButtonIdentifierNone];
    }
    
    return NO;
}

@end
