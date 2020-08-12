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


#import "ORK1TaskViewController.h"

#import "ORK1ActiveStepViewController.h"
#import "ORK1InstructionStepViewController_Internal.h"
#import "ORK1FormStepViewController.h"
#import "ORK1QuestionStepViewController.h"
#import "ORK1ReviewStepViewController_Internal.h"
#import "ORK1StepViewController_Internal.h"
#import "ORK1TappingIntervalStepViewController.h"
#import "ORK1TaskViewController_Internal.h"
#import "ORK1VisualConsentStepViewController.h"

#import "ORK1ActiveStep.h"
#import "ORK1FormStep.h"
#import "ORK1InstructionStep.h"
#import "ORK1OrderedTask.h"
#import "ORK1QuestionStep.h"
#import "ORK1Result_Private.h"
#import "ORK1ReviewStep_Internal.h"
#import "ORK1Step_Private.h"
#import "ORK1TappingIntervalStep.h"
#import "ORK1VisualConsentStep.h"

#import "ORK1Helpers_Internal.h"
#import "ORK1Observer.h"
#import "ORK1Skin.h"

@import AVFoundation;
@import CoreMotion;
#import <CoreLocation/CoreLocation.h>

#import "CEVRK1Theme.h"
#import "ORK1NavigableOrderedTask.h"
#import "ORK1StepNavigationRule.h"
#import "CEVRK1NavigationBarProgressView.h"


typedef void (^_ORK1LocationAuthorizationRequestHandler)(BOOL success);

@interface ORK1LocationAuthorizationRequester : NSObject <CLLocationManagerDelegate>

- (instancetype)initWithHandler:(_ORK1LocationAuthorizationRequestHandler)handler;

- (void)resume;

@end


@implementation ORK1LocationAuthorizationRequester {
    CLLocationManager *_manager;
    _ORK1LocationAuthorizationRequestHandler _handler;
    BOOL _started;
}

- (instancetype)initWithHandler:(_ORK1LocationAuthorizationRequestHandler)handler {
    self = [super init];
    if (self) {
        _handler = handler;
        _manager = [CLLocationManager new];
        _manager.delegate = self;
    }
    return self;
}

- (void)dealloc {
    _manager.delegate = nil;
}

- (void)resume {
    if (_started) {
        return;
    }
    
    _started = YES;
    NSString *whenInUseKey = (NSString *)[[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"];
    NSString *alwaysKey = (NSString *)[[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"];
    
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if ((status == kCLAuthorizationStatusNotDetermined) && (whenInUseKey || alwaysKey)) {
        if (alwaysKey) {
            [_manager requestAlwaysAuthorization];
        } else {
            [_manager requestWhenInUseAuthorization];
        }
    } else {
        [self finishWithResult:(status != kCLAuthorizationStatusDenied)];
    }
}

- (void)finishWithResult:(BOOL)result {
    if (_handler) {
        _handler(result);
        _handler = nil;
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (_handler && _started && status != kCLAuthorizationStatusNotDetermined) {
        [self finishWithResult:(status != kCLAuthorizationStatusDenied)];
    }
}

@end


@protocol ORK1ViewControllerToolbarObserverDelegate <NSObject>

@required
- (void)collectToolbarItemsFromViewController:(UIViewController *)viewController;

@end


@interface ORK1ViewControllerToolbarObserver : ORK1Observer

- (instancetype)initWithTargetViewController:(UIViewController *)target delegate:(id <ORK1ViewControllerToolbarObserverDelegate>)delegate;

@end


@implementation ORK1ViewControllerToolbarObserver

static void *_ORK1ViewControllerToolbarObserverContext = &_ORK1ViewControllerToolbarObserverContext;

- (instancetype)initWithTargetViewController:(UIViewController *)target delegate:(id <ORK1ViewControllerToolbarObserverDelegate>)delegate {
    return [super initWithTarget:target
                        keyPaths:@[ @"navigationItem.leftBarButtonItem", @"navigationItem.rightBarButtonItem", @"toolbarItems", @"navigationItem.title", @"navigationItem.titleView" ]
                        delegate:delegate
                          action:@selector(collectToolbarItemsFromViewController:)
                         context:_ORK1ViewControllerToolbarObserverContext];
}

@end


@interface ORK1TaskViewController () <ORK1ViewControllerToolbarObserverDelegate, ORK1ScrollViewObserverDelegate> {
    NSMutableDictionary *_managedResults;
    NSMutableArray *_managedStepIdentifiers;
    ORK1ViewControllerToolbarObserver *_stepViewControllerObserver;
    ORK1ScrollViewObserver *_scrollViewObserver;
    BOOL _hasSetProgress;
    BOOL _hasBeenPresented;
    BOOL _hasRequestedHealthData;
    ORK1PermissionMask _grantedPermissions;
    NSSet<HKObjectType *> *_requestedHealthTypesForRead;
    NSSet<HKObjectType *> *_requestedHealthTypesForWrite;
    NSURL *_outputDirectory;
    
    NSDate *_presentedDate;
    NSDate *_dismissedDate;
    
    NSString *_lastBeginningInstructionStepIdentifier;
    NSString *_lastRestorableStepIdentifier;
    
    BOOL _hasAudioSession; // does not need state restoration - temporary
    
    NSString *_restoredTaskIdentifier;
    NSString *_restoredStepIdentifier;
}

@property (nonatomic, strong) UIImageView *hairline;
@property (nonatomic, strong) CEVRK1NavigationBarProgressView *progressView;

@property (nonatomic, strong) UINavigationController *childNavigationController;
@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (nonatomic, strong) ORK1StepViewController *currentStepViewController;

@end


@implementation ORK1TaskViewController

@synthesize taskRunUUID=_taskRunUUID;

+ (void)initialize {
    if (self == [ORK1TaskViewController class]) {
        
        [[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[[ORK1TaskViewController class]]] setTranslucent:NO];
        if ([[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[[ORK1TaskViewController class]]] barTintColor] == nil) {
            [[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[[ORK1TaskViewController class]]] setBarTintColor:ORK1Color(ORK1ToolBarTintColorKey)];
        }
        
        if ([[UIToolbar appearanceWhenContainedInInstancesOfClasses:@[[ORK1TaskViewController class]]] barTintColor] == nil) {
            [[UIToolbar appearanceWhenContainedInInstancesOfClasses:@[[ORK1TaskViewController class]]] setBarTintColor:ORK1Color(ORK1ToolBarTintColorKey)];
        }
    }
}

static NSString *const _PageViewControllerRestorationKey = @"pageViewController";
static NSString *const _ChildNavigationControllerRestorationKey = @"childNavigationController";

+ (UIPageViewController *)pageViewController {
    UIPageViewController *pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                                               navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                                             options:nil];
    if ([pageViewController respondsToSelector:@selector(edgesForExtendedLayout)]) {
        pageViewController.edgesForExtendedLayout = UIRectEdgeNone;
    }
    pageViewController.restorationIdentifier = _PageViewControllerRestorationKey;
    pageViewController.restorationClass = self;
    
    
    // Disable swipe to scroll
    for (UIScrollView *view in pageViewController.view.subviews) {
        if ([view isKindOfClass:[UIScrollView class]]) {
            view.scrollEnabled = NO;
        }
    }
    return pageViewController;
}

- (void)setChildNavigationController:(UINavigationController *)childNavigationController {
    if (_childNavigationController) {
        [_childNavigationController.view removeFromSuperview];
        [_childNavigationController removeFromParentViewController];
        _childNavigationController = nil;
    }
    
    if ([self isViewLoaded]) {
        UIView *v = self.view;
        UIView *childView = childNavigationController.view;
        childView.frame = v.bounds;
        childView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [v addSubview:childView];
    }
    _childNavigationController = childNavigationController;
    [self addChildViewController:_childNavigationController];
    [_childNavigationController didMoveToParentViewController:self];
    _childNavigationController.restorationClass = [self class];
    _childNavigationController.restorationIdentifier = _ChildNavigationControllerRestorationKey;
}

- (instancetype)commonInitWithTask:(id<ORK1Task>)task taskRunUUID:(NSUUID *)taskRunUUID {
    UIPageViewController *pageViewController = [[self class] pageViewController];
    self.childNavigationController = [[UINavigationController alloc] initWithRootViewController:pageViewController];
    
    _pageViewController = pageViewController;
    [self setTask: task];
    
    self.showsProgressInNavigationBar = YES;
    
    _managedResults = [NSMutableDictionary dictionary];
    _managedStepIdentifiers = [NSMutableArray array];
    
    self.taskRunUUID = taskRunUUID;
    
    [self.childNavigationController.navigationBar setShadowImage:[UIImage new]];
    self.hairline = [self findHairlineViewUnder:self.childNavigationController.navigationBar];
    self.hairline.alpha = 0.0f;
    self.childNavigationController.toolbar.clipsToBounds = YES;
    
    // Ensure taskRunUUID has non-nil valuetaskRunUUID
    (void)[self taskRunUUID];
    self.restorationClass = [ORK1TaskViewController class];
    
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return [self commonInitWithTask:nil taskRunUUID:[NSUUID UUID]];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    return [self commonInitWithTask:nil taskRunUUID:[NSUUID UUID]];
}
#pragma clang diagnostic pop

- (instancetype)initWithTask:(id<ORK1Task>)task taskRunUUID:(NSUUID *)taskRunUUID {
    self = [super initWithNibName:nil bundle:nil];
    return [self commonInitWithTask:task taskRunUUID:taskRunUUID];
}

- (instancetype)initWithTask:(id<ORK1Task>)task restorationData:(NSData *)data delegate:(id<ORK1TaskViewControllerDelegate>)delegate {
    
    self = [self initWithTask:task taskRunUUID:nil];
    
    if (self) {
        self.delegate = delegate;
        if (data != nil) {
            self.restorationClass = [self class];
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
            [self decodeRestorableStateWithCoder:unarchiver];
            [self applicationFinishedRestoringState];
        }
    }
    return self;
}

- (void)setTaskRunUUID:(NSUUID *)taskRunUUID {
    if (_hasBeenPresented) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"Cannot change task instance UUID after presenting task controller" userInfo:nil];
    }
    
    _taskRunUUID = [taskRunUUID copy];
}

- (void)setTask:(id<ORK1Task>)task {
    if (_hasBeenPresented) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"Cannot change task after presenting task controller" userInfo:nil];
    }
    
    if (task) {
        if (![task conformsToProtocol:@protocol(ORK1Task)]) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Expected a task" userInfo:nil];
        }
        if (task.identifier == nil) {
            ORK1_Log_Warning(@"Task identifier should not be nil.");
        }
        if ([task respondsToSelector:@selector(validateParameters)]) {
            [task validateParameters];
        }
    }
    
    _hasRequestedHealthData = NO;
    _task = task;
}

