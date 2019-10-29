/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 Copyright (c) 2015, Bruce Duncan.
 Copyright (c) 2015-2016, Ricardo Sánchez-Sáez.
 Copyright (c) 2016, Sage Bionetworks.
 Copyright (c) 2017, Macro Yau.

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


#import "MainViewController.h"

#import "AppDelegate.h"
#import "DynamicTask.h"
#import "ORKTest-Swift.h"
#import "DragonPokerStep.h"

@import ResearchKit;

@import AVFoundation;


#define DefineStringKey(x) static NSString *const x = @#x

DefineStringKey(ConsentTaskIdentifier);
DefineStringKey(ConsentReviewTaskIdentifier);
DefineStringKey(EligibilityFormTaskIdentifier);
DefineStringKey(EligibilitySurveyTaskIdentifier);
DefineStringKey(LoginTaskIdentifier);
DefineStringKey(RegistrationTaskIdentifier);
DefineStringKey(VerificationTaskIdentifier);

DefineStringKey(CompletionStepTaskIdentifier);
DefineStringKey(DatePickingTaskIdentifier);
DefineStringKey(ImageCaptureTaskIdentifier);
DefineStringKey(VideoCaptureTaskIdentifier);
DefineStringKey(ImageChoicesTaskIdentifier);
DefineStringKey(InstantiateCustomVCTaskIdentifier);
DefineStringKey(LocationTaskIdentifier);
DefineStringKey(ScalesTaskIdentifier);
DefineStringKey(ColorScalesTaskIdentifier);
DefineStringKey(MiniFormTaskIdentifier);
DefineStringKey(OptionalFormTaskIdentifier);
DefineStringKey(SelectionSurveyTaskIdentifier);
DefineStringKey(PredicateTestsTaskIdentifier);

DefineStringKey(ActiveStepTaskIdentifier);
DefineStringKey(AudioTaskIdentifier);
DefineStringKey(AuxillaryImageTaskIdentifier);
DefineStringKey(FitnessTaskIdentifier);
DefineStringKey(FootnoteTaskIdentifier);
DefineStringKey(GaitTaskIdentifier);
DefineStringKey(IconImageTaskIdentifier);
DefineStringKey(HolePegTestTaskIdentifier);
DefineStringKey(MemoryTaskIdentifier);
DefineStringKey(PSATTaskIdentifier);
DefineStringKey(ReactionTimeTaskIdentifier);
DefineStringKey(StroopTaskIdentifier);
DefineStringKey(TrailMakingTaskIdentifier);
DefineStringKey(TwoFingerTapTaskIdentifier);
DefineStringKey(TimedWalkTaskIdentifier);
DefineStringKey(ToneAudiometryTaskIdentifier);
DefineStringKey(TowerOfHanoiTaskIdentifier);
DefineStringKey(TremorTaskIdentifier);
DefineStringKey(TremorRightHandTaskIdentifier);
DefineStringKey(WalkBackAndForthTaskIdentifier);

DefineStringKey(CreatePasscodeTaskIdentifier);

DefineStringKey(CustomNavigationItemTaskIdentifier);
DefineStringKey(DynamicTaskIdentifier);
DefineStringKey(InterruptibleTaskIdentifier);
DefineStringKey(NavigableOrderedTaskIdentifier);
DefineStringKey(NavigableLoopTaskIdentifier);
DefineStringKey(WaitTaskIdentifier);

DefineStringKey(CollectionViewHeaderReuseIdentifier);
DefineStringKey(CollectionViewCellReuseIdentifier);

DefineStringKey(EmbeddedReviewTaskIdentifier);
DefineStringKey(StandaloneReviewTaskIdentifier);
DefineStringKey(ConfirmationFormTaskIdentifier);

DefineStringKey(StepWillDisappearTaskIdentifier);
DefineStringKey(StepWillDisappearFirstStepIdentifier);

DefineStringKey(TableStepTaskIdentifier);
DefineStringKey(SignatureStepTaskIdentifier);
DefineStringKey(VideoInstructionStepTaskIdentifier);
DefineStringKey(PageStepTaskIdentifier);

@interface SectionHeader: UICollectionReusableView

- (void)configureHeaderWithTitle:(NSString *)title;

@end


@implementation SectionHeader {
    UILabel *_title;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self sharedInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self sharedInit];
    }
    return self;
}

static UIColor *HeaderColor() {
    return [UIColor colorWithWhite:0.97 alpha:1.0];
}
static const CGFloat HeaderSideLayoutMargin = 16.0;

- (void)sharedInit {
    self.layoutMargins = UIEdgeInsetsMake(0, HeaderSideLayoutMargin, 0, HeaderSideLayoutMargin);
    self.backgroundColor = HeaderColor();
    _title = [UILabel new];
    _title.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold]; // Table view header font
    [self addSubview:_title];
    
    _title.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = @{@"title": _title};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[title]-|"
                                                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                                                 metrics:nil
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[title]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:views]];
}

- (void)configureHeaderWithTitle:(NSString *)title {
    _title.text = title;
}

@end


@interface ButtonCell: UICollectionViewCell

- (void)configureButtonWithTitle:(NSString *)title target:(id)target selector:(SEL)selector;

@end


@implementation ButtonCell {
    UIButton *_button;
}

- (void)setUpButton {
    [_button removeFromSuperview];
    _button = [UIButton buttonWithType:UIButtonTypeSystem];
    _button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    _button.contentEdgeInsets = UIEdgeInsetsMake(0.0, HeaderSideLayoutMargin, 0.0, 0.0);
    [self.contentView addSubview:_button];
    
    _button.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = @{@"button": _button};
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[button]|"
                                                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                                                             metrics:nil
                                                                               views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[button]|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:views]];
}

- (void)configureButtonWithTitle:(NSString *)title target:(id)target selector:(SEL)selector {
    [self setUpButton];
    [_button setTitle:title forState:UIControlStateNormal];
    [_button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
}

@end


/**
 A subclass is required for the login step.
 
 The implementation below demonstrates how to subclass and override button actions.
 */
@interface LoginViewController : ORKLegacyLoginStepViewController

@end

@implementation LoginViewController

- (void)forgotPasswordButtonTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Forgot password?"
                                                                   message:@"Button tapped"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end


/**
 A subclass is required for the verification step.
 
 The implementation below demonstrates how to subclass and override button actions.
 */
@interface VerificationViewController : ORKLegacyVerificationStepViewController

@end

@implementation VerificationViewController

- (void)resendEmailButtonTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Resend Verification Email"
                                                                   message:@"Button tapped"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end


@interface MainViewController () <ORKLegacyTaskViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, ORKLegacyPasscodeDelegate> {
    id<ORKLegacyTaskResultSource> _lastRouteResult;
    ORKLegacyConsentDocument *_currentDocument;
    
    NSMutableDictionary<NSString *, NSData *> *_savedViewControllers;     // Maps task identifiers to task view controller restoration data
    
    UICollectionView *_collectionView;
    NSArray<NSString *> *_buttonSectionNames;
    NSArray<NSArray<NSString *> *> *_buttonTitles;
    
    ORKLegacyTaskResult *_embeddedReviewTaskResult;
}

@property (nonatomic, strong) ORKLegacyTaskViewController *taskViewController;

@end


@implementation MainViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.restorationIdentifier = @"main";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _savedViewControllers = [NSMutableDictionary new];
    
    UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flowLayout];
    _collectionView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_collectionView];
    
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[SectionHeader class]
        forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
               withReuseIdentifier:CollectionViewHeaderReuseIdentifier];
    [_collectionView registerClass:[ButtonCell class]
        forCellWithReuseIdentifier:CollectionViewCellReuseIdentifier];
    
    UIView *statusBarBackground = [UIView new];
    statusBarBackground.backgroundColor = HeaderColor();
    [self.view addSubview:statusBarBackground];

    _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    statusBarBackground.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = @{@"collectionView": _collectionView,
                            @"statusBarBackground": statusBarBackground,
                            @"topLayoutGuide": self.topLayoutGuide};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[statusBarBackground]|"
                                                                      options:NSLayoutFormatDirectionLeadingToTrailing
                                                                      metrics:nil
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[statusBarBackground]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:statusBarBackground
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.topLayoutGuide
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0
                                                           constant:0.0]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[collectionView]|"
                                                                      options:NSLayoutFormatDirectionLeadingToTrailing
                                                                      metrics:nil
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topLayoutGuide][collectionView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    
    _buttonSectionNames = @[
                            @"Onboarding",
                            @"Question Steps",
                            @"Active Tasks",
                            @"Passcode",
                            @"Review Step",
                            @"Miscellaneous",
                            ];
    _buttonTitles = @[ @[ // Onboarding
                           @"Consent",
                           @"Consent Review",
                           @"Eligibility Form",
                           @"Eligibility Survey",
                           @"Login",
                           @"Registration",
                           @"Verification",
                           ],
                       @[ // Question Steps
                           @"Date Pickers",
                           @"Image Capture",
                           @"Video Capture",
                           @"Image Choices",
                           @"Location",
                           @"Scale",
                           @"Scale Color Gradient",
                           @"Mini Form",
                           @"Optional Form",
                           @"Selection Survey",
                           ],
                       @[ // Active Tasks
                           @"Active Step Task",
                           @"Audio Task",
                           @"Fitness Task",
                           @"GAIT Task",
                           @"Hole Peg Test Task",
                           @"Memory Game Task",
                           @"PSAT Task",
                           @"Reaction Time Task",
                           @"Stroop Task",
                           @"Trail Making Task",
                           @"Timed Walk Task",
                           @"Tone Audiometry Task",
                           @"Tower Of Hanoi Task",
                           @"Two Finger Tapping Task",
                           @"Walk And Turn Task",
                           @"Hand Tremor Task",
                           @"Right Hand Tremor Task",
                           ],
                       @[ // Passcode
                           @"Authenticate Passcode",
                           @"Create Passcode",
                           @"Edit Passcode",
                           @"Remove Passcode",
                           ],
                       @[ // Review Step
                           @"Embedded Review Task",
                           @"Standalone Review Task",
                           ],
                       @[ // Miscellaneous
                           @"Custom Navigation Item",
                           @"Dynamic Task",
                           @"Interruptible Task",
                           @"Navigable Ordered Task",
                           @"Navigable Loop Task",
                           @"Predicate Tests",
                           @"Test Charts",
                           @"Test Charts Performance",
                           @"Toggle Tint Color",
                           @"Wait Task",
                           @"Step Will Disappear",
                           @"Confirmation Form Item",
                           @"Continue Button",
                           @"Instantiate Custom VC",
                           @"Table Step",
                           @"Signature Step",
                           @"Auxillary Image",
                           @"Video Instruction Step",
                           @"Icon Image",
                           @"Completion Step",
                           @"Page Step",
                           @"Footnote",
                           ],
                       ];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [_collectionView reloadData];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(self.view.bounds.size.width, 22.0);  // Table view header height
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat viewWidth = self.view.bounds.size.width;
    NSUInteger numberOfColums = 2;
    if (viewWidth >= 667.0) {
        numberOfColums = 3;
    }
    CGFloat width = viewWidth / numberOfColums;
    return CGSizeMake(width, 44.0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _buttonSectionNames.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return ((NSArray *)_buttonTitles[section]).count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    SectionHeader *sectionHeader = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:CollectionViewHeaderReuseIdentifier forIndexPath:indexPath];
    [sectionHeader configureHeaderWithTitle:_buttonSectionNames[indexPath.section]];
    return sectionHeader;
}

- (SEL)selectorFromButtonTitle:(NSString *)buttonTitle {
    // "THIS FOO baR title" is converted to the "thisFooBarTitleButtonTapped:" selector
    buttonTitle = buttonTitle.capitalizedString;
    NSMutableArray *titleTokens = [[buttonTitle componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] mutableCopy];
    titleTokens[0] = ((NSString *)titleTokens[0]).lowercaseString;
    NSString *selectorString = [NSString stringWithFormat:@"%@ButtonTapped:", [titleTokens componentsJoinedByString:@""]];
    return NSSelectorFromString(selectorString);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ButtonCell *buttonCell = [collectionView dequeueReusableCellWithReuseIdentifier:CollectionViewCellReuseIdentifier forIndexPath:indexPath];
    NSString *buttonTitle = _buttonTitles[indexPath.section][indexPath.row];
    SEL buttonSelector = [self selectorFromButtonTitle:buttonTitle];
    [buttonCell configureButtonWithTitle:buttonTitle target:self selector:buttonSelector];
    return buttonCell;
}

#pragma mark - Mapping identifiers to tasks

- (id<ORKLegacyTask>)makeTaskWithIdentifier:(NSString *)identifier {
    if ([identifier isEqualToString:DatePickingTaskIdentifier]) {
        return [self makeDatePickingTask];
    } else if ([identifier isEqualToString:SelectionSurveyTaskIdentifier]) {
        return [self makeSelectionSurveyTask];
    } else if ([identifier isEqualToString:ActiveStepTaskIdentifier]) {
        return [self makeActiveStepTask];
    } else if ([identifier isEqualToString:ConsentReviewTaskIdentifier]) {
        return [self makeConsentReviewTask];
    } else if ([identifier isEqualToString:ConsentTaskIdentifier]) {
        return [self makeConsentTask];
    } else if ([identifier isEqualToString:EligibilityFormTaskIdentifier]) {
        return [self makeEligibilityFormTask];
    } else if ([identifier isEqualToString:EligibilitySurveyTaskIdentifier]) {
        return [self makeEligibilitySurveyTask];
    } else if ([identifier isEqualToString:LoginTaskIdentifier]) {
        return [self makeLoginTask];
    } else if ([identifier isEqualToString:RegistrationTaskIdentifier]) {
        return [self makeRegistrationTask];
    } else if ([identifier isEqualToString:VerificationTaskIdentifier]) {
        return [self makeVerificationTask];
    } else if ([identifier isEqualToString:AudioTaskIdentifier]) {
        id<ORKLegacyTask> task = [ORKLegacyOrderedTask audioTaskWithIdentifier:AudioTaskIdentifier
                                            intendedUseDescription:nil
                                                 speechInstruction:nil
                                            shortSpeechInstruction:nil
                                                          duration:10
                                                 recordingSettings:nil
                                                   checkAudioLevel:YES
                                                           options:(ORKLegacyPredefinedTaskOption)0];
        return task;
    } else if ([identifier isEqualToString:ToneAudiometryTaskIdentifier]) {
        id<ORKLegacyTask> task = [ORKLegacyOrderedTask toneAudiometryTaskWithIdentifier:ToneAudiometryTaskIdentifier
                                                     intendedUseDescription:nil
                                                          speechInstruction:nil
                                                     shortSpeechInstruction:nil
                                                               toneDuration:20
                                                                    options:(ORKLegacyPredefinedTaskOption)0];
        return task;
    } else if ([identifier isEqualToString:MiniFormTaskIdentifier]) {
        return [self makeMiniFormTask];
    } else if ([identifier isEqualToString:OptionalFormTaskIdentifier]) {
        return [self makeOptionalFormTask];
    } else if ([identifier isEqualToString:PredicateTestsTaskIdentifier]) {
        return [self makePredicateTestsTask];
    } else if ([identifier isEqualToString:FitnessTaskIdentifier]) {
        return [ORKLegacyOrderedTask fitnessCheckTaskWithIdentifier:FitnessTaskIdentifier
                                       intendedUseDescription:nil
                                                 walkDuration:360
                                                 restDuration:180
                                                      options:ORKLegacyPredefinedTaskOptionNone];
    } else if ([identifier isEqualToString:GaitTaskIdentifier]) {
        return [ORKLegacyOrderedTask shortWalkTaskWithIdentifier:GaitTaskIdentifier
                                    intendedUseDescription:nil
                                       numberOfStepsPerLeg:20
                                              restDuration:30
                                                   options:ORKLegacyPredefinedTaskOptionNone];
    } else if ([identifier isEqualToString:MemoryTaskIdentifier]) {
        return [ORKLegacyOrderedTask spatialSpanMemoryTaskWithIdentifier:MemoryTaskIdentifier
                                            intendedUseDescription:nil
                                                       initialSpan:3
                                                       minimumSpan:2
                                                       maximumSpan:15
                                                         playSpeed:1
                                                      maximumTests:5
                                        maximumConsecutiveFailures:3
                                                 customTargetImage:nil
                                            customTargetPluralName:nil
                                                   requireReversal:NO
                                                           options:ORKLegacyPredefinedTaskOptionNone];
    } else if ([identifier isEqualToString:DynamicTaskIdentifier]) {
        return [DynamicTask new];
    } else if ([identifier isEqualToString:InterruptibleTaskIdentifier]) {
        return [self makeInterruptibleTask];
    } else if ([identifier isEqualToString:ScalesTaskIdentifier]) {
        return [self makeScalesTask];
    } else if ([identifier isEqualToString:ColorScalesTaskIdentifier]) {
        return [self makeColorScalesTask];
    } else if ([identifier isEqualToString:ImageChoicesTaskIdentifier]) {
        return [self makeImageChoicesTask];
    } else if ([identifier isEqualToString:ImageCaptureTaskIdentifier]) {
        return [self makeImageCaptureTask];
    } else if ([identifier isEqualToString:VideoCaptureTaskIdentifier]) {
        return [self makeVideoCaptureTask];
    } else if ([identifier isEqualToString:TwoFingerTapTaskIdentifier]) {
        return [ORKLegacyOrderedTask twoFingerTappingIntervalTaskWithIdentifier:TwoFingerTapTaskIdentifier
                                                   intendedUseDescription:nil
                                                                 duration:20.0
                                                              handOptions:ORKLegacyPredefinedTaskHandOptionBoth
                                                                  options:(ORKLegacyPredefinedTaskOption)0];
    } else if ([identifier isEqualToString:ReactionTimeTaskIdentifier]) {
        return [ORKLegacyOrderedTask reactionTimeTaskWithIdentifier:ReactionTimeTaskIdentifier
                                       intendedUseDescription:nil
                                      maximumStimulusInterval:8
                                      minimumStimulusInterval:4
                                        thresholdAcceleration:0.5
                                             numberOfAttempts:3
                                                      timeout:10
                                                 successSound:0
                                                 timeoutSound:0
                                                 failureSound:0
                                                      options:0];
    } else if ([identifier isEqualToString:StroopTaskIdentifier]) {
        return [ORKLegacyOrderedTask stroopTaskWithIdentifier:StroopTaskIdentifier
                                 intendedUseDescription:nil
                                       numberOfAttempts:15
                                                options:0];
    } else if ([identifier isEqualToString:TowerOfHanoiTaskIdentifier]) {
        return [ORKLegacyOrderedTask towerOfHanoiTaskWithIdentifier:TowerOfHanoiTaskIdentifier
                                       intendedUseDescription:nil
                                                numberOfDisks:5
                                                      options:0];
    } else if ([identifier isEqualToString:PSATTaskIdentifier]) {
        return [ORKLegacyOrderedTask PSATTaskWithIdentifier:PSATTaskIdentifier
                               intendedUseDescription:nil
                                     presentationMode:(ORKLegacyPSATPresentationModeAuditory | ORKLegacyPSATPresentationModeVisual)
                                interStimulusInterval:3.0
                                     stimulusDuration:1.0
                                         seriesLength:60
                                              options:ORKLegacyPredefinedTaskOptionNone];
    } else if ([identifier isEqualToString:TimedWalkTaskIdentifier]) {
        return [ORKLegacyOrderedTask timedWalkTaskWithIdentifier:TimedWalkTaskIdentifier
                                    intendedUseDescription:nil
                                          distanceInMeters:100
                                                 timeLimit:180
                                       turnAroundTimeLimit:60
                                includeAssistiveDeviceForm:YES
                                                   options:ORKLegacyPredefinedTaskOptionNone];
    } else if ([identifier isEqualToString:HolePegTestTaskIdentifier]) {
        return [ORKLegacyNavigableOrderedTask holePegTestTaskWithIdentifier:HolePegTestTaskIdentifier
                                               intendedUseDescription:nil
                                                         dominantHand:ORKLegacyBodySagittalRight
                                                         numberOfPegs:9
                                                            threshold:0.2
                                                              rotated:NO
                                                            timeLimit:300.0
                                                              options:ORKLegacyPredefinedTaskOptionNone];
    } else if ([identifier isEqualToString:NavigableOrderedTaskIdentifier]) {
        return [TaskFactory makeNavigableOrderedTask:NavigableOrderedTaskIdentifier];
    } else if ([identifier isEqualToString:NavigableLoopTaskIdentifier]) {
        return [self makeNavigableLoopTask];
    } else if ([identifier isEqualToString:CustomNavigationItemTaskIdentifier]) {
        return [self makeCustomNavigationItemTask];
    } else if ([identifier isEqualToString:CreatePasscodeTaskIdentifier]) {
        return [self makeCreatePasscodeTask];
    } else if ([identifier isEqualToString:EmbeddedReviewTaskIdentifier]) {
        return [self makeEmbeddedReviewTask];
    } else if ([identifier isEqualToString:StandaloneReviewTaskIdentifier]) {
        return [self makeStandaloneReviewTask];
    } else if ([identifier isEqualToString:WaitTaskIdentifier]) {
        return [self makeWaitingTask];
    } else if ([identifier isEqualToString:LocationTaskIdentifier]) {
        return [self makeLocationTask];
    } else if ([identifier isEqualToString:StepWillDisappearTaskIdentifier]) {
        return [self makeStepWillDisappearTask];
    } else if ([identifier isEqualToString:ConfirmationFormTaskIdentifier]) {
        return [self makeConfirmationFormTask];
    } else if ([identifier isEqualToString:InstantiateCustomVCTaskIdentifier]) {
        return [self makeInstantiateCustomVCTask];
    } else if ([identifier isEqualToString:WalkBackAndForthTaskIdentifier]) {
        return [ORKLegacyOrderedTask walkBackAndForthTaskWithIdentifier:WalkBackAndForthTaskIdentifier
                                           intendedUseDescription:nil
                                                     walkDuration:30
                                                     restDuration:30
                                                          options:ORKLegacyPredefinedTaskOptionNone];
    } else if ([identifier isEqualToString:TableStepTaskIdentifier]) {
        return [self makeTableStepTask];
    } else if ([identifier isEqualToString:SignatureStepTaskIdentifier]) {
        return [self makeSignatureStepTask];
    } else if ([identifier isEqualToString:TremorTaskIdentifier]) {
        return [ORKLegacyOrderedTask tremorTestTaskWithIdentifier:TremorTaskIdentifier
                                     intendedUseDescription:nil
                                         activeStepDuration:10
                                          activeTaskOptions:
                ORKLegacyTremorActiveTaskOptionExcludeHandAtShoulderHeight |
                ORKLegacyTremorActiveTaskOptionExcludeHandAtShoulderHeightElbowBent |
                ORKLegacyTremorActiveTaskOptionExcludeHandToNose
                                                handOptions:ORKLegacyPredefinedTaskHandOptionBoth
                                                    options:ORKLegacyPredefinedTaskOptionNone];
    } else if ([identifier isEqualToString:TremorRightHandTaskIdentifier]) {
        return [ORKLegacyOrderedTask tremorTestTaskWithIdentifier:TremorRightHandTaskIdentifier
                                     intendedUseDescription:nil
                                         activeStepDuration:10
                                          activeTaskOptions:0
                                                handOptions:ORKLegacyPredefinedTaskHandOptionRight
                                                    options:ORKLegacyPredefinedTaskOptionNone];
    } else if ([identifier isEqualToString:AuxillaryImageTaskIdentifier]) {
        return [self makeAuxillaryImageTask];
    } else if ([identifier isEqualToString:IconImageTaskIdentifier]) {
        return [self makeIconImageTask];
    } else if ([identifier isEqualToString:TrailMakingTaskIdentifier]) {
        return [ORKLegacyOrderedTask trailmakingTaskWithIdentifier:TrailMakingTaskIdentifier
                                      intendedUseDescription:nil
                                      trailmakingInstruction:nil
                                                   trailType:ORKLegacyTrailMakingTypeIdentifierA
                                                     options:ORKLegacyPredefinedTaskOptionNone];
    } else if ([identifier isEqualToString:PageStepTaskIdentifier]) {
        return [self makePageStepTask];
    } else if ([identifier isEqualToString:FootnoteTaskIdentifier]) {
        return [self makeFootnoteTask];
    }
    else if ([identifier isEqualToString:VideoInstructionStepTaskIdentifier]) {
        return [self makeVideoInstructionStepTask];
    }
    
    return nil;
}

/*
 Creates a task and presents it with a task view controller.
 */
- (void)beginTaskWithIdentifier:(NSString *)identifier {
    /*
     This is our implementation of restoration after saving during a task.
     If the user saved their work on a previous run of a task with the same
     identifier, we attempt to restore the view controller here.
     
     Since unarchiving can throw an exception, in a real application we would
     need to attempt to catch that exception here.
     */

    id<ORKLegacyTask> task = [self makeTaskWithIdentifier:identifier];
    NSParameterAssert(task);
    
    if (_savedViewControllers[identifier]) {
        NSData *data = _savedViewControllers[identifier];
        self.taskViewController = [[ORKLegacyTaskViewController alloc] initWithTask:task restorationData:data delegate:self];
    } else {
        // No saved data, just create the task and the corresponding task view controller.
        self.taskViewController = [[ORKLegacyTaskViewController alloc] initWithTask:task taskRunUUID:[NSUUID UUID]];
    }
    
    // If we have stored data then data will contain the stored data.
    // If we don't, data will be nil (and the task will be opened up as a 'new' task.
    NSData *data = _savedViewControllers[identifier];
    self.taskViewController = [[ORKLegacyTaskViewController alloc] initWithTask:task restorationData:data delegate:self];
    
    [self beginTask];
}

