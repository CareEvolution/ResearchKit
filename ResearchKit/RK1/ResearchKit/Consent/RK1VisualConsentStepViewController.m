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


#import "RK1VisualConsentStepViewController.h"

#import "RK1ContinueButton.h"
#import "RK1EAGLMoviePlayerView.h"
#import "RK1SignatureView.h"
#import "RK1TintedImageView_Internal.h"

#import "RK1ConsentSceneViewController_Internal.h"
#import "RK1VisualConsentTransitionAnimator.h"

#import "RK1ConsentDocument.h"
#import "RK1ConsentSection_Private.h"
#import "RK1Result.h"
#import "RK1StepViewController_Internal.h"
#import "RK1TaskViewController_Internal.h"
#import "RK1VisualConsentStep.h"

#import "RK1Accessibility.h"
#import "RK1Helpers_Internal.h"
#import "RK1Observer.h"
#import "RK1Skin.h"
#import "UIBarButtonItem+RK1BarButtonItem.h"

#import <MessageUI/MessageUI.h>
#import <QuartzCore/QuartzCore.h>


@interface RK1VisualConsentStepViewController () <UIPageViewControllerDelegate, RK1ScrollViewObserverDelegate> {
    BOOL _hasAppeared;
    RK1StepViewControllerNavigationDirection _navigationDirection;
    
    RK1VisualConsentTransitionAnimator *_animator;
    
    NSArray *_visualSections;
    
    RK1ScrollViewObserver *_scrollViewObserver;
}

@property (nonatomic, strong) UIPageViewController *pageViewController;

@property (nonatomic, strong) NSMutableDictionary *viewControllers;

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic) NSUInteger currentPage;

@property (nonatomic, strong) RK1ContinueButton *continueActionButton;

- (RK1ConsentSceneViewController *)viewControllerForIndex:(NSUInteger)index;
- (NSUInteger)currentIndex;
- (NSUInteger)indexOfViewController:(UIViewController *)viewController;

@end


@interface RK1AnimationPlaceholderView : UIView

@property (nonatomic, strong) RK1EAGLMoviePlayerView *playerView;

- (void)scrollToTopAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion;

@end


@implementation RK1AnimationPlaceholderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _playerView = [RK1EAGLMoviePlayerView new];
        _playerView.hidden = YES;
        [self addSubview:_playerView];
    }
    return self;
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    
    CGRect frame = self.frame;
    frame.size.height = RK1GetMetricForWindow(RK1ScreenMetricIllustrationHeight, newWindow);
    self.frame = frame;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _playerView.frame = self.bounds;
}

- (CGPoint)defaultFrameOrigin {
    return (CGPoint){0, RK1GetMetricForWindow(RK1ScreenMetricTopToIllustration, self.superview.window)};
}

