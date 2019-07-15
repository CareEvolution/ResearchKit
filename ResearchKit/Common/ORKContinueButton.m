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


#import "ORKContinueButton.h"

#import "ORKSkin.h"

#import "CEVRKTheme.h"


static const CGFloat ContinueButtonTouchMargin = 10;

@implementation ORKContinueButton {
    NSLayoutConstraint *_heightConstraint;
    NSLayoutConstraint *_widthConstraint;
}

- (instancetype)initWithTitle:(NSString *)title isDoneButton:(BOOL)isDoneButton {
    self = [super init];
    if (self) {
        [self setTitle:title forState:UIControlStateNormal];
        self.isDoneButton = isDoneButton;
        self.contentEdgeInsets = (UIEdgeInsets){.left = 6, .right = 6};

        [self setUpConstraints];
    }
    return self;
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    [self updateConstraintConstantsForWindow:newWindow];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange: previousTraitCollection];
    if (self.traitCollection.verticalSizeClass != previousTraitCollection.verticalSizeClass) {
        [self updateConstraintConstantsForWindow:self.window];
    }
}

- (void)updateConstraintConstantsForWindow:(UIWindow *)window {
    NSNumber *buttonVerticalPadding = [[[CEVRKTheme sharedTheme] continueButtonSettings] verticalPadding];
    CGFloat height = 0;
    if (buttonVerticalPadding) {
        CGSize buttonLabelSize = [self.titleLabel.text sizeWithAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:17]}];
        height = buttonLabelSize.height + (buttonVerticalPadding.floatValue * 2);
    } else {
        height = (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) ?
        ORKGetMetricForWindow(ORKScreenMetricContinueButtonHeightCompact, window) :
        ORKGetMetricForWindow(ORKScreenMetricContinueButtonHeightRegular, window);
    }
    _heightConstraint.constant = height;
    
    NSNumber *buttonWidthPercent = [[[CEVRKTheme sharedTheme] continueButtonSettings] widthPercent];
    if (buttonWidthPercent) {
        _widthConstraint.constant = window.frame.size.width * buttonWidthPercent.floatValue / 100;
    } else {
        _widthConstraint.constant = ORKGetMetricForWindow(ORKScreenMetricContinueButtonWidth, self.window);
    }
}

- (void)setUpConstraints {
    _heightConstraint = [NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                    multiplier:1.0
                                                      constant:0.0]; // constant will be set in updateConstraintConstantsForWindow:
    _heightConstraint.active = YES;
    
    _widthConstraint = [NSLayoutConstraint constraintWithItem:self
                                                    attribute:NSLayoutAttributeWidth
                                                    relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                       toItem:nil
                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                   multiplier:1.0
                                                     constant:0.0];  // constant will be set in updateConstraintConstantsForWindow:
    _widthConstraint.active = YES;
    [self updateConstraintConstantsForWindow:self.window];
}

- (void)updateConstraints {
    [self updateConstraintConstantsForWindow:self.window];
    [super updateConstraints];
}

+ (UIFont *)defaultFont {
    UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleHeadline];
    return [UIFont systemFontOfSize:[[descriptor objectForKey: UIFontDescriptorSizeAttribute] doubleValue]];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect outsetRect = UIEdgeInsetsInsetRect(self.bounds,
                                              (UIEdgeInsets){-ContinueButtonTouchMargin,
                                                             -ContinueButtonTouchMargin,
                                                             -ContinueButtonTouchMargin,
                                                             -ContinueButtonTouchMargin});
    BOOL isInside = [super pointInside:point withEvent:event] || CGRectContainsPoint(outsetRect, point);
    return isInside;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self themeButtonOverrides];
}

- (void)themeButtonOverrides {
    CEVRKThemeContinueButton *continueButtonSettings = [[CEVRKTheme sharedTheme] continueButtonSettings];
    if (!continueButtonSettings) {
        return;
    }
    
    CEVRKGradient *backgroundGradient = continueButtonSettings.backgroundGradient;
    if (!backgroundGradient) {
        return;
    }
    
    CAGradientLayer *gradient = [[CAGradientLayer alloc] init];
    gradient.frame = self.bounds;
    
    NSMutableArray *cgColors = [[NSMutableArray alloc] init];
    NSMutableArray *locations = [[NSMutableArray alloc] init];
    for (CEVRKGradientAnchor *anchor in backgroundGradient.grandientAnchors) {
        [cgColors addObject:(id)[anchor colorForAnchorHex].CGColor];
        [locations addObject:[NSNumber numberWithFloat:anchor.location]];
    }
    
    switch (backgroundGradient.axis) {
        case UILayoutConstraintAxisVertical:
            gradient.startPoint = CGPointMake(0, 0);
            gradient.endPoint = CGPointMake(0, 1);
            break;
        case UILayoutConstraintAxisHorizontal:
            gradient.startPoint = CGPointMake(0, 0);
            gradient.endPoint = CGPointMake(1, 0);
        default:
            break;
    }
    
    gradient.colors = [cgColors copy];
    gradient.locations = [locations copy];
    
    //gradient.cornerRadius = 5.0f;
    
    [self.layer insertSublayer:gradient atIndex:0];
    NSLog(@"Adding gradient - frame: %f, %f, %f, %f", gradient.frame.origin.x, gradient.frame.origin.y, gradient.frame.size.width, gradient.frame.size.height);
    
    //self.layer.borderColor = [[UIColor clearColor] CGColor];
    //self.layer.borderWidth = 0.1f;
    //self.layer.cornerRadius = 5.0f;
    //self.layer.borderColor = [_disableTintColor CGColor];
    
    /*
     if (self.titleLabel.text) {
     NSDictionary *attributes = @{NSFontAttributeName : [UIFont boldSystemFontOfSize:17],
     NSForegroundColorAttributeName : [ORKBorderedButton colorFromHexString:@"#262262"]
     };
     NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:[self.titleLabel.text uppercaseString] attributes:attributes];
     
     [self setAttributedTitle:attributedString forState:UIControlStateNormal];
     }*/
}

@end
