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


#import "ORK1FitnessStepViewController.h"

#import "ORK1ActiveStepTimer.h"
#import "ORK1ActiveStepView.h"
#import "ORK1FitnessContentView.h"
#import "ORK1VerticalContainerView.h"

#import "ORK1StepViewController_Internal.h"
#import "ORK1HealthQuantityTypeRecorder.h"
#import "ORK1PedometerRecorder.h"

#import "ORK1ActiveStepViewController_Internal.h"
#import "ORK1FitnessStep.h"
#import "ORK1Step_Private.h"

#import "ORK1Helpers_Internal.h"


@interface ORK1FitnessStepViewController () <ORK1HealthQuantityTypeRecorderDelegate, ORK1PedometerRecorderDelegate> {
    NSInteger _intendedSteps;
    ORK1FitnessContentView *_contentView;
    NSNumberFormatter *_hrFormatter;
}

@end


@implementation ORK1FitnessStepViewController

- (instancetype)initWithStep:(ORK1Step *)step {    
    self = [super initWithStep:step];
    if (self) {
        self.suspendIfInactive = NO;
    }
    return self;
}

- (ORK1FitnessStep *)fitnessStep {
    return (ORK1FitnessStep *)self.step;
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
    _contentView = [ORK1FitnessContentView new];
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
    
    ORK1PedometerRecorder *pedometerRecorder = nil;
    ORK1HealthQuantityTypeRecorder *heartRateRecorder = nil;
    for (ORK1Recorder *recorder in self.recorders) {
        if ([recorder isKindOfClass:[ORK1PedometerRecorder class]]) {
            pedometerRecorder = (ORK1PedometerRecorder *)recorder;
        } else if ([recorder isKindOfClass:[ORK1HealthQuantityTypeRecorder class]]) {
            ORK1HealthQuantityTypeRecorder *rec1 = (ORK1HealthQuantityTypeRecorder *)recorder;
            if ([[[rec1 quantityType] identifier] isEqualToString:HKQuantityTypeIdentifierHeartRate]) {
                heartRateRecorder = (ORK1HealthQuantityTypeRecorder *)recorder;
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

- (void)countDownTimerFired:(ORK1ActiveStepTimer *)timer finished:(BOOL)finished {
    _contentView.timeLeft = finished ? 0 : (timer.duration - timer.runtime);
    [super countDownTimerFired:timer finished:finished];
}

#pragma mark - ORK1HealthQuantityTypeRecorderDelegate

- (void)healthQuantityTypeRecorderDidUpdate:(ORK1HealthQuantityTypeRecorder *)healthQuantityTypeRecorder {
    if ([[healthQuantityTypeRecorder.quantityType identifier] isEqualToString:HKQuantityTypeIdentifierHeartRate]) {
        [self updateHeartRateWithQuantity:healthQuantityTypeRecorder.lastSample unit:healthQuantityTypeRecorder.unit];
    }
}

#pragma mark - ORK1PedometerRecorderDelegate

- (void)pedometerRecorderDidUpdate:(ORK1PedometerRecorder *)pedometerRecorder {
    double distanceInMeters = pedometerRecorder.totalDistance;
    [self updateDistance:distanceInMeters];
}

@end