/*
 Actually presents the task view controller.
 */
- (void)beginTask {
    id<ORKLegacyTask> task = self.taskViewController.task;
    self.taskViewController.delegate = self;
    
    if (_taskViewController.outputDirectory == nil) {
        // Sets an output directory in Documents, using the `taskRunUUID` in the path.
        NSURL *documents =  [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        NSURL *outputDir = [documents URLByAppendingPathComponent:self.taskViewController.taskRunUUID.UUIDString];
        [[NSFileManager defaultManager] createDirectoryAtURL:outputDir withIntermediateDirectories:YES attributes:nil error:nil];
        self.taskViewController.outputDirectory = outputDir;
    }
    
    /*
     For the dynamic task, we remember the last result and use it as a source
     of default values for any optional questions.
     */
    if ([task isKindOfClass:[DynamicTask class]]) {
        self.taskViewController.defaultResultSource = _lastRouteResult;
    }
    
    /*
     We set a restoration identifier so that UI state restoration is enabled
     for the task view controller. We don't need to do anything else to prepare
     for state restoration of a ResearchKit framework task VC.
     */
    _taskViewController.restorationIdentifier = [task identifier];
    
    if ([[task identifier] isEqualToString:CustomNavigationItemTaskIdentifier]) {
        _taskViewController.showsProgressInNavigationBar = NO;
    }
    
    [self presentViewController:_taskViewController animated:YES completion:nil];
}

#pragma mark - Date picking

/*
 This task presents several questions which exercise functionality based on
 `UIDatePicker`.
 */
- (ORKLegacyOrderedTask *)makeDatePickingTask {
    NSMutableArray *steps = [NSMutableArray new];
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"iid_001"];
        step.title = @"Date Survey";
        step.detailText = @"date pickers";
        [steps addObject:step];
    }

    /*
     A time interval question with no default set.
     */
    {
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_timeInterval_001"
                                                                      title:@"How long did it take to fall asleep last night?"
                                                                     answer:[ORKLegacyAnswerFormat timeIntervalAnswerFormat]];
        [steps addObject:step];
    }
    
    
    /*
     A time interval question specifying a default and a step size.
     */
    {
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_timeInterval_default_002"
                                                                      title:@"How long did it take to fall asleep last night?"
                                                                     answer:[ORKLegacyAnswerFormat timeIntervalAnswerFormatWithDefaultInterval:300 step:5]];
        [steps addObject:step];
    }
    
    /*
     A date answer format question, specifying a specific calendar.
     If no calendar were specified, the user's preferred calendar would be used.
     */
    {
        ORKLegacyDateAnswerFormat *dateAnswer = [ORKLegacyDateAnswerFormat dateAnswerFormatWithDefaultDate:nil minimumDate:nil maximumDate:nil calendar: [NSCalendar calendarWithIdentifier:NSCalendarIdentifierHebrew]];
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_date_001"
                                                                      title:@"When is your birthday?"
                                                                     answer:dateAnswer];
        [steps addObject:step];
    }
    
    /*
     A date question with a minimum, maximum, and default.
     Also specifically requires the Gregorian calendar.
     */
    {
        NSDate *defaultDate = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay value:10 toDate:[NSDate date] options:(NSCalendarOptions)0];
        NSDate *minDate = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay value:8 toDate:[NSDate date] options:(NSCalendarOptions)0];
        NSDate *maxDate = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay value:12 toDate:[NSDate date] options:(NSCalendarOptions)0];
        ORKLegacyDateAnswerFormat *dateAnswer = [ORKLegacyDateAnswerFormat dateAnswerFormatWithDefaultDate:defaultDate
                                                                                   minimumDate:minDate
                                                                                   maximumDate:maxDate
                                                                                      calendar: [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian]];
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_date_default_002"
                                                                      title:@"What day are you available?"
                                                                     answer:dateAnswer];
        [steps addObject:step];
    }
    
    /*
     A time of day question with no default.
     */
    {
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_timeOfDay_001"
                                                                 title:@"What time do you get up?"
                                                                   answer:[ORKLegacyTimeOfDayAnswerFormat timeOfDayAnswerFormat]];
        [steps addObject:step];
    }
    
    /*
     A time of day question with a default of 8:15 AM.
     */
    {
        
        NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
        dateComponents.hour = 8;
        dateComponents.minute = 15;
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_timeOfDay_default_001"
                                                                      title:@"What time do you get up?"
                                                                     answer:[ORKLegacyTimeOfDayAnswerFormat timeOfDayAnswerFormatWithDefaultComponents:dateComponents]];
        [steps addObject:step];
    }
    
    /*
     A date-time question with default parameters (no min, no max, default to now).
     */
    {
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_dateTime_001"
                                                                      title:@"When is your next meeting?"
                                                                     answer:[ORKLegacyDateAnswerFormat dateTimeAnswerFormat]];
        [steps addObject:step];
    }
    
    /*
     A date-time question with specified min, max, default date, and calendar.
     */
    {
        NSDate *defaultDate = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay value:10 toDate:[NSDate date] options:(NSCalendarOptions)0];
        NSDate *minDate = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay value:8 toDate:[NSDate date] options:(NSCalendarOptions)0];
        NSDate *maxDate = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay value:12 toDate:[NSDate date] options:(NSCalendarOptions)0];
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_dateTime_default_002"
                                                                      title:@"When is your next meeting?"
                                                                     answer:[ORKLegacyDateAnswerFormat dateTimeAnswerFormatWithDefaultDate:defaultDate minimumDate:minDate  maximumDate:maxDate calendar:[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian]]];
        [steps addObject:step];
        
    }
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:DatePickingTaskIdentifier steps:steps];
    return task;
}

- (void)datePickersButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:DatePickingTaskIdentifier];
}

#pragma mark - Selection survey

/*
 The selection survey task is just a collection of various styles of survey questions.
 */
- (ORKLegacyOrderedTask *)makeSelectionSurveyTask {
    NSMutableArray *steps = [NSMutableArray new];
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"iid_001"];
        step.title = @"Selection Survey";
        [steps addObject:step];
    }
    
    {
        /*
         A numeric question requiring integer answers in a fixed range, with no default.
         */
        ORKLegacyNumericAnswerFormat *format = [ORKLegacyNumericAnswerFormat integerAnswerFormatWithUnit:@"years"];
        format.minimum = @(0);
        format.maximum = @(199);
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_001"
                                                                      title:@"How old are you?"
                                                                     answer:format];
        [steps addObject:step];
    }
    
    {
        /*
         A boolean question.
         */
        ORKLegacyBooleanAnswerFormat *format = [ORKLegacyBooleanAnswerFormat new];
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_001b"
                                                                      title:@"Do you consent to a background check?"
                                                                     answer:format];
        [steps addObject:step];
    }
    
    {
        /*
         A custom boolean question.
         */
        ORKLegacyBooleanAnswerFormat *format = [ORKLegacyAnswerFormat booleanAnswerFormatWithYesString:@"Agree" noString:@"Disagree"];
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_001c"
                                                                      title:@"Do you agree to proceed to the background check questions?"
                                                                     answer:format];
        [steps addObject:step];
    }
    
    {
        /*
         A single-choice question presented in the tableview format.
         */
        ORKLegacyTextChoiceAnswerFormat *answerFormat = [ORKLegacyAnswerFormat choiceAnswerFormatWithStyle:ORKLegacyChoiceAnswerStyleSingleChoice textChoices:
                                                   @[
                                                     [ORKLegacyTextChoice choiceWithText:@"Less than seven"
                                                                             value:@(7)],
                                                     [ORKLegacyTextChoice choiceWithText:@"Between seven and eight"
                                                                             value:@(8)],
                                                     [ORKLegacyTextChoice choiceWithText:@"More than eight"
                                                                             value:@(9)]
                                                     ]];
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_003"
                                                                      title:@"How many hours did you sleep last night?"
                                                                     answer:answerFormat];
        
        step.optional = NO;
        [steps addObject:step];
    }
    
    {
        /*
         A multiple-choice question presented in the tableview format.
         */
        ORKLegacyTextChoiceAnswerFormat *answerFormat = [ORKLegacyAnswerFormat choiceAnswerFormatWithStyle:ORKLegacyChoiceAnswerStyleMultipleChoice textChoices:
                                                   @[
                                                     [ORKLegacyTextChoice choiceWithText:@"Cough"
                                                                             value:@"cough"],
                                                     [ORKLegacyTextChoice choiceWithText:@"Fever"
                                                                             value:@"fever"],
                                                     [ORKLegacyTextChoice choiceWithText:@"Headaches"
                                                                             value:@"headache"],
                                                     [ORKLegacyTextChoice choiceWithText:@"None of the above"
                                                                        detailText:nil
                                                                             value:@"none"
                                                                          exclusive:YES]
                                                     ]];
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_004a"
                                                                      title:@"Which symptoms do you have?"
                                                                     answer:answerFormat];
        [steps addObject:step];
    }
    
    {
        /*
         A multiple-choice question with text choices that have detail text.
         */
        ORKLegacyTextChoiceAnswerFormat *answerFormat = [ORKLegacyAnswerFormat choiceAnswerFormatWithStyle:ORKLegacyChoiceAnswerStyleMultipleChoice textChoices:
            @[
              [ORKLegacyTextChoice choiceWithText:@"Cough"
                                 detailText:@"A cough and/or sore throat"
                                      value:@"cough"
                                  exclusive:NO],
              [ORKLegacyTextChoice choiceWithText:@"Fever"
                                 detailText:@"A 100F or higher fever or feeling feverish"
                                      value:@"fever"
                                  exclusive:NO],
              [ORKLegacyTextChoice choiceWithText:@"Headaches"
                                 detailText:@"Headaches and/or body aches"
                                      value:@"headache"
                                  exclusive:NO]
              ]];
        
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_004"
                                                                      title:@"Which symptoms do you have?"
                                                                     answer:answerFormat];
        
        [steps addObject:step];
    }
    
    {
        /*
         A text question with the default multiple-line text entry.
         */
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_005"
                                                                      title:@"How did you feel last night?"
                                                                     answer:[ORKLegacyAnswerFormat textAnswerFormat]];
        [steps addObject:step];
    }
    
    {
        /*
         A text question with single-line text entry, with autocapitalization on
         for words, and autocorrection, and spellchecking turned off.
         */
        ORKLegacyTextAnswerFormat *format = [ORKLegacyAnswerFormat textAnswerFormat];
        format.multipleLines = NO;
        format.autocapitalizationType = UITextAutocapitalizationTypeWords;
        format.autocorrectionType = UITextAutocorrectionTypeNo;
        format.spellCheckingType = UITextSpellCheckingTypeNo;
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_005a"
                                                                      title:@"What is your name?"
                                                                     answer:format];
        [steps addObject:step];
    }
    
    {
        /*
         A text question with a length limit.
         */
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_005b"
                                                                      title:@"How did you feel last night?"
                                                                     answer:[ORKLegacyTextAnswerFormat textAnswerFormatWithMaximumLength:20]];
        [steps addObject:step];
    }

    {
        /*
         An email question with single-line text entry.
         */
        ORKLegacyEmailAnswerFormat *format = [ORKLegacyAnswerFormat emailAnswerFormat];
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_005c"
                                                                      title:@"What is your email?"
                                                                     answer:format];
        [steps addObject:step];
    }
    
    {
        /*
         A text question demos secureTextEntry feature
         */
        ORKLegacyTextAnswerFormat *format = [ORKLegacyAnswerFormat textAnswerFormatWithMaximumLength:10];
        format.secureTextEntry = YES;
        format.multipleLines = NO;
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_005d"
                                                                      title:@"What is your passcode?"
                                                                     answer:format];
        step.placeholder = @"Tap your passcode here";
        [steps addObject:step];
    }
    
    {
        /*
         A text question with single-line text entry and a length limit.
         */
        ORKLegacyTextAnswerFormat *format = [ORKLegacyAnswerFormat textAnswerFormatWithMaximumLength:20];
        format.multipleLines = NO;
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_005e"
                                                                      title:@"What is your name?"
                                                                     answer:format];
        [steps addObject:step];
    }
    
    {
        /*
         A single-select value-picker question. Rather than seeing the items in a tableview,
         the user sees them in a picker wheel. This is suitable where the list
         of items can be long, and the text describing the options can be kept short.
         */
        ORKLegacyValuePickerAnswerFormat *answerFormat = [ORKLegacyAnswerFormat valuePickerAnswerFormatWithTextChoices:
                                                    @[
                                                      [ORKLegacyTextChoice choiceWithText:@"Cough"
                                                                              value:@"cough"],
                                                      [ORKLegacyTextChoice choiceWithText:@"Fever"
                                                                              value:@"fever"],
                                                      [ORKLegacyTextChoice choiceWithText:@"Headaches"
                                                                              value:@"headache"]
                                                      ]];
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_081"
                                                                      title:@"Select a symptom"
                                                                     answer:answerFormat];
        
        [steps addObject:step];
    }
    
    {
        /*
         A multiple component value-picker question. 
         */
        ORKLegacyValuePickerAnswerFormat *colorFormat = [ORKLegacyAnswerFormat valuePickerAnswerFormatWithTextChoices:
                                                    @[
                                                      [ORKLegacyTextChoice choiceWithText:@"Red"
                                                                              value:@"red"],
                                                      [ORKLegacyTextChoice choiceWithText:@"Blue"
                                                                              value:@"blue"],
                                                      [ORKLegacyTextChoice choiceWithText:@"Green"
                                                                              value:@"green"]
                                                      ]];
        
        ORKLegacyValuePickerAnswerFormat *animalFormat = [ORKLegacyAnswerFormat valuePickerAnswerFormatWithTextChoices:
                                                   @[
                                                     [ORKLegacyTextChoice choiceWithText:@"Cat"
                                                                             value:@"cat"],
                                                     [ORKLegacyTextChoice choiceWithText:@"Dog"
                                                                             value:@"dog"],
                                                     [ORKLegacyTextChoice choiceWithText:@"Turtle"
                                                                             value:@"turtle"]
                                                     ]];
        
        ORKLegacyMultipleValuePickerAnswerFormat *answerFormat = [ORKLegacyAnswerFormat multipleValuePickerAnswerFormatWithValuePickers:
                                                            @[colorFormat, animalFormat]];
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_multipick"
                                                                      title:@"Select a pet:"
                                                                     answer:answerFormat];
        
        [steps addObject:step];
    }
    
    
    {
        /*
         A multiple component value-picker question.
         */
        ORKLegacyValuePickerAnswerFormat *f1 = [ORKLegacyAnswerFormat valuePickerAnswerFormatWithTextChoices:
                                                   @[
                                                     [ORKLegacyTextChoice choiceWithText:@"A"
                                                                             value:@"A"],
                                                     [ORKLegacyTextChoice choiceWithText:@"B"
                                                                             value:@"B"],
                                                     [ORKLegacyTextChoice choiceWithText:@"C"
                                                                             value:@"C"]
                                                     ]];
        
        ORKLegacyValuePickerAnswerFormat *f2 = [ORKLegacyAnswerFormat valuePickerAnswerFormatWithTextChoices:
                                                    @[
                                                      [ORKLegacyTextChoice choiceWithText:@"0"
                                                                              value:@0],
                                                      [ORKLegacyTextChoice choiceWithText:@"1"
                                                                              value:@1],
                                                      [ORKLegacyTextChoice choiceWithText:@"2"
                                                                              value:@2]
                                                      ]];
        
        ORKLegacyMultipleValuePickerAnswerFormat *answerFormat = [[ORKLegacyMultipleValuePickerAnswerFormat alloc] initWithValuePickers:@[f1, f2] separator:@"-"];
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_multipick_dash"
                                                                      title:@"Select a letter and number code:"
                                                                     answer:answerFormat];
        
        [steps addObject:step];
    }
    
    {
        /*
         A continuous slider question.
         */
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_010"
                                                                      title:@"On a scale of 1 to 10, how much pain do you feel?"
                                                                     answer:[[ORKLegacyContinuousScaleAnswerFormat alloc] initWithMaximumValue:10 minimumValue:1 defaultValue:NSIntegerMax maximumFractionDigits:1]];
        [steps addObject:step];
    }
    
    {
        /*
         The same as the previous question, but now using a discrete slider.
         */
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_010a"
                                                                      title:@"On a scale of 1 to 10, how much pain do you feel?"
                                                                     answer:[ORKLegacyAnswerFormat scaleAnswerFormatWithMaximumValue:10
                                                                                                                  minimumValue:1
                                                                                                                  defaultValue:NSIntegerMax
                                                                                                                          step:1
                                                                                                                      vertical:NO
                                                                                                       maximumValueDescription:@"High value"
                                                                                                       minimumValueDescription:@"Low value"]];
        [steps addObject:step];
    }
    
    {
        /*
         A HealthKit answer format question for gender.
         The default value is read from HealthKit when the step is being presented,
         but the user's answer is not written back to HealthKit.
         */
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"fqid_health_biologicalSex"
                                                                      title:@"What is your gender"
                                                                     answer:[ORKLegacyHealthKitCharacteristicTypeAnswerFormat answerFormatWithCharacteristicType:[HKCharacteristicType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex]]];
        [steps addObject:step];
    }
    
    {
        /*
         A HealthKit answer format question for blood type.
         The default value is read from HealthKit when the step is being presented,
         but the user's answer is not written back to HealthKit.
         */
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"fqid_health_bloodType"
                                                                      title:@"What is your blood type?"
                                                                     answer:[ORKLegacyHealthKitCharacteristicTypeAnswerFormat answerFormatWithCharacteristicType:[HKCharacteristicType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBloodType]]];
        [steps addObject:step];
    }
    
    {
        /*
         A HealthKit answer format question for date of birth.
         The default value is read from HealthKit when the step is being presented,
         but the user's answer is not written back to HealthKit.
         */
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"fqid_health_dob"
                                                                      title:@"What is your date of birth?"
                                                                     answer:[ORKLegacyHealthKitCharacteristicTypeAnswerFormat answerFormatWithCharacteristicType:[HKCharacteristicType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth]]];
        [steps addObject:step];
    }
    
    {
        /*
         A HealthKit answer format question for weight.
         The default value is read from HealthKit when the step is being presented,
         but the user's answer is not written back to HealthKit.
         */
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"fqid_health_weight"
                                                                      title:@"How much do you weigh?"
                                                                     answer:[ORKLegacyHealthKitQuantityTypeAnswerFormat answerFormatWithQuantityType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass]
                                                                                                                                          unit:nil
                                                                                                                                         style:ORKLegacyNumericAnswerStyleDecimal]];
        [steps addObject:step];
    }
    
    {
        /*
         A multiple choice question where the items are mis-formatted.
         This question is used for verifying correct layout of the table view
         cells when the content is mixed or very long.
         */
        ORKLegacyTextChoiceAnswerFormat *answerFormat = [ORKLegacyAnswerFormat choiceAnswerFormatWithStyle:ORKLegacyChoiceAnswerStyleMultipleChoice textChoices:
                                                   @[
                                                     [ORKLegacyTextChoice choiceWithText:@"Cough, A cough and/or sore throat, A cough and/or sore throat"
                                                                        detailText:@"A cough and/or sore throat, A cough and/or sore throat, A cough and/or sore throat"
                                                                             value:@"cough"
                                                                         exclusive:NO],
                                                     [ORKLegacyTextChoice choiceWithText:@"Fever, A 100F or higher fever or feeling feverish"
                                                                        detailText:nil
                                                                             value:@"fever"
                                                                         exclusive:NO],
                                                     [ORKLegacyTextChoice choiceWithText:@""
                                                                        detailText:@"Headaches, Headaches and/or body aches"
                                                                             value:@"headache"
                                                                         exclusive:NO]
                                                     ]];
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"qid_000a"
                                                                      title:@"(Misused) Which symptoms do you have?"
                                                                     answer:answerFormat];
        [steps addObject:step];
    }
    
    {
        ORKLegacyCompletionStep *step = [[ORKLegacyCompletionStep alloc] initWithIdentifier:@"completion"];
        step.title = @"Survey Complete";
        [steps addObject:step];
    }

    
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:SelectionSurveyTaskIdentifier steps:steps];
    return task;
}

- (void)selectionSurveyButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:SelectionSurveyTaskIdentifier];
}

#pragma mark - Active step task

/*
 This task demonstrates direct use of active steps, which is not particularly
 well-supported by the framework. The intended use of `ORKLegacyActiveStep` is as a
 base class for creating new types of active step, with matching view
 controllers appropriate to the particular task that uses them.
 
 Nonetheless, this functions as a test-bed for basic active task functonality.
 */
- (ORKLegacyOrderedTask *)makeActiveStepTask {
    NSMutableArray *steps = [NSMutableArray new];
    
    {
        /*
         Example of a fully-fledged instruction step.
         The text of this step is not appropriate to the rest of the task, but
         is helpful for verifying layout.
         */
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"iid_001"];
        step.title = @"Demo Study";
        step.text = @"This 12-step walkthrough will explain the study and the impact it will have on your life.";
        step.detailText = @"You must complete the walkthough to participate in the study.";
        [steps addObject:step];
    }
    
    {
        /*
         Audio-recording active step, configured directly using `ORKLegacyActiveStep`.
         
         Not a recommended way of doing audio recording with the ResearchKit framework.
         */
        ORKLegacyActiveStep *step = [[ORKLegacyActiveStep alloc] initWithIdentifier:@"aid_001d"];
        step.title = @"Audio";
        step.stepDuration = 10.0;
        step.text = @"An active test recording audio";
        step.recorderConfigurations = @[[[ORKLegacyAudioRecorderConfiguration alloc] initWithIdentifier:@"aid_001d.audio" recorderSettings:@{}]];
        step.shouldUseNextAsSkipButton = YES;
        [steps addObject:step];
    }
    
    {
        /*
         Audio-recording active step with lossless audio, configured directly
         using `ORKLegacyActiveStep`.
         
         Not a recommended way of doing audio recording with the ResearchKit framework.
         */
        ORKLegacyActiveStep *step = [[ORKLegacyActiveStep alloc] initWithIdentifier:@"aid_001e"];
        step.title = @"Audio";
        step.stepDuration = 10.0;
        step.text = @"An active test recording lossless audio";
        step.shouldUseNextAsSkipButton = YES;
        step.recorderConfigurations = @[[[ORKLegacyAudioRecorderConfiguration alloc]
                                         initWithIdentifier:@"aid_001e.audio" recorderSettings:@{AVFormatIDKey : @(kAudioFormatAppleLossless),
                                                                                                 AVNumberOfChannelsKey : @(2),
                                                                                                 AVSampleRateKey: @(44100.0)
                                                                                                 }]];
        [steps addObject:step];
    }
    
    {
        /*
         Touch recorder active step. This should record touches on the primary
         view for a 30 second period.
         
         Not a recommended way of collecting touch data with the ResearchKit framework.
         */
        ORKLegacyActiveStep *step = [[ORKLegacyActiveStep alloc] initWithIdentifier:@"aid_001a"];
        step.title = @"Touch";
        step.text = @"An active test, touch collection";
        step.shouldStartTimerAutomatically = NO;
        step.stepDuration = 30.0;
        step.spokenInstruction = @"An active test, touch collection";
        step.shouldUseNextAsSkipButton = YES;
        step.recorderConfigurations = @[[[ORKLegacyTouchRecorderConfiguration alloc] initWithIdentifier:@"aid_001a.touch"]];
        [steps addObject:step];
    }
        
    {
        /*
         Test for device motion recorder directly on an active step.
         
         Not a recommended way of customizing active steps with the ResearchKit framework.
         */
        ORKLegacyActiveStep *step = [[ORKLegacyActiveStep alloc] initWithIdentifier:@"aid_001c"];
        step.title = @"Motion";
        step.text = @"An active test collecting device motion data";
        step.shouldUseNextAsSkipButton = YES;
        step.recorderConfigurations = @[[[ORKLegacyDeviceMotionRecorderConfiguration alloc] initWithIdentifier:@"aid_001c.deviceMotion" frequency:100.0]];
        [steps addObject:step];
    }
    
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:ActiveStepTaskIdentifier steps:steps];
    return task;
}

- (void)activeStepTaskButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:ActiveStepTaskIdentifier];
}

#pragma mark - Consent review task

/*
 The consent review task is used to quickly verify the layout of the consent
 sharing step and the consent review step.
 
 In a real consent process, you would substitute the text of your consent document
 for the various placeholders.
 */
