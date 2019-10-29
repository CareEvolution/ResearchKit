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


#import "RK1Skin.h"

#import "RK1Helpers_Internal.h"


NSString *const RK1SignatureColorKey = @"RK1SignatureColorKey";
NSString *const RK1BackgroundColorKey = @"RK1BackgroundColorKey";
NSString *const RK1ToolBarTintColorKey = @"RK1ToolBarTintColorKey";
NSString *const RK1LightTintColorKey = @"RK1LightTintColorKey";
NSString *const RK1DarkTintColorKey = @"RK1DarkTintColorKey";
NSString *const RK1CaptionTextColorKey = @"RK1CaptionTextColorKey";
NSString *const RK1BlueHighlightColorKey = @"RK1BlueHighlightColorKey";
NSString *const RK1ChartDefaultTextColorKey = @"RK1ChartDefaultTextColorKey";
NSString *const RK1GraphAxisColorKey = @"RK1GraphAxisColorKey";
NSString *const RK1GraphAxisTitleColorKey = @"RK1GraphAxisTitleColorKey";
NSString *const RK1GraphReferenceLineColorKey = @"RK1GraphReferenceLineColorKey";
NSString *const RK1GraphScrubberLineColorKey = @"RK1GraphScrubberLineColorKey";
NSString *const RK1GraphScrubberThumbColorKey = @"RK1GraphScrubberThumbColorKey";
NSString *const RK1AuxiliaryImageTintColorKey = @"RK1AuxiliaryImageTintColorKey";

@implementation UIColor (RK1Color)

#define RK1CachedColorMethod(m, r, g, b, a) \
+ (UIColor *)m { \
    static UIColor *c##m = nil; \
    static dispatch_once_t onceToken##m; \
    dispatch_once(&onceToken##m, ^{ \
        c##m = [[UIColor alloc] initWithRed:r green:g blue:b alpha:a]; \
    }); \
    return c##m; \
}

RK1CachedColorMethod(ork_midGrayTintColor, 0.0 / 255.0, 0.0 / 255.0, 25.0 / 255.0, 0.22)
RK1CachedColorMethod(ork_redColor, 255.0 / 255.0,  59.0 / 255.0,  48.0 / 255.0, 1.0)
RK1CachedColorMethod(ork_grayColor, 142.0 / 255.0, 142.0 / 255.0, 147.0 / 255.0, 1.0)
RK1CachedColorMethod(ork_darkGrayColor, 102.0 / 255.0, 102.0 / 255.0, 102.0 / 255.0, 1.0)

#undef RK1CachedColorMethod

@end

static NSMutableDictionary *colors() {
    static NSMutableDictionary *colors = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colors = [@{
                    RK1SignatureColorKey: RK1RGB(0x000000),
                    RK1BackgroundColorKey: RK1RGB(0xffffff),
                    RK1ToolBarTintColorKey: RK1RGB(0xffffff),
                    RK1LightTintColorKey: RK1RGB(0xeeeeee),
                    RK1DarkTintColorKey: RK1RGB(0x888888),
                    RK1CaptionTextColorKey: RK1RGB(0xcccccc),
                    RK1BlueHighlightColorKey: [UIColor colorWithRed:0.0 green:122.0 / 255.0 blue:1.0 alpha:1.0],
                    RK1ChartDefaultTextColorKey: [UIColor lightGrayColor],
                    RK1GraphAxisColorKey: [UIColor colorWithRed:217.0 / 255.0 green:217.0 / 255.0 blue:217.0 / 255.0 alpha:1.0],
                    RK1GraphAxisTitleColorKey: [UIColor colorWithRed:142.0 / 255.0 green:142.0 / 255.0 blue:147.0 / 255.0 alpha:1.0],
                    RK1GraphReferenceLineColorKey: [UIColor colorWithRed:225.0 / 255.0 green:225.0 / 255.0 blue:229.0 / 255.0 alpha:1.0],
                    RK1GraphScrubberLineColorKey: [UIColor grayColor],
                    RK1GraphScrubberThumbColorKey: [UIColor colorWithWhite:1.0 alpha:1.0],
                    RK1AuxiliaryImageTintColorKey: [UIColor colorWithRed:228.0 / 255.0 green:233.0 / 255.0 blue:235.0 / 255.0 alpha:1.0],
                    } mutableCopy];
    });
    return colors;
}

