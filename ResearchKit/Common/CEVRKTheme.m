//
//  CEVRKTheme.m
//  ResearchKit
//
//  Created by Eric Schramm on 7/10/19.
//  Copyright © 2019 researchkit.org. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CEVRKTheme.h"

@implementation CEVRKTheme

@synthesize continueButtonSettings;

#pragma mark Singleton Methods

+ (instancetype)sharedTheme {
    static CEVRKTheme *sharedCEVRKTheme = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCEVRKTheme = [[self alloc] init];
    });
    return sharedCEVRKTheme;
}

- (instancetype)init {
    if (self = [super init]) {
        continueButtonSettings = nil;
    }
    return self;
}

- (void)updateWithTheme:(nullable CEVRKTheme *)theme {
    self.continueButtonSettings = theme.continueButtonSettings;
}

@end

@implementation CEVRKThemeContinueButton
@synthesize widthPercent, verticalPadding;
@end


@implementation CEVRKGradient

@synthesize grandientAnchors = _grandientAnchors;
@synthesize axis = _axis;

- (instancetype)initWithAxis:(UILayoutConstraintAxis)axis gradientAnchors:(NSArray<CEVRKGradientAnchor *> *)gradientAnchors {
    if (self = [super init]) {
        _axis = axis;
        _grandientAnchors = gradientAnchors;
        return self;
    }
    return nil;
}

@end


@implementation CEVRKGradientAnchor

@synthesize gradientHexColor = _gradientHexColor;
@synthesize location = _location;

- (instancetype)initWithGradientHexColor:(NSString *)gradientHexColor location:(CGFloat)location {
    if (self = [super init]) {
        _gradientHexColor = gradientHexColor;
        _location = location;
        return self;
    }
    return nil;
}

- (UIColor *)colorForAnchorHex {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:self.gradientHexColor];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

@end
