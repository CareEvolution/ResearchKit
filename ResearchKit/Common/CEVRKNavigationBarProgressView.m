//
//  CEVRKNavigationBarProgressView.m
//  ResearchKit
//
//  Created by Eric Schramm on 8/10/20.
//  Copyright © 2020 researchkit.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "CEVRKNavigationBarProgressView.h"


@interface CEVRKTaskProgressLastState : NSObject

@property (nonatomic, assign) BOOL progressBarLastHidden;

+ (instancetype)sharedProgressState;

@end


@implementation CEVRKTaskProgressLastState

+ (instancetype)sharedProgressState {
    static CEVRKTaskProgressLastState *sharedProgressState = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedProgressState = [[self alloc] init];
        sharedProgressState.progressBarLastHidden = YES;
    });
    return sharedProgressState;
}

@end


@implementation CEVRKNavigationBarProgressView {
    UIProgressView *_progressView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [super setHidden:[CEVRKTaskProgressLastState sharedProgressState].progressBarLastHidden];
        return self;
    }
    return nil;
}

- (void)setHidden:(BOOL)hidden {
    [CEVRKTaskProgressLastState sharedProgressState].progressBarLastHidden = hidden;
    [super setHidden:hidden];
}

@end