UIColor *RK1Color(NSString *colorKey) {
    return colors()[colorKey];
}

void RK1ColorSetColorForKey(NSString *key, UIColor *color) {
    NSMutableDictionary *d = colors();
    d[key] = color;
}

const CGSize RK1iPhone4ScreenSize = (CGSize){320, 480};
const CGSize RK1iPhone5ScreenSize = (CGSize){320, 568};
const CGSize RK1iPhone6ScreenSize = (CGSize){375, 667};
const CGSize RK1iPhone6PlusScreenSize = (CGSize){414, 736};
const CGSize RK1iPhoneXScreenSize = (CGSize){375, 812};
const CGSize RK1iPadScreenSize = (CGSize){768, 1024};
const CGSize RK1iPad12_9ScreenSize = (CGSize){1024, 1366};

RK1ScreenType RK1GetVerticalScreenTypeForBounds(CGRect bounds) {
    RK1ScreenType screenType = RK1ScreenTypeiPhone6;
    CGFloat maximumDimension = MAX(bounds.size.width, bounds.size.height);
    if (maximumDimension < RK1iPhone4ScreenSize.height + 1) {
        screenType = RK1ScreenTypeiPhone4;
    } else if (maximumDimension < RK1iPhone5ScreenSize.height + 1) {
        screenType = RK1ScreenTypeiPhone5;
    } else if (maximumDimension < RK1iPhone6ScreenSize.height + 1) {
        screenType = RK1ScreenTypeiPhone6;
    } else if (maximumDimension < RK1iPhone6PlusScreenSize.height + 1) {
        screenType = RK1ScreenTypeiPhone6Plus;
    } else if (maximumDimension < RK1iPhoneXScreenSize.height + 1) {
        screenType = RK1ScreenTypeiPhoneX;
    } else if (maximumDimension < RK1iPadScreenSize.height + 1) {
        screenType = RK1ScreenTypeiPad;
    } else {
        screenType = RK1ScreenTypeiPad12_9;
    }
    return screenType;
}

RK1ScreenType RK1GetHorizontalScreenTypeForBounds(CGRect bounds) {
    RK1ScreenType screenType = RK1ScreenTypeiPhone6;
    CGFloat minimumDimension = MIN(bounds.size.width, bounds.size.height);
    if (minimumDimension < RK1iPhone4ScreenSize.width + 1) {
        screenType = RK1ScreenTypeiPhone4;
    } else if (minimumDimension < RK1iPhone5ScreenSize.width + 1) {
        screenType = RK1ScreenTypeiPhone5;
    } else if (minimumDimension < RK1iPhone6ScreenSize.width + 1) {
        screenType = RK1ScreenTypeiPhone6;
    }  else if (minimumDimension < RK1iPhoneXScreenSize.width + 1) {
        screenType = RK1ScreenTypeiPhoneX;
    } else if (minimumDimension < RK1iPhone6PlusScreenSize.width + 1) {
        screenType = RK1ScreenTypeiPhone6Plus;
    } else if (minimumDimension < RK1iPadScreenSize.width + 1) {
        screenType = RK1ScreenTypeiPad;
    } else {
        screenType = RK1ScreenTypeiPad12_9;
    }
    return screenType;
}

UIWindow *RK1DefaultWindowIfWindowIsNil(UIWindow *window) {
    if (!window) {
        // Use this method instead of UIApplication's keyWindow or UIApplication's delegate's window
        // because we may need the window before the keyWindow is set (e.g., if a view controller
        // loads programmatically on the app delegate to be assigned as the root view controller)
        window = [UIApplication sharedApplication].windows.firstObject;
    }
    return window;
}

RK1ScreenType RK1GetVerticalScreenTypeForWindow(UIWindow *window) {
    window = RK1DefaultWindowIfWindowIsNil(window);
    return RK1GetVerticalScreenTypeForBounds(window.bounds);
}

RK1ScreenType RK1GetHorizontalScreenTypeForWindow(UIWindow *window) {
    window = RK1DefaultWindowIfWindowIsNil(window);
    return RK1GetHorizontalScreenTypeForBounds(window.bounds);
}

