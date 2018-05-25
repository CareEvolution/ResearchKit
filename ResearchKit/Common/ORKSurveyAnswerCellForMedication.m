//
//  ORKSurveyAnswerCellForMedication.m
//  ResearchKit
//
//  Created by Eric Schramm on 5/24/18.
//  Copyright © 2018 researchkit.org. All rights reserved.
//

#import "ORKSurveyAnswerCellForMedication.h"

#import "ORKAnswerTextField.h"
#import "ORKLocationSelectionView.h"

#import "ORKAnswerFormat_Internal.h"
#import "ORKQuestionStep_Internal.h"

#import "ORKHelpers_Internal.h"
#import "ORKSkin.h"


@interface ORKSurveyAnswerCellForMedication () //<ORKMedicationSelectionViewDelegate>  TODO!!!

@end


@implementation ORKSurveyAnswerCellForMedication {
    //ORKLocationSelectionView *_selectionView;
}
/*
- (BOOL)becomeFirstResponder {
    return [_selectionView becomeFirstResponder];
}

- (void)setStep:(ORKQuestionStep *)step {
    [super setStep:step];
}

+ (CGFloat)suggestedCellHeightForView:(UIView *)view {
    return [ORKLocationSelectionView.class textFieldHeight] + [ORKLocationSelectionView.class textFieldBottomMargin]*2 + ORKGetMetricForWindow(ORKScreenMetricLocationQuestionMapHeight, nil);
}
*/
- (void)prepareView {
    self.textLabel.text = @"[Select a medication]";
    [super prepareView];
    /*
    _selectionView = [[ORKLocationSelectionView alloc] initWithFormMode:NO
                                                     useCurrentLocation:((ORKLocationAnswerFormat *)self.step.answerFormat).useCurrentLocation
                                                          leadingMargin:self.separatorInset.left];
    _selectionView.delegate = self;
    _selectionView.tintColor = self.tintColor;
    [self addSubview:_selectionView];
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_selectionView);
    ORKEnableAutoLayoutForViews([views allValues]);
    
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
     */
}
/*
- (void)answerDidChange {
    _selectionView.answer = self.answer;
    NSString *placeholder = self.step.placeholder ? : ORKLocalizedString(@"PLACEHOLDER_TEXT_OR_NUMBER", nil);
    [_selectionView setPlaceholderText:placeholder];
}

- (void)locationSelectionViewDidChange:(ORKLocationSelectionView *)view {
    [self ork_setAnswer:_selectionView.answer];
}

- (void)locationSelectionView:(ORKLocationSelectionView *)view didFailWithErrorTitle:(NSString *)title message:(NSString *)message {
    [self showValidityAlertWithTitle:title message:message];
}*/

@end
