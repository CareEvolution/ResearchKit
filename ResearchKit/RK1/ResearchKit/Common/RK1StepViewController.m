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


#import "RK1StepViewController.h"

#import "UIBarButtonItem+RK1BarButtonItem.h"

#import "RK1StepViewController_Internal.h"
#import "RK1TaskViewController_Internal.h"

#import "RK1Result.h"
#import "RK1ReviewStep_Internal.h"

#import "RK1Helpers_Internal.h"
#import "RK1Skin.h"

#import "CEVRKTheme.h"

@interface RK1StepViewController () {
    BOOL _hasBeenPresented;
    BOOL _dismissing;
    BOOL _presentingAlert;
}

@property (nonatomic, strong,readonly) UIBarButtonItem *flexSpace;
@property (nonatomic, strong,readonly) UIBarButtonItem *fixedSpace;

@end


@implementation RK1StepViewController

- (void)initializeInternalButtonItems {
    _internalBackButtonItem = [UIBarButtonItem ork_backBarButtonItemWithTarget:self action:@selector(goBackward)];
    _internalBackButtonItem.accessibilityLabel = RK1LocalizedString(@"AX_BUTTON_BACK", nil);
    _internalContinueButtonItem = [[UIBarButtonItem alloc] initWithTitle:RK1LocalizedString(@"BUTTON_NEXT", nil) style:UIBarButtonItemStylePlain target:self action:@selector(goForward)];
    _internalDoneButtonItem = [[UIBarButtonItem alloc] initWithTitle:RK1LocalizedString(@"BUTTON_DONE", nil) style:UIBarButtonItemStyleDone target:self action:@selector(goForward)];
    _internalSkipButtonItem = [[UIBarButtonItem alloc] initWithTitle:RK1LocalizedString(@"BUTTON_SKIP", nil) style:UIBarButtonItemStylePlain target:self action:@selector(skip:)];
    _backButtonItem = _internalBackButtonItem;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initializeInternalButtonItems];
    }
    return self;
}
#pragma clang diagnostic pop

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initializeInternalButtonItems];
    }
    return self;
}

- (instancetype)initWithStep:(RK1Step *)step {
    self = [self init];
    if (self) {
        [self initializeInternalButtonItems];
        [self setStep:step];
    }
    return self;
}

- (instancetype)initWithStep:(RK1Step *)step result:(RK1Result *)result {
    // Default implementation ignores the previous result.
    return [self initWithStep:step];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = RK1Color(RK1BackgroundColorKey);
    
}

- (void)setupButtons {
    if (self.hasPreviousStep == YES) {
        [self ork_setBackButtonItem: _internalBackButtonItem];
    } else {
        [self ork_setBackButtonItem:nil];
    }
    
    if (self.hasNextStep == YES) {
        self.continueButtonItem = _internalContinueButtonItem;
    } else {
        self.continueButtonItem = _internalDoneButtonItem;
    }
    
    self.skipButtonItem = _internalSkipButtonItem;
}

- (void)setStep:(RK1Step *)step {
    if (_hasBeenPresented) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"Cannot set step after presenting step view controller" userInfo:nil];
    }
    if (step && step.identifier == nil) {
        RK1_Log_Warning(@"Step identifier should not be nil.");
    }
    
    _step = step;
    
    [step validateParameters];
    
    [self setupButtons];
    [self stepDidChange];
}

- (void)stepDidChange {
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    RK1_Log_Debug(@"%@", self);
    
    // Required here (instead of viewDidLoad) because any custom buttons are set once the delegate responds to the stepViewControllerWillAppear,
    // otherwise there is a minor visual glitch, where the original buttons are displayed on the UI for a short period. This is not placed after
    // the delegate responds to the stepViewControllerWillAppear, so that the target from the button's item can be used, if the intention is to
    // only modify the title of the button.
    [self setupButtons];
    
    if ([self.delegate respondsToSelector:@selector(stepViewControllerWillAppear:)]) {
        [self.delegate stepViewControllerWillAppear:self];
    }
        
    if (!_step) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"Cannot present step view controller without a step" userInfo:nil];
    }
    _hasBeenPresented = YES;
    
    // Set presentedDate on first time viewWillAppear
    if (!self.presentedDate) {
        self.presentedDate = [NSDate date];
    }
    
    // clear dismissedDate
    self.dismissedDate = nil;
    
    // Certain nested UI Elements (e.g., RK1HeadlineLabel) are attached to view hierarchy late in the lifecycle. This can cause a noticable,
    // unintended animation of state change as the view animates into view. Posting this notification and handling theme application upon
    // receipt can ensure a redraw cycle of the receiving element can "see" the theme prior to being inside the responder chain so the first
    // displayed draw is the expected theme.
    NSDictionary *userInfo = @{CEVRKThemeKey : [CEVRKTheme themeForElement:self]};
    NSNotification *notification = [NSNotification notificationWithName:CEVRK1StepViewControllerViewWillAppearNotification object:nil userInfo:userInfo];
    [NSNotificationCenter.defaultCenter postNotification:notification];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    _dismissing = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    
    [super viewDidDisappear:animated];

    // Set endDate if current stepVC is dismissed
    // Because stepVC is embeded in a UIPageViewController,
    // when current stepVC is out of screen, it didn't belongs to UIPageViewController's viewControllers any more.
    // If stepVC is just covered by a modal view, dismissedDate should not be set.
    if (self.nextResponder == nil ||
        ([self.parentViewController isKindOfClass:[UIPageViewController class]]
            && NO == [[(UIPageViewController *)self.parentViewController viewControllers] containsObject:self])) {
        self.dismissedDate = [NSDate date];
    }
    _dismissing = NO;
}