RK1ScreenType RK1GetScreenTypeForScreen(UIScreen *screen) {
    RK1ScreenType screenType = RK1ScreenTypeiPhone6;
    if (screen == [UIScreen mainScreen]) {
        screenType = RK1GetVerticalScreenTypeForBounds(screen.bounds);
    }
    return screenType;
}

const CGFloat RK1ScreenMetricMaxDimension = 10000.0;

CGFloat RK1GetMetricForScreenType(RK1ScreenMetric metric, RK1ScreenType screenType) {
    static  const CGFloat metrics[RK1ScreenMetric_COUNT][RK1ScreenType_COUNT] = {
        //   iPhoneX, iPhone 6+,  iPhone 6,  iPhone 5,  iPhone 4,      iPad  iPad 12.9
        {        128,       128,       128,       100,       100,       218,       218},      // RK1ScreenMetricTopToCaptionBaseline
        {         35,        35,        35,        32,        24,        35,        35},      // RK1ScreenMetricFontSizeHeadline
        {         38,        38,        38,        32,        28,        38,        38},      // RK1ScreenMetricMaxFontSizeHeadline
        {         30,        30,        30,        30,        24,        30,        30},      // RK1ScreenMetricFontSizeSurveyHeadline
        {         32,        32,        32,        32,        28,        32,        32},      // RK1ScreenMetricMaxFontSizeSurveyHeadline
        {         17,        17,        17,        17,        16,        17,        17},      // RK1ScreenMetricFontSizeSubheadline
        {         12,        12,        12,        12,        11,        12,        12},      // RK1ScreenMetricFontSizeFootnote
        {         62,        62,        62,        51,        51,        62,        62},      // RK1ScreenMetricCaptionBaselineToFitnessTimerTop
        {         62,        62,        62,        43,        43,        62,        62},      // RK1ScreenMetricCaptionBaselineToTappingLabelTop
        {         36,        36,        36,        32,        32,        36,        36},      // RK1ScreenMetricCaptionBaselineToInstructionBaseline
        {         30,        30,        30,        28,        24,        30,        30},      // RK1ScreenMetricInstructionBaselineToLearnMoreBaseline
        {         44,        44,        44,        20,        14,        44,        44},      // RK1ScreenMetricLearnMoreBaselineToStepViewTop
        {         40,        40,        40,        30,        14,        40,        40},      // RK1ScreenMetricLearnMoreBaselineToStepViewTopWithNoLearnMore
        {         36,        36,        36,        20,        12,        36,        36},      // RK1ScreenMetricContinueButtonTopMargin
        {         40,        40,        40,        20,        12,        40,        40},      // RK1ScreenMetricContinueButtonTopMarginForIntroStep
        {          0,         0,         0,         0,         0,        80,       170},      // RK1ScreenMetricTopToIllustration
        {         44,        44,        44,        40,        40,        44,        44},      // RK1ScreenMetricIllustrationToCaptionBaseline
        {        198,       198,       198,       194,       152,       297,       297},      // RK1ScreenMetricIllustrationHeight
        {        300,       300,       300,       176,       152,       300,       300},      // RK1ScreenMetricInstructionImageHeight
        {         44,        44,        44,        44,        44,        44,        44},      // RK1ScreenMetricContinueButtonHeightRegular
        {         44,        44,        32,        32,        32,        44,        44},      // RK1ScreenMetricContinueButtonHeightCompact
        {        150,       150,       150,       146,       146,       150,       150},      // RK1ScreenMetricContinueButtonWidth
        {        162,       162,       162,       120,       116,       240,       240},      // RK1ScreenMetricMinimumStepHeaderHeightForMemoryGame
        {        162,       162,       162,       120,       116,       240,       240},      // RK1ScreenMetricMinimumStepHeaderHeightForTowerOfHanoiPuzzle
        {         60,        60,        60,        60,        44,        60,        60},      // RK1ScreenMetricTableCellDefaultHeight
        {         55,        55,        55,        55,        44,        55,        55},      // RK1ScreenMetricTextFieldCellHeight
        {         36,        36,        36,        36,        26,        36,        36},      // RK1ScreenMetricChoiceCellFirstBaselineOffsetFromTop,
        {         24,        24,        24,        24,        18,        24,        24},      // RK1ScreenMetricChoiceCellLastBaselineToBottom,
        {         24,        24,        24,        24,        24,        24,        24},      // RK1ScreenMetricChoiceCellLabelLastBaselineToLabelFirstBaseline,
        {         30,        30,        30,        20,        20,        30,        30},      // RK1ScreenMetricLearnMoreButtonSideMargin
        {         10,        10,        10,         0,         0,        10,        10},      // RK1ScreenMetricHeadlineSideMargin
        {         44,        44,        44,        44,        44,        44,        44},      // RK1ScreenMetricToolbarHeight
        {        350,       322,       274,       217,       217,       446,       446},      // RK1ScreenMetricVerticalScaleHeight
        {        208,       208,       208,       208,       198,       256,       256},      // RK1ScreenMetricSignatureViewHeight
        {        324,       384,       324,       304,       304,       384,       384},      // RK1ScreenMetricPSATKeyboardViewWidth
        {        197,       197,       167,       157,       157,       197,       197},      // RK1ScreenMetricPSATKeyboardViewHeight
        {        238,       238,       238,       150,        90,       238,       238},      // RK1ScreenMetricLocationQuestionMapHeight
        {         40,        40,        40,        20,        14,        40,        40},      // RK1ScreenMetricTopToIconImageViewTop
        {         44,        44,        44,        40,        40,        80,        80},      // RK1ScreenMetricIconImageViewToCaptionBaseline
        {         30,        30,        30,        26,        22,        30,        30},      // RK1ScreenMetricVerificationTextBaselineToResendButtonBaseline
    };
    return metrics[metric][screenType];
}