- (ORKLegacyOrderedTask *)makeConsentReviewTask {
    /*
     Tests layout of the consent sharing step.
     
     This step is used when you want to obtain permission to share the data
     collected with other researchers for uses beyond the present study.
     */
    ORKLegacyConsentSharingStep *sharingStep =
    [[ORKLegacyConsentSharingStep alloc] initWithIdentifier:@"consent_sharing"
                         investigatorShortDescription:@"MyInstitution"
                          investigatorLongDescription:@"MyInstitution and its partners"
                        localizedLearnMoreHTMLContent:@"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."];
    
    /*
     Tests layout of the consent review step.
     
     In the consent review step, the user reviews the consent document and
     optionally enters their name and/or scribbles a signature.
     */
    ORKLegacyConsentDocument *doc = [self buildConsentDocument];
    ORKLegacyConsentSignature *participantSig = doc.signatures[0];
    [participantSig setSignatureDateFormatString:@"yyyy-MM-dd 'at' HH:mm"];
    _currentDocument = [doc copy];
    ORKLegacyConsentReviewStep *reviewStep = [[ORKLegacyConsentReviewStep alloc] initWithIdentifier:@"consent_review" signature:participantSig inDocument:doc];
    reviewStep.text = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
    reviewStep.reasonForConsent = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:ConsentReviewTaskIdentifier steps:@[sharingStep,reviewStep]];
    return task;
}

- (void)consentReviewButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:ConsentReviewTaskIdentifier];
}

#pragma mark - Consent task
/*
 This consent task demonstrates visual consent, followed by a consent review step.
 
 In a real consent process, you would substitute the text of your consent document
 for the various placeholders.
 */
- (ORKLegacyOrderedTask *)makeConsentTask {
    /*
     Most of the configuration of what pages will appear in the visual consent step,
     and what content will be displayed in the consent review step, it in the
     consent document itself.
     */
    ORKLegacyConsentDocument *consentDocument = [self buildConsentDocument];
    _currentDocument = [consentDocument copy];
    
    ORKLegacyVisualConsentStep *step = [[ORKLegacyVisualConsentStep alloc] initWithIdentifier:@"visual_consent" document:consentDocument];
    ORKLegacyConsentReviewStep *reviewStep = [[ORKLegacyConsentReviewStep alloc] initWithIdentifier:@"consent_review" signature:consentDocument.signatures[0] inDocument:consentDocument];
    reviewStep.text = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
    reviewStep.reasonForConsent = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";

    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:ConsentTaskIdentifier steps:@[step, reviewStep]];
    
    return task;
}

- (void)consentButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:ConsentTaskIdentifier];
}

#pragma mark - Eligibility form task
/*
 The eligibility form task is used to demonstrate an eligibility form (`ORKLegacyFormStep`, `ORKLegacyFormItem`).
 */
- (id<ORKLegacyTask>)makeEligibilityFormTask {
    NSMutableArray *steps = [NSMutableArray new];
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"intro_step"];
        step.title = @"Eligibility Form";
        [steps addObject:step];
    }
    
    {
        ORKLegacyFormStep *step = [[ORKLegacyFormStep alloc] initWithIdentifier:@"form_step"];
        step.optional = NO;
        step.title = @"Eligibility Form";
        step.text = @"Please answer the questions below.";
        
        NSMutableArray *items = [NSMutableArray new];
        [steps addObject:step];
        
        {
            
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"form_item_1"
                                                                   text:@"Are you over 18 years of age?"
                                                           answerFormat:[ORKLegacyAnswerFormat booleanAnswerFormat]];
            item.optional = NO;
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"form_item_2"
                                                                   text:@"Have you been diagnosed with pre-diabetes or type 2 diabetes?"
                                                           answerFormat:[ORKLegacyAnswerFormat booleanAnswerFormat]];
            item.optional = NO;
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"form_item_3"
                                                                   text:@"Can you not read and understand English in order to provide informed consent and follow the instructions?"
                                                           answerFormat:[ORKLegacyAnswerFormat booleanAnswerFormat]];
            item.optional = NO;
            [items addObject:item];
        }
        
        {
            NSArray *textChoices = @[[ORKLegacyTextChoice choiceWithText:@"Yes" value:@1],
                                     [ORKLegacyTextChoice choiceWithText:@"No" value:@0],
                                     [ORKLegacyTextChoice choiceWithText:@"N/A" value:@2]];
            ORKLegacyTextChoiceAnswerFormat *answerFormat = (ORKLegacyTextChoiceAnswerFormat *)[ORKLegacyAnswerFormat choiceAnswerFormatWithStyle:ORKLegacyChoiceAnswerStyleSingleChoice
                                                                                                                    textChoices:textChoices];
            
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"form_item_4"
                                                                   text:@"Are you pregnant?"
                                                           answerFormat:answerFormat];
            item.optional = NO;
            [items addObject:item];
        }
        
        [step setFormItems:items];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"ineligible_step"];
        step.title = @"You are ineligible to join the study.";
        [steps addObject:step];
    }
    
    {
        ORKLegacyCompletionStep *step = [[ORKLegacyCompletionStep alloc] initWithIdentifier:@"eligible_step"];
        step.title = @"You are eligible to join the study.";
        [steps addObject:step];
    }
    
    ORKLegacyNavigableOrderedTask *task = [[ORKLegacyNavigableOrderedTask alloc] initWithIdentifier:EligibilityFormTaskIdentifier steps:steps];
    
    // Build navigation rules.
    ORKLegacyPredicateStepNavigationRule *predicateRule = nil;
    ORKLegacyResultSelector *resultSelector = nil;
    
    resultSelector = [ORKLegacyResultSelector selectorWithStepIdentifier:@"form_step" resultIdentifier:@"form_item_1"];
    NSPredicate *predicateFormItem1 = [ORKLegacyResultPredicate predicateForBooleanQuestionResultWithResultSelector:resultSelector expectedAnswer:YES];

    resultSelector = [ORKLegacyResultSelector selectorWithStepIdentifier:@"form_step" resultIdentifier:@"form_item_2"];
    NSPredicate *predicateFormItem2 = [ORKLegacyResultPredicate predicateForBooleanQuestionResultWithResultSelector:resultSelector expectedAnswer:YES];
    
    resultSelector = [ORKLegacyResultSelector selectorWithStepIdentifier:@"form_step" resultIdentifier:@"form_item_3"];
    NSPredicate *predicateFormItem3 = [ORKLegacyResultPredicate predicateForBooleanQuestionResultWithResultSelector:resultSelector expectedAnswer:NO];
    
    resultSelector = [ORKLegacyResultSelector selectorWithStepIdentifier:@"form_step" resultIdentifier:@"form_item_4"];
    NSPredicate *predicateFormItem4a = [ORKLegacyResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector expectedAnswerValue:@0];
    NSPredicate *predicateFormItem4b = [ORKLegacyResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector expectedAnswerValue:@2];
    
    NSPredicate *predicateEligible1 = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateFormItem1,predicateFormItem2, predicateFormItem3, predicateFormItem4a]];
    NSPredicate *predicateEligible2 = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateFormItem1,predicateFormItem2, predicateFormItem3, predicateFormItem4b]];
    
    predicateRule = [[ORKLegacyPredicateStepNavigationRule alloc] initWithResultPredicates:@[predicateEligible1, predicateEligible2]
                                                          destinationStepIdentifiers:@[@"eligible_step", @"eligible_step"]];
    [task setNavigationRule:predicateRule forTriggerStepIdentifier:@"form_step"];
    
    // Add end direct rules to skip unneeded steps
    ORKLegacyDirectStepNavigationRule *directRule = nil;
    directRule = [[ORKLegacyDirectStepNavigationRule alloc] initWithDestinationStepIdentifier:ORKLegacyNullStepIdentifier];
    [task setNavigationRule:directRule forTriggerStepIdentifier:@"ineligible_step"];

    return task;
}

- (void)eligibilityFormButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:EligibilityFormTaskIdentifier];
}

#pragma mark - Eligibility survey
/*
 The eligibility survey task is used to demonstrate an eligibility survey.
 */
- (id<ORKLegacyTask>)makeEligibilitySurveyTask {
    NSMutableArray *steps = [NSMutableArray new];
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"intro_step"];
        step.title = @"Eligibility Survey";
        [steps addObject:step];
    }
    
    {
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"question_01"
                                                                      title:@"Are you over 18 years of age?"
                                                                     answer:[ORKLegacyAnswerFormat booleanAnswerFormat]];
        step.optional = NO;
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"ineligible_step"];
        step.title = @"You are ineligible to join the study.";
        [steps addObject:step];
    }
    
    {
        ORKLegacyCompletionStep *step = [[ORKLegacyCompletionStep alloc] initWithIdentifier:@"eligible_step"];
        step.title = @"You are eligible to join the study.";
        [steps addObject:step];
    }
    
    ORKLegacyNavigableOrderedTask *task = [[ORKLegacyNavigableOrderedTask alloc] initWithIdentifier:EligibilitySurveyTaskIdentifier steps:steps];

    // Build navigation rules.
    ORKLegacyResultSelector *resultSelector = [ORKLegacyResultSelector selectorWithResultIdentifier:@"question_01"];
    NSPredicate *predicateQuestion = [ORKLegacyResultPredicate predicateForBooleanQuestionResultWithResultSelector:resultSelector expectedAnswer:YES];

    ORKLegacyPredicateStepNavigationRule *predicateRule = [[ORKLegacyPredicateStepNavigationRule alloc] initWithResultPredicates:@[predicateQuestion]
                                                                                          destinationStepIdentifiers:@[@"eligible_step"]];
    [task setNavigationRule:predicateRule forTriggerStepIdentifier:@"question_01"];
    
    // Add end direct rules to skip unneeded steps
    ORKLegacyDirectStepNavigationRule *directRule = nil;
    directRule = [[ORKLegacyDirectStepNavigationRule alloc] initWithDestinationStepIdentifier:ORKLegacyNullStepIdentifier];
    [task setNavigationRule:directRule forTriggerStepIdentifier:@"ineligible_step"];
    
    return task;
}

- (void)eligibilitySurveyButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:EligibilitySurveyTaskIdentifier];
}

#pragma mark - Login task
/*
 The login task is used to demonstrate a login step.
 */

- (id<ORKLegacyTask>)makeLoginTask {
    NSMutableArray *steps = [NSMutableArray new];
    
    {
        ORKLegacyLoginStep *step = [[ORKLegacyLoginStep alloc] initWithIdentifier:@"login_step"
                                                                title:@"Login"
                                                                 text:@"Enter your credentials"
                                             loginViewControllerClass:[LoginViewController class]];
        [steps addObject:step];
    }
    
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:LoginTaskIdentifier steps:steps];
    return task;
}

- (IBAction)loginButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:LoginTaskIdentifier];
}

#pragma mark - Registration task
/*
 The registration task is used to demonstrate a registration step.
 */
- (id<ORKLegacyTask>)makeRegistrationTask {
    NSMutableArray *steps = [NSMutableArray new];
    
    {
        ORKLegacyRegistrationStepOption options = (ORKLegacyRegistrationStepIncludeFamilyName |
                                             ORKLegacyRegistrationStepIncludeGivenName |
                                             ORKLegacyRegistrationStepIncludeDOB |
                                             ORKLegacyRegistrationStepIncludeGender);
        ORKLegacyRegistrationStep *step = [[ORKLegacyRegistrationStep alloc] initWithIdentifier:@"registration_step"
                                                                              title:@"Registration"
                                                                               text:@"Fill out the form below"
                                                                            options:options];
        [steps addObject:step];
    }
    
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:RegistrationTaskIdentifier steps:steps];
    return task;
}

- (IBAction)registrationButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:RegistrationTaskIdentifier];
}


#pragma mark - Verification task
/*
 The verification task is used to demonstrate a verification step.
 */
- (id<ORKLegacyTask>)makeVerificationTask {
    NSMutableArray *steps = [NSMutableArray new];
    
    {
        ORKLegacyVerificationStep *step = [[ORKLegacyVerificationStep alloc] initWithIdentifier:@"verification_step" text:@"Check your email and click on the link to verify your email address and start using the app."
                                                    verificationViewControllerClass:[VerificationViewController class]];
        [steps addObject:step];
    }
    
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:VerificationTaskIdentifier steps:steps];
    return task;
}

- (IBAction)verificationButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:VerificationTaskIdentifier];
}

#pragma mark - Mini form task

/*
 The mini form task is used to test survey forms functionality (`ORKLegacyFormStep`).
 */
- (id<ORKLegacyTask>)makeMiniFormTask {
    NSMutableArray *steps = [NSMutableArray new];
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"mini_form_001"];
        step.title = @"Mini Form";
        [steps addObject:step];
    }
    
    {
        /*
         A short form for testing behavior when loading multiple HealthKit
         default values on the same form.
         */
        ORKLegacyFormStep *step = [[ORKLegacyFormStep alloc] initWithIdentifier:@"fid_000" title:@"Mini Form" text:@"Mini form groups multi-entry in one page"];
        NSMutableArray *items = [NSMutableArray new];
        [steps addObject:step];
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_health_weight1"
                                                                 text:@"Weight"
                                                         answerFormat:
                                [ORKLegacyHealthKitQuantityTypeAnswerFormat answerFormatWithQuantityType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass]
                                                                                             unit:[HKUnit unitFromMassFormatterUnit:NSMassFormatterUnitPound]
                                                                                            style:ORKLegacyNumericAnswerStyleDecimal]];
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_health_weight2"
                                                                 text:@"Weight"
                                                         answerFormat:
                                [ORKLegacyHealthKitQuantityTypeAnswerFormat answerFormatWithQuantityType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass]
                                                                                             unit:[HKUnit unitFromMassFormatterUnit:NSMassFormatterUnitPound]
                                                                                            style:ORKLegacyNumericAnswerStyleDecimal]];
            item.placeholder = @"Add weight";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_health_weight3"
                                                                   text:@"Weight"
                                                           answerFormat:
                                 [ORKLegacyHealthKitQuantityTypeAnswerFormat answerFormatWithQuantityType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass]
                                                                                               unit:[HKUnit unitFromMassFormatterUnit:NSMassFormatterUnitPound]
                                                                                              style:ORKLegacyNumericAnswerStyleDecimal]];
            item.placeholder = @"Input your body weight here. Really long text.";
            [items addObject:item];
        }
        
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_health_weight4"
                                                                   text:@"Weight"
                                                           answerFormat:[ORKLegacyNumericAnswerFormat decimalAnswerFormatWithUnit:nil]];
            item.placeholder = @"Input your body weight here";
            [items addObject:item];
        }
        
        [step setFormItems:items];
    }
    
    {
        /*
         A long "kitchen-sink" form with all the different types of supported
         answer formats.
         */
        ORKLegacyFormStep *step = [[ORKLegacyFormStep alloc] initWithIdentifier:@"fid_001" title:@"Mini Form" text:@"Mini form groups multi-entry in one page"];
        NSMutableArray *items = [NSMutableArray new];
        
        {
            
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_health_biologicalSex" text:@"Gender" answerFormat:[ORKLegacyHealthKitCharacteristicTypeAnswerFormat answerFormatWithCharacteristicType:[HKCharacteristicType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex]]];
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithSectionTitle:@"Pre1"];
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithSectionTitle:@"Basic Information"];
            [items addObject:item];
        }
        
        {
            
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_health_bloodType" text:@"Blood Type" answerFormat:[ORKLegacyHealthKitCharacteristicTypeAnswerFormat answerFormatWithCharacteristicType:[HKCharacteristicType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBloodType]]];
            item.placeholder = @"Choose a type";
            [items addObject:item];
        }
        
        {
            
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_health_dob" text:@"Date of Birth" answerFormat:[ORKLegacyHealthKitCharacteristicTypeAnswerFormat answerFormatWithCharacteristicType:[HKCharacteristicType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth]]];
            item.placeholder = @"DOB";
            [items addObject:item];
        }
        
        {
            
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_health_weight"
                                                                 text:@"Weight"
                                                         answerFormat:
                                [ORKLegacyHealthKitQuantityTypeAnswerFormat answerFormatWithQuantityType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass]
                                                                                    unit:nil
                                                                                   style:ORKLegacyNumericAnswerStyleDecimal]];
            item.placeholder = @"Add weight";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_001" text:@"Have headache?" answerFormat:[ORKLegacyBooleanAnswerFormat new]];
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_002" text:@"Which fruit do you like most? Please pick one from below."
                                                         answerFormat:[ORKLegacyAnswerFormat choiceAnswerFormatWithStyle:ORKLegacyChoiceAnswerStyleSingleChoice textChoices:@[@"Apple", @"Orange", @"Banana"]
                                                                                                              ]];
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_003" text:@"Message"
                                                         answerFormat:[ORKLegacyAnswerFormat textAnswerFormat]];
            item.placeholder = @"Your message";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_004a" text:@"BP Diastolic"
                                                         answerFormat:[ORKLegacyAnswerFormat integerAnswerFormatWithUnit:@"mm Hg"]];
            item.placeholder = @"Enter value";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_004b" text:@"BP Systolic"
                                                         answerFormat:[ORKLegacyAnswerFormat integerAnswerFormatWithUnit:@"mm Hg"]];
            item.placeholder = @"Enter value";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_005" text:@"Email"
                                                           answerFormat:[ORKLegacyAnswerFormat emailAnswerFormat]];
            item.placeholder = @"Enter Email";
            [items addObject:item];
        }
        
        {
            NSRegularExpression *validationRegularExpression =
            [NSRegularExpression regularExpressionWithPattern:@"^(https?:\\/\\/)?([\\da-z\\.-]+)\\.([a-z\\.]{2,6})([\\/\\w \\.-]*)*\\/?$"
                                                      options:(NSRegularExpressionOptions)0
                                                        error:nil];
            ORKLegacyTextAnswerFormat *format = [ORKLegacyAnswerFormat textAnswerFormatWithValidationRegularExpression:validationRegularExpression
                                                                                            invalidMessage:@"Invalid URL: %@"];
            format.multipleLines = NO;
            format.keyboardType = UIKeyboardTypeURL;
            format.autocapitalizationType = UITextAutocapitalizationTypeNone;
            format.autocorrectionType = UITextAutocorrectionTypeNo;
            format.spellCheckingType = UITextSpellCheckingTypeNo;
            
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_006" text:@"URL"
                                                           answerFormat:format];
            item.placeholder = @"Enter URL";
            [items addObject:item];
        }

        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_007" text:@"Message"
                                                           answerFormat:[ORKLegacyAnswerFormat textAnswerFormatWithMaximumLength:20]];
            item.placeholder = @"Your message (limit 20 characters).";
            [items addObject:item];
        }
        
        {
            ORKLegacyTextAnswerFormat *format = [ORKLegacyAnswerFormat textAnswerFormatWithMaximumLength:12];
            format.secureTextEntry = YES;
            format.multipleLines = NO;
            
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_008" text:@"Passcode"
                                                           answerFormat:format];
            item.placeholder = @"Enter Passcode";
            [items addObject:item];
        }

        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_height_001" text:@"Height"
                                                           answerFormat:[ORKLegacyAnswerFormat heightAnswerFormat]];
            item.placeholder = @"Pick a height (local system)";
            [items addObject:item];
        }

        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_height_002" text:@"Height"
                                                           answerFormat:[ORKLegacyAnswerFormat heightAnswerFormatWithMeasurementSystem:ORKLegacyMeasurementSystemMetric]];
            item.placeholder = @"Pick a height (metric system)";
            [items addObject:item];
        }

        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_height_003" text:@"Height"
                                                           answerFormat:[ORKLegacyAnswerFormat heightAnswerFormatWithMeasurementSystem:ORKLegacyMeasurementSystemUSC]];
            item.placeholder = @"Pick a height (imperial system)";
            [items addObject:item];
        }

        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_weight_001" text:@"Weight"
                                                           answerFormat:[ORKLegacyAnswerFormat weightAnswerFormat]];
            item.placeholder = @"Pick a weight (local system)";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_weight_002" text:@"Weight"
                                                           answerFormat:[ORKLegacyAnswerFormat weightAnswerFormatWithMeasurementSystem:ORKLegacyMeasurementSystemMetric]];
            item.placeholder = @"Pick a weight (metric system)";
            [items addObject:item];
        }

        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_weight_003" text:@"Weight"
                                                           answerFormat:[ORKLegacyAnswerFormat weightAnswerFormatWithMeasurementSystem:ORKLegacyMeasurementSystemUSC]];
            item.placeholder = @"Pick a weight (USC system)";
            [items addObject:item];
        }

        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_weight_004" text:@"Weight"
                                                           answerFormat:[ORKLegacyAnswerFormat weightAnswerFormatWithMeasurementSystem:ORKLegacyMeasurementSystemMetric
                                                                                                                numericPrecision:ORKLegacyNumericPrecisionLow
                                                                                                                    minimumValue:10
                                                                                                                    maximumValue:20
                                                                                                                    defaultValue:11.5]];
            item.placeholder = @"Pick a weight (metric system, low precision)";
            [items addObject:item];
        }

        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_weight_005" text:@"Weight"
                                                           answerFormat:[ORKLegacyAnswerFormat weightAnswerFormatWithMeasurementSystem:ORKLegacyMeasurementSystemUSC
                                                                                                                numericPrecision:ORKLegacyNumericPrecisionLow
                                                                                                                    minimumValue:10
                                                                                                                    maximumValue:20
                                                                                                                    defaultValue:11.5]];
            item.placeholder = @"Pick a weight (USC system, low precision)";
            [items addObject:item];
        }

        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_weight_006" text:@"Weight"
                                                           answerFormat:[ORKLegacyAnswerFormat weightAnswerFormatWithMeasurementSystem:ORKLegacyMeasurementSystemMetric
                                                                                                                numericPrecision:ORKLegacyNumericPrecisionHigh
                                                                                                                    minimumValue:10
                                                                                                                    maximumValue:20
                                                                                                                    defaultValue:11.5]];
            item.placeholder = @"Pick a weight (metric system, high precision)";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_weight_007" text:@"Weight"
                                                           answerFormat:[ORKLegacyAnswerFormat weightAnswerFormatWithMeasurementSystem:ORKLegacyMeasurementSystemUSC
                                                                                                                numericPrecision:ORKLegacyNumericPrecisionHigh
                                                                                                                    minimumValue:10
                                                                                                                    maximumValue:20
                                                                                                                    defaultValue:11.5]];
            item.placeholder = @"Pick a weight (USC system, high precision)";
            [items addObject:item];
        }

        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_date_001" text:@"Birthdate"
                                                         answerFormat:[ORKLegacyAnswerFormat dateAnswerFormat]];
            item.placeholder = @"Pick a date";
            [items addObject:item];
        }
        
        {
            NSDate *defaultDate = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitYear value:-30 toDate:[NSDate date] options:(NSCalendarOptions)0];
            NSDate *minDate = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitYear value:-150 toDate:[NSDate date] options:(NSCalendarOptions)0];

            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_date_002" text:@"Birthdate"
                                                         answerFormat:[ORKLegacyAnswerFormat dateAnswerFormatWithDefaultDate:defaultDate
                                                                                                        minimumDate:minDate
                                                                                                        maximumDate:[NSDate date]
                                                                                                           calendar:nil]];
            item.placeholder = @"Pick a date (with default)";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_timeOfDay_001" text:@"Today sunset time?"
                                                         answerFormat:[ORKLegacyAnswerFormat timeOfDayAnswerFormat]];
            item.placeholder = @"No default time";
            [items addObject:item];
        }
        
        {
            NSDateComponents *defaultDC = [[NSDateComponents alloc] init];
            defaultDC.hour = 14;
            defaultDC.minute = 23;
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_timeOfDay_002" text:@"Today sunset time?"
                                                         answerFormat:[ORKLegacyAnswerFormat timeOfDayAnswerFormatWithDefaultComponents:defaultDC]];
            item.placeholder = @"Default time 14:23";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_dateTime_001" text:@"Next eclipse visible in Cupertino?"
                                                         answerFormat:[ORKLegacyAnswerFormat dateTimeAnswerFormat]];
            
            item.placeholder = @"No default date and range";
            [items addObject:item];
        }
        
        {
            
            NSDate *defaultDate = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay value:3 toDate:[NSDate date] options:(NSCalendarOptions)0];
            NSDate *minDate = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay value:0 toDate:[NSDate date] options:(NSCalendarOptions)0];
            NSDate *maxDate = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay value:10 toDate:[NSDate date] options:(NSCalendarOptions)0];
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_dateTime_002" text:@"Next eclipse visible in Cupertino?"
                                                         answerFormat:[ORKLegacyAnswerFormat dateTimeAnswerFormatWithDefaultDate:defaultDate
                                                                                                            minimumDate:minDate
                                                                                                            maximumDate:maxDate
                                                                                                               calendar:nil]];
            
            item.placeholder = @"Default date in 3 days and range(0, 10)";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_timeInterval_001" text:@"Wake up interval"
                                                           answerFormat:[ORKLegacyAnswerFormat timeIntervalAnswerFormat]];
            item.placeholder = @"No default Interval and step size";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_timeInterval_002" text:@"Wake up interval"
                                                           answerFormat:[ORKLegacyAnswerFormat timeIntervalAnswerFormatWithDefaultInterval:300 step:3]];
            
            item.placeholder = @"Default Interval 300 and step size 3";
            [items addObject:item];
        }
        
        {
            /*
             Testbed for image choice.
             
             In a real application, you would use real images rather than square
             colored boxes.
             */
            ORKLegacyImageChoice *option1 = [ORKLegacyImageChoice choiceWithNormalImage:[self imageWithColor:[UIColor redColor] size:CGSizeMake(360, 360) border:NO]
                                                              selectedImage:[self imageWithColor:[UIColor redColor] size:CGSizeMake(360, 360) border:YES]
                                                                       text:@"Red" value:@"red"];
            ORKLegacyImageChoice *option2 = [ORKLegacyImageChoice choiceWithNormalImage:[self imageWithColor:[UIColor orangeColor] size:CGSizeMake(360, 360) border:NO]
                                                              selectedImage:[self imageWithColor:[UIColor orangeColor] size:CGSizeMake(360, 360) border:YES]
                                                                       text:nil value:@"orange"];
            ORKLegacyImageChoice *option3 = [ORKLegacyImageChoice choiceWithNormalImage:[self imageWithColor:[UIColor yellowColor] size:CGSizeMake(360, 360) border:NO]
                                                              selectedImage:[self imageWithColor:[UIColor yellowColor] size:CGSizeMake(360, 360) border:YES]
                                                                       text:@"Yellow" value:@"yellow"];
            
            ORKLegacyFormItem *item3 = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_009_3" text:@"What is your favorite color?"
                                                          answerFormat:[ORKLegacyAnswerFormat choiceAnswerFormatWithImageChoices:@[option1, option2, option3]]];
            [items addObject:item3];
        }
        
        {
            // Discrete scale
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_scale_001" text:@"Pick an integer" answerFormat:[[ORKLegacyScaleAnswerFormat alloc] initWithMaximumValue: 100 minimumValue: 0 defaultValue:NSIntegerMax step:10]];
            [items addObject:item];
        }
        
        {
            // Discrete scale, with default value
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_scale_002" text:@"Pick an integer" answerFormat:[[ORKLegacyScaleAnswerFormat alloc] initWithMaximumValue: 100 minimumValue: 0 defaultValue:20 step:10]];
            [items addObject:item];
        }
        
        {
            // Continuous scale
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_scale_003" text:@"Pick a decimal" answerFormat:[[ORKLegacyContinuousScaleAnswerFormat alloc] initWithMaximumValue: 100 minimumValue: 0 defaultValue:NSIntegerMax maximumFractionDigits:2]];
            [items addObject:item];
        }
        
        {
            // Continuous scale, with default value
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_scale_004" text:@"Pick a decimal" answerFormat:[[ORKLegacyContinuousScaleAnswerFormat alloc] initWithMaximumValue: 100 minimumValue: 0 defaultValue:87.34 maximumFractionDigits:2]];
            [items addObject:item];
        }
        
        {
            // Vertical Discrete scale, with default value
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_scale_005" text:@"Pick an integer" answerFormat:[[ORKLegacyScaleAnswerFormat alloc] initWithMaximumValue: 100 minimumValue: 0 defaultValue:90 step:10 vertical:YES]];
            [items addObject:item];
        }
        
        {
            // Vertical Continuous scale, with default value
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_scale_006" text:@"Pick a decimal" answerFormat:[[ORKLegacyContinuousScaleAnswerFormat alloc] initWithMaximumValue: 100 minimumValue: 0 defaultValue:12.75 maximumFractionDigits:2 vertical:YES]];
            [items addObject:item];
        }
        
        {
            ORKLegacyTextChoice *textChoice1 = [ORKLegacyTextChoice choiceWithText:@"Poor" value:@(1)];
            ORKLegacyTextChoice *textChoice2 = [ORKLegacyTextChoice choiceWithText:@"Fair" value:@(2)];
            ORKLegacyTextChoice *textChoice3 = [ORKLegacyTextChoice choiceWithText:@"Good" value:@(3)];
            ORKLegacyTextChoice *textChoice4 = [ORKLegacyTextChoice choiceWithText:@"Above Average" value:@(4)];
            ORKLegacyTextChoice *textChoice5 = [ORKLegacyTextChoice choiceWithText:@"Excellent" value:@(5)];
            
            NSArray *textChoices = @[textChoice1, textChoice2, textChoice3, textChoice4, textChoice5];
            
            ORKLegacyTextScaleAnswerFormat *scaleAnswerFormat = [ORKLegacyAnswerFormat textScaleAnswerFormatWithTextChoices:textChoices
                                                                                                   defaultIndex:NSIntegerMax
                                                                                                       vertical:NO];
            
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_scale_007"
                                                                   text:@"How are you feeling today?"
                                                           answerFormat:scaleAnswerFormat];
            [items addObject:item];
        }
        
        {
            ORKLegacyTextChoice *textChoice1 = [ORKLegacyTextChoice choiceWithText:@"Poor" value:@(1)];
            ORKLegacyTextChoice *textChoice2 = [ORKLegacyTextChoice choiceWithText:@"Fair" value:@(2)];
            ORKLegacyTextChoice *textChoice3 = [ORKLegacyTextChoice choiceWithText:@"Good" value:@(3)];
            ORKLegacyTextChoice *textChoice4 = [ORKLegacyTextChoice choiceWithText:@"Above Average" value:@(4)];
            ORKLegacyTextChoice *textChoice5 = [ORKLegacyTextChoice choiceWithText:@"Excellent" value:@(5)];
            
            NSArray *textChoices = @[textChoice1, textChoice2, textChoice3, textChoice4, textChoice5];
            
            ORKLegacyTextScaleAnswerFormat *scaleAnswerFormat = [ORKLegacyAnswerFormat textScaleAnswerFormatWithTextChoices:textChoices
                                                                                                   defaultIndex:NSIntegerMax
                                                                                                       vertical:YES];
            
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_scale_008"
                                                                   text:@"How are you feeling today?"
                                                           answerFormat:scaleAnswerFormat];
            [items addObject:item];
        }
        
        {
            //Location
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fiqd_location" text:@"Pick a location" answerFormat:[ORKLegacyAnswerFormat locationAnswerFormat]];
            [items addObject:item];
        }
        
        [step setFormItems:items];
        [steps addObject:step];
    }

    {
        
        ORKLegacyFormStep *step = [[ORKLegacyFormStep alloc] initWithIdentifier:@"fid_002" title:@"Required form step" text:nil];
        ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_001"
                                                               text:@"Value"
                                                       answerFormat:[ORKLegacyNumericAnswerFormat valuePickerAnswerFormatWithTextChoices:@[@"1", @"2", @"3"]]];
        item.placeholder = @"Pick a value";
        [step setFormItems:@[item]];
        step.optional = NO;
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"aid_001"];
        step.title = @"Thanks";
        [steps addObject:step];
    }
    
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:MiniFormTaskIdentifier steps:steps];
    
    return task;
}

