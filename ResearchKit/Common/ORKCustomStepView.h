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
#import <ResearchKitLegacy/ORKDefines.h>


NS_ASSUME_NONNULL_BEGIN

@class ORKLegacyQuestionStepCustomView;

/**
 The `ORKLegacyQuestionStepCustomViewDelegate` protocol defines the methods that a question step custom view should implement.
 
 Typically, a question step view controller (`ORKLegacyQuestionStepViewController`) is the delegate of a
 custom question step view.
 */
@protocol ORKLegacyQuestionStepCustomViewDelegate<NSObject>

- (void)customQuestionStepView:(ORKLegacyQuestionStepCustomView *)customQuestionStepView didChangeAnswer:(nullable id)answer;

@end

/**
 The `ORKLegacyQuestionStepCustomView` class is a base class for views that are used to
 display question steps (`ORKLegacyQuestionStep` objects) in a question step view controller
 (an `ORKLegacyQuestionStepViewController` object).
 
 Typically, you subclass `ORKLegacyQuestionStepCustomView` only when you need to implement a new
 answer format for the survey engine.
 
 To ensure that your subclass is allocated the display space it requires, you should implement 
 `sizeThatFits:`, or include internal constraints, or report an intrinsic content size.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyQuestionStepCustomView : UIView

/** The delegate of the question step custom view.
 
 A question step custom view should report changes in its `result` property.
 
*/
@property (nonatomic, weak, nullable) id<ORKLegacyQuestionStepCustomViewDelegate> delegate;

/// The answer to the question, which should be represented as a JSON-serializable atomic type.
@property (nonatomic, copy, nullable) id answer;

@end


@class ORKLegacySurveyAnswerCell;

ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyQuestionStepCellHolderView : ORKLegacyQuestionStepCustomView

@property (nonatomic, strong, nullable) ORKLegacySurveyAnswerCell *cell;

@end

NS_ASSUME_NONNULL_END
