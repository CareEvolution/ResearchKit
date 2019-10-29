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


#import "ORKSkin.h"

#import "ORKHelpers_Internal.h"


NSString *const ORKLegacySignatureColorKey = @"ORKSignatureColorKey";
NSString *const ORKLegacyBackgroundColorKey = @"ORKBackgroundColorKey";
NSString *const ORKLegacyToolBarTintColorKey = @"ORKToolBarTintColorKey";
NSString *const ORKLegacyLightTintColorKey = @"ORKLightTintColorKey";
NSString *const ORKLegacyDarkTintColorKey = @"ORKDarkTintColorKey";
NSString *const ORKLegacyCaptionTextColorKey = @"ORKCaptionTextColorKey";
NSString *const ORKLegacyBlueHighlightColorKey = @"ORKBlueHighlightColorKey";
NSString *const ORKLegacyChartDefaultTextColorKey = @"ORKChartDefaultTextColorKey";
NSString *const ORKLegacyGraphAxisColorKey = @"ORKGraphAxisColorKey";
NSString *const ORKLegacyGraphAxisTitleColorKey = @"ORKGraphAxisTitleColorKey";
NSString *const ORKLegacyGraphReferenceLineColorKey = @"ORKGraphReferenceLineColorKey";
NSString *const ORKLegacyGraphScrubberLineColorKey = @"ORKGraphScrubberLineColorKey";
NSString *const ORKLegacyGraphScrubberThumbColorKey = @"ORKGraphScrubberThumbColorKey";
NSString *const ORKLegacyAuxiliaryImageTintColorKey = @"ORKAuxiliaryImageTintColorKey";

@implementation UIColor (ORKLegacyColor)

#define ORKLegacyCachedColorMethod(m, r, g, b, a) \
+ (UIColor *)m { \
    static UIColor *c##m = nil; \
    static dispatch_once_t onceToken##m; \
    dispatch_once(&onceToken##m, ^{ \
        c##m = [[UIColor alloc] initWithRed:r green:g blue:b alpha:a]; \
    }); \
    return c##m; \
}

ORKLegacyCachedColorMethod(ork_midGrayTintColor, 0.0 / 255.0, 0.0 / 255.0, 25.0 / 255.0, 0.22)
ORKLegacyCachedColorMethod(ork_redColor, 255.0 / 255.0,  59.0 / 255.0,  48.0 / 255.0, 1.0)
ORKLegacyCachedColorMethod(ork_grayColor, 142.0 / 255.0, 142.0 / 255.0, 147.0 / 255.0, 1.0)
ORKLegacyCachedColorMethod(ork_darkGrayColor, 102.0 / 255.0, 102.0 / 255.0, 102.0 / 255.0, 1.0)

#undef ORKLegacyCachedColorMethod

@end

static NSMutableDictionary *colors() {
    static NSMutableDictionary *colors = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colors = [@{
                    ORKLegacySignatureColorKey: ORKLegacyRGB(0x000000),
                    ORKLegacyBackgroundColorKey: ORKLegacyRGB(0xffffff),
                    ORKLegacyToolBarTintColorKey: ORKLegacyRGB(0xffffff),
                    ORKLegacyLightTintColorKey: ORKLegacyRGB(0xeeeeee),
                    ORKLegacyDarkTintColorKey: ORKLegacyRGB(0x888888),
                    ORKLegacyCaptionTextColorKey: ORKLegacyRGB(0xcccccc),
                    ORKLegacyBlueHighlightColorKey: [UIColor colorWithRed:0.0 green:122.0 / 255.0 blue:1.0 alpha:1.0],
                    ORKLegacyChartDefaultTextColorKey: [UIColor lightGrayColor],
                    ORKLegacyGraphAxisColorKey: [UIColor colorWithRed:217.0 / 255.0 green:217.0 / 255.0 blue:217.0 / 255.0 alpha:1.0],
                    ORKLegacyGraphAxisTitleColorKey: [UIColor colorWithRed:142.0 / 255.0 green:142.0 / 255.0 blue:147.0 / 255.0 alpha:1.0],
                    ORKLegacyGraphReferenceLineColorKey: [UIColor colorWithRed:225.0 / 255.0 green:225.0 / 255.0 blue:229.0 / 255.0 alpha:1.0],
                    ORKLegacyGraphScrubberLineColorKey: [UIColor grayColor],
                    ORKLegacyGraphScrubberThumbColorKey: [UIColor colorWithWhite:1.0 alpha:1.0],
                    ORKLegacyAuxiliaryImageTintColorKey: [UIColor colorWithRed:228.0 / 255.0 green:233.0 / 255.0 blue:235.0 / 255.0 alpha:1.0],
                    } mutableCopy];
    });
    return colors;
}