- (void)miniFormButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:MiniFormTaskIdentifier];
}

#pragma mark - Mini form task

/*
 The optional form task is used to test form items' optional functionality (`ORKLegacyFormStep`, `ORKLegacyFormItem`).
 */
- (id<ORKLegacyTask>)makeOptionalFormTask {
    NSMutableArray *steps = [NSMutableArray new];
    
    {
        {
            ORKLegacyFormStep *step = [[ORKLegacyFormStep alloc] initWithIdentifier:@"scale_form_00" title:@"Optional Form Items" text:@"Optional form with a required scale item with a default value"];
            NSMutableArray *items = [NSMutableArray new];
            [steps addObject:step];
            
            {
                ORKLegacyScaleAnswerFormat *format = [ORKLegacyScaleAnswerFormat scaleAnswerFormatWithMaximumValue:10 minimumValue:1 defaultValue:4 step:1 vertical:YES maximumValueDescription:nil minimumValueDescription:nil];
                ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"scale_form"
                                                                       text:@"Optional scale"
                                                               answerFormat:format];
                item.optional = NO;
                [items addObject:item];
            }
                 
            [step setFormItems:items];
        }

        
        ORKLegacyFormStep *step = [[ORKLegacyFormStep alloc] initWithIdentifier:@"fid_000" title:@"Optional Form Items" text:@"Optional form with no required items"];
        NSMutableArray *items = [NSMutableArray new];
        [steps addObject:step];
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithSectionTitle:@"Optional"];
            [items addObject:item];
        }

        {
            ORKLegacyTextAnswerFormat *format = [ORKLegacyAnswerFormat textAnswerFormatWithMaximumLength:12];
            format.multipleLines = NO;
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_text3"
                                                                   text:@"Text"
                                                           answerFormat:format];
            item.placeholder = @"Input any text here.";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_text4"
                                                                   text:@"Number"
                                                           answerFormat:[ORKLegacyNumericAnswerFormat decimalAnswerFormatWithUnit:nil]];
            item.placeholder = @"Input any number here.";
            [items addObject:item];
        }
        
        [step setFormItems:items];
    }
    
    {
        ORKLegacyFormStep *step = [[ORKLegacyFormStep alloc] initWithIdentifier:@"fid_001" title:@"Optional Form Items" text:@"Optional form with some required items"];
        NSMutableArray *items = [NSMutableArray new];
        [steps addObject:step];
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithSectionTitle:@"Optional"];
            [items addObject:item];
        }

        ORKLegacyTextAnswerFormat *format = [ORKLegacyAnswerFormat textAnswerFormatWithMaximumLength:12];
        format.multipleLines = NO;
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_text1"
                                                                   text:@"Text A"
                                                           answerFormat:format];
            item.placeholder = @"Input any text here.";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_text2"
                                                                   text:@"Text B"
                                                           answerFormat:format];
            item.placeholder = @"Input any text here.";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithSectionTitle:@"Required"];
            [items addObject:item];
        }

        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_text3"
                                                                   text:@"Text C"
                                                           answerFormat:format
                                                               optional:NO];
            item.placeholder = @"Input any text here.";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_text4"
                                                                   text:@"Number"
                                                           answerFormat:[ORKLegacyNumericAnswerFormat decimalAnswerFormatWithUnit:nil]
                                                               optional:NO];
            item.placeholder = @"Input any number here.";
            [items addObject:item];
        }
        
        [step setFormItems:items];
    }

    {
        ORKLegacyFormStep *step = [[ORKLegacyFormStep alloc] initWithIdentifier:@"fid_002" title:@"Optional Form Items" text:@"Optional form with all items required"];
        NSMutableArray *items = [NSMutableArray new];
        [steps addObject:step];
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithSectionTitle:@"Required"];
            [items addObject:item];
        }

        ORKLegacyTextAnswerFormat *format = [ORKLegacyAnswerFormat textAnswerFormatWithMaximumLength:12];
        format.multipleLines = NO;
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_text1"
                                                                   text:@"Text A"
                                                           answerFormat:format
                                                               optional:NO];
            item.placeholder = @"Input any text here.";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_text2"
                                                                   text:@"Text B"
                                                           answerFormat:format
                                                               optional:NO];
            item.placeholder = @"Input any text here.";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_text3"
                                                                   text:@"Text C"
                                                           answerFormat:format
                                                               optional:NO];
            item.placeholder = @"Input any text here.";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_text4"
                                                                   text:@"Number"
                                                           answerFormat:[ORKLegacyNumericAnswerFormat decimalAnswerFormatWithUnit:nil]
                                                               optional:NO];
            item.placeholder = @"Input any number here.";
            [items addObject:item];
        }
        
        [step setFormItems:items];
    }

    {
        ORKLegacyFormStep *step = [[ORKLegacyFormStep alloc] initWithIdentifier:@"fid_003" title:@"Optional Form Items" text:@"Required form with no required items"];
        NSMutableArray *items = [NSMutableArray new];
        [steps addObject:step];
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithSectionTitle:@"Optional"];
            [items addObject:item];
        }

        {
            ORKLegacyTextAnswerFormat *format = [ORKLegacyAnswerFormat textAnswerFormatWithMaximumLength:6];
            format.multipleLines = NO;
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_text3"
                                                                   text:@"Text"
                                                           answerFormat:format];
            item.placeholder = @"Input any text here.";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_text4"
                                                                   text:@"Number"
                                                           answerFormat:[ORKLegacyNumericAnswerFormat decimalAnswerFormatWithUnit:nil]];
            item.placeholder = @"Input any number here.";
            [items addObject:item];
        }
        
        [step setFormItems:items];
        step.optional = NO;
    }
    
    {
        ORKLegacyFormStep *step = [[ORKLegacyFormStep alloc] initWithIdentifier:@"fid_004" title:@"Optional Form Items" text:@"Required form with some required items"];
        NSMutableArray *items = [NSMutableArray new];
        [steps addObject:step];
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithSectionTitle:@"Optional"];
            [items addObject:item];
        }

        ORKLegacyTextAnswerFormat *format = [ORKLegacyAnswerFormat textAnswerFormatWithMaximumLength:12];
        format.multipleLines = NO;
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_text1"
                                                                   text:@"Text A"
                                                           answerFormat:format];
            item.placeholder = @"Input your text here.";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_text2"
                                                                   text:@"Text B"
                                                           answerFormat:format];
            item.placeholder = @"Input your text here.";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithSectionTitle:@"Required"];
            [items addObject:item];
        }

        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_text3"
                                                                   text:@"Text C"
                                                           answerFormat:format];
            item.optional = NO;
            item.placeholder = @"Input your text here.";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_text4"
                                                                   text:@"Number"
                                                           answerFormat:[ORKLegacyNumericAnswerFormat decimalAnswerFormatWithUnit:nil]];
            item.optional = NO;
            item.placeholder = @"Input any number here.";
            [items addObject:item];
        }
        
        [step setFormItems:items];
        step.optional = NO;
    }

    {
        ORKLegacyFormStep *step = [[ORKLegacyFormStep alloc] initWithIdentifier:@"fid_005" title:@"Optional Form Items" text:@"Required form with all items required"];
        NSMutableArray *items = [NSMutableArray new];
        [steps addObject:step];
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithSectionTitle:@"Required"];
            [items addObject:item];
        }

        ORKLegacyTextAnswerFormat *format = [ORKLegacyAnswerFormat textAnswerFormatWithMaximumLength:12];
        format.multipleLines = NO;
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_text1"
                                                                   text:@"Text A"
                                                           answerFormat:format];
            item.optional = NO;
            item.placeholder = @"Input any text here.";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_text2"
                                                                   text:@"Text B"
                                                           answerFormat:format];
            item.optional = NO;
            item.placeholder = @"Input any text here.";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_text3"
                                                                   text:@"Text C"
                                                           answerFormat:format];
            item.optional = NO;
            item.placeholder = @"Input any text here.";
            [items addObject:item];
        }
        
        {
            ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"fqid_text4"
                                                                   text:@"Number"
                                                           answerFormat:[ORKLegacyNumericAnswerFormat decimalAnswerFormatWithUnit:nil]];
            item.optional = NO;
            item.placeholder = @"Input any number here.";
            [items addObject:item];
        }
        
        [step setFormItems:items];
        step.optional = NO;
    }
    
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:MiniFormTaskIdentifier steps:steps];
    
    return task;
}

- (void)optionalFormButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:OptionalFormTaskIdentifier];
}

#pragma mark - Predicate Tests
/*
 This is intended to test the predicate functions and APIs
 */
- (id<ORKLegacyTask>)makePredicateTestsTask {
    NSMutableArray *steps = [NSMutableArray new];
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"intro_step"];
        step.title = @"Predicate Tests";
        [steps addObject:step];
    }
    
    // Test Expected Boolean value
    {
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"question_01"
                                                                      title:@"Pass the Boolean question?"
                                                                     answer:[ORKLegacyAnswerFormat booleanAnswerFormat]];
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"question_01_fail"];
        step.title = @"You failed the Boolean question.";
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"question_01_pass"];
        step.title = @"You passed the Boolean question.";
        [steps addObject:step];
    }
    
    // Test expected Single Choice
    {
        ORKLegacyAnswerFormat *answer = [ORKLegacyAnswerFormat choiceAnswerFormatWithStyle:ORKLegacyChoiceAnswerStyleSingleChoice textChoices:[NSArray arrayWithObjects:@"Choose Yes", @"Choose No", nil]];
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"question_02"
                                                                      title:@"Pass the single choice question?"
                                                                     answer:answer];
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"question_02_fail"];
        step.title = @"You failed the single choice question.";
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"question_02_pass"];
        step.title = @"You passed the single choice question.";
        [steps addObject:step];
    }
    
    //  Test expected multiple choices
    {
        ORKLegacyAnswerFormat *answer = [ORKLegacyAnswerFormat choiceAnswerFormatWithStyle:ORKLegacyChoiceAnswerStyleMultipleChoice textChoices:[NSArray arrayWithObjects:@"Cat", @"Dog", @"Rock", nil]];
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"question_03"
                                                                      title:@"Select all the animals"
                                                                     answer:answer];
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"question_03_fail"];
        step.title = @"You failed the multiple choice animals question.";
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"question_03_pass"];
        step.title = @"You passed the multiple choice animals question.";
        [steps addObject:step];
    }

    //  Test expected multiple choices
    {
        ORKLegacyAnswerFormat *answer = [ORKLegacyAnswerFormat choiceAnswerFormatWithStyle:ORKLegacyChoiceAnswerStyleSingleChoice textChoices:[NSArray arrayWithObjects:@"Cat", @"Catheter", @"Cathedral", @"Dog", nil]];
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"question_04"
                                                                      title:@"Choose any word containing the word 'Cat'"
                                                                     answer:answer];
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"question_04_fail"];
        step.title = @"You failed the 'Cat' pattern match question.";
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"question_04_pass"];
        step.title = @"You passed the 'Cat' pattern match question.";
        [steps addObject:step];
    }

    //  Test expected text
    {
        ORKLegacyAnswerFormat *answer = [ORKLegacyAnswerFormat textAnswerFormat];
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"question_05"
                                                                      title:@"Write the word 'Dog'"
                                                                     answer:answer];
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"question_05_fail"];
        step.title = @"You didn't write 'Dog'.";
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"question_05_pass"];
        step.title = @"You wrote 'Dog'.";
        [steps addObject:step];
    }
    
    //  Test matching text
    {
        ORKLegacyAnswerFormat *answer = [ORKLegacyAnswerFormat textAnswerFormat];
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"question_06"
                                                                      title:@"Write a word matching '*og'"
                                                                     answer:answer];
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"question_06_fail"];
        step.title = @"You didn't write a word matching '*og'.";
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"question_06_pass"];
        step.title = @"You wrote a word matching '*og'.";
        [steps addObject:step];
    }
    
    //  Numeric test - any number over 10
    {
        ORKLegacyAnswerFormat *answer = [ORKLegacyAnswerFormat integerAnswerFormatWithUnit:nil];
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"question_07"
                                                                      title:@"Enter a number over 10"
                                                                     answer:answer];
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"question_07_fail"];
        step.title = @"Your number was less then 10.";
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"question_07_pass"];
        step.title = @"Your number was over 10.";
        [steps addObject:step];
    }
    
    {
        /*
         Vertical continuous scale with three decimal places and a default.
         */
        ORKLegacyContinuousScaleAnswerFormat *scaleAnswerFormat =  [ORKLegacyAnswerFormat continuousScaleAnswerFormatWithMaximumValue:10
                                                                                                             minimumValue:1
                                                                                                             defaultValue:8.725
                                                                                                    maximumFractionDigits:3
                                                                                                                 vertical:YES
                                                                                                  maximumValueDescription:nil
                                                                                                  minimumValueDescription:nil];
        
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"question_08"
                                                                      title:@"Choose a value under 5"
                                                                     answer:scaleAnswerFormat];
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"question_08_fail"];
        step.title = @"Your number was more than 5.";
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"question_08_pass"];
        step.title = @"Your number was less than 5.";
        [steps addObject:step];
    }


    {
        ORKLegacyCompletionStep *step = [[ORKLegacyCompletionStep alloc] initWithIdentifier:@"all_passed"];
        step.title = @"All validation tests now completed.";
        [steps addObject:step];
    }
    
    ORKLegacyNavigableOrderedTask *task = [[ORKLegacyNavigableOrderedTask alloc] initWithIdentifier:EligibilitySurveyTaskIdentifier steps:steps];
    
    // Build navigation rules.
    {
        // If we answer 'Yes' to Question 1, then proceed to the pass screen
        ORKLegacyResultSelector *resultSelector = [ORKLegacyResultSelector selectorWithResultIdentifier:@"question_01"];
        NSPredicate *predicateQuestion = [ORKLegacyResultPredicate predicateForBooleanQuestionResultWithResultSelector:resultSelector expectedAnswer:YES];
    
        ORKLegacyPredicateStepNavigationRule *predicateRule = [[ORKLegacyPredicateStepNavigationRule alloc] initWithResultPredicates:@[predicateQuestion]
                                                                                          destinationStepIdentifiers:@[@"question_01_pass"]];
        [task setNavigationRule:predicateRule forTriggerStepIdentifier:@"question_01"];
    }
    
    {
        // If we arrived at question_01_fail then fall through to question 2
        ORKLegacyDirectStepNavigationRule *directRule = nil;
        directRule = [[ORKLegacyDirectStepNavigationRule alloc] initWithDestinationStepIdentifier:@"question_02"];
        [task setNavigationRule:directRule forTriggerStepIdentifier:@"question_01_fail"];
    }
    
    {
        // If we answer 'Yes' to Question 2, then proceed to the pass screen
        ORKLegacyResultSelector *resultSelector = [ORKLegacyResultSelector selectorWithResultIdentifier:@"question_02"];
        NSPredicate *predicateQuestion = [ORKLegacyResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector expectedAnswerValue:@"Choose Yes"];
    
        ORKLegacyPredicateStepNavigationRule *predicateRule = [[ORKLegacyPredicateStepNavigationRule alloc] initWithResultPredicates:@[predicateQuestion]
                                                                                          destinationStepIdentifiers:@[@"question_02_pass"]];
        [task setNavigationRule:predicateRule forTriggerStepIdentifier:@"question_02"];
    }
    
    {
        // If we arrived at question_02_fail then fall through to question 3
        ORKLegacyDirectStepNavigationRule *directRule = nil;
        directRule = [[ORKLegacyDirectStepNavigationRule alloc] initWithDestinationStepIdentifier:@"question_03"];
        [task setNavigationRule:directRule forTriggerStepIdentifier:@"question_02_fail"];
    }
    
    {
        // If we answer 'Yes' to Question 3, then proceed to the pass screen
        ORKLegacyResultSelector *resultSelector = [ORKLegacyResultSelector selectorWithResultIdentifier:@"question_03"];
        NSPredicate *predicateQuestion = [ORKLegacyResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector expectedAnswerValues:[NSArray arrayWithObjects: @"Cat",@"Dog", nil]];
        
        ORKLegacyPredicateStepNavigationRule *predicateRule = [[ORKLegacyPredicateStepNavigationRule alloc] initWithResultPredicates:@[predicateQuestion]
                                                                                              destinationStepIdentifiers:@[@"question_03_pass"]];
        [task setNavigationRule:predicateRule forTriggerStepIdentifier:@"question_03"];
    }
    
    {
        // If we arrived at question_03_fail then fall through to question 4
        ORKLegacyDirectStepNavigationRule *directRule = nil;
        directRule = [[ORKLegacyDirectStepNavigationRule alloc] initWithDestinationStepIdentifier:@"question_04"];
        [task setNavigationRule:directRule forTriggerStepIdentifier:@"question_03_fail"];
    }
    
    {
        // If we answer 'Yes' to Question 4, then proceed to the pass screen
        ORKLegacyResultSelector *resultSelector = [ORKLegacyResultSelector selectorWithResultIdentifier:@"question_04"];
        NSPredicate *predicateQuestion = [ORKLegacyResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector matchingPattern:@"Cat.*"];
        
        ORKLegacyPredicateStepNavigationRule *predicateRule = [[ORKLegacyPredicateStepNavigationRule alloc] initWithResultPredicates:@[predicateQuestion]
                                                                                              destinationStepIdentifiers:@[@"question_04_pass"]];
        [task setNavigationRule:predicateRule forTriggerStepIdentifier:@"question_04"];
    }
    
    {
        // If we arrived at question_04_fail then fall through to question 5
        ORKLegacyDirectStepNavigationRule *directRule = nil;
        directRule = [[ORKLegacyDirectStepNavigationRule alloc] initWithDestinationStepIdentifier:@"question_05"];
        [task setNavigationRule:directRule forTriggerStepIdentifier:@"question_04_fail"];
    }
    
    {
        // If we answer 'Dog' to Question 5, then proceed to the pass screen
        ORKLegacyResultSelector *resultSelector = [ORKLegacyResultSelector selectorWithResultIdentifier:@"question_05"];
        NSPredicate *predicateQuestion = [ORKLegacyResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector expectedString:@"Dog"];
        
        ORKLegacyPredicateStepNavigationRule *predicateRule = [[ORKLegacyPredicateStepNavigationRule alloc] initWithResultPredicates:@[predicateQuestion]
                                                                                              destinationStepIdentifiers:@[@"question_05_pass"]];
        [task setNavigationRule:predicateRule forTriggerStepIdentifier:@"question_05"];
    }
    
    {
        // If we arrived at question_05_fail then fall through to question 6
        ORKLegacyDirectStepNavigationRule *directRule = nil;
        directRule = [[ORKLegacyDirectStepNavigationRule alloc] initWithDestinationStepIdentifier:@"question_06"];
        [task setNavigationRule:directRule forTriggerStepIdentifier:@"question_05_fail"];
    }
    
    
    {
        // If we answer '*og' to Question 6, then proceed to the pass screen
        ORKLegacyResultSelector *resultSelector = [ORKLegacyResultSelector selectorWithResultIdentifier:@"question_06"];
        NSPredicate *predicateQuestion = [ORKLegacyResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector matchingPattern:@".*og"];
        
        ORKLegacyPredicateStepNavigationRule *predicateRule = [[ORKLegacyPredicateStepNavigationRule alloc] initWithResultPredicates:@[predicateQuestion]
                                                                                              destinationStepIdentifiers:@[@"question_06_pass"]];
        [task setNavigationRule:predicateRule forTriggerStepIdentifier:@"question_06"];
    }
    
    {
        // If we arrived at question_06_fail then fall through to question 7
        ORKLegacyDirectStepNavigationRule *directRule = nil;
        directRule = [[ORKLegacyDirectStepNavigationRule alloc] initWithDestinationStepIdentifier:@"question_07"];
        [task setNavigationRule:directRule forTriggerStepIdentifier:@"question_06_fail"];
    }
    
    {
        // If we answer '*og' to Question 7, then proceed to the pass screen
        ORKLegacyResultSelector *resultSelector = [ORKLegacyResultSelector selectorWithResultIdentifier:@"question_07"];
        NSPredicate *predicateQuestion = [ORKLegacyResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector minimumExpectedAnswerValue:10];
        
        ORKLegacyPredicateStepNavigationRule *predicateRule = [[ORKLegacyPredicateStepNavigationRule alloc] initWithResultPredicates:@[predicateQuestion]
                                                                                              destinationStepIdentifiers:@[@"question_07_pass"]];
        [task setNavigationRule:predicateRule forTriggerStepIdentifier:@"question_07"];
    }
    
    {
        // If we arrived at question_05_fail then fall through to question 6
        ORKLegacyDirectStepNavigationRule *directRule = nil;
        directRule = [[ORKLegacyDirectStepNavigationRule alloc] initWithDestinationStepIdentifier:@"question_08"];
        [task setNavigationRule:directRule forTriggerStepIdentifier:@"question_07_fail"];
    }
    
    {
        // If we answer '*og' to Question 7, then proceed to the pass screen
        ORKLegacyResultSelector *resultSelector = [ORKLegacyResultSelector selectorWithResultIdentifier:@"question_08"];
        NSPredicate *predicateQuestion = [ORKLegacyResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector maximumExpectedAnswerValue:5];
        
        ORKLegacyPredicateStepNavigationRule *predicateRule = [[ORKLegacyPredicateStepNavigationRule alloc] initWithResultPredicates:@[predicateQuestion]
                                                                                              destinationStepIdentifiers:@[@"question_08_pass"]];
        [task setNavigationRule:predicateRule forTriggerStepIdentifier:@"question_08"];
    }
    
    {
        // If we arrived at question_05_fail then fall through to question 6
        ORKLegacyDirectStepNavigationRule *directRule = nil;
        directRule = [[ORKLegacyDirectStepNavigationRule alloc] initWithDestinationStepIdentifier:@"all_passed"];
        [task setNavigationRule:directRule forTriggerStepIdentifier:@"question_08_fail"];
    }

    return task;
}

