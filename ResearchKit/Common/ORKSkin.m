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


NSString *const ORK1SignatureColorKey = @"ORKSignatureColorKey";
NSString *const ORK1BackgroundColorKey = @"ORKBackgroundColorKey";
NSString *const ORK1ToolBarTintColorKey = @"ORKToolBarTintColorKey";
NSString *const ORK1LightTintColorKey = @"ORKLightTintColorKey";
NSString *const ORK1DarkTintColorKey = @"ORKDarkTintColorKey";
NSString *const ORK1CaptionTextColorKey = @"ORKCaptionTextColorKey";
NSString *const ORK1BlueHighlightColorKey = @"ORKBlueHighlightColorKey";
NSString *const ORK1ChartDefaultTextColorKey = @"ORKChartDefaultTextColorKey";
NSString *const ORK1GraphAxisColorKey = @"ORKGraphAxisColorKey";
NSString *const ORK1GraphAxisTitleColorKey = @"ORKGraphAxisTitleColorKey";
NSString *const ORK1GraphReferenceLineColorKey = @"ORKGraphReferenceLineColorKey";
NSString *const ORK1GraphScrubberLineColorKey = @"ORKGraphScrubberLineColorKey";
NSString *const ORK1GraphScrubberThumbColorKey = @"ORKGraphScrubberThumbColorKey";
NSString *const ORK1AuxiliaryImageTintColorKey = @"ORKAuxiliaryImageTintColorKey";

@implementation UIColor (ORK1Color)

#define ORK1CachedColorMethod(m, r, g, b, a) \
+ (UIColor *)m { \
    static UIColor *c##m = nil; \
    static dispatch_once_t onceToken##m; \
    dispatch_once(&onceToken##m, ^{ \
        c##m = [[UIColor alloc] initWithRed:r green:g blue:b alpha:a]; \
    }); \
    return c##m; \
}

ORK1CachedColorMethod(ork_midGrayTintColor, 0.0 / 255.0, 0.0 / 255.0, 25.0 / 255.0, 0.22)
ORK1CachedColorMethod(ork_redColor, 255.0 / 255.0,  59.0 / 255.0,  48.0 / 255.0, 1.0)
ORK1CachedColorMethod(ork_grayColor, 142.0 / 255.0, 142.0 / 255.0, 147.0 / 255.0, 1.0)
ORK1CachedColorMethod(ork_darkGrayColor, 102.0 / 255.0, 102.0 / 255.0, 102.0 / 255.0, 1.0)

#undef ORK1CachedColorMethod

@end

static NSMutableDictionary *colors() {
    static NSMutableDictionary *colors = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colors = [@{
                    ORK1SignatureColorKey: ORK1RGB(0x000000),
                    ORK1BackgroundColorKey: ORK1RGB(0xffffff),
                    ORK1ToolBarTintColorKey: ORK1RGB(0xffffff),
                    ORK1LightTintColorKey: ORK1RGB(0xeeeeee),
                    ORK1DarkTintColorKey: ORK1RGB(0x888888),
                    ORK1CaptionTextColorKey: ORK1RGB(0xcccccc),
                    ORK1BlueHighlightColorKey: [UIColor colorWithRed:0.0 green:122.0 / 255.0 blue:1.0 alpha:1.0],
                    ORK1ChartDefaultTextColorKey: [UIColor lightGrayColor],
                    ORK1GraphAxisColorKey: [UIColor colorWithRed:217.0 / 255.0 green:217.0 / 255.0 blue:217.0 / 255.0 alpha:1.0],
                    ORK1GraphAxisTitleColorKey: [UIColor colorWithRed:142.0 / 255.0 green:142.0 / 255.0 blue:147.0 / 255.0 alpha:1.0],
                    ORK1GraphReferenceLineColorKey: [UIColor colorWithRed:225.0 / 255.0 green:225.0 / 255.0 blue:229.0 / 255.0 alpha:1.0],
                    ORK1GraphScrubberLineColorKey: [UIColor grayColor],
                    ORK1GraphScrubberThumbColorKey: [UIColor colorWithWhite:1.0 alpha:1.0],
                    ORK1AuxiliaryImageTintColorKey: [UIColor colorWithRed:228.0 / 255.0 green:233.0 / 255.0 blue:235.0 / 255.0 alpha:1.0],
                    } mutableCopy];
    });
    return colors;
}