UIColor *ORKLegacyColor(NSString *colorKey) {
    return colors()[colorKey];
}

void ORKLegacyColorSetColorForKey(NSString *key, UIColor *color) {
    NSMutableDictionary *d = colors();
    d[key] = color;
}

const CGSize ORKLegacyiPhone4ScreenSize = (CGSize){320, 480};
const CGSize ORKLegacyiPhone5ScreenSize = (CGSize){320, 568};
const CGSize ORKLegacyiPhone6ScreenSize = (CGSize){375, 667};
const CGSize ORKLegacyiPhone6PlusScreenSize = (CGSize){414, 736};
const CGSize ORKLegacyiPhoneXScreenSize = (CGSize){375, 812};
const CGSize ORKLegacyiPadScreenSize = (CGSize){768, 1024};
const CGSize ORKLegacyiPad12_9ScreenSize = (CGSize){1024, 1366};

ORKLegacyScreenType ORKLegacyGetVerticalScreenTypeForBounds(CGRect bounds) {
    ORKLegacyScreenType screenType = ORKLegacyScreenTypeiPhone6;
    CGFloat maximumDimension = MAX(bounds.size.width, bounds.size.height);
    if (maximumDimension < ORKLegacyiPhone4ScreenSize.height + 1) {
        screenType = ORKLegacyScreenTypeiPhone4;
    } else if (maximumDimension < ORKLegacyiPhone5ScreenSize.height + 1) {
        screenType = ORKLegacyScreenTypeiPhone5;
    } else if (maximumDimension < ORKLegacyiPhone6ScreenSize.height + 1) {
        screenType = ORKLegacyScreenTypeiPhone6;
    } else if (maximumDimension < ORKLegacyiPhone6PlusScreenSize.height + 1) {
        screenType = ORKLegacyScreenTypeiPhone6Plus;
    } else if (maximumDimension < ORKLegacyiPhoneXScreenSize.height + 1) {
        screenType = ORKLegacyScreenTypeiPhoneX;
    } else if (maximumDimension < ORKLegacyiPadScreenSize.height + 1) {
        screenType = ORKLegacyScreenTypeiPad;
    } else {
        screenType = ORKLegacyScreenTypeiPad12_9;
    }
    return screenType;
}

ORKLegacyScreenType ORKLegacyGetHorizontalScreenTypeForBounds(CGRect bounds) {
    ORKLegacyScreenType screenType = ORKLegacyScreenTypeiPhone6;
    CGFloat minimumDimension = MIN(bounds.size.width, bounds.size.height);
    if (minimumDimension < ORKLegacyiPhone4ScreenSize.width + 1) {
        screenType = ORKLegacyScreenTypeiPhone4;
    } else if (minimumDimension < ORKLegacyiPhone5ScreenSize.width + 1) {
        screenType = ORKLegacyScreenTypeiPhone5;
    } else if (minimumDimension < ORKLegacyiPhone6ScreenSize.width + 1) {
        screenType = ORKLegacyScreenTypeiPhone6;
    }  else if (minimumDimension < ORKLegacyiPhoneXScreenSize.width + 1) {
        screenType = ORKLegacyScreenTypeiPhoneX;
    } else if (minimumDimension < ORKLegacyiPhone6PlusScreenSize.width + 1) {
        screenType = ORKLegacyScreenTypeiPhone6Plus;
    } else if (minimumDimension < ORKLegacyiPadScreenSize.width + 1) {
        screenType = ORKLegacyScreenTypeiPad;
    } else {
        screenType = ORKLegacyScreenTypeiPad12_9;
    }
    return screenType;
}

UIWindow *ORKLegacyDefaultWindowIfWindowIsNil(UIWindow *window) {
    if (!window) {
        // Use this method instead of UIApplication's keyWindow or UIApplication's delegate's window
        // because we may need the window before the keyWindow is set (e.g., if a view controller
        // loads programmatically on the app delegate to be assigned as the root view controller)
        window = [UIApplication sharedApplication].windows.firstObject;
    }
    return window;
}

ORKLegacyScreenType ORKLegacyGetVerticalScreenTypeForWindow(UIWindow *window) {
    window = ORKLegacyDefaultWindowIfWindowIsNil(window);
    return ORKLegacyGetVerticalScreenTypeForBounds(window.bounds);
}

