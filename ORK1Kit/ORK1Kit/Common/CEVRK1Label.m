//
//  CEVRK1Label.m
//  ORK1Kit
//
//  Created by Eric Schramm on 8/27/20.
//  Copyright © 2020 researchkit.org. All rights reserved.
//

#import "CEVRK1Label.h"
#import "CEVRK1Theme.h"


@implementation CEVRK1Label {
    NSString *_rawText;
}

- (void)setText:(NSString * _Nullable)text {
    _rawText = text;
    [self updateAppearance];
}

- (NSString * _Nullable)rawText {
    return _rawText;
}

- (void)updateAppearance {
    // overridden in subclasses
}
@end