UIColor *ORK1Color(NSString *colorKey) {
    return colors()[colorKey];
}

void ORK1ColorSetColorForKey(NSString *key, UIColor *color) {
    NSMutableDictionary *d = colors();
    d[key] = color;
}

const CGSize ORK1iPhone4ScreenSize = (CGSize){320, 480};
const CGSize ORK1iPhone5ScreenSize = (CGSize){320, 568};
const CGSize ORK1iPhone6ScreenSize = (CGSize){375, 667};
const CGSize ORK1iPhone6PlusScreenSize = (CGSize){414, 736};
const CGSize ORK1iPhoneXScreenSize = (CGSize){375, 812};
const CGSize ORK1iPadScreenSize = (CGSize){768, 1024};
const CGSize ORK1iPad12_9ScreenSize = (CGSize){1024, 1366};

ORK1ScreenType ORK1GetVerticalScreenTypeForBounds(CGRect bounds) {
    ORK1ScreenType screenType = ORK1ScreenTypeiPhone6;
    CGFloat maximumDimension = MAX(bounds.size.width, bounds.size.height);
    if (maximumDimension < ORK1iPhone4ScreenSize.height + 1) {
        screenType = ORK1ScreenTypeiPhone4;
    } else if (maximumDimension < ORK1iPhone5ScreenSize.height + 1) {
        screenType = ORK1ScreenTypeiPhone5;
    } else if (maximumDimension < ORK1iPhone6ScreenSize.height + 1) {
        screenType = ORK1ScreenTypeiPhone6;
    } else if (maximumDimension < ORK1iPhone6PlusScreenSize.height + 1) {
        screenType = ORK1ScreenTypeiPhone6Plus;
    } else if (maximumDimension < ORK1iPhoneXScreenSize.height + 1) {
        screenType = ORK1ScreenTypeiPhoneX;
    } else if (maximumDimension < ORK1iPadScreenSize.height + 1) {
        screenType = ORK1ScreenTypeiPad;
    } else {
        screenType = ORK1ScreenTypeiPad12_9;
    }
    return screenType;
}

ORK1ScreenType ORK1GetHorizontalScreenTypeForBounds(CGRect bounds) {
    ORK1ScreenType screenType = ORK1ScreenTypeiPhone6;
    CGFloat minimumDimension = MIN(bounds.size.width, bounds.size.height);
    if (minimumDimension < ORK1iPhone4ScreenSize.width + 1) {
        screenType = ORK1ScreenTypeiPhone4;
    } else if (minimumDimension < ORK1iPhone5ScreenSize.width + 1) {
        screenType = ORK1ScreenTypeiPhone5;
    } else if (minimumDimension < ORK1iPhone6ScreenSize.width + 1) {
        screenType = ORK1ScreenTypeiPhone6;
    }  else if (minimumDimension < ORK1iPhoneXScreenSize.width + 1) {
        screenType = ORK1ScreenTypeiPhoneX;
    } else if (minimumDimension < ORK1iPhone6PlusScreenSize.width + 1) {
        screenType = ORK1ScreenTypeiPhone6Plus;
    } else if (minimumDimension < ORK1iPadScreenSize.width + 1) {
        screenType = ORK1ScreenTypeiPad;
    } else {
        screenType = ORK1ScreenTypeiPad12_9;
    }
    return screenType;
}

UIWindow *ORK1DefaultWindowIfWindowIsNil(UIWindow *window) {
    if (!window) {
        // Use this method instead of UIApplication's keyWindow or UIApplication's delegate's window
        // because we may need the window before the keyWindow is set (e.g., if a view controller
        // loads programmatically on the app delegate to be assigned as the root view controller)
        window = [UIApplication sharedApplication].windows.firstObject;
    }
    return window;
}

ORK1ScreenType ORK1GetVerticalScreenTypeForWindow(UIWindow *window) {
    window = ORK1DefaultWindowIfWindowIsNil(window);
    return ORK1GetVerticalScreenTypeForBounds(window.bounds);
}

ORK1ScreenType ORK1GetHorizontalScreenTypeForWindow(UIWindow *window) {
    window = ORK1DefaultWindowIfWindowIsNil(window);
    return ORK1GetHorizontalScreenTypeForBounds(window.bounds);
}

