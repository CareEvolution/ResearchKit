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

- (void)updateWithTheme:(CEVRKTheme *)theme {
    self.continueButtonSettings = theme.continueButtonSettings;
}

@end

@implementation CEVRKThemeContinueButton
@synthesize widthPercent, verticalPadding;
@end
