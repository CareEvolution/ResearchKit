/*
 Copyright (c) 2017, Apple Inc. All rights reserved.
 
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


#import "ORKStroopStepViewController.h"
#import "ORKActiveStepView.h"
#import "ORKStroopContentView.h"
#import "ORKActiveStepViewController_Internal.h"
#import "ORKStepViewController_Internal.h"
#import "ORKStroopResult.h"
#import "ORKResult_Private.h"
#import "ORKCollectionResult_Private.h"
#import "ORKStroopStep.h"
#import "ORKHelpers_Internal.h"
#import "ORKBorderedButton.h"
#import "ORKNavigationContainerView.h"
#import "ORKTaskViewController_Private.h"

@interface ORKStroopStepViewController ()

@property (nonatomic, strong) ORKStroopContentView *stroopContentView;
@property (nonatomic) NSUInteger questionNumber;
@property (nonatomic, strong) ORKStroopTest *currentTest;

@end


@implementation ORKStroopStepViewController {
    NSArray<ORKStroopColor *> *_allColors;
    
    NSTimer *_nextQuestionTimer;
    
    NSTimer *_timeoutTimer;
    
    NSMutableArray *_results;
    NSTimeInterval _startTime;
    NSTimeInterval _endTime;
}

- (instancetype)initWithStep:(ORKStep *)step {
    self = [super initWithStep:step];
    
    if (self) {
        self.suspendIfInactive = YES;
    }
    
    return self;
}

- (ORKStroopStep *)stroopStep {
    return (ORKStroopStep *)self.step;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _results = [NSMutableArray new];
    _allColors = @[[[ORKStroopColor alloc] initWithIdentifier:ORKStroopColorIdentifierRed],
                   [[ORKStroopColor alloc] initWithIdentifier:ORKStroopColorIdentifierGreen],
                   [[ORKStroopColor alloc] initWithIdentifier:ORKStroopColorIdentifierBlue],
                   [[ORKStroopColor alloc] initWithIdentifier:ORKStroopColorIdentifierYellow]];

    self.questionNumber = 0;
    _stroopContentView = [ORKStroopContentView new];
    [_stroopContentView setUseGridLayoutForButtons: [self stroopStep].useGridLayoutForButtons];

    if ([self stroopStep].useGridLayoutForButtons) {
        [self.navigationFooterView setHidden:true];

        _timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:30
            target:self
          selector:@selector(timeOut)
          userInfo:nil
           repeats:NO];
    }
    
    self.activeStepView.activeCustomView = _stroopContentView;
    self.activeStepView.stepViewFillsAvailableSpace = YES;
    
    [self.stroopContentView.RButton addTarget:self
                                       action:@selector(buttonPressed:)
                             forControlEvents:UIControlEventTouchUpInside];
    [self.stroopContentView.GButton addTarget:self
                                       action:@selector(buttonPressed:)
                             forControlEvents:UIControlEventTouchUpInside];
    [self.stroopContentView.BButton addTarget:self
                                       action:@selector(buttonPressed:)
                             forControlEvents:UIControlEventTouchUpInside];
    [self.stroopContentView.YButton addTarget:self
                                       action:@selector(buttonPressed:)
                             forControlEvents:UIControlEventTouchUpInside];
}

- (void)buttonPressed:(id)sender {
    NSString *colorLabelText = self.stroopContentView.colorLabelAttributedText.string;
    if (![colorLabelText isEqualToString:@" "]) {
        [self setButtonsDisabled];
        if (sender == self.stroopContentView.RButton) {
            [self createResultWithSelectedColorIdentifier:ORKStroopColorIdentifierRed];
        }
        else if (sender == self.stroopContentView.GButton) {
            [self createResultWithSelectedColorIdentifier:ORKStroopColorIdentifierGreen];
        }
        else if (sender == self.stroopContentView.BButton) {
            [self createResultWithSelectedColorIdentifier:ORKStroopColorIdentifierBlue];
        }
        else if (sender == self.stroopContentView.YButton) {
            [self createResultWithSelectedColorIdentifier:ORKStroopColorIdentifierYellow];
        }
        self.stroopContentView.colorLabelAttributedText = [[NSAttributedString alloc] initWithString:@" "];
        _nextQuestionTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                             target:self
                                                           selector:@selector(startNextQuestionOrFinish)
                                                           userInfo:nil
                                                            repeats:NO];
        
        if ([self stroopStep].useGridLayoutForButtons) {

            [_timeoutTimer invalidate];
                    _timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:30
                          target:self
                        selector:@selector(timeOut)
                        userInfo:nil
                         repeats:NO];
        }
    }
}

- (void)timeOut {
    
    UIAlertController* controller = [UIAlertController alertControllerWithTitle: ORKLocalizedString(@"TIME_OUT_TILE", nil)
                                                                        message: ORKLocalizedString(@"TIME_OUT_BODY", nil) preferredStyle:UIAlertControllerStyleAlert];
    [controller addAction:[UIAlertAction actionWithTitle: ORKLocalizedString(@"TIME_OUT_RESTART_ACTION", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[self taskViewController] flipToFirstPage];
    }]];
    
    [controller addAction:[UIAlertAction actionWithTitle: ORKLocalizedString(@"TIME_OUT_END_ACTION", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        ORKStrongTypeOf(self.taskViewController.delegate) strongDelegate = self.taskViewController.delegate;
        if ([strongDelegate respondsToSelector:@selector(taskViewController:didFinishWithReason:error:)]) {
            [strongDelegate taskViewController:self.taskViewController didFinishWithReason:ORKTaskViewControllerFinishReasonDiscarded error:nil];
        }
    }]];

    [self presentViewController:controller animated:true completion:nil];
}

- (void)startNextQuestionTimer {
    _nextQuestionTimer = [NSTimer scheduledTimerWithTimeInterval:0.3
                                                         target:self
                                                       selector:@selector(startNextQuestionOrFinish)
                                                       userInfo:nil
                                                        repeats:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self start];
}

- (void)stepDidFinish {
    [_timeoutTimer invalidate];
    [super stepDidFinish];
    [self.stroopContentView finishStep:self];
    [self goForward];
}

- (ORKStepResult *)result {
    ORKStepResult *stepResult = [super result];
    if (_results) {
         stepResult.results = [_results copy];
    }
    return stepResult;
}

- (void)start {
    [super start];
    [self startQuestion];
}


#pragma mark - ORKResult

- (void)createResultWithSelectedColorIdentifier:(NSString *)colorIdentifier {
    ORKStroopResult *stroopResult = [[ORKStroopResult alloc] initWithIdentifier:self.step.identifier];
    stroopResult.startTime = _startTime;
    stroopResult.endTime =  [NSProcessInfo processInfo].systemUptime;
    stroopResult.color = self.currentTest.color.title;
    stroopResult.text = self.currentTest.text.title;
    stroopResult.colorSelected = colorIdentifier;
    switch (self.currentTest.stroopStyle) {
        case ORKStroopStyleBox:
            stroopResult.stroopStyle = @"box";
            break;
        case ORKStroopStyleBlackText:
        case ORKStroopStyleColoredText:
            stroopResult.stroopStyle = @"text";
            break;
        case ORKStroopStyleColoredTextRandomlyUnderlined:
            stroopResult.stroopStyle = @"text-underlined";
            break;
        default:
            break;
    }
    [_results addObject:stroopResult];
}

- (void)startNextQuestionOrFinish {
    self.questionNumber = self.questionNumber + 1;
    NSInteger numberOfAttempts = ([self stroopStep].nonRandomizedTests.count > 0) ? [self stroopStep].nonRandomizedTests.count : [self stroopStep].numberOfAttempts;
    if (self.questionNumber == numberOfAttempts) {
        [self finish];
    } else {
        [self startQuestion];
    }
}

- (void)startQuestion {
    if ([self stroopStep].nonRandomizedTests.count > 0) {
        self.currentTest = [self stroopStep].nonRandomizedTests[self.questionNumber];
    } else {
        self.currentTest = [self randomizeTest];
    }
    [self drawTest:self.currentTest];
    [self setButtonsEnabled];
    _startTime = [NSProcessInfo processInfo].systemUptime;
}

- (ORKStroopTest *)randomizeTest {
    ORKStroopTest *randomizedTest = [[ORKStroopTest alloc] init];
    ORKStroopStep *stroopStep = [self stroopStep];
    switch (stroopStep.stroopStyle) {
        case ORKStroopStyleBox:
            randomizedTest.stroopStyle = ORKStroopStyleBox;
            randomizedTest.color = _allColors[arc4random_uniform((uint32_t)_allColors.count)];
            randomizedTest.text = randomizedTest.color;
            break;
        case ORKStroopStyleBlackText:
            randomizedTest.stroopStyle = ORKStroopStyleBlackText;
            randomizedTest.color = [[ORKStroopColor alloc] initWithIdentifier:ORKStroopColorIdentifierBlack];
            randomizedTest.text = _allColors[arc4random_uniform((uint32_t)_allColors.count)];
        case ORKStroopStyleColoredText:
            randomizedTest.stroopStyle = ORKStroopStyleColoredText;
            randomizedTest.color = _allColors[arc4random_uniform((uint32_t)_allColors.count)];
            if ([self randomBoolWithTrueProbability:stroopStep.probabilityOfVisualAndColorAlignment]) {
                randomizedTest.text = randomizedTest.color;
            } else {
                NSMutableArray<ORKStroopColor *> *colorsLeft = [_allColors mutableCopy];
                [colorsLeft removeObject:randomizedTest.color];
                randomizedTest.text = colorsLeft[arc4random_uniform((uint32_t)colorsLeft.count)];
            }
        case ORKStroopStyleColoredTextRandomlyUnderlined:
            if ([self randomBoolWithTrueProbability:@(0.5)]) {
                randomizedTest.stroopStyle = ORKStroopStyleColoredTextRandomlyUnderlined;
            } else {
                randomizedTest.stroopStyle = ORKStroopStyleColoredText;
            }
            randomizedTest.color = _allColors[arc4random_uniform((uint32_t)_allColors.count)];
            if ([self randomBoolWithTrueProbability:stroopStep.probabilityOfVisualAndColorAlignment]) {
                randomizedTest.text = randomizedTest.color;
            } else {
                NSMutableArray<ORKStroopColor *> *colorsLeft = [_allColors mutableCopy];
                [colorsLeft removeObject:randomizedTest.color];
                randomizedTest.text = colorsLeft[arc4random_uniform((uint32_t)colorsLeft.count)];
            }
        default:
            break;
    }
    return randomizedTest;
}

- (void)drawTest:(ORKStroopTest *)test {
    self.stroopContentView.colorLabelAttributedText = [self attributedText:test.text.title isUnderlined:(test.stroopStyle == ORKStroopStyleColoredTextRandomlyUnderlined)];
    [self.stroopContentView setColor:test.color.color isText:(test.stroopStyle != ORKStroopStyleBox)];
}

- (BOOL)randomBoolWithTrueProbability:(NSNumber * __nonnull)trueProbability {
    const UInt32 precision = 1000;
    UInt32 random = arc4random_uniform(precision);
    return (double)random < ((double)precision * trueProbability.doubleValue);
}

- (NSAttributedString *)attributedText:(NSString *)text isUnderlined:(BOOL)isUnderlined {
    NSDictionary *attributes = isUnderlined
        ? @{NSFontAttributeName : [UIFont systemFontOfSize:60], NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)}
        : @{NSFontAttributeName : [UIFont systemFontOfSize:60]};
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (void)setButtonsDisabled {
    [self.stroopContentView.RButton setEnabled: NO];
    [self.stroopContentView.GButton setEnabled: NO];
    [self.stroopContentView.BButton setEnabled: NO];
    [self.stroopContentView.YButton setEnabled: NO];
}

- (void)setButtonsEnabled {
    [self.stroopContentView.RButton setEnabled: YES];
    [self.stroopContentView.GButton setEnabled: YES];
    [self.stroopContentView.BButton setEnabled: YES];
    [self.stroopContentView.YButton setEnabled: YES];
}

@end
