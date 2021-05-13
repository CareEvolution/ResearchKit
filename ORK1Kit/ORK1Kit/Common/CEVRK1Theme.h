//
//  CEVRK1Theme.h
//  ORK1Kit
//
//  Created by Eric Schramm on 7/10/19.
//  Copyright © 2019 researchkit.org. All rights reserved.
//

@import UIKit;

#import <ORK1Kit/ORK1Defines.h>

typedef NS_ENUM(NSInteger, CEVRK1ThemeType) {
    CEVRK1ThemeTypeDefault,
    CEVRK1ThemeTypeAllOfUs
} ORK1_ENUM_AVAILABLE;

typedef NS_ENUM(NSInteger, CEVRK1TextTransform) {
    CEVRK1TextTransformUppercase,
    CEVRK1TextTransformLowercase
} ORK1_ENUM_AVAILABLE;

typedef NS_ENUM(NSInteger, CEVRK1GradientDirection) {
    CEVRK1GradientDirectionLeftToRight,
    CEVRK1GradientDirectionTopToBottom
} ORK1_ENUM_AVAILABLE;

typedef NS_ENUM(NSInteger, CEVRK1DisplayTextType) {
    CEVRK1DisplayTextTypeTitle,
    CEVRK1DisplayTextTypeText,
    CEVRK1DisplayTextTypeDetailText,
    CEVRK1DisplayTextTypeFootnote
};


@class ORK1BorderedButton;
@class ORK1ContinueButton;
@class ORK1TaskViewController;
@class CEVRK1Label;
@class CEVRK1TextView;


ORK1_CLASS_AVAILABLE
@interface CEVRK1Gradient : NSObject
@property (nonatomic, assign) CEVRK1GradientDirection direction;
@property (nonatomic, strong) UIColor * _Nonnull startColor;
@property (nonatomic, strong) UIColor * _Nonnull endColor;
@end


ORK1_CLASS_AVAILABLE
@interface CEVRK1TextStyle : NSObject
@property (nonatomic, strong, nullable) NSNumber *fontSize;
@property (nonatomic, strong, nullable) NSNumber *fontWeight;
@property (nonatomic, strong, nullable) UIColor *color;
@property (nonatomic, strong, nullable) NSNumber *alignment;
@end


ORK1_CLASS_AVAILABLE
@interface CEVRK1Theme : NSObject
+ (nonnull CEVRK1Theme *)themeByOverridingTheme:(nullable CEVRK1Theme *)theme1 withTheme:(nullable CEVRK1Theme *)theme2; // properties from theme2 take priority over theme1
+ (nonnull instancetype)themeForElement:(nonnull id)element;
+ (nullable ORK1TaskViewController *)fallbackTaskViewController;
+ (void)setFallbackTaskViewController:(nullable ORK1TaskViewController *)taskViewController;
- (nonnull instancetype)initWithType:(CEVRK1ThemeType)type;

@property (nonatomic, strong) UIColor * _Nullable tintColor;

@property (nonatomic, strong, nullable) CEVRK1TextStyle *titleStyle;
@property (nonatomic, strong, nullable) CEVRK1TextStyle *textStyle;
@property (nonatomic, strong, nullable) CEVRK1TextStyle *detailTextStyle;
@property (nonatomic, strong, nullable) CEVRK1TextStyle *footnoteTextStyle;

@property (nonatomic, strong) UIColor * _Nullable nextButtonBackgroundColor;
@property (nonatomic, strong) CEVRK1Gradient * _Nullable nextButtonBackgroundGradient;
@property (nonatomic, strong) NSNumber * _Nullable nextButtonFontWeight; // UIFontWeight
@property (nonatomic, strong) NSNumber * _Nullable nextButtonTextTransform; // CEVRK1TextTransform
@property (nonatomic, strong) NSNumber * _Nullable nextButtonLetterSpacing; // in points
@property (nonatomic, strong) UIColor * _Nullable nextButtonTextColor;

@property (nonatomic, strong) UIColor * _Nullable progressBarColor;

- (void)updateAppearanceForLabel:(nonnull CEVRK1Label *)label ofType:(CEVRK1DisplayTextType)textType;
- (void)updateAppearanceForTextView:(nonnull CEVRK1TextView *)textView;
+ (void)renderMarkdownForLabel:(nonnull CEVRK1Label *)label;

- (void)updateAppearanceForContinueButton:(nonnull ORK1ContinueButton *)continueButton;

- (nullable UIColor *)taskViewControllerTintColor;
- (nullable NSNumber *)navigationContrainerViewButtonConstraintFromContinueButton;
@end


@protocol CEVRK1ThemedUIElement <NSObject>

/**
 Stores a theme for UI styling.
 
 Any UIElement that can be in the responder chain can conform to this protocol
 and provide a theme for UI customization. Useful for UI elements that are
 ORK1Kit objects or subclasses thereof that may be used outside of standard
 ORK1Kit view hieararchy.
 */

@property (nonatomic, retain, nullable) CEVRK1Theme *cev_theme;

@end
