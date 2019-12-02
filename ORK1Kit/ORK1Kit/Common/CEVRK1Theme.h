//
//  CEVRK1Theme.h
//  ORK1Kit
//
//  Created by Eric Schramm on 7/10/19.
//  Copyright © 2019 researchkit.org. All rights reserved.
//

@import UIKit;

#import "ORK1Defines.h"

extern NSNotificationName _Nonnull const CEVORK1StepViewControllerViewWillAppearNotification;
extern NSString * _Nonnull const CEVRK1ThemeKey;

typedef NS_ENUM(NSInteger, CEVRK1ThemeType) {
    CEVRK1ThemeTypeDefault,
    CEVRK1ThemeTypeAllOfUs
} ORK1_ENUM_AVAILABLE;


@class ORK1BorderedButton;
@class ORK1ContinueButton;

ORK1_CLASS_AVAILABLE
@interface CEVRK1Theme : NSObject

- (nonnull instancetype)init NS_UNAVAILABLE;
- (nonnull instancetype)initWithType:(CEVRK1ThemeType)type;
+ (nonnull instancetype)defaultTheme;
+ (nonnull instancetype)themeForElement:(nonnull id)element;

- (nullable UIFont *)headlineLabelFontWithSize:(CGFloat)fontSize;
- (nullable UIColor *)headlineLabelFontColor;
- (nullable UIColor *)taskViewControllerTintColor;
- (nullable NSNumber *)navigationContrainerViewButtonConstraintFromContinueButton;
- (nullable NSNumber *)continueButtonHeightForTextSize:(CGSize)textSize;
- (nullable NSNumber *)continueButtonWidthForWindowWidth:(CGFloat)windowWidth;
- (nullable UIColor *)disabledTintColor;
- (void)updateAppearanceForContinueButton:(nonnull ORK1ContinueButton *)continueButton;
- (void)updateTextForContinueButton:(nonnull ORK1ContinueButton *)continueButton;

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
