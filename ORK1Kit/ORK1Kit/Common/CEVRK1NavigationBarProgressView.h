//
//  CEVRK1NavigationBarProgressView.h
//  ORK1Kit
//
//  Created by Eric Schramm on 8/10/20.
//  Copyright © 2020 researchkit.org. All rights reserved.
//

/*
 Placing a UIProgressView as the navigationItem.titleView forces the progressView to stretch from the
 left bar item to the right bar item with no control over width. This view allows us more control over
 sizing (width) of the progressView
 */

@interface CEVRK1NavigationBarProgressView : UIView

- (void)setProgress:(float)progress;

@end
