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


#import "ORK1VerticalContainerView.h"
#import "ORK1VerticalContainerView_Internal.h"

#import "ORK1CustomStepView_Internal.h"
#import "ORK1NavigationContainerView.h"
#import "ORK1StepHeaderView_Internal.h"
#import "ORK1TintedImageView.h"

#import "ORK1Helpers_Internal.h"
#import "ORK1Skin.h"


static const CGFloat AssumedNavBarHeight = 44;
static const CGFloat AssumedStatusBarHeight = 20;

// Enable this define to see outlines and colors of all the views laid out at this level.
// #define LAYOUT_DEBUG

/*
 view hierachy in ORK1VerticalContainerView (from top to bottom):
 
 scrollContainer
    - container
        - customViewContainer
        - headerView
        - stepViewContainer
    - continueSkipContainer
 */

@interface ORK1VerticalContainerView () <UIScrollViewDelegate>
@end

@implementation ORK1VerticalContainerView {
    UIView *_scrollContainer;
    UIView *_container;
    
    ORK1TintedImageView *_imageView;

    NSMutableArray *_variableConstraints;
    
    NSLayoutConstraint *_headerMinimumHeightConstraint;
    NSLayoutConstraint *_illustrationHeightConstraint;
    NSLayoutConstraint *_stepViewCenterInStepViewContainerConstraint;
    NSLayoutConstraint *_stepViewToContinueConstraint;
    NSLayoutConstraint *_stepViewToContinueMinimumConstraint;
    NSLayoutConstraint *_topToIllustrationConstraint;
    
    NSLayoutConstraint *_continueContainerToScrollContainerBottomConstraint;
    NSLayoutConstraint *_continueContainerToContainerBottomConstraint;
    
    CGFloat _keyboardOverlap;
    
    UIView *_stepViewContainer;
    
    BOOL _keyboardIsUp;
    
    // CEV HACK
    NSUInteger autoLayoutLoopCount;
    NSUInteger carriageReturnsAdded;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _scrollContainer = [UIView new];
        [self addSubview:_scrollContainer];
        _container = [UIView new];
        [_scrollContainer addSubview:_container];
        
        {
            _headerView = [ORK1StepHeaderView new];
            _headerView.layoutMargins = UIEdgeInsetsZero;
            _headerView.translatesAutoresizingMaskIntoConstraints = NO;
            [_container addSubview:_headerView];
        }
        
        {
            _stepViewContainer = [UIView new];
            _stepViewContainer.preservesSuperviewLayoutMargins = YES;
            [_container addSubview:_stepViewContainer];
        }
        
        {
            // This lives in the scroll container, so it doesn't affect the vertical layout of the primary content
            // except through explicit constraints.
            _continueSkipContainer = [ORK1NavigationContainerView new];
            _continueSkipContainer.bottomMargin = 20;
            _continueSkipContainer.translatesAutoresizingMaskIntoConstraints = NO;
            [_scrollContainer addSubview:_continueSkipContainer];
        }
        
        {
            // Custom View
            _customViewContainer = [UIView new];
            [_container addSubview:self.customViewContainer];
        }
        
        ORK1EnableAutoLayoutForViews(@[_scrollContainer, _container, _headerView, _stepViewContainer, _continueSkipContainer, _customViewContainer]);

        [self setUpStaticConstraints];
        [self setNeedsUpdateConstraints];
        
        UITapGestureRecognizer *tapOffRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOffAction:)];
        [self addGestureRecognizer:tapOffRecognizer];
        
        UISwipeGestureRecognizer *swipeOffRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeOffAction:)];
        swipeOffRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
        [self addGestureRecognizer:swipeOffRecognizer];
        
        // CEV HACK
        autoLayoutLoopCount = 0;
        carriageReturnsAdded = 0;
        self.delegate = self;
    }
    return self;
}