ORK1ScreenType ORK1GetScreenTypeForScreen(UIScreen *screen) {
    ORK1ScreenType screenType = ORK1ScreenTypeiPhone6;
    if (screen == [UIScreen mainScreen]) {
        screenType = ORK1GetVerticalScreenTypeForBounds(screen.bounds);
    }
    return screenType;
}

const CGFloat ORK1ScreenMetricMaxDimension = 10000.0;

CGFloat ORK1GetMetricForScreenType(ORK1ScreenMetric metric, ORK1ScreenType screenType) {
    static  const CGFloat metrics[ORK1ScreenMetric_COUNT][ORK1ScreenType_COUNT] = {
        //   iPhoneX, iPhone 6+,  iPhone 6,  iPhone 5,  iPhone 4,      iPad  iPad 12.9
        {        128,       128,       128,       100,       100,       218,       218},      // ORK1ScreenMetricTopToCaptionBaseline
        {         35,        35,        35,        32,        24,        35,        35},      // ORK1ScreenMetricFontSizeHeadline
        {         38,        38,        38,        32,        28,        38,        38},      // ORK1ScreenMetricMaxFontSizeHeadline
        {         30,        30,        30,        30,        24,        30,        30},      // ORK1ScreenMetricFontSizeSurveyHeadline
        {         32,        32,        32,        32,        28,        32,        32},      // ORK1ScreenMetricMaxFontSizeSurveyHeadline
        {         17,        17,        17,        17,        16,        17,        17},      // ORK1ScreenMetricFontSizeSubheadline
        {         12,        12,        12,        12,        11,        12,        12},      // ORK1ScreenMetricFontSizeFootnote
        {         62,        62,        62,        51,        51,        62,        62},      // ORK1ScreenMetricCaptionBaselineToFitnessTimerTop
        {         62,        62,        62,        43,        43,        62,        62},      // ORK1ScreenMetricCaptionBaselineToTappingLabelTop
        {         36,        36,        36,        32,        32,        36,        36},      // ORK1ScreenMetricCaptionBaselineToInstructionBaseline
        {         30,        30,        30,        28,        24,        30,        30},      // ORK1ScreenMetricInstructionBaselineToLearnMoreBaseline
        {         44,        44,        44,        20,        14,        44,        44},      // ORK1ScreenMetricLearnMoreBaselineToStepViewTop
        {         40,        40,        40,        30,        14,        40,        40},      // ORK1ScreenMetricLearnMoreBaselineToStepViewTopWithNoLearnMore
        {         36,        36,        36,        20,        12,        36,        36},      // ORK1ScreenMetricContinueButtonTopMargin
        {         40,        40,        40,        20,        12,        40,        40},      // ORK1ScreenMetricContinueButtonTopMarginForIntroStep
        {          0,         0,         0,         0,         0,        80,       170},      // ORK1ScreenMetricTopToIllustration
        {         44,        44,        44,        40,        40,        44,        44},      // ORK1ScreenMetricIllustrationToCaptionBaseline
        {        198,       198,       198,       194,       152,       297,       297},      // ORK1ScreenMetricIllustrationHeight
        {        300,       300,       300,       176,       152,       300,       300},      // ORK1ScreenMetricInstructionImageHeight
        {         44,        44,        44,        44,        44,        44,        44},      // ORK1ScreenMetricContinueButtonHeightRegular
        {         44,        44,        32,        32,        32,        44,        44},      // ORK1ScreenMetricContinueButtonHeightCompact
        {        150,       150,       150,       146,       146,       150,       150},      // ORK1ScreenMetricContinueButtonWidth
        {        162,       162,       162,       120,       116,       240,       240},      // ORK1ScreenMetricMinimumStepHeaderHeightForMemoryGame
        {        162,       162,       162,       120,       116,       240,       240},      // ORK1ScreenMetricMinimumStepHeaderHeightForTowerOfHanoiPuzzle
        {         60,        60,        60,        60,        44,        60,        60},      // ORK1ScreenMetricTableCellDefaultHeight
        {         55,        55,        55,        55,        44,        55,        55},      // ORK1ScreenMetricTextFieldCellHeight
        {         36,        36,        36,        36,        26,        36,        36},      // ORK1ScreenMetricChoiceCellFirstBaselineOffsetFromTop,
        {         24,        24,        24,        24,        18,        24,        24},      // ORK1ScreenMetricChoiceCellLastBaselineToBottom,
        {         24,        24,        24,        24,        24,        24,        24},      // ORK1ScreenMetricChoiceCellLabelLastBaselineToLabelFirstBaseline,
        {         30,        30,        30,        20,        20,        30,        30},      // ORK1ScreenMetricLearnMoreButtonSideMargin
        {         10,        10,        10,         0,         0,        10,        10},      // ORK1ScreenMetricHeadlineSideMargin
        {         44,        44,        44,        44,        44,        44,        44},      // ORK1ScreenMetricToolbarHeight
        {        350,       322,       274,       217,       217,       446,       446},      // ORK1ScreenMetricVerticalScaleHeight
        {        208,       208,       208,       208,       198,       256,       256},      // ORK1ScreenMetricSignatureViewHeight
        {        324,       384,       324,       304,       304,       384,       384},      // ORK1ScreenMetricPSATKeyboardViewWidth
        {        197,       197,       167,       157,       157,       197,       197},      // ORK1ScreenMetricPSATKeyboardViewHeight
        {        238,       238,       238,       150,        90,       238,       238},      // ORK1ScreenMetricLocationQuestionMapHeight
        {         40,        40,        40,        20,        14,        40,        40},      // ORK1ScreenMetricTopToIconImageViewTop
        {         44,        44,        44,        40,        40,        80,        80},      // ORK1ScreenMetricIconImageViewToCaptionBaseline
        {         30,        30,        30,        26,        22,        30,        30},      // ORK1ScreenMetricVerificationTextBaselineToResendButtonBaseline
    };
    return metrics[metric][screenType];
}

