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


#import "ORK1QuestionStepViewController.h"

#import "ORK1ChoiceViewCell.h"
#import "ORK1QuestionStepView.h"
#import "ORK1StepHeaderView_Internal.h"
#import "ORK1SurveyAnswerCellForScale.h"
#import "ORK1SurveyAnswerCellForNumber.h"
#import "ORK1SurveyAnswerCellForText.h"
#import "ORK1SurveyAnswerCellForPicker.h"
#import "ORK1SurveyAnswerCellForImageSelection.h"
#import "ORK1SurveyAnswerCellForLocation.h"
#import "ORK1TableContainerView.h"
#import "ORK1TextChoiceCellGroup.h"

#import "ORK1NavigationContainerView_Internal.h"
#import "ORK1QuestionStepViewController_Private.h"
#import "ORK1StepViewController_Internal.h"
#import "ORK1TaskViewController_Internal.h"

#import "ORK1AnswerFormat_Internal.h"
#import "ORK1QuestionStep_Internal.h"
#import "ORK1Result_Private.h"
#import "ORK1Step_Private.h"

#import "ORK1Helpers_Internal.h"
#import "ORK1Skin.h"


typedef NS_ENUM(NSInteger, ORK1QuestionSection) {
    ORK1QuestionSectionAnswer = 0,
    ORK1QuestionSection_COUNT
};


@interface ORK1QuestionStepViewController () <UITableViewDataSource,UITableViewDelegate, ORK1SurveyAnswerCellDelegate> {
    id _answer;
    
    ORK1TableContainerView *_tableContainer;
    ORK1StepHeaderView *_headerView;
    ORK1NavigationContainerView *_continueSkipView;
    ORK1AnswerDefaultSource *_defaultSource;
    
    NSCalendar *_savedSystemCalendar;
    NSTimeZone *_savedSystemTimeZone;
    
    ORK1TextChoiceCellGroup *_choiceCellGroup;
    
    id _defaultAnswer;
    
    BOOL _visible;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) ORK1QuestionStepView *questionView;

@property (nonatomic, strong) ORK1AnswerFormat *answerFormat;
@property (nonatomic, copy) id<NSCopying, NSObject, NSCoding> answer;

@property (nonatomic, strong) ORK1ContinueButton *continueActionButton;

@property (nonatomic, strong) ORK1SurveyAnswerCell *answerCell;

@property (nonatomic, readonly) UILabel *questionLabel;
@property (nonatomic, readonly) UILabel *promptLabel;

// If `hasChangedAnswer`, then a new `defaultAnswer` should not change the answer
@property (nonatomic, assign) BOOL hasChangedAnswer;

@property (nonatomic, copy) id<NSCopying, NSObject, NSCoding> originalAnswer;

@end


@implementation ORK1QuestionStepViewController

- (void)initializeInternalButtonItems {
    [super initializeInternalButtonItems];
    self.internalSkipButtonItem.title = ORK1LocalizedString(@"BUTTON_SKIP_QUESTION", nil);
}

- (instancetype)initWithStep:(ORK1Step *)step result:(ORK1Result *)result {
    self = [self initWithStep:step];
    if (self) {
		ORK1StepResult *stepResult = (ORK1StepResult *)result;
		if (stepResult && [stepResult results].count > 0) {
            ORK1QuestionResult *questionResult = ORK1DynamicCast([stepResult results].firstObject, ORK1QuestionResult);
            id answer = [questionResult answer];
            if (questionResult != nil && answer == nil) {
                answer = ORK1NullAnswerValue();
            }
			self.answer = answer;
            self.originalAnswer = answer;
		}
    }
    return self;
}

- (instancetype)initWithStep:(ORK1Step *)step {
    self = [super initWithStep:step];
    if (self) {
        _defaultSource = [ORK1AnswerDefaultSource sourceWithHealthStore:[HKHealthStore new]];
    }
    return self;
}