- (void)setUpStaticConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_scrollContainer, _container);
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_scrollContainer]|"
                                                                             options:(NSLayoutFormatOptions)0
                                                                             metrics:nil
                                                                               views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_scrollContainer]|"
                                                                             options:(NSLayoutFormatOptions)0
                                                                             metrics:nil
                                                                               views:views]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_scrollContainer
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeHeight
                                                       multiplier:1.0
                                                         constant:0.0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_scrollContainer
                                                        attribute:NSLayoutAttributeWidth
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeWidth
                                                       multiplier:1.0
                                                         constant:0.0]];
    
    // This constraint is needed to get the scroll container not to size itself too large (we don't want scrolling if it's not needed)
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:_scrollContainer
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self
                                                                        attribute:NSLayoutAttributeHeight
                                                                       multiplier:1.0
                                                                         constant:0.0];
    heightConstraint.priority = UILayoutPriorityDefaultLow;
    [constraints addObject:heightConstraint];
    
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)swipeOffAction:(UITapGestureRecognizer *)recognizer {
    [self endEditing:NO];
}

- (void)tapOffAction:(UITapGestureRecognizer *)recognizer {
    // On a tap, dismiss the keyboard if the tap was not inside a view that is first responder or a child of a first responder.
    CGPoint point = [recognizer locationInView:self];
    UIView *view = [self hitTest:point withEvent:nil];
    BOOL viewIsChildOfFirstResponder = NO;
    while (view) {
        if ([view isFirstResponder]) {
            viewIsChildOfFirstResponder = YES;
            break;
        }
        view = [view superview];
    }
    
    if (!viewIsChildOfFirstResponder) {
        [self endEditing:NO];
    }
}

- (void)dealloc {
    [self registerForKeyboardNotifications:NO];
}

- (void)registerForKeyboardNotifications:(BOOL)shouldRegister {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    if (shouldRegister) {
        [notificationCenter addObserver:self
                selector:@selector(keyboardWillShow:)
                    name:UIKeyboardWillShowNotification object:nil];
        
        [notificationCenter addObserver:self
                selector:@selector(keyboardWillHide:)
                    name:UIKeyboardWillHideNotification object:nil];
        [notificationCenter addObserver:self
                selector:@selector(keyboardFrameWillChange:)
                    name:UIKeyboardWillChangeFrameNotification object:nil];
    } else {
        [notificationCenter removeObserver:self name:UIKeyboardWillShowNotification object:nil];
        [notificationCenter removeObserver:self name:UIKeyboardWillHideNotification object:nil];
        [notificationCenter removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    }
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self updateLayoutMargins];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self updateLayoutMargins];
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    [self updateConstraintConstantsForWindow:newWindow];
    if (newWindow) {
        [self registerForKeyboardNotifications:YES];
    } else {
        [self registerForKeyboardNotifications:NO];
    }
}

- (CGSize)keyboardIntersectionSizeFromNotification:(NSNotification *)notification {
    CGRect keyboardFrame = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrame = [self convertRect:keyboardFrame fromView:nil];
    
    CGRect scrollFrame = self.bounds;
    
    // The origin of this is in our superview's coordinate system, but I don't think
    // we actually use the origin - so just return the size.
    CGRect intersectionFrame = CGRectIntersection(scrollFrame, keyboardFrame);
    return intersectionFrame.size;
}

- (void)animateLayoutForKeyboardNotification:(NSNotification *)notification {
    NSTimeInterval animationDuration = ((NSNumber *)notification.userInfo[UIKeyboardAnimationDurationUserInfoKey]).doubleValue;
    
    [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        CGRect bounds = self.bounds;
        CGSize contentSize = self.contentSize;
        
        CGSize intersectionSize = [self keyboardIntersectionSizeFromNotification:notification];
        CGFloat visibleHeight = bounds.size.height - intersectionSize.height;
        
        // Keep track of the keyboard overlap, so we can adjust the constraint properly.
        _keyboardOverlap = intersectionSize.height;
        
        [self updateContinueButtonConstraints];
        
        // Trigger layout inside the animation block to get the constraint change to animate.
        [self layoutIfNeeded];
        
        if (_keyboardIsUp) {
            // The content ends at the bottom of the continueSkipContainer.
            // We want to calculate new insets so it's possible to scroll it fully visible, but no more.
            // Made a little more complicated because the contentSize will still extend below the bottom of this container,
            // because we haven't changed our bounds.
            CGFloat contentMaxY = CGRectGetMaxY([self convertRect:_continueSkipContainer.bounds fromView:_continueSkipContainer]);
            
            // First compute the contentOffset.y that would make the continue and skip buttons visible
            CGFloat yOffset = MAX(contentMaxY - visibleHeight, 0);
            yOffset = MIN(yOffset, contentSize.height - visibleHeight);
            
            // If that yOffset would not make the stepView visible, override to align with the top of the stepView.
            CGRect potentialVisibleRect = (CGRect){{0,yOffset},{bounds.size.width,visibleHeight}};
            CGRect targetBounds = [self convertRect:_stepView.bounds fromView:_stepView];
            if (!CGRectContainsRect(potentialVisibleRect, targetBounds)) {
                yOffset = targetBounds.origin.y;
            }
            
            CGFloat keyboardOverlapWithActualContent = MAX(contentMaxY - (contentSize.height - intersectionSize.height), 0);
            UIEdgeInsets insets = (UIEdgeInsets){.bottom = keyboardOverlapWithActualContent };
            self.contentInset = insets;
        
            // Rather than setContentOffset, setBounds so that we get a smooth animation
            if (ABS(yOffset - bounds.origin.y) > 1) {
                bounds.origin.y = yOffset;
                [self setBounds:bounds];
            }
        }
    } completion:nil];
}

