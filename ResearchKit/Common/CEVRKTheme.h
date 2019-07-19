//
//  CEVRKTheme.h
//  ResearchKit
//
//  Created by Eric Schramm on 7/10/19.
//  Copyright © 2019 researchkit.org. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSInteger, CEVRKThemeType) {
    CEVRKThemeTypeDefault,
    CEVRKThemeTypeAllOfUs
} ORK_ENUM_AVAILABLE;


@class ORKBorderedButton;
@class ORKContinueButton;

@interface CEVRKTheme : NSObject

- (nonnull instancetype)init NS_UNAVAILABLE;
+ (nonnull instancetype)initWithType:(CEVRKThemeType)type;
+ (nonnull instancetype)defaultTheme;
+ (nonnull instancetype)themeForView:(nonnull UIView *)view;

- (nullable UIFont *)headlineLabelFontWithSize:(CGFloat)fontSize;
- (nullable UIColor *)headlineLabelFontColor;
- (nullable UIColor *)taskViewControllerTintColor;
- (nullable NSNumber *)navigationContrainerViewButtonConstraintFromContinueButton;
- (nullable NSNumber *)continueButtonHeightForTextSize:(CGSize)textSize;
- (nullable NSNumber *)continueButtonWidthForWindowWidth:(CGFloat)windowWidth;
- (nullable UIColor *)disabledTintColor;
- (void)updateAppearanceForContinueButton:(nonnull ORKContinueButton *)continueButton;
- (void)updateTextForContinueButton:(nonnull ORKContinueButton *)continueButton;

@end
