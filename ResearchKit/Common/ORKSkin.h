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
#import "ORKDefines.h"


NS_ASSUME_NONNULL_BEGIN

/// Color used for toolbar
ORKLegacy_EXTERN NSString *const ORKLegacyToolBarTintColorKey;

/// Color used for view's backgroud
ORKLegacy_EXTERN NSString *const ORKLegacyBackgroundColorKey;

/// Color used for signature
ORKLegacy_EXTERN NSString *const ORKLegacySignatureColorKey;

/// Color used for a light-colored tint
ORKLegacy_EXTERN NSString *const ORKLegacyLightTintColorKey;

/// Color used for a dark-colored tint
ORKLegacy_EXTERN NSString *const ORKLegacyDarkTintColorKey;

/// Color used for caption text
ORKLegacy_EXTERN NSString *const ORKLegacyCaptionTextColorKey;

/// Color used for a "blue" highlight
ORKLegacy_EXTERN NSString *const ORKLegacyBlueHighlightColorKey;

/// Default color used for legend, title and text on ORKLegacyPieChartView
ORKLegacy_EXTERN NSString *const ORKLegacyChartDefaultTextColorKey;

/// Default color used for axes of ORKLegacyGraphChartView
ORKLegacy_EXTERN NSString *const ORKLegacyGraphAxisColorKey;

/// Default color used for titles on axes of ORKLegacyGraphChartView
ORKLegacy_EXTERN NSString *const ORKLegacyGraphAxisTitleColorKey;

/// Default color used for scrubber line of ORKLegacyGraphChartView
ORKLegacy_EXTERN NSString *const ORKLegacyGraphScrubberLineColorKey;

/// Default color used for scrubber thumb of ORKLegacyGraphChartView
ORKLegacy_EXTERN NSString *const ORKLegacyGraphScrubberThumbColorKey;

/// Default color used for reference line of ORKLegacyGraphChartView
ORKLegacy_EXTERN NSString *const ORKLegacyGraphReferenceLineColorKey;

/// Default color used for auxiliary image tint of ORKLegacyInstructionStepView
ORKLegacy_EXTERN NSString *const ORKLegacyAuxiliaryImageTintColorKey;

/// Return the color for a specified ORKLegacy...ColorKey
UIColor *ORKLegacyColor(NSString *colorKey);

/// Modify the color for a specified ORKLegacy...ColorKey. (for customization)
void ORKLegacyColorSetColorForKey(NSString *key, UIColor *color);

@interface UIColor (ORKLegacyColor)

+ (UIColor *)ork_midGrayTintColor;
+ (UIColor *)ork_redColor;
+ (UIColor *)ork_grayColor;
+ (UIColor *)ork_darkGrayColor;

@end

extern const CGFloat ORKLegacyScreenMetricMaxDimension;

typedef NS_ENUM(NSInteger, ORKLegacyScreenMetric) {
    ORKLegacyScreenMetricTopToCaptionBaseline,
    ORKLegacyScreenMetricFontSizeHeadline,
    ORKLegacyScreenMetricMaxFontSizeHeadline,
    ORKLegacyScreenMetricFontSizeSurveyHeadline,
    ORKLegacyScreenMetricMaxFontSizeSurveyHeadline,
    ORKLegacyScreenMetricFontSizeSubheadline,
    ORKLegacyScreenMetricFontSizeFootnote,
    ORKLegacyScreenMetricCaptionBaselineToFitnessTimerTop,
    ORKLegacyScreenMetricCaptionBaselineToTappingLabelTop,
    ORKLegacyScreenMetricCaptionBaselineToInstructionBaseline,
    ORKLegacyScreenMetricInstructionBaselineToLearnMoreBaseline,
    ORKLegacyScreenMetricLearnMoreBaselineToStepViewTop,
    ORKLegacyScreenMetricLearnMoreBaselineToStepViewTopWithNoLearnMore,
    ORKLegacyScreenMetricContinueButtonTopMargin,
    ORKLegacyScreenMetricContinueButtonTopMarginForIntroStep,
    ORKLegacyScreenMetricTopToIllustration,
    ORKLegacyScreenMetricIllustrationToCaptionBaseline,
    ORKLegacyScreenMetricIllustrationHeight,
    ORKLegacyScreenMetricInstructionImageHeight,
    ORKLegacyScreenMetricContinueButtonHeightRegular,
    ORKLegacyScreenMetricContinueButtonHeightCompact,
    ORKLegacyScreenMetricContinueButtonWidth,
    ORKLegacyScreenMetricMinimumStepHeaderHeightForMemoryGame,
    ORKLegacyScreenMetricMinimumStepHeaderHeightForTowerOfHanoiPuzzle,
    ORKLegacyScreenMetricTableCellDefaultHeight,
    ORKLegacyScreenMetricTextFieldCellHeight,
    ORKLegacyScreenMetricChoiceCellFirstBaselineOffsetFromTop,
    ORKLegacyScreenMetricChoiceCellLastBaselineToBottom,
    ORKLegacyScreenMetricChoiceCellLabelLastBaselineToLabelFirstBaseline,
    ORKLegacyScreenMetricLearnMoreButtonSideMargin,
    ORKLegacyScreenMetricHeadlineSideMargin,
    ORKLegacyScreenMetricToolbarHeight,
    ORKLegacyScreenMetricVerticalScaleHeight,
    ORKLegacyScreenMetricSignatureViewHeight,
    ORKLegacyScreenMetricPSATKeyboardViewWidth,
    ORKLegacyScreenMetricPSATKeyboardViewHeight,
    ORKLegacyScreenMetricLocationQuestionMapHeight,
    ORKLegacyScreenMetricTopToIconImageViewTop,
    ORKLegacyScreenMetricIconImageViewToCaptionBaseline,
    ORKLegacyScreenMetricVerificationTextBaselineToResendButtonBaseline,
    ORKLegacyScreenMetric_COUNT
};

typedef NS_ENUM(NSInteger, ORKLegacyScreenType) {
    ORKLegacyScreenTypeiPhoneX,
    ORKLegacyScreenTypeiPhone6Plus,
    ORKLegacyScreenTypeiPhone6,
    ORKLegacyScreenTypeiPhone5,
    ORKLegacyScreenTypeiPhone4,
    ORKLegacyScreenTypeiPad,
    ORKLegacyScreenTypeiPad12_9,
    ORKLegacyScreenType_COUNT
};

ORKLegacyScreenType ORKLegacyGetVerticalScreenTypeForWindow(UIWindow * _Nullable window);
CGFloat ORKLegacyGetMetricForWindow(ORKLegacyScreenMetric metric, UIWindow * _Nullable window);

CGFloat ORKLegacyStandardLeftMarginForTableViewCell(UIView *view);
CGFloat ORKLegacyStandardHorizontalMarginForView(UIView *view);
UIEdgeInsets ORKLegacyStandardLayoutMarginsForTableViewCell(UIView *view);
UIEdgeInsets ORKLegacyStandardFullScreenLayoutMarginsForView(UIView *view);
UIEdgeInsets ORKLegacyScrollIndicatorInsetsForScrollView(UIView *view);
CGFloat ORKLegacyWidthForSignatureView(UIWindow * _Nullable window);

void ORKLegacyUpdateScrollViewBottomInset(UIScrollView *scrollView, CGFloat bottomInset);


NS_ASSUME_NONNULL_END