- (UIBarButtonItem *)defaultCancelButtonItem {
    return [[UIBarButtonItem alloc] initWithTitle:ORK1LocalizedString(@"BUTTON_CANCEL", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelAction:)];
}

- (UIBarButtonItem *)defaultLearnMoreButtonItem {
    return [[UIBarButtonItem alloc] initWithTitle:ORK1LocalizedString(@"BUTTON_LEARN_MORE", nil) style:UIBarButtonItemStylePlain target:self action:@selector(learnMoreAction:)];
}

- (CEVRK1NavigationBarProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[CEVRK1NavigationBarProgressView alloc] initWithFrame:CGRectZero];
    }
    return _progressView;
}

- (void)requestHealthStoreAccessWithReadTypes:(NSSet *)readTypes
                                   writeTypes:(NSSet *)writeTypes
                                      handler:(void (^)(void))handler {
    NSParameterAssert(handler != nil);
    if ((![HKHealthStore isHealthDataAvailable]) || (!readTypes && !writeTypes)) {
        _requestedHealthTypesForRead = nil;
        _requestedHealthTypesForWrite = nil;
        handler();
        return;
    }
    
    _requestedHealthTypesForRead = readTypes;
    _requestedHealthTypesForWrite = writeTypes;
    
    __block HKHealthStore *healthStore = [HKHealthStore new];
    [healthStore requestAuthorizationToShareTypes:writeTypes readTypes:readTypes completion:^(BOOL success, NSError *error) {
        ORK1_Log_Warning(@"Health access: error=%@", error);
        dispatch_async(dispatch_get_main_queue(), handler);
        
        // Clear self-ref.
        healthStore = nil;
    }];
}

- (void)requestPedometerAccessWithHandler:(void (^)(BOOL success))handler {
    NSParameterAssert(handler != nil);
    if (![CMPedometer isStepCountingAvailable]) {
        handler(NO);
        return;
    }
    
    __block CMPedometer *pedometer = [CMPedometer new];
    [pedometer queryPedometerDataFromDate:[NSDate dateWithTimeIntervalSinceNow:-100]
                                   toDate:[NSDate date]
                              withHandler:^(CMPedometerData *pedometerData, NSError *error) {
                                  ORK1_Log_Warning(@"Pedometer access: error=%@", error);
                                  
                                  BOOL success = YES;
                                  if ([[error domain] isEqualToString:CMErrorDomain]) {
                                      switch (error.code) {
                                          case CMErrorMotionActivityNotAuthorized:
                                          case CMErrorNotAuthorized:
                                          case CMErrorNotAvailable:
                                          case CMErrorNotEntitled:
                                          case CMErrorMotionActivityNotAvailable:
                                          case CMErrorMotionActivityNotEntitled:
                                              success = NO;
                                              break;
                                          default:
                                              break;
                                      }
                                  }
                                  
                                  dispatch_async(dispatch_get_main_queue(), ^(void) { handler(success); });
                                  
                                  // Clear self ref to release.
                                  pedometer = nil;
                              }];
}

- (void)requestAudioRecordingAccessWithHandler:(void (^)(BOOL success))handler {
    NSParameterAssert(handler != nil);
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(granted);
        });
    }];
}

- (void)requestCameraAccessWithHandler:(void (^)(BOOL success))handler {
    NSParameterAssert(handler != nil);
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(granted);
        });
    }];
}

- (void)requestLocationAccessWithHandler:(void (^)(BOOL success))handler {
    NSParameterAssert(handler != nil);
    
    // Self-retain; clear the retain cycle in the handler block.
    __block ORK1LocationAuthorizationRequester *requester =
    [[ORK1LocationAuthorizationRequester alloc]
     initWithHandler:^(BOOL success) {
         handler(success);
         
         requester = nil;
     }];
    
    [requester resume];
}

- (ORK1PermissionMask)desiredPermissions {
    ORK1PermissionMask permissions = ORK1PermissionNone;
    if ([self.task respondsToSelector:@selector(requestedPermissions)]) {
        permissions = [self.task requestedPermissions];
    }
    return permissions;
}