- (void)keyboardFrameWillChange:(NSNotification *)notification {
    CGSize intersectionSize = [self keyboardIntersectionSizeFromNotification:notification];
    
    // Assume the overlap is at the bottom of the view
    ORK1UpdateScrollViewBottomInset(self, intersectionSize.height);
    
    _keyboardIsUp = YES;
    [self animateLayoutForKeyboardNotification:notification];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    CGSize intersectionSize = [self keyboardIntersectionSizeFromNotification:notification];
    
    // Assume the overlap is at the bottom of the view
    ORK1UpdateScrollViewBottomInset(self, intersectionSize.height);
    
    _keyboardIsUp = YES;
    [self animateLayoutForKeyboardNotification:notification];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    ORK1UpdateScrollViewBottomInset(self, 0);
    
    _keyboardIsUp = NO;
    [self animateLayoutForKeyboardNotification:notification];
}

- (void)updateContinueButtonConstraints {
    _continueContainerToScrollContainerBottomConstraint.active = !_continueHugsContent;
    _continueContainerToContainerBottomConstraint.active = _continueHugsContent;
    
    if (_keyboardIsUp) {
        // Try to move up from the bottom to be above the keyboard.
        // This will go only so far - if we hit actual content, this will
        // be counteracted by the constraint to stay below the content.
        _continueContainerToScrollContainerBottomConstraint.constant = - _keyboardOverlap;
    } else {
        _continueContainerToScrollContainerBottomConstraint.constant = 0;
    }
}

- (void)updateStepViewCenteringConstraint {
    BOOL hasIllustration = (_imageView.image != nil);
    BOOL hasCaption = _headerView.captionLabel.text.length > 0;
    BOOL hasInstruction = _headerView.instructionLabel.text.length > 0;
    BOOL hasLearnMore = (_headerView.learnMoreButton.alpha > 0);
    BOOL hasContinueOrSkip = [_continueSkipContainer hasContinueOrSkip];

    if (_stepViewCenterInStepViewContainerConstraint) {
        BOOL offsetCentering = !(hasIllustration || hasCaption || hasInstruction || hasLearnMore || hasContinueOrSkip);
        _stepViewCenterInStepViewContainerConstraint.active = offsetCentering;
    }    
}

- (void)updateLayoutMargins {
    CGFloat margin = ORK1StandardHorizontalMarginForView(self);
    UIEdgeInsets layoutMargins = (UIEdgeInsets){.left = margin, .right = margin};
    self.layoutMargins = layoutMargins;
    _scrollContainer.layoutMargins = layoutMargins;
    _container.layoutMargins = layoutMargins;
}