CGFloat RK1GetMetricForWindow(RK1ScreenMetric metric, UIWindow *window) {
    CGFloat metricValue = 0;
    switch (metric) {
        case RK1ScreenMetricContinueButtonWidth:
        case RK1ScreenMetricHeadlineSideMargin:
        case RK1ScreenMetricLearnMoreButtonSideMargin:
            metricValue = RK1GetMetricForScreenType(metric, RK1GetHorizontalScreenTypeForWindow(window));
            break;
            
        default:
            metricValue = RK1GetMetricForScreenType(metric, RK1GetVerticalScreenTypeForWindow(window));
            break;
    }
    
    return metricValue;
}

const CGFloat RK1LayoutMarginWidthRegularBezel = 15.0;
const CGFloat RK1LayoutMarginWidthThinBezelRegular = 20.0;
const CGFloat RK1LayoutMarginWidthiPad = 115.0;

CGFloat RK1StandardLeftTableViewCellMarginForWindow(UIWindow *window) {
    CGFloat margin = 0;
    switch (RK1GetHorizontalScreenTypeForWindow(window)) {
        case RK1ScreenTypeiPhone4:
        case RK1ScreenTypeiPhone5:
        case RK1ScreenTypeiPhone6:
            margin = RK1LayoutMarginWidthRegularBezel;
            break;
        case RK1ScreenTypeiPhone6Plus:
        case RK1ScreenTypeiPad:
        case RK1ScreenTypeiPad12_9:
        default:
            margin = RK1LayoutMarginWidthThinBezelRegular;
            break;
    }
    return margin;
}

CGFloat RK1StandardLeftMarginForTableViewCell(UITableViewCell *cell) {
    return RK1StandardLeftTableViewCellMarginForWindow(cell.window);
}

CGFloat RK1StandardHorizontalAdaptiveSizeMarginForiPadWidth(CGFloat screenSizeWidth, UIWindow *window) {
    // Use adaptive side margin, if window is wider than iPhone6 Plus.
    // Min Marign = RK1LayoutMarginWidthThinBezelRegular, Max Marign = RK1LayoutMarginWidthiPad or iPad12_9
    
    CGFloat ratio =  (window.bounds.size.width - RK1iPhone6PlusScreenSize.width) / (screenSizeWidth - RK1iPhone6PlusScreenSize.width);
    ratio = MIN(1.0, ratio);
    ratio = MAX(0.0, ratio);
    return RK1LayoutMarginWidthThinBezelRegular + (RK1LayoutMarginWidthiPad - RK1LayoutMarginWidthThinBezelRegular)*ratio;
}

