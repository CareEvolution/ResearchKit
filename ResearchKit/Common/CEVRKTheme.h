//
//  CEVRKTheme.h
//  ResearchKit
//
//  Created by Eric Schramm on 7/10/19.
//  Copyright © 2019 researchkit.org. All rights reserved.
//

@import UIKit;

static NSString * _Nonnull const kThemeAllOfUs = @"AllOfUs";

NS_ASSUME_NONNULL_BEGIN

@interface CEVRKTheme : NSObject

@property (nonatomic, retain, nullable) NSString *themeName;

+ (instancetype)sharedTheme;
- (void)updateWithTheme:(nullable NSString *)themeName;

@end

NS_ASSUME_NONNULL_END