CGFloat ORK1GetMetricForWindow(ORK1ScreenMetric metric, UIWindow *window) {
    CGFloat metricValue = 0;
    switch (metric) {
        case ORK1ScreenMetricContinueButtonWidth:
        case ORK1ScreenMetricHeadlineSideMargin:
        case ORK1ScreenMetricLearnMoreButtonSideMargin:
            metricValue = ORK1GetMetricForScreenType(metric, ORK1GetHorizontalScreenTypeForWindow(window));
            break;
            
        default:
            metricValue = ORK1GetMetricForScreenType(metric, ORK1GetVerticalScreenTypeForWindow(window));
            break;
    }
    
    return metricValue;
}

const CGFloat ORK1LayoutMarginWidthRegularBezel = 15.0;
const CGFloat ORK1LayoutMarginWidthThinBezelRegular = 20.0;
const CGFloat ORK1LayoutMarginWidthiPad = 115.0;

CGFloat ORK1StandardLeftTableViewCellMarginForWindow(UIWindow *window) {
    CGFloat margin = 0;
    switch (ORK1GetHorizontalScreenTypeForWindow(window)) {
        case ORK1ScreenTypeiPhone4:
        case ORK1ScreenTypeiPhone5:
        case ORK1ScreenTypeiPhone6:
            margin = ORK1LayoutMarginWidthRegularBezel;
            break;
        case ORK1ScreenTypeiPhone6Plus:
        case ORK1ScreenTypeiPad:
        case ORK1ScreenTypeiPad12_9:
        default:
            margin = ORK1LayoutMarginWidthThinBezelRegular;
            break;
    }
    return margin;
}

CGFloat ORK1StandardLeftMarginForTableViewCell(UITableViewCell *cell) {
    return ORK1StandardLeftTableViewCellMarginForWindow(cell.window);
}

CGFloat ORK1StandardHorizontalAdaptiveSizeMarginForiPadWidth(CGFloat screenSizeWidth, UIWindow *window) {
    // Use adaptive side margin, if window is wider than iPhone6 Plus.
    // Min Marign = ORK1LayoutMarginWidthThinBezelRegular, Max Marign = ORK1LayoutMarginWidthiPad or iPad12_9
    
    CGFloat ratio =  (window.bounds.size.width - ORK1iPhone6PlusScreenSize.width) / (screenSizeWidth - ORK1iPhone6PlusScreenSize.width);
    ratio = MIN(1.0, ratio);
    ratio = MAX(0.0, ratio);
    return ORK1LayoutMarginWidthThinBezelRegular + (ORK1LayoutMarginWidthiPad - ORK1LayoutMarginWidthThinBezelRegular)*ratio;
}

