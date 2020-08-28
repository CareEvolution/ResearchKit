//
//  CEVRK1TextView.m
//  ORK1Kit
//
//  Created by Eric Schramm on 8/26/20.
//  Copyright © 2020 researchkit.org. All rights reserved.
//

#import "CEVRK1TextView.h"
#import "CEVRK1Theme.h"
#import "ORK1SubheadlineLabel.h"


@implementation CEVRK1TextView

- (void)init_CEVRK1TextView {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateAppearance)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
}

- (void)setTextValue:(NSString *)textValue {
    _textValue = textValue;
    [self updateAppearance];
}

- (void)setDetailTextValue:(NSString *)detailTextValue {
    _detailTextValue = detailTextValue;
    [self updateAppearance];
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    [self updateAppearance];
}

- (void)updateAppearance {
    // to handle any changes in dynamic text size, we update the current font and re-render
    // NOTE: textview imitates previously used ORK1SubheadlineLabel
    self.font = [[ORK1SubheadlineLabel class] defaultFont];
    [[CEVRK1Theme themeForElement:self] updateAppearanceForTextView:self];
    [self invalidateIntrinsicContentSize];
}

@end
