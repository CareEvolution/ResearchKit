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
#import "ORKEAGLMoviePlayerView.h"
#import "ORKSignatureView.h"
#import "ORKTintedImageView_Internal.h"

#import "ORKConsentSceneViewController_Internal.h"
#import "ORKVisualConsentTransitionAnimator.h"

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


@interface ORKLegacyVisualConsentStepViewController () <UIPageViewControllerDelegate, ORKLegacyScrollViewObserverDelegate> {
    BOOL _hasAppeared;
    ORKLegacyStepViewControllerNavigationDirection _navigationDirection;
    
    ORKLegacyVisualConsentTransitionAnimator *_animator;
    
    NSArray *_visualSections;
    
    ORKLegacyScrollViewObserver *_scrollViewObserver;
}

@property (nonatomic, strong) UIPageViewController *pageViewController;

@property (nonatomic, strong) NSMutableDictionary *viewControllers;

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic) NSUInteger currentPage;

@property (nonatomic, strong) ORKLegacyContinueButton *continueActionButton;

- (ORKLegacyConsentSceneViewController *)viewControllerForIndex:(NSUInteger)index;
- (NSUInteger)currentIndex;
- (NSUInteger)indexOfViewController:(UIViewController *)viewController;

@end


@interface ORKLegacyAnimationPlaceholderView : UIView

@property (nonatomic, strong) ORKLegacyEAGLMoviePlayerView *playerView;

- (void)scrollToTopAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion;

@end


@implementation ORKLegacyAnimationPlaceholderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _playerView = [ORKLegacyEAGLMoviePlayerView new];
        _playerView.hidden = YES;
        [self addSubview:_playerView];
    }
    return self;
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    
    CGRect frame = self.frame;
    frame.size.height = ORKLegacyGetMetricForWindow(ORKLegacyScreenMetricIllustrationHeight, newWindow);
    self.frame = frame;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _playerView.frame = self.bounds;
}

- (CGPoint)defaultFrameOrigin {
    return (CGPoint){0, ORKLegacyGetMetricForWindow(ORKLegacyScreenMetricTopToIllustration, self.superview.window)};
}

