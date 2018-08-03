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


#import "ORK1WalkingTaskStepViewController.h"

#import "ORK1ActiveStepView.h"
#import "ORK1CustomStepView_Internal.h"
#import "ORK1ProgressView.h"
#import "ORK1VerticalContainerView_Internal.h"

#import "ORK1ActiveStepViewController_Internal.h"
#import "ORK1StepViewController_Internal.h"
#import "ORK1PedometerRecorder.h"

#import "ORK1Step_Private.h"
#import "ORK1WalkingTaskStep.h"

#import "ORK1Helpers_Internal.h"
#import "ORK1Skin.h"


@interface ORK1WalkingContentView : ORK1ActiveStepCustomView {
    NSLayoutConstraint *_topConstraint;
}

@property (nonatomic, strong, readonly) ORK1ProgressView *progressView;

@end


@implementation ORK1WalkingContentView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _progressView = [ORK1ProgressView new];
        _progressView.translatesAutoresizingMaskIntoConstraints = NO;
        
#if LAYOUT_DEBUG
        self.backgroundColor = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
        _progressView.backgroundColor = [[UIColor yellowColor] colorWithAlphaComponent:0.2];
#endif
        
        [self addSubview:_progressView];
        [self setUpConstraints];
        [self updateConstraintConstantsForWindow:self.window];
    }
    return self;
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    [self updateConstraintConstantsForWindow:newWindow];
}

- (void)updateConstraintConstantsForWindow:(UIWindow *)window {
    const CGFloat CaptionBaselineToProgressTop = 100;
    const CGFloat CaptionBaselineToStepViewTop = ORK1GetMetricForWindow(ORK1ScreenMetricLearnMoreBaselineToStepViewTop, window);
    _topConstraint.constant = CaptionBaselineToProgressTop - CaptionBaselineToStepViewTop;
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_progressView);
    [constraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_progressView]-(>=0)-|"
                                             options:NSLayoutFormatAlignAllCenterX
                                             metrics:nil
                                               views:views]];
    _topConstraint = [NSLayoutConstraint constraintWithItem:_progressView
                                                  attribute:NSLayoutAttributeTop
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self
                                                  attribute:NSLayoutAttributeTop
                                                 multiplier:1.0
                                                   constant:0.0]; // constant will be set in updateConstraintConstantsForWindow:
    [constraints addObject:_topConstraint];
   
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_progressView
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1.0
                                                          constant:0.0]];
    
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)updateConstraints {
    [self updateConstraintConstantsForWindow:self.window];
    [super updateConstraints];
}

@end


@interface ORK1WalkingTaskStepViewController () <ORK1PedometerRecorderDelegate> {
    NSInteger _intendedSteps;
    ORK1WalkingContentView *_contentView;
}

@end


@implementation ORK1WalkingTaskStepViewController

- (instancetype)initWithStep:(ORK1Step *)step {
    self = [super initWithStep:step];
    if (self) {
        self.suspendIfInactive = NO;
    }
    return self;
}

- (ORK1WalkingTaskStep *)walkingTaskStep {
    NSAssert(self.step == nil || [self.step isKindOfClass:[ORK1WalkingTaskStep class]], @"Expected step subclass of ORK1WalkingTaskStep");
    return (ORK1WalkingTaskStep *)self.step;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _contentView = [ORK1WalkingContentView new];
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.activeStepView.activeCustomView = _contentView;
}

- (void)stepDidChange {
    [super stepDidChange];
    
    _intendedSteps = [[self walkingTaskStep] numberOfStepsPerLeg];
}

- (void)pedometerRecorderDidUpdate:(ORK1PedometerRecorder *)pedometerRecorder {
    NSInteger numberOfSteps = [pedometerRecorder totalNumberOfSteps];
    ORK1_Log_Debug(@"Steps: %lld", (long long)numberOfSteps);
    if (_intendedSteps > 0 && numberOfSteps >= _intendedSteps) {
        [self finish];
    }
}

@end