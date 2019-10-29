/*
 Copyright (c) 2016, Sage Bionetworks
 
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


#import "ORKPageStepViewController.h"
#import <ResearchKitLegacy/ResearchKit_Private.h>
#import "ORKStepViewController_Internal.h"
#import "UIBarButtonItem+ORKBarButtonItem.h"
#import "ORKHelpers_Internal.h"
#import "ORKTaskViewController_Internal.h"
#import "ORKResult_Private.h"
#import "ORKStep_Private.h"

typedef NS_ENUM(NSInteger, ORKLegacyPageNavigationDirection) {
    ORKLegacyPageNavigationDirectionNone = 0,
    ORKLegacyPageNavigationDirectionForward = 1,
    ORKLegacyPageNavigationDirectionReverse = -1
} ORKLegacy_ENUM_AVAILABLE;

@interface ORKLegacyPageStepViewController () <UIPageViewControllerDelegate, ORKLegacyStepViewControllerDelegate>

@property (nonatomic, readonly) ORKLegacyPageResult *initialResult;
@property (nonatomic, readonly) ORKLegacyPageResult *pageResult;
@property (nonatomic, readonly) UIPageViewController *pageViewController;
@property (nonatomic, copy, readonly, nullable) NSString *currentStepIdentifier;
@property (nonatomic, readonly) ORKLegacyStepViewController *currentStepViewController;

@end


@implementation ORKLegacyPageStepViewController

- (instancetype)initWithStep:(ORKLegacyStep *)step result:(ORKLegacyResult *)result {
    self = [super initWithStep:step result:result];
    if (self && [step isKindOfClass:[ORKLegacyPageStep class]] && [result isKindOfClass:[ORKLegacyStepResult class]]) {
        _pageResult = [[ORKLegacyPageResult alloc] initWithPageStep:(ORKLegacyPageStep *)step stepResult:(ORKLegacyStepResult *)result];
        _initialResult = [_pageResult copy];
    }
    return self;
}

- (ORKLegacyPageStep *)pageStep {
    if ([self.step isKindOfClass:[ORKLegacyPageStep class]]) {
        return (ORKLegacyPageStep *)self.step;
    }
    return nil;
}

- (ORKLegacyStepViewController *)currentStepViewController {
    UIViewController *viewController = [self.pageViewController.viewControllers firstObject];
    if ([viewController isKindOfClass:[ORKLegacyStepViewController class]]) {
        return (ORKLegacyStepViewController *)viewController;
    }
    return nil;
}

@synthesize pageResult = _pageResult;
- (ORKLegacyPageResult *)pageResult {
    if (_pageResult == nil) {
        _pageResult = [[ORKLegacyPageResult alloc] initWithIdentifier:self.step.identifier];
    }
    if (!ORKLegacyEqualObjects(_pageResult.outputDirectory, self.outputDirectory)) {
        _pageResult = [_pageResult copyWithOutputDirectory:self.outputDirectory];
    }
    return _pageResult;
}

- (void)stepDidChange {
    if (![self isViewLoaded]) {
        return;
    }
    
    _currentStepIdentifier = nil;
    _pageResult = nil;
    [self navigateInDirection:ORKLegacyPageNavigationDirectionNone animated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Prepare pageViewController
    _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                          navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                        options:nil];
    _pageViewController.delegate = self;
    
    if ([_pageViewController respondsToSelector:@selector(edgesForExtendedLayout)]) {
        _pageViewController.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    _pageViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _pageViewController.view.frame = self.view.bounds;
    [self.view addSubview:_pageViewController.view];
    [self addChildViewController:_pageViewController];
    [_pageViewController didMoveToParentViewController:self];
    
    [self navigateInDirection:ORKLegacyPageNavigationDirectionNone animated:NO];
}

- (void)updateNavLeftBarButtonItem {
    if ((self.currentStepIdentifier == nil) || ([self stepInDirection:ORKLegacyPageNavigationDirectionReverse] == nil)) {
        [super updateNavLeftBarButtonItem];
    } else {
        self.navigationItem.leftBarButtonItem = [self goToPreviousPageButtonItem];
    }
}

- (UIBarButtonItem *)goToPreviousPageButtonItem {
    // Hide the back navigation item if not allowed
    if (!self.currentStepViewController.step.allowsBackNavigation) {
        return nil;
    }
    UIBarButtonItem *button = [UIBarButtonItem ork_backBarButtonItemWithTarget:self action:@selector(goToPreviousPage)];
    button.accessibilityLabel = ORKLegacyLocalizedString(@"AX_BUTTON_BACK", nil);
    return button;
}

- (void)goToPreviousPage {
    [self navigateInDirection:ORKLegacyPageNavigationDirectionReverse animated:YES];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (void)willNavigateDirection:(ORKLegacyStepViewControllerNavigationDirection)direction {
    // update the current step based on the direction of navigation
    if (direction == ORKLegacyStepViewControllerNavigationDirectionForward) {
        _currentStepIdentifier = nil;
    }
    else {
        NSString *lastStepIdentifier = [[self.pageResult.results lastObject] identifier];
        if ([self.pageStep stepWithIdentifier:lastStepIdentifier] != nil) {
            _currentStepIdentifier = lastStepIdentifier;
        }
    }
    [super willNavigateDirection:direction];
}

#pragma mark - result handling

- (id <ORKLegacyTaskResultSource>)resultSource {
    return self.pageResult;
}

- (ORKLegacyStepResult *)result {
    ORKLegacyStepResult *result = [super result];
    NSArray *pageResults = [self.pageResult flattenResults];
    result.results = [result.results arrayByAddingObjectsFromArray:pageResults] ? : pageResults;
    return result;
}


#pragma mark ORKLegacyStepViewControllerDelegate

- (void)stepViewController:(ORKLegacyStepViewController *)stepViewController didFinishWithNavigationDirection:(ORKLegacyStepViewControllerNavigationDirection)direction {
    NSInteger delta = (direction == ORKLegacyStepViewControllerNavigationDirectionForward) ? 1 : -1;
    if (direction == ORKLegacyStepViewControllerNavigationDirectionForward) {
        // If going forward, update the page result with the final stepResult
        ORKLegacyStepResult *stepResult = stepViewController.result;
        [self.pageResult addStepResult:stepResult];
    }
    [self navigateInDirection:delta animated:YES];
}

- (void)stepViewControllerResultDidChange:(ORKLegacyStepViewController *)stepViewController {
    [self.pageResult addStepResult:stepViewController.result];
    [self notifyDelegateOnResultChange];
}

- (void)stepViewControllerDidFail:(ORKLegacyStepViewController *)stepViewController withError:(NSError *)error {
    ORKLegacyStrongTypeOf(self.delegate) delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(stepViewControllerDidFail:withError:)]) {
        [delegate stepViewControllerDidFail:self withError:error];
    }
}

- (BOOL)stepViewControllerHasNextStep:(ORKLegacyStepViewController *)stepViewController {
    return [self hasNextStep] || ([self stepInDirection:ORKLegacyPageNavigationDirectionForward] != nil);
}

- (BOOL)stepViewControllerHasPreviousStep:(ORKLegacyStepViewController *)stepViewController {
    return [self hasPreviousStep] || ([self stepInDirection:ORKLegacyPageNavigationDirectionReverse] != nil);
}

- (void)stepViewController:(ORKLegacyStepViewController *)stepViewController recorder:(ORKLegacyRecorder *)recorder didFailWithError:(NSError *)error {
    ORKLegacyStrongTypeOf(self.delegate) delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(stepViewController:recorder:didFailWithError:)]) {
        [delegate stepViewController:self recorder:recorder didFailWithError:error];
    }
}

#pragma mark Navigation

- (ORKLegacyStep *)stepInDirection:(ORKLegacyPageNavigationDirection)delta {
    if ((delta == ORKLegacyPageNavigationDirectionNone) && (self.currentStepIdentifier != nil)) {
        return [self.pageStep stepWithIdentifier:self.currentStepIdentifier];
    } else if ((delta >= 0) || (self.currentStepIdentifier == nil)) {
        return [self.pageStep stepAfterStepWithIdentifier:self.currentStepIdentifier withResult:self.pageResult];
    } else {
        [self.pageResult removeStepResultWithIdentifier:self.currentStepIdentifier];
        return [self.pageStep stepBeforeStepWithIdentifier:self.currentStepIdentifier withResult:self.pageResult];
    }
}

- (void)navigateInDirection:(ORKLegacyPageNavigationDirection)delta animated:(BOOL)animated {
    ORKLegacyStep *step = [self stepInDirection:delta];
    if (step == nil) {
        if (delta < 0) {
            [self goBackward];
        }
        else {
            [self goForward];
        }
    } else {
        UIPageViewControllerNavigationDirection direction = (!animated || delta >= 0) ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
        [self goToStep:step direction:direction animated:animated];
    }
}

- (ORKLegacyStepViewController *)stepViewControllerForStep:(ORKLegacyStep *)step {
    ORKLegacyStepResult *stepResult = [self.pageResult stepResultForStepIdentifier:step.identifier];
    if (stepResult == nil) {
        // If the pageResult does not carry a step result, then check the initial result
        stepResult = [self.initialResult stepResultForStepIdentifier:step.identifier];
    }
    ORKLegacyStepViewController *viewController = [step instantiateStepViewControllerWithResult:stepResult];
    return viewController;
}

- (void)goToStep:(ORKLegacyStep *)step direction:(UIPageViewControllerNavigationDirection)direction animated:(BOOL)animated {
    ORKLegacyStepViewController *stepViewController = [self stepViewControllerForStep:step];
    
    if (!stepViewController) {
        ORKLegacy_Log_Debug(@"No view controller!");
        [self goForward];
        return;
    }
    
    // Flush the page result
    [self.pageResult removeStepResultsAfterStepWithIdentifier: step.identifier];
    
    // Setup view controller
    stepViewController.delegate = self;
    stepViewController.outputDirectory = self.outputDirectory;
    
    // Setup page direction
    ORKLegacyAdjustPageViewControllerNavigationDirectionForRTL(&direction);
    
    _currentStepIdentifier = step.identifier;
    __weak typeof(self) weakSelf = self;
    
    // unregister ScrollView to clear hairline
    [self.taskViewController setRegisteredScrollView:nil];
    
    [self.pageViewController setViewControllers:@[stepViewController] direction:direction animated:animated completion:^(BOOL finished) {
        if (finished) {
            ORKLegacyStrongTypeOf(weakSelf) strongSelf = weakSelf;
            [strongSelf updateNavLeftBarButtonItem];
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, strongSelf.navigationItem.leftBarButtonItem);
        }
    }];
}

#pragma mark - UIStateRestoring

static NSString *const _ORKLegacyCurrentStepIdentifierRestoreKey = @"currentStepIdentifier";
static NSString *const _ORKLegacyPageResultRestoreKey = @"pageResult";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    [coder encodeObject:_currentStepIdentifier forKey:_ORKLegacyCurrentStepIdentifierRestoreKey];
    [coder encodeObject:_pageResult forKey:_ORKLegacyPageResultRestoreKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    _currentStepIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:_ORKLegacyCurrentStepIdentifierRestoreKey];
    _pageResult = [coder decodeObjectOfClass:[ORKLegacyPageResult class] forKey:_ORKLegacyPageResultRestoreKey];
}

@end
