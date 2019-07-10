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

@synthesize fontName;

#pragma mark Singleton Methods

+ (id)sharedTheme {
    static CEVRKTheme *sharedCEVRKTheme = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCEVRKTheme = [[self alloc] init];
    });
    return sharedCEVRKTheme;
}

- (id)init {
    if (self = [super init]) {
        fontName = nil;
    }
    return self;
}

@end
