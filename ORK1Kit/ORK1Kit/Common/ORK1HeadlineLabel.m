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


#import "ORK1HeadlineLabel.h"

#import "ORK1Helpers_Internal.h"
#import "ORK1Skin.h"

#import "CEVRK1Theme.h"

@interface ORK1HeadlineLabel()

@property (nonatomic, strong, nullable) CEVRK1Theme *cev_theme;

@end

@implementation ORK1HeadlineLabel

@synthesize cev_theme = _cev_theme;

+ (UIFont *)defaultFontInSurveyMode:(BOOL)surveyMode {
    UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleHeadline];
    const CGFloat defaultHeadlineSize = 17;
    
    CGFloat fontSize = [[descriptor objectForKey: UIFontDescriptorSizeAttribute] doubleValue] - defaultHeadlineSize + ORK1GetMetricForWindow(surveyMode ? ORK1ScreenMetricFontSizeSurveyHeadline : ORK1ScreenMetricFontSizeHeadline, nil);
    CGFloat maxFontSize = ORK1GetMetricForWindow(surveyMode ? ORK1ScreenMetricMaxFontSizeSurveyHeadline : ORK1ScreenMetricMaxFontSizeHeadline, nil);
    
    return ORK1LightFontWithSize(MIN(maxFontSize, fontSize));
}

+ (UIFont *)defaultFont {
    return [self defaultFontInSurveyMode:NO];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        __weak __typeof__(self) weakSelf = self;
        [NSNotificationCenter.defaultCenter addObserverForName:CEVORK1StepViewControllerViewWillAppearNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
            CEVRK1Theme *theme = note.userInfo[CEVRK1ThemeKey];
            if ([theme isKindOfClass:[CEVRK1Theme class]]) {
                weakSelf.cev_theme = theme;
                [weakSelf updateAppearance];
            }
        }];
    }
    return self;
}

- (UIFont *)defaultFont {
    UIFont *defaultFontForSurveyMode = [[self class] defaultFontInSurveyMode:_useSurveyMode];
    return [[CEVRK1Theme themeForElement:self] headlineLabelFontWithSize:defaultFontForSurveyMode.pointSize] ?: defaultFontForSurveyMode;
}

- (void)setUseSurveyMode:(BOOL)useSurveyMode {
    _useSurveyMode = useSurveyMode;
    [self updateAppearance];
}

// Nasty override (hack)
- (void)updateAppearance {
    UIColor *overrideColor = [[CEVRK1Theme themeForElement:self] headlineLabelFontColor];
    if (overrideColor) {
        self.textColor = overrideColor;
    }
    
    self.font = [self defaultFont];
    [self invalidateIntrinsicContentSize];
}

#pragma mark Accessibility

- (UIAccessibilityTraits)accessibilityTraits {
    return [super accessibilityTraits] | UIAccessibilityTraitHeader;
}

@end