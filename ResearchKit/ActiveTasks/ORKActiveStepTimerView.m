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


#import "ORKActiveStepTimerView.h"

#import "ORKActiveStepTimer.h"
#import "ORKCountdownLabel.h"
#import "ORKSurveyAnswerCellForText.h"
#import "ORKSurveyAnswerCellForNumber.h"
#import "ORKTextButton.h"
#import "ORKVoiceEngine.h"

#import "ORKActiveStepViewController_Internal.h"
#import "ORKStepViewController_Internal.h"

#import "ORKActiveStep_Internal.h"

#import "ORKHelpers_Internal.h"
#import "ORKSkin.h"


@implementation ORK1ActiveStepTimerView {
    BOOL _started;
    BOOL _registeredForNotifications;
    
    NSLayoutConstraint *_countDownLabelBottomToStartTimerButtonTopConstraint;
    NSLayoutConstraint *_countDownLabelZeroHeightConstraint;
    NSLayoutConstraint *_startTimerButtonZeroHeightConstraint;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Count Down
        {
            _countDownLabel = [ORK1CountdownLabel new];
            _countDownLabel.textAlignment = NSTextAlignmentCenter;
            _countDownLabel.text = @" ";
            
            [self addSubview:_countDownLabel];
        }
        // Count down start button
        {
            _startTimerButton = [ORK1TextButton new];
            [_startTimerButton setTitle:ORK1LocalizedString(@"BUTTON_START_TIMER", nil) forState:UIControlStateNormal];
            [_startTimerButton addTarget:self action:@selector(startTimerButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            _startTimerButton.exclusiveTouch = YES;
            
            [self addSubview:_startTimerButton];
        }
        
        _countDownLabel.accessibilityTraits |= UIAccessibilityTraitUpdatesFrequently;
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [self setUpConstraints];
    }
    return self;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    ORK1ActiveStepViewController *viewController = self.activeStepViewController;
    if (viewController) {
        [self updateDisplay:viewController];
    }
}

- (void)setRegisteredForNotifications:(BOOL)registered {
    if (registered == _registeredForNotifications) {
        return;
    }

    registered = _registeredForNotifications;
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    if (registered) {
        [notificationCenter addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    } else {
        [notificationCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    }
}

- (void)didMoveToWindow {
    [self setRegisteredForNotifications:(self.window != nil)];
}

- (void)setStep:(ORK1ActiveStep *)step {
    _step = step;
    _countDownLabel.hidden = !(_step.hasCountDown);
    BOOL hasTimerButton = (_step.hasCountDown && _step.shouldStartTimerAutomatically == NO);
    _startTimerButton.hidden = !hasTimerButton;
    _startTimerButton.alpha = 1;
    
    [_countDownLabel setCountDownValue:(NSInteger)[_step stepDuration]];
    
    [self setNeedsUpdateConstraints];
}

- (void)startTimerButtonTapped:(id)sender {
    [self.activeStepViewController start];
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, _countDownLabel);
}

- (void)updateDisplay:(ORK1ActiveStepViewController *)viewController {
    NSInteger countDownValue = (NSInteger)round(viewController.timeRemaining);
    [_countDownLabel setCountDownValue:countDownValue];
}

- (void)resetStep:(ORK1ActiveStepViewController *)viewController {
    self.step = (ORK1ActiveStep *)viewController.step;
}

- (void)startStep:(ORK1ActiveStepViewController *)viewController {
    _startTimerButton.alpha = 0;
}

- (void)suspendStep:(ORK1ActiveStepViewController *)viewController {
}

- (void)resumeStep:(ORK1ActiveStepViewController *)viewController {
    self.step = (ORK1ActiveStep *)viewController.step;
    if ([viewController timerActive]) {
        _startTimerButton.alpha = 0;
        [self updateDisplay:viewController];
    }
}

- (void)finishStep:(ORK1ActiveStepViewController *)viewController {
}

static const CGFloat CountDownLabelToButtonMargin = 2.0;

- (void)setUpConstraints {
    NSDictionary *views = NSDictionaryOfVariableBindings(_countDownLabel, _startTimerButton);
    ORK1EnableAutoLayoutForViews(views.allValues);
    
    NSMutableArray *constraints = [NSMutableArray new];
    
    for (UIView *view in views.allValues) {
        [constraints addObject:[NSLayoutConstraint constraintWithItem:view
                                                            attribute:NSLayoutAttributeWidth
                                                            relatedBy:NSLayoutRelationLessThanOrEqual
                                                               toItem:self
                                                            attribute:NSLayoutAttributeWidth
                                                           multiplier:1.0
                                                             constant:0.0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:view
                                                            attribute:NSLayoutAttributeCenterX
                                                            relatedBy:NSLayoutRelationLessThanOrEqual
                                                               toItem:self
                                                            attribute:NSLayoutAttributeCenterX
                                                           multiplier:1.0
                                                             constant:0.0]];
    }
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self
                                                        attribute:NSLayoutAttributeTop
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_countDownLabel
                                                        attribute:NSLayoutAttributeTop
                                                       multiplier:1.0
                                                         constant:0.0]];

    _countDownLabelBottomToStartTimerButtonTopConstraint = [NSLayoutConstraint constraintWithItem:_startTimerButton
                                                                                        attribute:NSLayoutAttributeTop
                                                                                        relatedBy:NSLayoutRelationEqual
                                                                                           toItem:_countDownLabel
                                                                                        attribute:NSLayoutAttributeBottom
                                                                                       multiplier:1.0
                                                                                         constant:CountDownLabelToButtonMargin];
    [constraints addObject:_countDownLabelBottomToStartTimerButtonTopConstraint];

    [constraints addObject:[NSLayoutConstraint constraintWithItem:_startTimerButton
                                                        attribute:NSLayoutAttributeBottom
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeBottom
                                                       multiplier:1.0
                                                         constant:0.0]];

    [NSLayoutConstraint activateConstraints:constraints];
    
    _countDownLabelZeroHeightConstraint = [NSLayoutConstraint constraintWithItem:_countDownLabel
                                                                   attribute:NSLayoutAttributeHeight
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:nil
                                                                   attribute:NSLayoutAttributeNotAnAttribute
                                                                  multiplier:1.0
                                                                    constant:0.0];
    _startTimerButtonZeroHeightConstraint = [NSLayoutConstraint constraintWithItem:_startTimerButton
                                                                         attribute:NSLayoutAttributeHeight
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:nil
                                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                                        multiplier:1.0
                                                                          constant:0.0];
    [self setNeedsUpdateConstraints];
}

- (void)updateConstraints {
    _countDownLabelZeroHeightConstraint.active = _countDownLabel.hidden;
    _startTimerButtonZeroHeightConstraint.active = (_countDownLabel.hidden || _startTimerButton.hidden);
    _countDownLabelBottomToStartTimerButtonTopConstraint.constant =
    (_countDownLabel.hidden || _startTimerButton.hidden) ? 0.0 : CountDownLabelToButtonMargin;
    [super updateConstraints];
}

@end