- (void)requestHealthAuthorizationWithCompletion:(void (^)(void))completion {
    if (_hasRequestedHealthData) {
        if (completion) completion();
        return;
    }
    
    NSSet *readTypes = nil;
    if ([self.task respondsToSelector:@selector(requestedHealthKitTypesForReading)]) {
        readTypes = [self.task requestedHealthKitTypesForReading];
    }
    
    NSSet *writeTypes = nil;
    if ([self.task respondsToSelector:@selector(requestedHealthKitTypesForWriting)]) {
        writeTypes = [self.task requestedHealthKitTypesForWriting];
    }
    
    ORK1PermissionMask permissions = [self desiredPermissions];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            ORK1_Log_Debug(@"Requesting health access");
            [self requestHealthStoreAccessWithReadTypes:readTypes
                                             writeTypes:writeTypes
                                                handler:^{
                                                    dispatch_semaphore_signal(semaphore);
                                                }];
        });
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        if (permissions & ORK1PermissionCoreMotionAccelerometer) {
            _grantedPermissions |= ORK1PermissionCoreMotionAccelerometer;
        }
        if (permissions & ORK1PermissionCoreMotionActivity) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ORK1_Log_Debug(@"Requesting pedometer access");
                [self requestPedometerAccessWithHandler:^(BOOL success) {
                    if (success) {
                        _grantedPermissions |= ORK1PermissionCoreMotionActivity;
                    } else {
                        _grantedPermissions &= ~ORK1PermissionCoreMotionActivity;
                    }
                    dispatch_semaphore_signal(semaphore);
                }];
            });
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }
        if (permissions & ORK1PermissionAudioRecording) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ORK1_Log_Debug(@"Requesting audio access");
                [self requestAudioRecordingAccessWithHandler:^(BOOL success) {
                    if (success) {
                        _grantedPermissions |= ORK1PermissionAudioRecording;
                    } else {
                        _grantedPermissions &= ~ORK1PermissionAudioRecording;
                    }
                    dispatch_semaphore_signal(semaphore);
                }];
            });
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }
        if (permissions & ORK1PermissionCoreLocation) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ORK1_Log_Debug(@"Requesting location access");
                [self requestLocationAccessWithHandler:^(BOOL success) {
                    if (success) {
                        _grantedPermissions |= ORK1PermissionCoreLocation;
                    } else {
                        _grantedPermissions &= ~ORK1PermissionCoreLocation;
                    }
                    dispatch_semaphore_signal(semaphore);
                }];
            });
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }
        if (permissions & ORK1PermissionCamera) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ORK1_Log_Debug(@"Requesting camera access");
                [self requestCameraAccessWithHandler:^(BOOL success) {
                    if (success) {
                        _grantedPermissions |= ORK1PermissionCamera;
                    } else {
                        _grantedPermissions &= ~ORK1PermissionCamera;
                    }
                    dispatch_semaphore_signal(semaphore);
                }];
            });
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }
        
        _hasRequestedHealthData = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            _hasRequestedHealthData = YES;
            if (completion) completion();
        });
    });
}

- (void)startAudioPromptSessionIfNeeded {
    id<ORK1Task> task = self.task;
    if ([task isKindOfClass:[ORK1OrderedTask class]]) {
        if ([(ORK1OrderedTask *)task providesBackgroundAudioPrompts]) {
            NSError *error = nil;
            if (![self startAudioPromptSessionWithError:&error]) {
                // User-visible console log message
                ORK1_Log_Warning(@"Failed to start audio prompt session: %@", error);
            }
        }
    }
}

- (BOOL)startAudioPromptSessionWithError:(NSError **)errorOut {
    NSError *error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    BOOL success = YES;
    // Use PlayAndRecord to avoid overwriting the category being used by
    // recording configurations.
    if (![session setCategory:AVAudioSessionCategoryPlayback
                  withOptions:0
                        error:&error]) {
        success = NO;
        ORK1_Log_Warning(@"Could not start audio session: %@", error);
    }
    
    // We are setting the session active so that we can stay live to play audio
    // in the background.
    if (success && ![session setActive:YES withOptions:0 error:&error]) {
        success = NO;
        ORK1_Log_Warning(@"Could not set audio session active: %@", error);
    }
    
    if (errorOut) {
        *errorOut = error;
    }
    
    _hasAudioSession = _hasAudioSession || success;
    if (_hasAudioSession) {
        ORK1_Log_Debug(@"*** Started audio session");
    }
    return success;
}

- (void)finishAudioPromptSession {
    if (_hasAudioSession) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *error = nil;
        if (![session setActive:NO withOptions:0 error:&error]) {
            ORK1_Log_Warning(@"Could not deactivate audio session: %@", error);
        } else {
            ORK1_Log_Debug(@"*** Finished audio session");
        }
    }
}

- (NSSet<HKObjectType *> *)requestedHealthTypesForRead {
    return _requestedHealthTypesForRead;
}

- (NSSet<HKObjectType *> *)requestedHealthTypesForWrite {
    return _requestedHealthTypesForWrite;
}

- (void)loadView {
    UIView *view = [[UIView alloc] initWithFrame:(CGRect){{0,0},{320,480}}];
    
    if (_childNavigationController) {
        UIView *childView = _childNavigationController.view;
        childView.frame = view.bounds;
        childView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [view addSubview:childView];
    }
    
    self.view = view;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Certain nested UI Elements (e.g., ORK1HeadlineLabel) are attached to view hierarchy late in the lifecycle. This can cause a noticable,
    // unintended animation of state change as the view animates into view. Setting the fallback task can ensure a redraw cycle of the
    // receiving element can "see" the theme prior to being inside the responder chain so the first displayed draw is the expected theme.
    [CEVRK1Theme setFallbackTaskViewController:self];
    
    UIColor *overrideTintColor = [[CEVRK1Theme themeForElement:self.view] taskViewControllerTintColor];
    if (overrideTintColor) {
        self.view.tintColor = overrideTintColor;
    }
    
    if (!_task) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"Attempted to present task view controller without a task" userInfo:nil];
    }
    
    if (!_hasBeenPresented) {
        // Add first step viewController
        ORK1Step *step = [self nextStep];
        if ([self shouldPresentStep:step]) {
            
            if (![step isKindOfClass:[ORK1InstructionStep class]]) {
                [self startAudioPromptSessionIfNeeded];
                [self requestHealthAuthorizationWithCompletion:nil];
            }
            
            ORK1StepViewController *firstViewController = [self viewControllerForStep:step];
            [self showViewController:firstViewController goForward:YES animated:animated];
            
        }
        _hasBeenPresented = YES;
    }
    
    // Record TaskVC's start time.
    // TaskVC is one time use only, no need to update _startDate later.
    if (!_presentedDate) {
        _presentedDate = [NSDate date];
    }
    
    // Clear endDate if current TaskVC got presented again
    _dismissedDate = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // Set endDate on TaskVC is dismissed,
    // because nextResponder is not nil when current TaskVC is covered by another modal view
    if (self.nextResponder == nil) {
        _dismissedDate = [NSDate date];
    }
}

- (UIImageView *)findHairlineViewUnder:(UIView *)view {
    if ([view isKindOfClass:UIImageView.class] && view.bounds.size.height <= 1.0) {
        return (UIImageView *)view;
    }
    
    for (UIView *subview in view.subviews) {
        UIImageView *imageView = [self findHairlineViewUnder:subview];
        if (imageView) {
            return imageView;
        }
    }
    
    return nil;
}

- (NSArray *)managedResults {
    NSMutableArray *results = [NSMutableArray new];
    
    [_managedStepIdentifiers enumerateObjectsUsingBlock:^(NSString *identifier, NSUInteger idx, BOOL *stop) {
        id <NSCopying> key = [self uniqueManagedKey:identifier index:idx];
        ORK1Result *result = _managedResults[key];
        NSAssert2(result, @"Result should not be nil for identifier %@ with key %@", identifier, key);
        [results addObject:result];
    }];
    
    return [results copy];
}

