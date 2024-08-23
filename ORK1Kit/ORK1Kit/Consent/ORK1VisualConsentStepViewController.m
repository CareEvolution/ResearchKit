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


#import "ORK1VisualConsentStepViewController.h"

#import "ORK1ContinueButton.h"
#import "ORK1SignatureView.h"
#import "ORK1TintedImageView_Internal.h"

#import "ORK1ConsentSceneViewController_Internal.h"

#import "ORK1ConsentDocument.h"
#import "ORK1ConsentSection_Private.h"
#import "ORK1Result.h"
#import "ORK1StepViewController_Internal.h"
#import "ORK1TaskViewController_Internal.h"
#import "ORK1VisualConsentStep.h"

#import "ORK1Accessibility.h"
#import "ORK1Helpers_Internal.h"
#import "ORK1Observer.h"
#import "ORK1Skin.h"
#import "UIBarButtonItem+ORK1BarButtonItem.h"

#import <MessageUI/MessageUI.h>
#import <QuartzCore/QuartzCore.h>


@interface ORK1VisualConsentStepViewController () <UIPageViewControllerDelegate> {
    BOOL _hasAppeared;
    ORK1StepViewControllerNavigationDirection _navigationDirection;
    
    NSArray *_visualSections;
}

@property (nonatomic, strong) UIPageViewController *pageViewController;

@property (nonatomic, strong) NSMutableDictionary *viewControllers;

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic) NSUInteger currentPage;

@property (nonatomic, strong) ORK1ContinueButton *continueActionButton;

- (ORK1ConsentSceneViewController *)viewControllerForIndex:(NSUInteger)index;
- (NSUInteger)currentIndex;
- (NSUInteger)indexOfViewController:(UIViewController *)viewController;

@end


@interface ORK1AnimationPlaceholderView : UIView

- (void)scrollToTopAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion;

@end


@implementation ORK1AnimationPlaceholderView

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    
    CGRect frame = self.frame;
    frame.size.height = ORK1GetMetricForWindow(ORK1ScreenMetricIllustrationHeight, newWindow);
    self.frame = frame;
}

- (CGPoint)defaultFrameOrigin {
    return (CGPoint){0, ORK1GetMetricForWindow(ORK1ScreenMetricTopToIllustration, self.superview.window)};
}