- (void)updateConstraintConstantsForWindow:(UIWindow *)window {
    const CGFloat StepViewBottomToContinueTop = ORK1GetMetricForWindow(ORK1ScreenMetricContinueButtonTopMargin, window);
    const CGFloat StepViewBottomToContinueTopForIntroStep = ORK1GetMetricForWindow(ORK1ScreenMetricContinueButtonTopMarginForIntroStep, window);
    
    {
        BOOL hasIllustration = (_imageView.image != nil);
        _headerView.hasContentAbove = hasIllustration;

        const CGFloat IllustrationHeight = ORK1GetMetricForWindow(ORK1ScreenMetricIllustrationHeight, window);
        const CGFloat IllustrationTopMargin = ORK1GetMetricForWindow(ORK1ScreenMetricTopToIllustration, window);
        
        _illustrationHeightConstraint.constant = (_imageView.image ? IllustrationHeight : 0);
        _topToIllustrationConstraint.constant = (_imageView.image ?IllustrationTopMargin : 0);
    }
    
    {
        BOOL hasStepView = (_stepView != nil);
        BOOL hasContinueOrSkip = [_continueSkipContainer hasContinueOrSkip];

        CGFloat continueSpacing = StepViewBottomToContinueTop;
        if (self.continueHugsContent && !hasStepView) {
            continueSpacing = 0;
        }
        if (self.stepViewFillsAvailableSpace) {
            continueSpacing = StepViewBottomToContinueTopForIntroStep;
        }
        if (!hasContinueOrSkip) {
            // If we don't actually have continue or skip, we should not apply any space
            continueSpacing = 0;
        }
        CGFloat continueSpacing2 = MIN(10, continueSpacing);
        _stepViewToContinueConstraint.constant = continueSpacing;
        _stepViewToContinueMinimumConstraint.constant = continueSpacing2;
    }
    
    {
        _headerMinimumHeightConstraint.constant = _minimumStepHeaderHeight;
    }
}

- (void)setContinueHugsContent:(BOOL)continueHugsContent {
    _continueHugsContent = continueHugsContent;
    [self setNeedsUpdateConstraints];
}

- (void)setVerticalCenteringEnabled:(BOOL)verticalCenteringEnabled {
    _verticalCenteringEnabled = verticalCenteringEnabled;
    [self setNeedsUpdateConstraints];
}

- (void)setStepViewFillsAvailableSpace:(BOOL)stepViewFillsAvailableSpace {
    _stepViewFillsAvailableSpace = stepViewFillsAvailableSpace;
    [self setNeedsUpdateConstraints];
}

- (void)setMinimumStepHeaderHeight:(CGFloat)minimumStepHeaderHeight {
    _minimumStepHeaderHeight = minimumStepHeaderHeight;
    [self updateConstraintConstantsForWindow:self.window];
}

- (void)updateConstraints {
    [NSLayoutConstraint deactivateConstraints:_variableConstraints];
    [_variableConstraints removeAllObjects];
    
    if (!_variableConstraints) {
        _variableConstraints = [NSMutableArray new];
    }

    _continueContainerToContainerBottomConstraint = nil;
    _continueContainerToScrollContainerBottomConstraint = nil;
    
    NSArray *views = @[_headerView, _customViewContainer, _continueSkipContainer, _stepViewContainer];
    
    // Roughly center the container, but put it a little above the center if possible
    if (_verticalCenteringEnabled) {
        NSLayoutConstraint *verticalCentering1 = [NSLayoutConstraint constraintWithItem:_container
                                                                              attribute:NSLayoutAttributeCenterY
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:_scrollContainer
                                                                              attribute:NSLayoutAttributeCenterY
                                                                             multiplier:0.8
                                                                               constant:0.0];
        verticalCentering1.priority = UILayoutPriorityDefaultLow;
        [_variableConstraints addObject:verticalCentering1];
        
        NSLayoutConstraint *verticalCentering2 = [NSLayoutConstraint constraintWithItem:_container
                                                                              attribute:NSLayoutAttributeCenterY
                                                                              relatedBy:NSLayoutRelationLessThanOrEqual
                                                                                 toItem:_scrollContainer
                                                                              attribute:NSLayoutAttributeCenterY
                                                                             multiplier:1.0
                                                                               constant:0.0];
        verticalCentering2.priority = UILayoutPriorityDefaultHigh;
        [_variableConstraints addObject:verticalCentering2];

        NSLayoutConstraint *verticalCentering3 = [NSLayoutConstraint constraintWithItem:_container
                                                                              attribute:NSLayoutAttributeTop
                                                                              relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                                 toItem:_scrollContainer
                                                                              attribute:NSLayoutAttributeTop
                                                                             multiplier:1.0
                                                                               constant:0.0];
        verticalCentering3.priority = UILayoutPriorityDefaultHigh;
        [_variableConstraints addObject:verticalCentering3];
    } else {
        NSLayoutConstraint *verticalTop = [NSLayoutConstraint constraintWithItem:_container
                                                                       attribute:NSLayoutAttributeTop
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:_scrollContainer
                                                                       attribute:NSLayoutAttributeTop
                                                                      multiplier:1.0
                                                                        constant:0.0];
        [_variableConstraints addObject:verticalTop];
    }
    
    // Don't let the container get too tall
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:_container
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationLessThanOrEqual
                                                                           toItem:_scrollContainer
                                                                        attribute:NSLayoutAttributeHeight
                                                                       multiplier:1.0
                                                                         constant:0.0];
    [_variableConstraints addObject:heightConstraint];
    
    [_variableConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[container]|"
                                                                                      options:(NSLayoutFormatOptions)0
                                                                                      metrics:nil
                                                                                        views:@{@"container":_container}]];