- (void)predicateTestsButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:PredicateTestsTaskIdentifier];
}

#pragma mark - Active tasks

- (void)fitnessTaskButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:FitnessTaskIdentifier];
}

- (void)gaitTaskButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:GaitTaskIdentifier];
}

- (void)memoryGameTaskButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:MemoryTaskIdentifier];
}

- (IBAction)waitTaskButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:WaitTaskIdentifier];
}

- (void)audioTaskButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:AudioTaskIdentifier];
}

- (void)toneAudiometryTaskButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:ToneAudiometryTaskIdentifier];
}

- (void)twoFingerTappingTaskButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:TwoFingerTapTaskIdentifier];
}

- (void)reactionTimeTaskButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:ReactionTimeTaskIdentifier];
}

- (void)stroopTaskButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:StroopTaskIdentifier];
}

- (void)towerOfHanoiTaskButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:TowerOfHanoiTaskIdentifier];
}

- (void)timedWalkTaskButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:TimedWalkTaskIdentifier];
}

- (void)psatTaskButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:PSATTaskIdentifier];
}

- (void)holePegTestTaskButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:HolePegTestTaskIdentifier];
}

- (void)walkAndTurnTaskButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:WalkBackAndForthTaskIdentifier];
}

- (void)handTremorTaskButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:TremorTaskIdentifier];
}

- (void)rightHandTremorTaskButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:TremorRightHandTaskIdentifier];
}

#pragma mark - Dynamic task

/*
 See the `DynamicTask` class for a definition of this task.
 */
- (void)dynamicTaskButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:DynamicTaskIdentifier];
}

#pragma mark - Screening task

/*
 This demonstrates a task where if the user enters a value that is too low for
 the first question (say, under 18), the task view controller delegate API can
 be used to reject the answer and prevent forward navigation.
 
 See the implementation of the task view controller delegate methods for specific
 handling of this task.
 */
- (id<ORKLegacyTask>)makeInterruptibleTask {
    NSMutableArray *steps = [NSMutableArray new];
    
    {
        ORKLegacyNumericAnswerFormat *format = [ORKLegacyNumericAnswerFormat integerAnswerFormatWithUnit:@"years"];
        format.minimum = @(5);
        format.maximum = @(90);
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"itid_001"
                                                                      title:@"How old are you?"
                                                                     answer:format];
        [steps addObject:step];
    }
    
    {
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"itid_002"
                                                                      title:@"How much did you pay for your car?"
                                                                     answer:[ORKLegacyNumericAnswerFormat decimalAnswerFormatWithUnit:@"USD"]];
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"itid_003"];
        step.title = @"Thank you for completing this task.";
        [steps addObject:step];
    }
    
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:InterruptibleTaskIdentifier steps:steps];
    return task;
}

- (void)interruptibleTaskButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:InterruptibleTaskIdentifier];
}

#pragma mark - Scales task

/*
 This task is used to test various uses of discrete and continuous, horizontal and vertical valued sliders.
 */
- (id<ORKLegacyTask>)makeScalesTask {

    NSMutableArray *steps = [NSMutableArray array];
    
    {
        /*
         Continuous scale with two decimal places.
         */
        ORKLegacyContinuousScaleAnswerFormat *scaleAnswerFormat =  [ORKLegacyAnswerFormat continuousScaleAnswerFormatWithMaximumValue:10
                                                                                                             minimumValue:1
                                                                                                             defaultValue:NSIntegerMax
                                                                                                    maximumFractionDigits:2
                                                                                                                 vertical:NO
                                                                                                  maximumValueDescription:nil
                                                                                                  minimumValueDescription:nil];
        
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"scale_01"
                                                                    title:@"On a scale of 1 to 10, how much pain do you feel?"
                                                                   answer:scaleAnswerFormat];
        [steps addObject:step];
    }
    
    {
        /*
         Discrete scale, no default.
         */
        ORKLegacyScaleAnswerFormat *scaleAnswerFormat =  [ORKLegacyAnswerFormat scaleAnswerFormatWithMaximumValue:300
                                                                                         minimumValue:100
                                                                                         defaultValue:NSIntegerMax
                                                                                                 step:50
                                                                                             vertical:NO
                                                                              maximumValueDescription:nil
                                                                              minimumValueDescription:nil];
        
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"scale_02"
                                                                    title:@"How much money do you need?"
                                                                   answer:scaleAnswerFormat];
        [steps addObject:step];
    }
    
    {
        /*
         Discrete scale, with a default.
         */
        ORKLegacyScaleAnswerFormat *scaleAnswerFormat =  [ORKLegacyAnswerFormat scaleAnswerFormatWithMaximumValue:10
                                                                                         minimumValue:1
                                                                                         defaultValue:5
                                                                                                 step:1
                                                                                             vertical:NO
                                                                              maximumValueDescription:nil
                                                                              minimumValueDescription:nil];
        
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"scale_03"
                                                                    title:@"On a scale of 1 to 10, how much pain do you feel?"
                                                                   answer:scaleAnswerFormat];
        [steps addObject:step];
    }
    
    {
        /*
         Discrete scale, with a default that is not on a step boundary.
         */
        ORKLegacyScaleAnswerFormat *scaleAnswerFormat =  [ORKLegacyAnswerFormat scaleAnswerFormatWithMaximumValue:300
                                                                                         minimumValue:100
                                                                                         defaultValue:174
                                                                                                 step:50
                                                                                             vertical:NO
                                                                              maximumValueDescription:nil
                                                                              minimumValueDescription:nil];
        
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"scale_04"
                                                                    title:@"How much money do you need?"
                                                                   answer:scaleAnswerFormat];
        [steps addObject:step];
    }

    {
        /*
         Vertical continuous scale with three decimal places and a default.
         */
        ORKLegacyContinuousScaleAnswerFormat *scaleAnswerFormat =  [ORKLegacyAnswerFormat continuousScaleAnswerFormatWithMaximumValue:10
                                                                                                             minimumValue:1
                                                                                                             defaultValue:8.725
                                                                                                    maximumFractionDigits:3
                                                                                                                 vertical:YES
                                                                                                  maximumValueDescription:nil
                                                                                                  minimumValueDescription:nil];
        
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"scale_05"
                                                                      title:@"On a scale of 1 to 10, what is your mood?"
                                                                     answer:scaleAnswerFormat];
        [steps addObject:step];
    }

    {
        /*
         Vertical discrete scale, with a default on a step boundary.
         */
        ORKLegacyScaleAnswerFormat *scaleAnswerFormat =  [ORKLegacyAnswerFormat scaleAnswerFormatWithMaximumValue:10
                                                                                         minimumValue:1
                                                                                         defaultValue:5
                                                                                                 step:1
                                                                                             vertical:YES
                                                                              maximumValueDescription:nil
                                                                              minimumValueDescription:nil];
        
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"scale_06"
                                                                      title:@"How was your mood yesterday?"
                                                                     answer:scaleAnswerFormat];
        [steps addObject:step];
    }
    
    {
        /*
         Vertical discrete scale, with min and max labels.
         */
        ORKLegacyScaleAnswerFormat *scaleAnswerFormat =  [ORKLegacyAnswerFormat scaleAnswerFormatWithMaximumValue:10
                                                                                         minimumValue:1
                                                                                         defaultValue:NSIntegerMax
                                                                                                 step:1
                                                                                             vertical:YES
                                                                              maximumValueDescription:@"A lot"
                                                                              minimumValueDescription:@"Not at all"];
        
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"scale_07"
                                                                      title:@"On a scale of 1 to 10, what is your mood?"
                                                                     answer:scaleAnswerFormat];
        [steps addObject:step];
    }
    
    {
        /*
         Vertical continuous scale, with min and max labels.
         */
        ORKLegacyContinuousScaleAnswerFormat *scaleAnswerFormat =  [ORKLegacyAnswerFormat continuousScaleAnswerFormatWithMaximumValue:10
                                                                                                             minimumValue:1
                                                                                                             defaultValue:99
                                                                                                    maximumFractionDigits:2
                                                                                                                 vertical:YES
                                                                                                  maximumValueDescription:@"High value"
                                                                                                  minimumValueDescription:@"Low value"];
        
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"scale_08"
                                                                      title:@"How would you measure your mood improvement?"
                                                                     answer:scaleAnswerFormat];
        [steps addObject:step];
    }
    
    {
        /*
         Vertical discrete scale, with min and max labels.
         */
        ORKLegacyScaleAnswerFormat *scaleAnswerFormat =  [ORKLegacyAnswerFormat scaleAnswerFormatWithMaximumValue:10
                                                                                         minimumValue:1
                                                                                         defaultValue:NSIntegerMax
                                                                                                 step:1
                                                                                             vertical:NO
                                                                              maximumValueDescription:@"A lot"
                                                                              minimumValueDescription:@"Not at all"];
        
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"scale_09"
                                                                      title:@"On a scale of 1 to 10, what is your mood?"
                                                                     answer:scaleAnswerFormat];
        [steps addObject:step];
    }
    
    {
        /*
         Vertical continuous scale, with min and max labels.
         */
        ORKLegacyContinuousScaleAnswerFormat *scaleAnswerFormat =  [ORKLegacyAnswerFormat continuousScaleAnswerFormatWithMaximumValue:10
                                                                                                             minimumValue:1
                                                                                                             defaultValue:99
                                                                                                    maximumFractionDigits:2
                                                                                                                 vertical:NO
                                                                                                  maximumValueDescription:@"High value"
                                                                                                  minimumValueDescription:@"Low value"];
        
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"scale_10"
                                                                      title:@"How would you measure your mood improvement?"
                                                                     answer:scaleAnswerFormat];
        [steps addObject:step];
    }

    {
        /*
         Vertical continuous scale with three decimal places, a default, and a format style.
         */
        ORKLegacyContinuousScaleAnswerFormat *scaleAnswerFormat =  [ORKLegacyAnswerFormat continuousScaleAnswerFormatWithMaximumValue:1.0
                                                                                                             minimumValue:0.0
                                                                                                             defaultValue:0.8725
                                                                                                    maximumFractionDigits:0
                                                                                                                 vertical:YES
                                                                                                  maximumValueDescription:nil
                                                                                                  minimumValueDescription:nil];

        scaleAnswerFormat.numberStyle = ORKLegacyNumberFormattingStylePercent;
        
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"scale_11"
                                                                      title:@"How much has your mood improved?"
                                                                     answer:scaleAnswerFormat];
        [steps addObject:step];
    }
    
    {
        /*
         Continuous scale with images.
         */
        ORKLegacyContinuousScaleAnswerFormat *scaleAnswerFormat =  [ORKLegacyAnswerFormat continuousScaleAnswerFormatWithMaximumValue:10
                                                                                                             minimumValue:1
                                                                                                             defaultValue:NSIntegerMax
                                                                                                    maximumFractionDigits:2
                                                                                                                 vertical:YES
                                                                                                  maximumValueDescription:@"Hot"
                                                                                                  minimumValueDescription:@"Warm"];
        
        scaleAnswerFormat.minimumImage = [self imageWithColor:[UIColor yellowColor] size:CGSizeMake(30, 30) border:NO];
        scaleAnswerFormat.maximumImage = [self imageWithColor:[UIColor redColor] size:CGSizeMake(30, 30) border:NO];
        scaleAnswerFormat.minimumImage.accessibilityHint = @"A yellow colored square to represent warmness.";
        scaleAnswerFormat.maximumImage.accessibilityHint = @"A red colored square to represent hot.";
        
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"scale_12"
                                                                      title:@"On a scale of 1 to 10, how warm do you feel?"
                                                                     answer:scaleAnswerFormat];
        [steps addObject:step];
    }
    
    {
        /*
         Discrete scale with images.
         */
        ORKLegacyScaleAnswerFormat *scaleAnswerFormat =  [ORKLegacyAnswerFormat scaleAnswerFormatWithMaximumValue:10
                                                                                         minimumValue:1
                                                                                         defaultValue:NSIntegerMax
                                                                                                 step:1
                                                                                             vertical:NO
                                                                              maximumValueDescription:nil
                                                                              minimumValueDescription:nil];
        
        scaleAnswerFormat.minimumImage = [self imageWithColor:[UIColor yellowColor] size:CGSizeMake(30, 30) border:NO];
        scaleAnswerFormat.maximumImage = [self imageWithColor:[UIColor redColor] size:CGSizeMake(30, 30) border:NO];
        
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"scale_13"
                                                                      title:@"On a scale of 1 to 10, how warm do you feel?"
                                                                     answer:scaleAnswerFormat];
        [steps addObject:step];
    }
    
    {
        ORKLegacyTextChoice *textChoice1 = [ORKLegacyTextChoice choiceWithText:@"Poor" value:@(1)];
        ORKLegacyTextChoice *textChoice2 = [ORKLegacyTextChoice choiceWithText:@"Fair" value:@(2)];
        ORKLegacyTextChoice *textChoice3 = [ORKLegacyTextChoice choiceWithText:@"Good" value:@(3)];
        ORKLegacyTextChoice *textChoice4 = [ORKLegacyTextChoice choiceWithText:@"Above Average" value:@(4)];
        ORKLegacyTextChoice *textChoice5 = [ORKLegacyTextChoice choiceWithText:@"Excellent" value:@(5)];
        
        NSArray *textChoices = @[textChoice1, textChoice2, textChoice3, textChoice4, textChoice5];
        
        ORKLegacyTextScaleAnswerFormat *scaleAnswerFormat = [ORKLegacyAnswerFormat textScaleAnswerFormatWithTextChoices:textChoices
                                                                                               defaultIndex:3
                                                                                                   vertical:NO];
        
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"scale_14"
                                                                      title:@"How are you feeling today?"
                                                                     answer:scaleAnswerFormat];
        
        [steps addObject:step];
    }
    
    {
        ORKLegacyTextChoice *textChoice1 = [ORKLegacyTextChoice choiceWithText:@"Poor" value:@(1)];
        ORKLegacyTextChoice *textChoice2 = [ORKLegacyTextChoice choiceWithText:@"Fair" value:@(2)];
        ORKLegacyTextChoice *textChoice3 = [ORKLegacyTextChoice choiceWithText:@"Good" value:@(3)];
        ORKLegacyTextChoice *textChoice4 = [ORKLegacyTextChoice choiceWithText:@"Above Average" value:@(4)];
        ORKLegacyTextChoice *textChoice5 = [ORKLegacyTextChoice choiceWithText:@"Excellent" value:@(5)];
        
        NSArray *textChoices = @[textChoice1, textChoice2, textChoice3, textChoice4, textChoice5];
        
        ORKLegacyTextScaleAnswerFormat *scaleAnswerFormat = [ORKLegacyAnswerFormat textScaleAnswerFormatWithTextChoices:textChoices
                                                                                               defaultIndex:NSIntegerMax
                                                                                                   vertical:YES];
        
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"scale_15"
                                                                      title:@"How are you feeling today?"
                                                                     answer:scaleAnswerFormat];
        
        [steps addObject:step];
    }

    
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:ScalesTaskIdentifier steps:steps];
    return task;
    
}

- (void)scaleButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:ScalesTaskIdentifier];
}

- (id<ORKLegacyTask>)makeColorScalesTask {
    ORKLegacyOrderedTask *task = (ORKLegacyOrderedTask *)[self makeScalesTask];
    
    for (ORKLegacyQuestionStep *step in task.steps) {
        if ([step isKindOfClass:[ORKLegacyQuestionStep class]]) {
            ORKLegacyAnswerFormat *answerFormat  = step.answerFormat;
            if ([answerFormat respondsToSelector:@selector(setGradientColors:)]) {
                [answerFormat performSelector:@selector(setGradientColors:) withObject:@[[UIColor redColor],
                                                                                         [UIColor greenColor],
                                                                                         [UIColor greenColor],
                                                                                         [UIColor yellowColor],
                                                                                         [UIColor yellowColor]]];
                [answerFormat performSelector:@selector(setGradientLocations:) withObject:@[@0.2, @0.2, @0.7, @0.7, @0.8]];
            }
        }
    }
    
    return task;
}

- (void)scaleColorGradientButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:ColorScalesTaskIdentifier];
}

#pragma mark - Image choice task

/*
 Tests various uses of image choices.
 
 All these tests use square colored images to test layout correctness. In a real
 application you would use images to convey an image scale.
 
 Tests image choices both in form items, and in question steps.
 */
- (id<ORKLegacyTask>)makeImageChoicesTask {
    NSMutableArray *steps = [NSMutableArray new];
    
    for (NSValue *ratio in @[[NSValue valueWithCGPoint:CGPointMake(1.0, 1.0)], [NSValue valueWithCGPoint:CGPointMake(2.0, 1.0)], [NSValue valueWithCGPoint:CGPointMake(1.0, 2.0)]])
    {
        ORKLegacyFormStep *step = [[ORKLegacyFormStep alloc] initWithIdentifier:[NSString stringWithFormat:@"form_step_%@",NSStringFromCGPoint(ratio.CGPointValue)] title:@"Image Choices Form" text:@"Testing image choices in a form layout."];
        
        NSMutableArray *items = [NSMutableArray new];
        
        for (NSNumber *dimension in @[@(360), @(60)])
        {
            CGSize size1 = CGSizeMake(dimension.floatValue * ratio.CGPointValue.x, dimension.floatValue * ratio.CGPointValue.y);
            CGSize size2 = CGSizeMake(dimension.floatValue * ratio.CGPointValue.y, dimension.floatValue * ratio.CGPointValue.x);
            
            ORKLegacyImageChoice *option1 = [ORKLegacyImageChoice choiceWithNormalImage:[self imageWithColor:[UIColor redColor] size:size1 border:NO]
                                                              selectedImage:[self imageWithColor:[UIColor redColor] size:size1 border:YES]
                                                                       text:@"Red" value:@"red"];
            ORKLegacyImageChoice *option2 = [ORKLegacyImageChoice choiceWithNormalImage:[self imageWithColor:[UIColor orangeColor] size:size1 border:NO]
                                                              selectedImage:[self imageWithColor:[UIColor orangeColor] size:size1 border:YES]
                                                                       text:nil value:@"orange"];
            ORKLegacyImageChoice *option3 = [ORKLegacyImageChoice choiceWithNormalImage:[self imageWithColor:[UIColor yellowColor] size:size1 border:NO]
                                                              selectedImage:[self imageWithColor:[UIColor yellowColor] size:size1 border:YES]
                                                                       text:@"Yellow Yellow Yellow Yellow Yellow Yellow Yellow Yellow Yellow Yellow Yellow Yellow" value:@"yellow"];
            ORKLegacyImageChoice *option4 = [ORKLegacyImageChoice choiceWithNormalImage:[self imageWithColor:[UIColor greenColor] size:size2 border:NO]
                                                              selectedImage:[self imageWithColor:[UIColor greenColor] size:size2 border:YES]
                                                                       text:@"Green" value:@"green"];
            ORKLegacyImageChoice *option5 = [ORKLegacyImageChoice choiceWithNormalImage:[self imageWithColor:[UIColor blueColor] size:size1 border:NO]
                                                              selectedImage:[self imageWithColor:[UIColor blueColor] size:size1 border:YES]
                                                                       text:nil value:@"blue"];
            ORKLegacyImageChoice *option6 = [ORKLegacyImageChoice choiceWithNormalImage:[self imageWithColor:[UIColor cyanColor] size:size2 border:NO]
                                                              selectedImage:[self imageWithColor:[UIColor cyanColor] size:size2 border:YES]
                                                                       text:@"Cyan" value:@"cyanColor"];
            
            
            ORKLegacyFormItem *item1 = [[ORKLegacyFormItem alloc] initWithIdentifier:[@"fqid_009_1" stringByAppendingFormat:@"%@",dimension] text:@"Pick a color."
                                                            answerFormat:[ORKLegacyAnswerFormat choiceAnswerFormatWithImageChoices:@[option1] ]];
            [items addObject:item1];
            
            ORKLegacyFormItem *item2 = [[ORKLegacyFormItem alloc] initWithIdentifier:[@"fqid_009_2" stringByAppendingFormat:@"%@",dimension] text:@"Pick a color."
                                                            answerFormat:[ORKLegacyAnswerFormat choiceAnswerFormatWithImageChoices:@[option1, option2] ]];
            [items addObject:item2];
            
            ORKLegacyFormItem *item3 = [[ORKLegacyFormItem alloc] initWithIdentifier:[@"fqid_009_3" stringByAppendingFormat:@"%@",dimension] text:@"Pick a color."
                                                            answerFormat:[ORKLegacyAnswerFormat choiceAnswerFormatWithImageChoices:@[option1, option2, option3] ]];
            [items addObject:item3];
            
            ORKLegacyFormItem *item6 = [[ORKLegacyFormItem alloc] initWithIdentifier:[@"fqid_009_6" stringByAppendingFormat:@"%@",dimension] text:@"Pick a color."
                                                            answerFormat:[ORKLegacyAnswerFormat choiceAnswerFormatWithImageChoices:@[option1, option2, option3, option4, option5, option6] ]];
            [items addObject:item6];
        }
        
        [step setFormItems:items];
        [steps addObject:step];
        
        for (NSNumber *dimension in @[@(360), @(60), @(20)]) {
            CGSize size1 = CGSizeMake(dimension.floatValue * ratio.CGPointValue.x, dimension.floatValue * ratio.CGPointValue.y);
            CGSize size2 = CGSizeMake(dimension.floatValue * ratio.CGPointValue.y, dimension.floatValue * ratio.CGPointValue.x);

            ORKLegacyImageChoice *option1 = [ORKLegacyImageChoice choiceWithNormalImage:[self imageWithColor:[UIColor redColor] size:size1 border:NO]
                                                              selectedImage:[self imageWithColor:[UIColor redColor] size:size1 border:YES]
                                                                       text:@"Red\nRed\nRed\nRed" value:@"red"];
            ORKLegacyImageChoice *option2 = [ORKLegacyImageChoice choiceWithNormalImage:[self imageWithColor:[UIColor orangeColor] size:size1 border:NO]
                                                              selectedImage:[self imageWithColor:[UIColor orangeColor] size:size1 border:YES]
                                                                       text:@"Orange" value:@"orange"];
            ORKLegacyImageChoice *option3 = [ORKLegacyImageChoice choiceWithNormalImage:[self imageWithColor:[UIColor yellowColor] size:size1 border:NO]
                                                              selectedImage:[self imageWithColor:[UIColor yellowColor] size:size1 border:YES]
                                                                       text:@"Yellow Yellow Yellow Yellow Yellow Yellow Yellow Yellow Yellow Yellow" value:@"yellow"];
            ORKLegacyImageChoice *option4 = [ORKLegacyImageChoice choiceWithNormalImage:[self imageWithColor:[UIColor greenColor] size:size2 border:NO]
                                                              selectedImage:[self imageWithColor:[UIColor greenColor] size:size2 border:YES]
                                                                       text:@"Green" value:@"green"];
            ORKLegacyImageChoice *option5 = [ORKLegacyImageChoice choiceWithNormalImage:[self imageWithColor:[UIColor blueColor] size:size1 border:NO]
                                                              selectedImage:[self imageWithColor:[UIColor blueColor] size:size1 border:YES]
                                                                       text:@"Blue" value:@"blue"];
            ORKLegacyImageChoice *option6 = [ORKLegacyImageChoice choiceWithNormalImage:[self imageWithColor:[UIColor cyanColor] size:size2 border:NO]
                                                              selectedImage:[self imageWithColor:[UIColor cyanColor] size:size2 border:YES]
                                                                       text:@"Cyan" value:@"cyanColor"];
            
            ORKLegacyQuestionStep *step1 = [ORKLegacyQuestionStep questionStepWithIdentifier:[NSString stringWithFormat:@"qid_color1_%@_%@", NSStringFromCGPoint(ratio.CGPointValue), dimension]
                                                                           title:@"Pick a color."
                                                                          answer:[ORKLegacyAnswerFormat choiceAnswerFormatWithImageChoices:@[option1] ]];
            [steps addObject:step1];
            
            ORKLegacyQuestionStep *step2 = [ORKLegacyQuestionStep questionStepWithIdentifier:[NSString stringWithFormat:@"qid_color2_%@_%@", NSStringFromCGPoint(ratio.CGPointValue), dimension]
                                                                           title:@"Pick a color."
                                                                          answer:[ORKLegacyAnswerFormat choiceAnswerFormatWithImageChoices:@[option1, option2] ]];
            [steps addObject:step2];
            
            ORKLegacyQuestionStep *step3 = [ORKLegacyQuestionStep questionStepWithIdentifier:[NSString stringWithFormat:@"qid_color3_%@_%@", NSStringFromCGPoint(ratio.CGPointValue), dimension]
                                                                           title:@"Pick a color."
                                                                          answer:[ORKLegacyAnswerFormat choiceAnswerFormatWithImageChoices:@[option1, option2, option3] ]];
            [steps addObject:step3];
            
            ORKLegacyQuestionStep *step6 = [ORKLegacyQuestionStep questionStepWithIdentifier:[NSString stringWithFormat:@"qid_color6_%@_%@", NSStringFromCGPoint(ratio.CGPointValue), dimension]
                                                                           title:@"Pick a color."
                                                                          answer:[ORKLegacyAnswerFormat choiceAnswerFormatWithImageChoices:@[option1, option2, option3, option4, option5, option6]]];
            [steps addObject:step6];
        }
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"end"];
        step.title = @"Image Choices End";
        [steps addObject:step];
    }
    
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:ImageChoicesTaskIdentifier steps:steps];
    return task;
    
}

