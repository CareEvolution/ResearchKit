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


#import "RK1PageStepViewController.h"
#import <ResearchKit/ResearchKit_Private.h>
#import "RK1StepViewController_Internal.h"
#import "UIBarButtonItem+RK1BarButtonItem.h"
#import "RK1Helpers_Internal.h"
#import "RK1TaskViewController_Internal.h"
#import "RK1Result_Private.h"
#import "RK1Step_Private.h"

typedef NS_ENUM(NSInteger, RK1PageNavigationDirection) {
    RK1PageNavigationDirectionNone = 0,
    RK1PageNavigationDirectionForward = 1,
    RK1PageNavigationDirectionReverse = -1
} RK1_ENUM_AVAILABLE;

@interface RK1PageStepViewController () <UIPageViewControllerDelegate, RK1StepViewControllerDelegate>

@property (nonatomic, readonly) RK1PageResult *initialResult;
@property (nonatomic, readonly) RK1PageResult *pageResult;
@property (nonatomic, readonly) UIPageViewController *pageViewController;
@property (nonatomic, copy, readonly, nullable) NSString *currentStepIdentifier;
@property (nonatomic, readonly) RK1StepViewController *currentStepViewController;

@end


@implementation RK1PageStepViewController

- (instancetype)initWithStep:(RK1Step *)step result:(RK1Result *)result {
    self = [super initWithStep:step result:result];
    if (self && [step isKindOfClass:[RK1PageStep class]] && [result isKindOfClass:[RK1StepResult class]]) {
        _pageResult = [[RK1PageResult alloc] initWithPageStep:(RK1PageStep *)step stepResult:(RK1StepResult *)result];
        _initialResult = [_pageResult copy];
    }
    return self;
}

- (RK1PageStep *)pageStep {
    if ([self.step isKindOfClass:[RK1PageStep class]]) {
        return (RK1PageStep *)self.step;
    }
    return nil;
}

- (RK1StepViewController *)currentStepViewController {
    UIViewController *viewController = [self.pageViewController.viewControllers firstObject];
    if ([viewController isKindOfClass:[RK1StepViewController class]]) {
        return (RK1StepViewController *)viewController;
    }
    return nil;
}

