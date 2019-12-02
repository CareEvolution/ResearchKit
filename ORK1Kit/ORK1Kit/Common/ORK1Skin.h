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
#import "ORK1Defines.h"


NS_ASSUME_NONNULL_BEGIN

/// Color used for toolbar
ORK1_EXTERN NSString *const ORK1ToolBarTintColorKey;

/// Color used for view's backgroud
ORK1_EXTERN NSString *const ORK1BackgroundColorKey;

/// Color used for signature
ORK1_EXTERN NSString *const ORK1SignatureColorKey;

/// Color used for a light-colored tint
ORK1_EXTERN NSString *const ORK1LightTintColorKey;

/// Color used for a dark-colored tint
ORK1_EXTERN NSString *const ORK1DarkTintColorKey;

/// Color used for caption text
ORK1_EXTERN NSString *const ORK1CaptionTextColorKey;

/// Color used for a "blue" highlight
ORK1_EXTERN NSString *const ORK1BlueHighlightColorKey;

/// Default color used for legend, title and text on ORK1PieChartView
ORK1_EXTERN NSString *const ORK1ChartDefaultTextColorKey;

/// Default color used for axes of ORK1GraphChartView
ORK1_EXTERN NSString *const ORK1GraphAxisColorKey;

/// Default color used for titles on axes of ORK1GraphChartView
ORK1_EXTERN NSString *const ORK1GraphAxisTitleColorKey;

/// Default color used for scrubber line of ORK1GraphChartView
ORK1_EXTERN NSString *const ORK1GraphScrubberLineColorKey;

/// Default color used for scrubber thumb of ORK1GraphChartView
ORK1_EXTERN NSString *const ORK1GraphScrubberThumbColorKey;

/// Default color used for reference line of ORK1GraphChartView
ORK1_EXTERN NSString *const ORK1GraphReferenceLineColorKey;

/// Default color used for auxiliary image tint of ORK1InstructionStepView
ORK1_EXTERN NSString *const ORK1AuxiliaryImageTintColorKey;

/// Return the color for a specified ORK1...ColorKey
UIColor *ORK1Color(NSString *colorKey);

/// Modify the color for a specified ORK1...ColorKey. (for customization)
void ORK1ColorSetColorForKey(NSString *key, UIColor *color);

@interface UIColor (ORK1Color)

+ (UIColor *)ork_midGrayTintColor;
+ (UIColor *)ork_redColor;
+ (UIColor *)ork_grayColor;
+ (UIColor *)ork_darkGrayColor;

@end

extern const CGFloat ORK1ScreenMetricMaxDimension;

typedef NS_ENUM(NSInteger, ORK1ScreenMetric) {
    ORK1ScreenMetricTopToCaptionBaseline,
    ORK1ScreenMetricFontSizeHeadline,
    ORK1ScreenMetricMaxFontSizeHeadline,
    ORK1ScreenMetricFontSizeSurveyHeadline,
    ORK1ScreenMetricMaxFontSizeSurveyHeadline,
    ORK1ScreenMetricFontSizeSubheadline,
    ORK1ScreenMetricFontSizeFootnote,
    ORK1ScreenMetricCaptionBaselineToFitnessTimerTop,
    ORK1ScreenMetricCaptionBaselineToTappingLabelTop,
    ORK1ScreenMetricCaptionBaselineToInstructionBaseline,
    ORK1ScreenMetricInstructionBaselineToLearnMoreBaseline,
    ORK1ScreenMetricLearnMoreBaselineToStepViewTop,
    ORK1ScreenMetricLearnMoreBaselineToStepViewTopWithNoLearnMore,
    ORK1ScreenMetricContinueButtonTopMargin,
    ORK1ScreenMetricContinueButtonTopMarginForIntroStep,
    ORK1ScreenMetricTopToIllustration,
    ORK1ScreenMetricIllustrationToCaptionBaseline,
    ORK1ScreenMetricIllustrationHeight,
    ORK1ScreenMetricInstructionImageHeight,
    ORK1ScreenMetricContinueButtonHeightRegular,
    ORK1ScreenMetricContinueButtonHeightCompact,
    ORK1ScreenMetricContinueButtonWidth,
    ORK1ScreenMetricMinimumStepHeaderHeightForMemoryGame,
    ORK1ScreenMetricMinimumStepHeaderHeightForTowerOfHanoiPuzzle,
    ORK1ScreenMetricTableCellDefaultHeight,
    ORK1ScreenMetricTextFieldCellHeight,
    ORK1ScreenMetricChoiceCellFirstBaselineOffsetFromTop,
    ORK1ScreenMetricChoiceCellLastBaselineToBottom,
    ORK1ScreenMetricChoiceCellLabelLastBaselineToLabelFirstBaseline,
    ORK1ScreenMetricLearnMoreButtonSideMargin,
    ORK1ScreenMetricHeadlineSideMargin,
    ORK1ScreenMetricToolbarHeight,
    ORK1ScreenMetricVerticalScaleHeight,
    ORK1ScreenMetricSignatureViewHeight,
    ORK1ScreenMetricPSATKeyboardViewWidth,
    ORK1ScreenMetricPSATKeyboardViewHeight,
    ORK1ScreenMetricLocationQuestionMapHeight,
    ORK1ScreenMetricTopToIconImageViewTop,
    ORK1ScreenMetricIconImageViewToCaptionBaseline,
    ORK1ScreenMetricVerificationTextBaselineToResendButtonBaseline,
    ORK1ScreenMetric_COUNT
};

typedef NS_ENUM(NSInteger, ORK1ScreenType) {
    ORK1ScreenTypeiPhoneX,
    ORK1ScreenTypeiPhone6Plus,
    ORK1ScreenTypeiPhone6,
    ORK1ScreenTypeiPhone5,
    ORK1ScreenTypeiPhone4,
    ORK1ScreenTypeiPad,
    ORK1ScreenTypeiPad12_9,
    ORK1ScreenType_COUNT
};

ORK1ScreenType ORK1GetVerticalScreenTypeForWindow(UIWindow * _Nullable window);
CGFloat ORK1GetMetricForWindow(ORK1ScreenMetric metric, UIWindow * _Nullable window);

CGFloat ORK1StandardLeftMarginForTableViewCell(UIView *view);
CGFloat ORK1StandardHorizontalMarginForView(UIView *view);
UIEdgeInsets ORK1StandardLayoutMarginsForTableViewCell(UIView *view);
UIEdgeInsets ORK1StandardFullScreenLayoutMarginsForView(UIView *view);
UIEdgeInsets ORK1ScrollIndicatorInsetsForScrollView(UIView *view);
CGFloat ORK1WidthForSignatureView(UIWindow * _Nullable window);

void ORK1UpdateScrollViewBottomInset(UIScrollView *scrollView, CGFloat bottomInset);


NS_ASSUME_NONNULL_END