ORKLegacyScreenType ORKLegacyGetHorizontalScreenTypeForWindow(UIWindow *window) {
    window = ORKLegacyDefaultWindowIfWindowIsNil(window);
    return ORKLegacyGetHorizontalScreenTypeForBounds(window.bounds);
}

ORKLegacyScreenType ORKLegacyGetScreenTypeForScreen(UIScreen *screen) {
    ORKLegacyScreenType screenType = ORKLegacyScreenTypeiPhone6;
    if (screen == [UIScreen mainScreen]) {
        screenType = ORKLegacyGetVerticalScreenTypeForBounds(screen.bounds);
    }
    return screenType;
}

const CGFloat ORKLegacyScreenMetricMaxDimension = 10000.0;

CGFloat ORKLegacyGetMetricForScreenType(ORKLegacyScreenMetric metric, ORKLegacyScreenType screenType) {
    static  const CGFloat metrics[ORKLegacyScreenMetric_COUNT][ORKLegacyScreenType_COUNT] = {
        //   iPhoneX, iPhone 6+,  iPhone 6,  iPhone 5,  iPhone 4,      iPad  iPad 12.9
        {        128,       128,       128,       100,       100,       218,       218},      // ORKLegacyScreenMetricTopToCaptionBaseline
        {         35,        35,        35,        32,        24,        35,        35},      // ORKLegacyScreenMetricFontSizeHeadline
        {         38,        38,        38,        32,        28,        38,        38},      // ORKLegacyScreenMetricMaxFontSizeHeadline
        {         30,        30,        30,        30,        24,        30,        30},      // ORKLegacyScreenMetricFontSizeSurveyHeadline
        {         32,        32,        32,        32,        28,        32,        32},      // ORKLegacyScreenMetricMaxFontSizeSurveyHeadline
        {         17,        17,        17,        17,        16,        17,        17},      // ORKLegacyScreenMetricFontSizeSubheadline
        {         12,        12,        12,        12,        11,        12,        12},      // ORKLegacyScreenMetricFontSizeFootnote
        {         62,        62,        62,        51,        51,        62,        62},      // ORKLegacyScreenMetricCaptionBaselineToFitnessTimerTop
        {         62,        62,        62,        43,        43,        62,        62},      // ORKLegacyScreenMetricCaptionBaselineToTappingLabelTop
        {         36,        36,        36,        32,        32,        36,        36},      // ORKLegacyScreenMetricCaptionBaselineToInstructionBaseline
        {         30,        30,        30,        28,        24,        30,        30},      // ORKLegacyScreenMetricInstructionBaselineToLearnMoreBaseline
        {         44,        44,        44,        20,        14,        44,        44},      // ORKLegacyScreenMetricLearnMoreBaselineToStepViewTop
        {         40,        40,        40,        30,        14,        40,        40},      // ORKLegacyScreenMetricLearnMoreBaselineToStepViewTopWithNoLearnMore
        {         36,        36,        36,        20,        12,        36,        36},      // ORKLegacyScreenMetricContinueButtonTopMargin
        {         40,        40,        40,        20,        12,        40,        40},      // ORKLegacyScreenMetricContinueButtonTopMarginForIntroStep
        {          0,         0,         0,         0,         0,        80,       170},      // ORKLegacyScreenMetricTopToIllustration
        {         44,        44,        44,        40,        40,        44,        44},      // ORKLegacyScreenMetricIllustrationToCaptionBaseline
        {        198,       198,       198,       194,       152,       297,       297},      // ORKLegacyScreenMetricIllustrationHeight
        {        300,       300,       300,       176,       152,       300,       300},      // ORKLegacyScreenMetricInstructionImageHeight
        {         44,        44,        44,        44,        44,        44,        44},      // ORKLegacyScreenMetricContinueButtonHeightRegular
        {         44,        44,        32,        32,        32,        44,        44},      // ORKLegacyScreenMetricContinueButtonHeightCompact
        {        150,       150,       150,       146,       146,       150,       150},      // ORKLegacyScreenMetricContinueButtonWidth
        {        162,       162,       162,       120,       116,       240,       240},      // ORKLegacyScreenMetricMinimumStepHeaderHeightForMemoryGame
        {        162,       162,       162,       120,       116,       240,       240},      // ORKLegacyScreenMetricMinimumStepHeaderHeightForTowerOfHanoiPuzzle
        {         60,        60,        60,        60,        44,        60,        60},      // ORKLegacyScreenMetricTableCellDefaultHeight
        {         55,        55,        55,        55,        44,        55,        55},      // ORKLegacyScreenMetricTextFieldCellHeight
        {         36,        36,        36,        36,        26,        36,        36},      // ORKLegacyScreenMetricChoiceCellFirstBaselineOffsetFromTop,
        {         24,        24,        24,        24,        18,        24,        24},      // ORKLegacyScreenMetricChoiceCellLastBaselineToBottom,
        {         24,        24,        24,        24,        24,        24,        24},      // ORKLegacyScreenMetricChoiceCellLabelLastBaselineToLabelFirstBaseline,
        {         30,        30,        30,        20,        20,        30,        30},      // ORKLegacyScreenMetricLearnMoreButtonSideMargin
        {         10,        10,        10,         0,         0,        10,        10},      // ORKLegacyScreenMetricHeadlineSideMargin
        {         44,        44,        44,        44,        44,        44,        44},      // ORKLegacyScreenMetricToolbarHeight
        {        350,       322,       274,       217,       217,       446,       446},      // ORKLegacyScreenMetricVerticalScaleHeight
        {        208,       208,       208,       208,       198,       256,       256},      // ORKLegacyScreenMetricSignatureViewHeight
        {        324,       384,       324,       304,       304,       384,       384},      // ORKLegacyScreenMetricPSATKeyboardViewWidth
        {        197,       197,       167,       157,       157,       197,       197},      // ORKLegacyScreenMetricPSATKeyboardViewHeight
        {        238,       238,       238,       150,        90,       238,       238},      // ORKLegacyScreenMetricLocationQuestionMapHeight
        {         40,        40,        40,        20,        14,        40,        40},      // ORKLegacyScreenMetricTopToIconImageViewTop
        {         44,        44,        44,        40,        40,        80,        80},      // ORKLegacyScreenMetricIconImageViewToCaptionBaseline
        {         30,        30,        30,        26,        22,        30,        30},      // ORKLegacyScreenMetricVerificationTextBaselineToResendButtonBaseline
    };
    return metrics[metric][screenType];
}

