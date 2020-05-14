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
#import "ORK1Step.h"

@interface UIColor (LightAndDark)
- (UIColor *)lighterColor;
- (UIColor *)darkerColor;
@end

NSString *const CEVThemeAttributeName = @"CEVThemeAttributeName";
NSString *const CEVRK1ThemeKey = @"cev_theme";

@implementation CEVRK1Gradient

- (instancetype)init {
    if ((self = [super init])) {
        self.direction = CEVRK1GradientDirectionTopToBottom;
        self.startColor = [UIColor clearColor];
        self.endColor = [UIColor clearColor];
    }
    return self;
}

@end

@implementation CEVRK1Theme

+ (CEVRK1Theme *)themeByOverridingTheme:(nullable CEVRK1Theme *)theme withTheme:(nullable CEVRK1Theme *)theme2 {
    CEVRK1Theme *merged = [[CEVRK1Theme alloc] init];
    merged.tintColor = theme2.tintColor ?: theme.tintColor;

    merged.titleFontSize = theme2.titleFontSize ?: theme.titleFontSize;
    merged.titleFontWeight = theme2.titleFontWeight ?: theme.titleFontWeight;
    merged.titleColor = theme2.titleColor ?: theme.titleColor;
    merged.titleAlignment = theme2.titleAlignment ?: theme.titleAlignment;

    merged.textFontSize = theme2.textFontSize ?: theme.textFontSize;
    merged.textFontWeight = theme2.textFontWeight ?: theme.textFontWeight;
    merged.textColor = theme2.textColor ?: theme.textColor;
    merged.textAlignment = theme2.textAlignment ?: theme.textAlignment;

    merged.detailTextFontSize = theme2.detailTextFontSize ?: theme.detailTextFontSize;
    merged.detailTextFontWeight = theme2.detailTextFontWeight ?: theme.detailTextFontWeight;
    merged.detailTextColor = theme2.detailTextColor ?: theme.detailTextColor;
    merged.detailTextAlignment = theme2.detailTextAlignment ?: theme.detailTextAlignment;

    merged.nextButtonBackgroundColor = theme2.nextButtonBackgroundColor ?: theme.nextButtonBackgroundColor;
    merged.nextButtonBackgroundGradient = theme2.nextButtonBackgroundGradient ?: theme.nextButtonBackgroundGradient;
    merged.nextButtonFontWeight = theme2.nextButtonFontWeight ?: theme.nextButtonFontWeight;
    merged.nextButtonTextTransform = theme2.nextButtonTextTransform ?: theme.nextButtonTextTransform;
    merged.nextButtonLetterSpacing = theme2.nextButtonLetterSpacing ?: theme.nextButtonLetterSpacing;
    merged.nextButtonTextColor = theme2.nextButtonTextColor ?: theme.nextButtonTextColor;
    return merged;
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
        CEVRK1Theme *taskTheme = task.cev_theme;
        CEVRK1Theme *stepTheme = ((ORK1StepViewController *)element).step.cev_theme;
        return [CEVRK1Theme themeByOverridingTheme:taskTheme withTheme:stepTheme];
    } else if ([element respondsToSelector:@selector(nextResponder)] && [element nextResponder]) {                // continue up responder chain
        id nextResponder = [element nextResponder];
        return [CEVRK1Theme themeForElement:nextResponder];
    } else if ([element respondsToSelector:@selector(parentViewController)] && [element parentViewController]) {  // if has parentViewController, try that route
        UIViewController *parentViewController = [element parentViewController];
        return [CEVRK1Theme themeForElement:parentViewController];
    } else if (sFallbackTaskViewController != nil) {                                                              // if has fallback, try fallback
        CEVRK1Theme *taskTheme = sFallbackTaskViewController.task.cev_theme;
        CEVRK1Theme *stepTheme = sFallbackTaskViewController.currentStepViewController.step.cev_theme;
        return [CEVRK1Theme themeByOverridingTheme:taskTheme withTheme:stepTheme];
    } else {                                                                                                      // has reached end of chain or not in chain
        return [[CEVRK1Theme alloc] init];
    }
}

__weak static ORK1TaskViewController *sFallbackTaskViewController = nil;

+ (nullable ORK1TaskViewController *)fallbackTaskViewController {
    return sFallbackTaskViewController;
}

+ (void)setFallbackTaskViewController:(nullable ORK1TaskViewController *)taskViewController {
    sFallbackTaskViewController = taskViewController;
}