#ifdef LAYOUT_DEBUG
    _container.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.3];
    _scrollContainer.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.3];
#endif

    // All items with constants use constraint ivars
    _illustrationHeightConstraint = [NSLayoutConstraint constraintWithItem:_customViewContainer
                                                                 attribute:NSLayoutAttributeHeight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:nil
                                                                 attribute:NSLayoutAttributeNotAnAttribute
                                                                multiplier:1.0
                                                                  constant:198.0];
    [_variableConstraints addObject:_illustrationHeightConstraint];
    
    _topToIllustrationConstraint = [NSLayoutConstraint constraintWithItem:_customViewContainer
                                                                attribute:NSLayoutAttributeTop
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_container
                                                                attribute:NSLayoutAttributeTop
                                                               multiplier:1.0
                                                                 constant:0.0];
    [_variableConstraints addObject:_topToIllustrationConstraint];

    [_variableConstraints addObject:[NSLayoutConstraint constraintWithItem:_headerView
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:_customViewContainer
                                                                 attribute:NSLayoutAttributeBottom
                                                                multiplier:1.0
                                                                  constant:0.0]];
    
    [_variableConstraints addObject:[NSLayoutConstraint constraintWithItem:_stepViewContainer
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:_headerView
                                                                 attribute:NSLayoutAttributeBottom
                                                                multiplier:1.0
                                                                  constant:0.0]];
    
    _headerMinimumHeightConstraint = [NSLayoutConstraint constraintWithItem:_headerView
                                                                  attribute:NSLayoutAttributeHeight
                                                                  relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                     toItem:nil
                                                                  attribute:NSLayoutAttributeNotAnAttribute
                                                                 multiplier:1.0
                                                                   constant:_minimumStepHeaderHeight];
    [_variableConstraints addObject:_headerMinimumHeightConstraint];
    
    {
        // Normally we want extra space, but we don't want to sacrifice that to scrolling (if it makes a difference)
        _stepViewToContinueConstraint = [NSLayoutConstraint constraintWithItem:_continueSkipContainer
                                                                      attribute:NSLayoutAttributeTop
                                                                      relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                         toItem:_stepViewContainer
                                                                      attribute:NSLayoutAttributeBottom
                                                                     multiplier:1.0
                                                                       constant:36.0];
        _stepViewToContinueConstraint.priority = UILayoutPriorityDefaultLow - 2;
        [_variableConstraints addObject:_stepViewToContinueConstraint];
        
        _stepViewToContinueMinimumConstraint = [NSLayoutConstraint constraintWithItem:_continueSkipContainer
                                                                            attribute:NSLayoutAttributeTop
                                                                            relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                               toItem:_stepViewContainer
                                                                            attribute:NSLayoutAttributeBottom
                                                                           multiplier:1.0
                                                                             constant:0.0];
        [_variableConstraints addObject:_stepViewToContinueMinimumConstraint];
    }
    
    _continueContainerToScrollContainerBottomConstraint = [NSLayoutConstraint constraintWithItem:_continueSkipContainer
                                                                                                 attribute:NSLayoutAttributeBottom
                                                                                                 relatedBy:NSLayoutRelationEqual
                                                                                                    toItem:_scrollContainer
                                                                                                 attribute:NSLayoutAttributeBottomMargin
                                                                                                multiplier:1.0
                                                                                                  constant:0.0];
    _continueContainerToScrollContainerBottomConstraint.priority = UILayoutPriorityRequired - 1;
    [_variableConstraints addObject:_continueContainerToScrollContainerBottomConstraint];
    
    // Force all to stay within the container's width.
    for (UIView *view in views) {
#ifdef LAYOUT_DEBUG
        view.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.3];
        view.layer.borderColor = [UIColor redColor].CGColor;
        view.layer.borderWidth = 1.0;
