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


@interface ORK1VisualConsentStepViewController () <UIPageViewControllerDelegate, ORK1ScrollViewObserverDelegate> {
    BOOL _hasAppeared;
    ORK1StepViewControllerNavigationDirection _navigationDirection;
    
    ORK1VisualConsentTransitionAnimator *_animator;
    
    NSArray *_visualSections;
    
    ORK1ScrollViewObserver *_scrollViewObserver;
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

@property (nonatomic, strong) ORK1EAGLMoviePlayerView *playerView;

- (void)scrollToTopAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion;

@end


@implementation ORK1AnimationPlaceholderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _playerView = [ORK1EAGLMoviePlayerView new];
        _playerView.hidden = YES;
        [self addSubview:_playerView];
    }
    return self;
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    
    CGRect frame = self.frame;
    frame.size.height = ORK1GetMetricForWindow(ORK1ScreenMetricIllustrationHeight, newWindow);
    self.frame = frame;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _playerView.frame = self.bounds;
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

- (ORK1EAGLMoviePlayerView *)animationPlayerView {
    return [(ORK1AnimationPlaceholderView *)_animationView playerView];
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
    
    self.animationView = [[ORK1AnimationPlaceholderView alloc] initWithFrame:
                          (CGRect){{0, 0}, {viewBounds.size.width, ORK1GetMetricForWindow(ORK1ScreenMetricIllustrationHeight, self.view.window)}}];
    _animationView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
    _animationView.backgroundColor = [UIColor clearColor];
    _animationView.userInteractionEnabled = NO;
    [self.view addSubview:_animationView];
    
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
    [(ORK1AnimationPlaceholderView *)_animationView scrollToTopAnimated:YES completion:nil];
    [currentConsentSceneViewController scrollToTopAnimated:YES completion:^(BOOL finished) {
        if (finished) {
            [self showNextViewController];
        }
    }];
}