- (void)setManagedResult:(ORK1StepResult *)result forKey:(NSString *)aKey {
    if (aKey == nil) {
        return;
    }
    
    if (result == nil || NO == [result isKindOfClass:[ORK1StepResult class]]) {
        @throw [NSException exceptionWithName:NSGenericException reason:[NSString stringWithFormat: @"Expect result object to be `ORK1StepResult` type and not nil: {%@ : %@}", aKey, result] userInfo:nil];
        return;
    }
    
    // Manage last result tracking (used in predicate navigation)
    // If the previous result and the replacement result are the same result then `isPreviousResult`
    // will be set to `NO` otherwise it will be marked with `YES`.
    ORK1StepResult *previousResult = _managedResults[aKey];
    previousResult.isPreviousResult = YES;
    result.isPreviousResult = NO;
    
    if (_managedResults == nil) {
        _managedResults = [NSMutableDictionary new];
    }
    _managedResults[aKey] = result;
    
    // Also point to the object using a unique key
    NSUInteger idx = _managedStepIdentifiers.count;
    if ([_managedStepIdentifiers.lastObject isEqualToString:aKey]) {
        idx--;
    }
    id <NSCopying> uniqueKey = [self uniqueManagedKey:aKey index:idx];
    _managedResults[uniqueKey] = result;
}

- (id <NSCopying>)uniqueManagedKey:(NSString*)stepIdentifier index:(NSUInteger)index {
    return [NSString stringWithFormat:@"%@:%@", stepIdentifier, @(index)];
}

- (NSUUID *)taskRunUUID {
    if (_taskRunUUID == nil) {
        _taskRunUUID = [NSUUID UUID];
    }
    return _taskRunUUID;
}

- (ORK1TaskResult *)result {
    
    ORK1TaskResult *result = [[ORK1TaskResult alloc] initWithTaskIdentifier:[self.task identifier] taskRunUUID:self.taskRunUUID outputDirectory:self.outputDirectory];
    result.startDate = _presentedDate;
    result.endDate = _dismissedDate ? :[NSDate date];
    
    // Update current step result
    [self setManagedResult:[self.currentStepViewController result] forKey:self.currentStepViewController.step.identifier];
    
    result.results = [self managedResults];
    
    return result;
}

- (NSData *)restorationData {
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [self encodeRestorableStateWithCoder:archiver];
    [archiver finishEncoding];
    
    return [data copy];
}

- (void)ensureDirectoryExists:(NSURL *)outputDirectory {
    // Only verify existence if the output directory is non-nil.
    // But, even if the output directory is nil, we still set it and forward to the step VC.
    if (outputDirectory != nil) {
        BOOL isDirectory = NO;
        BOOL directoryExists = [[NSFileManager defaultManager] fileExistsAtPath:outputDirectory.path isDirectory:&isDirectory];
        
        if (!directoryExists) {
            NSError *error = nil;
            if (![[NSFileManager defaultManager] createDirectoryAtURL:outputDirectory withIntermediateDirectories:YES attributes:nil error:&error]) {
                @throw [NSException exceptionWithName:NSGenericException reason:@"Could not create output directory and output directory does not exist" userInfo:@{@"error": error}];
            }
            isDirectory = YES;
        } else if (!isDirectory) {
            @throw [NSException exceptionWithName:NSGenericException reason:@"Desired outputDirectory is not a directory or could not be created." userInfo:nil];
        }
    }
}

- (void)setOutputDirectory:(NSURL *)outputDirectory {
    if (_hasBeenPresented) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"Cannot change outputDirectory after presenting task controller" userInfo:nil];
    }
    [self ensureDirectoryExists:outputDirectory];
    
    _outputDirectory = [outputDirectory copy];
    
    [[self currentStepViewController] setOutputDirectory:_outputDirectory];
}

- (void)setRegisteredScrollView:(UIScrollView *)registeredScrollView {
    if (_registeredScrollView != registeredScrollView) {
        
        // Clear harline
        self.hairline.alpha = 0.0;
        
        _registeredScrollView = registeredScrollView;
        
        // Stop old observer
        _scrollViewObserver = nil;
        
        // Start new observer
        if (_registeredScrollView) {
            _scrollViewObserver = [[ORK1ScrollViewObserver alloc] initWithTargetView:_registeredScrollView delegate:self];
        }
    }
}

- (void)suspend {
    [self finishAudioPromptSession];
    [ORK1DynamicCast(_currentStepViewController, ORK1ActiveStepViewController) suspend];
}

- (void)resume {
    [self startAudioPromptSessionIfNeeded];
    [ORK1DynamicCast(_currentStepViewController, ORK1ActiveStepViewController) resume];
}

- (void)goForward {
    [_currentStepViewController goForward];
}

- (void)goBackward {
    [_currentStepViewController goBackward];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    UIInterfaceOrientationMask supportedOrientations;
    if (self.currentStepViewController) {
        supportedOrientations = self.currentStepViewController.supportedInterfaceOrientations;
    } else {
        supportedOrientations = [[self nextStep].stepViewControllerClass supportedInterfaceOrientations];
    }
    return supportedOrientations;
}

#pragma mark - internal helpers

- (void)updateLastBeginningInstructionStepIdentifierForStep:(ORK1Step *)step
                                                  goForward:(BOOL)goForward {
    if (NO == goForward) {
        // Going backward, check current step to nil saved state
        if (_lastBeginningInstructionStepIdentifier != nil &&
            [_currentStepViewController.step.identifier isEqualToString:_lastBeginningInstructionStepIdentifier]) {
            
            _lastBeginningInstructionStepIdentifier = nil;
        }
        // Don't return here, because the *next* step might NOT be an instruction step
        // the next time we look.
    }
    
    ORK1Step *nextStep = [self.task stepAfterStep:step withResult:[self result]];
    BOOL isNextStepInstructionStep = [nextStep isKindOfClass:[ORK1InstructionStep class]];
    
    if (_lastBeginningInstructionStepIdentifier == nil &&
        nextStep && NO == isNextStepInstructionStep) {
        _lastBeginningInstructionStepIdentifier = step.identifier;
    }
}

- (BOOL)isStepLastBeginningInstructionStep:(ORK1Step *)step {
    if (!step) {
        return NO;
    }
    return (_lastBeginningInstructionStepIdentifier != nil &&
            [step isKindOfClass:[ORK1InstructionStep class]]&&
            [step.identifier isEqualToString:_lastBeginningInstructionStepIdentifier]);
}

- (BOOL)grantedAtLeastOnePermission {
    // Return YES, if no desired permission or granted at least one permission.
    ORK1PermissionMask desiredMask = [self desiredPermissions];
    return (desiredMask == 0 || ((desiredMask & _grantedPermissions) != 0));
}

