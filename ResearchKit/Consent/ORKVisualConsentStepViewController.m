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


#import "ORKVisualConsentStepViewController.h"

#import "ORKContinueButton.h"
#import "ORKSignatureView.h"
#import "ORKTintedImageView_Internal.h"

#import "ORKConsentSceneViewController_Internal.h"

#import "ORKConsentDocument.h"
#import "ORKConsentSection_Private.h"
#import "ORKResult.h"
#import "ORKStepViewController_Internal.h"
#import "ORKTaskViewController_Internal.h"
#import "ORKVisualConsentStep.h"

#import "ORKAccessibility.h"
#import "ORKHelpers_Internal.h"
#import "ORKObserver.h"
#import "ORKSkin.h"
#import "UIBarButtonItem+ORKBarButtonItem.h"

#import <MessageUI/MessageUI.h>
#import <QuartzCore/QuartzCore.h>


@interface ORKVisualConsentStepViewController () <UIPageViewControllerDelegate> {
    BOOL _hasAppeared;
    ORKStepViewControllerNavigationDirection _navigationDirection;
    
    NSArray *_visualSections;
}

@property (nonatomic, strong) UIPageViewController *pageViewController;

@property (nonatomic, strong) NSMutableDictionary *viewControllers;

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic) NSUInteger currentPage;

@property (nonatomic, strong) ORKContinueButton *continueActionButton;

@property (nonatomic, strong) ORKBorderedButton *cancelActionButton;

- (ORKConsentSceneViewController *)viewControllerForIndex:(NSUInteger)index;
- (NSUInteger)currentIndex;
- (NSUInteger)indexOfViewController:(UIViewController *)viewController;

@end


@interface ORKAnimationPlaceholderView : UIView

- (void)scrollToTopAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion;

@end


@implementation ORKAnimationPlaceholderView

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    
    CGRect frame = self.frame;
    frame.size.height = ORKGetMetricForWindow(ORKScreenMetricIllustrationHeight, newWindow);
    self.frame = frame;
}

- (CGPoint)defaultFrameOrigin {
    return (CGPoint){0, ORKGetMetricForWindow(ORKScreenMetricTopToIllustration, self.superview.window)};
}

- (void)scrollToTopAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
    CGRect targetFrame = self.frame;
    targetFrame.origin = [self defaultFrameOrigin];
    if (animated) {
        [UIView animateWithDuration:ORKScrollToTopAnimationDuration
                         animations:^{
            self.frame = targetFrame;
        }  completion:completion];
    } else {
        self.frame = targetFrame;
        if (completion) {
            completion(YES);
        }
    }
}

@end


@implementation ORKVisualConsentStepViewController {
    UIColor *_backgroundColor;
}

- (void)dealloc {
    [[ORKTintedImageCache sharedCache] removeAllObjects];
}

