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
#import "NSAttributedString+Markdown.h"
#import "ORK1Label.h"
#import "CEVRK1TextView.h"


@interface UIFont (Scalable)
+ (NSDictionary *)cevrk1_textStyleToPointSize;
+ (UIFont *)cevrk1_preferredFontOfSize:(CGFloat)size weight:(UIFontWeight)weight;
@end


@interface UIColor (LightAndDark)
- (UIColor *)cevrk1_darkerColor;
@end


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

                     
@implementation CEVRK1TextStyle
@end


@implementation CEVRK1Theme

+ (CEVRK1Theme *)themeByOverridingTheme:(nullable CEVRK1Theme *)theme withTheme:(nullable CEVRK1Theme *)theme2 {
    CEVRK1Theme *merged = [[CEVRK1Theme alloc] init];
    merged.tintColor = theme2.tintColor ?: theme.tintColor;
    
    merged.titleStyle = [CEVRK1Theme textStyleByOverridingTextStyle:theme.titleStyle withTextStyle:theme2.titleStyle];
    merged.textStyle = [CEVRK1Theme textStyleByOverridingTextStyle:theme.textStyle withTextStyle:theme2.textStyle];
    merged.detailTextStyle = [CEVRK1Theme textStyleByOverridingTextStyle:theme.detailTextStyle withTextStyle:theme2.detailTextStyle];

    merged.nextButtonBackgroundColor = theme2.nextButtonBackgroundColor ?: theme.nextButtonBackgroundColor;
    merged.nextButtonBackgroundGradient = theme2.nextButtonBackgroundGradient ?: theme.nextButtonBackgroundGradient;
    merged.nextButtonFontWeight = theme2.nextButtonFontWeight ?: theme.nextButtonFontWeight;
    merged.nextButtonTextTransform = theme2.nextButtonTextTransform ?: theme.nextButtonTextTransform;
    merged.nextButtonLetterSpacing = theme2.nextButtonLetterSpacing ?: theme.nextButtonLetterSpacing;
    merged.nextButtonTextColor = theme2.nextButtonTextColor ?: theme.nextButtonTextColor;
    
    merged.progressBarColor = theme2.progressBarColor ?: theme.progressBarColor;
    
    return merged;
}