- (void)scrollToTopAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
    CGRect targetFrame = self.frame;
    targetFrame.origin = [self defaultFrameOrigin];
    if (animated) {
        [UIView animateWithDuration:ORKLegacyScrollToTopAnimationDuration
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


@implementation ORKLegacyVisualConsentStepViewController

- (void)dealloc {
    [[ORKLegacyTintedImageCache sharedCache] removeAllObjects];
}

- (void)stepDidChange {
    [super stepDidChange];
    {
        NSMutableArray *visualSections = [NSMutableArray new];
        
        NSArray *sections = self.visualConsentStep.consentDocument.sections;
        for (ORKLegacyConsentSection *scene in sections) {
            if (scene.type != ORKLegacyConsentSectionTypeOnlyInDocument) {
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

- (ORKLegacyEAGLMoviePlayerView *)animationPlayerView {
    return [(ORKLegacyAnimationPlaceholderView *)_animationView playerView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect viewBounds = self.view.bounds;
    
    self.view.backgroundColor = ORKLegacyColor(ORKLegacyBackgroundColorKey);
   
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
    
    self.animationView = [[ORKLegacyAnimationPlaceholderView alloc] initWithFrame:
                          (CGRect){{0, 0}, {viewBounds.size.width, ORKLegacyGetMetricForWindow(ORKLegacyScreenMetricIllustrationHeight, self.view.window)}}];
    _animationView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
    _animationView.backgroundColor = [UIColor clearColor];
    _animationView.userInteractionEnabled = NO;
    [self.view addSubview:_animationView];
    
    [self updatePageIndex];
}

- (ORKLegacyVisualConsentStep *)visualConsentStep {
    assert(!self.step || [self.step isKindOfClass:[ORKLegacyVisualConsentStep class]]);
    return (ORKLegacyVisualConsentStep *)self.step;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_pageViewController.viewControllers.count == 0) {

        _hasAppeared = YES;
        
        // Add first viewController
        NSUInteger idx = 0;
        if (_navigationDirection == ORKLegacyStepViewControllerNavigationDirectionReverse) {
            idx = [self pageCount]-1;
        }
        
        [self showViewController:[self viewControllerForIndex:idx] forward:YES animated:NO];
    }
    [self updatePageIndex];
}

- (void)willNavigateDirection:(ORKLegacyStepViewControllerNavigationDirection)direction {
    _navigationDirection = direction;
}

- (UIBarButtonItem *)goToPreviousPageButton {
    UIBarButtonItem *button = [UIBarButtonItem ork_backBarButtonItemWithTarget:self action:@selector(goToPreviousPage)];
    button.accessibilityLabel = ORKLegacyLocalizedString(@"AX_BUTTON_BACK", nil);
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
    ORKLegacyConsentSceneViewController *currentConsentSceneViewController = [self viewControllerForIndex:[self currentIndex]];
    [(ORKLegacyAnimationPlaceholderView *)_animationView scrollToTopAnimated:YES completion:nil];
    [currentConsentSceneViewController scrollToTopAnimated:YES completion:^(BOOL finished) {
        if (finished) {
            [self showNextViewController];
        }
    }];
}

- (void)showNextViewController {
    CGRect animationViewFrame = _animationView.frame;
    animationViewFrame.origin = [ORKLegacyDynamicCast(_animationView, ORKLegacyAnimationPlaceholderView) defaultFrameOrigin];
    _animationView.frame = animationViewFrame;
    ORKLegacyConsentSceneViewController *nextConsentSceneViewController = [self viewControllerForIndex:[self currentIndex] + 1];
    [(ORKLegacyAnimationPlaceholderView *)_animationView scrollToTopAnimated:NO completion:nil];
    [nextConsentSceneViewController scrollToTopAnimated:NO completion:^(BOOL finished) {
        // 'finished' is always YES when not animated
        [self showViewController:nextConsentSceneViewController forward:YES animated:YES];
        ORKLegacyAccessibilityPostNotificationAfterDelay(UIAccessibilityScreenChangedNotification, nil, 0.5);
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

    ORKLegacyConsentSection *currentSection = (ORKLegacyConsentSection *)_visualSections[currentIndex];
    if (currentSection.type == ORKLegacyConsentSectionTypeOverview) {
        _animationView.isAccessibilityElement = NO;
    } else {
        _animationView.isAccessibilityElement = YES;
        _animationView.accessibilityLabel = [NSString stringWithFormat:ORKLegacyLocalizedString(@"AX_IMAGE_ILLUSTRATION", nil), currentSection.title];
        _animationView.accessibilityTraits |= UIAccessibilityTraitImage;
    }
    
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

- (void)doShowViewController:(ORKLegacyConsentSceneViewController *)viewController
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
    
    ORKLegacyWeakTypeOf(self) weakSelf = self;
    [self.pageViewController setViewControllers:@[viewController] direction:direction animated:animated completion:^(BOOL finished) {
        ORKLegacyStrongTypeOf(self) strongSelf = weakSelf;
        pageViewControllerView.userInteractionEnabled = YES;
        [strongSelf updatePageIndex];

        if (completion != NULL) {
            completion(finished);
        }
    }];
}

- (void)doAnimateFromViewController:(ORKLegacyConsentSceneViewController *)fromViewController
                       toController:(ORKLegacyConsentSceneViewController *)toViewController
                          direction:(UIPageViewControllerNavigationDirection)direction
                                url:(NSURL *)url
            animateBeforeTransition:(BOOL)animateBeforeTransition
            transitionBeforeAnimate:(BOOL)transitionBeforeAnimate
                         completion:(void (^)(BOOL finished))completion {

    NSAssert(url, @"url cannot be nil");
    NSAssert(!(animateBeforeTransition && transitionBeforeAnimate), @"Both flags cannot be set");

    ORKLegacyWeakTypeOf(self) weakSelf = self;
    void (^finishAndNilAnimator)(ORKLegacyVisualConsentTransitionAnimator *animator) = ^(ORKLegacyVisualConsentTransitionAnimator *animator) {
        ORKLegacyStrongTypeOf(self) strongSelf = weakSelf;
        [animator finish];
        if (strongSelf && strongSelf->_animator == animator) {
            // Do not show images and hide animationPlayerView if it's not the current animator
            fromViewController.imageHidden = NO;
            toViewController.imageHidden = NO;
            [strongSelf animationPlayerView].hidden = YES;
            strongSelf->_animator = nil;
        }
    };

    ORKLegacyVisualConsentTransitionAnimator *animator = [[ORKLegacyVisualConsentTransitionAnimator alloc] initWithVisualConsentStepViewController:self movieURL:url];
    _animator = animator;

    __block BOOL transitionFinished = NO;
    __block BOOL animatorFinished = NO;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // The semaphore waits for both 'animateTransitionWithDirection:loadHandler:completionHandler:' and
        // 'doShowViewController:direction:animated:completion:' methods to complete (both of these methods
        // signal the semaphore on completion). It doesn't matter which of the two finishes first.
        // Defensive 5-second timeout in case the animator doesn't complete.
        BOOL semaphoreATimedOut = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 5));
        BOOL semaphoreBTimedOut = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 5));
        
        if (semaphoreATimedOut || semaphoreBTimedOut) {
            ORKLegacy_Log_Debug(@"[Semaphore timed out] semaphoreATimedOut: %d, semaphoreBTimedOut: %d, transitionFinished: %d, animatorFinished: %d", semaphoreATimedOut, semaphoreBTimedOut, transitionFinished, animatorFinished);
        }
            
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL animationAndTransitionFinished = (transitionFinished && animatorFinished);

            if (!animatorFinished) {
                finishAndNilAnimator(animator);
            }
            
            if (completion) {
                completion(animationAndTransitionFinished);
            }
        });
    });

    if (!animateBeforeTransition && !transitionBeforeAnimate) {
        [_animator animateTransitionWithDirection:direction
                                      loadHandler:^(ORKLegacyVisualConsentTransitionAnimator *animator, UIPageViewControllerNavigationDirection direction) {
                                          
                                          fromViewController.imageHidden = YES;
                                          toViewController.imageHidden = YES;
                                          
                                          ORKLegacyStrongTypeOf(self) strongSelf = weakSelf;
                                          [strongSelf doShowViewController:toViewController
                                                                 direction:direction
                                                                  animated:YES
                                                                completion:^(BOOL finished) {
                                                                    
                                                                    transitionFinished = finished;
                                                                    dispatch_semaphore_signal(semaphore);
                                                                }];
                                      }
                                completionHandler:^(ORKLegacyVisualConsentTransitionAnimator *animator, UIPageViewControllerNavigationDirection direction) {
        
                                    animatorFinished = YES;
                                    finishAndNilAnimator(animator);
                                    dispatch_semaphore_signal(semaphore);
                                }];
        
    } else if (animateBeforeTransition && !transitionBeforeAnimate) {
        [_animator animateTransitionWithDirection:direction
                                      loadHandler:^(ORKLegacyVisualConsentTransitionAnimator *animator, UIPageViewControllerNavigationDirection direction) {
                                          
                                          fromViewController.imageHidden = YES;
                                      }
                                completionHandler:^(ORKLegacyVisualConsentTransitionAnimator *animator, UIPageViewControllerNavigationDirection direction) {
                                    
                                    animatorFinished = YES;
                                    finishAndNilAnimator(animator);
                                    
                                    ORKLegacyStrongTypeOf(self) strongSelf = weakSelf;
                                    [strongSelf doShowViewController:toViewController
                                                           direction:direction
                                                            animated:YES
                                                          completion:^(BOOL finished) {
                                                              
                                                              transitionFinished = finished;
                                                              dispatch_semaphore_signal(semaphore);
                                                          }];
                                    
                                    dispatch_semaphore_signal(semaphore);
                                }];

    } else if (!animateBeforeTransition && transitionBeforeAnimate) {
        toViewController.imageHidden = YES;
        [self doShowViewController:toViewController
                         direction:direction
                          animated:YES
                        completion:^(BOOL finished) {
                            
                            transitionFinished = finished;
                            
                            [_animator animateTransitionWithDirection:direction
                                                          loadHandler:nil
                                                    completionHandler:^(ORKLegacyVisualConsentTransitionAnimator *animator, UIPageViewControllerNavigationDirection direction) {
                                                        
                                                        animatorFinished = YES;
                                                        finishAndNilAnimator(animator);
                                                        dispatch_semaphore_signal(semaphore);
                                                    }];
                            
                            dispatch_semaphore_signal(semaphore);
                        }];
    }
}