- (instancetype)initWithType:(CEVRK1ThemeType)type {
    if (self = [super init]) {
        if (type == CEVRK1ThemeTypeAllOfUs) {
            self.tintColor = ORK1RGB(0x216fb4);
            self.titleColor = ORK1RGB(0x262262);
            self.titleFontWeight = @(UIFontWeightSemibold);
            self.nextButtonTextColor = ORK1RGB(0x262262);
            self.nextButtonFontWeight = @(UIFontWeightSemibold);
            self.nextButtonLetterSpacing = @3;
            self.nextButtonTextTransform = @(CEVRK1TextTransformUppercase);
            self.nextButtonBackgroundGradient = [[CEVRK1Gradient alloc] init];
            self.nextButtonBackgroundGradient.direction = CEVRK1GradientDirectionLeftToRight;
            self.nextButtonBackgroundGradient.startColor = ORK1RGB(0xf38d7a);
            self.nextButtonBackgroundGradient.endColor = ORK1RGB(0xf8c954);
        }        
        return self;
    }
    return nil;
}

- (void)updateAppearanceForTitleLabel:(nonnull UILabel *)label {
    // If we have styled this, don't override
    if (label.attributedText.length > 0 && [label.attributedText attribute:CEVThemeAttributeName atIndex:0 effectiveRange:0] != nil) {
        return;
    }
    if (self.titleColor != nil) {
        label.textColor = self.titleColor;
    }
    if (self.titleAlignment != nil) {
        label.textAlignment = self.titleAlignment.intValue;
    }
    if (self.titleFontSize != nil) {
        label.font = [UIFont systemFontOfSize:self.titleFontSize.floatValue weight:UIFontWeightRegular];
    }
    if (self.titleFontWeight != nil) {
        label.font = [UIFont systemFontOfSize:label.font.pointSize weight:self.titleFontWeight.floatValue];
    }
}

- (void)updateAppearanceForTextLabel:(nonnull UILabel *)label {
    // If we have styled this, don't override
    if (label.attributedText.length > 0 && [label.attributedText attribute:CEVThemeAttributeName atIndex:0 effectiveRange:0] != nil) {
        return;
    }
    if (self.textColor != nil) {
        label.textColor = self.textColor;
    }
    if (self.textAlignment != nil) {
        label.textAlignment = self.textAlignment.intValue;
    }
    if (self.textFontSize != nil) {
        label.font = [UIFont systemFontOfSize:self.textFontSize.floatValue weight:UIFontWeightRegular];
    }
    if (self.textFontWeight != nil) {
        label.font = [UIFont systemFontOfSize:label.font.pointSize weight:self.textFontWeight.floatValue];
    }
}

- (void)updateAttributesForText:(NSMutableDictionary *)attributes {
    if (self.textColor != nil) {
        attributes[NSForegroundColorAttributeName] = self.textColor;
    }
    if (self.textAlignment != nil) {
        NSMutableParagraphStyle *paragraphStyle = [attributes[NSParagraphStyleAttributeName] mutableCopy];
        if (paragraphStyle == nil) {
            paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        }
        paragraphStyle.alignment = self.textAlignment.intValue;
        attributes[NSParagraphStyleAttributeName] = paragraphStyle;
    }
    if (self.textFontSize != nil && self.textFontWeight != nil) {
        attributes[NSFontAttributeName] = [UIFont systemFontOfSize:self.textFontSize.floatValue weight: self.textFontWeight.floatValue];
    } else if (self.textFontSize != nil) {
        attributes[NSFontAttributeName] = [UIFont systemFontOfSize:self.textFontSize.floatValue weight:UIFontWeightRegular];
    } else if (self.textFontWeight != nil) {
        attributes[NSFontAttributeName] = [UIFont systemFontOfSize:15 weight:self.textFontWeight.floatValue];
    }
    attributes[CEVThemeAttributeName] = @0; // Flag that we have styled this string.
}

- (void)updateAttributesForDetailText:(NSMutableDictionary *)attributes {
    if (self.detailTextColor != nil) {
        attributes[NSForegroundColorAttributeName] = self.detailTextColor;
    }
    if (self.detailTextAlignment != nil) {
        NSMutableParagraphStyle *paragraphStyle = [attributes[NSParagraphStyleAttributeName] mutableCopy];
        if (paragraphStyle == nil) {
            paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        }
        paragraphStyle.alignment = self.detailTextAlignment.intValue;
        attributes[NSParagraphStyleAttributeName] = paragraphStyle;
    }
    if (self.detailTextFontSize != nil && self.detailTextFontWeight != nil) {
        attributes[NSFontAttributeName] = [UIFont systemFontOfSize:self.detailTextFontSize.floatValue weight: self.detailTextFontWeight.floatValue];
    } else if (self.detailTextFontSize != nil) {
        attributes[NSFontAttributeName] = [UIFont systemFontOfSize:self.detailTextFontSize.floatValue weight:UIFontWeightRegular];
    } else if (self.detailTextFontWeight != nil) {
        attributes[NSFontAttributeName] = [UIFont systemFontOfSize:15 weight:self.detailTextFontWeight.floatValue];
    }
    attributes[CEVThemeAttributeName] = @0; // Flag that we have styled this string.
}