- (void)showViewController:(ORK1StepViewController *)viewController goForward:(BOOL)goForward animated:(BOOL)animated {
    if (nil == viewController) {
        return;
    }
    
    ORK1Step *step = viewController.step;
    [self updateLastBeginningInstructionStepIdentifierForStep:step goForward:goForward];
    
    
    if ([self isStepLastBeginningInstructionStep:step]) {
        // Check again, in case it's a user-supplied view controller for this step that's not an ORK1InstructionStepViewController.
        if ([viewController isKindOfClass:[ORK1InstructionStepViewController class]]) {
            [(ORK1InstructionStepViewController *)viewController useAppropriateButtonTitleAsLastBeginningInstructionStep];
        }
    }
    
    ORK1StepViewController *fromController = self.currentStepViewController;
    if (fromController && animated && [self isStepLastBeginningInstructionStep:fromController.step]) {
        [self startAudioPromptSessionIfNeeded];
        
        if ( [self grantedAtLeastOnePermission] == NO) {
            // Do the health request and THEN proceed.
            [self requestHealthAuthorizationWithCompletion:^{
                
                // If we are able to collect any data, proceed.
                // An alternative rule would be to never proceed if any permission fails.
                // However, since iOS does not re-present requests for access, we
                // can easily fail even if the user does not see a dialog, which would
                // be highly unexpected.
                if ([self grantedAtLeastOnePermission] == NO) {
                    [self reportError:[NSError errorWithDomain:NSCocoaErrorDomain
                                                          code:NSUserCancelledError
                                                      userInfo:@{@"reason": @"Required permissions not granted."}]
                               onStep:fromController.step];
                } else {
                    [self showViewController:viewController goForward:goForward animated:animated];
                }
            }];
            return;
        }
    }
    
    if (step.identifier && ![_managedStepIdentifiers.lastObject isEqualToString:step.identifier]) {
        [_managedStepIdentifiers addObject:step.identifier];
    }
    if ([step isRestorable] && !(viewController.isBeingReviewed && viewController.parentReviewStep.isStandalone)) {
        _lastRestorableStepIdentifier = step.identifier;
    }
    
    UIPageViewControllerNavigationDirection direction = goForward ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
    
    ORK1AdjustPageViewControllerNavigationDirectionForRTL(&direction);
    
    ORK1StepViewControllerNavigationDirection stepDirection = goForward ? ORK1StepViewControllerNavigationDirectionForward : ORK1StepViewControllerNavigationDirectionReverse;
    
    [viewController willNavigateDirection:stepDirection];
    
    ORK1_Log_Debug(@"%@ %@", self, viewController);
    
    // Stop monitor old scrollView, reset hairline's alpha to 0;
    self.registeredScrollView = nil;
    
    // Switch to non-animated transition if the application is not in the foreground.
    animated = animated && ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive);
    
    // Update currentStepViewController now, so we don't accept additional transition requests
    // from the same VC.
    _currentStepViewController = viewController;
    
    ORK1TaskProgress taskProgress;
    taskProgress.current = 0;
    taskProgress.total =  0;
    
    if ([self shouldDisplayProgress]) {
        ORK1TaskProgress progress = [_task progressOfCurrentStep:viewController.step withResult:[self result]];
        if (progress.total > 0) {
            taskProgress = progress;
        }
    }
    
    ORK1WeakTypeOf(self) weakSelf = self;
    [self.pageViewController setViewControllers:@[viewController] direction:direction animated:animated completion:^(BOOL finished) {
        
        if (weakSelf == nil) {
            ORK1_Log_Debug(@"Task VC has been dismissed, skipping block code");
            return;
        }
        
        ORK1StrongTypeOf(weakSelf) strongSelf = weakSelf;
        
        ORK1_Log_Debug(@"%@ %@", strongSelf, viewController);
        
        // Set the progress only if progress value returned or if it is nil having previously set a progress to display.
        if (taskProgress.total > 0 || strongSelf->_hasSetProgress) {
            if (strongSelf->_hasSetProgress && taskProgress.total == 0) {
                // remove any progress
                strongSelf.pageViewController.navigationItem.titleView = nil;
                strongSelf.pageViewController.navigationItem.title = nil;
            } else {
                ORK1OrderedTask *orderedTask = (ORK1OrderedTask *)strongSelf.task;
                if (orderedTask.progressIndicatorStyle == CEVRK1TaskProgressIndicatorStyleBar) {
                    strongSelf.pageViewController.navigationItem.title = nil;
                    float calculatedProgress = 0;
                    if (orderedTask.progressBarProgressionMetric == CEVRK1TaskProgressBarProgressionMetricFastToSlow) {
                        calculatedProgress = log((float)taskProgress.current + 1) / log((float)taskProgress.total + 1);
                    } else {  // Linear
                        calculatedProgress = (float)taskProgress.current / (float)taskProgress.total;
                    }
                    [strongSelf.progressView setProgress:calculatedProgress];
                    strongSelf.pageViewController.navigationItem.titleView = strongSelf.progressView;
                    
                    // for UITesting, we will add a title that will not display, but should appear via accessibility
                    NSUInteger progressPercent = (NSUInteger)(calculatedProgress * 100);
                    strongSelf.pageViewController.navigationItem.title = [NSString stringWithFormat:@"ProgressBar:%@", @(progressPercent)];
                    
                } else {
                    strongSelf.pageViewController.navigationItem.titleView = nil;
                    strongSelf.pageViewController.navigationItem.title = [NSString localizedStringWithFormat:ORK1LocalizedString(@"STEP_PROGRESS_FORMAT", nil) ,ORK1LocalizedStringFromNumber(@(taskProgress.current)), ORK1LocalizedStringFromNumber(@(taskProgress.total))];
                }
            }
        }
        
        strongSelf->_hasSetProgress = (taskProgress.total > 0);
        
        // Collect toolbarItems
        [strongSelf collectToolbarItemsFromViewController:viewController];
    }];
}

- (BOOL)shouldPresentStep:(ORK1Step *)step {
    BOOL shouldPresent = (step != nil);
    
    if (shouldPresent && [self.delegate respondsToSelector:@selector(taskViewController:shouldPresentStep:)]) {
        shouldPresent = [self.delegate taskViewController:self shouldPresentStep:step];
    }
    
    return shouldPresent;
}

- (ORK1Step *)nextStep {
    ORK1Step *step = nil;
    
    if ([self.task respondsToSelector:@selector(stepAfterStep:withResult:)]) {
        step = [self.task stepAfterStep:self.currentStepViewController.step withResult:[self result]];
    }
    
    return step;
    
}

- (ORK1Step *)prevStep {
    ORK1Step *step = nil;
    
    if ([self.task respondsToSelector:@selector(stepBeforeStep:withResult:)]) {
        step = [self.task stepBeforeStep:self.currentStepViewController.step withResult:[self result]];
    }
    
    return step;
}

- (void)collectToolbarItemsFromViewController:(UIViewController *)viewController {
    if (_currentStepViewController == viewController) {
        _pageViewController.toolbarItems = viewController.toolbarItems;
        _pageViewController.navigationItem.leftBarButtonItem = viewController.navigationItem.leftBarButtonItem;
        _pageViewController.navigationItem.rightBarButtonItem = viewController.navigationItem.rightBarButtonItem;
        if (![self shouldDisplayProgress]) {
            _pageViewController.navigationItem.title = viewController.navigationItem.title;
            _pageViewController.navigationItem.titleView = viewController.navigationItem.titleView;
        }
    }
}

- (void)observedScrollViewDidScroll:(UIScrollView *)scrollView {
    // alpha's range [0.0, 1.0]
    float alpha = MAX( MIN(scrollView.contentOffset.y / 64.0, 1.0), 0.0);
    self.hairline.alpha = alpha;
}

- (NSArray<ORK1Step *> *)stepsForReviewStep:(ORK1ReviewStep *)reviewStep {
    NSMutableArray<ORK1Step *> *steps = [[NSMutableArray<ORK1Step *> alloc] init];
    if (reviewStep.isStandalone) {
        steps = nil;
    } else {
        ORK1WeakTypeOf(self) weakSelf = self;
        [_managedStepIdentifiers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            ORK1StrongTypeOf(self) strongSelf = weakSelf;
            ORK1Step *nextStep = [strongSelf.task stepWithIdentifier:(NSString*) obj];
            if (nextStep && ![nextStep.identifier isEqualToString:reviewStep.identifier]) {
                [steps addObject:nextStep];
            } else {
                *stop = YES;
            }
        }];
    }
    return [steps copy];
}

