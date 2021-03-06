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


@import UIKit;
#import "ORK1TableViewCell.h"


NS_ASSUME_NONNULL_BEGIN

@class ORK1QuestionStep;
@class ORK1SurveyAnswerCell;

@protocol ORK1SurveyAnswerCellDelegate

@required
- (void)answerCell:(ORK1SurveyAnswerCell *)cell answerDidChangeTo:(id)answer dueUserAction:(BOOL)dueUserAction;
- (void)answerCell:(ORK1SurveyAnswerCell *)cell invalidInputAlertWithMessage:(NSString *)input;
- (void)answerCell:(ORK1SurveyAnswerCell *)cell invalidInputAlertWithTitle:(NSString *)title message:(NSString *)message;

@end


@interface ORK1SurveyAnswerCell : ORK1TableViewCell {
@protected
    id _answer;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier
                         step:(ORK1QuestionStep *)step
                       answer:(id)answer
                     delegate:(id<ORK1SurveyAnswerCellDelegate>)delegate;

@property (nonatomic, weak, nullable) ORK1QuestionStep *step;

@property (nonatomic, weak, nullable) id<ORK1SurveyAnswerCellDelegate> delegate;

@property (nonatomic, copy, nullable) id answer;

// Gives an opportunity for cells to prevent navigation if the value has not been set
- (BOOL)shouldContinue;

@end


@interface ORK1SurveyAnswerCell (ORK1SurveyAnswerCellInternal)

- (void)prepareView;

- (nullable UITextView *)textView;

+ (CGFloat)suggestedCellHeightForView:(UIView *)view;

- (NSArray *)suggestedCellHeightConstraintsForView:(UIView *)view;

- (void)ork_setAnswer:(nullable id)answer;
- (void)answerDidChange;

+ (BOOL)shouldDisplayWithSeparators;

- (void)showValidityAlertWithMessage:(nullable NSString *)text;

- (void)showValidityAlertWithTitle:(NSString *)title message:(NSString *)message;

/*
 CEV HACK - Cell should resign any firstResponder text fields to prevent a race condition where
 navigation writes result data to internal cache (_managedResults on ORK1TaskViewController)
 first, then during tear down the firstResponder is resigned to a text field rewriting the
 answer marking the original answer as isPreviousResult == YES which breaks skip navigation rules
 in certain scenarios (answer on Q1 to skip Q3 doesn't skip Q3).
 */
- (void)stepIsNavigatingForward;

// Get full width layout for some subclass cells 
+ (NSLayoutConstraint *)fullWidthLayoutConstraint:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