- (void)stepDidChange {
    [super stepDidChange];
    _answerFormat = [self.questionStep impliedAnswerFormat];
    
    self.hasChangedAnswer = NO;
    
    if ([self isViewLoaded]) {
        [_tableContainer removeFromSuperview];
        _tableView.delegate = nil;
        _tableView.dataSource = nil;
        _tableView = nil;
        _headerView = nil;
        _continueSkipView = nil;
        
        [_questionView removeFromSuperview];
        _questionView = nil;
        
        if ([self.questionStep formatRequiresTableView] && !_customQuestionView) {
            _tableContainer = [[ORK1TableContainerView alloc] initWithFrame:self.view.bounds];
            
            // Create a new one (with correct style)
            _tableView = _tableContainer.tableView;
            _tableView.delegate = self;
            _tableView.dataSource = self;
            _tableView.clipsToBounds = YES;
            
            [self.view addSubview:_tableContainer];
            _tableContainer.tapOffView = self.view;
            
            _headerView = _tableContainer.stepHeaderView;
            _headerView.captionLabel.useSurveyMode = self.step.useSurveyMode;
            _headerView.captionLabel.text = self.questionStep.title;
            _headerView.instructionTextView.textValue = self.questionStep.text;
            _headerView.learnMoreButtonItem = self.learnMoreButtonItem;
            
            _continueSkipView = _tableContainer.continueSkipContainerView;
            _continueSkipView.skipButtonItem = self.skipButtonItem;
            _continueSkipView.continueEnabled = [self continueButtonEnabled];
            _continueSkipView.continueButtonItem = self.continueButtonItem;
            _continueSkipView.optional = self.step.optional;
            if (self.readOnlyMode) {
                _continueSkipView.optional = YES;
                [_continueSkipView setNeverHasContinueButton:YES];
                _continueSkipView.skipEnabled = [self skipButtonEnabled];
                _continueSkipView.skipButton.accessibilityTraits = UIAccessibilityTraitStaticText;
            }
            [_tableContainer setNeedsLayout];
        } else if (self.step) {
            _questionView = [ORK1QuestionStepView new];
            _questionView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
            _questionView.questionStep = [self questionStep];
            [self.view addSubview:_questionView];
            
            if (_customQuestionView) {
                _questionView.questionCustomView = _customQuestionView;
                _customQuestionView.delegate = self;
                _customQuestionView.answer = [self answer];
                _customQuestionView.userInteractionEnabled = !self.readOnlyMode;
            } else {
                ORK1QuestionStepCellHolderView *cellHolderView = [ORK1QuestionStepCellHolderView new];
                cellHolderView.delegate = self;
                cellHolderView.cell = [self answerCellForTableView:nil];
                [NSLayoutConstraint activateConstraints:
                 [cellHolderView.cell suggestedCellHeightConstraintsForView:self.parentViewController.view]];
                cellHolderView.answer = [self answer];
                cellHolderView.userInteractionEnabled = !self.readOnlyMode;
                _questionView.questionCustomView = cellHolderView;
            }
            
            _questionView.translatesAutoresizingMaskIntoConstraints = NO;
            _questionView.continueSkipContainer.continueButtonItem = self.continueButtonItem;
            _questionView.headerView.learnMoreButtonItem = self.learnMoreButtonItem;
            _questionView.continueSkipContainer.skipButtonItem = self.skipButtonItem;
            _questionView.continueSkipContainer.continueEnabled = [self continueButtonEnabled];
            if (self.readOnlyMode) {
                _questionView.continueSkipContainer.optional = YES;
                [_questionView.continueSkipContainer setNeverHasContinueButton:YES];
                _questionView.continueSkipContainer.skipEnabled = [self skipButtonEnabled];
                _questionView.continueSkipContainer.skipButton.accessibilityTraits = UIAccessibilityTraitStaticText;
            }

            
            NSMutableArray *constraints = [NSMutableArray new];
            [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[questionView]|"
                                                                                     options:(NSLayoutFormatOptions)0
                                                                                     metrics:nil
                                                                                       views:@{@"questionView": _questionView}]];
            [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topGuide][questionView][bottomGuide]"
                                                                                     options:(NSLayoutFormatOptions)0
                                                                                     metrics:nil
                                                                                       views:@{@"questionView": _questionView,
                                                                                               @"topGuide": self.topLayoutGuide,
                                                                                               @"bottomGuide": self.bottomLayoutGuide}]];
            for (NSLayoutConstraint *constraint in constraints) {
                constraint.priority = UILayoutPriorityRequired;
            }
            [NSLayoutConstraint activateConstraints:constraints];
        }
    }
    
    if ([self allowContinue] == NO) {
        self.continueButtonItem  = self.internalContinueButtonItem;
    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self stepDidChange];
    
}