- (ORK1StepViewController *)viewControllerForStep:(ORK1Step *)step {
    if (step == nil) {
        return nil;
    }
    
    ORK1StepViewController *stepViewController = nil;
    
    if ([self.delegate respondsToSelector:@selector(taskViewController:viewControllerForStep:)]) {
        // NOTE: While the delegate does not have direct access to the defaultResultSource,
        // it is assumed that it can set results as needed on the custom implementation of an
        // ORK1StepViewController that it returns.
        stepViewController = [self.delegate taskViewController:self viewControllerForStep:step];
    }
    
    // If the delegate did not return a step view controller then instantiate one
    if (!stepViewController) {
        
        // Special-case the ORK1ReviewStep
        if ([step isKindOfClass:[ORK1ReviewStep class]]) {
            ORK1ReviewStep *reviewStep = (ORK1ReviewStep *)step;
            NSArray *steps = [self stepsForReviewStep:reviewStep];
            id<ORK1TaskResultSource> resultSource = reviewStep.isStandalone ? reviewStep.resultSource : self.result;
            stepViewController = [[ORK1ReviewStepViewController alloc] initWithReviewStep:(ORK1ReviewStep *) step steps:steps resultSource:resultSource];
            ORK1ReviewStepViewController *reviewStepViewController = (ORK1ReviewStepViewController *) stepViewController;
            reviewStepViewController.reviewDelegate = self;
        }
        else {
            
            // Get the step result associated with this step
            ORK1StepResult *result = nil;
            ORK1StepResult *previousResult = _managedResults[step.identifier];
            
            // Check the default source first
            BOOL alwaysCheckForDefaultResult = ([self.defaultResultSource respondsToSelector:@selector(alwaysCheckForDefaultResult)] &&
                                                [self.defaultResultSource alwaysCheckForDefaultResult]);
            if ((previousResult == nil) || alwaysCheckForDefaultResult) {
                result = [self.defaultResultSource stepResultForStepIdentifier:step.identifier];
            }
            
            // If nil, assign to the previous result (if available) otherwise create new instance
            if (!result) {
                result = previousResult ? : [[ORK1StepResult alloc] initWithIdentifier:step.identifier];
            }
            
            // Allow the step to instantiate the view controller. This will allow either the default
            // implementation using an override of the internal method `-stepViewControllerClass` or
            // allow for storyboard implementations.
            stepViewController = [step instantiateStepViewControllerWithResult:result];
        }
    }
    
    // Throw an exception if the created step view controller is not a subclass of ORK1StepViewController
    ORK1ThrowInvalidArgumentExceptionIfNil(stepViewController);
    if (![stepViewController isKindOfClass:[ORK1StepViewController class]]) {
        @throw [NSException exceptionWithName:NSGenericException reason:[NSString stringWithFormat:@"View controller should be of class %@", [ORK1StepViewController class]] userInfo:@{@"viewController": stepViewController}];
    }
    
    // If this is a restorable task view controller, check that the restoration identifier and class
    // are set on the step result. If not, do so here. This gives the instantiator the opportunity to
    // set this value, but ensures that it is set to the default if the instantiator does not do so.
    if ([self.delegate respondsToSelector:@selector(taskViewControllerSupportsSaveAndRestore:)] &&
        [self.delegate taskViewControllerSupportsSaveAndRestore:self]){
        if (stepViewController.restorationIdentifier == nil) {
            stepViewController.restorationIdentifier = step.identifier;
        }
        if (stepViewController.restorationClass == nil) {
            stepViewController.restorationClass = [stepViewController class];
        }
    }
    
    stepViewController.outputDirectory = self.outputDirectory;
    [self setManagedResult:stepViewController.result forKey:step.identifier];
    
    
    if (stepViewController.cancelButtonItem == nil) {
        stepViewController.cancelButtonItem = [self defaultCancelButtonItem];
    }
    
    if ([self.delegate respondsToSelector:@selector(taskViewController:hasLearnMoreForStep:)] &&
        [self.delegate taskViewController:self hasLearnMoreForStep:step]) {
        
        stepViewController.learnMoreButtonItem = [self defaultLearnMoreButtonItem];
    }
    
    stepViewController.delegate = self;
    
    _stepViewControllerObserver = [[ORK1ViewControllerToolbarObserver alloc] initWithTargetViewController:stepViewController delegate:self];
    return stepViewController;
}

- (BOOL)shouldDisplayProgress {
    BOOL taskSuppressProgressDisplay = NO;
    if ([_task isKindOfClass:[ORK1OrderedTask class]]) {
        taskSuppressProgressDisplay = ([(ORK1OrderedTask *)_task progressIndicatorStyle] == CEVRK1TaskProgressIndicatorStyleNone);
    }
    return self.showsProgressInNavigationBar
            && [_task respondsToSelector:@selector(progressOfCurrentStep:withResult:)]
            && self.currentStepViewController.step.showsProgress
            && !(self.currentStepViewController.parentReviewStep.isStandalone)
            && !(self.currentStepViewController.step.excludeFromProgressCalculation)
            && !taskSuppressProgressDisplay;
}

#pragma mark - internal action Handlers

- (void)finishWithReason:(ORK1TaskViewControllerFinishReason)reason error:(NSError *)error {
    ORK1StrongTypeOf(self.delegate) strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(taskViewController:didFinishWithReason:error:)]) {
        [strongDelegate taskViewController:self didFinishWithReason:reason error:error];
    }
}

- (void)presentCancelOptions:(BOOL)saveable sender:(UIBarButtonItem *)sender {
    
    if ([self.delegate respondsToSelector:@selector(taskViewControllerShouldConfirmCancel:)] &&
        ![self.delegate taskViewControllerShouldConfirmCancel:self]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self finishWithReason:ORK1TaskViewControllerFinishReasonDiscarded error:nil];
        });
        return;
    }
    
    BOOL supportSaving = NO;
    if ([self.delegate respondsToSelector:@selector(taskViewControllerSupportsSaveAndRestore:)]) {
        supportSaving = [self.delegate taskViewControllerSupportsSaveAndRestore:self];
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    alert.popoverPresentationController.barButtonItem = sender;
    
    if (supportSaving && saveable) {
        [alert addAction:[UIAlertAction actionWithTitle:ORK1LocalizedString(@"BUTTON_OPTION_SAVE", nil)
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        [self finishWithReason:ORK1TaskViewControllerFinishReasonSaved error:nil];
                                                    });
                                                }]];
    }
    
    NSString *discardTitle = saveable ? ORK1LocalizedString(@"BUTTON_OPTION_DISCARD", nil) : ORK1LocalizedString(@"BUTTON_OPTION_STOP_TASK", nil);
    
    [alert addAction:[UIAlertAction actionWithTitle:discardTitle
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    [self finishWithReason:ORK1TaskViewControllerFinishReasonDiscarded error:nil];
                                                });
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:ORK1LocalizedString(@"BUTTON_CANCEL", nil)
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)cancelAction:(UIBarButtonItem *)sender {
    // Should we also include visualConsentStep here? Others?
    BOOL isCurrentInstructionStep = [self.currentStepViewController.step isKindOfClass:[ORK1InstructionStep class]];
    
    // [self result] would not include any results beyond current step.
    // Use _managedResults to get the completed result set.
    NSArray *results = _managedResults.allValues;
    BOOL saveable = NO;
    for (ORK1StepResult *result in results) {
        if ([result isSaveable]) {
            saveable = YES;
            break;
        }
    }
    
    BOOL isStandaloneReviewStep = NO;
    if ([self.currentStepViewController.step isKindOfClass:[ORK1ReviewStep class]]) {
        ORK1ReviewStep *reviewStep = (ORK1ReviewStep *)self.currentStepViewController.step;
        isStandaloneReviewStep = reviewStep.isStandalone;
    }
    
    if ((isCurrentInstructionStep && saveable == NO) || isStandaloneReviewStep || self.currentStepViewController.readOnlyMode) {
        [self finishWithReason:ORK1TaskViewControllerFinishReasonDiscarded error:nil];
    } else {
        [self presentCancelOptions:saveable sender:sender];
    }
}

- (IBAction)learnMoreAction:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(taskViewController:learnMoreForStep:)]) {
        [self.delegate taskViewController:self learnMoreForStep:self.currentStepViewController];
    }
}

- (void)reportError:(NSError *)error onStep:(ORK1Step *)step {
    [self finishWithReason:ORK1TaskViewControllerFinishReasonFailed error:error];
}

