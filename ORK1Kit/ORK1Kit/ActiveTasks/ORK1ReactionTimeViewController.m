/*
 Copyright (c) 2015, James Cox. All rights reserved.
 
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


#import "ORK1ReactionTimeViewController.h"

#import "ORK1ActiveStepView.h"
#import "ORK1ReactionTimeContentView.h"

#import "ORK1ActiveStepViewController_Internal.h"
#import "ORK1StepViewController_Internal.h"

#import "ORK1ReactionTimeStep.h"
#import "ORK1Result.h"

#import "ORK1Helpers_Internal.h"

#import <AudioToolbox/AudioServices.h>
#import <CoreMotion/CMDeviceMotion.h>


@implementation ORK1ReactionTimeViewController {
    ORK1ReactionTimeContentView *_reactionTimeContentView;
    NSMutableArray *_results;
    NSTimer *_stimulusTimer;
    NSTimer *_timeoutTimer;
    NSTimeInterval _stimulusTimestamp;
    BOOL _validResult;
    BOOL _timedOut;
    BOOL _shouldIndicateFailure;
}

static const NSTimeInterval OutcomeAnimationDuration = 0.3;

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self configureTitle];
    _results = [NSMutableArray new];
    _reactionTimeContentView = [ORK1ReactionTimeContentView new];
    self.activeStepView.activeCustomView = _reactionTimeContentView;
    self.activeStepView.stepViewFillsAvailableSpace = YES;
    [_reactionTimeContentView setStimulusHidden:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self start];
    _shouldIndicateFailure = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    _shouldIndicateFailure = NO;
}

#pragma mark - ORK1ActiveStepViewController

- (void)start {
    [super start];
    [self startStimulusTimer];

}

#if TARGET_IPHONE_SIMULATOR
- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (event.type == UIEventSubtypeMotionShake) {
        if (_validResult) {
            ORK1ReactionTimeResult *reactionTimeResult = [[ORK1ReactionTimeResult alloc] initWithIdentifier:self.step.identifier];
            reactionTimeResult.timestamp = _stimulusTimestamp;
            [_results addObject:reactionTimeResult];
        }
        [self attemptDidFinish];
    }
}
#endif


- (ORK1StepResult *)result {
    ORK1StepResult *stepResult = [super result];
    stepResult.results = [self.addedResults arrayByAddingObjectsFromArray:_results] ? : _results;
    return stepResult;
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    [super applicationWillResignActive:notification];
    _validResult = NO;
    [_stimulusTimer invalidate];
    [_timeoutTimer invalidate];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [super applicationDidBecomeActive:notification];
    [self resetAfterDelay:0];
}

#pragma mark - ORK1RecorderDelegate

- (void)recorder:(ORK1Recorder *)recorder didCompleteWithResult:(ORK1Result *)result {
    if (_validResult) {
        ORK1ReactionTimeResult *reactionTimeResult = [[ORK1ReactionTimeResult alloc] initWithIdentifier:self.step.identifier];
        reactionTimeResult.timestamp = _stimulusTimestamp;
        reactionTimeResult.fileResult = (ORK1FileResult *)result;
        [_results addObject:reactionTimeResult];
    }
    [self attemptDidFinish];
}

#pragma mark - ORK1DeviceMotionRecorderDelegate

- (void)deviceMotionRecorderDidUpdateWithMotion:(CMDeviceMotion *)motion {
    CMAcceleration v = motion.userAcceleration;
    double vectorMagnitude = sqrt(((v.x * v.x) + (v.y * v.y) + (v.z * v.z)));
    if (vectorMagnitude > [self reactionTimeStep].thresholdAcceleration) {
        [self stopRecorders];
    }
}

#pragma mark - ORK1ReactionTimeStepViewController

- (ORK1ReactionTimeStep *)reactionTimeStep {
    return (ORK1ReactionTimeStep *)self.step;
}

- (void)configureTitle {
    NSString *format = ORK1LocalizedString(@"REACTION_TIME_TASK_ATTEMPTS_FORMAT", nil);
    NSString *text = [NSString stringWithFormat:format, ORK1LocalizedStringFromNumber(@(_results.count + 1)), ORK1LocalizedStringFromNumber(@([self reactionTimeStep].numberOfAttempts))];
    [self.activeStepView updateTitle:ORK1LocalizedString(@"REACTION_TIME_TASK_ACTIVE_STEP_TITLE", nil) text:text];
}

- (void)attemptDidFinish {
    void (^completion)(void) = ^{
        if (_results.count == [self reactionTimeStep].numberOfAttempts) {
            [self finish];
        } else {
            [self resetAfterDelay:2];
        }
    };
    if (_validResult) {
        [self indicateSuccess:completion];
    } else {
        [self indicateFailure:completion];
    }
    _validResult = NO;
    _timedOut = NO;
    [_stimulusTimer invalidate];
    [_timeoutTimer invalidate];
}

- (void)indicateSuccess:(void(^)(void))completion {
    [_reactionTimeContentView startSuccessAnimationWithDuration:OutcomeAnimationDuration completion:completion];
    AudioServicesPlaySystemSound([self reactionTimeStep].successSound);
}

- (void)indicateFailure:(void(^)(void))completion {
    if (!_shouldIndicateFailure) {
        return;
    }
    [_reactionTimeContentView startFailureAnimationWithDuration:OutcomeAnimationDuration completion:completion];
    SystemSoundID sound = _timedOut ? [self reactionTimeStep].timeoutSound : [self reactionTimeStep].failureSound;
    AudioServicesPlayAlertSound(sound);
}

- (void)resetAfterDelay:(NSTimeInterval)delay {
    ORK1WeakTypeOf(self) weakSelf = self;
    [_reactionTimeContentView resetAfterDelay:delay completion:^{
        [weakSelf configureTitle];
        [weakSelf start];
    }];
}

- (void)startStimulusTimer {
    _stimulusTimer = [NSTimer scheduledTimerWithTimeInterval:[self stimulusInterval] target:self selector:@selector(stimulusTimerDidFire) userInfo:nil repeats:NO];
}

- (void)stimulusTimerDidFire {
    _stimulusTimestamp = [NSProcessInfo processInfo].systemUptime;
    [_reactionTimeContentView setStimulusHidden:NO];
    _validResult = YES;
    [self startTimeoutTimer];
}

- (void)startTimeoutTimer {
    NSTimeInterval timeout = [self reactionTimeStep].timeout;
    if (timeout > 0) {
        _timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(timeoutTimerDidFire) userInfo:nil repeats:NO];
    }
}

- (void)timeoutTimerDidFire {
    _validResult = NO;
    _timedOut = YES;
    [self stopRecorders];
    
#if TARGET_IPHONE_SIMULATOR
    // Device motion recorder won't work, so manually trigger didfinish
    [self attemptDidFinish];
#endif
}

- (NSTimeInterval)stimulusInterval {
    ORK1ReactionTimeStep *step = [self reactionTimeStep];
    NSTimeInterval range = step.maximumStimulusInterval - step.minimumStimulusInterval;
    NSTimeInterval randomFactor = ((NSTimeInterval)rand() / RAND_MAX) * range;
    return randomFactor + step.minimumStimulusInterval;
}

@end