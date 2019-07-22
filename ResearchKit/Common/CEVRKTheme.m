//
//  CEVRKTheme.m
//  ResearchKit
//
//  Created by Eric Schramm on 7/10/19.
//  Copyright © 2019 researchkit.org. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CEVRKTheme.h"
#import "ORKHelpers_Internal.h"
#import "ORKContinueButton.h"
#import "ORKTaskViewController.h"
#import "ORKTask.h"

@interface CEVRKTheme()
@property (nonatomic, assign) CEVRKThemeType themeType;
@end

@implementation CEVRKTheme

@synthesize themeType = _themeType;

- (instancetype)initWithType:(CEVRKThemeType)type {
    if (self = [super init]) {
        self.themeType = type;
        return self;
    }
    return nil;
}

+ (instancetype)defaultTheme {
    CEVRKTheme *defaultTheme = [[self alloc] init];
    defaultTheme.themeType = CEVRKThemeTypeDefault;
    return defaultTheme;
}

+ (instancetype)themeForElement:(id)element {
    if ([element respondsToSelector:@selector(theme)]) {                // has theme
        id <CEVRKThemedUIElement> themedElement = element;
        CEVRKTheme *theme = [themedElement theme];
        return theme ?: [CEVRKTheme defaultTheme];
    } else if ([element isKindOfClass:[ORKStepViewController class]]) {  // is stepViewController, jump to task for theme
        id <ORKTask> task = [(ORKStepViewController *)element taskViewController].task;
        return [CEVRKTheme themeForElement:task];
    } else if ([element respondsToSelector:@selector(nextResponder)]) {  // continue up responder chain
        UIResponder *currentResponder = (UIResponder *)element;
        id nextResponder = [currentResponder nextResponder];
        return [CEVRKTheme themeForElement:nextResponder];
    } else {                                                             // has reached end of chain or not in chain
        return [CEVRKTheme defaultTheme];
    }
}

- (UIFont *)headlineLabelFontWithSize:(CGFloat)fontSize {
    switch (self.themeType) {
        case CEVRKThemeTypeAllOfUs:
            return [UIFont boldSystemFontOfSize:fontSize];
        default:
            return nil;
    }
}

- (UIColor *)headlineLabelFontColor {
    switch (self.themeType) {
        case CEVRKThemeTypeAllOfUs:
            return ORKRGB(0x262262);
        default:
            return nil;
    }
}

- (UIColor *)taskViewControllerTintColor {
    switch (self.themeType) {
        case CEVRKThemeTypeAllOfUs:
            return ORKRGB(0x216fb4);
        default:
            return nil;
    }
}

- (NSNumber *)navigationContrainerViewButtonConstraintFromContinueButton {
    switch (self.themeType) {
    case CEVRKThemeTypeAllOfUs:
        // extends the difference between the standard and custom button size since
        // we need to allow for room for the skip button to show below the continue button
        return @(44 - 52);
    default:
        return nil;
    }
}

- (NSNumber *)continueButtonHeightForTextSize:(CGSize)textSize {
    switch (self.themeType) {
        case CEVRKThemeTypeAllOfUs:
            return @(textSize.height + (16 * 2));  // padding of 16
        default:
            return nil;
    }
}

- (NSNumber *)continueButtonWidthForWindowWidth:(CGFloat)windowWidth {
    switch (self.themeType) {
        case CEVRKThemeTypeAllOfUs:
            return @(windowWidth - (20 * 2));  // width 100 % minus system padding
        default:
            return nil;
    }
}

- (UIColor *)disabledTintColor {
    switch (self.themeType) {
        case CEVRKThemeTypeAllOfUs:
            return [[UIColor blackColor] colorWithAlphaComponent:0.3f];  // same as super class setting
        default:
            return nil;
    }
}

- (void)updateAppearanceForContinueButton:(ORKContinueButton *)continueButton {
    switch (self.themeType) {
        case CEVRKThemeTypeAllOfUs: {
            // remove any previous gradient layers if button resizes due to state changes
            for (NSInteger layerIndex = continueButton.layer.sublayers.count - 1; layerIndex >= 0; layerIndex --) {
                CALayer *layer = continueButton.layer.sublayers[layerIndex];
                if ([layer isKindOfClass:[CAGradientLayer class]]) {
                    [layer removeFromSuperlayer];
                }
            }
            
            [self updateTextForContinueButton:continueButton];
            
            UIColor *disableTintColor = [self disabledTintColor];
            if (!continueButton.isEnabled && disableTintColor) {
                continueButton.layer.borderColor = disableTintColor.CGColor;
                return;
            }
            
            CAGradientLayer *gradient = [[CAGradientLayer alloc] init];
            gradient.frame = continueButton.bounds;
            gradient.colors = @[(id)ORKRGB(0xf38d7a).CGColor, (id)ORKRGB(0xf8c954).CGColor];
            gradient.startPoint = CGPointMake(0, 0);
            gradient.endPoint = CGPointMake(1, 0);
            gradient.cornerRadius = 5.0f;
            
            [continueButton.layer insertSublayer:gradient atIndex:0];
            
            continueButton.layer.borderWidth = 0;
        }
        default:
            break;
    }
}

- (void)updateTextForContinueButton:(ORKContinueButton *)continueButton {
    switch (self.themeType) {
        case CEVRKThemeTypeAllOfUs: {
            if (!continueButton.titleLabel.text) {
                return;
            }
            
            UIColor *textColor = continueButton.isEnabled ? ORKRGB(0x262262) : [self disabledTintColor];
            
            UIFont *fontToMakeBold = [ORKContinueButton defaultFont];
            NSDictionary *attributes = @{           NSFontAttributeName            : [UIFont boldSystemFontOfSize:fontToMakeBold.pointSize],
                                                    NSForegroundColorAttributeName : textColor,
                                                    NSKernAttributeName            : @(3)};  // 3 pts = 0.25 em
            NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:[continueButton.titleLabel.text uppercaseString] attributes:attributes];
            [continueButton setAttributedTitle:attributedString forState:UIControlStateNormal];
        }
        default:
            break;
    }
}

@end
