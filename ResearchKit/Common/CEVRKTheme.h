//
//  CEVRKTheme.h
//  ResearchKit
//
//  Created by Eric Schramm on 7/10/19.
//  Copyright © 2019 researchkit.org. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface CEVRKGradientAnchor : NSObject

@property (nonatomic, assign) NSString *gradientHexColor;
@property (nonatomic, assign) CGFloat location;

- (instancetype)initWithGradientHexColor:(NSString *)gradientHexColor location:(CGFloat)location;
- (UIColor *)colorForAnchorHex;

@end


@interface CEVRKGradient : NSObject

@property (nonatomic, assign) UILayoutConstraintAxis axis;
@property (nonatomic, retain) NSArray<CEVRKGradientAnchor *> *grandientAnchors;

- (instancetype)initWithAxis:(UILayoutConstraintAxis)axis gradientAnchors:(NSArray<CEVRKGradientAnchor *> *)gradientAnchors;

@end


@interface CEVRKThemeContinueButton : NSObject

@property (nonatomic, retain, nullable) NSNumber *widthPercent;
@property (nonatomic, retain, nullable) NSNumber *verticalPadding;
@property (nonatomic, retain, nullable) CEVRKGradient *backgroundGradient;

@end


@interface CEVRKTheme : NSObject

@property (nonatomic, retain, nullable) CEVRKThemeContinueButton *continueButtonSettings;

+ (instancetype)sharedTheme;
- (void)updateWithTheme:(nullable CEVRKTheme *)theme;

@end

NS_ASSUME_NONNULL_END
