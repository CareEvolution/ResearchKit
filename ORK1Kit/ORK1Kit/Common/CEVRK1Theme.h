//
//  CEVRK1Theme.h
//  ORK1Kit
//
//  Created by Eric Schramm on 7/10/19.
//  Copyright © 2019 researchkit.org. All rights reserved.
//

@import UIKit;
@class ORK1TaskViewController;

#import "ORK1Defines.h"

extern NSString * _Nonnull const CEVRK1ThemeKey;
extern NSString * _Nonnull const CEVThemeAttributeName;

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

@class ORK1BorderedButton;
@class ORK1ContinueButton;

ORK1_CLASS_AVAILABLE
@interface CEVRK1Gradient : NSObject
@property (nonatomic, assign) CEVRK1GradientDirection direction;
@property (nonatomic, strong) UIColor * _Nonnull startColor;
@property (nonatomic, strong) UIColor * _Nonnull endColor;
@end

ORK1_CLASS_AVAILABLE
@interface CEVRK1Theme : NSObject
+ (nonnull CEVRK1Theme *)themeByOverridingTheme:(nullable CEVRK1Theme *)theme1 withTheme:(nullable CEVRK1Theme *)theme2; // properties from theme2 take priority over theme1
+ (nonnull instancetype)themeForElement:(nonnull id)element;
+ (nullable ORK1TaskViewController *)fallbackTaskViewController;
+ (void)setFallbackTaskViewController:(nullable ORK1TaskViewController *)taskViewController;
- (nonnull instancetype)initWithType:(CEVRK1ThemeType)type;

@property (nonatomic, strong) UIColor * _Nullable tintColor;

@property (nonatomic, strong) NSNumber * _Nullable titleFontSize;
@property (nonatomic, strong) NSNumber * _Nullable titleFontWeight; // UIFontWeight
@property (nonatomic, strong) UIColor * _Nullable titleColor;
@property (nonatomic, strong) NSNumber * _Nullable titleAlignment; // NSTextAlignment

@property (nonatomic, strong) NSNumber * _Nullable textFontSize;
@property (nonatomic, strong) NSNumber * _Nullable textFontWeight; // UIFontWeight
@property (nonatomic, strong) UIColor * _Nullable textColor;
@property (nonatomic, strong) NSNumber * _Nullable textAlignment; // NSTextAlignment

@property (nonatomic, strong) NSNumber * _Nullable detailTextFontSize;
@property (nonatomic, strong) NSNumber * _Nullable detailTextFontWeight; // UIFontWeight
@property (nonatomic, strong) UIColor * _Nullable detailTextColor;
@property (nonatomic, strong) NSNumber * _Nullable detailTextAlignment; // NSTextAlignment

@property (nonatomic, strong) UIColor * _Nullable nextButtonBackgroundColor;
@property (nonatomic, strong) CEVRK1Gradient * _Nullable nextButtonBackgroundGradient;
@property (nonatomic, strong) NSNumber * _Nullable nextButtonFontWeight; // UIFontWeight
@property (nonatomic, strong) NSNumber * _Nullable nextButtonTextTransform; // CEVRK1TextTransform
@property (nonatomic, strong) NSNumber * _Nullable nextButtonLetterSpacing; // in points
@property (nonatomic, strong) UIColor * _Nullable nextButtonTextColor;

- (void)updateAppearanceForTitleLabel:(nonnull UILabel *)label;
- (void)updateAppearanceForTextLabel:(nonnull UILabel *)label;
- (void)updateAttributesForText:(nonnull NSMutableDictionary *)attributes;
- (void)updateAttributesForDetailText:(nonnull NSMutableDictionary *)attributes;
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
