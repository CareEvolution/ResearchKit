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
    _progressView.progress = 0;
    self.accessibilityElements = @[_progressView];
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_progressView];
    _progressView.translatesAutoresizingMaskIntoConstraints = NO;
    
    if (@available(iOS 26.0, *)) {
        _progressView.backgroundColor = [UIColor whiteColor];
        [NSLayoutConstraint activateConstraints:@[
            [_progressView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_progressView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_progressView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_progressView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        ]];
    } else {
        // This forces the bar to stretch so the ORK1ProgressView will attempt to take up the entire available width
        NSLayoutConstraint *widthConstraint = [self.widthAnchor constraintEqualToConstant:200];
        widthConstraint.priority = UILayoutPriorityDefaultHigh;
        [NSLayoutConstraint activateConstraints:@[
            [_progressView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10],
            [_progressView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-30],
            [_progressView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            widthConstraint
        ]];
    }
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