- (void)observedScrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == _scrollViewObserver.target) {
        CGRect animationViewFrame = _animationView.frame;
        CGPoint scrollViewBoundsOrigin = scrollView.bounds.origin;
        CGPoint defaultFrameOrigin = [ORKLegacyDynamicCast(_animationView, ORKLegacyAnimationPlaceholderView) defaultFrameOrigin];
        animationViewFrame.origin = (CGPoint){defaultFrameOrigin.x - scrollViewBoundsOrigin.x, defaultFrameOrigin.y - scrollViewBoundsOrigin.y};
        _animationView.frame = animationViewFrame;
    }
}

- (ORKLegacyConsentSection *)consentSectionForIndex:(NSUInteger)index {
    ORKLegacyConsentSection *consentSection = nil;
    NSArray *visualSections = [self visualSections];
    if (index < visualSections.count) {
        consentSection = visualSections[index];
    }
    return consentSection;
}

- (void)showViewController:(ORKLegacyConsentSceneViewController *)viewController forward:(BOOL)forward animated:(BOOL)animated {
    [self showViewController:viewController forward:forward animated:animated preloadNextConsentSectionImage:YES];
}

- (void)showViewController:(ORKLegacyConsentSceneViewController *)viewController forward:(BOOL)forward animated:(BOOL)animated preloadNextConsentSectionImage:(BOOL)preloadNextViewController {
    [self showViewController:viewController
                     forward:forward
                    animated:animated
                  completion:^(BOOL finished) {
                      if (preloadNextViewController) {
                          ORKLegacyConsentSection *nextConsentSection = [self consentSectionForIndex:[self currentIndex] + 1];
                          ORKLegacyTintedImageView *currentSceneImageView = viewController.sceneView.imageView;
                          [[ORKLegacyTintedImageCache sharedCache] cacheImage:nextConsentSection.image
                                                              tintColor:currentSceneImageView.tintColor
                                                                  scale:currentSceneImageView.window.screen.scale];
                      }
                  }];
}

