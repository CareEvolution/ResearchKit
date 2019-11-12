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


#import "ORK1AudioStepViewController.h"

#import "ORK1ActiveStepTimer.h"
#import "ORK1ActiveStepView.h"
#import "ORK1AudioContentView.h"
#import "ORK1CustomStepView_Internal.h"
#import "ORK1VerticalContainerView.h"

#import "ORK1ActiveStepViewController_Internal.h"
#import "ORK1AudioRecorder.h"

#import "ORK1AudioStep.h"
#import "ORK1Step_Private.h"

#import "ORK1Helpers_Internal.h"

@import AVFoundation;


@interface ORK1AudioStepViewController ()

@property (nonatomic, strong) AVAudioRecorder *avAudioRecorder;

@end


@implementation ORK1AudioStepViewController {
    ORK1AudioContentView *_audioContentView;
    ORK1AudioRecorder *_audioRecorder;
    ORK1ActiveStepTimer *_timer;
    NSError *_audioRecorderError;
}

- (instancetype)initWithStep:(ORK1Step *)step {
    self = [super initWithStep:step];
    if (self) {
        // Continue audio recording in the background
        self.suspendIfInactive = NO;
    }
    return self;
}

- (void)setAlertThreshold:(CGFloat)alertThreshold {
    _alertThreshold = alertThreshold;
    if (self.isViewLoaded && alertThreshold > 0) {
        _audioContentView.alertThreshold = alertThreshold;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _audioContentView = [ORK1AudioContentView new];
    _audioContentView.timeLeft = self.audioStep.stepDuration;

    if (self.alertThreshold > 0) {
        _audioContentView.alertThreshold = self.alertThreshold;
    }

    self.activeStepView.activeCustomView = _audioContentView;
}

- (void)audioRecorderDidChange {
    _audioRecorder.audioRecorder.meteringEnabled = YES;
    [self setAvAudioRecorder:_audioRecorder.audioRecorder];
}

- (void)recordersDidChange {
    ORK1AudioRecorder *audioRecorder = nil;
    for (ORK1Recorder *recorder in self.recorders) {
        if ([recorder isKindOfClass:[ORK1AudioRecorder class]]) {
            audioRecorder = (ORK1AudioRecorder *)recorder;
            break;
        }
    }
    _audioRecorder = audioRecorder;
    [self audioRecorderDidChange];
}

- (ORK1AudioStep *)audioStep {
    return (ORK1AudioStep *)self.step;
}

- (void)doSample {
    if (_audioRecorderError) {
        return;
    }
    [_avAudioRecorder updateMeters];
    float value = [_avAudioRecorder averagePowerForChannel:0];
    // Assume value is in range roughly -60dB to 0dB
    float clampedValue = MAX(value / 60.0, -1) + 1;
    [_audioContentView addSample:@(clampedValue)];
    _audioContentView.timeLeft = [_timer duration] - [_timer runtime];
}

- (void)startNewTimerIfNeeded {
    if (!_timer) {
        NSTimeInterval duration = self.audioStep.stepDuration;
        ORK1WeakTypeOf(self) weakSelf = self;
        _timer = [[ORK1ActiveStepTimer alloc] initWithDuration:duration interval:duration / 100 runtime:0 handler:^(ORK1ActiveStepTimer *timer, BOOL finished) {
            ORK1StrongTypeOf(self) strongSelf = weakSelf;
            [strongSelf doSample];
            if (finished) {
                [strongSelf finish];
            }
        }];
        [_timer resume];
    }
    _audioContentView.finished = NO;
}

- (void)start {
    [super start];
    [self audioRecorderDidChange];
    [_timer reset];
    _timer = nil;
    [self startNewTimerIfNeeded];
    
}

- (void)suspend {
    [super suspend];
    [_timer pause];
    if (_avAudioRecorder) {
        [_audioContentView addSample:@(0)];
    }
}

- (void)resume {
    [super resume];
    [self audioRecorderDidChange];
    [self startNewTimerIfNeeded];
    [_timer resume];
}

- (void)finish {
    if (_audioRecorderError) {
        return;
    }
    [super finish];
    [_timer reset];
    _timer = nil;
}

- (void)stepDidFinish {
    _audioContentView.finished = YES;
}

- (void)setAvAudioRecorder:(AVAudioRecorder *)recorder {
    _avAudioRecorder = nil;
    _avAudioRecorder = recorder;
}

- (void)recorder:(ORK1Recorder *)recorder didFailWithError:(NSError *)error {
    [super recorder:recorder didFailWithError:error];
    _audioRecorderError = error;
    _audioContentView.failed = YES;
}

@end