- (void)showNextViewController {
    CGRect animationViewFrame = _animationView.frame;
    animationViewFrame.origin = [ORK1DynamicCast(_animationView, ORK1AnimationPlaceholderView) defaultFrameOrigin];
    _animationView.frame = animationViewFrame;
    ORK1ConsentSceneViewController *nextConsentSceneViewController = [self viewControllerForIndex:[self currentIndex] + 1];
    [(ORK1AnimationPlaceholderView *)_animationView scrollToTopAnimated:NO completion:nil];
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
    if (currentSection.type == ORK1ConsentSectionTypeOverview) {
        _animationView.isAccessibilityElement = NO;
    } else {
        _animationView.isAccessibilityElement = YES;
        _animationView.accessibilityLabel = [NSString stringWithFormat:ORK1LocalizedString(@"AX_IMAGE_ILLUSTRATION", nil), currentSection.title];
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

- (void)doAnimateFromViewController:(ORK1ConsentSceneViewController *)fromViewController
                       toController:(ORK1ConsentSceneViewController *)toViewController
                          direction:(UIPageViewControllerNavigationDirection)direction
                                url:(NSURL *)url
            animateBeforeTransition:(BOOL)animateBeforeTransition
            transitionBeforeAnimate:(BOOL)transitionBeforeAnimate
                         completion:(void (^)(BOOL finished))completion {

    NSAssert(url, @"url cannot be nil");
    NSAssert(!(animateBeforeTransition && transitionBeforeAnimate), @"Both flags cannot be set");

    ORK1WeakTypeOf(self) weakSelf = self;
    void (^finishAndNilAnimator)(ORK1VisualConsentTransitionAnimator *animator) = ^(ORK1VisualConsentTransitionAnimator *animator) {
        ORK1StrongTypeOf(self) strongSelf = weakSelf;
        [animator finish];
        if (strongSelf && strongSelf->_animator == animator) {
            // Do not show images and hide animationPlayerView if it's not the current animator
            fromViewController.imageHidden = NO;
            toViewController.imageHidden = NO;
            [strongSelf animationPlayerView].hidden = YES;
            strongSelf->_animator = nil;
        }
    };

    ORK1VisualConsentTransitionAnimator *animator = [[ORK1VisualConsentTransitionAnimator alloc] initWithVisualConsentStepViewController:self movieURL:url];
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
            ORK1_Log_Debug(@"[Semaphore timed out] semaphoreATimedOut: %d, semaphoreBTimedOut: %d, transitionFinished: %d, animatorFinished: %d", semaphoreATimedOut, semaphoreBTimedOut, transitionFinished, animatorFinished);
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
                                      loadHandler:^(ORK1VisualConsentTransitionAnimator *animator, UIPageViewControllerNavigationDirection direction) {
                                          
                                          fromViewController.imageHidden = YES;
                                          toViewController.imageHidden = YES;
                                          
                                          ORK1StrongTypeOf(self) strongSelf = weakSelf;
                                          [strongSelf doShowViewController:toViewController
                                                                 direction:direction
                                                                  animated:YES
                                                                completion:^(BOOL finished) {
                                                                    
                                                                    transitionFinished = finished;
                                                                    dispatch_semaphore_signal(semaphore);
                                                                }];
                                      }
                                completionHandler:^(ORK1VisualConsentTransitionAnimator *animator, UIPageViewControllerNavigationDirection direction) {
        
                                    animatorFinished = YES;
                                    finishAndNilAnimator(animator);
                                    dispatch_semaphore_signal(semaphore);
                                }];
        
    } else if (animateBeforeTransition && !transitionBeforeAnimate) {
        [_animator animateTransitionWithDirection:direction
                                      loadHandler:^(ORK1VisualConsentTransitionAnimator *animator, UIPageViewControllerNavigationDirection direction) {
                                          
                                          fromViewController.imageHidden = YES;
                                      }
                                completionHandler:^(ORK1VisualConsentTransitionAnimator *animator, UIPageViewControllerNavigationDirection direction) {
                                    
                                    animatorFinished = YES;
                                    finishAndNilAnimator(animator);
                                    
                                    ORK1StrongTypeOf(self) strongSelf = weakSelf;
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
                                                    completionHandler:^(ORK1VisualConsentTransitionAnimator *animator, UIPageViewControllerNavigationDirection direction) {
                                                        
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
        CGPoint defaultFrameOrigin = [ORK1DynamicCast(_animationView, ORK1AnimationPlaceholderView) defaultFrameOrigin];
        animationViewFrame.origin = (CGPoint){defaultFrameOrigin.x - scrollViewBoundsOrigin.x, defaultFrameOrigin.y - scrollViewBoundsOrigin.y};
        _animationView.frame = animationViewFrame;
    }
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
    // Stop old hairline scroll view observer and start new one
    _scrollViewObserver = [[ORK1ScrollViewObserver alloc] initWithTargetView:viewController.scrollView delegate:self];
    [self.taskViewController setRegisteredScrollView:viewController.scrollView];

    ORK1ConsentSceneViewController *fromViewController = nil;
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

    ORK1AdjustPageViewControllerNavigationDirectionForRTL(&direction);
    
    if (!animated) {
        // No animation at all
        viewController.imageHidden = NO;
        [self doShowViewController:viewController direction:direction animated:animated completion:completion];
    } else {
        NSUInteger toIndex = [self indexOfViewController:viewController];
        
        NSURL *url = nil;
        BOOL animateBeforeTransition = NO;
        BOOL transitionBeforeAnimate = NO;
        
        ORK1ConsentSectionType currentSection = [(ORK1ConsentSection *)_visualSections[currentIndex] type];
        ORK1ConsentSectionType destinationSection = (toIndex != NSNotFound) ? [(ORK1ConsentSection *)_visualSections[toIndex] type] : ORK1ConsentSectionTypeCustom;
        
        // Only use video animation when going forward
        if (toIndex > currentIndex) {
            
            // Use the custom animation URL, if there is one for the destination index.
            if (toIndex != NSNotFound && toIndex < _visualSections.count) {
                url = [ORK1DynamicCast(_visualSections[toIndex], ORK1ConsentSection) customAnimationURL];
            }
            BOOL isCustomURL = (url != nil);
            
            // If there's no custom URL, use an animation only if transitioning in the expected order.
            // Exception for datagathering, which does an arrival animation AFTER.
            if (!isCustomURL) {
                if (destinationSection == ORK1ConsentSectionTypeDataGathering) {
                    transitionBeforeAnimate = YES;
                    url = ORK1MovieURLForConsentSectionType(ORK1ConsentSectionTypeOverview);
                } else if ((destinationSection - currentSection) == 1) {
                    url = ORK1MovieURLForConsentSectionType(currentSection);
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
