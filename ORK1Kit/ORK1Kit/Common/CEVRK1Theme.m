//
//  CEVRK1Theme.m
//  ORK1Kit
//
//  Created by Eric Schramm on 7/10/19.
//  Copyright © 2019 researchkit.org. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CEVRK1Theme.h"
#import "ORK1Helpers_Internal.h"
#import "ORK1ContinueButton.h"
#import "ORK1TaskViewController.h"
#import "ORK1Task.h"

NSNotificationName const CEVORK1StepViewControllerViewWillAppearNotification = @"CEVORK1StepViewControllerViewWillAppearNotification";
NSString *const CEVRK1ThemeKey = @"cev_theme";

@interface CEVRK1Theme()
@property (nonatomic, assign) CEVRK1ThemeType themeType;
@end

@implementation CEVRK1Theme

@synthesize themeType = _themeType;

- (instancetype)initWithType:(CEVRK1ThemeType)type {
    if (self = [super init]) {
        self.themeType = type;
        return self;
    }
    return nil;
}

+ (instancetype)defaultTheme {
    CEVRK1Theme *defaultTheme = [[self alloc] init];
    defaultTheme.themeType = CEVRK1ThemeTypeDefault;
    return defaultTheme;
}

+ (instancetype)themeForElement:(id)element {
    if ([element respondsToSelector:@selector(cev_theme)]) {                                                      // has theme
        id <CEVRK1ThemedUIElement> themedElement = element;
        CEVRK1Theme *theme = [themedElement cev_theme];
        if (theme) {                                                                                              // if theme is null, keep searching
            return theme;
        }
    }
    if ([element isKindOfClass:[ORK1StepViewController class]]) {                                                  // is stepViewController, jump to task for theme
        id <ORK1Task> task = [(ORK1StepViewController *)element taskViewController].task;
        return [CEVRK1Theme themeForElement:task];
    } else if ([element respondsToSelector:@selector(nextResponder)] && [element nextResponder]) {                // continue up responder chain
        id nextResponder = [element nextResponder];
        return [CEVRK1Theme themeForElement:nextResponder];
    } else if ([element respondsToSelector:@selector(parentViewController)] && [element parentViewController]) {  // if has parentViewController, try that route
        UIViewController *parentViewController = [element parentViewController];
        return [CEVRK1Theme themeForElement:parentViewController];
    } else {                                                                                                      // has reached end of chain or not in chain
        return [CEVRK1Theme defaultTheme];
    }
}