- (void)showViewController:(ORKLegacyConsentSceneViewController *)viewController
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
    _scrollViewObserver = [[ORKLegacyScrollViewObserver alloc] initWithTargetView:viewController.scrollView delegate:self];
    [self.taskViewController setRegisteredScrollView:viewController.scrollView];

    ORKLegacyConsentSceneViewController *fromViewController = nil;
    NSUInteger currentIndex = [self currentIndex];
    if (currentIndex == NSNotFound) {
        animated = NO;
    } else {
        fromViewController = _viewControllers[@(currentIndex)];
    }
    
    // Cancel any previous video animation
    fromViewController.imageHidden = NO;
    viewController.imageHidden = NO;
    if (_animator) {
        [self animationPlayerView].hidden = YES;
        [_animator finish];
        _animator = nil;
    }
    
    UIPageViewControllerNavigationDirection direction = forward ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;

    ORKLegacyAdjustPageViewControllerNavigationDirectionForRTL(&direction);
    
    if (!animated) {
        // No animation at all
        viewController.imageHidden = NO;
        [self doShowViewController:viewController direction:direction animated:animated completion:completion];
    } else {
        NSUInteger toIndex = [self indexOfViewController:viewController];
        
        NSURL *url = nil;
        BOOL animateBeforeTransition = NO;
        BOOL transitionBeforeAnimate = NO;
        
        ORKLegacyConsentSectionType currentSection = [(ORKLegacyConsentSection *)_visualSections[currentIndex] type];
        ORKLegacyConsentSectionType destinationSection = (toIndex != NSNotFound) ? [(ORKLegacyConsentSection *)_visualSections[toIndex] type] : ORKLegacyConsentSectionTypeCustom;
        
        // Only use video animation when going forward
        if (toIndex > currentIndex) {
            
            // Use the custom animation URL, if there is one for the destination index.
            if (toIndex != NSNotFound && toIndex < _visualSections.count) {
                url = [ORKLegacyDynamicCast(_visualSections[toIndex], ORKLegacyConsentSection) customAnimationURL];
            }
            BOOL isCustomURL = (url != nil);
            
            // If there's no custom URL, use an animation only if transitioning in the expected order.
            // Exception for datagathering, which does an arrival animation AFTER.
            if (!isCustomURL) {
                if (destinationSection == ORKLegacyConsentSectionTypeDataGathering) {
                    transitionBeforeAnimate = YES;
                    url = ORKLegacyMovieURLForConsentSectionType(ORKLegacyConsentSectionTypeOverview);
                } else if ((destinationSection - currentSection) == 1) {
                    url = ORKLegacyMovieURLForConsentSectionType(currentSection);
                }
            }
        }
        
        if (!url) {
            // No video animation URL, just a regular push transition animation.
            [self doShowViewController:viewController direction:direction animated:animated completion:completion];
        } else {
            [self doAnimateFromViewController:fromViewController
                                 toController:viewController
                                    direction:direction
                                          url:url
                      animateBeforeTransition:animateBeforeTransition
                      transitionBeforeAnimate:transitionBeforeAnimate
                                   completion:completion];
        }
    }
}

