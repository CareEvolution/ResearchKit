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


#import "RK1ContinueButton.h"

#import "RK1Skin.h"

#import "CEVRKTheme.h"


static const CGFloat ContinueButtonTouchMargin = 10;

@implementation RK1ContinueButton {
    NSLayoutConstraint *_heightConstraint;
    NSLayoutConstraint *_widthConstraint;
}

- (instancetype)initWithTitle:(NSString *)title isDoneButton:(BOOL)isDoneButton {
    self = [super init];
    if (self) {
        [self setTitle:title forState:UIControlStateNormal];
        self.isDoneButton = isDoneButton;
        self.contentEdgeInsets = (UIEdgeInsets){.left = 6, .right = 6};

        [self setUpConstraints];
    }
    return self;
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    [self updateConstraintConstantsForWindow:newWindow];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange: previousTraitCollection];
    if (self.traitCollection.verticalSizeClass != previousTraitCollection.verticalSizeClass) {
        [self updateConstraintConstantsForWindow:self.window];
    }
    
    if (self.traitCollection.preferredContentSizeCategory != previousTraitCollection.preferredContentSizeCategory) {
        [[CEVRKTheme themeForElement:self] updateTextForContinueButton:self];
    }
}

- (void)updateConstraintConstantsForWindow:(UIWindow *)window {
    _heightConstraint.constant = [self buttonHeightForWindow:window];
    _widthConstraint.constant = [self buttonWidthForWindow:window];
}

- (CGFloat)buttonWidthForWindow:(UIWindow *)window {
    NSNumber *overrideWidth = [[CEVRKTheme themeForElement:self] continueButtonWidthForWindowWidth:window.frame.size.width];
    
    if (overrideWidth) {
        return overrideWidth.floatValue;
    } else {
        return RK1GetMetricForWindow(RK1ScreenMetricContinueButtonWidth, self.window);
    }
}

- (CGFloat)buttonHeightForWindow:(UIWindow *)window {
    CGFloat height = (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) ?
    RK1GetMetricForWindow(RK1ScreenMetricContinueButtonHeightCompact, window) :
    RK1GetMetricForWindow(RK1ScreenMetricContinueButtonHeightRegular, window);
    
    CGSize textSize = [self.titleLabel.text sizeWithAttributes:@{NSFontAttributeName : [RK1ContinueButton defaultFont]}];
    return ([[CEVRKTheme themeForElement:self] continueButtonHeightForTextSize:textSize] ?: @(height)).floatValue;
}
    
- (void)setUpConstraints {
    _heightConstraint = [NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                    multiplier:1.0
                                                      constant:0.0]; // constant will be set in updateConstraintConstantsForWindow:
    _heightConstraint.active = YES;
    
    _widthConstraint = [NSLayoutConstraint constraintWithItem:self
                                                    attribute:NSLayoutAttributeWidth
                                                    relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                       toItem:nil
                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                   multiplier:1.0
                                                     constant:0.0];  // constant will be set in updateConstraintConstantsForWindow:
    _widthConstraint.active = YES;
    [self updateConstraintConstantsForWindow:self.window];
}

- (void)updateConstraints {
    [self updateConstraintConstantsForWindow:self.window];
    [super updateConstraints];
}

+ (UIFont *)defaultFont {
    UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleHeadline];
    return [UIFont systemFontOfSize:[[descriptor objectForKey: UIFontDescriptorSizeAttribute] doubleValue]];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect outsetRect = UIEdgeInsetsInsetRect(self.bounds,
                                              (UIEdgeInsets){-ContinueButtonTouchMargin,
                                                             -ContinueButtonTouchMargin,
                                                             -ContinueButtonTouchMargin,
                                                             -ContinueButtonTouchMargin});
    BOOL isInside = [super pointInside:point withEvent:event] || CGRectContainsPoint(outsetRect, point);
    return isInside;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [[CEVRKTheme themeForElement:self] updateAppearanceForContinueButton:self];
}

@end
