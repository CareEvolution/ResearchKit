//
//  CEVRKTheme.h
//  ResearchKit
//
//  Created by Eric Schramm on 7/10/19.
//  Copyright © 2019 researchkit.org. All rights reserved.
//

@import UIKit;

#import "RK1Defines.h"

extern NSNotificationName _Nonnull const CEVRK1StepViewControllerViewWillAppearNotification;
extern NSString * _Nonnull const CEVRKThemeKey;

typedef NS_ENUM(NSInteger, CEVRKThemeType) {
    CEVRKThemeTypeDefault,
    CEVRKThemeTypeAllOfUs
} RK1_ENUM_AVAILABLE;


@class RK1BorderedButton;
@class RK1ContinueButton;

RK1_CLASS_AVAILABLE
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
- (void)updateAppearanceForContinueButton:(nonnull RK1ContinueButton *)continueButton;
- (void)updateTextForContinueButton:(nonnull RK1ContinueButton *)continueButton;

@end


@protocol CEVRKThemedUIElement <NSObject>

/**
 Stores a theme for UI styling.
 
 Any UIElement that can be in the responder chain can conform to this protocol
 and provide a theme for UI customization. Useful for UI elements that are
 ResearchKit objects or subclasses thereof that may be used outside of standard
 ResearchKit view hieararchy.
 */

@property (nonatomic, retain, nullable) CEVRKTheme *cev_theme;

@end