- (void)scrollToTopAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
    CGRect targetFrame = self.frame;
    targetFrame.origin = [self defaultFrameOrigin];
    if (animated) {
        [UIView animateWithDuration:ORK1ScrollToTopAnimationDuration
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


@implementation ORK1VisualConsentStepViewController

- (void)dealloc {
    [[ORK1TintedImageCache sharedCache] removeAllObjects];
}

- (void)stepDidChange {
    [super stepDidChange];
    {
        NSMutableArray *visualSections = [NSMutableArray new];
        
        NSArray *sections = self.visualConsentStep.consentDocument.sections;
        for (ORK1ConsentSection *scene in sections) {
            if (scene.type != ORK1ConsentSectionTypeOnlyInDocument) {
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
    
    self.view.backgroundColor = ORK1Color(ORK1BackgroundColorKey);
   
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
    
    _pageViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _pageViewController.view.frame = viewBounds;
    [self.view addSubview:_pageViewController.view];
    [self addChildViewController:_pageViewController];
    [_pageViewController didMoveToParentViewController:self];
    
    [self updatePageIndex];
}

- (ORK1VisualConsentStep *)visualConsentStep {
    assert(!self.step || [self.step isKindOfClass:[ORK1VisualConsentStep class]]);
    return (ORK1VisualConsentStep *)self.step;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_pageViewController.viewControllers.count == 0) {

        _hasAppeared = YES;
        
        // Add first viewController
        NSUInteger idx = 0;
        if (_navigationDirection == ORK1StepViewControllerNavigationDirectionReverse) {
            idx = [self pageCount]-1;
        }
        
        [self showViewController:[self viewControllerForIndex:idx] forward:YES animated:NO];
    }
    [self updatePageIndex];
}

- (void)willNavigateDirection:(ORK1StepViewControllerNavigationDirection)direction {
    _navigationDirection = direction;
}

- (UIBarButtonItem *)goToPreviousPageButton {
    UIBarButtonItem *button = [UIBarButtonItem ork_backBarButtonItemWithTarget:self action:@selector(goToPreviousPage)];
    button.accessibilityLabel = ORK1LocalizedString(@"AX_BUTTON_BACK", nil);
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
    ORK1ConsentSceneViewController *currentConsentSceneViewController = [self viewControllerForIndex:[self currentIndex]];
    [currentConsentSceneViewController scrollToTopAnimated:YES completion:^(BOOL finished) {
        if (finished) {
            [self showNextViewController];
        }
    }];
}

- (void)showNextViewController {
    ORK1ConsentSceneViewController *nextConsentSceneViewController = [self viewControllerForIndex:[self currentIndex] + 1];
    [nextConsentSceneViewController scrollToTopAnimated:NO completion:^(BOOL finished) {
        // 'finished' is always YES when not animated
        [self showViewController:nextConsentSceneViewController forward:YES animated:YES];
        ORK1AccessibilityPostNotificationAfterDelay(UIAccessibilityScreenChangedNotification, nil, 0.5);
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

    ORK1ConsentSection *currentSection = (ORK1ConsentSection *)_visualSections[currentIndex];
   
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

- (void)doShowViewController:(ORK1ConsentSceneViewController *)viewController
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
    
    ORK1WeakTypeOf(self) weakSelf = self;
    [self.pageViewController setViewControllers:@[viewController] direction:direction animated:animated completion:^(BOOL finished) {
        ORK1StrongTypeOf(self) strongSelf = weakSelf;
        pageViewControllerView.userInteractionEnabled = YES;
        [strongSelf updatePageIndex];

        if (completion != NULL) {
            completion(finished);
        }
    }];
}

- (ORK1ConsentSection *)consentSectionForIndex:(NSUInteger)index {
    ORK1ConsentSection *consentSection = nil;
    NSArray *visualSections = [self visualSections];
    if (index < visualSections.count) {
        consentSection = visualSections[index];
    }
    return consentSection;
}

- (void)showViewController:(ORK1ConsentSceneViewController *)viewController forward:(BOOL)forward animated:(BOOL)animated {
    [self showViewController:viewController forward:forward animated:animated preloadNextConsentSectionImage:YES];
}

- (void)showViewController:(ORK1ConsentSceneViewController *)viewController forward:(BOOL)forward animated:(BOOL)animated preloadNextConsentSectionImage:(BOOL)preloadNextViewController {
    [self showViewController:viewController
                     forward:forward
                    animated:animated
                  completion:^(BOOL finished) {
                      if (preloadNextViewController) {
                          ORK1ConsentSection *nextConsentSection = [self consentSectionForIndex:[self currentIndex] + 1];
                          ORK1TintedImageView *currentSceneImageView = viewController.sceneView.imageView;
                          [[ORK1TintedImageCache sharedCache] cacheImage:nextConsentSection.image
                                                              tintColor:currentSceneImageView.tintColor
                                                                  scale:currentSceneImageView.window.screen.scale];
                      }
                  }];
}

- (void)showViewController:(ORK1ConsentSceneViewController *)viewController
                   forward:(BOOL)forward
                  animated:(BOOL)animated
                completion:(void (^)(BOOL finished))completion {
    if (!viewController) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    [self.taskViewController setRegisteredScrollView:viewController.scrollView];

    ORK1ConsentSceneViewController *fromViewController = nil;
    NSUInteger currentIndex = [self currentIndex];
    if (currentIndex != NSNotFound) {
        fromViewController = _viewControllers[@(currentIndex)];
    }
    
    UIPageViewControllerNavigationDirection direction = forward ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;

    ORK1AdjustPageViewControllerNavigationDirectionForRTL(&direction);
    
    if (!animated) {
        // No animation at all
        viewController.imageHidden = NO;
        [self doShowViewController:viewController direction:direction animated:animated completion:completion];
    } else {
        [self doShowViewController:viewController direction:direction animated:animated completion:completion];
    }
}

- (ORK1ConsentSceneViewController *)viewControllerForIndex:(NSUInteger)index {
    if (_viewControllers == nil) {
        _viewControllers = [NSMutableDictionary new];
    }
    
    ORK1ConsentSceneViewController *consentViewController = nil;
    
    if (_viewControllers[@(index)]) {
        consentViewController = _viewControllers[@(index)];
    } else if (index >= [self pageCount]) {
        consentViewController = nil;
    } else {
        ORK1ConsentSceneViewController *sceneViewController = [[ORK1ConsentSceneViewController alloc] initWithSection:[self visualSections][index]];
        consentViewController = sceneViewController;
        
        if (index == [self pageCount]-1) {
            sceneViewController.continueButtonItem = self.continueButtonItem;
        } else {
            NSString *buttonTitle = ORK1LocalizedString(@"BUTTON_NEXT", nil);
            if (sceneViewController.section.type == ORK1ConsentSectionTypeOverview) {
                buttonTitle = ORK1LocalizedString(@"BUTTON_GET_STARTED", nil);
            }
            
            sceneViewController.continueButtonItem = [[UIBarButtonItem alloc] initWithTitle:buttonTitle style:UIBarButtonItemStylePlain target:self action:@selector(next)];
        }
    }
    
    if (consentViewController) {
        _viewControllers[@(index)] = consentViewController;
    }
    
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

static NSString *const _ORK1CurrentPageRestoreKey = @"currentPage";
static NSString *const _ORK1HasAppearedRestoreKey = @"hasAppeared";
static NSString *const _ORK1InitialBackButtonRestoreKey = @"initialBackButton";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeInteger:_currentPage forKey:_ORK1CurrentPageRestoreKey];
    [coder encodeBool:_hasAppeared forKey:_ORK1HasAppearedRestoreKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    self.currentPage = [coder decodeIntegerForKey:_ORK1CurrentPageRestoreKey];
    _hasAppeared = [coder decodeBoolForKey:_ORK1HasAppearedRestoreKey];
    
    _viewControllers = nil;
    [self showViewController:[self viewControllerForIndex:_currentPage] forward:YES animated:NO];
}

@end