- (void)willNavigateDirection:(RK1StepViewControllerNavigationDirection)direction {
}

- (void)setContinueButtonTitle:(NSString *)continueButtonTitle {
    self.internalContinueButtonItem.title = continueButtonTitle;
    self.internalDoneButtonItem.title = continueButtonTitle;
    
    self.continueButtonItem = self.internalContinueButtonItem;
}

- (NSString *)continueButtonTitle {
    return self.continueButtonItem.title;
}

- (void)setLearnMoreButtonTitle:(NSString *)learnMoreButtonTitle {
    self.learnMoreButtonItem.title = learnMoreButtonTitle;
    self.learnMoreButtonItem = self.learnMoreButtonItem;
}

- (NSString *)learnMoreButtonTitle {
    return self.learnMoreButtonItem.title;
}

- (void)setSkipButtonTitle:(NSString *)skipButtonTitle {
    self.internalSkipButtonItem.title = skipButtonTitle;
    self.skipButtonItem = self.internalSkipButtonItem;
}

- (NSString *)skipButtonTitle {
    return self.skipButtonItem.title;
}

// internal use version to set backButton, without overriding "_internalBackButtonItem"
- (void)ork_setBackButtonItem:(UIBarButtonItem *)backButton {
    backButton.accessibilityLabel = RK1LocalizedString(@"AX_BUTTON_BACK", nil);
    _backButtonItem = backButton;
    [self updateNavLeftBarButtonItem];
}

// Subclass should avoid using this method, which wound overide "_internalBackButtonItem"
- (void)setBackButtonItem:(UIBarButtonItem *)backButton {
    backButton.accessibilityLabel = RK1LocalizedString(@"AX_BUTTON_BACK", nil);
    _backButtonItem = backButton;
    _internalBackButtonItem = backButton;
    [self updateNavLeftBarButtonItem];
}

- (void)updateNavRightBarButtonItem {
    self.navigationItem.rightBarButtonItem = _cancelButtonItem;
}

- (void)updateNavLeftBarButtonItem {
    self.navigationItem.leftBarButtonItem = _backButtonItem;
}

- (void)setCancelButtonItem:(UIBarButtonItem *)cancelButton {
    _cancelButtonItem = cancelButton;
    [self updateNavRightBarButtonItem];
}

- (BOOL)hasPreviousStep {
    RK1StrongTypeOf(self.delegate) strongDelegate = self.delegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(stepViewControllerHasPreviousStep:)]) {
        return [strongDelegate stepViewControllerHasPreviousStep:self];
    }
    
    return NO;
}

- (BOOL)hasNextStep {
    RK1StrongTypeOf(self.delegate) strongDelegate = self.delegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(stepViewControllerHasNextStep:)]) {
        return [strongDelegate stepViewControllerHasNextStep:self];
    }
    
    return NO;
}

- (RK1StepResult *)result {
    
    RK1StepResult *stepResult = [[RK1StepResult alloc] initWithStepIdentifier:self.step.identifier results:_addedResults ? : @[]];
    stepResult.startDate = self.presentedDate ? : [NSDate date];
    stepResult.endDate = self.dismissedDate ? : [NSDate date];
    
    return stepResult;
}

- (void)addResult:(RK1Result *)result {
    RK1Result *copy = [result copy];
    if (_addedResults == nil) {
        _addedResults = @[copy];
    } else {
        NSUInteger idx = [_addedResults indexOfObject:copy];
        if (idx == NSNotFound) {
            _addedResults = [_addedResults arrayByAddingObject:copy];
        } else {
            NSMutableArray *results = [_addedResults mutableCopy];
            [results insertObject:copy atIndex:idx];
            _addedResults = [results copy];
        }
    }
}

- (void)notifyDelegateOnResultChange {
    
    RK1StrongTypeOf(self.delegate) strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(stepViewControllerResultDidChange:)]) {
        [strongDelegate stepViewControllerResultDidChange:self];
    }
}

- (BOOL)hasBeenPresented {
    return _hasBeenPresented;
}

+ (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    // The default values for a view controller's supported interface orientations is set to
    // UIInterfaceOrientationMaskAll for the iPad idiom and UIInterfaceOrientationMaskAllButUpsideDown for the iPhone idiom.
    UIInterfaceOrientationMask supportedOrientations = UIInterfaceOrientationMaskAllButUpsideDown;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        supportedOrientations = UIInterfaceOrientationMaskAll;
    }
    return supportedOrientations;
}

