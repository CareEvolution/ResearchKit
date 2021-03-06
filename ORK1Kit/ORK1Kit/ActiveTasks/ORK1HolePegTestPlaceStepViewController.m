/*
 Copyright (c) 2015, Shazino SAS. All rights reserved.
 
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


#import "ORK1HolePegTestPlaceStepViewController.h"

#import "ORK1ActiveStepView.h"
#import "ORK1HolePegTestPlaceContentView.h"

#import "ORK1ActiveStepViewController_Internal.h"
#import "ORK1StepViewController_Internal.h"
#import "ORK1TaskViewController.h"

#import "ORK1HolePegTestPlaceStep.h"
#import "ORK1NavigableOrderedTask.h"
#import "ORK1Result.h"

#import "ORK1Helpers_Internal.h"


@interface ORK1HolePegTestPlaceStepViewController () <ORK1HolePegTestPlaceContentViewDelegate>

@property (nonatomic, strong) NSMutableArray *samples;
@property (nonatomic, strong) ORK1HolePegTestPlaceContentView *holePegTestPlaceContentView;
@property (nonatomic, assign) NSTimeInterval sampleStart;
@property (nonatomic, assign) NSUInteger successes;
@property (nonatomic, assign) NSUInteger failures;

@end


@implementation ORK1HolePegTestPlaceStepViewController

- (instancetype)initWithStep:(ORK1Step *)step {
    self = [super initWithStep:step];
    if (self) {
        self.suspendIfInactive = YES;
    }
    return self;
}

- (ORK1HolePegTestPlaceStep *)holePegTestPlaceStep {
    return (ORK1HolePegTestPlaceStep *)self.step;
}

- (void)initializeInternalButtonItems {
    [super initializeInternalButtonItems];
    
    // Don't show next button
    self.internalContinueButtonItem = nil;
    self.internalDoneButtonItem = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.holePegTestPlaceContentView = [[ORK1HolePegTestPlaceContentView alloc] initWithMovingDirection:[self holePegTestPlaceStep].movingDirection
                                                                                               rotated:[self holePegTestPlaceStep].rotated];
    self.holePegTestPlaceContentView.threshold = [self holePegTestPlaceStep].threshold;
    self.holePegTestPlaceContentView.delegate = self;
    self.activeStepView.activeCustomView = self.holePegTestPlaceContentView;
    self.activeStepView.stepViewFillsAvailableSpace = YES;
}

#pragma mark - step life cycle methods

- (void)start {
    self.successes = 0;
    self.failures = 0;
    self.samples = [NSMutableArray array];
    [self.holePegTestPlaceContentView setProgress:0.001f animated:NO];
    
    [super start];
}

#pragma mark - result methods

- (ORK1StepResult *)result {
    ORK1StepResult *sResult = [super result];

    NSMutableArray *results = [NSMutableArray arrayWithArray:sResult.results];

    ORK1HolePegTestResult *holePegTestResult = [[ORK1HolePegTestResult alloc] initWithIdentifier:self.step.identifier];
    holePegTestResult.movingDirection = [self holePegTestPlaceStep].movingDirection;
    holePegTestResult.dominantHandTested = [self holePegTestPlaceStep].isDominantHandTested;
    holePegTestResult.numberOfPegs = [self holePegTestPlaceStep].numberOfPegs;
    holePegTestResult.threshold = [self holePegTestPlaceStep].threshold;
    holePegTestResult.rotated = [self holePegTestPlaceStep].isRotated;
    holePegTestResult.totalSuccesses = self.successes;
    holePegTestResult.totalFailures = self.failures;
    holePegTestResult.totalTime = [self holePegTestPlaceStep].stepDuration - self.timeRemaining;
    double totalDistance = 0.0;
    for (ORK1HolePegTestSample *sample in self.samples) {
        totalDistance += sample.distance;
    }
    holePegTestResult.totalDistance = totalDistance;
    holePegTestResult.samples = self.samples;

    [results addObject:holePegTestResult];
    
    sResult.results = [results copy];
    
    return sResult;
}

- (void)saveSampleWithDistance:(CGFloat)distance {
    ORK1HolePegTestSample *sample = [[ORK1HolePegTestSample alloc] init];
    sample.time = CACurrentMediaTime() - self.sampleStart;
    sample.distance = distance;
    self.sampleStart = CACurrentMediaTime();
    
    [self.samples addObject:sample];
}

#pragma mark - hole peg test content view delegate

- (NSString *)stepTitle {
    NSString *title = ([self holePegTestPlaceStep].movingDirection == ORK1BodySagittalLeft) ? ORK1LocalizedString(@"HOLE_PEG_TEST_PLACE_INSTRUCTION_LEFT_HAND", nil) : ORK1LocalizedString(@"HOLE_PEG_TEST_PLACE_INSTRUCTION_RIGHT_HAND", nil);
    return title;
}

- (void)holePegTestPlaceDidProgress:(ORK1HolePegTestPlaceContentView *)holePegTestPlaceContentView {
    if (!self.isStarted) {
        self.sampleStart = CACurrentMediaTime();
        [self start];
    }
    
    [self.activeStepView updateTitle:[self stepTitle]
                                text:ORK1LocalizedString(@"HOLE_PEG_TEST_TEXT_2", nil)];
}

- (void)holePegTestPlaceDidSucceed:(ORK1HolePegTestPlaceContentView *)holePegTestPlaceContentView withDistance:(CGFloat)distance {
    self.successes++;
    
    [self saveSampleWithDistance:distance];
    
    [holePegTestPlaceContentView setProgress:((CGFloat)self.successes / [self holePegTestPlaceStep].numberOfPegs) animated:YES];
    [self.activeStepView updateTitle:[self stepTitle]
                                text:ORK1LocalizedString(@"HOLE_PEG_TEST_TEXT", nil)];
    
    if (self.successes >= [self holePegTestPlaceStep].numberOfPegs) {
        [((ORK1NavigableOrderedTask *)self.taskViewController.task) removeNavigationRuleForTriggerStepIdentifier:[self holePegTestPlaceStep].identifier];
        [self finish];
    }
}

- (void)holePegTestPlaceDidFail:(ORK1HolePegTestPlaceContentView *)holePegTestPlaceContentView {
    self.failures++;
    
    [self.activeStepView updateTitle:[self stepTitle]
                                text:ORK1LocalizedString(@"HOLE_PEG_TEST_TEXT", nil)];
}

@end