- (void)imageChoicesButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:ImageChoicesTaskIdentifier];
}

# pragma mark - Image Capture
- (id<ORKLegacyTask>)makeImageCaptureTask {
    NSMutableArray *steps = [NSMutableArray new];
    
    /*
     If implementing an image capture task like this one, remember that people will
     take your instructions literally. So, be cautious. Make sure your template image
     is high contrast and very visible against a variety of backgrounds.
     */
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"begin"];
        step.title = @"Hands";
        step.image = [[UIImage imageNamed:@"hands_solid"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        step.detailText = @"In this step we will capture images of both of your hands";
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"right1"];
        step.title = @"Right Hand";
        step.image = [[UIImage imageNamed:@"right_hand_solid"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        step.detailText = @"Let's start by capturing an image of your right hand";
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"right2"];
        step.title = @"Right Hand";
        step.image = [[UIImage imageNamed:@"right_hand_outline"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        step.detailText = @"Align your right hand with the on-screen outline and capture the image.  Be sure to place your hand over a contrasting background.  You can re-capture the image as many times as you need.";
        [steps addObject:step];
    }
    
    {
        ORKLegacyImageCaptureStep *step = [[ORKLegacyImageCaptureStep alloc] initWithIdentifier:@"right3"];
        step.templateImage = [UIImage imageNamed:@"right_hand_outline_big"];
        step.templateImageInsets = UIEdgeInsetsMake(0.05, 0.05, 0.05, 0.05);
        step.accessibilityInstructions = @"Extend your right hand, palm side down, one foot in front of your device. Tap the Capture Image button, or two-finger double tap the preview to capture the image";
        step.accessibilityHint = @"Captures the image visible in the preview";
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"left1"];
        step.title = @"Left Hand";
        step.image = [[UIImage imageNamed:@"left_hand_solid"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        step.detailText = @"Now let's capture an image of your left hand";
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"left2"];
        step.title = @"Left Hand";
        step.image = [[UIImage imageNamed:@"left_hand_outline"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        step.detailText = @"Align your left hand with the on-screen outline and capture the image.  Be sure to place your hand over a contrasting background.  You can re-capture the image as many times as you need.";
        [steps addObject:step];
    }
    
    {
        ORKLegacyImageCaptureStep *step = [[ORKLegacyImageCaptureStep alloc] initWithIdentifier:@"left3"];
        step.templateImage = [UIImage imageNamed:@"left_hand_outline_big"];
        step.templateImageInsets = UIEdgeInsetsMake(0.05, 0.05, 0.05, 0.05);
        step.accessibilityInstructions = @"Extend your left hand, palm side down, one foot in front of your device. Tap the Capture Image button, or two-finger double tap the preview to capture the image";
        step.accessibilityHint = @"Captures the image visible in the preview";
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"end"];
        step.title = @"Complete";
        step.detailText = @"Hand image capture complete";
        [steps addObject:step];
    }
    
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:ImageCaptureTaskIdentifier steps:steps];
    return task;
}

- (void)imageCaptureButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:ImageCaptureTaskIdentifier];
}

#pragma mark - Video Capture
- (id<ORKLegacyTask>)makeVideoCaptureTask {
    NSMutableArray *steps = [NSMutableArray new];
    
    /*
     If implementing an video capture task like this one, remember that people will
     take your instructions literally. So, be cautious. Make sure your template image
     is high contrast and very visible against a variety of backgrounds.
     */
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"begin"];
        step.title = @"Hands";
        step.image = [[UIImage imageNamed:@"hands_solid"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        step.detailText = @"In this step we will capture 5 second videos of both of your hands";
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"right1"];
        step.title = @"Right Hand";
        step.image = [[UIImage imageNamed:@"right_hand_solid"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        step.detailText = @"Let's start by capturing a video of your right hand";
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"right2"];
        step.title = @"Right Hand";
        step.image = [[UIImage imageNamed:@"right_hand_outline"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        step.detailText = @"Align your right hand with the on-screen outline and record the video.  Be sure to place your hand over a contrasting background.  You can re-capture the video as many times as you need.";
        [steps addObject:step];
    }
    
    {
        ORKLegacyVideoCaptureStep *step = [[ORKLegacyVideoCaptureStep alloc] initWithIdentifier:@"right3"];
        step.templateImage = [UIImage imageNamed:@"right_hand_outline_big"];
        step.templateImageInsets = UIEdgeInsetsMake(0.05, 0.05, 0.05, 0.05);
        step.duration = @5.0;
        step.accessibilityInstructions = @"Extend your right hand, palm side down, one foot in front of your device. Tap the Start Recording button, or two-finger double tap the preview to capture the video";
        step.accessibilityHint = @"Records the video visible in the preview";
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"left1"];
        step.title = @"Left Hand";
        step.image = [[UIImage imageNamed:@"left_hand_solid"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        step.detailText = @"Now let's capture a video of your left hand";
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"left2"];
        step.title = @"Left Hand";
        step.image = [[UIImage imageNamed:@"left_hand_outline"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        step.detailText = @"Align your left hand with the on-screen outline and record the video.  Be sure to place your hand over a contrasting background.  You can re-capture the video as many times as you need.";
        [steps addObject:step];
    }
    
    {
        ORKLegacyVideoCaptureStep *step = [[ORKLegacyVideoCaptureStep alloc] initWithIdentifier:@"left3"];
        step.templateImage = [UIImage imageNamed:@"left_hand_outline_big"];
        step.templateImageInsets = UIEdgeInsetsMake(0.05, 0.05, 0.05, 0.05);
        step.duration = @5.0;
        step.accessibilityInstructions = @"Extend your left hand, palm side down, one foot in front of your device. Tap the Start Recording button, or two-finger double tap the preview to capture the video";
        step.accessibilityHint = @"Records the video visible in the preview";
        [steps addObject:step];
    }
    
    {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"end"];
        step.title = @"Complete";
        step.detailText = @"Hand video capture complete";
        [steps addObject:step];
    }
    
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:VideoCaptureTaskIdentifier steps:steps];
    return task;
}

- (void)videoCaptureButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:VideoCaptureTaskIdentifier];
}


- (void)navigableOrderedTaskButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:NavigableOrderedTaskIdentifier];
}

- (void)navigableLoopTaskButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:NavigableLoopTaskIdentifier];
}

- (void)toggleTintColorButtonTapped:(id)sender {
    static UIColor *defaultTintColor = nil;
    if (!defaultTintColor) {
        defaultTintColor = self.view.tintColor;
    }
    if ([[UIView appearance].tintColor isEqual:[UIColor redColor]]) {
        [UIView appearance].tintColor = defaultTintColor;
    } else {
        [UIView appearance].tintColor = [UIColor redColor];
    }
    // Update appearance
    UIView *superview = self.view.superview;
    [self.view removeFromSuperview];
    [superview addSubview:self.view];
}

#pragma mark - Navigable Loop Task

- (id<ORKLegacyTask>)makeNavigableLoopTask {
    NSMutableArray *steps = [NSMutableArray new];
    
    ORKLegacyAnswerFormat *answerFormat = nil;
    ORKLegacyStep *step = nil;
    NSArray *textChoices = nil;
    ORKLegacyQuestionStep *questionStep = nil;
    
    // Intro step
    step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"introStep"];
    step.title = @"This task demonstrates an skippable step and an optional loop within a navigable ordered task";
    [steps addObject:step];

    // Skippable step
    answerFormat = [ORKLegacyAnswerFormat booleanAnswerFormat];
    questionStep = [ORKLegacyQuestionStep questionStepWithIdentifier:@"skipNextStep" title:@"Do you want to skip the next step?" answer:answerFormat];
    questionStep.optional = NO;
    [steps addObject:questionStep];

    step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"skippableStep"];
    step.title = @"You'll optionally skip this step";
    step.text = @"You should only see this step if you answered the previous question with 'No'";
    [steps addObject:step];
    
    // Loop target step
    step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"loopAStep"];
    step.title = @"You'll optionally return to this step";
    [steps addObject:step];

    // Branching paths
    textChoices =
    @[
      [ORKLegacyTextChoice choiceWithText:@"Scale" value:@"scale"],
      [ORKLegacyTextChoice choiceWithText:@"Text Choice" value:@"textchoice"]
      ];
    
    answerFormat = [ORKLegacyAnswerFormat choiceAnswerFormatWithStyle:ORKLegacyChoiceAnswerStyleSingleChoice
                                                    textChoices:textChoices];
    
    questionStep = [ORKLegacyQuestionStep questionStepWithIdentifier:@"branchingStep" title:@"Which kind of question do you prefer?" answer:answerFormat];
    questionStep.optional = NO;
    [steps addObject:questionStep];

    // Scale question step
    ORKLegacyContinuousScaleAnswerFormat *scaleAnswerFormat =  [ORKLegacyAnswerFormat continuousScaleAnswerFormatWithMaximumValue:10
                                                                                                         minimumValue:1
                                                                                                         defaultValue:8.725
                                                                                                maximumFractionDigits:3
                                                                                                             vertical:YES
                                                                                              maximumValueDescription:nil
                                                                                              minimumValueDescription:nil];
    
    step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"scaleStep"
                                                 title:@"On a scale of 1 to 10, what is your mood?"
                                                answer:scaleAnswerFormat];
    [steps addObject:step];
    
    // Text choice question step
    textChoices =
    @[
      [ORKLegacyTextChoice choiceWithText:@"Good" value:@"good"],
      [ORKLegacyTextChoice choiceWithText:@"Bad" value:@"bad"]
      ];
    
    answerFormat = [ORKLegacyAnswerFormat choiceAnswerFormatWithStyle:ORKLegacyChoiceAnswerStyleSingleChoice
                                                    textChoices:textChoices];
    
    questionStep = [ORKLegacyQuestionStep questionStepWithIdentifier:@"textChoiceStep" title:@"How is your mood?" answer:answerFormat];
    questionStep.optional = NO;
    [steps addObject:questionStep];

    // Loop conditional step
    answerFormat = [ORKLegacyAnswerFormat booleanAnswerFormat];
    step = [ORKLegacyQuestionStep questionStepWithIdentifier:@"loopBStep" title:@"Do you want to repeat the survey?" answer:answerFormat];
    step.optional = NO;
    [steps addObject:step];
    
    step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"endStep"];
    step.title = @"You have finished the task";
    [steps addObject:step];
    
    ORKLegacyNavigableOrderedTask *task = [[ORKLegacyNavigableOrderedTask alloc] initWithIdentifier:NavigableLoopTaskIdentifier
                                                                                  steps:steps];
    
    // Build navigation rules
    ORKLegacyResultSelector *resultSelector = nil;
    ORKLegacyPredicateStepNavigationRule *predicateRule = nil;
    ORKLegacyDirectStepNavigationRule *directRule = nil;
    ORKLegacyPredicateSkipStepNavigationRule *predicateSkipRule = nil;
    
    // skippable step
    resultSelector = [ORKLegacyResultSelector selectorWithResultIdentifier:@"skipNextStep"];
    NSPredicate *predicateSkipStep = [ORKLegacyResultPredicate predicateForBooleanQuestionResultWithResultSelector:resultSelector
                                                                                              expectedAnswer:YES];
    predicateSkipRule = [[ORKLegacyPredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicateSkipStep];
    [task setSkipNavigationRule:predicateSkipRule forStepIdentifier:@"skippableStep"];

    // From the branching step, go to either scaleStep or textChoiceStep
    resultSelector = [ORKLegacyResultSelector selectorWithResultIdentifier:@"branchingStep"];
    NSPredicate *predicateAnswerTypeScale = [ORKLegacyResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                                               expectedAnswerValue:@"scale"];
    predicateRule = [[ORKLegacyPredicateStepNavigationRule alloc] initWithResultPredicates:@[ predicateAnswerTypeScale ]
                                                          destinationStepIdentifiers:@[ @"scaleStep" ]
                                                               defaultStepIdentifier:@"textChoiceStep"];
    [task setNavigationRule:predicateRule forTriggerStepIdentifier:@"branchingStep"];
    
    // From the loopB step, return to loopA if user chooses so
    resultSelector = [ORKLegacyResultSelector selectorWithResultIdentifier:@"loopBStep"];
    NSPredicate *predicateLoopYes = [ORKLegacyResultPredicate predicateForBooleanQuestionResultWithResultSelector:resultSelector
                                                                                             expectedAnswer:YES];
    predicateRule = [[ORKLegacyPredicateStepNavigationRule alloc] initWithResultPredicates:@[ predicateLoopYes ]
                                                          destinationStepIdentifiers:@[ @"loopAStep" ] ];
    [task setNavigationRule:predicateRule forTriggerStepIdentifier:@"loopBStep"];
    
    // scaleStep to loopB direct navigation rule
    directRule = [[ORKLegacyDirectStepNavigationRule alloc] initWithDestinationStepIdentifier:@"loopBStep"];
    [task setNavigationRule:directRule forTriggerStepIdentifier:@"scaleStep"];
    
    return task;
}

#pragma mark - Custom navigation item task

- (id<ORKLegacyTask>)makeCustomNavigationItemTask {
    NSMutableArray *steps = [[NSMutableArray alloc] init];
    ORKLegacyInstructionStep *step1 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"customNavigationItemTask.step1"];
    step1.title = @"Custom Navigation Item Title";
    ORKLegacyInstructionStep *step2 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"customNavigationItemTask.step2"];
    step2.title = @"Custom Navigation Item Title View";
    [steps addObject: step1];
    [steps addObject: step2];
    return [[ORKLegacyOrderedTask alloc] initWithIdentifier: CustomNavigationItemTaskIdentifier steps:steps];
}

- (void)customNavigationItemButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:CustomNavigationItemTaskIdentifier];
}

#pragma mark - Passcode step and view controllers

/*
 Tests various uses of passcode step and view controllers.
 
 Passcode authentication and passcode editing are presented in
 the examples. Passcode creation would ideally be as part of
 the consent process.
 */

- (id<ORKLegacyTask>)makeCreatePasscodeTask {
    NSMutableArray *steps = [[NSMutableArray alloc] init];
    ORKLegacyPasscodeStep *passcodeStep = [[ORKLegacyPasscodeStep alloc] initWithIdentifier:@"consent_passcode"];
    passcodeStep.text = @"This passcode protects your privacy and ensures that the user giving consent is the one completing the tasks.";
    [steps addObject: passcodeStep];
    return [[ORKLegacyOrderedTask alloc] initWithIdentifier: CreatePasscodeTaskIdentifier steps:steps];
}

- (void)createPasscodeButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:CreatePasscodeTaskIdentifier];
}

- (void)removePasscodeButtonTapped:(id)sender {
    if ([ORKLegacyPasscodeViewController isPasscodeStoredInKeychain]) {
        if ([ORKLegacyPasscodeViewController removePasscodeFromKeychain]) {
            [self showAlertWithTitle:@"Success" message:@"Passcode removed."];
        } else {
            [self showAlertWithTitle:@"Error" message:@"Passcode could not be removed."];
        }
    } else {
        [self showAlertWithTitle:@"Error" message:@"There is no passcode stored in the keychain."];
    }
}

- (void)authenticatePasscodeButtonTapped:(id)sender {
    if ([ORKLegacyPasscodeViewController isPasscodeStoredInKeychain]) {
        ORKLegacyPasscodeViewController *viewController = [ORKLegacyPasscodeViewController
                                                     passcodeAuthenticationViewControllerWithText:@"Authenticate your passcode in order to proceed."
                                                     delegate:self];
        [self presentViewController:viewController animated:YES completion:nil];
    } else {
        [self showAlertWithTitle:@"Error" message:@"A passcode must be created before you can authenticate it."];
    }
}

- (void)editPasscodeButtonTapped:(id)sender {
    if ([ORKLegacyPasscodeViewController isPasscodeStoredInKeychain]) {
        ORKLegacyPasscodeViewController *viewController = [ORKLegacyPasscodeViewController passcodeEditingViewControllerWithText:nil
                                                                                                            delegate:self
                                                                                                        passcodeType:ORKLegacyPasscodeType6Digit];
        [self presentViewController:viewController animated:YES completion:nil];
    } else {
        [self showAlertWithTitle:@"Error" message:@"A passcode must be created before you can edit it."];
    }
}

#pragma mark - Passcode delegate

- (void)passcodeViewControllerDidFailAuthentication:(UIViewController *)viewController {
    NSLog(@"Passcode authentication failed.");
    [self showAlertWithTitle:@"Error" message:@"Passcode authentication failed"];
}

- (void)passcodeViewControllerDidFinishWithSuccess:(UIViewController *)viewController {
    NSLog(@"New passcode saved.");
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)passcodeViewControllerDidCancel:(UIViewController *)viewController {
    NSLog(@"User tapped the cancel button.");
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)passcodeViewControllerForgotPasscodeTapped:(UIViewController *)viewController {
    NSLog(@"Forgot Passcode tapped.");
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Forgot Passcode"
                                                                   message:@"Forgot Passcode tapped."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [viewController presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Review step

- (NSArray<ORKLegacyStep *> *)stepsForReviewTasks {
    // ORKLegacyInstructionStep
    ORKLegacyInstructionStep *instructionStep = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"instructionStep"];
    instructionStep.title = @"Review Task";
    instructionStep.text = @"The task demonstrates the usage of ORKLegacyReviewStep within a task";
    NSMutableArray<ORKLegacyTextChoice *> *textChoices = [[NSMutableArray alloc] init];
    [textChoices addObject:[[ORKLegacyTextChoice alloc] initWithText:@"Good" detailText:@"" value:[NSNumber numberWithInt:0] exclusive:NO]];
    [textChoices addObject:[[ORKLegacyTextChoice alloc] initWithText:@"Average" detailText:@"" value:[NSNumber numberWithInt:1] exclusive:NO]];
    [textChoices addObject:[[ORKLegacyTextChoice alloc] initWithText:@"Poor" detailText:@"" value:[NSNumber numberWithInt:2] exclusive:NO]];
    ORKLegacyQuestionStep *step1 = [ORKLegacyQuestionStep questionStepWithIdentifier:@"step1" title:@"How do you feel today?" answer:[ORKLegacyAnswerFormat valuePickerAnswerFormatWithTextChoices:textChoices]];
    // ORKLegacyImageChoiceAnswerFormat
    NSMutableArray<ORKLegacyImageChoice *> *imageChoices = [[NSMutableArray alloc] init];
    [imageChoices addObject:[[ORKLegacyImageChoice alloc] initWithNormalImage:[UIImage imageNamed:@"left_hand_outline"] selectedImage:[UIImage imageNamed:@"left_hand_solid"] text:@"Left hand" value:[NSNumber numberWithInt:1]]];
    [imageChoices addObject:[[ORKLegacyImageChoice alloc] initWithNormalImage:[UIImage imageNamed:@"right_hand_outline"] selectedImage:[UIImage imageNamed:@"right_hand_solid"] text:@"Right hand" value:[NSNumber numberWithInt:0]]];
    ORKLegacyQuestionStep *step2 = [ORKLegacyQuestionStep questionStepWithIdentifier:@"step2" title:@"Which hand was injured?" answer:[ORKLegacyAnswerFormat choiceAnswerFormatWithImageChoices:imageChoices]];
    // ORKLegacyTextChoiceAnswerFormat
    ORKLegacyQuestionStep *step3 = [ORKLegacyQuestionStep questionStepWithIdentifier:@"step3" title:@"How do you feel today?" answer:[ORKLegacyAnswerFormat choiceAnswerFormatWithStyle:ORKLegacyChoiceAnswerStyleSingleChoice textChoices:textChoices]];
    // ORKLegacyBooleanAnswerFormat
    ORKLegacyQuestionStep *step4 = [ORKLegacyQuestionStep questionStepWithIdentifier:@"step4" title:@"Are you at least 18 years old?" answer:[ORKLegacyAnswerFormat booleanAnswerFormat]];
    // ORKLegacyTimeOfDayAnswerFormat
    ORKLegacyQuestionStep *step5 = [ORKLegacyQuestionStep questionStepWithIdentifier:@"step5" title:@"When did you wake up today?" answer:[ORKLegacyAnswerFormat timeOfDayAnswerFormat]];
    // ORKLegacyDateAnswerFormat
    ORKLegacyQuestionStep *step6 = [ORKLegacyQuestionStep questionStepWithIdentifier:@"step6" title:@"When is your birthday?" answer:[ORKLegacyAnswerFormat dateAnswerFormat]];
    // ORKLegacyFormStep
    ORKLegacyFormStep *formStep = [[ORKLegacyFormStep alloc] initWithIdentifier:@"formStep" title:@"Survey" text:@"Please answer the following set of questions"];
    ORKLegacyFormItem *formItem1 = [[ORKLegacyFormItem alloc] initWithIdentifier:@"formItem1" text:@"How do you feel today?" answerFormat:[ORKLegacyAnswerFormat choiceAnswerFormatWithStyle:ORKLegacyChoiceAnswerStyleSingleChoice textChoices:textChoices]];
    ORKLegacyFormItem *formItem2 = [[ORKLegacyFormItem alloc] initWithIdentifier:@"formItem2" text:@"Are you pregnant?" answerFormat:[ORKLegacyAnswerFormat booleanAnswerFormat]];
    formStep.formItems = @[formItem1, formItem2];
    // ORKLegacyReviewStep
    ORKLegacyReviewStep *reviewStep = [ORKLegacyReviewStep embeddedReviewStepWithIdentifier:@"embeddedReviewStep"];
    reviewStep.title = @"Review";
    reviewStep.text = @"Review your answers";
    // ORKLegacyNumericAnswerFormat
    ORKLegacyQuestionStep *step7 = [ORKLegacyQuestionStep questionStepWithIdentifier:@"step7" title:@"How many children do you have?" answer:[ORKLegacyAnswerFormat integerAnswerFormatWithUnit:@"children"]];
    // ORKLegacyScaleAnswerFormat
    ORKLegacyQuestionStep *step8 = [ORKLegacyQuestionStep questionStepWithIdentifier:@"step8" title:@"On a scale from 1 to 10: How do you feel today?" answer:[ORKLegacyAnswerFormat scaleAnswerFormatWithMaximumValue:10 minimumValue:1 defaultValue:6 step:1 vertical:NO maximumValueDescription:@"Excellent" minimumValueDescription:@"Poor"]];
    // ORKLegacyContinousScaleAnswerFormat
    ORKLegacyQuestionStep *step9 = [ORKLegacyQuestionStep questionStepWithIdentifier:@"step9" title:@"On a scale from 1 to 10: How do you feel today?" answer:[ORKLegacyAnswerFormat continuousScaleAnswerFormatWithMaximumValue:10 minimumValue:1 defaultValue:6 maximumFractionDigits:2 vertical:NO maximumValueDescription:@"Excellent" minimumValueDescription:@"Poor"]];
    // ORKLegacyTextScaleAnswerFormat
    ORKLegacyQuestionStep *step10 = [ORKLegacyQuestionStep questionStepWithIdentifier:@"step10" title:@"How do you feel today?" answer:[ORKLegacyAnswerFormat textScaleAnswerFormatWithTextChoices:textChoices defaultIndex:0 vertical:NO]];
    // ORKLegacyTextAnswerFormat
    ORKLegacyQuestionStep *step11 = [ORKLegacyQuestionStep questionStepWithIdentifier:@"step11" title:@"What books do you like best?" answer:[ORKLegacyAnswerFormat textAnswerFormat]];
    // ORKLegacyEmailAnswerFormat
    ORKLegacyQuestionStep *step12 = [ORKLegacyQuestionStep questionStepWithIdentifier:@"step12" title:@"What is your e-mail address?" answer:[ORKLegacyAnswerFormat emailAnswerFormat]];
    // ORKLegacyTimeIntervalAnswerFormat
    ORKLegacyQuestionStep *step13 = [ORKLegacyQuestionStep questionStepWithIdentifier:@"step13" title:@"How many hours did you sleep last night?" answer:[ORKLegacyAnswerFormat timeIntervalAnswerFormat]];
    // ORKLegacyHeightAnswerFormat
    ORKLegacyQuestionStep *step14 = [ORKLegacyQuestionStep questionStepWithIdentifier:@"step14" title:@"What is your height?" answer:[ORKLegacyAnswerFormat heightAnswerFormat]];
    // ORKLegacyWeightAnswerFormat
    ORKLegacyQuestionStep *step15 = [ORKLegacyQuestionStep questionStepWithIdentifier:@"step15" title:@"What is your weight?" answer:[ORKLegacyAnswerFormat weightAnswerFormat]];
    // ORKLegacyLocationAnswerFormat
    ORKLegacyQuestionStep *step16 = [ORKLegacyQuestionStep questionStepWithIdentifier:@"step16" title:@"Where do you live?" answer:[ORKLegacyAnswerFormat locationAnswerFormat]];

    return @[instructionStep, step1, step2, step3, step4, step5, step6, formStep, reviewStep, step7, step8, step9, step10, step11, step12, step13, step14, step15, step16];
}

- (id<ORKLegacyTask>)makeEmbeddedReviewTask {
    // ORKLegacyValuePickerAnswerFormat
    NSMutableArray<ORKLegacyStep *> *steps = [[NSMutableArray alloc] initWithArray:[self stepsForReviewTasks]];
    ORKLegacyReviewStep *reviewStep = [ORKLegacyReviewStep embeddedReviewStepWithIdentifier:@"reviewStep"];
    reviewStep.title = @"Review";
    reviewStep.text = @"Review your answers";
    [steps addObject:reviewStep];
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:EmbeddedReviewTaskIdentifier steps:steps];
    return task;
}