- (void)showValidityAlertWithMessage:(NSString *)text {
    // Ignore if our answer is null
    if (self.answer == ORK1NullAnswerValue()) {
        return;
    }
    
    [super showValidityAlertWithMessage:text];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (_tableView) {
        [self.taskViewController setRegisteredScrollView:_tableView];
    }
    if (_questionView) {
        [self.taskViewController setRegisteredScrollView:_questionView];
    }
    
    NSMutableSet *types = [NSMutableSet set];
    ORK1AnswerFormat *format = [[self questionStep] answerFormat];
    HKObjectType *objType = [format healthKitObjectTypeForAuthorization];
    if (objType) {
        [types addObject:objType];
    }
    
    BOOL scheduledRefresh = NO;
    if (types.count) {
        NSSet<HKObjectType *> *alreadyRequested = [[self taskViewController] requestedHealthTypesForRead];
        if (![types isSubsetOfSet:alreadyRequested]) {
            scheduledRefresh = YES;
            [_defaultSource.healthStore requestAuthorizationToShareTypes:nil readTypes:types completion:^(BOOL success, NSError *error) {
                if (success) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self refreshDefaults];
                    });
                }
            }];
        }
    }
    if (!scheduledRefresh) {
        [self refreshDefaults];
    }
    
    [_tableContainer layoutIfNeeded];
}

- (void)answerDidChange {
    if ([self.questionStep formatRequiresTableView] && !_customQuestionView) {
        [self.tableView reloadData];
    } else {
        if (_customQuestionView) {
            _customQuestionView.answer = _answer;
        } else {
            ORK1QuestionStepCellHolderView *holder = (ORK1QuestionStepCellHolderView *)_questionView.questionCustomView;
            holder.answer = _answer;
            [self.answerCell setAnswer:_answer];
        }
    }
    [self updateButtonStates];
}

- (void)refreshDefaults {
    [_defaultSource fetchDefaultValueForAnswerFormat:[[self questionStep] answerFormat] handler:^(id defaultValue, NSError *error) {
        if (defaultValue != nil || error == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _defaultAnswer = defaultValue;
                [self defaultAnswerDidChange];
            });
        } else {
            ORK1_Log_Warning(@"Error fetching default: %@", error);
        }
    }];
}

- (void)defaultAnswerDidChange {
    id defaultAnswer = _defaultAnswer;
    if (![self hasAnswer] && defaultAnswer && !self.hasChangedAnswer) {
        _answer = defaultAnswer;
        
        [self answerDidChange];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Delay creating the date picker until the view has appeared (to avoid animation stutter)
    ORK1SurveyAnswerCellForPicker *cell = (ORK1SurveyAnswerCellForPicker *)[(ORK1QuestionStepCellHolderView *)_questionView.questionCustomView cell];
    if ([cell isKindOfClass:[ORK1SurveyAnswerCellForPicker class]]) {
        [cell loadPicker];
    }
    
    [[NSNotificationCenter defaultCenter] addObserverForName:ORK1UpdateChoiceCell object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        UITableViewCell *cell = (UITableViewCell *)note.userInfo[ORK1UpdateChoiceCellKeyCell];
        if ([cell isKindOfClass:[UITableViewCell class]]) {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            [self adjustUIforChangesToDetailTextAtIndex:indexPath.row];
        }
    }];
    
    _visible = YES;
    
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    _visible = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ORK1UpdateChoiceCell object:nil];
}

