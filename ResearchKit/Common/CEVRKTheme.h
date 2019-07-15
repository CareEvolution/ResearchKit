//
//  CEVRKTheme.h
//  ResearchKit
//
//  Created by Eric Schramm on 7/10/19.
//  Copyright © 2019 researchkit.org. All rights reserved.
//

@import Foundation;

@interface CEVRKThemeContinueButton : NSObject

@property (nonatomic, retain) NSNumber *widthPercent;
@property (nonatomic, retain) NSNumber *verticalPadding;

@end

@interface CEVRKTheme : NSObject

@property (nonatomic, retain) NSString *fontName;
@property (nonatomic, retain) CEVRKThemeContinueButton *continueButtonSettings;

+ (instancetype)sharedTheme;
- (void)updateWithTheme:(CEVRKTheme *)theme;

@end