- (void)updateAppearanceForContinueButton:(ORK1ContinueButton *)continueButton {
    // remove any previous gradient layers if button resizes due to state changes
    for (NSInteger layerIndex = continueButton.layer.sublayers.count - 1; layerIndex >= 0; layerIndex --) {
        CALayer *layer = continueButton.layer.sublayers[layerIndex];
        if ([layer isKindOfClass:[CAGradientLayer class]]) {
            [layer removeFromSuperlayer];
        }
    }
    
    // Configure gradient
    CEVRK1GradientDirection gradientDirection = CEVRK1GradientDirectionLeftToRight;
    UIColor *startColor = [UIColor colorWithRed:68/255.0 green:131/255.0 blue:200/255.0 alpha:1.0];
    UIColor *endColor = startColor;
    if (self.nextButtonBackgroundColor != nil) {
        startColor = self.nextButtonBackgroundColor;
        endColor = self.nextButtonBackgroundColor;
    }
    if (self.nextButtonBackgroundGradient != nil) {
        gradientDirection = self.nextButtonBackgroundGradient.direction;
        startColor = self.nextButtonBackgroundGradient.startColor;
        endColor = self.nextButtonBackgroundGradient.endColor;
    }
    
    UIColor *borderColor = nil;
    CGFloat borderWidth = 0;
    CAGradientLayer *gradient = [[CAGradientLayer alloc] init];
    gradient.frame = continueButton.bounds;
    if (!continueButton.enabled) {
        UIColor *disabledColor = [UIColor whiteColor];
        gradient.colors = @[(id)disabledColor.CGColor, (id)disabledColor.CGColor];
        borderWidth = 1;
        borderColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    } else if (continueButton.highlighted || continueButton.selected) {
        gradient.colors = @[(id)startColor.darkerColor.CGColor, (id)endColor.darkerColor.CGColor];
    } else {
        gradient.colors = @[(id)startColor.CGColor, (id)endColor.CGColor];
    }
    if (gradientDirection == CEVRK1GradientDirectionLeftToRight) {
        gradient.startPoint = CGPointMake(0, 0);
        gradient.endPoint = CGPointMake(1, 0);
    } else {
        gradient.startPoint = CGPointMake(0, 0);
        gradient.endPoint = CGPointMake(0, 1);
    }
    gradient.cornerRadius = 5.0f;
    gradient.borderWidth = borderWidth;
    gradient.borderColor = borderColor.CGColor;
    [continueButton.layer insertSublayer:gradient atIndex:0];
    continueButton.layer.borderWidth = 0;

    // Configure title
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    
    UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleHeadline];
    UIFont *font = [UIFont systemFontOfSize:[[descriptor objectForKey: UIFontDescriptorSizeAttribute] doubleValue] weight:UIFontWeightSemibold];
    if (self.nextButtonFontWeight != nil) {
        font = [UIFont systemFontOfSize:font.pointSize weight:self.nextButtonFontWeight.floatValue];
    }
    attributes[NSFontAttributeName] = font;
    
    UIColor *textColor = [UIColor whiteColor];
    if (self.nextButtonTextColor != nil) {
        textColor = self.nextButtonTextColor;
    }
    if (!continueButton.isEnabled) {
        textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    }
    attributes[NSForegroundColorAttributeName] = textColor;
    
    if (self.nextButtonLetterSpacing != nil) {
        attributes[NSKernAttributeName] = self.nextButtonLetterSpacing;
    }
    
    NSString *text = [continueButton titleForState:UIControlStateNormal];
    if (self.nextButtonTextTransform != nil) {
        switch ((CEVRK1TextTransform)self.nextButtonTextTransform.integerValue) {
        case CEVRK1TextTransformUppercase:
            text = text.uppercaseString;
            break;
        case CEVRK1TextTransformLowercase:
            text = text.lowercaseString;
            break;
        }
    }
    if (text != nil) {
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:text attributes:attributes];
        [continueButton setAttributedTitle:attributedString forState:UIControlStateNormal];
    }
    
    continueButton.heightConstraint.constant = font.pointSize + (16 * 2);  // padding of 16
    continueButton.widthConstraint.constant = continueButton.window.frame.size.width - (20 * 2); // width 100 % minus system padding
}

- (UIColor *)taskViewControllerTintColor {
    return self.tintColor;
}

- (NSNumber *)navigationContrainerViewButtonConstraintFromContinueButton {
    // extends the difference between the standard and custom button size since
    // we need to allow for room for the skip button to show below the continue button
    return @(44 - 52);
}

@end

// https://stackoverflow.com/a/11598127
@implementation UIColor (LightAndDark)

- (UIColor *)lighterColor
{
    CGFloat h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:s
                          brightness:MIN(b * 1.3, 1.0)
                               alpha:a];
    return nil;
}

- (UIColor *)darkerColor
{
    CGFloat h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:s
                          brightness:b * 0.75
                               alpha:a];
    return nil;
}
@end