- (void)flipToNextPageFrom:(ORK1StepViewController *)fromController {
    if (fromController != _currentStepViewController) {
        return;
    }
    
    ORK1Step *step = fromController.parentReviewStep;
    if (!step) {
        step = [self nextStep];
    }
    
    if (step == nil) {
        if ([self.delegate respondsToSelector:@selector(taskViewController:didChangeResult:)]) {
            [self.delegate taskViewController:self didChangeResult:[self result]];
        }
        
        [self finishAudioPromptSession];
        
        if ([self.task isKindOfClass:[ORK1NavigableOrderedTask class]]) {
            ORK1NavigableOrderedTask *orderedTask = (ORK1NavigableOrderedTask *)self.task;
            if ([orderedTask.specialEndSurveyStepIdentifier isEqualToString:ORK1CancelStepIdentifier]) {
                [self cancelAction:nil];
            } else if ([orderedTask.specialEndSurveyStepIdentifier isEqualToString:ORK1CancelAndSaveStepIdentifier]) {
                [self finishWithReason:ORK1TaskViewControllerFinishReasonSaved error:nil];
            } else if ([orderedTask.specialEndSurveyStepIdentifier isEqualToString:ORK1CancelAndDiscardStepIdentifier]) {
                [self finishWithReason:ORK1TaskViewControllerFinishReasonDiscarded error:nil];
            } else {  // includes ORK1CompleteStepIdentifier
                [self finishWithReason:ORK1TaskViewControllerFinishReasonCompleted error:nil];
            }
        } else {
            [self finishWithReason:ORK1TaskViewControllerFinishReasonCompleted error:nil];
        }
    } else if ([self shouldPresentStep:step]) {
        ORK1StepViewController *stepViewController = [self viewControllerForStep:step];
        NSAssert(stepViewController != nil, @"A non-nil step should always generate a step view controller");
        if (fromController.isBeingReviewed) {
            [_managedStepIdentifiers removeLastObject];
        }
        [self showViewController:stepViewController goForward:YES animated:YES];
    }
    
}

- (void)flipToPreviousPageFrom:(ORK1StepViewController *)fromController {
    if (fromController != _currentStepViewController) {
        return;
    }
    
    ORK1Step *step = fromController.parentReviewStep;
    if (!step) {
        step = [self prevStep];
    }
    ORK1StepViewController *stepViewController = nil;
    
    if ([self shouldPresentStep:step]) {
        ORK1Step *currentStep = _currentStepViewController.step;
        NSString *itemId = currentStep.identifier;
        
        stepViewController = [self viewControllerForStep:step];
        if (stepViewController) {
            // Remove the identifier from the list
            assert([itemId isEqualToString:_managedStepIdentifiers.lastObject]);
            [_managedStepIdentifiers removeLastObject];
            
            [self showViewController:stepViewController goForward:NO animated:YES];
        }
    }
}

#pragma mark -  ORK1StepViewControllerDelegate

- (void)stepViewControllerWillAppear:(ORK1StepViewController *)viewController {
    if ([self.delegate respondsToSelector:@selector(taskViewController:stepViewControllerWillAppear:)]) {
        [self.delegate taskViewController:self stepViewControllerWillAppear:viewController];
    }
}

- (void)stepViewController:(ORK1StepViewController *)stepViewController didFinishWithNavigationDirection:(ORK1StepViewControllerNavigationDirection)direction {
    
    if (!stepViewController.readOnlyMode) {
        // Add step result object
        [self setManagedResult:[stepViewController result] forKey:stepViewController.step.identifier];
    }
    
    // Alert the delegate that the step is finished 
    ORK1StrongTypeOf(self.delegate) strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(taskViewController:stepViewControllerWillDisappear:navigationDirection:)]) {
        [strongDelegate taskViewController:self stepViewControllerWillDisappear:stepViewController navigationDirection:direction];
    }
    
    if (direction == ORK1StepViewControllerNavigationDirectionForward) {
        [self flipToNextPageFrom:stepViewController];
    } else {
        [self flipToPreviousPageFrom:stepViewController];
    }
}

- (void)stepViewControllerDidFail:(ORK1StepViewController *)stepViewController withError:(NSError *)error {
    [self finishWithReason:ORK1TaskViewControllerFinishReasonFailed error:error];
}

- (void)stepViewControllerResultDidChange:(ORK1StepViewController *)stepViewController {
    if (!stepViewController.readOnlyMode) {
        [self setManagedResult:stepViewController.result forKey:stepViewController.step.identifier];
    }
    
    ORK1StrongTypeOf(self.delegate) strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(taskViewController:didChangeResult:)]) {
        [strongDelegate taskViewController:self didChangeResult:[self result]];
    }
}

- (BOOL)stepViewControllerHasPreviousStep:(ORK1StepViewController *)stepViewController {
    ORK1Step *thisStep = stepViewController.step;
    if (!thisStep) {
        return NO;
    }
    ORK1Step *previousStep = stepViewController.parentReviewStep;
    if (!previousStep) {
        previousStep = [self stepBeforeStep:thisStep];
    }
    if ([previousStep isKindOfClass:[ORK1ActiveStep class]] || ([thisStep allowsBackNavigation] == NO)) {
        previousStep = nil; // Can't go back to an active step
    }
    return (previousStep != nil);
}

- (BOOL)stepViewControllerHasNextStep:(ORK1StepViewController *)stepViewController {
    ORK1Step *thisStep = stepViewController.step;
    if (!thisStep) {
        return NO;
    }
    ORK1Step *nextStep = [self stepAfterStep:thisStep];
    return (nextStep != nil);
}

- (void)stepViewController:(ORK1StepViewController *)stepViewController recorder:(ORK1Recorder *)recorder didFailWithError:(NSError *)error {
    ORK1StrongTypeOf(self.delegate) strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(taskViewController:recorder:didFailWithError:)]) {
        [strongDelegate taskViewController:self recorder:recorder didFailWithError:error];
    }
}

- (ORK1Step *)stepBeforeStep:(ORK1Step *)step {
    return [self.task stepBeforeStep:step withResult:[self result]];
}

- (ORK1Step *)stepAfterStep:(ORK1Step *)step {
    return [self.task stepAfterStep:step withResult:[self result]];
}

#pragma mark - ORK1ReviewStepViewControllerDelegate

- (void)reviewStepViewController:(ORK1ReviewStepViewController *)reviewStepViewController
                  willReviewStep:(ORK1Step *)step {
    id<ORK1TaskResultSource> resultSource = _defaultResultSource;
    if (reviewStepViewController.reviewStep && reviewStepViewController.reviewStep.isStandalone) {
        _defaultResultSource = reviewStepViewController.reviewStep.resultSource;
    }
    ORK1StepViewController *stepViewController = [self viewControllerForStep:step];
    _defaultResultSource = resultSource;
    NSAssert(stepViewController != nil, @"A non-nil step should always generate a step view controller");
    stepViewController.continueButtonTitle = ORK1LocalizedString(@"BUTTON_SAVE", nil);
    stepViewController.parentReviewStep = (ORK1ReviewStep *) reviewStepViewController.step;
    stepViewController.skipButtonTitle = stepViewController.readOnlyMode ? ORK1LocalizedString(@"BUTTON_READ_ONLY_MODE", nil) : ORK1LocalizedString(@"BUTTON_CLEAR_ANSWER", nil);
    if (stepViewController.parentReviewStep.isStandalone) {
        stepViewController.navigationItem.title = stepViewController.parentReviewStep.title;
    }
    [self showViewController:stepViewController goForward:YES animated:YES];
}

#pragma mark - UIStateRestoring