+ (CEVRK1TextStyle *)textStyleByOverridingTextStyle:(nullable CEVRK1TextStyle*)textStyle withTextStyle:(nullable CEVRK1TextStyle*)textStyle2 {
    CEVRK1TextStyle *merged = [[CEVRK1TextStyle alloc] init];
    merged.fontSize   = textStyle2.fontSize   ?: textStyle.fontSize;
    merged.fontWeight = textStyle2.fontWeight ?: textStyle.fontWeight;
    merged.color      = textStyle2.color      ?: textStyle.color;
    merged.alignment  = textStyle2.alignment  ?: textStyle.alignment;
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
            self.titleStyle = [[CEVRK1TextStyle alloc] init];
            self.titleStyle.color = ORK1RGB(0x262262);
            self.titleStyle.fontWeight = @(UIFontWeightSemibold);
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

- (NSMutableDictionary *)textAttributesForView:(UIView *)view {
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    if (!paragraphStyle) {
        paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    }
    if ([[view class] isSubclassOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        attributes[NSFontAttributeName] = label.font;
        attributes[NSForegroundColorAttributeName] = label.textColor;
        paragraphStyle.alignment = label.textAlignment;
        attributes[NSParagraphStyleAttributeName] = paragraphStyle;
    } else if ([[view class] isSubclassOfClass:[UITextView class]]) {
        UITextView *textView = (UITextView *)view;
        attributes[NSFontAttributeName] = textView.font;
        attributes[NSForegroundColorAttributeName] = textView.textColor;
        paragraphStyle.alignment = textView.textAlignment;
        attributes[NSParagraphStyleAttributeName] = paragraphStyle;
    } else {
        NSAssert(YES, @"textAttributesForView expects either a UILabel or UITextView");
    }
    return attributes;
}

- (void)updateAppearanceForLabel:(CEVRK1Label *)label ofType:(CEVRK1DisplayTextType)textType {
    if (![label rawText]) {
        label.attributedText = nil;
        return;
    }
    CEVRK1TextStyle *textStyle;
    switch (textType) {
        case CEVRK1DisplayTextTypeTitle: {
            textStyle = self.titleStyle;
            break;
        }
        case CEVRK1DisplayTextTypeText: {
            textStyle = self.textStyle;
            break;
        }
        case CEVRK1DisplayTextTypeDetailText: {
            NSAssert(YES, @"DetailText should be handled in updateAppearanceForTextView");
            break;
        }
        default:
            break;
    }
    NSMutableDictionary *attributes = [self textAttributesForView:label];
    [self combineIntoAttributes:attributes textStyle:textStyle];
    label.attributedText = [[NSAttributedString alloc] initWithMarkdownRepresentation:[label rawText] attributes:attributes];
}

- (void)updateAppearanceForTextView:(nonnull CEVRK1TextView *)textView {   
    if (!textView.textValue && !textView.detailTextValue) {
        textView.attributedText = nil;
        return;
    }
    
    NSMutableAttributedString *attributedInstruction;
    NSMutableDictionary *textViewAttributes = [self textAttributesForView:textView];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setParagraphSpacingBefore:textView.font.lineHeight * 0.5];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    
    
    if (textView.detailTextValue && textView.textValue) {
        NSMutableDictionary *textAttributes = [textViewAttributes mutableCopy];
        [self updateAttributes:textAttributes forDisplayTextType:CEVRK1DisplayTextTypeText];
        NSString *concatenatedString = [NSString stringWithFormat:@"%@\n", textView.textValue];
        attributedInstruction = [[[NSAttributedString alloc] initWithMarkdownRepresentation:concatenatedString attributes:textAttributes] mutableCopy];
        
        NSMutableDictionary *detailAttributes = [textViewAttributes mutableCopy];
        detailAttributes[NSParagraphStyleAttributeName] = paragraphStyle;
        [self updateAttributes:detailAttributes forDisplayTextType:CEVRK1DisplayTextTypeDetailText];
        NSAttributedString *detailAttributedString = [[NSAttributedString alloc] initWithMarkdownRepresentation:textView.detailTextValue attributes:detailAttributes];
        [attributedInstruction appendAttributedString:detailAttributedString];
        
    } else if (textView.detailTextValue || textView.textValue) {
        textViewAttributes[NSParagraphStyleAttributeName] = paragraphStyle;
        if (textView.detailTextValue) {
            [self updateAttributes:textViewAttributes forDisplayTextType:CEVRK1DisplayTextTypeDetailText];
        } else {
            [self updateAttributes:textViewAttributes forDisplayTextType:CEVRK1DisplayTextTypeText];
        }
        attributedInstruction = [[[NSAttributedString alloc] initWithMarkdownRepresentation:textView.detailTextValue ?: textView.textValue attributes: textViewAttributes] mutableCopy];
    }

    textView.attributedText = attributedInstruction;
}

- (void)updateAttributes:(NSMutableDictionary *)attributes forDisplayTextType:(CEVRK1DisplayTextType)textType {
    CEVRK1TextStyle *textStyle;
    switch (textType) {
        case CEVRK1DisplayTextTypeTitle: {
            NSAssert(YES, @"Title text should be handled in updateAppearanceForLabel");
            break;
        }
        case CEVRK1DisplayTextTypeText: {
            textStyle = self.textStyle;
            break;
        }
        case CEVRK1DisplayTextTypeDetailText: {
            textStyle = self.detailTextStyle;
            break;
        }
        default:
            break;
    }
    [self combineIntoAttributes:attributes textStyle:textStyle];
}

- (void)combineIntoAttributes:(NSMutableDictionary *)attributes textStyle:(CEVRK1TextStyle *)textStyle {
    if (textStyle.fontSize && textStyle.fontWeight) {
        attributes[NSFontAttributeName] = [UIFont cevrk1_preferredFontOfSize:textStyle.fontSize.floatValue weight:textStyle.fontWeight.floatValue];
    } else if (textStyle.fontSize) {
        attributes[NSFontAttributeName] = [UIFont cevrk1_preferredFontOfSize:textStyle.fontSize.floatValue weight:UIFontWeightRegular];
    } else if (textStyle.fontWeight) {
        CGFloat currentFontSize = ((UIFont *)attributes[NSFontAttributeName]).pointSize;
        attributes[NSFontAttributeName] = [UIFont cevrk1_preferredFontOfSize:currentFontSize weight:textStyle.fontWeight.floatValue];
    }
    
    if (textStyle.color) {
        attributes[NSForegroundColorAttributeName] = textStyle.color;
    }
    
    if (textStyle.alignment) {
        NSMutableParagraphStyle *paragraphStyle = [attributes[NSParagraphStyleAttributeName] mutableCopy];
        if (paragraphStyle == nil) {
            paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        }
        paragraphStyle.alignment = textStyle.alignment.intValue;
        attributes[NSParagraphStyleAttributeName] = paragraphStyle;
    }
}

// Currently used for text choices which currently do not have style overrides
+ (void)renderMarkdownForLabel:(nonnull CEVRK1Label *)label {
    if ([label rawText]) {
        NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
        attributes[NSForegroundColorAttributeName] = label.textColor;
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        if (paragraphStyle == nil) {
            paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        }
        paragraphStyle.alignment = label.textAlignment;
        attributes[NSParagraphStyleAttributeName] = paragraphStyle;
        attributes[NSFontAttributeName] = label.font;
        label.attributedText = [[NSAttributedString alloc] initWithMarkdownRepresentation:[label rawText] attributes:attributes];
    } else {
        label.attributedText = nil;
    }
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
        gradient.colors = @[(id)startColor.cevrk1_darkerColor.CGColor, (id)endColor.cevrk1_darkerColor.CGColor];
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
    CGFloat fontSize = [[descriptor objectForKey: UIFontDescriptorSizeAttribute] doubleValue];
    UIFont *font = [UIFont cevrk1_preferredFontOfSize:fontSize weight:UIFontWeightSemibold];
    if (self.nextButtonFontWeight != nil) {
        font = [UIFont cevrk1_preferredFontOfSize:fontSize weight:self.nextButtonFontWeight.floatValue];
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

- (UIColor *)cevrk1_darkerColor
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

@implementation UIFont (Scalable)

+ (NSDictionary *)cevrk1_textStyleToPointSize {
    NSMutableDictionary *dict = [@{
        UIFontTextStyleTitle1: @28,
        UIFontTextStyleTitle2: @22,
        UIFontTextStyleTitle3: @20,
        UIFontTextStyleHeadline: @17,
        UIFontTextStyleBody: @17,
        UIFontTextStyleCallout: @16,
        UIFontTextStyleSubheadline: @15,
        UIFontTextStyleFootnote: @13,
        UIFontTextStyleCaption1: @12,
        UIFontTextStyleCaption2: @11,
    } mutableCopy];
    if (@available(iOS 11.0, *)) {
        dict[UIFontTextStyleLargeTitle] = @34;
    }
    return dict;
}

+ (UIFont *)cevrk1_preferredFontOfSize:(CGFloat)size weight:(UIFontWeight)weight {
    if (@available(iOS 11.0, *)) {
        // Find closest style to the given size
        NSString *style = UIFontTextStyleBody;
        CGFloat diff = fabs(size - 17);
        for (NSString *i in [UIFont cevrk1_textStyleToPointSize].allKeys) {
            NSString *currStyle = i;
            CGFloat currSize = ((NSNumber *)[UIFont cevrk1_textStyleToPointSize][i]).floatValue;
            CGFloat currDiff = fabs(currSize - size);
            if (currDiff < diff) {
                diff = currDiff;
                style = currStyle;
            }
        }

        UIFont *font = [UIFont systemFontOfSize:size weight:weight];
        return [[UIFontMetrics metricsForTextStyle:style] scaledFontForFont:font];
    } else {
        return [UIFont systemFontOfSize:size weight:weight];
    }
}

@end
