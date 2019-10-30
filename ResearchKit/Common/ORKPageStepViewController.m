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

typedef NS_ENUM(NSInteger, ORK1PageNavigationDirection) {
    ORK1PageNavigationDirectionNone = 0,
    ORK1PageNavigationDirectionForward = 1,
    ORK1PageNavigationDirectionReverse = -1
} ORK1_ENUM_AVAILABLE;

@interface ORK1PageStepViewController () <UIPageViewControllerDelegate, ORK1StepViewControllerDelegate>

@property (nonatomic, readonly) ORK1PageResult *initialResult;
@property (nonatomic, readonly) ORK1PageResult *pageResult;
@property (nonatomic, readonly) UIPageViewController *pageViewController;
@property (nonatomic, copy, readonly, nullable) NSString *currentStepIdentifier;
@property (nonatomic, readonly) ORK1StepViewController *currentStepViewController;

@end


@implementation ORK1PageStepViewController

- (instancetype)initWithStep:(ORK1Step *)step result:(ORK1Result *)result {
    self = [super initWithStep:step result:result];
    if (self && [step isKindOfClass:[ORK1PageStep class]] && [result isKindOfClass:[ORK1StepResult class]]) {
        _pageResult = [[ORK1PageResult alloc] initWithPageStep:(ORK1PageStep *)step stepResult:(ORK1StepResult *)result];
        _initialResult = [_pageResult copy];
    }
    return self;
}

- (ORK1PageStep *)pageStep {
    if ([self.step isKindOfClass:[ORK1PageStep class]]) {
        return (ORK1PageStep *)self.step;
    }
    return nil;
}

- (ORK1StepViewController *)currentStepViewController {
    UIViewController *viewController = [self.pageViewController.viewControllers firstObject];
    if ([viewController isKindOfClass:[ORK1StepViewController class]]) {
        return (ORK1StepViewController *)viewController;
    }
    return nil;
}

