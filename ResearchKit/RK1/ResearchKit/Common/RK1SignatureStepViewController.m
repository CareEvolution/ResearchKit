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


#import "RK1SignatureStepViewController.h"

#import "RK1SignatureView.h"

#import "RK1NavigationContainerView_Internal.h"
#import "RK1StepHeaderView_Internal.h"
#import "RK1StepViewController_Internal.h"
#import "RK1VerticalContainerView_Internal.h"

#import "RK1Result_Private.h"
#import "RK1Step.h"

#import "RK1Helpers_Internal.h"
#import "RK1Skin.h"


@interface RK1SignatureWrapperView : UIView

@property (nonatomic, strong) RK1SignatureView *signatureView;

@property (nonatomic, strong) RK1TextButton *clearButton;

@property (nonatomic, assign) BOOL clearButtonEnabled;

@end


@implementation RK1SignatureWrapperView

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    [self setNeedsLayout];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        {
            _clearButton = [RK1TextButton new];
            _clearButton.contentEdgeInsets = (UIEdgeInsets){12,10,8,10}; // insets adjusted to get correct vertical height from bottom of screen when aligned to margin
            _clearButton.exclusiveTouch = YES;
            [_clearButton setTitle:RK1LocalizedString(@"BUTTON_CLEAR", nil) forState:UIControlStateNormal];
            _clearButton.translatesAutoresizingMaskIntoConstraints = NO;
            _clearButton.alpha = 0;
            [self addSubview:_clearButton];
        }
        
        {
            _signatureView = [RK1SignatureView new];
            [_signatureView setClipsToBounds:YES];
            
            _signatureView.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:_signatureView];
        }
        
        [self setUpConstraints];
    }
    return self;
}

- (void)updateLayoutMargins {
    CGFloat margin = RK1StandardHorizontalMarginForView(self);
    self.layoutMargins = (UIEdgeInsets){.left = margin, .right = margin };
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self updateLayoutMargins];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self updateLayoutMargins];
}

- (void)setClearButtonEnabled:(BOOL)clearButtonEnabled {
    _clearButtonEnabled = clearButtonEnabled;
    
    if (clearButtonEnabled) {
        NSTimeInterval duration = (UIAccessibilityIsVoiceOverRunning() ? 0 : 0.2);
        [UIView animateWithDuration:duration delay:0 options:(UIViewAnimationOptions)UIViewAnimationOptionBeginFromCurrentState animations:^{
            _clearButton.alpha = 1;
        } completion:^(BOOL finished) {
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
        }];
    } else {
        _clearButton.alpha = 0;
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, _signatureView);
    }
}

- (void)setUpConstraints {
    // Static constraints
    NSMutableArray *constraints = [NSMutableArray array];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_clearButton, _signatureView);
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_signatureView]-(>=0)-[_clearButton]|"
                                                                             options:(NSLayoutFormatOptions)0
                                                                             metrics:nil
                                                                               views:views]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_signatureView
                                                        attribute:NSLayoutAttributeCenterX
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeCenterX
                                                       multiplier:1.0
                                                         constant:0.0]];
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=0)-[_clearButton]-(>=0)-|"
                                                                             options:(NSLayoutFormatOptions)0
                                                                             metrics:nil
                                                                               views:views]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_signatureView
                                                        attribute:NSLayoutAttributeTop
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeTop
                                                       multiplier:1.0
                                                         constant:0.0]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_clearButton
                                                        attribute:NSLayoutAttributeCenterX
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeCenterX
                                                       multiplier:1.0
                                                         constant:0.0]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_clearButton
                                                        attribute:NSLayoutAttributeBaseline
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_signatureView
                                                        attribute:NSLayoutAttributeBottom
                                                       multiplier:1.0
                                                         constant:30.0]];
    
    [NSLayoutConstraint activateConstraints:constraints];
}

@end


@interface RK1ConsentSigningView : RK1VerticalContainerView