- (void)adjustUIforChangesToDetailTextAtIndex:(NSUInteger)index {
    
    /*
     Due to the complexity of the layout, animating the expansion and contraction of the textDetail will
     move the continue button up or down out of ideal position. To prevent this, we calculate the expected
     difference in tableView size and pass this to the ORK1TableContainerView which will hide the continue
     button, adjust the constraint and then animate the button alpha to 1.
     */
    
    [self.tableView beginUpdates];
    
    ORK1QuestionStep *questionStep = (ORK1QuestionStep *)self.step;
    ORK1TextChoiceAnswerFormat *format = (ORK1TextChoiceAnswerFormat *) questionStep.answerFormat;
    if (![format isKindOfClass:[ORK1TextChoiceAnswerFormat class]]) {
        [self.tableView endUpdates];
        return;
    }
    ORK1TextChoice *choice = format.textChoices[index];
    NSString *longText = !choice.detailTextShouldDisplay ? choice.detailText : nil;
    CGFloat sizeBeforeResize = [ORK1ChoiceViewCell suggestedCellHeightForShortText:choice.text longText:longText inTableView:self.tableView];
    
    [_choiceCellGroup updateLabelsForCell:[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]] atIndex:index];
    
    longText = choice.detailTextShouldDisplay ? choice.detailText : nil;
    CGFloat sizeAfterResize = [ORK1ChoiceViewCell suggestedCellHeightForShortText:choice.text longText:longText inTableView:self.tableView];
    
    [_tableContainer adjustBottomConstraintWithExpectedOffset:(sizeAfterResize - sizeBeforeResize)];
    [self.tableView endUpdates];
}

- (void)setCustomQuestionView:(ORK1QuestionStepCustomView *)customQuestionView {
    [_customQuestionView removeFromSuperview];
    _customQuestionView = customQuestionView;
    if ([_customQuestionView constraints].count == 0) {
        _customQuestionView.translatesAutoresizingMaskIntoConstraints = NO;

        CGSize requiredSize = [_customQuestionView sizeThatFits:(CGSize){self.view.bounds.size.width, CGFLOAT_MAX}];
        
        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:_customQuestionView
                                                                           attribute:NSLayoutAttributeWidth
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                                          multiplier:1.0
                                                                            constant:requiredSize.width];
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:_customQuestionView
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                                           multiplier:1.0
                                                                             constant:requiredSize.height];
        
        widthConstraint.priority = UILayoutPriorityDefaultLow;
        heightConstraint.priority = UILayoutPriorityDefaultLow;
        [NSLayoutConstraint activateConstraints:@[widthConstraint, heightConstraint]];
    }
    [self stepDidChange];
}

- (void)updateButtonStates {
    if ([self isStepImmediateNavigation]) {
//        _continueSkipView.neverHasContinueButton = YES;
//        _continueSkipView.continueButtonItem = nil;
    }
    _questionView.continueSkipContainer.continueEnabled = [self continueButtonEnabled];
    _continueSkipView.continueEnabled = [self continueButtonEnabled];
    _questionView.continueSkipContainer.skipEnabled = [self skipButtonEnabled];
    _continueSkipView.skipEnabled = [self skipButtonEnabled];
}

// Override to monitor button title change
- (void)setContinueButtonItem:(UIBarButtonItem *)continueButtonItem {
    [super setContinueButtonItem:continueButtonItem];
    _questionView.continueSkipContainer.continueButtonItem = continueButtonItem;
    _continueSkipView.continueButtonItem = continueButtonItem;
    [self updateButtonStates];
}