- (void)scrollToTopAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
    CGRect targetFrame = self.frame;
    targetFrame.origin = [self defaultFrameOrigin];
    if (animated) {
        [UIView animateWithDuration:RK1ScrollToTopAnimationDuration
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


@implementation RK1VisualConsentStepViewController

- (void)dealloc {
    [[RK1TintedImageCache sharedCache] removeAllObjects];
}

- (void)stepDidChange {
    [super stepDidChange];
    {
        NSMutableArray *visualSections = [NSMutableArray new];
        
        NSArray *sections = self.visualConsentStep.consentDocument.sections;
        for (RK1ConsentSection *scene in sections) {
            if (scene.type != RK1ConsentSectionTypeOnlyInDocument) {
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

- (RK1EAGLMoviePlayerView *)animationPlayerView {
    return [(RK1AnimationPlaceholderView *)_animationView playerView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect viewBounds = self.view.bounds;
    
    self.view.backgroundColor = RK1Color(RK1BackgroundColorKey);
   
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
    
    self.animationView = [[RK1AnimationPlaceholderView alloc] initWithFrame:
                          (CGRect){{0, 0}, {viewBounds.size.width, RK1GetMetricForWindow(RK1ScreenMetricIllustrationHeight, self.view.window)}}];
    _animationView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
    _animationView.backgroundColor = [UIColor clearColor];
    _animationView.userInteractionEnabled = NO;
    [self.view addSubview:_animationView];
    
    [self updatePageIndex];
}

- (RK1VisualConsentStep *)visualConsentStep {
    assert(!self.step || [self.step isKindOfClass:[RK1VisualConsentStep class]]);
    return (RK1VisualConsentStep *)self.step;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_pageViewController.viewControllers.count == 0) {

        _hasAppeared = YES;
        
        // Add first viewController
        NSUInteger idx = 0;
        if (_navigationDirection == RK1StepViewControllerNavigationDirectionReverse) {
            idx = [self pageCount]-1;
        }
        
        [self showViewController:[self viewControllerForIndex:idx] forward:YES animated:NO];
    }
    [self updatePageIndex];
}

- (void)willNavigateDirection:(RK1StepViewControllerNavigationDirection)direction {
    _navigationDirection = direction;
}

- (UIBarButtonItem *)goToPreviousPageButton {
    UIBarButtonItem *button = [UIBarButtonItem ork_backBarButtonItemWithTarget:self action:@selector(goToPreviousPage)];
    button.accessibilityLabel = RK1LocalizedString(@"AX_BUTTON_BACK", nil);
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
    RK1ConsentSceneViewController *currentConsentSceneViewController = [self viewControllerForIndex:[self currentIndex]];
    [(RK1AnimationPlaceholderView *)_animationView scrollToTopAnimated:YES completion:nil];
    [currentConsentSceneViewController scrollToTopAnimated:YES completion:^(BOOL finished) {
        if (finished) {
            [self showNextViewController];
        }
    }];
}

- (void)showNextViewController {
    CGRect animationViewFrame = _animationView.frame;
    animationViewFrame.origin = [RK1DynamicCast(_animationView, RK1AnimationPlaceholderView) defaultFrameOrigin];
    _animationView.frame = animationViewFrame;
    RK1ConsentSceneViewController *nextConsentSceneViewController = [self viewControllerForIndex:[self currentIndex] + 1];
    [(RK1AnimationPlaceholderView *)_animationView scrollToTopAnimated:NO completion:nil];
    [nextConsentSceneViewController scrollToTopAnimated:NO completion:^(BOOL finished) {
        // 'finished' is always YES when not animated
        [self showViewController:nextConsentSceneViewController forward:YES animated:YES];
        RK1AccessibilityPostNotificationAfterDelay(UIAccessibilityScreenChangedNotification, nil, 0.5);
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

    RK1ConsentSection *currentSection = (RK1ConsentSection *)_visualSections[currentIndex];
    if (currentSection.type == RK1ConsentSectionTypeOverview) {
        _animationView.isAccessibilityElement = NO;
    } else {
        _animationView.isAccessibilityElement = YES;
        _animationView.accessibilityLabel = [NSString stringWithFormat:RK1LocalizedString(@"AX_IMAGE_ILLUSTRATION", nil), currentSection.title];
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

- (void)doShowViewController:(RK1ConsentSceneViewController *)viewController
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
    
    RK1WeakTypeOf(self) weakSelf = self;
    [self.pageViewController setViewControllers:@[viewController] direction:direction animated:animated completion:^(BOOL finished) {
        RK1StrongTypeOf(self) strongSelf = weakSelf;
        pageViewControllerView.userInteractionEnabled = YES;
        [strongSelf updatePageIndex];

        if (completion != NULL) {
            completion(finished);
        }
    }];
}

- (void)doAnimateFromViewController:(RK1ConsentSceneViewController *)fromViewController
                       toController:(RK1ConsentSceneViewController *)toViewController
                          direction:(UIPageViewControllerNavigationDirection)direction
                                url:(NSURL *)url
            animateBeforeTransition:(BOOL)animateBeforeTransition
            transitionBeforeAnimate:(BOOL)transitionBeforeAnimate
                         completion:(void (^)(BOOL finished))completion {

    NSAssert(url, @"url cannot be nil");
    NSAssert(!(animateBeforeTransition && transitionBeforeAnimate), @"Both flags cannot be set");

    RK1WeakTypeOf(self) weakSelf = self;
    void (^finishAndNilAnimator)(RK1VisualConsentTransitionAnimator *animator) = ^(RK1VisualConsentTransitionAnimator *animator) {
        RK1StrongTypeOf(self) strongSelf = weakSelf;
        [animator finish];
        if (strongSelf && strongSelf->_animator == animator) {
            // Do not show images and hide animationPlayerView if it's not the current animator
            fromViewController.imageHidden = NO;
            toViewController.imageHidden = NO;
            [strongSelf animationPlayerView].hidden = YES;
            strongSelf->_animator = nil;
        }
    };

    RK1VisualConsentTransitionAnimator *animator = [[RK1VisualConsentTransitionAnimator alloc] initWithVisualConsentStepViewController:self movieURL:url];
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
            RK1_Log_Debug(@"[Semaphore timed out] semaphoreATimedOut: %d, semaphoreBTimedOut: %d, transitionFinished: %d, animatorFinished: %d", semaphoreATimedOut, semaphoreBTimedOut, transitionFinished, animatorFinished);
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
                                      loadHandler:^(RK1VisualConsentTransitionAnimator *animator, UIPageViewControllerNavigationDirection direction) {
                                          
                                          fromViewController.imageHidden = YES;
                                          toViewController.imageHidden = YES;
                                          
                                          RK1StrongTypeOf(self) strongSelf = weakSelf;
                                          [strongSelf doShowViewController:toViewController
                                                                 direction:direction
                                                                  animated:YES
                                                                completion:^(BOOL finished) {
                                                                    
                                                                    transitionFinished = finished;
                                                                    dispatch_semaphore_signal(semaphore);
                                                                }];
                                      }
                                completionHandler:^(RK1VisualConsentTransitionAnimator *animator, UIPageViewControllerNavigationDirection direction) {
        
                                    animatorFinished = YES;
                                    finishAndNilAnimator(animator);
                                    dispatch_semaphore_signal(semaphore);
                                }];
        
    } else if (animateBeforeTransition && !transitionBeforeAnimate) {
        [_animator animateTransitionWithDirection:direction
                                      loadHandler:^(RK1VisualConsentTransitionAnimator *animator, UIPageViewControllerNavigationDirection direction) {
                                          
                                          fromViewController.imageHidden = YES;
                                      }
                                completionHandler:^(RK1VisualConsentTransitionAnimator *animator, UIPageViewControllerNavigationDirection direction) {
                                    
                                    animatorFinished = YES;
                                    finishAndNilAnimator(animator);
                                    
                                    RK1StrongTypeOf(self) strongSelf = weakSelf;
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
                                                    completionHandler:^(RK1VisualConsentTransitionAnimator *animator, UIPageViewControllerNavigationDirection direction) {
                                                        
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
        CGPoint defaultFrameOrigin = [RK1DynamicCast(_animationView, RK1AnimationPlaceholderView) defaultFrameOrigin];
        animationViewFrame.origin = (CGPoint){defaultFrameOrigin.x - scrollViewBoundsOrigin.x, defaultFrameOrigin.y - scrollViewBoundsOrigin.y};
        _animationView.frame = animationViewFrame;
    }
}

- (RK1ConsentSection *)consentSectionForIndex:(NSUInteger)index {
    RK1ConsentSection *consentSection = nil;
    NSArray *visualSections = [self visualSections];
    if (index < visualSections.count) {
        consentSection = visualSections[index];
    }
    return consentSection;
}

- (void)showViewController:(RK1ConsentSceneViewController *)viewController forward:(BOOL)forward animated:(BOOL)animated {
    [self showViewController:viewController forward:forward animated:animated preloadNextConsentSectionImage:YES];
}

- (void)showViewController:(RK1ConsentSceneViewController *)viewController forward:(BOOL)forward animated:(BOOL)animated preloadNextConsentSectionImage:(BOOL)preloadNextViewController {
    [self showViewController:viewController
                     forward:forward
                    animated:animated
                  completion:^(BOOL finished) {
                      if (preloadNextViewController) {
                          RK1ConsentSection *nextConsentSection = [self consentSectionForIndex:[self currentIndex] + 1];
                          RK1TintedImageView *currentSceneImageView = viewController.sceneView.imageView;
                          [[RK1TintedImageCache sharedCache] cacheImage:nextConsentSection.image
                                                              tintColor:currentSceneImageView.tintColor
                                                                  scale:currentSceneImageView.window.screen.scale];
                      }
                  }];
}

- (void)showViewController:(RK1ConsentSceneViewController *)viewController
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
    _scrollViewObserver = [[RK1ScrollViewObserver alloc] initWithTargetView:viewController.scrollView delegate:self];
    [self.taskViewController setRegisteredScrollView:viewController.scrollView];

    RK1ConsentSceneViewController *fromViewController = nil;
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

    RK1AdjustPageViewControllerNavigationDirectionForRTL(&direction);
    
    if (!animated) {
        // No animation at all
        viewController.imageHidden = NO;
        [self doShowViewController:viewController direction:direction animated:animated completion:completion];
    } else {
        NSUInteger toIndex = [self indexOfViewController:viewController];
        
        NSURL *url = nil;
        BOOL animateBeforeTransition = NO;
        BOOL transitionBeforeAnimate = NO;
        
        RK1ConsentSectionType currentSection = [(RK1ConsentSection *)_visualSections[currentIndex] type];
        RK1ConsentSectionType destinationSection = (toIndex != NSNotFound) ? [(RK1ConsentSection *)_visualSections[toIndex] type] : RK1ConsentSectionTypeCustom;
        
        // Only use video animation when going forward
        if (toIndex > currentIndex) {
            
            // Use the custom animation URL, if there is one for the destination index.
            if (toIndex != NSNotFound && toIndex < _visualSections.count) {
                url = [RK1DynamicCast(_visualSections[toIndex], RK1ConsentSection) customAnimationURL];
            }
            BOOL isCustomURL = (url != nil);
            
            // If there's no custom URL, use an animation only if transitioning in the expected order.
            // Exception for datagathering, which does an arrival animation AFTER.
            if (!isCustomURL) {
                if (destinationSection == RK1ConsentSectionTypeDataGathering) {
                    transitionBeforeAnimate = YES;
                    url = RK1MovieURLForConsentSectionType(RK1ConsentSectionTypeOverview);
                } else if ((destinationSection - currentSection) == 1) {
                    url = RK1MovieURLForConsentSectionType(currentSection);
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

- (RK1ConsentSceneViewController *)viewControllerForIndex:(NSUInteger)index {
    if (_viewControllers == nil) {
        _viewControllers = [NSMutableDictionary new];
    }
    
    RK1ConsentSceneViewController *consentViewController = nil;
    
    if (_viewControllers[@(index)]) {
        consentViewController = _viewControllers[@(index)];
    } else if (index >= [self pageCount]) {
        consentViewController = nil;
    } else {
        RK1ConsentSceneViewController *sceneViewController = [[RK1ConsentSceneViewController alloc] initWithSection:[self visualSections][index]];
        consentViewController = sceneViewController;
        
        if (index == [self pageCount]-1) {
            sceneViewController.continueButtonItem = self.continueButtonItem;
        } else {
            NSString *buttonTitle = RK1LocalizedString(@"BUTTON_NEXT", nil);
            if (sceneViewController.section.type == RK1ConsentSectionTypeOverview) {
                buttonTitle = RK1LocalizedString(@"BUTTON_GET_STARTED", nil);
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

static NSString *const _RK1CurrentPageRestoreKey = @"currentPage";
static NSString *const _RK1HasAppearedRestoreKey = @"hasAppeared";
static NSString *const _RK1InitialBackButtonRestoreKey = @"initialBackButton";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeInteger:_currentPage forKey:_RK1CurrentPageRestoreKey];
    [coder encodeBool:_hasAppeared forKey:_RK1HasAppearedRestoreKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    self.currentPage = [coder decodeIntegerForKey:_RK1CurrentPageRestoreKey];
    _hasAppeared = [coder decodeBoolForKey:_RK1HasAppearedRestoreKey];
    
    _viewControllers = nil;
    [self showViewController:[self viewControllerForIndex:_currentPage] forward:YES animated:NO];
}

@end