#endif
        if (view == _stepViewContainer) {
            [_variableConstraints addObject:[NSLayoutConstraint constraintWithItem:view
                                                                         attribute:NSLayoutAttributeWidth
                                                                         relatedBy:NSLayoutRelationLessThanOrEqual
                                                                            toItem:_container
                                                                         attribute:NSLayoutAttributeWidth
                                                                        multiplier:1.0
                                                                          constant:0.0]];
        } else {
            
            NSLayoutRelation relation = (view == _continueSkipContainer) ? NSLayoutRelationEqual : NSLayoutRelationGreaterThanOrEqual;
            
            [_variableConstraints addObject:[NSLayoutConstraint constraintWithItem:view
                                                                         attribute:NSLayoutAttributeLeft
                                                                         relatedBy:relation
                                                                            toItem:_container
                                                                         attribute:NSLayoutAttributeLeftMargin
                                                                        multiplier:1.0
                                                                          constant:0.0]];
            [_variableConstraints addObject:[NSLayoutConstraint constraintWithItem:view
                                                                         attribute:NSLayoutAttributeRight
                                                                         relatedBy:relation
                                                                            toItem:_container
                                                                         attribute:NSLayoutAttributeRightMargin
                                                                        multiplier:1.0
                                                                          constant:0.0]];
        }
        [_variableConstraints addObject:[NSLayoutConstraint constraintWithItem:view
                                                                     attribute:NSLayoutAttributeCenterX
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_container
                                                                     attribute:NSLayoutAttributeCenterX
                                                                    multiplier:1.0
                                                                      constant:0.0]];
        
        NSLayoutConstraint *viewToContainerBottomConstraint = [NSLayoutConstraint constraintWithItem:view
                                                                                attribute:NSLayoutAttributeBottom
                                                                                relatedBy:NSLayoutRelationLessThanOrEqual
                                                                                   toItem:_container
                                                                                attribute:NSLayoutAttributeBottom
                                                                               multiplier:1.0
                                                                                 constant:0.0];
        
        // Because the bottom items are not always present, we add individual "bottom" constraints
        // for all views to ensure the parent sizes large enough to contain everything.
        [_variableConstraints addObject:viewToContainerBottomConstraint];
        
        if (view == _continueSkipContainer) {
            _continueContainerToContainerBottomConstraint = viewToContainerBottomConstraint;
        }
    }
    
    [self prepareCustomViewContainerConstraints];
    [self prepareStepViewContainerConstraints];
    [NSLayoutConstraint activateConstraints:_variableConstraints];

    [self updateLayoutMargins];

    [self updateConstraintConstantsForWindow:self.window];
    [self updateStepViewCenteringConstraint];
    [self updateContinueButtonConstraints];

    [super updateConstraints];
}