- (void)setLearnMoreButtonItem:(UIBarButtonItem *)learnMoreButtonItem {
    [super setLearnMoreButtonItem:learnMoreButtonItem];
    _headerView.learnMoreButtonItem = self.learnMoreButtonItem;
    _questionView.headerView.learnMoreButtonItem = self.learnMoreButtonItem;
}

- (void)setSkipButtonItem:(UIBarButtonItem *)skipButtonItem {
    [super setSkipButtonItem:skipButtonItem];
    
    _questionView.continueSkipContainer.skipButtonItem = self.skipButtonItem;
    _continueSkipView.skipButtonItem = self.skipButtonItem;
    [self updateButtonStates];
}

- (ORK1StepResult *)result {
    ORK1StepResult *parentResult = [super result];
    ORK1QuestionStep *questionStep = self.questionStep;
    
    if (self.answer) {
        ORK1QuestionResult *result = [questionStep.answerFormat resultWithIdentifier:questionStep.identifier answer:self.answer];
        ORK1AnswerFormat *impliedAnswerFormat = [questionStep impliedAnswerFormat];
        
        if ([impliedAnswerFormat isKindOfClass:[ORK1DateAnswerFormat class]]) {
            ORK1DateQuestionResult *dateQuestionResult = (ORK1DateQuestionResult *)result;
            if (dateQuestionResult.dateAnswer) {
                NSCalendar *usedCalendar = [(ORK1DateAnswerFormat *)impliedAnswerFormat calendar] ? : _savedSystemCalendar;
                dateQuestionResult.calendar = [NSCalendar calendarWithIdentifier:usedCalendar.calendarIdentifier ? : [NSCalendar currentCalendar].calendarIdentifier];
                dateQuestionResult.timeZone = _savedSystemTimeZone ? : [NSTimeZone systemTimeZone];
            }
        } else if ([impliedAnswerFormat isKindOfClass:[ORK1NumericAnswerFormat class]]) {
            ORK1NumericQuestionResult *nqr = (ORK1NumericQuestionResult *)result;
            if (nqr.unit == nil) {
                nqr.unit = [(ORK1NumericAnswerFormat *)impliedAnswerFormat unit];
            }
        }
        
        result.startDate = parentResult.startDate;
        result.endDate = parentResult.endDate;
        
        parentResult.results = @[result];
    }
    
    return parentResult;
}

#pragma mark - Internal

- (ORK1QuestionStep *)questionStep {
    assert(!self.step || [self.step isKindOfClass:[ORK1QuestionStep class]]);
    return (ORK1QuestionStep *)self.step;
}

- (BOOL)hasAnswer {
    return !ORK1IsAnswerEmpty(self.answer);
}

- (void)saveAnswer:(id)answer {
    self.answer = answer;
    _savedSystemCalendar = [NSCalendar currentCalendar];
    _savedSystemTimeZone = [NSTimeZone systemTimeZone];
    [self notifyDelegateOnResultChange];
}

- (void)skipForward {
    // Null out the answer before proceeding
    [self saveAnswer:ORK1NullAnswerValue()];
    ORK1SurveyAnswerCell *cell = self.answerCell;
    cell.answer = ORK1NullAnswerValue();
    
    [super skipForward];
}

- (void)notifyDelegateOnResultChange {
    [super notifyDelegateOnResultChange];
    
    if (self.hasNextStep == NO) {
        self.continueButtonItem = self.internalDoneButtonItem;
    } else {
        self.continueButtonItem = self.internalContinueButtonItem;
    }
    
    self.skipButtonItem = self.internalSkipButtonItem;
    if (!self.questionStep.optional && !self.readOnlyMode) {
        self.skipButtonItem = nil;
    }

    if ([self allowContinue] == NO) {
        self.continueButtonItem  = self.internalContinueButtonItem;
    }
    
    [self.tableView reloadData];
}