- (BOOL)isBeingReviewed {
    return _parentReviewStep != nil;
}

- (BOOL)readOnlyMode {
    return self.isBeingReviewed && _parentReviewStep.isStandalone;
}

#pragma mark - Action Handlers

- (void)goForward {
    RK1StepViewControllerNavigationDirection direction = self.isBeingReviewed ? RK1StepViewControllerNavigationDirectionReverse : RK1StepViewControllerNavigationDirectionForward;
    RK1StrongTypeOf(self.delegate) strongDelegate = self.delegate;
    [strongDelegate stepViewController:self didFinishWithNavigationDirection:direction];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (void)goBackward {
    
    RK1StrongTypeOf(self.delegate) strongDelegate = self.delegate;
    [strongDelegate stepViewController:self didFinishWithNavigationDirection:RK1StepViewControllerNavigationDirectionReverse];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (void)skip:(UIView *)sender {
    if (self.isBeingReviewed && !self.readOnlyMode) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:RK1LocalizedString(@"BUTTON_CLEAR_ANSWER", nil)
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction *action) {
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        [self skipForward];
                                                    });
                                                }]];
        [alert addAction:[UIAlertAction actionWithTitle:RK1LocalizedString(@"BUTTON_CANCEL", nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil
                          ]];
        alert.popoverPresentationController.sourceView = sender;
        alert.popoverPresentationController.sourceRect = sender.bounds;
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        [self skipForward];
    }
}

- (void)skipForward {
    [self goForward];
}


- (RK1TaskViewController *)taskViewController {
    // look to parent view controller for a task view controller
    UIViewController *parentViewController = [self parentViewController];
    while (parentViewController && ![parentViewController isKindOfClass:[RK1TaskViewController class]]) {
        parentViewController = [parentViewController parentViewController];
    }
    return (RK1TaskViewController *)parentViewController;
}

- (void)showValidityAlertWithMessage:(NSString *)text {
    [self showValidityAlertWithTitle:RK1LocalizedString(@"RANGE_ALERT_TITLE", nil) message:text];
}

- (void)showValidityAlertWithTitle:(NSString *)title message:(NSString *)message {
    if (![title length] && ![message length]) {
        // No alert if the value is empty
        return;
    }
    if (_dismissing || ![self isViewLoaded] || !self.view.window) {
        // No alert if not in view chain.
        return;
    }
    
    if (_presentingAlert) {
        return;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:RK1LocalizedString(@"BUTTON_CANCEL", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    
    _presentingAlert = YES;
    [self presentViewController:alert animated:YES completion:^{
        _presentingAlert = NO;
    }];
}


#pragma mark - UIStateRestoring

static NSString *const _RK1StepIdentifierRestoreKey = @"stepIdentifier";
static NSString *const _RK1PresentedDateRestoreKey = @"presentedDate";
static NSString *const _RK1OutputDirectoryKey = @"outputDirectory";
static NSString *const _RK1ParentReviewStepKey = @"parentReviewStep";
static NSString *const _RK1AddedResultsKey = @"addedResults";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:_step.identifier forKey:_RK1StepIdentifierRestoreKey];
    [coder encodeObject:_presentedDate forKey:_RK1PresentedDateRestoreKey];
    [coder encodeObject:RK1BookmarkDataFromURL(_outputDirectory) forKey:_RK1OutputDirectoryKey];
    [coder encodeObject:_parentReviewStep forKey:_RK1ParentReviewStepKey];
    [coder encodeObject:_addedResults forKey:_RK1AddedResultsKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    self.outputDirectory = RK1URLFromBookmarkData([coder decodeObjectOfClass:[NSData class] forKey:_RK1OutputDirectoryKey]);
    
    if (!self.step) {
        // Just logging to the console in this case, since this can happen during a taskVC restoration of a dynamic task.
        // The step VC will get restored, but then never added back to the hierarchy.
        RK1_Log_Warning(@"%@",[NSString stringWithFormat:@"No step provided while restoring %@", NSStringFromClass([self class])]);
    }
    
    self.presentedDate = [coder decodeObjectOfClass:[NSDate class] forKey:_RK1PresentedDateRestoreKey];
    self.restoredStepIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:_RK1StepIdentifierRestoreKey];
    
    if (self.step && _restoredStepIdentifier && ![self.step.identifier isEqualToString:_restoredStepIdentifier]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"Attempted to restore step with identifier %@ but got step identifier %@", _restoredStepIdentifier, self.step.identifier]
                                     userInfo:nil];
    }
    
    self.parentReviewStep = [coder decodeObjectOfClass:[RK1ReviewStep class] forKey:_RK1ParentReviewStepKey];
    
    _addedResults = [coder decodeObjectOfClass:[NSArray class] forKey:_RK1AddedResultsKey];
}

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    RK1StepViewController *viewController = [[[self class] alloc] initWithStep:nil];
    viewController.restorationIdentifier = identifierComponents.lastObject;
    viewController.restorationClass = self;
    return viewController;
}

#pragma mark - Accessibility

- (BOOL)accessibilityPerformEscape {
    [self goBackward];
    return YES;
}

@end