- (void)stepDidChange {
    [super stepDidChange];
    _backgroundColor = [UIColor whiteColor];
    {
        NSMutableArray *visualSections = [NSMutableArray new];
        
        NSArray *sections = self.visualConsentStep.consentDocument.sections;
        for (ORKConsentSection *scene in sections) {
            if (scene.type != ORKConsentSectionTypeOnlyInDocument) {
                [visualSections addObject:scene];
            }
        }
        _visualSections = [visualSections copy];
    }
    
    if (self.step && [self pageCount] == 0) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"Visual consent step has no visible scenes" userInfo:nil];
    }
    
    _viewControllers = nil;
    
    [self showViewController:[self viewControllerForIndex:0] forward:YES animated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect viewBounds = self.view.bounds;
   
    // Prepare pageViewController
    _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                          navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                        options:nil];
    //_pageViewController.dataSource = self;
    _pageViewController.delegate = self;
    
    [self scrollView].bounces = NO;
    
    if ([_pageViewController respondsToSelector:@selector(edgesForExtendedLayout)]) {
        _pageViewController.edgesForExtendedLayout = UIRectEdgeNone;
    }
    [self.view addSubview:_pageViewController.view];
    
    if (ORKNeedWideScreenDesign(self.view)) {
        UIView *_iPadContentView;
        self.view.backgroundColor = ORKColor(ORKBackgroundColorKey);
        [self setiPadBackgroundViewColor:_backgroundColor];
        _iPadContentView = [self viewForiPadLayoutConstraints];
        [_iPadContentView setBackgroundColor:_backgroundColor];
        _pageViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
                                                  [NSLayoutConstraint constraintWithItem:_pageViewController.view
                                                                               attribute:NSLayoutAttributeTop
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:_iPadContentView
                                                                               attribute:NSLayoutAttributeTop
                                                                              multiplier:1.0
                                                                                constant:0.0],
                                                  [NSLayoutConstraint constraintWithItem:_pageViewController.view
                                                                               attribute:NSLayoutAttributeLeft
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:_iPadContentView
                                                                               attribute:NSLayoutAttributeLeft
                                                                              multiplier:1.0
                                                                                constant:0.0],
                                                  [NSLayoutConstraint constraintWithItem:_pageViewController.view
                                                                               attribute:NSLayoutAttributeRight
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:_iPadContentView
                                                                               attribute:NSLayoutAttributeRight
                                                                              multiplier:1.0
                                                                                constant:0.0],
                                                  [NSLayoutConstraint constraintWithItem:_pageViewController.view
                                                                               attribute:NSLayoutAttributeBottom
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:_iPadContentView
                                                                               attribute:NSLayoutAttributeBottom
                                                                              multiplier:1.0
                                                                                constant:0.0],
                                                  ]];
    }
    else {
        
        _pageViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _pageViewController.view.frame = viewBounds;
        
        self.view.backgroundColor = ORKColor(ORKConsentBackgroundColorKey);
    }
    
    
    [self addChildViewController:_pageViewController];
    [_pageViewController didMoveToParentViewController:self];
    
    if (self.taskViewController.navigationBar) {
        [self.taskViewController.navigationBar setBarTintColor:self.view.backgroundColor];
    }
    
    [self updatePageIndex];
}

- (ORKVisualConsentStep *)visualConsentStep {
    assert(!self.step || [self.step isKindOfClass:[ORKVisualConsentStep class]]);
    return (ORKVisualConsentStep *)self.step;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_pageViewController.viewControllers.count == 0) {

        _hasAppeared = YES;
        
        // Add first viewController
        NSUInteger idx = 0;
        if (_navigationDirection == ORKStepViewControllerNavigationDirectionReverse) {
            idx = [self pageCount]-1;
        }
        
        [self showViewController:[self viewControllerForIndex:idx] forward:YES animated:NO];
    }
    [self updatePageIndex];
}

- (void)willNavigateDirection:(ORKStepViewControllerNavigationDirection)direction {
    _navigationDirection = direction;
}

- (UIBarButtonItem *)goToPreviousPageButton {
    UIBarButtonItem *button = [UIBarButtonItem ork_backBarButtonItemWithTarget:self action:@selector(goToPreviousPage)];
    button.accessibilityLabel = ORKLocalizedString(@"AX_BUTTON_BACK", nil);
    return button;
}

- (void)ork_setBackButtonItem:(UIBarButtonItem *)backButton {
    [super ork_setBackButtonItem:backButton];
}

- (void)updateNavLeftBarButtonItem {
    if ([self currentIndex] == 0) {
        [super updateNavLeftBarButtonItem];
    } else {
        self.navigationItem.leftBarButtonItem = [self goToPreviousPageButton];
    }
}

- (void)updateBackButton {
    if (!_hasAppeared) {
        return;
    }
    
    [self updateNavLeftBarButtonItem];
}

#pragma mark - actions