- (id<NSCopying, NSCoding, NSObject>)answer {
    if (self.questionStep.questionType == ORK1QuestionTypeMultipleChoice && (_answer == nil || _answer == ORK1NullAnswerValue())) {
        _answer = [NSMutableArray array];
    }
    return _answer;
}

- (void)setAnswer:(id)answer {
    _answer = answer;
}

- (BOOL)continueButtonEnabled {
    BOOL enabled = ([self hasAnswer] || (self.questionStep.optional && !self.skipButtonItem));
    if (self.isBeingReviewed) {
        enabled = enabled && (![self.answer isEqual:self.originalAnswer]);
    }
    return enabled;
}

- (BOOL)skipButtonEnabled {
    BOOL enabled = [self questionStep].optional;
    if (self.isBeingReviewed) {
        enabled = self.readOnlyMode ? NO : enabled && !ORK1IsAnswerEmpty(self.originalAnswer);
    }
    return enabled;
}

- (BOOL)allowContinue {
    return !(self.questionStep.optional == NO && [self hasAnswer] == NO);
}

// Not to use `ImmediateNavigation` when current step already has an answer.
// So user is able to review the answer when it is present.
- (BOOL)isStepImmediateNavigation {
    return [self.questionStep isFormatImmediateNavigation] && [self hasAnswer] == NO && !self.isBeingReviewed;
}

#pragma mark - ORK1QuestionStepCustomViewDelegate

- (void)customQuestionStepView:(ORK1QuestionStepCustomView *)customQuestionStepView didChangeAnswer:(id)answer; {
    [self saveAnswer:answer];
    self.hasChangedAnswer = YES;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return ORK1QuestionSection_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    ORK1AnswerFormat *impliedAnswerFormat = [_answerFormat impliedAnswerFormat];
    
    if (section == ORK1QuestionSectionAnswer) {
        _choiceCellGroup = [[ORK1TextChoiceCellGroup alloc] initWithTextChoiceAnswerFormat:(ORK1TextChoiceAnswerFormat *)impliedAnswerFormat
                                                                                   answer:self.answer
                                                                       beginningIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]
                                                                      immediateNavigation:[self isStepImmediateNavigation]];
        return _choiceCellGroup.size;
    }
    return 0;
}