CGFloat RK1StandardHorizontalMarginForWindow(UIWindow *window) {
    window = RK1DefaultWindowIfWindowIsNil(window); // need a proper window to use bounds
    CGFloat margin = 0;
    switch (RK1GetHorizontalScreenTypeForWindow(window)) {
        case RK1ScreenTypeiPhone4:
        case RK1ScreenTypeiPhone5:
        case RK1ScreenTypeiPhone6:
        case RK1ScreenTypeiPhoneX:
        case RK1ScreenTypeiPhone6Plus:
        default:
            margin = RK1StandardLeftTableViewCellMarginForWindow(window);
            break;
        case RK1ScreenTypeiPad:{
            margin = RK1StandardHorizontalAdaptiveSizeMarginForiPadWidth(RK1iPadScreenSize.width, window);
            break;
        }
        case RK1ScreenTypeiPad12_9:{
            margin = RK1StandardHorizontalAdaptiveSizeMarginForiPadWidth(RK1iPad12_9ScreenSize.width, window);
            break;
        }
    }
    return margin;
}

CGFloat RK1StandardHorizontalMarginForView(UIView *view) {
    return RK1StandardHorizontalMarginForWindow(view.window);
}

UIEdgeInsets RK1StandardLayoutMarginsForTableViewCell(UITableViewCell *cell) {
    const CGFloat StandardVerticalTableViewCellMargin = 8.0;
    return (UIEdgeInsets){.left = RK1StandardLeftMarginForTableViewCell(cell),
                          .right = RK1StandardLeftMarginForTableViewCell(cell),
                          .bottom = StandardVerticalTableViewCellMargin,
                          .top = StandardVerticalTableViewCellMargin};
}

UIEdgeInsets RK1StandardFullScreenLayoutMarginsForView(UIView *view) {
    UIEdgeInsets layoutMargins = UIEdgeInsetsZero;
    RK1ScreenType screenType = RK1GetHorizontalScreenTypeForWindow(view.window);
    if (screenType == RK1ScreenTypeiPad || screenType == RK1ScreenTypeiPad12_9) {
        CGFloat margin = RK1StandardHorizontalMarginForView(view);
        layoutMargins = (UIEdgeInsets){.left = margin, .right = margin };
    }
    return layoutMargins;
}

UIEdgeInsets RK1ScrollIndicatorInsetsForScrollView(UIView *view) {
    UIEdgeInsets scrollIndicatorInsets = UIEdgeInsetsZero;
    RK1ScreenType screenType = RK1GetHorizontalScreenTypeForWindow(view.window);
    if (screenType == RK1ScreenTypeiPad || screenType == RK1ScreenTypeiPad12_9) {
        CGFloat margin = RK1StandardHorizontalMarginForView(view);
        scrollIndicatorInsets = (UIEdgeInsets){.left = -margin, .right = -margin };
    }
    return scrollIndicatorInsets;
}

CGFloat RK1WidthForSignatureView(UIWindow *window) {
    window = RK1DefaultWindowIfWindowIsNil(window); // need a proper window to use bounds
    const CGSize windowSize = window.bounds.size;
    const CGFloat windowPortraitWidth = MIN(windowSize.width, windowSize.height);
    const CGFloat signatureViewWidth = windowPortraitWidth - (2 * RK1StandardHorizontalMarginForView(window) + 2 * RK1StandardLeftMarginForTableViewCell(window));
    return signatureViewWidth;
}

void RK1UpdateScrollViewBottomInset(UIScrollView *scrollView, CGFloat bottomInset) {
    UIEdgeInsets insets = scrollView.contentInset;
    if (!RK1CGFloatNearlyEqualToFloat(insets.bottom, bottomInset)) {
        CGPoint savedOffset = scrollView.contentOffset;
        
        insets.bottom = bottomInset;
        scrollView.contentInset = insets;
        
        insets = scrollView.scrollIndicatorInsets;
        insets.bottom = bottomInset;
        scrollView.scrollIndicatorInsets = insets;
        
        scrollView.contentOffset = savedOffset;
    }
}