- (IBAction)embeddedReviewTaskButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:EmbeddedReviewTaskIdentifier];
}

- (id<ORKLegacyTask>)makeStandaloneReviewTask {
    NSMutableArray<ORKLegacyStep *> *steps = [[NSMutableArray alloc] initWithArray:[self stepsForReviewTasks]];
    ORKLegacyReviewStep *reviewStep = [ORKLegacyReviewStep standaloneReviewStepWithIdentifier:@"reviewStep" steps:steps resultSource:_embeddedReviewTaskResult];
    reviewStep.title = @"Review";
    reviewStep.text = @"Review your answers from your last survey";
    reviewStep.excludeInstructionSteps = YES;
    return [[ORKLegacyOrderedTask alloc] initWithIdentifier:StandaloneReviewTaskIdentifier steps:@[reviewStep]];
}

- (IBAction)standaloneReviewTaskButtonTapped:(id)sender {
    if (_embeddedReviewTaskResult != nil) {
        [self beginTaskWithIdentifier:StandaloneReviewTaskIdentifier];
    } else {
        [self showAlertWithTitle:@"Alert" message:@"Please run embedded review task first"];
    }
}

#pragma mark - Helpers

/*
 Shows an alert.
 
 Used to display an alert with the provided title and message.
 
 @param title       The title text for the alert.
 @param message     The message text for the alert.
 */
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
 
/*
 Builds a test consent document.
 */
- (ORKLegacyConsentDocument *)buildConsentDocument {
    ORKLegacyConsentDocument *consent = [[ORKLegacyConsentDocument alloc] init];
    
    /*
     If you have HTML review content, you can substitute it for the
     concatenation of sections by doing something like this:
     consent.htmlReviewContent = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:XXX ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];
     */
    
    /*
     Title that will be shown in the generated document.
     */
    consent.title = @"Demo Consent";
    
    
    /*
     Signature page content, used in the generated document above the signatures.
     */
    consent.signaturePageTitle = @"Consent";
    consent.signaturePageContent = @"I agree  to participate in this research Study.";
    
    /*
     The empty signature that the user will fill in.
     */
    ORKLegacyConsentSignature *participantSig = [ORKLegacyConsentSignature signatureForPersonWithTitle:@"Participant" dateFormatString:nil identifier:@"participantSig"];
    [consent addSignature:participantSig];
    
    /*
     Pre-populated investigator's signature.
     */
    ORKLegacyConsentSignature *investigatorSig = [ORKLegacyConsentSignature signatureForPersonWithTitle:@"Investigator" dateFormatString:nil identifier:@"investigatorSig" givenName:@"Jake" familyName:@"Clemson" signatureImage:[UIImage imageNamed:@"signature"] dateString:@"9/2/14" ];
    [consent addSignature:investigatorSig];
    
    /*
     These are the set of consent sections that have pre-defined animations and
     images.
     
     We will create a section for each of the section types, and then add a custom
     section on the end.
     */
    NSArray *scenes = @[@(ORKLegacyConsentSectionTypeOverview),
                        @(ORKLegacyConsentSectionTypeDataGathering),
                        @(ORKLegacyConsentSectionTypePrivacy),
                        @(ORKLegacyConsentSectionTypeDataUse),
                        @(ORKLegacyConsentSectionTypeTimeCommitment),
                        @(ORKLegacyConsentSectionTypeStudySurvey),
                        @(ORKLegacyConsentSectionTypeStudyTasks),
                        @(ORKLegacyConsentSectionTypeWithdrawing)];
    
    NSMutableArray *sections = [NSMutableArray new];
    for (NSNumber *type in scenes) {
        NSString *summary = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam adhuc, meo fortasse vitio, quid ego quaeram non perspicis. Plane idem, inquit, et maxima quidem, qua fieri nulla maior potest. Quonam, inquit, modo? An potest, inquit ille, quicquam esse suavius quam nihil dolere? Cave putes quicquam esse verius. Quonam, inquit, modo? Et doming eirmod delicata cum. Vel fabellas scribentur neglegentur cu, pro te iudicabit explicari. His alia idque scriptorem ei, quo no nominavi noluisse.";
        ORKLegacyConsentSection *consentSection = [[ORKLegacyConsentSection alloc] initWithType:type.integerValue];
        consentSection.summary = summary;
        
        if (type.integerValue == ORKLegacyConsentSectionTypeOverview) {
            /*
             Tests HTML content instead of text for Learn More.
             */
            consentSection.htmlContent = @"<ul><li>Lorem</li><li>ipsum</li><li>dolor</li></ul><p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam adhuc, meo fortasse vitio, quid ego quaeram non perspicis. Plane idem, inquit, et maxima quidem, qua fieri nulla maior potest. Quonam, inquit, modo?</p>\
                <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam adhuc, meo fortasse vitio, quid ego quaeram non perspicis. Plane idem, inquit, et maxima quidem, qua fieri nulla maior potest. Quonam, inquit, modo?</p> 研究";
        } else if (type.integerValue == ORKLegacyConsentSectionTypeDataGathering) {
            /*
             Tests PDF content instead of text, HTML for Learn More.
             */
            NSString *path = [[NSBundle mainBundle] pathForResource:@"SAMPLE_PDF_TEST" ofType:@"pdf"];
            consentSection.contentURL = [NSURL URLWithString:path];

        } else {
            /*
             Tests text Learn More content.
             */
            consentSection.content = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam adhuc, meo fortasse vitio, quid ego quaeram non perspicis. Plane idem, inquit, et maxima quidem, qua fieri nulla maior potest. Quonam, inquit, modo? An potest, inquit ille, quicquam esse suavius quam nihil dolere? Cave putes quicquam esse verius. Quonam, inquit, modo?\
                Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam adhuc, meo fortasse vitio, quid ego quaeram non perspicis. Plane idem, inquit, et maxima quidem, qua fieri nulla maior potest. Quonam, inquit, modo?\
                An potest, inquit ille, quicquam esse suavius quam nihil dolere? Cave putes quicquam esse verius. Quonam, inquit, modo? Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam adhuc, meo fortasse vitio, quid ego quaeram non perspicis. Plane idem, inquit, et maxima quidem, qua fieri nulla maior potest. Quonam, inquit, modo?\
                An potest, inquit ille, quicquam esse suavius quam nihil dolere? Cave putes quicquam esse verius. Quonam, inquit, modo? Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam adhuc, meo fortasse vitio, quid ego quaeram non perspicis. Plane idem, inquit, et maxima quidem, qua fieri nulla maior potest. Quonam, inquit, modo? An potest, inquit ille, quicquam esse suavius quam nihil dolere? Cave putes quicquam esse verius. Quonam, inquit, modo?\
                Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam adhuc, meo fortasse vitio, quid ego quaeram non perspicis. Plane idem, inquit, et maxima quidem, qua fieri nulla maior potest. Quonam, inquit, modo?\
                An potest, inquit ille, quicquam esse suavius quam nihil dolere? Cave putes quicquam esse verius. Quonam, inquit, modo?";
        }
        
        [sections addObject:consentSection];
    }
    
    {
        /*
         A custom consent scene. This doesn't demo it but you can also set a custom
         animation.
         */
        ORKLegacyConsentSection *consentSection = [[ORKLegacyConsentSection alloc] initWithType:ORKLegacyConsentSectionTypeCustom];
        consentSection.summary = @"Custom Scene summary";
        consentSection.title = @"Custom Scene";
        consentSection.customImage = [UIImage imageNamed:@"image_example.png"];
        consentSection.customLearnMoreButtonTitle = @"Learn more about customizing ResearchKit";
        consentSection.content = @"You can customize ResearchKit a lot!";
        [sections addObject:consentSection];
    }
    
    {
        /*
         An "only in document" scene. This is ignored for visual consent, but included in
         the concatenated document for review.
         */
        ORKLegacyConsentSection *consentSection = [[ORKLegacyConsentSection alloc] initWithType:ORKLegacyConsentSectionTypeOnlyInDocument];
        consentSection.summary = @"OnlyInDocument Scene summary";
        consentSection.title = @"OnlyInDocument Scene";
        consentSection.content = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam adhuc, meo fortasse vitio, quid ego quaeram non perspicis. Plane idem, inquit, et maxima quidem, qua fieri nulla maior potest. Quonam, inquit, modo? An potest, inquit ille, quicquam esse suavius quam nihil dolere? Cave putes quicquam esse verius. Quonam, inquit, modo?";
        [sections addObject:consentSection];
    }
    
    consent.sections = [sections copy];
    return consent;
}

/*
 A helper for creating square colored images, which can optionally have a border.
 
 Used for testing the image choices answer format.
 
 @param color   Color to use for the image.
 @param size    Size of image.
 @param border  Boolean value indicating whether to add a black border around the image.
 
 @return An image.
 */
- (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size border:(BOOL)border {
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    
    view.backgroundColor = color;
    
    if (border) {
        view.layer.borderColor = [[UIColor blackColor] CGColor];
        view.layer.borderWidth = 5.0;
    }

    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

#pragma mark - Managing the task view controller

/*
 Dismisses the task view controller.
 */
- (void)dismissTaskViewController:(ORKLegacyTaskViewController *)taskViewController removeOutputDirectory:(BOOL)removeOutputDirectory {
    _currentDocument = nil;
    
    NSURL *outputDirectoryURL = taskViewController.outputDirectory;
    [self dismissViewControllerAnimated:YES completion:^{
        if (outputDirectoryURL && removeOutputDirectory)
        {
            /*
             We attempt to clean up the output directory.
             
             This is only useful for a test app, where we don't care about the
             data after the test is complete. In a real application, only
             delete your data when you've processed it or sent it to a server.
             */
            NSError *err = nil;
            if (![[NSFileManager defaultManager] removeItemAtURL:outputDirectoryURL error:&err]) {
                NSLog(@"Error removing %@: %@", outputDirectoryURL, err);
            }
        }
    }];
}

#pragma mark - ORKLegacyTaskViewControllerDelegate

/*
 Any step can have "Learn More" content.
 
 For testing, we return YES only for instruction steps, except on the active
 tasks.
 */
- (BOOL)taskViewController:(ORKLegacyTaskViewController *)taskViewController hasLearnMoreForStep:(ORKLegacyStep *)step {
    NSString *task_identifier = taskViewController.task.identifier;

    return ([step isKindOfClass:[ORKLegacyInstructionStep class]]
            && NO == [@[AudioTaskIdentifier, FitnessTaskIdentifier, GaitTaskIdentifier, TwoFingerTapTaskIdentifier, NavigableOrderedTaskIdentifier, NavigableLoopTaskIdentifier] containsObject:task_identifier]);
}

/*
 When the user taps on "Learn More" on a step, respond on this delegate callback.
 In this test app, we just print to the console.
 */
- (void)taskViewController:(ORKLegacyTaskViewController *)taskViewController learnMoreForStep:(ORKLegacyStepViewController *)stepViewController {
    NSLog(@"Learn more tapped for step %@", stepViewController.step.identifier);
}

- (BOOL)taskViewController:(ORKLegacyTaskViewController *)taskViewController shouldPresentStep:(ORKLegacyStep *)step {
    if ([ step.identifier isEqualToString:@"itid_002"]) {
        /*
         Tests interrupting navigation from the task view controller delegate.
         
         This is an example of preventing a user from proceeding if they don't
         enter a valid answer.
         */
        
        ORKLegacyQuestionResult *questionResult = (ORKLegacyQuestionResult *)[[[taskViewController result] stepResultForStepIdentifier:@"itid_001"] firstResult];
        if (questionResult == nil || [(NSNumber *)questionResult.answer integerValue] < 18) {
            UIAlertController *alertViewController =
            [UIAlertController alertControllerWithTitle:@"Warning"
                                                message:@"You can't participate if you are under 18."
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            
            UIAlertAction *ok = [UIAlertAction
                                 actionWithTitle:@"OK"
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action)
                                 {
                                     [alertViewController dismissViewControllerAnimated:YES completion:nil];
                                 }];
            
            
            [alertViewController addAction:ok];
            
            [taskViewController presentViewController:alertViewController animated:NO completion:nil];
            return NO;
        }
    }
    return YES;
}

/*
 In `stepViewControllerWillAppear:`, it is possible to significantly customize
 the behavior of the step view controller. In this test app, we do a few funny
 things to push the limits of this customization.
 */
- (void)taskViewController:(ORKLegacyTaskViewController *)taskViewController
stepViewControllerWillAppear:(ORKLegacyStepViewController *)stepViewController {
    
    if ([stepViewController.step.identifier isEqualToString:@"aid_001c"]) {
        /*
         Tests adding a custom view to a view controller for an active step, without
         subclassing.
         
         This is possible, but not recommended. A better choice would be to create
         a custom active step subclass and a matching active step view controller
         subclass, so you completely own the view controller and its appearance.
         */
        
        UIView *customView = [UIView new];
        customView.backgroundColor = [UIColor cyanColor];
        
        // Have the custom view request the space it needs.
        // A little tricky because we need to let it size to fit if there's not enough space.
        customView.translatesAutoresizingMaskIntoConstraints = NO;
        NSArray *verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[c(>=160)]"
                                                                               options:(NSLayoutFormatOptions)0
                                                                               metrics:nil
                                                                                 views:@{@"c":customView}];
        for (NSLayoutConstraint *constraint in verticalConstraints)
        {
            constraint.priority = UILayoutPriorityFittingSizeLevel;
        }
        [NSLayoutConstraint activateConstraints:verticalConstraints];
        [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[c(>=280)]"
                                                                                        options:(NSLayoutFormatOptions)0
                                                                                        metrics:nil
                                                                                          views:@{@"c":customView}]];
        
        [(ORKLegacyActiveStepViewController *)stepViewController setCustomView:customView];
        
        // Set custom button on navigation bar
        stepViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Custom button"
                                                                                               style:UIBarButtonItemStylePlain
                                                                                              target:nil
                                                                                              action:nil];
    } else if ([stepViewController.step.identifier hasPrefix:@"question_"]
               && ![stepViewController.step.identifier hasSuffix:@"6"]) {
        /*
         Tests customizing continue button ("some of the time").
         */
        stepViewController.continueButtonTitle = @"Next Question";
    } else if ([stepViewController.step.identifier isEqualToString:@"mini_form_001"]) {
        /*
         Tests customizing continue and learn more buttons.
         */
        stepViewController.continueButtonTitle = @"Try Mini Form";
        stepViewController.learnMoreButtonTitle = @"Learn more about this survey";
    } else if ([stepViewController.step.identifier isEqualToString: @"qid_001"]) {
        /*
         Example of customizing the back and cancel buttons in a way that's
         visibly obvious.
         */
        stepViewController.backButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back1"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:stepViewController.backButtonItem.target
                                                                            action:stepViewController.backButtonItem.action];
        stepViewController.cancelButtonItem.title = @"Cancel1";
    } else if ([stepViewController.step.identifier isEqualToString:@"customNavigationItemTask.step1"]) {
        stepViewController.navigationItem.title = @"Custom title";
    } else if ([stepViewController.step.identifier isEqualToString:@"customNavigationItemTask.step2"]) {
        NSMutableArray *items = [[NSMutableArray alloc] init];
        [items addObject:@"Item1"];
        [items addObject:@"Item2"];
        [items addObject:@"Item3"];
        stepViewController.navigationItem.titleView = [[UISegmentedControl alloc] initWithItems:items];
    } else if ([stepViewController.step.identifier isEqualToString:@"waitTask.step2"]) {
        // Indeterminate step
        [((ORKLegacyWaitStepViewController *)stepViewController) performSelector:@selector(updateText:) withObject:@"Updated text" afterDelay:2.0];
        [((ORKLegacyWaitStepViewController *)stepViewController) performSelector:@selector(goForward) withObject:nil afterDelay:5.0];
    } else if ([stepViewController.step.identifier isEqualToString:@"waitTask.step4"]) {
        // Determinate step
        [self updateProgress:0.0 waitStepViewController:((ORKLegacyWaitStepViewController *)stepViewController)];
    } else if ([stepViewController.step.identifier isEqualToString:@"completionStepWithDoneButton"] &&
               [stepViewController isKindOfClass:[ORKLegacyCompletionStepViewController class]]) {
        ((ORKLegacyCompletionStepViewController*)stepViewController).shouldShowContinueButton = YES;
    }

}

/*
 We support save and restore on all of the tasks in this test app.
 
 In a real app, not all tasks necessarily ought to support saving -- for example,
 active tasks that can't usefully be restarted after a significant time gap
 should not support save at all.
 */
- (BOOL)taskViewControllerSupportsSaveAndRestore:(ORKLegacyTaskViewController *)taskViewController {
    return YES;
}

/*
 In almost all cases, we want to dismiss the task view controller.
 
 In this test app, we don't dismiss on a fail (we just log it).
 */
- (void)taskViewController:(ORKLegacyTaskViewController *)taskViewController didFinishWithReason:(ORKLegacyTaskViewControllerFinishReason)reason error:(NSError *)error {
    switch (reason) {
        case ORKLegacyTaskViewControllerFinishReasonCompleted:
            if ([taskViewController.task.identifier isEqualToString:EmbeddedReviewTaskIdentifier]) {
                _embeddedReviewTaskResult = taskViewController.result;
            }
            [self taskViewControllerDidComplete:taskViewController];
            break;
        case ORKLegacyTaskViewControllerFinishReasonFailed:
            NSLog(@"Error on step %@: %@", taskViewController.currentStepViewController.step, error);
            break;
        case ORKLegacyTaskViewControllerFinishReasonDiscarded:
            if ([taskViewController.task.identifier isEqualToString:EmbeddedReviewTaskIdentifier]) {
                _embeddedReviewTaskResult = nil;
            }
            [self dismissTaskViewController:taskViewController removeOutputDirectory:YES];
            break;
        case ORKLegacyTaskViewControllerFinishReasonSaved:
        {
            if ([taskViewController.task.identifier isEqualToString:EmbeddedReviewTaskIdentifier]) {
                _embeddedReviewTaskResult = taskViewController.result;
            }
            /*
             Save the restoration data, dismiss the task VC, and do an early return
             so we don't clear the restoration data.
             */
            id<ORKLegacyTask> task = taskViewController.task;
            _savedViewControllers[task.identifier] = taskViewController.restorationData;
            [self dismissTaskViewController:taskViewController removeOutputDirectory:NO];
            return;
        }
            break;
            
        default:
            break;
    }
    
    [_savedViewControllers removeObjectForKey:taskViewController.task.identifier];
    _taskViewController = nil;
}

/*
 When a task completes, we pretty-print the result to the console.
 
 This is ok for testing, but if what you want to do is see the results of a task,
 the `ORKLegacyCatalog` Swift sample app might be a better choice, since it lets
 you navigate through the result structure.
 */
- (void)taskViewControllerDidComplete:(ORKLegacyTaskViewController *)taskViewController {
    
    NSLog(@"[ORKLegacyTest] task results: %@", taskViewController.result);
    
    // Validate the results
    NSArray *results = taskViewController.result.results;
    if (results) {
        NSSet *uniqueResults = [NSSet setWithArray:results];
        BOOL allResultsUnique = (results.count == uniqueResults.count);
        NSAssert(allResultsUnique, @"The returned results have duplicates of the same object.");
    }
    
    if (_currentDocument) {
        /*
         This demonstrates how to take a signature result, apply it to a document,
         and then generate a PDF From the document that includes the signature.
         */
        
        // Search for the review step.
        NSArray *steps = [(ORKLegacyOrderedTask *)taskViewController.task steps];
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"self isKindOfClass: %@", [ORKLegacyConsentReviewStep class]];
        ORKLegacyStep *reviewStep = [[steps filteredArrayUsingPredicate:predicate] firstObject];
        ORKLegacyConsentSignatureResult *signatureResult = (ORKLegacyConsentSignatureResult *)[[[taskViewController result] stepResultForStepIdentifier:reviewStep.identifier] firstResult];
        
        [signatureResult applyToDocument:_currentDocument];
        
        [_currentDocument makePDFWithCompletionHandler:^(NSData *pdfData, NSError *error) {
            NSLog(@"Created PDF of size %lu (error = %@)", (unsigned long)pdfData.length, error);
            
            if (!error) {
                NSURL *documents = [NSURL fileURLWithPath:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject];
                NSURL *outputUrl = [documents URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.pdf", taskViewController.taskRunUUID.UUIDString]];
                
                [pdfData writeToURL:outputUrl atomically:YES];
                NSLog(@"Wrote PDF to %@", [outputUrl path]);
            }
        }];
        
        _currentDocument = nil;
    }
    
    NSURL *dir = taskViewController.outputDirectory;
    [self dismissViewControllerAnimated:YES completion:^{
        if (dir)
        {
            NSError *err = nil;
            if (![[NSFileManager defaultManager] removeItemAtURL:dir error:&err]) {
                NSLog(@"Error removing %@: %@", dir, err);
            }
        }
    }];
}

/**
  When a task has completed it calls this method to post the result of the task to the delegate.
*/
- (void)taskViewController:(ORKLegacyTaskViewController *)taskViewController didChangeResult:(ORKLegacyTaskResult *)result {
    /*
     Upon creation of a Passcode by a user, the results of their creation
     are returned by getting it from ORKLegacyPasscodeResult in this delegate call.
     This is triggered upon completion/failure/or cancel
     */
    ORKLegacyStepResult *stepResult = (ORKLegacyStepResult *)[[result results] firstObject];
    if ([[[stepResult results] firstObject] isKindOfClass:[ORKLegacyPasscodeResult class]]) {
        ORKLegacyPasscodeResult *passcodeResult = (ORKLegacyPasscodeResult *)[[stepResult results] firstObject];
        NSLog(@"passcode saved: %d , Touch ID Enabled: %d", passcodeResult.passcodeSaved, passcodeResult.touchIdEnabled);

    }
}

