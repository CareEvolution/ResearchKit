//
//  CEVRKTheme.h
//  ResearchKit
//
//  Created by Eric Schramm on 7/10/19.
//  Copyright © 2019 researchkit.org. All rights reserved.
//

@import Foundation;

@interface CEVRKTheme : NSObject {
    NSString *fontName;
}

@property (nonatomic, retain) NSString *fontName;

+ (id)sharedTheme;

@end
