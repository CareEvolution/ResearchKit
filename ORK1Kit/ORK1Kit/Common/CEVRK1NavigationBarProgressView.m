//
//  CEVRK1NavigationBarProgressView.m
//  ORK1Kit
//
//  Created by Eric Schramm on 8/10/20.
//  Copyright © 2020 researchkit.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "CEVRK1NavigationBarProgressView.h"
#import "CEVRK1Theme.h"


@implementation CEVRK1NavigationBarProgressView {
    UIProgressView *_progressView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self createConstraints];
        return self;
    }
    return nil;
}

- (void)createConstraints {
    _progressView = [[UIProgressView alloc] initWithFrame:CGRectZero];
    _progressView.backgroundColor = [UIColor whiteColor];
    _progressView.progress = 0;
    self.accessibilityElements = @[_progressView];
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_progressView];
    _progressView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        [_progressView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0], //10],
        [_progressView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0], //-30],
    ]];
}

- (float)progress {
    return _progressView.progress;
}

- (void)setProgress:(float)progress withTheme:(nullable CEVRK1Theme *)theme animated:(BOOL)animated {
    [_progressView setProgress:progress animated:animated];
    if (theme.progressBarColor) {
        _progressView.tintColor = theme.progressBarColor;
    }
}

@end