- (void)taskViewController:(ORKLegacyTaskViewController *)taskViewController stepViewControllerWillDisappear:(ORKLegacyStepViewController *)stepViewController navigationDirection:(ORKLegacyStepViewControllerNavigationDirection)direction {
    if ([taskViewController.task.identifier isEqualToString:StepWillDisappearTaskIdentifier] &&
        [stepViewController.step.identifier isEqualToString:StepWillDisappearFirstStepIdentifier]) {
        taskViewController.view.tintColor = [UIColor magentaColor];
    }
}

#pragma mark - UI state restoration

/*
 UI state restoration code for the MainViewController.
 
 The MainViewController needs to be able to re-create the exact task that
 was being done, in order for the task view controller to restore correctly.
 
 In a real app implementation, this might mean that you would also need to save
 and restore the actual task; here, since we know the tasks don't change during
 testing, we just re-create the task.
 */
- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:_taskViewController forKey:@"taskVC"];
    [coder encodeObject:_lastRouteResult forKey:@"lastRouteResult"];
    [coder encodeObject:_embeddedReviewTaskResult forKey:@"embeddedReviewTaskResult"];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    _taskViewController = [coder decodeObjectOfClass:[UIViewController class] forKey:@"taskVC"];
    _lastRouteResult = [coder decodeObjectForKey:@"lastRouteResult"];
    
    // Need to give the task VC back a copy of its task, so it can restore itself.
    
    // Could save and restore the task's identifier separately, but the VC's
    // restoration identifier defaults to the task's identifier.
    id<ORKLegacyTask> taskForTaskViewController = [self makeTaskWithIdentifier:_taskViewController.restorationIdentifier];
    
    _taskViewController.task = taskForTaskViewController;
    if ([_taskViewController.restorationIdentifier isEqualToString:@"DynamicTask01"])
    {
        _taskViewController.defaultResultSource = _lastRouteResult;
    }
    _taskViewController.delegate = self;
}

#pragma mark - Charts

- (void)testChartsButtonTapped:(id)sender {
    UIStoryboard *chartStoryboard = [UIStoryboard storyboardWithName:@"Charts" bundle:nil];
    UIViewController *chartListViewController = [chartStoryboard instantiateViewControllerWithIdentifier:@"ChartListViewController"];
    [self presentViewController:chartListViewController animated:YES completion:nil];
}

- (void)testChartsPerformanceButtonTapped:(id)sender {
    UIStoryboard *chartStoryboard = [UIStoryboard storyboardWithName:@"Charts" bundle:nil];
    UIViewController *chartListViewController = [chartStoryboard instantiateViewControllerWithIdentifier:@"ChartPerformanceListViewController"];
    [self presentViewController:chartListViewController animated:YES completion:nil];
}

#pragma mark - Wait Task

- (ORKLegacyOrderedTask *)makeWaitingTask {
    
    NSMutableArray *steps = [[NSMutableArray alloc] init];
    
    /*
     To properly use the wait steps, one needs to implement the "" method of ORKLegacyTaskViewControllerDelegate to start their background action when the wait task begins, and then call the "finish" method on the ORKLegacyWaitTaskViewController when the background task has been completed.
     */
    ORKLegacyInstructionStep *step1 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"waitTask.step1"];
    step1.title = @"Setup";
    step1.detailText = @"ORKTest needs to set up some things before you begin, once the setup is complete you will be able to continue.";
    [steps addObject:step1];
    
    // Interterminate wait step.
    ORKLegacyWaitStep *step2 = [[ORKLegacyWaitStep alloc] initWithIdentifier:@"waitTask.step2"];
    step2.title = @"Getting Ready";
    step2.text = @"Please wait while the setup completes.";
    [steps addObject:step2];
    
    ORKLegacyInstructionStep *step3 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"waitTask.step3"];
    step3.title = @"Account Setup";
    step3.detailText = @"The information you entered will be sent to the secure server to complete your account setup.";
    [steps addObject:step3];
    
    // Determinate wait step.
    ORKLegacyWaitStep *step4 = [[ORKLegacyWaitStep alloc] initWithIdentifier:@"waitTask.step4"];
    step4.title = @"Syncing Account";
    step4.text = @"Please wait while the data is uploaded.";
    step4.indicatorType = ORKLegacyProgressIndicatorTypeProgressBar;
    [steps addObject:step4];
    
    ORKLegacyCompletionStep *step5 = [[ORKLegacyCompletionStep alloc] initWithIdentifier:@"waitTask.step5"];
    step5.title = @"Setup Complete";
    [steps addObject:step5];

    ORKLegacyOrderedTask *waitTask = [[ORKLegacyOrderedTask alloc] initWithIdentifier:WaitTaskIdentifier steps:steps];
    return waitTask;
}

- (void)updateProgress:(CGFloat)progress waitStepViewController:(ORKLegacyWaitStepViewController *)waitStepviewController {
    if (progress <= 1.0) {
        [waitStepviewController setProgress:progress animated:true];
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
            [self updateProgress:(progress + 0.01) waitStepViewController:waitStepviewController];
            if (progress > 0.495 && progress < 0.505) {
                NSString *newText = @"Please wait while the data is downloaded.";
                [waitStepviewController updateText:newText];
            }
        });
    } else {
        [waitStepviewController goForward];
    }
}

#pragma mark - Location Task

- (IBAction)locationButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:LocationTaskIdentifier];
}

- (ORKLegacyOrderedTask *)makeLocationTask {
    NSMutableArray *steps = [[NSMutableArray alloc] init];
    
    ORKLegacyInstructionStep *step1 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"locationTask.step1"];
    step1.title = @"Location Survey";
    [steps addObject:step1];
    
    // Location question with current location observing on
    ORKLegacyQuestionStep *step2 = [[ORKLegacyQuestionStep alloc] initWithIdentifier:@"locationTask.step2"];
    step2.title = @"Where are you right now?";
    step2.answerFormat = [[ORKLegacyLocationAnswerFormat alloc] init];
    [steps addObject:step2];
    
    // Location question with current location observing off
    ORKLegacyQuestionStep *step3 = [[ORKLegacyQuestionStep alloc] initWithIdentifier:@"locationTask.step3"];
    step3.title = @"Where is your home?";
    ORKLegacyLocationAnswerFormat *locationAnswerFormat  = [[ORKLegacyLocationAnswerFormat alloc] init];
    locationAnswerFormat.useCurrentLocation= NO;
    step3.answerFormat = locationAnswerFormat;
    [steps addObject:step3];
    
    ORKLegacyCompletionStep *step4 = [[ORKLegacyCompletionStep alloc] initWithIdentifier:@"locationTask.step4"];
    step4.title = @"Survey Complete";
    [steps addObject:step4];
    
    ORKLegacyOrderedTask *locationTask = [[ORKLegacyOrderedTask alloc] initWithIdentifier:LocationTaskIdentifier steps:steps];
    return locationTask;
}

#pragma mark - Step Will Disappear Task Delegate example

- (IBAction)stepWillDisappearButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:StepWillDisappearTaskIdentifier];
}

- (ORKLegacyOrderedTask *)makeStepWillDisappearTask {
    
    ORKLegacyInstructionStep *step1 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:StepWillDisappearFirstStepIdentifier];
    step1.title = @"Step Will Disappear Delegate Example";
    step1.text = @"The tint color of the task view controller is changed to magenta in the `stepViewControllerWillDisappear:` method.";
    
    ORKLegacyCompletionStep *stepLast = [[ORKLegacyCompletionStep alloc] initWithIdentifier:@"stepLast"];
    stepLast.title = @"Survey Complete";
    
    ORKLegacyOrderedTask *locationTask = [[ORKLegacyOrderedTask alloc] initWithIdentifier:StepWillDisappearTaskIdentifier steps:@[step1, stepLast]];
    return locationTask;
}

#pragma mark - Confirmation Form Item

- (IBAction)confirmationFormItemButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:ConfirmationFormTaskIdentifier];
}

- (ORKLegacyOrderedTask *)makeConfirmationFormTask {
    NSMutableArray *steps = [[NSMutableArray alloc] init];
    
    ORKLegacyInstructionStep *step1 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"confirmationForm.step1"];
    step1.title = @"Confirmation Form Items Survey";
    [steps addObject:step1];
    
    // Create a step for entering password with confirmation
    ORKLegacyFormStep *step2 = [[ORKLegacyFormStep alloc] initWithIdentifier:@"confirmationForm.step2" title:@"Password" text:nil];
    [steps addObject:step2];
    
    {
        ORKLegacyTextAnswerFormat *answerFormat = [ORKLegacyAnswerFormat textAnswerFormat];
        answerFormat.multipleLines = NO;
        answerFormat.secureTextEntry = YES;
        answerFormat.autocapitalizationType = UITextAutocapitalizationTypeNone;
        answerFormat.autocorrectionType = UITextAutocorrectionTypeNo;
        answerFormat.spellCheckingType = UITextSpellCheckingTypeNo;
        
        ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"password"
                                                               text:@"Password"
                                                       answerFormat:answerFormat
                                                           optional:NO];
        item.placeholder = @"Enter password";

        ORKLegacyFormItem *confirmationItem = [item confirmationAnswerFormItemWithIdentifier:@"password.confirmation"
                                                                                  text:@"Confirm"
                                                                          errorMessage:@"Passwords do not match"];
        confirmationItem.placeholder = @"Enter password again";
        
        step2.formItems = @[item, confirmationItem];
    }
    
    // Create a step for entering participant id
    ORKLegacyFormStep *step3 = [[ORKLegacyFormStep alloc] initWithIdentifier:@"confirmationForm.step3" title:@"Participant ID" text:nil];
    [steps addObject:step3];
    
    {
        ORKLegacyTextAnswerFormat *answerFormat = [ORKLegacyAnswerFormat textAnswerFormat];
        answerFormat.multipleLines = NO;
        answerFormat.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        answerFormat.autocorrectionType = UITextAutocorrectionTypeNo;
        answerFormat.spellCheckingType = UITextSpellCheckingTypeNo;
        
        ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:@"participantID"
                                                               text:@"Participant ID"
                                                       answerFormat:answerFormat
                                                           optional:YES];
        item.placeholder = @"Enter Participant ID";
        
        ORKLegacyFormItem *confirmationItem = [item confirmationAnswerFormItemWithIdentifier:@"participantID.confirmation"
                                                                                  text:@"Confirm"
                                                                          errorMessage:@"IDs do not match"];
        confirmationItem.placeholder = @"Enter ID again";
        
        step3.formItems = @[item, confirmationItem];
    }
    
    ORKLegacyCompletionStep *step4 = [[ORKLegacyCompletionStep alloc] initWithIdentifier:@"confirmationForm.lastStep"];
    step4.title = @"Survey Complete";
    [steps addObject:step4];
    
    return [[ORKLegacyOrderedTask alloc] initWithIdentifier:ConfirmationFormTaskIdentifier steps:steps];
}

#pragma mark - Continue button

- (IBAction)continueButtonButtonTapped:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ContinueButtonExample" bundle:nil];
    UIViewController *vc = [storyboard instantiateInitialViewController];
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - Instantiate Custom Step View Controller Example

- (IBAction)instantiateCustomVcButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:InstantiateCustomVCTaskIdentifier];
}

- (ORKLegacyOrderedTask *)makeInstantiateCustomVCTask {
    
    ORKLegacyInstructionStep *step1 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"locationTask.step1"];
    step1.title = @"Instantiate Custom View Controller";
    step1.text = @"The next step uses a custom subclass of an ORKLegacyFormStepViewController.";
    
    DragonPokerStep *dragonStep = [[DragonPokerStep alloc] initWithIdentifier:@"dragonStep"];
    
    ORKLegacyStep *lastStep = [[ORKLegacyCompletionStep alloc] initWithIdentifier:@"done"];
    
    return [[ORKLegacyOrderedTask alloc] initWithIdentifier:InstantiateCustomVCTaskIdentifier steps:@[step1, dragonStep, lastStep]];
}

#pragma mark - Step Table

- (IBAction)tableStepButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:TableStepTaskIdentifier];
}

- (ORKLegacyOrderedTask *)makeTableStepTask {
    NSMutableArray *steps = [[NSMutableArray alloc] init];
    
    ORKLegacyInstructionStep *step1 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"step1"];
    step1.text = @"Example of an ORKLegacyTableStepViewController";
    [steps addObject:step1];
    
    ORKLegacyTableStep *tableStep = [[ORKLegacyTableStep alloc] initWithIdentifier:@"tableStep"];
    tableStep.items = @[@"Item 1", @"Item 2", @"Item 3"];
    [steps addObject:tableStep];
    
    ORKLegacyCompletionStep *stepLast = [[ORKLegacyCompletionStep alloc] initWithIdentifier:@"lastStep"];
    stepLast.title = @"Task Complete";
    [steps addObject:stepLast];
    
    return [[ORKLegacyOrderedTask alloc] initWithIdentifier:TableStepTaskIdentifier steps:steps];
}

#pragma mark - Signature Table

- (IBAction)signatureStepButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:SignatureStepTaskIdentifier];
}

- (ORKLegacyOrderedTask *)makeSignatureStepTask {
    NSMutableArray *steps = [[NSMutableArray alloc] init];
    
    ORKLegacyInstructionStep *step1 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"step1"];
    step1.text = @"Example of an ORKLegacySignatureStep";
    [steps addObject:step1];
    
    ORKLegacySignatureStep *signatureStep = [[ORKLegacySignatureStep alloc] initWithIdentifier:@"signatureStep"];
    [steps addObject:signatureStep];
    
    ORKLegacyCompletionStep *stepLast = [[ORKLegacyCompletionStep alloc] initWithIdentifier:@"lastStep"];
    stepLast.title = @"Task Complete";
    [steps addObject:stepLast];
    
    return [[ORKLegacyOrderedTask alloc] initWithIdentifier:SignatureStepTaskIdentifier steps:steps];
}

#pragma mark - Auxillary Image

- (IBAction)auxillaryImageButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:AuxillaryImageTaskIdentifier];
}

- (ORKLegacyOrderedTask *)makeAuxillaryImageTask {
    
    ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:AuxillaryImageTaskIdentifier];
    step.title = @"Title";
    step.text = @"This is description text.";
    step.detailText = @"This is detail text.";
    step.image = [UIImage imageNamed:@"tremortest3a" inBundle:[NSBundle bundleForClass:[ORKLegacyOrderedTask class]] compatibleWithTraitCollection:nil];
    step.auxiliaryImage = [UIImage imageNamed:@"tremortest3b" inBundle:[NSBundle bundleForClass:[ORKLegacyOrderedTask class]] compatibleWithTraitCollection:nil];
    
    return [[ORKLegacyOrderedTask alloc] initWithIdentifier:SignatureStepTaskIdentifier steps:@[step]];
}

#pragma mark - Video Instruction Task

- (IBAction)videoInstructionStepButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:VideoInstructionStepTaskIdentifier];
}

- (ORKLegacyOrderedTask *)makeVideoInstructionStepTask {
    NSMutableArray *steps = [[NSMutableArray alloc] init];
    
    ORKLegacyInstructionStep *firstStep = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"firstStep"];
    firstStep.text = @"Example of an ORKLegacyVideoInstructionStep";
    [steps addObject:firstStep];
    
    ORKLegacyVideoInstructionStep *videoInstructionStep = [[ORKLegacyVideoInstructionStep alloc] initWithIdentifier:@"videoInstructionStep"];
    videoInstructionStep.text = @"Video Instruction";
    videoInstructionStep.videoURL = [[NSURL alloc] initWithString:@"https://www.apple.com/media/us/researchkit/2016/a63aa7d4_e6fd_483f_a59d_d962016c8093/films/carekit/researchkit-carekit-cc-us-20160321_r848-9dwc.mov"];
    
    [steps addObject:videoInstructionStep];
    
    ORKLegacyCompletionStep *lastStep = [[ORKLegacyCompletionStep alloc] initWithIdentifier:@"lastStep"];
    lastStep.title = @"Task Complete";
    [steps addObject:lastStep];
    
    return [[ORKLegacyOrderedTask alloc] initWithIdentifier:SignatureStepTaskIdentifier steps:steps];
}

#pragma mark - Icon Image

- (IBAction)iconImageButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:IconImageTaskIdentifier];
}

- (ORKLegacyOrderedTask *)makeIconImageTask {
    
    ORKLegacyInstructionStep *step1 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"step1"];
    step1.title = @"Title";
    step1.text = @"This is an example of a step with an icon image.";

    NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
    NSString *icon = [[infoPlist valueForKeyPath:@"CFBundleIcons.CFBundlePrimaryIcon.CFBundleIconFiles"] lastObject];
    step1.iconImage = [UIImage imageNamed:icon];
    
    ORKLegacyInstructionStep *step2 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"step2"];
    step2.text = @"This is an example of a step with an icon image and no title.";
    step2.iconImage = [UIImage imageNamed:icon];
    
    ORKLegacyInstructionStep *step3 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"step3"];
    step3.title = @"Title";
    step3.text = @"This is an example of a step with an icon image that is very big.";
    step3.iconImage = [UIImage imageNamed:@"Poppies"];
    
    return [[ORKLegacyOrderedTask alloc] initWithIdentifier:IconImageTaskIdentifier steps:@[step1, step2, step3]];
}

#pragma mark - Trail Making Task

- (IBAction)trailMakingTaskButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:TrailMakingTaskIdentifier];
}

#pragma mark - Completion Step Continue Button

- (IBAction)completionStepButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:CompletionStepTaskIdentifier];
}

- (ORKLegacyOrderedTask *)makeCompletionStepTask {
    NSMutableArray *steps = [[NSMutableArray alloc] init];
    
    ORKLegacyCompletionStep *step1 = [[ORKLegacyCompletionStep alloc] initWithIdentifier:@"completionStepWithDoneButton"];
    step1.text = @"Example of a step view controller with the continue button in the standard location below the checkmark.";
    [steps addObject:step1];
    
    ORKLegacyCompletionStep *stepLast = [[ORKLegacyCompletionStep alloc] initWithIdentifier:@"lastStep"];
    stepLast.title = @"Example of an step view controller with the continue button in the upper right.";
    [steps addObject:stepLast];
    
    return [[ORKLegacyOrderedTask alloc] initWithIdentifier:CompletionStepTaskIdentifier steps:steps];
}

#pragma mark - Page Step

- (IBAction)pageStepButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:PageStepTaskIdentifier];
}

- (ORKLegacyOrderedTask *)makePageStepTask {
    
    NSMutableArray *steps = [[NSMutableArray alloc] init];
    
    ORKLegacyInstructionStep *step1 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"step1"];
    step1.text = @"Example of an ORKLegacyPageStep";
    [steps addObject:step1];
    
    NSMutableArray<ORKLegacyTextChoice *> *textChoices = [[NSMutableArray alloc] init];
    [textChoices addObject:[[ORKLegacyTextChoice alloc] initWithText:@"Good" detailText:@"" value:[NSNumber numberWithInt:0] exclusive:NO]];
    [textChoices addObject:[[ORKLegacyTextChoice alloc] initWithText:@"Average" detailText:@"" value:[NSNumber numberWithInt:1] exclusive:NO]];
    [textChoices addObject:[[ORKLegacyTextChoice alloc] initWithText:@"Poor" detailText:@"" value:[NSNumber numberWithInt:2] exclusive:NO]];
    ORKLegacyAnswerFormat *answerFormat = [ORKLegacyAnswerFormat choiceAnswerFormatWithStyle:ORKLegacyChoiceAnswerStyleSingleChoice textChoices:textChoices];
    ORKLegacyFormItem *formItem = [[ORKLegacyFormItem alloc] initWithIdentifier:@"choice" text:nil answerFormat:answerFormat];
    ORKLegacyFormStep *groupStep1 = [[ORKLegacyFormStep alloc] initWithIdentifier:@"step1" title:nil text:@"How do you feel today?"];
    groupStep1.formItems = @[formItem];
    
    NSMutableArray<ORKLegacyImageChoice *> *imageChoices = [[NSMutableArray alloc] init];
    [imageChoices addObject:[[ORKLegacyImageChoice alloc] initWithNormalImage:[UIImage imageNamed:@"left_hand_outline"] selectedImage:[UIImage imageNamed:@"left_hand_solid"] text:@"Left hand" value:[NSNumber numberWithInt:1]]];
    [imageChoices addObject:[[ORKLegacyImageChoice alloc] initWithNormalImage:[UIImage imageNamed:@"right_hand_outline"] selectedImage:[UIImage imageNamed:@"right_hand_solid"] text:@"Right hand" value:[NSNumber numberWithInt:0]]];
    ORKLegacyQuestionStep *groupStep2 = [ORKLegacyQuestionStep questionStepWithIdentifier:@"step2" title:@"Which hand was injured?" answer:[ORKLegacyAnswerFormat choiceAnswerFormatWithImageChoices:imageChoices]];
    
    ORKLegacySignatureStep *groupStep3 = [[ORKLegacySignatureStep alloc] initWithIdentifier:@"step3"];
    
    ORKLegacyStep *groupStep4 = [[ORKLegacyConsentReviewStep alloc] initWithIdentifier:@"groupStep4" signature:nil inDocument:[self buildConsentDocument]];
    
    ORKLegacyPageStep *pageStep = [[ORKLegacyPageStep alloc] initWithIdentifier:@"pageStep" steps:@[groupStep1, groupStep2, groupStep3, groupStep4]];
    [steps addObject:pageStep];
    
    ORKLegacyOrderedTask *audioTask = [ORKLegacyOrderedTask audioTaskWithIdentifier:@"audioTask"
                                                 intendedUseDescription:nil
                                                      speechInstruction:nil
                                                 shortSpeechInstruction:nil
                                                               duration:10
                                                      recordingSettings:nil
                                                        checkAudioLevel:YES
                                                                options:
                                 ORKLegacyPredefinedTaskOptionExcludeInstructions |
                                 ORKLegacyPredefinedTaskOptionExcludeConclusion];
    ORKLegacyPageStep *audioStep = [[ORKLegacyNavigablePageStep alloc] initWithIdentifier:@"audioStep" pageTask:audioTask];
    [steps addObject:audioStep];
    
    ORKLegacyCompletionStep *stepLast = [[ORKLegacyCompletionStep alloc] initWithIdentifier:@"lastStep"];
    stepLast.title = @"Task Complete";
    [steps addObject:stepLast];
    
    return [[ORKLegacyOrderedTask alloc] initWithIdentifier:PageStepTaskIdentifier steps:steps];
    
}


#pragma mark - Footnote

- (IBAction)footnoteButtonTapped:(id)sender {
    [self beginTaskWithIdentifier:FootnoteTaskIdentifier];
}

- (ORKLegacyOrderedTask *)makeFootnoteTask {
    
    ORKLegacyInstructionStep *step1 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"step1"];
    step1.title = @"Footnote example";
    step1.text = @"This is an instruction step with a footnote.";
    step1.footnote = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce dignissim tortor eget orci placerat, eu congue diam tempor. In hac.";
    
    ORKLegacyInstructionStep *step2 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"step2"];
    step2.title = @"Image and No Footnote";
    step2.text = @"This is an instruction step with an image and NO footnote.";
    step2.image = [UIImage imageNamed:@"image_example"];
    
    ORKLegacyInstructionStep *step3 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"step3"];
    step3.title = @"Image and Footnote";
    step3.text = @"This is an instruction step with an image and a footnote.";
    step3.image = [UIImage imageNamed:@"image_example"];
    step3.footnote = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce dignissim tortor eget orci placerat, eu congue diam tempor. In hac.";
    
    ORKLegacyFormStep *step4 = [[ORKLegacyFormStep alloc] initWithIdentifier:@"step4" title:@"Form Step with skip" text:@"This is a form step with a skip button."];
    step4.formItems = @[[[ORKLegacyFormItem alloc] initWithIdentifier:@"form_item_1"
                                                           text:@"Are you over 18 years of age?"
                                                   answerFormat:[ORKLegacyAnswerFormat booleanAnswerFormat]]];
    step4.optional = YES;
    
    ORKLegacyFormStep *step5 = [[ORKLegacyFormStep alloc] initWithIdentifier:@"step5" title:@"Form Step with Footnote" text:@"This is a form step with a skip button and footnote."];
    step5.formItems = @[[[ORKLegacyFormItem alloc] initWithIdentifier:@"form_item_1"
                                                           text:@"Are you over 18 years of age?"
                                                   answerFormat:[ORKLegacyAnswerFormat booleanAnswerFormat]]];
    step5.optional = YES;
    step5.footnote = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce dignissim tortor eget orci placerat, eu congue diam tempor. In hac.";

    ORKLegacyCompletionStep *lastStep = [[ORKLegacyCompletionStep alloc] initWithIdentifier:@"lastStep"];
    lastStep.title = @"Last step.";
    lastStep.text = @"This is a completion step with a footnote.";
    lastStep.footnote = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce dignissim tortor eget orci placerat, eu congue diam tempor. In hac.";

    return [[ORKLegacyOrderedTask alloc] initWithIdentifier:FootnoteTaskIdentifier steps:@[step1, step2, step3, step4, step5, lastStep]];
}


@end