- (ORK1SurveyAnswerCell *)answerCellForTableView:(UITableView *)tableView {
    static NSDictionary *typeAndCellMapping = nil;
    static NSString *identifier = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        typeAndCellMapping = @{@(ORK1QuestionTypeScale): [ORK1SurveyAnswerCellForScale class],
                               @(ORK1QuestionTypeDecimal): [ORK1SurveyAnswerCellForNumber class],
                               @(ORK1QuestionTypeText): [ORK1SurveyAnswerCellForText class],
                               @(ORK1QuestionTypeTimeOfDay): [ORK1SurveyAnswerCellForPicker class],
                               @(ORK1QuestionTypeDate): [ORK1SurveyAnswerCellForPicker class],
                               @(ORK1QuestionTypeDateAndTime): [ORK1SurveyAnswerCellForPicker class],
                               @(ORK1QuestionTypeTimeInterval): [ORK1SurveyAnswerCellForPicker class],
                               @(ORK1QuestionTypeHeight) : [ORK1SurveyAnswerCellForPicker class],
                               @(ORK1QuestionTypeWeight) : [ORK1SurveyAnswerCellForPicker class],
                               @(ORK1QuestionTypeMultiplePicker) : [ORK1SurveyAnswerCellForPicker class],
                               @(ORK1QuestionTypeInteger): [ORK1SurveyAnswerCellForNumber class],
                               @(ORK1QuestionTypeLocation): [ORK1SurveyAnswerCellForLocation class]};
    });
    
    // SingleSelectionPicker Cell && Other Cells
    Class class = typeAndCellMapping[@(self.questionStep.questionType)];
    
    if ([self.questionStep isFormatChoiceWithImageOptions]) {
        class = [ORK1SurveyAnswerCellForImageSelection class];
    } else if ([self.questionStep isFormatTextfield]) {
        // Override for single-line text entry
        class = [ORK1SurveyAnswerCellForTextField class];
    } else if ([[self.questionStep impliedAnswerFormat] isKindOfClass:[ORK1ValuePickerAnswerFormat class]]) {
        class = [ORK1SurveyAnswerCellForPicker class];
    }
    
    identifier = NSStringFromClass(class);
    
    NSAssert(class != nil, @"class should not be nil");
    
    ORK1SurveyAnswerCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil) { 
        cell = [[class alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier step:[self questionStep] answer:self.answer delegate:self];
    }
    
    self.answerCell = cell;
    
    if ([self.questionStep isFormatTextfield] ||
        [cell isKindOfClass:[ORK1SurveyAnswerCellForScale class]] ||
        [cell isKindOfClass:[ORK1SurveyAnswerCellForPicker class]]) {
        cell.separatorInset = UIEdgeInsetsMake(0, ORK1ScreenMetricMaxDimension, 0, 0);
    }

    if ([cell isKindOfClass:[ORK1SurveyAnswerCellForPicker class]] && _visible) {
        [(ORK1SurveyAnswerCellForPicker *)cell loadPicker];
    }
    
    return cell;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    tableView.layoutMargins = UIEdgeInsetsZero;
    
    //////////////////////////////////
    // Section for Answer Area
    //////////////////////////////////
    
    static NSString *identifier = nil;

    assert (self.questionStep.isFormatFitsChoiceCells);
    
    identifier = [NSStringFromClass([self class]) stringByAppendingFormat:@"%@", @(indexPath.row)];
    
    ORK1ChoiceViewCell *cell = [_choiceCellGroup cellAtIndexPath:indexPath withReuseIdentifier:identifier];
    
    cell.userInteractionEnabled = !self.readOnlyMode;
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.layoutMargins = UIEdgeInsetsZero;
    cell.separatorInset = (UIEdgeInsets){.left = ORK1StandardLeftMarginForTableViewCell(tableView)};
}

- (BOOL)shouldContinue {
    ORK1SurveyAnswerCell *cell = self.answerCell;
    if (!cell) {
        return YES;
    }

    return [cell shouldContinue];
}

- (void)goForward {
    if (![self shouldContinue]) {
        return;
    }
    [[self answerCell] stepIsNavigatingForward];
    [self notifyDelegateOnResultChange];
    [super goForward];
}

- (void)goBackward {
    if (self.isBeingReviewed) {
        [self saveAnswer:self.originalAnswer];
    }
    [self notifyDelegateOnResultChange];
    [super goBackward];
}

- (void)continueAction:(id)sender {
    if (self.continueActionButton.enabled) {
        if (![self shouldContinue]) {
            return;
        }
        
        ORK1SuppressPerformSelectorWarning(
                                          [self.continueButtonItem.target performSelector:self.continueButtonItem.action withObject:self.continueButtonItem];);
    }
}