CGFloat ORKLegacyGetMetricForWindow(ORKLegacyScreenMetric metric, UIWindow *window) {
    CGFloat metricValue = 0;
    switch (metric) {
        case ORKLegacyScreenMetricContinueButtonWidth:
        case ORKLegacyScreenMetricHeadlineSideMargin:
        case ORKLegacyScreenMetricLearnMoreButtonSideMargin:
            metricValue = ORKLegacyGetMetricForScreenType(metric, ORKLegacyGetHorizontalScreenTypeForWindow(window));
            break;
            
        default:
            metricValue = ORKLegacyGetMetricForScreenType(metric, ORKLegacyGetVerticalScreenTypeForWindow(window));
            break;
    }
    
    return metricValue;
}

const CGFloat ORKLegacyLayoutMarginWidthRegularBezel = 15.0;
const CGFloat ORKLegacyLayoutMarginWidthThinBezelRegular = 20.0;
const CGFloat ORKLegacyLayoutMarginWidthiPad = 115.0;

CGFloat ORKLegacyStandardLeftTableViewCellMarginForWindow(UIWindow *window) {
    CGFloat margin = 0;
    switch (ORKLegacyGetHorizontalScreenTypeForWindow(window)) {
        case ORKLegacyScreenTypeiPhone4:
        case ORKLegacyScreenTypeiPhone5:
        case ORKLegacyScreenTypeiPhone6:
            margin = ORKLegacyLayoutMarginWidthRegularBezel;
            break;
        case ORKLegacyScreenTypeiPhone6Plus:
        case ORKLegacyScreenTypeiPad:
        case ORKLegacyScreenTypeiPad12_9:
        default:
            margin = ORKLegacyLayoutMarginWidthThinBezelRegular;
            break;
    }
    return margin;
}

CGFloat ORKLegacyStandardLeftMarginForTableViewCell(UITableViewCell *cell) {
    return ORKLegacyStandardLeftTableViewCellMarginForWindow(cell.window);
}

CGFloat ORKLegacyStandardHorizontalAdaptiveSizeMarginForiPadWidth(CGFloat screenSizeWidth, UIWindow *window) {
    // Use adaptive side margin, if window is wider than iPhone6 Plus.
    // Min Marign = ORKLegacyLayoutMarginWidthThinBezelRegular, Max Marign = ORKLegacyLayoutMarginWidthiPad or iPad12_9
    
    CGFloat ratio =  (window.bounds.size.width - ORKLegacyiPhone6PlusScreenSize.width) / (screenSizeWidth - ORKLegacyiPhone6PlusScreenSize.width);
    ratio = MIN(1.0, ratio);
    ratio = MAX(0.0, ratio);
    return ORKLegacyLayoutMarginWidthThinBezelRegular + (ORKLegacyLayoutMarginWidthiPad - ORKLegacyLayoutMarginWidthThinBezelRegular)*ratio;
}

