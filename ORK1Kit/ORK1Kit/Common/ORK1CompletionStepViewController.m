/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "ORK1CompletionStepViewController.h"

#import "ORK1CustomStepView_Internal.h"
#import "ORK1InstructionStepView.h"
#import "ORK1NavigationContainerView.h"
#import "ORK1StepHeaderView_Internal.h"
#import "ORK1VerticalContainerView_Internal.h"

#import "ORK1InstructionStepViewController_Internal.h"
#import "ORK1StepViewController_Internal.h"

#import "ORK1Helpers_Internal.h"


@interface ORK1CompletionStepView : ORK1ActiveStepCustomView

@property (nonatomic) CGFloat animationPoint;

- (void)setAnimationPoint:(CGFloat)animationPoint animated:(BOOL)animated;

@end


@implementation ORK1CompletionStepView {
    CAShapeLayer *_shapeLayer;
}

static const CGFloat TickViewSize = 122;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = TickViewSize / 2;
        [self tintColorDidChange];
        
        UIBezierPath *path = [UIBezierPath new];
        [path moveToPoint:(CGPoint){37, 65}];
        [path addLineToPoint:(CGPoint){50, 78}];
        [path addLineToPoint:(CGPoint){87, 42}];
        path.lineCapStyle = kCGLineCapRound;
        path.lineWidth = 5;
    
        CAShapeLayer *shapeLayer = [CAShapeLayer new];
        shapeLayer.path = path.CGPath;
        shapeLayer.lineWidth = 5;
        shapeLayer.lineCap = kCALineCapRound;
        shapeLayer.lineJoin = kCALineJoinRound;
        shapeLayer.frame = self.layer.bounds;
        shapeLayer.strokeColor = [UIColor whiteColor].CGColor;
        shapeLayer.backgroundColor = [UIColor clearColor].CGColor;
        shapeLayer.fillColor = nil;
        [self.layer addSublayer:shapeLayer];
        _shapeLayer = shapeLayer;
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _shapeLayer.frame = self.layer.bounds;
}

- (CGSize)intrinsicContentSize {
    return (CGSize){TickViewSize,TickViewSize};
}

- (CGSize)sizeThatFits:(CGSize)size {
    return [self intrinsicContentSize];
}

- (void)tintColorDidChange {
    self.backgroundColor = [self tintColor];
}

- (void)setAnimationPoint:(CGFloat)animationPoint {
    _shapeLayer.strokeEnd = animationPoint;
    _animationPoint = animationPoint;
}

- (void)setAnimationPoint:(CGFloat)animationPoint animated:(BOOL)animated {
    CAMediaTimingFunction *timing = [[CAMediaTimingFunction alloc] initWithControlPoints:0.180739998817444 :0 :0.577960014343262 :0.918200016021729];
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    [animation setTimingFunction:timing];
    [animation setFillMode:kCAFillModeBoth];
    animation.fromValue = @([(CAShapeLayer *)[_shapeLayer presentationLayer] strokeEnd]);
    animation.toValue = @(animationPoint);
    
    animation.duration = 0.3;
    _animationPoint = animationPoint;
    
    _shapeLayer.strokeEnd = animationPoint;
    [_shapeLayer addAnimation:animation forKey:@"strokeEnd"];
    
}

- (BOOL)isAccessibilityElement {
    return YES;
}

- (UIAccessibilityTraits)accessibilityTraits {
    return [super accessibilityTraits] | UIAccessibilityTraitImage;
}

@end


@implementation ORK1CompletionStepViewController {
    ORK1CompletionStepView *_completionStepView;
}

- (void)stepDidChange {
    [super stepDidChange];
    
    _completionStepView = [ORK1CompletionStepView new];
    if (self.checkmarkColor) {
        _completionStepView.tintColor = self.checkmarkColor;
    }
    
    self.stepView.stepView = _completionStepView;
    
    self.stepView.continueSkipContainer.continueButtonItem = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _completionStepView.animationPoint = animated ? 0 : 1;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (animated) {
        [_completionStepView setAnimationPoint:1 animated:YES];
    }
    
    UILabel *captionLabel = self.stepView.headerView.captionLabel;
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, captionLabel);
    _completionStepView.accessibilityLabel = [NSString localizedStringWithFormat:ORK1LocalizedString(@"AX_IMAGE_ILLUSTRATION", nil), captionLabel.accessibilityLabel];
}

- (void)setCheckmarkColor:(UIColor *)checkmarkColor {
    _checkmarkColor = [checkmarkColor copy];
    _completionStepView.tintColor = checkmarkColor;
}

- (void)setShouldShowContinueButton:(BOOL)shouldShowContinueButton {
    _shouldShowContinueButton = shouldShowContinueButton;
    
    // Update button states
    [self setContinueButtonItem:self.continueButtonItem];
    [self updateNavRightBarButtonItem];
}

// Override top right bar button item
- (void)updateNavRightBarButtonItem {
    if (self.shouldShowContinueButton) {
        self.navigationItem.rightBarButtonItem = nil;
    }
    else {
        self.navigationItem.rightBarButtonItem = self.continueButtonItem;
    }
}

- (void)setContinueButtonItem:(UIBarButtonItem *)continueButtonItem {
    [super setContinueButtonItem:continueButtonItem];
    if (!self.shouldShowContinueButton) {
        self.stepView.continueSkipContainer.continueButtonItem = nil;
    }
    [self updateNavRightBarButtonItem];
}

@end
