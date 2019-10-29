//
//  CEVRKTheme.m
//  ResearchKit
//
//  Created by Eric Schramm on 7/10/19.
//  Copyright © 2019 researchkit.org. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CEVRKTheme.h"
#import "RK1Helpers_Internal.h"
#import "RK1ContinueButton.h"
#import "RK1TaskViewController.h"
#import "RK1Task.h"

NSNotificationName const CEVRK1StepViewControllerViewWillAppearNotification = @"CEVRK1StepViewControllerViewWillAppearNotification";
NSString *const CEVRKThemeKey = @"cev_theme";

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
    if ([element respondsToSelector:@selector(cev_theme)]) {                                                      // has theme
        id <CEVRKThemedUIElement> themedElement = element;
        CEVRKTheme *theme = [themedElement cev_theme];
        if (theme) {                                                                                              // if theme is null, keep searching
            return theme;
        }
    }
    if ([element isKindOfClass:[RK1StepViewController class]]) {                                                  // is stepViewController, jump to task for theme
        id <RK1Task> task = [(RK1StepViewController *)element taskViewController].task;
        return [CEVRKTheme themeForElement:task];
    } else if ([element respondsToSelector:@selector(nextResponder)] && [element nextResponder]) {                // continue up responder chain
        id nextResponder = [element nextResponder];
        return [CEVRKTheme themeForElement:nextResponder];
    } else if ([element respondsToSelector:@selector(parentViewController)] && [element parentViewController]) {  // if has parentViewController, try that route
        UIViewController *parentViewController = [element parentViewController];
        return [CEVRKTheme themeForElement:parentViewController];
    } else {                                                                                                      // has reached end of chain or not in chain
        return [CEVRKTheme defaultTheme];
    }
}

+ (NSString *)themeTitleForType:(CEVRKThemeType)type {
    switch (type) {
        case CEVRKThemeTypeDefault:
            return @"Default Theme";
            break;
        case CEVRKThemeTypeAllOfUs:
            return @"All of Us Theme";
            break;
        default:
            return @"No theme - undefined";
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<CEVRKTheme: %p : %@>", self, [CEVRKTheme themeTitleForType:_themeType]];
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
            return RK1RGB(0x262262);
        default:
            return nil;
    }
}

- (UIColor *)taskViewControllerTintColor {
    switch (self.themeType) {
        case CEVRKThemeTypeAllOfUs:
            return RK1RGB(0x216fb4);
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

- (void)updateAppearanceForContinueButton:(RK1ContinueButton *)continueButton {
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
                continueButton.layer.cornerRadius = 5.0f;
                continueButton.layer.borderWidth = 1.0f;
                return;
            }
            
            CAGradientLayer *gradient = [[CAGradientLayer alloc] init];
            gradient.frame = continueButton.bounds;
            if (continueButton.highlighted || continueButton.selected) {
                gradient.colors = @[(id)RK1RGB(0xcd6754).CGColor, (id)RK1RGB(0xd2a32e).CGColor];
            } else {
                gradient.colors = @[(id)RK1RGB(0xf38d7a).CGColor, (id)RK1RGB(0xf8c954).CGColor];
            }
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

- (void)updateTextForContinueButton:(RK1ContinueButton *)continueButton {
    switch (self.themeType) {
        case CEVRKThemeTypeAllOfUs: {
            if (!continueButton.titleLabel.text) {
                return;
            }
            
            UIColor *textColor = continueButton.isEnabled ? RK1RGB(0x262262) : [self disabledTintColor];
            
            UIFont *fontToMakeBold = [RK1ContinueButton defaultFont];
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
