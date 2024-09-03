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
    UIFont *_originalFont;
}

- (void)setText:(NSString * _Nullable)text {
    _rawText = text;
    [self updateAppearance];
}

- (void)setFont:(UIFont *)font {
    _originalFont = font;
    [super setFont:font];
}

- (NSString * _Nullable)rawText {
    return _rawText;
}

- (UIFont *)originalFont {
    return _originalFont;
}

- (void)updateAppearance {
    // overridden in subclasses
}
@end