@property (nonatomic, strong) RK1SignatureWrapperView *wrapperView;

@end


@implementation RK1ConsentSigningView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        _wrapperView = [RK1SignatureWrapperView new];
        _wrapperView.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.stepView = _wrapperView;
        
        self.continueSkipContainer.optional = NO;
        [self.continueSkipContainer updateContinueAndSkipEnabled];
    }
    return self;
}

@end


@interface RK1SignatureStepViewController () <RK1SignatureViewDelegate>

@property (nonatomic, strong, readonly, nullable) RK1SignatureView *signatureView;
@property (nonatomic, strong) RK1ConsentSigningView *signingView;
@property (nonatomic, strong) RK1NavigationContainerView *continueSkipView;
@property (nonatomic, strong) NSArray <UIBezierPath *> *originalPath;

@end


@implementation RK1SignatureStepViewController

- (instancetype)initWithStep:(RK1Step *)step result:(RK1Result *)result {
    self = [super initWithStep:step result:result];
    if (self && step) {
        if ([result isKindOfClass:[RK1StepResult class]]) {
            [[(RK1StepResult *)result results] enumerateObjectsUsingBlock:^(RK1Result * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[RK1SignatureResult class]]) {
                    _originalPath = [(RK1SignatureResult*)obj signaturePath];
                    *stop = YES;
                }
            }];

        }
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // set the original path and update state
    self.signatureView.signaturePath = self.originalPath;
    [self updateButtonStates];
}

- (RK1StepResult *)result {
    RK1StepResult *parentResult = [super result];
    
    if (self.signatureView.signatureExists) {
        RK1SignatureResult *sigResult = [[RK1SignatureResult alloc] initWithSignatureImage:self.signatureView.signatureImage
                                                                             signaturePath:self.signatureView.signaturePath];
        parentResult.results = @[sigResult];
    }
    
    return parentResult;
}

- (void)setContinueButtonItem:(UIBarButtonItem *)continueButtonItem {
    [super setContinueButtonItem:continueButtonItem];
    self.continueSkipView.continueButtonItem = continueButtonItem;
    [self updateButtonStates];
}

- (void)setSkipButtonItem:(UIBarButtonItem *)skipButtonItem {
    [super setSkipButtonItem:skipButtonItem];
    self.continueSkipView.skipButtonItem = skipButtonItem;
    [self updateButtonStates];
}

- (void)updateButtonStates {
    BOOL hasSigned = self.signatureView.signatureExists;
    self.continueSkipView.continueEnabled = hasSigned;
    self.continueSkipView.optional = self.step.optional;
    [_signingView.wrapperView setClearButtonEnabled:hasSigned];
}

- (void)stepDidChange {
    [super stepDidChange];
    
    [_signingView removeFromSuperview];
    _signingView.wrapperView.signatureView.delegate = nil;
    
    _signingView = [RK1ConsentSigningView new];
    _signingView.wrapperView.signatureView.delegate = self;
    _signingView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _signingView.frame = self.view.bounds;
    _signingView.headerView.captionLabel.text = self.step.title;
    _signingView.headerView.instructionLabel.text = self.step.text;
    
    _continueSkipView = _signingView.continueSkipContainer;
    _continueSkipView.skipButtonItem = self.skipButtonItem;
    _continueSkipView.continueButtonItem = self.continueButtonItem;
    [self updateButtonStates];
    
    [_signingView.wrapperView.clearButton addTarget:self action:@selector(clearAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_signingView];
}

- (RK1SignatureView *)signatureView {
    return _signingView.wrapperView.signatureView;
}

- (void)clearAction:(id)sender {
    [_signingView.wrapperView.signatureView clear];
    [self updateButtonStates];
    [self notifyDelegateOnResultChange];
}

- (void)signatureViewDidEditImage:(RK1SignatureView *)signatureView {
    [self updateButtonStates];
    [self notifyDelegateOnResultChange];
}

@end