- (IBAction)goToPreviousPage {
    [self showViewController:[self viewControllerForIndex:[self currentIndex]-1] forward:NO animated:YES preloadNextConsentSectionImage:NO];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (IBAction)next {
    ORKConsentSceneViewController *currentConsentSceneViewController = [self viewControllerForIndex:[self currentIndex]];
    [currentConsentSceneViewController scrollToTopAnimated:YES completion:^(BOOL finished) {
        if (finished) {
            [self showNextViewController];
        }
    }];
}

- (void)showNextViewController {
    ORKConsentSceneViewController *nextConsentSceneViewController = [self viewControllerForIndex:[self currentIndex] + 1];
    [nextConsentSceneViewController scrollToTopAnimated:NO completion:^(BOOL finished) {
        // 'finished' is always YES when not animated
        [self showViewController:nextConsentSceneViewController forward:YES animated:YES];
        ORKAccessibilityPostNotificationAfterDelay(UIAccessibilityScreenChangedNotification, nil, 0.5);
    }];
}

#pragma mark - internal

- (UIScrollView *)scrollView {
    if (_scrollView == nil) {
        for (UIView *view in self.pageViewController.view.subviews) {
            if ([view isKindOfClass:[UIScrollView class]]) {
                _scrollView = (UIScrollView *)view;
                break;
            }
        }
    }
    return _scrollView;
}

- (void)updatePageIndex {
    NSUInteger currentIndex = [self currentIndex];
    if (currentIndex == NSNotFound) {
        return;
    }
    
    _currentPage = currentIndex;
    
    [self updateBackButton];

    ORKConsentSection *currentSection = (ORKConsentSection *)_visualSections[currentIndex];
    
    if ([[self visualConsentDelegate] respondsToSelector:@selector(visualConsentStepViewController:didShowSection:sectionIndex:)]) {
        [[self visualConsentDelegate] visualConsentStepViewController:self didShowSection:currentSection sectionIndex:currentIndex];
    }
}

- (void)setScrollEnabled:(BOOL)enabled {
    [[self scrollView] setScrollEnabled:enabled];
}

- (NSArray *)visualSections {
    return _visualSections;
}

- (NSUInteger)pageCount {
    return _visualSections.count;
}

- (UIImageView *)findHairlineImageViewUnder:(UIView *)view {
    if ([view isKindOfClass:UIImageView.class] && view.bounds.size.height <= 1.0) {
        return (UIImageView *)view;
    }
    for (UIView *subview in view.subviews) {
        UIImageView *imageView = [self findHairlineImageViewUnder:subview];
        if (imageView) {
            return imageView;
        }
    }
    return nil;
}

- (void)doShowViewController:(ORKConsentSceneViewController *)viewController
                   direction:(UIPageViewControllerNavigationDirection)direction
                    animated:(BOOL)animated
                  completion:(void (^)(BOOL finished))completion {
    UIView *pageViewControllerView = self.pageViewController.view;
    pageViewControllerView.userInteractionEnabled = NO;
    
    if (!viewController || !self.pageViewController) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    
    if (ORKNeedWideScreenDesign(self.view)) {
        [self setiPadStepTitleLabelText:viewController.title];
    }
    else {
        self.title = viewController.title;
    }
    
    ORKWeakTypeOf(self) weakSelf = self;
    [self.pageViewController setViewControllers:@[viewController] direction:direction animated:animated completion:^(BOOL finished) {
        ORKStrongTypeOf(self) strongSelf = weakSelf;
        pageViewControllerView.userInteractionEnabled = YES;
        [strongSelf updatePageIndex];

        if (completion != NULL) {
            completion(finished);
        }
    }];
}

- (ORKConsentSection *)consentSectionForIndex:(NSUInteger)index {
    ORKConsentSection *consentSection = nil;
    NSArray *visualSections = [self visualSections];
    if (index < visualSections.count) {
        consentSection = visualSections[index];
    }
    return consentSection;
}

- (void)showViewController:(ORKConsentSceneViewController *)viewController forward:(BOOL)forward animated:(BOOL)animated {
    [self showViewController:viewController forward:forward animated:animated preloadNextConsentSectionImage:YES];
}

- (void)showViewController:(ORKConsentSceneViewController *)viewController forward:(BOOL)forward animated:(BOOL)animated preloadNextConsentSectionImage:(BOOL)preloadNextViewController {
    [self showViewController:viewController
                     forward:forward
                    animated:animated
                  completion:^(BOOL finished) {
                      if (preloadNextViewController) {
                          ORKConsentSection *nextConsentSection = [self consentSectionForIndex:[self currentIndex] + 1];
                          ORKTintedImageView *currentSceneImageView = viewController.sceneView.imageView;
                          [[ORKTintedImageCache sharedCache] cacheImage:nextConsentSection.image
                                                              tintColor:currentSceneImageView.tintColor
                                                                  scale:currentSceneImageView.window.screen.scale];
                      }
                  }];
}

- (void)showViewController:(ORKConsentSceneViewController *)viewController
                   forward:(BOOL)forward
                  animated:(BOOL)animated
                completion:(void (^)(BOOL finished))completion {
    if (!viewController) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    // Stop old hairline scroll view observer and start new one
    [self.taskViewController setRegisteredScrollView:viewController.sceneView];

    ORKConsentSceneViewController *fromViewController = nil;
    NSUInteger currentIndex = [self currentIndex];
    if (currentIndex != NSNotFound) {
        fromViewController = _viewControllers[@(currentIndex)];
    }
    
    UIPageViewControllerNavigationDirection direction = forward ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;

    ORKAdjustPageViewControllerNavigationDirectionForRTL(&direction);
    
    if (!animated) {
        // No animation at all
        viewController.imageHidden = NO;
        [self doShowViewController:viewController direction:direction animated:animated completion:completion];
    } else {
        [self doShowViewController:viewController direction:direction animated:animated completion:completion];
    }
}

- (ORKConsentSceneViewController *)viewControllerForIndex:(NSUInteger)index {
    if (_viewControllers == nil) {
        _viewControllers = [NSMutableDictionary new];
    }
    
    ORKConsentSceneViewController *consentViewController = nil;
    
    if (_viewControllers[@(index)]) {
        consentViewController = _viewControllers[@(index)];
    } else if (index >= [self pageCount]) {
        consentViewController = nil;
    } else {
        ORKConsentSceneViewController *sceneViewController = [[ORKConsentSceneViewController alloc] initWithSection:[self visualSections][index]];
        consentViewController = sceneViewController;
        
        if (index == [self pageCount]-1) {
            sceneViewController.continueButtonItem = self.continueButtonItem;
        } else {
            NSString *buttonTitle = ORKLocalizedString(@"BUTTON_NEXT", nil);
            if (sceneViewController.section.type == ORKConsentSectionTypeOverview) {
                buttonTitle = ORKLocalizedString(@"BUTTON_GET_STARTED", nil);
            }
            
            sceneViewController.continueButtonItem = [[UIBarButtonItem alloc] initWithTitle:buttonTitle style:UIBarButtonItemStylePlain target:self action:@selector(next)];
        }
    }
    
    if (consentViewController) {
        _viewControllers[@(index)] = consentViewController;
    }
    
    consentViewController.cancelButtonItem = self.cancelButtonItem;
    return consentViewController;
}

- (NSUInteger)indexOfViewController:(UIViewController *)viewController {
    if (!viewController) {
        return NSNotFound;
    }
    
    NSUInteger index = NSNotFound;
    for (NSNumber *key in _viewControllers) {
        if (_viewControllers[key] == viewController) {
            index = key.unsignedIntegerValue;
            break;
        }
    }
    return index;
}

- (NSUInteger)currentIndex {
    return [self indexOfViewController:_pageViewController.viewControllers.firstObject];
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger index = [self indexOfViewController:viewController];
    if (index == NSNotFound) {
        return nil;
    }
    
    return [self viewControllerForIndex:index - 1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger index = [self indexOfViewController:viewController];
    if (index == NSNotFound) {
        return nil;
    }
    
    return [self viewControllerForIndex:index + 1];
}

#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    if (finished && completed) {
        [self updatePageIndex];
    }
}

static NSString *const _ORKCurrentPageRestoreKey = @"currentPage";
static NSString *const _ORKHasAppearedRestoreKey = @"hasAppeared";
static NSString *const _ORKInitialBackButtonRestoreKey = @"initialBackButton";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeInteger:_currentPage forKey:_ORKCurrentPageRestoreKey];
    [coder encodeBool:_hasAppeared forKey:_ORKHasAppearedRestoreKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    self.currentPage = [coder decodeIntegerForKey:_ORKCurrentPageRestoreKey];
    _hasAppeared = [coder decodeBoolForKey:_ORKHasAppearedRestoreKey];
    
    _viewControllers = nil;
    [self showViewController:[self viewControllerForIndex:_currentPage] forward:YES animated:NO];
}

@end