#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != ORK1QuestionSectionAnswer) {
        return nil;
    }
    if (NO == self.questionStep.isFormatFitsChoiceCells) {
        return nil;
    }
    return indexPath;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == ORK1QuestionSectionAnswer;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [_choiceCellGroup didSelectCellAtIndexPath:indexPath];
    
    // Capture `isStepImmediateNavigation` before saving an answer.
    BOOL immediateNavigation = [self isStepImmediateNavigation];
    
    id answer = (self.questionStep.questionType == ORK1QuestionTypeBoolean) ? [_choiceCellGroup answerForBoolean] :[_choiceCellGroup answer];
    
    [self saveAnswer:answer];
    self.hasChangedAnswer = YES;
    
    if (immediateNavigation) {
        // Proceed as continueButton tapped
        ORK1SuppressPerformSelectorWarning(
                                         [self.continueButtonItem.target performSelector:self.continueButtonItem.action withObject:self.continueButtonItem];);
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = [ORK1SurveyAnswerCell suggestedCellHeightForView:tableView];
    
    switch (self.questionStep.questionType) {
        case ORK1QuestionTypeSingleChoice:
        case ORK1QuestionTypeMultipleChoice:{
            if ([self.questionStep isFormatFitsChoiceCells]) {
                height = [self heightForChoiceItemOptionAtIndex:indexPath.row];
            } else {
                height = [ORK1SurveyAnswerCellForPicker suggestedCellHeightForView:tableView];
            }
        }
            break;
        case ORK1QuestionTypeInteger:
        case ORK1QuestionTypeDecimal:{
            height = [ORK1SurveyAnswerCellForNumber suggestedCellHeightForView:tableView];
        }
            break;
        case ORK1QuestionTypeText:{
            height = [ORK1SurveyAnswerCellForText suggestedCellHeightForView:tableView];
        }
            break;
        case ORK1QuestionTypeTimeOfDay:
        case ORK1QuestionTypeTimeInterval:
        case ORK1QuestionTypeDate:
        case ORK1QuestionTypeDateAndTime:{
            height = [ORK1SurveyAnswerCellForPicker suggestedCellHeightForView:tableView];
        }
            break;
        default:{
        }
            break;
    }
    
    return height;
}

- (CGFloat)heightForChoiceItemOptionAtIndex:(NSInteger)index {
    ORK1TextChoice *option = [(ORK1TextChoiceAnswerFormat *)_answerFormat textChoices][index];
    return [ORK1ChoiceViewCell suggestedCellHeightForShortText:option.text
                                                      longText:(option.detailTextShouldDisplay) ? option.detailText : nil
                                                   inTableView:_tableView];
}

#pragma mark - ORK1SurveyAnswerCellDelegate

- (void)answerCell:(ORK1SurveyAnswerCell *)cell answerDidChangeTo:(id)answer dueUserAction:(BOOL)dueUserAction {
    [self saveAnswer:answer];
    
    if (self.hasChangedAnswer == NO && dueUserAction == YES) {
        self.hasChangedAnswer = YES;
    }
}

- (void)answerCell:(ORK1SurveyAnswerCell *)cell invalidInputAlertWithMessage:(NSString *)input {
    [self showValidityAlertWithMessage:input];
}

- (void)answerCell:(ORK1SurveyAnswerCell *)cell invalidInputAlertWithTitle:(NSString *)title message:(NSString *)message {
    [self showValidityAlertWithTitle:title message:message];
}

static NSString *const _ORK1AnswerRestoreKey = @"answer";
static NSString *const _ORK1HasChangedAnswerRestoreKey = @"hasChangedAnswer";
static NSString *const _ORK1OriginalAnswerRestoreKey = @"originalAnswer";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:_answer forKey:_ORK1AnswerRestoreKey];
    [coder encodeBool:_hasChangedAnswer forKey:_ORK1HasChangedAnswerRestoreKey];
    [coder encodeObject:_originalAnswer forKey:_ORK1OriginalAnswerRestoreKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    NSSet *decodeableSet = [NSSet setWithObjects:[NSNumber class], [NSString class], [NSDateComponents class], [NSArray class], nil];
    self.answer = [coder decodeObjectOfClasses:decodeableSet forKey:_ORK1AnswerRestoreKey];
    self.hasChangedAnswer = [coder decodeBoolForKey:_ORK1HasChangedAnswerRestoreKey];
    self.originalAnswer = [coder decodeObjectOfClasses:decodeableSet forKey:_ORK1OriginalAnswerRestoreKey];
    
    [self answerDidChange];
}

@end
