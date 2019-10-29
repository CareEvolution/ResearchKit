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


#import "RK1FitnessStepViewController.h"

#import "RK1ActiveStepTimer.h"
#import "RK1ActiveStepView.h"
#import "RK1FitnessContentView.h"
#import "RK1VerticalContainerView.h"

#import "RK1StepViewController_Internal.h"
#import "RK1HealthQuantityTypeRecorder.h"
#import "RK1PedometerRecorder.h"

#import "RK1ActiveStepViewController_Internal.h"
#import "RK1FitnessStep.h"
#import "RK1Step_Private.h"

#import "RK1Helpers_Internal.h"


@interface RK1FitnessStepViewController () <RK1HealthQuantityTypeRecorderDelegate, RK1PedometerRecorderDelegate> {
    NSInteger _intendedSteps;
    RK1FitnessContentView *_contentView;
    NSNumberFormatter *_hrFormatter;
}

@end


@implementation RK1FitnessStepViewController

- (instancetype)initWithStep:(RK1Step *)step {    
    self = [super initWithStep:step];
    if (self) {
        self.suspendIfInactive = NO;
    }
    return self;
}

- (RK1FitnessStep *)fitnessStep {
    return (RK1FitnessStep *)self.step;
}

- (void)stepDidChange {
    [super stepDidChange];
    _hrFormatter = [[NSNumberFormatter alloc] init];
    _hrFormatter.numberStyle = kCFNumberFormatterNoStyle;
    _contentView.timeLeft = self.fitnessStep.stepDuration;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _contentView = [RK1FitnessContentView new];
    _contentView.image = self.fitnessStep.image;
    _contentView.timeLeft = self.fitnessStep.stepDuration;
    self.activeStepView.activeCustomView = _contentView;
    self.activeStepView.stepViewFillsAvailableSpace = YES;
}

- (void)updateHeartRateWithQuantity:(HKQuantitySample *)quantity unit:(HKUnit *)unit {
    if (quantity != nil) {
        _contentView.hasHeartRate = YES;
    }
    if (quantity) {
        _contentView.heartRate = [_hrFormatter stringFromNumber:@([quantity.quantity doubleValueForUnit:unit])];
    } else {
        _contentView.heartRate = @"--";
    }
}

- (void)updateDistance:(double)distanceInMeters {
    _contentView.hasDistance = YES;
    _contentView.distanceInMeters = distanceInMeters;
    
}

- (void)recordersDidChange {
    [super recordersDidChange];
    
    RK1PedometerRecorder *pedometerRecorder = nil;
    RK1HealthQuantityTypeRecorder *heartRateRecorder = nil;
    for (RK1Recorder *recorder in self.recorders) {
        if ([recorder isKindOfClass:[RK1PedometerRecorder class]]) {
            pedometerRecorder = (RK1PedometerRecorder *)recorder;
        } else if ([recorder isKindOfClass:[RK1HealthQuantityTypeRecorder class]]) {
            RK1HealthQuantityTypeRecorder *rec1 = (RK1HealthQuantityTypeRecorder *)recorder;
            if ([[[rec1 quantityType] identifier] isEqualToString:HKQuantityTypeIdentifierHeartRate]) {
                heartRateRecorder = (RK1HealthQuantityTypeRecorder *)recorder;
            }
        }
    }
    
    if (heartRateRecorder == nil) {
        _contentView.hasHeartRate = NO;
    }
    _contentView.heartRate = @"--";
    _contentView.hasDistance = (pedometerRecorder != nil);
    _contentView.distanceInMeters = 0;
    
}

- (void)countDownTimerFired:(RK1ActiveStepTimer *)timer finished:(BOOL)finished {
    _contentView.timeLeft = finished ? 0 : (timer.duration - timer.runtime);
    [super countDownTimerFired:timer finished:finished];
}

#pragma mark - RK1HealthQuantityTypeRecorderDelegate

- (void)healthQuantityTypeRecorderDidUpdate:(RK1HealthQuantityTypeRecorder *)healthQuantityTypeRecorder {
    if ([[healthQuantityTypeRecorder.quantityType identifier] isEqualToString:HKQuantityTypeIdentifierHeartRate]) {
        [self updateHeartRateWithQuantity:healthQuantityTypeRecorder.lastSample unit:healthQuantityTypeRecorder.unit];
    }
}

#pragma mark - RK1PedometerRecorderDelegate

- (void)pedometerRecorderDidUpdate:(RK1PedometerRecorder *)pedometerRecorder {
    double distanceInMeters = pedometerRecorder.totalDistance;
    [self updateDistance:distanceInMeters];
}

@end