static NSString *const _ORK1TaskRunUUIDRestoreKey = @"taskRunUUID";
static NSString *const _ORK1ShowsProgressInNavigationBarRestoreKey = @"showsProgressInNavigationBar";
static NSString *const _ORK1ManagedResultsRestoreKey = @"managedResults";
static NSString *const _ORK1ManagedStepIdentifiersRestoreKey = @"managedStepIdentifiers";
static NSString *const _ORK1HasSetProgressRestoreKey = @"hasSetProgress";
static NSString *const _ORK1HasRequestedHealthDataRestoreKey = @"hasRequestedHealthData";
static NSString *const _ORK1RequestedHealthTypesForReadRestoreKey = @"requestedHealthTypesForRead";
static NSString *const _ORK1RequestedHealthTypesForWriteRestoreKey = @"requestedHealthTypesForWrite";
static NSString *const _ORK1OutputDirectoryRestoreKey = @"outputDirectory";
static NSString *const _ORK1LastBeginningInstructionStepIdentifierKey = @"lastBeginningInstructionStepIdentifier";
static NSString *const _ORK1TaskIdentifierRestoreKey = @"taskIdentifier";
static NSString *const _ORK1StepIdentifierRestoreKey = @"stepIdentifier";
static NSString *const _ORK1PresentedDate = @"presentedDate";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:_taskRunUUID forKey:_ORK1TaskRunUUIDRestoreKey];
    [coder encodeBool:self.showsProgressInNavigationBar forKey:_ORK1ShowsProgressInNavigationBarRestoreKey];
    [coder encodeObject:_managedResults forKey:_ORK1ManagedResultsRestoreKey];
    [coder encodeObject:_managedStepIdentifiers forKey:_ORK1ManagedStepIdentifiersRestoreKey];
    [coder encodeBool:_hasSetProgress forKey:_ORK1HasSetProgressRestoreKey];
    [coder encodeObject:_requestedHealthTypesForRead forKey:_ORK1RequestedHealthTypesForReadRestoreKey];
    [coder encodeObject:_requestedHealthTypesForWrite forKey:_ORK1RequestedHealthTypesForWriteRestoreKey];
    [coder encodeObject:_presentedDate forKey:_ORK1PresentedDate];
    
    [coder encodeObject:ORK1BookmarkDataFromURL(_outputDirectory) forKey:_ORK1OutputDirectoryRestoreKey];
    [coder encodeObject:_lastBeginningInstructionStepIdentifier forKey:_ORK1LastBeginningInstructionStepIdentifierKey];
    
    [coder encodeObject:_task.identifier forKey:_ORK1TaskIdentifierRestoreKey];
    
    ORK1Step *step = [_currentStepViewController step];
    if ([step isRestorable] && !(_currentStepViewController.isBeingReviewed && _currentStepViewController.parentReviewStep.isStandalone)) {
        [coder encodeObject:step.identifier forKey:_ORK1StepIdentifierRestoreKey];
    } else if (_lastRestorableStepIdentifier) {
        [coder encodeObject:_lastRestorableStepIdentifier forKey:_ORK1StepIdentifierRestoreKey];
    }
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    _taskRunUUID = [coder decodeObjectOfClass:[NSUUID class] forKey:_ORK1TaskRunUUIDRestoreKey];
    self.showsProgressInNavigationBar = [coder decodeBoolForKey:_ORK1ShowsProgressInNavigationBarRestoreKey];
    
    _outputDirectory = ORK1URLFromBookmarkData([coder decodeObjectOfClass:[NSData class] forKey:_ORK1OutputDirectoryRestoreKey]);
    [self ensureDirectoryExists:_outputDirectory];
    
    // Must have a task object already provided by this point in the restoration, in order to restore any other state.
    if (_task) {
        
        // Recover partially entered results, even if we may not be able to jump to the desired step.
        _managedResults = [coder decodeObjectOfClass:[NSMutableDictionary class] forKey:_ORK1ManagedResultsRestoreKey];
        _managedStepIdentifiers = [coder decodeObjectOfClass:[NSMutableArray class] forKey:_ORK1ManagedStepIdentifiersRestoreKey];
        
        _restoredTaskIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:_ORK1TaskIdentifierRestoreKey];
        if (_restoredTaskIdentifier) {
            if (![_task.identifier isEqualToString:_restoredTaskIdentifier]) {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                               reason:[NSString stringWithFormat:@"Restored task identifier %@ does not match task %@ provided",_restoredTaskIdentifier,_task.identifier]
                                             userInfo:nil];
            }
        }
        
        if ([_task respondsToSelector:@selector(stepWithIdentifier:)]) {
            _hasSetProgress = [coder decodeBoolForKey:_ORK1HasSetProgressRestoreKey];
            _requestedHealthTypesForRead = [coder decodeObjectOfClass:[NSSet class] forKey:_ORK1RequestedHealthTypesForReadRestoreKey];
            _requestedHealthTypesForWrite = [coder decodeObjectOfClass:[NSSet class] forKey:_ORK1RequestedHealthTypesForWriteRestoreKey];
            _presentedDate = [coder decodeObjectOfClass:[NSDate class] forKey:_ORK1PresentedDate];
            _lastBeginningInstructionStepIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:_ORK1LastBeginningInstructionStepIdentifierKey];
            
            _restoredStepIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:_ORK1StepIdentifierRestoreKey];
        } else {
            ORK1_Log_Warning(@"Not restoring current step of task %@ because it does not implement -stepWithIdentifier:", _task.identifier);
        }
    }
}


- (void)applicationFinishedRestoringState {
    [super applicationFinishedRestoringState];
    
    _pageViewController = (UIPageViewController *)[self.childNavigationController viewControllers][0];
    
    if (!_task) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"Task must be provided to restore task view controller"
                                     userInfo:nil];
    }
    
    if (_restoredStepIdentifier) {
        ORK1StepViewController *stepViewController = _currentStepViewController;
        if (stepViewController) {
            stepViewController.delegate = self;
            
            if (stepViewController.cancelButtonItem == nil) {
                stepViewController.cancelButtonItem = [self defaultCancelButtonItem];
            }
            
            if ([self.delegate respondsToSelector:@selector(taskViewController:hasLearnMoreForStep:)] &&
                [self.delegate taskViewController:self hasLearnMoreForStep:stepViewController.step]) {
                
                stepViewController.learnMoreButtonItem = [self defaultLearnMoreButtonItem];
            }
            
            _stepViewControllerObserver = [[ORK1ViewControllerToolbarObserver alloc] initWithTargetViewController:stepViewController delegate:self];
            
        } else if ([_task respondsToSelector:@selector(stepWithIdentifier:)]) {
            stepViewController = [self viewControllerForStep:[_task stepWithIdentifier:_restoredStepIdentifier]];
        } else {
            stepViewController = [self viewControllerForStep:[_task stepAfterStep:nil withResult:[self result]]];
        }
        
        if (stepViewController != nil) {
            [self showViewController:stepViewController goForward:YES animated:NO];
            _hasBeenPresented = YES;
        }
    }
}

+ (UIViewController *) viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    if ([identifierComponents.lastObject isEqualToString:_PageViewControllerRestorationKey]) {
        UIPageViewController *pageViewController = [self pageViewController];
        pageViewController.restorationIdentifier = identifierComponents.lastObject;
        pageViewController.restorationClass = self;
        return pageViewController;
    } else if ([identifierComponents.lastObject isEqualToString:_ChildNavigationControllerRestorationKey]) {
        UINavigationController *navigationController = [UINavigationController new];
        navigationController.restorationIdentifier = identifierComponents.lastObject;
        navigationController.restorationClass = self;
        return navigationController;
    }
    
    ORK1TaskViewController *taskViewController = [[ORK1TaskViewController alloc] initWithTask:nil taskRunUUID:nil];
    taskViewController.restorationIdentifier = identifierComponents.lastObject;
    taskViewController.restorationClass = self;
    return taskViewController;
}

#pragma mark UINavigationController pass-throughs

- (void)setNavigationBarHidden:(BOOL)navigationBarHidden {
    self.childNavigationController.navigationBarHidden = navigationBarHidden;
}

- (BOOL)isNavigationBarHidden {
    return self.childNavigationController.navigationBarHidden;
}

- (void)setNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated {
    [self.childNavigationController setNavigationBarHidden:hidden animated:YES];
}

- (UINavigationBar *)navigationBar {
    return self.childNavigationController.navigationBar;
}

@end
