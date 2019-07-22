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
- (nonnull instancetype)initWithType:(CEVRKThemeType)type;
+ (nonnull instancetype)defaultTheme;
+ (nonnull instancetype)themeForElement:(nonnull id)element;

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


@protocol CEVRKThemedUIElement <NSObject>

/**
 Returns a theme for UI styling.
 
 Any UIElement that can be in the responder chain can conform to this protocol
 and provide a theme for UI customization. Useful for UI elements that are
 ResearchKit objects or subclasses thereof that may be used outside of standard
 ResearchKit view hieararchy.
 
 @return Theme for UI styling.
 */

- (nonnull CEVRKTheme *)theme;

@end