- (ORKLegacyConsentSceneViewController *)viewControllerForIndex:(NSUInteger)index {
    if (_viewControllers == nil) {
        _viewControllers = [NSMutableDictionary new];
    }
    
    ORKLegacyConsentSceneViewController *consentViewController = nil;
    
    if (_viewControllers[@(index)]) {
        consentViewController = _viewControllers[@(index)];
    } else if (index >= [self pageCount]) {
        consentViewController = nil;
    } else {
        ORKLegacyConsentSceneViewController *sceneViewController = [[ORKLegacyConsentSceneViewController alloc] initWithSection:[self visualSections][index]];
        consentViewController = sceneViewController;
        
        if (index == [self pageCount]-1) {
            sceneViewController.continueButtonItem = self.continueButtonItem;
        } else {
            NSString *buttonTitle = ORKLegacyLocalizedString(@"BUTTON_NEXT", nil);
            if (sceneViewController.section.type == ORKLegacyConsentSectionTypeOverview) {
                buttonTitle = ORKLegacyLocalizedString(@"BUTTON_GET_STARTED", nil);
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

static NSString *const _ORKLegacyCurrentPageRestoreKey = @"currentPage";
static NSString *const _ORKLegacyHasAppearedRestoreKey = @"hasAppeared";
static NSString *const _ORKLegacyInitialBackButtonRestoreKey = @"initialBackButton";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeInteger:_currentPage forKey:_ORKLegacyCurrentPageRestoreKey];
    [coder encodeBool:_hasAppeared forKey:_ORKLegacyHasAppearedRestoreKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    self.currentPage = [coder decodeIntegerForKey:_ORKLegacyCurrentPageRestoreKey];
    _hasAppeared = [coder decodeBoolForKey:_ORKLegacyHasAppearedRestoreKey];
    
    _viewControllers = nil;
    [self showViewController:[self viewControllerForIndex:_currentPage] forward:YES animated:NO];
}

@end