CGFloat ORK1StandardHorizontalMarginForWindow(UIWindow *window) {
    window = ORK1DefaultWindowIfWindowIsNil(window); // need a proper window to use bounds
    CGFloat margin = 0;
    switch (ORK1GetHorizontalScreenTypeForWindow(window)) {
        case ORK1ScreenTypeiPhone4:
        case ORK1ScreenTypeiPhone5:
        case ORK1ScreenTypeiPhone6:
        case ORK1ScreenTypeiPhoneX:
        case ORK1ScreenTypeiPhone6Plus:
        default:
            margin = ORK1StandardLeftTableViewCellMarginForWindow(window);
            break;
        case ORK1ScreenTypeiPad:{
            margin = ORK1StandardHorizontalAdaptiveSizeMarginForiPadWidth(ORK1iPadScreenSize.width, window);
            break;
        }
        case ORK1ScreenTypeiPad12_9:{
            margin = ORK1StandardHorizontalAdaptiveSizeMarginForiPadWidth(ORK1iPad12_9ScreenSize.width, window);
            break;
        }
    }
    return margin;
}

CGFloat ORK1StandardHorizontalMarginForView(UIView *view) {
    return ORK1StandardHorizontalMarginForWindow(view.window);
}

UIEdgeInsets ORK1StandardLayoutMarginsForTableViewCell(UITableViewCell *cell) {
    const CGFloat StandardVerticalTableViewCellMargin = 8.0;
    return (UIEdgeInsets){.left = ORK1StandardLeftMarginForTableViewCell(cell),
                          .right = ORK1StandardLeftMarginForTableViewCell(cell),
                          .bottom = StandardVerticalTableViewCellMargin,
                          .top = StandardVerticalTableViewCellMargin};
}

UIEdgeInsets ORK1StandardFullScreenLayoutMarginsForView(UIView *view) {
    UIEdgeInsets layoutMargins = UIEdgeInsetsZero;
    ORK1ScreenType screenType = ORK1GetHorizontalScreenTypeForWindow(view.window);
    if (screenType == ORK1ScreenTypeiPad || screenType == ORK1ScreenTypeiPad12_9) {
        CGFloat margin = ORK1StandardHorizontalMarginForView(view);
        layoutMargins = (UIEdgeInsets){.left = margin, .right = margin };
    }
    return layoutMargins;
}

UIEdgeInsets ORK1ScrollIndicatorInsetsForScrollView(UIView *view) {
    UIEdgeInsets scrollIndicatorInsets = UIEdgeInsetsZero;
    ORK1ScreenType screenType = ORK1GetHorizontalScreenTypeForWindow(view.window);
    if (screenType == ORK1ScreenTypeiPad || screenType == ORK1ScreenTypeiPad12_9) {
        CGFloat margin = ORK1StandardHorizontalMarginForView(view);
        scrollIndicatorInsets = (UIEdgeInsets){.left = -margin, .right = -margin };
    }
    return scrollIndicatorInsets;
}

CGFloat ORK1WidthForSignatureView(UIWindow *window) {
    window = ORK1DefaultWindowIfWindowIsNil(window); // need a proper window to use bounds
    const CGSize windowSize = window.bounds.size;
    const CGFloat windowPortraitWidth = MIN(windowSize.width, windowSize.height);
    const CGFloat signatureViewWidth = windowPortraitWidth - (2 * ORK1StandardHorizontalMarginForView(window) + 2 * ORK1StandardLeftMarginForTableViewCell(window));
    return signatureViewWidth;
}

void ORK1UpdateScrollViewBottomInset(UIScrollView *scrollView, CGFloat bottomInset) {
    UIEdgeInsets insets = scrollView.contentInset;
    if (!ORK1CGFloatNearlyEqualToFloat(insets.bottom, bottomInset)) {
        CGPoint savedOffset = scrollView.contentOffset;
        
        insets.bottom = bottomInset;
        scrollView.contentInset = insets;
        
        insets = scrollView.scrollIndicatorInsets;
        insets.bottom = bottomInset;
        scrollView.scrollIndicatorInsets = insets;
        
        scrollView.contentOffset = savedOffset;
    }
}
