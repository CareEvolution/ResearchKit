/*
 Copyright (c) 2015, Brandon McQuilkin, Quintiles Inc.
 Copyright (c) 2015, Pavel Kanzelsberger, Quintiles Inc.
 
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


#import "ORK1SurveyAnswerCellForLocation.h"

#import "ORK1AnswerTextField.h"
#import "ORK1LocationSelectionView.h"

#import "ORK1AnswerFormat_Internal.h"
#import "ORK1QuestionStep_Internal.h"

#import "ORK1Helpers_Internal.h"
#import "ORK1Skin.h"

@import MapKit;


@interface ORK1SurveyAnswerCellForLocation () <ORK1LocationSelectionViewDelegate>
    
@end


@implementation ORK1SurveyAnswerCellForLocation {
    ORK1LocationSelectionView *_selectionView;
}

- (BOOL)becomeFirstResponder {
    return [_selectionView becomeFirstResponder];
}

- (void)setStep:(ORK1QuestionStep *)step {
    [super setStep:step];
}

+ (CGFloat)suggestedCellHeightForView:(UIView *)view {
    return [ORK1LocationSelectionView.class textFieldHeight] + [ORK1LocationSelectionView.class textFieldBottomMargin]*2 + ORK1GetMetricForWindow(ORK1ScreenMetricLocationQuestionMapHeight, nil);
}

- (void)prepareView {
    _selectionView = [[ORK1LocationSelectionView alloc] initWithFormMode:NO
                                                     useCurrentLocation:((ORK1LocationAnswerFormat *)self.step.answerFormat).useCurrentLocation
                                                          leadingMargin:self.separatorInset.left];
    _selectionView.delegate = self;
    _selectionView.tintColor = self.tintColor;
    [self addSubview:_selectionView];

    [self setUpConstraints];
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];

    NSDictionary *views = NSDictionaryOfVariableBindings(_selectionView);
    ORK1EnableAutoLayoutForViews([views allValues]);
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_selectionView]|"
                                                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                                                 metrics:nil
                                                                   views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_selectionView]|"
                                                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                                                 metrics:nil
                                                                   views:views]];
    
    NSLayoutConstraint *resistsCompressingMapConstraint = [NSLayoutConstraint constraintWithItem:_selectionView
                                                                                       attribute:NSLayoutAttributeWidth
                                                                                       relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                                          toItem:nil
                                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                                      multiplier:1.0
                                                                                        constant:20000.0];
    resistsCompressingMapConstraint.priority = UILayoutPriorityDefaultHigh;
    [constraints addObject:resistsCompressingMapConstraint];
    
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)answerDidChange {
    _selectionView.answer = self.answer;
    NSString *placeholder = self.step.placeholder ? : ORK1LocalizedString(@"PLACEHOLDER_TEXT_OR_NUMBER", nil);
    [_selectionView setPlaceholderText:placeholder];
}

- (void)locationSelectionViewDidChange:(ORK1LocationSelectionView *)view {
    [self ork_setAnswer:_selectionView.answer];
}

- (void)locationSelectionView:(ORK1LocationSelectionView *)view didFailWithErrorTitle:(NSString *)title message:(NSString *)message {
    [self showValidityAlertWithTitle:title message:message];
}

@end
