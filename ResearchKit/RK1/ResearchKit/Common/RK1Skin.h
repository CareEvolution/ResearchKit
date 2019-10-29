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
#import "RK1Defines.h"


NS_ASSUME_NONNULL_BEGIN

/// Color used for toolbar
RK1_EXTERN NSString *const RK1ToolBarTintColorKey;

/// Color used for view's backgroud
RK1_EXTERN NSString *const RK1BackgroundColorKey;

/// Color used for signature
RK1_EXTERN NSString *const RK1SignatureColorKey;

/// Color used for a light-colored tint
RK1_EXTERN NSString *const RK1LightTintColorKey;

/// Color used for a dark-colored tint
RK1_EXTERN NSString *const RK1DarkTintColorKey;

/// Color used for caption text
RK1_EXTERN NSString *const RK1CaptionTextColorKey;

/// Color used for a "blue" highlight
RK1_EXTERN NSString *const RK1BlueHighlightColorKey;

/// Default color used for legend, title and text on RK1PieChartView
RK1_EXTERN NSString *const RK1ChartDefaultTextColorKey;

/// Default color used for axes of RK1GraphChartView
RK1_EXTERN NSString *const RK1GraphAxisColorKey;

/// Default color used for titles on axes of RK1GraphChartView
RK1_EXTERN NSString *const RK1GraphAxisTitleColorKey;

/// Default color used for scrubber line of RK1GraphChartView
RK1_EXTERN NSString *const RK1GraphScrubberLineColorKey;

/// Default color used for scrubber thumb of RK1GraphChartView
RK1_EXTERN NSString *const RK1GraphScrubberThumbColorKey;

/// Default color used for reference line of RK1GraphChartView
RK1_EXTERN NSString *const RK1GraphReferenceLineColorKey;

/// Default color used for auxiliary image tint of RK1InstructionStepView
RK1_EXTERN NSString *const RK1AuxiliaryImageTintColorKey;

/// Return the color for a specified RK1...ColorKey
UIColor *RK1Color(NSString *colorKey);

/// Modify the color for a specified RK1...ColorKey. (for customization)
void RK1ColorSetColorForKey(NSString *key, UIColor *color);

@interface UIColor (RK1Color)

+ (UIColor *)ork_midGrayTintColor;
+ (UIColor *)ork_redColor;
+ (UIColor *)ork_grayColor;
+ (UIColor *)ork_darkGrayColor;

@end

extern const CGFloat RK1ScreenMetricMaxDimension;

typedef NS_ENUM(NSInteger, RK1ScreenMetric) {
    RK1ScreenMetricTopToCaptionBaseline,
    RK1ScreenMetricFontSizeHeadline,
    RK1ScreenMetricMaxFontSizeHeadline,
    RK1ScreenMetricFontSizeSurveyHeadline,
    RK1ScreenMetricMaxFontSizeSurveyHeadline,
    RK1ScreenMetricFontSizeSubheadline,
    RK1ScreenMetricFontSizeFootnote,
    RK1ScreenMetricCaptionBaselineToFitnessTimerTop,
    RK1ScreenMetricCaptionBaselineToTappingLabelTop,
    RK1ScreenMetricCaptionBaselineToInstructionBaseline,
    RK1ScreenMetricInstructionBaselineToLearnMoreBaseline,
    RK1ScreenMetricLearnMoreBaselineToStepViewTop,
    RK1ScreenMetricLearnMoreBaselineToStepViewTopWithNoLearnMore,
    RK1ScreenMetricContinueButtonTopMargin,
    RK1ScreenMetricContinueButtonTopMarginForIntroStep,
    RK1ScreenMetricTopToIllustration,
    RK1ScreenMetricIllustrationToCaptionBaseline,
    RK1ScreenMetricIllustrationHeight,
    RK1ScreenMetricInstructionImageHeight,
    RK1ScreenMetricContinueButtonHeightRegular,
    RK1ScreenMetricContinueButtonHeightCompact,
    RK1ScreenMetricContinueButtonWidth,
    RK1ScreenMetricMinimumStepHeaderHeightForMemoryGame,
    RK1ScreenMetricMinimumStepHeaderHeightForTowerOfHanoiPuzzle,
    RK1ScreenMetricTableCellDefaultHeight,
    RK1ScreenMetricTextFieldCellHeight,
    RK1ScreenMetricChoiceCellFirstBaselineOffsetFromTop,
    RK1ScreenMetricChoiceCellLastBaselineToBottom,
    RK1ScreenMetricChoiceCellLabelLastBaselineToLabelFirstBaseline,
    RK1ScreenMetricLearnMoreButtonSideMargin,
    RK1ScreenMetricHeadlineSideMargin,
    RK1ScreenMetricToolbarHeight,
    RK1ScreenMetricVerticalScaleHeight,
    RK1ScreenMetricSignatureViewHeight,
    RK1ScreenMetricPSATKeyboardViewWidth,
    RK1ScreenMetricPSATKeyboardViewHeight,
    RK1ScreenMetricLocationQuestionMapHeight,
    RK1ScreenMetricTopToIconImageViewTop,
    RK1ScreenMetricIconImageViewToCaptionBaseline,
    RK1ScreenMetricVerificationTextBaselineToResendButtonBaseline,
    RK1ScreenMetric_COUNT
};

typedef NS_ENUM(NSInteger, RK1ScreenType) {
    RK1ScreenTypeiPhoneX,
    RK1ScreenTypeiPhone6Plus,
    RK1ScreenTypeiPhone6,
    RK1ScreenTypeiPhone5,
    RK1ScreenTypeiPhone4,
    RK1ScreenTypeiPad,
    RK1ScreenTypeiPad12_9,
    RK1ScreenType_COUNT
};

RK1ScreenType RK1GetVerticalScreenTypeForWindow(UIWindow * _Nullable window);
CGFloat RK1GetMetricForWindow(RK1ScreenMetric metric, UIWindow * _Nullable window);

CGFloat RK1StandardLeftMarginForTableViewCell(UIView *view);
CGFloat RK1StandardHorizontalMarginForView(UIView *view);
UIEdgeInsets RK1StandardLayoutMarginsForTableViewCell(UIView *view);
UIEdgeInsets RK1StandardFullScreenLayoutMarginsForView(UIView *view);
UIEdgeInsets RK1ScrollIndicatorInsetsForScrollView(UIView *view);
CGFloat RK1WidthForSignatureView(UIWindow * _Nullable window);

void RK1UpdateScrollViewBottomInset(UIScrollView *scrollView, CGFloat bottomInset);


NS_ASSUME_NONNULL_END
