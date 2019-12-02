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


#import "ORK1HolePegTestRemoveStepViewController.h"

#import "ORK1ActiveStepView.h"
#import "ORK1HolePegTestRemoveContentView.h"

#import "ORK1ActiveStepViewController_Internal.h"
#import "ORK1StepViewController_Internal.h"
#import "ORK1TaskViewController.h"

#import "ORK1HolePegTestRemoveStep.h"

#import "ORK1Helpers_Internal.h"
#import "ORK1Result.h"


@interface ORK1HolePegTestRemoveStepViewController () <ORK1HolePegTestRemoveContentViewDelegate>

@property (nonatomic, strong) NSMutableArray *samples;
@property (nonatomic, strong) ORK1HolePegTestRemoveContentView *holePegTestRemoveContentView;
@property (nonatomic, assign) NSTimeInterval sampleStart;
@property (nonatomic, assign) NSUInteger successes;
@property (nonatomic, assign) NSUInteger failures;

@end


@implementation ORK1HolePegTestRemoveStepViewController

- (instancetype)initWithStep:(ORK1Step *)step {
    self = [super initWithStep:step];
    if (self) {
        self.suspendIfInactive = YES;
    }
    return self;
}

- (ORK1HolePegTestRemoveStep *)holePegTestRemoveStep {
    return (ORK1HolePegTestRemoveStep *)self.step;
}

- (void)initializeInternalButtonItems {
    [super initializeInternalButtonItems];
    
    // Don't show next button
    self.internalContinueButtonItem = nil;
    self.internalDoneButtonItem = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.holePegTestRemoveContentView = [[ORK1HolePegTestRemoveContentView alloc] initWithMovingDirection:[self holePegTestRemoveStep].movingDirection];
    self.holePegTestRemoveContentView.threshold = [self holePegTestRemoveStep].threshold;
    self.holePegTestRemoveContentView.delegate = self;
    self.activeStepView.activeCustomView = self.holePegTestRemoveContentView;
    self.activeStepView.stepViewFillsAvailableSpace = YES;
    
    NSString *identifier = [[self holePegTestRemoveStep].identifier stringByReplacingOccurrencesOfString:@"remove" withString:@"place"];
    NSTimeInterval placeStepDuration = ((ORK1HolePegTestResult *)[[self.taskViewController.result stepResultForStepIdentifier:identifier].results firstObject]).totalTime;
    [self holePegTestRemoveStep].stepDuration -= placeStepDuration;
    
    [self start];
}

#pragma mark - step life cycle methods

- (void)start {
    self.sampleStart = CACurrentMediaTime();
    self.successes = 0;
    self.failures = 0;
    self.samples = [NSMutableArray array];
    [self.holePegTestRemoveContentView setProgress:0.001f animated:NO];
    
    [super start];
}

#pragma mark - result methods

- (ORK1StepResult *)result {
    ORK1StepResult *sResult = [super result];
    
    NSMutableArray *results = [NSMutableArray arrayWithArray:sResult.results];
    
    ORK1HolePegTestResult *holePegTestResult = [[ORK1HolePegTestResult alloc] initWithIdentifier:self.step.identifier];
    holePegTestResult.movingDirection = [self holePegTestRemoveStep].movingDirection;
    holePegTestResult.dominantHandTested = [self holePegTestRemoveStep].isDominantHandTested;
    holePegTestResult.numberOfPegs = [self holePegTestRemoveStep].numberOfPegs;
    holePegTestResult.threshold = [self holePegTestRemoveStep].threshold;
    holePegTestResult.rotated = NO;
    holePegTestResult.totalSuccesses = self.successes;
    holePegTestResult.totalFailures = self.failures;
    holePegTestResult.totalTime = [self holePegTestRemoveStep].stepDuration - self.timeRemaining;
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
    NSString *title = ([self holePegTestRemoveStep].movingDirection == ORK1BodySagittalLeft) ? ORK1LocalizedString(@"HOLE_PEG_TEST_REMOVE_INSTRUCTION_RIGHT_HAND", nil) : ORK1LocalizedString(@"HOLE_PEG_TEST_REMOVE_INSTRUCTION_LEFT_HAND", nil);
    return title;
}

- (void)holePegTestRemoveDidProgress:(ORK1HolePegTestRemoveContentView *)holePegTestRemoveContentView {
    [self.activeStepView updateTitle:[self stepTitle]
                                text:ORK1LocalizedString(@"HOLE_PEG_TEST_TEXT_2", nil)];
}

- (void)holePegTestRemoveDidSucceed:(ORK1HolePegTestRemoveContentView *)holePegTestRemoveContentView withDistance:(CGFloat)distance {
    self.successes++;
    
    [self saveSampleWithDistance:distance];
    
    [holePegTestRemoveContentView setProgress:((CGFloat)self.successes / [self holePegTestRemoveStep].numberOfPegs) animated:YES];
    [self.activeStepView updateTitle:[self stepTitle]
                                text:ORK1LocalizedString(@"HOLE_PEG_TEST_TEXT", nil)];
    
    if (self.successes >= [self holePegTestRemoveStep].numberOfPegs) {
        [self finish];
    }
}

- (void)holePegTestRemoveDidFail:(ORK1HolePegTestRemoveContentView *)holePegTestRemoveContentView {
    self.failures++;
    
    [self.activeStepView updateTitle:[self stepTitle]
                                text:ORK1LocalizedString(@"HOLE_PEG_TEST_TEXT", nil)];
}

@end