@synthesize pageResult = _pageResult;
- (RK1PageResult *)pageResult {
    if (_pageResult == nil) {
        _pageResult = [[RK1PageResult alloc] initWithIdentifier:self.step.identifier];
    }
    if (!RK1EqualObjects(_pageResult.outputDirectory, self.outputDirectory)) {
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
    [self navigateInDirection:RK1PageNavigationDirectionNone animated:NO];
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
    
    [self navigateInDirection:RK1PageNavigationDirectionNone animated:NO];
}

- (void)updateNavLeftBarButtonItem {
    if ((self.currentStepIdentifier == nil) || ([self stepInDirection:RK1PageNavigationDirectionReverse] == nil)) {
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
    button.accessibilityLabel = RK1LocalizedString(@"AX_BUTTON_BACK", nil);
    return button;
}

- (void)goToPreviousPage {
    [self navigateInDirection:RK1PageNavigationDirectionReverse animated:YES];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (void)willNavigateDirection:(RK1StepViewControllerNavigationDirection)direction {
    // update the current step based on the direction of navigation
    if (direction == RK1StepViewControllerNavigationDirectionForward) {
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

- (id <RK1TaskResultSource>)resultSource {
    return self.pageResult;
}

- (RK1StepResult *)result {
    RK1StepResult *result = [super result];
    NSArray *pageResults = [self.pageResult flattenResults];
    result.results = [result.results arrayByAddingObjectsFromArray:pageResults] ? : pageResults;
    return result;
}


#pragma mark RK1StepViewControllerDelegate

- (void)stepViewController:(RK1StepViewController *)stepViewController didFinishWithNavigationDirection:(RK1StepViewControllerNavigationDirection)direction {
    NSInteger delta = (direction == RK1StepViewControllerNavigationDirectionForward) ? 1 : -1;
    if (direction == RK1StepViewControllerNavigationDirectionForward) {
        // If going forward, update the page result with the final stepResult
        RK1StepResult *stepResult = stepViewController.result;
        [self.pageResult addStepResult:stepResult];
    }
    [self navigateInDirection:delta animated:YES];
}

- (void)stepViewControllerResultDidChange:(RK1StepViewController *)stepViewController {
    [self.pageResult addStepResult:stepViewController.result];
    [self notifyDelegateOnResultChange];
}

- (void)stepViewControllerDidFail:(RK1StepViewController *)stepViewController withError:(NSError *)error {
    RK1StrongTypeOf(self.delegate) delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(stepViewControllerDidFail:withError:)]) {
        [delegate stepViewControllerDidFail:self withError:error];
    }
}

- (BOOL)stepViewControllerHasNextStep:(RK1StepViewController *)stepViewController {
    return [self hasNextStep] || ([self stepInDirection:RK1PageNavigationDirectionForward] != nil);
}

- (BOOL)stepViewControllerHasPreviousStep:(RK1StepViewController *)stepViewController {
    return [self hasPreviousStep] || ([self stepInDirection:RK1PageNavigationDirectionReverse] != nil);
}

- (void)stepViewController:(RK1StepViewController *)stepViewController recorder:(RK1Recorder *)recorder didFailWithError:(NSError *)error {
    RK1StrongTypeOf(self.delegate) delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(stepViewController:recorder:didFailWithError:)]) {
        [delegate stepViewController:self recorder:recorder didFailWithError:error];
    }
}

#pragma mark Navigation

- (RK1Step *)stepInDirection:(RK1PageNavigationDirection)delta {
    if ((delta == RK1PageNavigationDirectionNone) && (self.currentStepIdentifier != nil)) {
        return [self.pageStep stepWithIdentifier:self.currentStepIdentifier];
    } else if ((delta >= 0) || (self.currentStepIdentifier == nil)) {
        return [self.pageStep stepAfterStepWithIdentifier:self.currentStepIdentifier withResult:self.pageResult];
    } else {
        [self.pageResult removeStepResultWithIdentifier:self.currentStepIdentifier];
        return [self.pageStep stepBeforeStepWithIdentifier:self.currentStepIdentifier withResult:self.pageResult];
    }
}

- (void)navigateInDirection:(RK1PageNavigationDirection)delta animated:(BOOL)animated {
    RK1Step *step = [self stepInDirection:delta];
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

- (RK1StepViewController *)stepViewControllerForStep:(RK1Step *)step {
    RK1StepResult *stepResult = [self.pageResult stepResultForStepIdentifier:step.identifier];
    if (stepResult == nil) {
        // If the pageResult does not carry a step result, then check the initial result
        stepResult = [self.initialResult stepResultForStepIdentifier:step.identifier];
    }
    RK1StepViewController *viewController = [step instantiateStepViewControllerWithResult:stepResult];
    return viewController;
}

- (void)goToStep:(RK1Step *)step direction:(UIPageViewControllerNavigationDirection)direction animated:(BOOL)animated {
    RK1StepViewController *stepViewController = [self stepViewControllerForStep:step];
    
    if (!stepViewController) {
        RK1_Log_Debug(@"No view controller!");
        [self goForward];
        return;
    }
    
    // Flush the page result
    [self.pageResult removeStepResultsAfterStepWithIdentifier: step.identifier];
    
    // Setup view controller
    stepViewController.delegate = self;
    stepViewController.outputDirectory = self.outputDirectory;
    
    // Setup page direction
    RK1AdjustPageViewControllerNavigationDirectionForRTL(&direction);
    
    _currentStepIdentifier = step.identifier;
    __weak typeof(self) weakSelf = self;
    
    // unregister ScrollView to clear hairline
    [self.taskViewController setRegisteredScrollView:nil];
    
    [self.pageViewController setViewControllers:@[stepViewController] direction:direction animated:animated completion:^(BOOL finished) {
        if (finished) {
            RK1StrongTypeOf(weakSelf) strongSelf = weakSelf;
            [strongSelf updateNavLeftBarButtonItem];
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, strongSelf.navigationItem.leftBarButtonItem);
        }
    }];
}

#pragma mark - UIStateRestoring

static NSString *const _RK1CurrentStepIdentifierRestoreKey = @"currentStepIdentifier";
static NSString *const _RK1PageResultRestoreKey = @"pageResult";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    [coder encodeObject:_currentStepIdentifier forKey:_RK1CurrentStepIdentifierRestoreKey];
    [coder encodeObject:_pageResult forKey:_RK1PageResultRestoreKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    _currentStepIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:_RK1CurrentStepIdentifierRestoreKey];
    _pageResult = [coder decodeObjectOfClass:[RK1PageResult class] forKey:_RK1PageResultRestoreKey];
}

@end