CGFloat ORKLegacyStandardHorizontalMarginForWindow(UIWindow *window) {
    window = ORKLegacyDefaultWindowIfWindowIsNil(window); // need a proper window to use bounds
    CGFloat margin = 0;
    switch (ORKLegacyGetHorizontalScreenTypeForWindow(window)) {
        case ORKLegacyScreenTypeiPhone4:
        case ORKLegacyScreenTypeiPhone5:
        case ORKLegacyScreenTypeiPhone6:
        case ORKLegacyScreenTypeiPhoneX:
        case ORKLegacyScreenTypeiPhone6Plus:
        default:
            margin = ORKLegacyStandardLeftTableViewCellMarginForWindow(window);
            break;
        case ORKLegacyScreenTypeiPad:{
            margin = ORKLegacyStandardHorizontalAdaptiveSizeMarginForiPadWidth(ORKLegacyiPadScreenSize.width, window);
            break;
        }
        case ORKLegacyScreenTypeiPad12_9:{
            margin = ORKLegacyStandardHorizontalAdaptiveSizeMarginForiPadWidth(ORKLegacyiPad12_9ScreenSize.width, window);
            break;
        }
    }
    return margin;
}

CGFloat ORKLegacyStandardHorizontalMarginForView(UIView *view) {
    return ORKLegacyStandardHorizontalMarginForWindow(view.window);
}

UIEdgeInsets ORKLegacyStandardLayoutMarginsForTableViewCell(UITableViewCell *cell) {
    const CGFloat StandardVerticalTableViewCellMargin = 8.0;
    return (UIEdgeInsets){.left = ORKLegacyStandardLeftMarginForTableViewCell(cell),
                          .right = ORKLegacyStandardLeftMarginForTableViewCell(cell),
                          .bottom = StandardVerticalTableViewCellMargin,
                          .top = StandardVerticalTableViewCellMargin};
}

UIEdgeInsets ORKLegacyStandardFullScreenLayoutMarginsForView(UIView *view) {
    UIEdgeInsets layoutMargins = UIEdgeInsetsZero;
    ORKLegacyScreenType screenType = ORKLegacyGetHorizontalScreenTypeForWindow(view.window);
    if (screenType == ORKLegacyScreenTypeiPad || screenType == ORKLegacyScreenTypeiPad12_9) {
        CGFloat margin = ORKLegacyStandardHorizontalMarginForView(view);
        layoutMargins = (UIEdgeInsets){.left = margin, .right = margin };
    }
    return layoutMargins;
}

UIEdgeInsets ORKLegacyScrollIndicatorInsetsForScrollView(UIView *view) {
    UIEdgeInsets scrollIndicatorInsets = UIEdgeInsetsZero;
    ORKLegacyScreenType screenType = ORKLegacyGetHorizontalScreenTypeForWindow(view.window);
    if (screenType == ORKLegacyScreenTypeiPad || screenType == ORKLegacyScreenTypeiPad12_9) {
        CGFloat margin = ORKLegacyStandardHorizontalMarginForView(view);
        scrollIndicatorInsets = (UIEdgeInsets){.left = -margin, .right = -margin };
    }
    return scrollIndicatorInsets;
}

CGFloat ORKLegacyWidthForSignatureView(UIWindow *window) {
    window = ORKLegacyDefaultWindowIfWindowIsNil(window); // need a proper window to use bounds
    const CGSize windowSize = window.bounds.size;
    const CGFloat windowPortraitWidth = MIN(windowSize.width, windowSize.height);
    const CGFloat signatureViewWidth = windowPortraitWidth - (2 * ORKLegacyStandardHorizontalMarginForView(window) + 2 * ORKLegacyStandardLeftMarginForTableViewCell(window));
    return signatureViewWidth;
}

void ORKLegacyUpdateScrollViewBottomInset(UIScrollView *scrollView, CGFloat bottomInset) {
    UIEdgeInsets insets = scrollView.contentInset;
    if (!ORKLegacyCGFloatNearlyEqualToFloat(insets.bottom, bottomInset)) {
        CGPoint savedOffset = scrollView.contentOffset;
        
        insets.bottom = bottomInset;
        scrollView.contentInset = insets;
        
        insets = scrollView.scrollIndicatorInsets;
        insets.bottom = bottomInset;
        scrollView.scrollIndicatorInsets = insets;
        
        scrollView.contentOffset = savedOffset;
    }
}