- (void)prepareStepViewContainerConstraints {
    if (_stepView) {
        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:_stepViewContainer
                                                                           attribute:NSLayoutAttributeWidth
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                                          multiplier:1.0
                                                                            constant:ORK1ScreenMetricMaxDimension];
        widthConstraint.priority = UILayoutPriorityFittingSizeLevel;
        [_variableConstraints addObject:widthConstraint];
        
        [_variableConstraints addObject:[NSLayoutConstraint constraintWithItem:_stepView
                                                                     attribute:NSLayoutAttributeCenterX
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_stepViewContainer
                                                                     attribute:NSLayoutAttributeCenterX
                                                                    multiplier:1.0
                                                                      constant:0.0]];
        
        NSLayoutConstraint *stepViewWidthConstraint = [NSLayoutConstraint constraintWithItem:_stepView
                                                                                   attribute:NSLayoutAttributeWidth
                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                      toItem:_stepViewContainer
                                                                                   attribute:NSLayoutAttributeWidth
                                                                                  multiplier:1.0
                                                                                    constant:0.0];
        stepViewWidthConstraint.priority = UILayoutPriorityRequired;
        [_variableConstraints addObject:stepViewWidthConstraint];
        
        if (_stepViewFillsAvailableSpace) {
            NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:_stepViewContainer
                                                                          attribute:NSLayoutAttributeHeight
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:nil
                                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                                         multiplier:1.0
                                                                           constant:ORK1ScreenMetricMaxDimension];
            constraint.priority = UILayoutPriorityFittingSizeLevel;
            [_variableConstraints addObject:constraint];

            NSLayoutConstraint *verticalCentering = [NSLayoutConstraint constraintWithItem:_stepView
                                                                                 attribute:NSLayoutAttributeCenterY
                                                                                 relatedBy:NSLayoutRelationEqual
                                                                                    toItem:_stepViewContainer
                                                                                 attribute:NSLayoutAttributeCenterY
                                                                                multiplier:1.0
                                                                                  constant:0.0];
            verticalCentering.priority = UILayoutPriorityRequired - 2;
            [_variableConstraints addObject:verticalCentering];
            
            {
                NSLayoutConstraint *verticalCentering2 = [NSLayoutConstraint constraintWithItem:_stepView
                                                                                      attribute:NSLayoutAttributeCenterY
                                                                                      relatedBy:NSLayoutRelationEqual
                                                                                         toItem:_stepViewContainer
                                                                                      attribute:NSLayoutAttributeCenterY
                                                                                     multiplier:1.0
                                                                                       constant:-(AssumedNavBarHeight + AssumedStatusBarHeight) / 2];
                verticalCentering2.priority = UILayoutPriorityRequired - 1;
                [_variableConstraints addObject:verticalCentering2];
                _stepViewCenterInStepViewContainerConstraint = verticalCentering2;
            }
            
            [_variableConstraints addObject:[NSLayoutConstraint constraintWithItem:_stepView
                                                                         attribute:NSLayoutAttributeHeight
                                                                         relatedBy:NSLayoutRelationLessThanOrEqual
                                                                            toItem:_stepViewContainer
                                                                         attribute:NSLayoutAttributeHeight
                                                                        multiplier:1.0
                                                                          constant:0.0]];
        } else {
            [_variableConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[stepView]|"
                                                                                              options:(NSLayoutFormatOptions)0
                                                                                              metrics:nil
                                                                                                views:@{@"stepView": _stepView}]];
        }
    } else {
        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:_stepViewContainer
                                                                           attribute:NSLayoutAttributeWidth
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                                          multiplier:1.0
                                                                            constant:0.0];
        widthConstraint.priority = UILayoutPriorityFittingSizeLevel;
        [_variableConstraints addObject:widthConstraint];
        
        [_variableConstraints addObject:[NSLayoutConstraint constraintWithItem:_stepViewContainer
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:0.0]];
    }
}

- (void)prepareCustomViewContainerConstraints {
    if (_customView) {
        [_variableConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[customView]|"
                                                                                          options:(NSLayoutFormatOptions)0
                                                                                          metrics:nil
                                                                                            views:@{@"customView": _customView}]];
        [_variableConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[customView]|"
                                                                                          options:(NSLayoutFormatOptions)0
                                                                                          metrics:nil
                                                                                            views:@{@"customView": _customView}]];
    }
    if (_imageView) {
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [_variableConstraints addObject:[NSLayoutConstraint constraintWithItem:_imageView
                                                                     attribute:NSLayoutAttributeWidth
                                                                     relatedBy:NSLayoutRelationLessThanOrEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeWidth
                                                                    multiplier:1.0
                                                                      constant:0.0]];
        
        [_variableConstraints addObject:[NSLayoutConstraint constraintWithItem:_imageView
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationLessThanOrEqual
                                                                        toItem:_customViewContainer
                                                                     attribute:NSLayoutAttributeHeight
                                                                    multiplier:1.0
                                                                      constant:0.0]];
        [_variableConstraints addObject:[NSLayoutConstraint constraintWithItem:_imageView
                                                                     attribute:NSLayoutAttributeCenterX
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_customViewContainer
                                                                     attribute:NSLayoutAttributeCenterX
                                                                    multiplier:1.0
                                                                      constant:0.0]];
        [_variableConstraints addObject:[NSLayoutConstraint constraintWithItem:_imageView
                                                                     attribute:NSLayoutAttributeCenterY
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_customViewContainer
                                                                     attribute:NSLayoutAttributeCenterY
                                                                    multiplier:1.0
                                                                      constant:0.0]];
    }
}

