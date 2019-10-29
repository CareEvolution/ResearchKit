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


#import "RK1WalkingTaskStepViewController.h"

#import "RK1ActiveStepView.h"
#import "RK1CustomStepView_Internal.h"
#import "RK1ProgressView.h"
#import "RK1VerticalContainerView_Internal.h"

#import "RK1ActiveStepViewController_Internal.h"
#import "RK1StepViewController_Internal.h"
#import "RK1PedometerRecorder.h"

#import "RK1Step_Private.h"
#import "RK1WalkingTaskStep.h"

#import "RK1Helpers_Internal.h"
#import "RK1Skin.h"


@interface RK1WalkingContentView : RK1ActiveStepCustomView {
    NSLayoutConstraint *_topConstraint;
}

@property (nonatomic, strong, readonly) RK1ProgressView *progressView;

@end


@implementation RK1WalkingContentView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _progressView = [RK1ProgressView new];
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
    const CGFloat CaptionBaselineToStepViewTop = RK1GetMetricForWindow(RK1ScreenMetricLearnMoreBaselineToStepViewTop, window);
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


@interface RK1WalkingTaskStepViewController () <RK1PedometerRecorderDelegate> {
    NSInteger _intendedSteps;
    RK1WalkingContentView *_contentView;
}

@end


@implementation RK1WalkingTaskStepViewController

- (instancetype)initWithStep:(RK1Step *)step {
    self = [super initWithStep:step];
    if (self) {
        self.suspendIfInactive = NO;
    }
    return self;
}

- (RK1WalkingTaskStep *)walkingTaskStep {
    NSAssert(self.step == nil || [self.step isKindOfClass:[RK1WalkingTaskStep class]], @"Expected step subclass of RK1WalkingTaskStep");
    return (RK1WalkingTaskStep *)self.step;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _contentView = [RK1WalkingContentView new];
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.activeStepView.activeCustomView = _contentView;
}

- (void)stepDidChange {
    [super stepDidChange];
    
    _intendedSteps = [[self walkingTaskStep] numberOfStepsPerLeg];
}

- (void)pedometerRecorderDidUpdate:(RK1PedometerRecorder *)pedometerRecorder {
    NSInteger numberOfSteps = [pedometerRecorder totalNumberOfSteps];
    RK1_Log_Debug(@"Steps: %lld", (long long)numberOfSteps);
    if (_intendedSteps > 0 && numberOfSteps >= _intendedSteps) {
        [self finish];
    }
}

@end