@synthesize pageResult = _pageResult;
- (ORK1PageResult *)pageResult {
    if (_pageResult == nil) {
        _pageResult = [[ORK1PageResult alloc] initWithIdentifier:self.step.identifier];
    }
    if (!ORK1EqualObjects(_pageResult.outputDirectory, self.outputDirectory)) {
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
    [self navigateInDirection:ORK1PageNavigationDirectionNone animated:NO];
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
    
    [self navigateInDirection:ORK1PageNavigationDirectionNone animated:NO];
}

- (void)updateNavLeftBarButtonItem {
    if ((self.currentStepIdentifier == nil) || ([self stepInDirection:ORK1PageNavigationDirectionReverse] == nil)) {
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
    button.accessibilityLabel = ORK1LocalizedString(@"AX_BUTTON_BACK", nil);
    return button;
}

- (void)goToPreviousPage {
    [self navigateInDirection:ORK1PageNavigationDirectionReverse animated:YES];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (void)willNavigateDirection:(ORK1StepViewControllerNavigationDirection)direction {
    // update the current step based on the direction of navigation
    if (direction == ORK1StepViewControllerNavigationDirectionForward) {
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

- (id <ORK1TaskResultSource>)resultSource {
    return self.pageResult;
}

- (ORK1StepResult *)result {
    ORK1StepResult *result = [super result];
    NSArray *pageResults = [self.pageResult flattenResults];
    result.results = [result.results arrayByAddingObjectsFromArray:pageResults] ? : pageResults;
    return result;
}


#pragma mark ORK1StepViewControllerDelegate

- (void)stepViewController:(ORK1StepViewController *)stepViewController didFinishWithNavigationDirection:(ORK1StepViewControllerNavigationDirection)direction {
    NSInteger delta = (direction == ORK1StepViewControllerNavigationDirectionForward) ? 1 : -1;
    if (direction == ORK1StepViewControllerNavigationDirectionForward) {
        // If going forward, update the page result with the final stepResult
        ORK1StepResult *stepResult = stepViewController.result;
        [self.pageResult addStepResult:stepResult];
    }
    [self navigateInDirection:delta animated:YES];
}

- (void)stepViewControllerResultDidChange:(ORK1StepViewController *)stepViewController {
    [self.pageResult addStepResult:stepViewController.result];
    [self notifyDelegateOnResultChange];
}

- (void)stepViewControllerDidFail:(ORK1StepViewController *)stepViewController withError:(NSError *)error {
    ORK1StrongTypeOf(self.delegate) delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(stepViewControllerDidFail:withError:)]) {
        [delegate stepViewControllerDidFail:self withError:error];
    }
}

- (BOOL)stepViewControllerHasNextStep:(ORK1StepViewController *)stepViewController {
    return [self hasNextStep] || ([self stepInDirection:ORK1PageNavigationDirectionForward] != nil);
}

- (BOOL)stepViewControllerHasPreviousStep:(ORK1StepViewController *)stepViewController {
    return [self hasPreviousStep] || ([self stepInDirection:ORK1PageNavigationDirectionReverse] != nil);
}

- (void)stepViewController:(ORK1StepViewController *)stepViewController recorder:(ORK1Recorder *)recorder didFailWithError:(NSError *)error {
    ORK1StrongTypeOf(self.delegate) delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(stepViewController:recorder:didFailWithError:)]) {
        [delegate stepViewController:self recorder:recorder didFailWithError:error];
    }
}

#pragma mark Navigation

- (ORK1Step *)stepInDirection:(ORK1PageNavigationDirection)delta {
    if ((delta == ORK1PageNavigationDirectionNone) && (self.currentStepIdentifier != nil)) {
        return [self.pageStep stepWithIdentifier:self.currentStepIdentifier];
    } else if ((delta >= 0) || (self.currentStepIdentifier == nil)) {
        return [self.pageStep stepAfterStepWithIdentifier:self.currentStepIdentifier withResult:self.pageResult];
    } else {
        [self.pageResult removeStepResultWithIdentifier:self.currentStepIdentifier];
        return [self.pageStep stepBeforeStepWithIdentifier:self.currentStepIdentifier withResult:self.pageResult];
    }
}

- (void)navigateInDirection:(ORK1PageNavigationDirection)delta animated:(BOOL)animated {
    ORK1Step *step = [self stepInDirection:delta];
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

- (ORK1StepViewController *)stepViewControllerForStep:(ORK1Step *)step {
    ORK1StepResult *stepResult = [self.pageResult stepResultForStepIdentifier:step.identifier];
    if (stepResult == nil) {
        // If the pageResult does not carry a step result, then check the initial result
        stepResult = [self.initialResult stepResultForStepIdentifier:step.identifier];
    }
    ORK1StepViewController *viewController = [step instantiateStepViewControllerWithResult:stepResult];
    return viewController;
}

- (void)goToStep:(ORK1Step *)step direction:(UIPageViewControllerNavigationDirection)direction animated:(BOOL)animated {
    ORK1StepViewController *stepViewController = [self stepViewControllerForStep:step];
    
    if (!stepViewController) {
        ORK1_Log_Debug(@"No view controller!");
        [self goForward];
        return;
    }
    
    // Flush the page result
    [self.pageResult removeStepResultsAfterStepWithIdentifier: step.identifier];
    
    // Setup view controller
    stepViewController.delegate = self;
    stepViewController.outputDirectory = self.outputDirectory;
    
    // Setup page direction
    ORK1AdjustPageViewControllerNavigationDirectionForRTL(&direction);
    
    _currentStepIdentifier = step.identifier;
    __weak typeof(self) weakSelf = self;
    
    // unregister ScrollView to clear hairline
    [self.taskViewController setRegisteredScrollView:nil];
    
    [self.pageViewController setViewControllers:@[stepViewController] direction:direction animated:animated completion:^(BOOL finished) {
        if (finished) {
            ORK1StrongTypeOf(weakSelf) strongSelf = weakSelf;
            [strongSelf updateNavLeftBarButtonItem];
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, strongSelf.navigationItem.leftBarButtonItem);
        }
    }];
}

#pragma mark - UIStateRestoring

static NSString *const _ORK1CurrentStepIdentifierRestoreKey = @"currentStepIdentifier";
static NSString *const _ORK1PageResultRestoreKey = @"pageResult";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    [coder encodeObject:_currentStepIdentifier forKey:_ORK1CurrentStepIdentifierRestoreKey];
    [coder encodeObject:_pageResult forKey:_ORK1PageResultRestoreKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    _currentStepIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:_ORK1CurrentStepIdentifierRestoreKey];
    _pageResult = [coder decodeObjectOfClass:[ORK1PageResult class] forKey:_ORK1PageResultRestoreKey];
}

@end