- (void)setCustomView:(UIView *)customView {
    [_customView removeFromSuperview];
    _customView = customView;
    [_customViewContainer addSubview:_customView];
    
    if (_customView && [_customView constraints].count == 0) {
        [_customView setTranslatesAutoresizingMaskIntoConstraints:NO];
        CGSize requiredSize = [_customView sizeThatFits:(CGSize){self.bounds.size.width, CGFLOAT_MAX}];
        
        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:_customView
                                                                           attribute:NSLayoutAttributeWidth
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                                          multiplier:1.0
                                                                            constant:requiredSize.width];
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:_customView
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                                           multiplier:1.0
                                                                             constant:requiredSize.height];
        
        widthConstraint.priority = UILayoutPriorityDefaultLow;
        heightConstraint.priority = UILayoutPriorityDefaultLow;
        [NSLayoutConstraint activateConstraints:@[widthConstraint, heightConstraint]];
    }
    [self setNeedsUpdateConstraints];
}

- (UIImageView *)imageView {
    if (_imageView == nil) {
        _imageView = [[ORK1TintedImageView alloc] init];
        [_customViewContainer addSubview:_imageView];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.userInteractionEnabled = YES;
        [self setNeedsUpdateConstraints];
    }
    return _imageView;
}

- (void)setStepView:(ORK1ActiveStepCustomView *)customView {
    [_stepView removeFromSuperview];
    _stepView = customView;
    [_stepViewContainer addSubview:_stepView];
    [self setNeedsUpdateConstraints];
}

- (void)layoutSubviews {
    
    /*
     CEV HACK - Several cases of infinite looping behavior inside of auto-layout have been found
     to crash our apps due to the length of text in an ORK1InstructionStep among the various
     vertically stacked views being at the threshold of causing the the ORK1VerticalContainerView to
     scroll.
     
     This detects excessive looping and adds a carriage return to the subheadLineLabel (text property
     of ORK1InstructionStep) which appears to break the loop by allowing the constraints to be
     satisfied.
     
     Additional carriage returns will be added if the loop persists every 50 iterations.
     
     For more info see: https://github.com/CareEvolution/CEVORK1Kit/issues/116,
     https://github.com/CareEvolution/CEVORK1Kit/issues/136,
     https://github.com/CareEvolution/CEVORK1Kit/issues/152
     */
    
    autoLayoutLoopCount++;
    
    if (autoLayoutLoopCount % 50 == 0 &&
        autoLayoutLoopCount / 50 > carriageReturnsAdded) {
        if (_scrollContainer.subviews.count > 0 && _scrollContainer.subviews[0].subviews.count > 0 && _scrollContainer.subviews[0].subviews[0].subviews.count > 3) {
            UIView *possibleSubheadLineLabel = _scrollContainer.subviews[0].subviews[0].subviews[3];
            if ([possibleSubheadLineLabel isKindOfClass:[ORK1SubheadlineLabel class]]) {
                ORK1SubheadlineLabel *subheadLineLabel = (ORK1SubheadlineLabel *)possibleSubheadLineLabel;
                NSMutableString *updatedText = [NSMutableString stringWithString:subheadLineLabel.text];
                [updatedText appendString:@"\n"];
                subheadLineLabel.text = updatedText;
                carriageReturnsAdded++;
            }
        }
    }
    
    [super layoutSubviews];
}

// CEV HACK
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    autoLayoutLoopCount = 0;
}

@end