+ (NSString *)themeTitleForType:(CEVRK1ThemeType)type {
    switch (type) {
        case CEVRK1ThemeTypeDefault:
            return @"Default Theme";
            break;
        case CEVRK1ThemeTypeAllOfUs:
            return @"All of Us Theme";
            break;
        default:
            return @"No theme - undefined";
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<CEVRK1Theme: %p : %@>", self, [CEVRK1Theme themeTitleForType:_themeType]];
}

- (UIFont *)headlineLabelFontWithSize:(CGFloat)fontSize {
    switch (self.themeType) {
        case CEVRK1ThemeTypeAllOfUs:
            return [UIFont boldSystemFontOfSize:fontSize];
        default:
            return nil;
    }
}

- (UIColor *)headlineLabelFontColor {
    switch (self.themeType) {
        case CEVRK1ThemeTypeAllOfUs:
            return ORK1RGB(0x262262);
        default:
            return nil;
    }
}

- (UIColor *)taskViewControllerTintColor {
    switch (self.themeType) {
        case CEVRK1ThemeTypeAllOfUs:
            return ORK1RGB(0x216fb4);
        default:
            return nil;
    }
}

- (NSNumber *)navigationContrainerViewButtonConstraintFromContinueButton {
    switch (self.themeType) {
    case CEVRK1ThemeTypeAllOfUs:
        // extends the difference between the standard and custom button size since
        // we need to allow for room for the skip button to show below the continue button
        return @(44 - 52);
    default:
        return nil;
    }
}

- (NSNumber *)continueButtonHeightForTextSize:(CGSize)textSize {
    return @(textSize.height + (16 * 2));  // padding of 16
}

- (NSNumber *)continueButtonWidthForWindowWidth:(CGFloat)windowWidth {
    return @(windowWidth - (20 * 2));  // width 100 % minus system padding
}

- (UIColor *)disabledTintColor {
    switch (self.themeType) {
        case CEVRK1ThemeTypeAllOfUs:
            return [[UIColor blackColor] colorWithAlphaComponent:0.3f];  // same as super class setting
        default:
            return nil;
    }
}

- (void)updateAppearanceForContinueButton:(ORK1ContinueButton *)continueButton {
    switch (self.themeType) {
        case CEVRK1ThemeTypeAllOfUs: {
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
                gradient.colors = @[(id)ORK1RGB(0xcd6754).CGColor, (id)ORK1RGB(0xd2a32e).CGColor];
            } else {
                gradient.colors = @[(id)ORK1RGB(0xf38d7a).CGColor, (id)ORK1RGB(0xf8c954).CGColor];
            }
            gradient.startPoint = CGPointMake(0, 0);
            gradient.endPoint = CGPointMake(1, 0);
            gradient.cornerRadius = 5.0f;
            
            [continueButton.layer insertSublayer:gradient atIndex:0];
            
            continueButton.layer.borderWidth = 0;
            break;
        }
        default: {
            if (continueButton.enabled && (continueButton.highlighted || continueButton.selected)) {
                // Highlighted
                UIColor *color = [UIColor colorWithRed:68/255.0 green:131/255.0 blue:200/255.0 alpha:0.5];
                continueButton.backgroundColor = color;
                continueButton.layer.borderColor = [color CGColor];
            } else if(continueButton.enabled && !(continueButton.highlighted || continueButton.selected)) {
                // Normal
                UIColor *color = [UIColor colorWithRed:68/255.0 green:131/255.0 blue:200/255.0 alpha:1.0];
                continueButton.backgroundColor = color;
                continueButton.layer.borderColor = [color CGColor];
            } else {
                // Disabled
                UIColor *color = [UIColor colorWithRed:221/255.0 green:221/255.0 blue:221/255.0 alpha:1.0];
                continueButton.backgroundColor = [UIColor whiteColor];
                continueButton.layer.borderColor = [color CGColor];
            }
            [self updateTextForContinueButton:continueButton];
            break;
        }
    }
}

- (void)updateTextForContinueButton:(ORK1ContinueButton *)continueButton {
    switch (self.themeType) {
        case CEVRK1ThemeTypeAllOfUs: {
            if (!continueButton.titleLabel.text) {
                return;
            }
            
            UIColor *textColor = continueButton.isEnabled ? ORK1RGB(0x262262) : [self disabledTintColor];
            
            UIFont *fontToMakeBold = [ORK1ContinueButton defaultFont];
            NSDictionary *attributes = @{           NSFontAttributeName            : [UIFont boldSystemFontOfSize:fontToMakeBold.pointSize],
                                                    NSForegroundColorAttributeName : textColor,
                                                    NSKernAttributeName            : @(3)};  // 3 pts = 0.25 em
            NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:[continueButton.titleLabel.text uppercaseString] attributes:attributes];
            [continueButton setAttributedTitle:attributedString forState:UIControlStateNormal];
            break;
        }
        default: {
            UIFont *fontToMakeBold = [ORK1ContinueButton defaultFont];
            continueButton.titleLabel.font = [UIFont boldSystemFontOfSize:fontToMakeBold.pointSize];
            [continueButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [continueButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
            [continueButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
            [continueButton setTitleColor:[UIColor colorWithRed:153/255.0 green:153/255.0 blue:153/255.0 alpha:1.0] forState:UIControlStateDisabled];
            break;
        }
    }
}

@end
