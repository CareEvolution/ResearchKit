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


#import "RK1QuestionStepViewController.h"

#import "RK1ChoiceViewCell.h"
#import "RK1QuestionStepView.h"
#import "RK1StepHeaderView_Internal.h"
#import "RK1SurveyAnswerCellForScale.h"
#import "RK1SurveyAnswerCellForNumber.h"
#import "RK1SurveyAnswerCellForText.h"
#import "RK1SurveyAnswerCellForPicker.h"
#import "RK1SurveyAnswerCellForImageSelection.h"
#import "RK1SurveyAnswerCellForLocation.h"
#import "RK1TableContainerView.h"
#import "RK1TextChoiceCellGroup.h"

#import "RK1NavigationContainerView_Internal.h"
#import "RK1QuestionStepViewController_Private.h"
#import "RK1StepViewController_Internal.h"
#import "RK1TaskViewController_Internal.h"

#import "RK1AnswerFormat_Internal.h"
#import "RK1QuestionStep_Internal.h"
#import "RK1Result_Private.h"
#import "RK1Step_Private.h"

#import "RK1Helpers_Internal.h"
#import "RK1Skin.h"


typedef NS_ENUM(NSInteger, RK1QuestionSection) {
    RK1QuestionSectionAnswer = 0,
    RK1QuestionSection_COUNT
};


@interface RK1QuestionStepViewController () <UITableViewDataSource,UITableViewDelegate, RK1SurveyAnswerCellDelegate> {
    id _answer;
    
    RK1TableContainerView *_tableContainer;
    RK1StepHeaderView *_headerView;
    RK1NavigationContainerView *_continueSkipView;
    RK1AnswerDefaultSource *_defaultSource;
    
    NSCalendar *_savedSystemCalendar;
    NSTimeZone *_savedSystemTimeZone;
    
    RK1TextChoiceCellGroup *_choiceCellGroup;
    
    id _defaultAnswer;
    
    BOOL _visible;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) RK1QuestionStepView *questionView;

@property (nonatomic, strong) RK1AnswerFormat *answerFormat;
@property (nonatomic, copy) id<NSCopying, NSObject, NSCoding> answer;

@property (nonatomic, strong) RK1ContinueButton *continueActionButton;

@property (nonatomic, strong) RK1SurveyAnswerCell *answerCell;

@property (nonatomic, readonly) UILabel *questionLabel;
@property (nonatomic, readonly) UILabel *promptLabel;

// If `hasChangedAnswer`, then a new `defaultAnswer` should not change the answer
@property (nonatomic, assign) BOOL hasChangedAnswer;

@property (nonatomic, copy) id<NSCopying, NSObject, NSCoding> originalAnswer;

@end


@implementation RK1QuestionStepViewController

- (void)initializeInternalButtonItems {
    [super initializeInternalButtonItems];
    self.internalSkipButtonItem.title = RK1LocalizedString(@"BUTTON_SKIP_QUESTION", nil);
}

- (instancetype)initWithStep:(RK1Step *)step result:(RK1Result *)result {
    self = [self initWithStep:step];
    if (self) {
		RK1StepResult *stepResult = (RK1StepResult *)result;
		if (stepResult && [stepResult results].count > 0) {
            RK1QuestionResult *questionResult = RK1DynamicCast([stepResult results].firstObject, RK1QuestionResult);
            id answer = [questionResult answer];
            if (questionResult != nil && answer == nil) {
                answer = RK1NullAnswerValue();
            }
			self.answer = answer;
            self.originalAnswer = answer;
		}
    }
    return self;
}

- (instancetype)initWithStep:(RK1Step *)step {
    self = [super initWithStep:step];
    if (self) {
        _defaultSource = [RK1AnswerDefaultSource sourceWithHealthStore:[HKHealthStore new]];
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
            _tableContainer = [[RK1TableContainerView alloc] initWithFrame:self.view.bounds];
            
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
            _headerView.instructionLabel.text = self.questionStep.text;
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
            _questionView = [RK1QuestionStepView new];
            _questionView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
            _questionView.questionStep = [self questionStep];
            [self.view addSubview:_questionView];
            
            if (_customQuestionView) {
                _questionView.questionCustomView = _customQuestionView;
                _customQuestionView.delegate = self;
                _customQuestionView.answer = [self answer];
                _customQuestionView.userInteractionEnabled = !self.readOnlyMode;
            } else {
                RK1QuestionStepCellHolderView *cellHolderView = [RK1QuestionStepCellHolderView new];
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
    if (self.answer == RK1NullAnswerValue()) {
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
    RK1AnswerFormat *format = [[self questionStep] answerFormat];
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
            RK1QuestionStepCellHolderView *holder = (RK1QuestionStepCellHolderView *)_questionView.questionCustomView;
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
            RK1_Log_Warning(@"Error fetching default: %@", error);
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
    RK1SurveyAnswerCellForPicker *cell = (RK1SurveyAnswerCellForPicker *)[(RK1QuestionStepCellHolderView *)_questionView.questionCustomView cell];
    if ([cell isKindOfClass:[RK1SurveyAnswerCellForPicker class]]) {
        [cell loadPicker];
    }
    
    _visible = YES;
    
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    _visible = NO;
}

- (void)setCustomQuestionView:(RK1QuestionStepCustomView *)customQuestionView {
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

- (RK1StepResult *)result {
    RK1StepResult *parentResult = [super result];
    RK1QuestionStep *questionStep = self.questionStep;
    
    if (self.answer) {
        RK1QuestionResult *result = [questionStep.answerFormat resultWithIdentifier:questionStep.identifier answer:self.answer];
        RK1AnswerFormat *impliedAnswerFormat = [questionStep impliedAnswerFormat];
        
        if ([impliedAnswerFormat isKindOfClass:[RK1DateAnswerFormat class]]) {
            RK1DateQuestionResult *dateQuestionResult = (RK1DateQuestionResult *)result;
            if (dateQuestionResult.dateAnswer) {
                NSCalendar *usedCalendar = [(RK1DateAnswerFormat *)impliedAnswerFormat calendar] ? : _savedSystemCalendar;
                dateQuestionResult.calendar = [NSCalendar calendarWithIdentifier:usedCalendar.calendarIdentifier ? : [NSCalendar currentCalendar].calendarIdentifier];
                dateQuestionResult.timeZone = _savedSystemTimeZone ? : [NSTimeZone systemTimeZone];
            }
        } else if ([impliedAnswerFormat isKindOfClass:[RK1NumericAnswerFormat class]]) {
            RK1NumericQuestionResult *nqr = (RK1NumericQuestionResult *)result;
            if (nqr.unit == nil) {
                nqr.unit = [(RK1NumericAnswerFormat *)impliedAnswerFormat unit];
            }
        }
        
        result.startDate = parentResult.startDate;
        result.endDate = parentResult.endDate;
        
        parentResult.results = @[result];
    }
    
    return parentResult;
}

#pragma mark - Internal

- (RK1QuestionStep *)questionStep {
    assert(!self.step || [self.step isKindOfClass:[RK1QuestionStep class]]);
    return (RK1QuestionStep *)self.step;
}

- (BOOL)hasAnswer {
    return !RK1IsAnswerEmpty(self.answer);
}

- (void)saveAnswer:(id)answer {
    self.answer = answer;
    _savedSystemCalendar = [NSCalendar currentCalendar];
    _savedSystemTimeZone = [NSTimeZone systemTimeZone];
    [self notifyDelegateOnResultChange];
}

- (void)skipForward {
    // Null out the answer before proceeding
    [self saveAnswer:RK1NullAnswerValue()];
    RK1SurveyAnswerCell *cell = self.answerCell;
    cell.answer = RK1NullAnswerValue();
    
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
    if (self.questionStep.questionType == RK1QuestionTypeMultipleChoice && (_answer == nil || _answer == RK1NullAnswerValue())) {
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
        enabled = self.readOnlyMode ? NO : enabled && !RK1IsAnswerEmpty(self.originalAnswer);
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

#pragma mark - RK1QuestionStepCustomViewDelegate

- (void)customQuestionStepView:(RK1QuestionStepCustomView *)customQuestionStepView didChangeAnswer:(id)answer; {
    [self saveAnswer:answer];
    self.hasChangedAnswer = YES;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return RK1QuestionSection_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    RK1AnswerFormat *impliedAnswerFormat = [_answerFormat impliedAnswerFormat];
    
    if (section == RK1QuestionSectionAnswer) {
        _choiceCellGroup = [[RK1TextChoiceCellGroup alloc] initWithTextChoiceAnswerFormat:(RK1TextChoiceAnswerFormat *)impliedAnswerFormat
                                                                                   answer:self.answer
                                                                       beginningIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]
                                                                      immediateNavigation:[self isStepImmediateNavigation]];
        return _choiceCellGroup.size;
    }
    return 0;
}

- (RK1SurveyAnswerCell *)answerCellForTableView:(UITableView *)tableView {
    static NSDictionary *typeAndCellMapping = nil;
    static NSString *identifier = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        typeAndCellMapping = @{@(RK1QuestionTypeScale): [RK1SurveyAnswerCellForScale class],
                               @(RK1QuestionTypeDecimal): [RK1SurveyAnswerCellForNumber class],
                               @(RK1QuestionTypeText): [RK1SurveyAnswerCellForText class],
                               @(RK1QuestionTypeTimeOfDay): [RK1SurveyAnswerCellForPicker class],
                               @(RK1QuestionTypeDate): [RK1SurveyAnswerCellForPicker class],
                               @(RK1QuestionTypeDateAndTime): [RK1SurveyAnswerCellForPicker class],
                               @(RK1QuestionTypeTimeInterval): [RK1SurveyAnswerCellForPicker class],
                               @(RK1QuestionTypeHeight) : [RK1SurveyAnswerCellForPicker class],
                               @(RK1QuestionTypeWeight) : [RK1SurveyAnswerCellForPicker class],
                               @(RK1QuestionTypeMultiplePicker) : [RK1SurveyAnswerCellForPicker class],
                               @(RK1QuestionTypeInteger): [RK1SurveyAnswerCellForNumber class],
                               @(RK1QuestionTypeLocation): [RK1SurveyAnswerCellForLocation class]};
    });
    
    // SingleSelectionPicker Cell && Other Cells
    Class class = typeAndCellMapping[@(self.questionStep.questionType)];
    
    if ([self.questionStep isFormatChoiceWithImageOptions]) {
        class = [RK1SurveyAnswerCellForImageSelection class];
    } else if ([self.questionStep isFormatTextfield]) {
        // Override for single-line text entry
        class = [RK1SurveyAnswerCellForTextField class];
    } else if ([[self.questionStep impliedAnswerFormat] isKindOfClass:[RK1ValuePickerAnswerFormat class]]) {
        class = [RK1SurveyAnswerCellForPicker class];
    }
    
    identifier = NSStringFromClass(class);
    
    NSAssert(class != nil, @"class should not be nil");
    
    RK1SurveyAnswerCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil) { 
        cell = [[class alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier step:[self questionStep] answer:self.answer delegate:self];
    }
    
    self.answerCell = cell;
    
    if ([self.questionStep isFormatTextfield] ||
        [cell isKindOfClass:[RK1SurveyAnswerCellForScale class]] ||
        [cell isKindOfClass:[RK1SurveyAnswerCellForPicker class]]) {
        cell.separatorInset = UIEdgeInsetsMake(0, RK1ScreenMetricMaxDimension, 0, 0);
    }

    if ([cell isKindOfClass:[RK1SurveyAnswerCellForPicker class]] && _visible) {
        [(RK1SurveyAnswerCellForPicker *)cell loadPicker];
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
    
    RK1ChoiceViewCell *cell = [_choiceCellGroup cellAtIndexPath:indexPath withReuseIdentifier:identifier];
    
    cell.userInteractionEnabled = !self.readOnlyMode;
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.layoutMargins = UIEdgeInsetsZero;
    cell.separatorInset = (UIEdgeInsets){.left = RK1StandardLeftMarginForTableViewCell(tableView)};
}

- (BOOL)shouldContinue {
    RK1SurveyAnswerCell *cell = self.answerCell;
    if (!cell) {
        return YES;
    }

    return [cell shouldContinue];
}

- (void)goForward {
    if (![self shouldContinue]) {
        return;
    }
    
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
        
        RK1SuppressPerformSelectorWarning(
                                          [self.continueButtonItem.target performSelector:self.continueButtonItem.action withObject:self.continueButtonItem];);
    }
}

#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != RK1QuestionSectionAnswer) {
        return nil;
    }
    if (NO == self.questionStep.isFormatFitsChoiceCells) {
        return nil;
    }
    return indexPath;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == RK1QuestionSectionAnswer;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [_choiceCellGroup didSelectCellAtIndexPath:indexPath];
    
    // Capture `isStepImmediateNavigation` before saving an answer.
    BOOL immediateNavigation = [self isStepImmediateNavigation];
    
    id answer = (self.questionStep.questionType == RK1QuestionTypeBoolean) ? [_choiceCellGroup answerForBoolean] :[_choiceCellGroup answer];
    
    [self saveAnswer:answer];
    self.hasChangedAnswer = YES;
    
    if (immediateNavigation) {
        // Proceed as continueButton tapped
        RK1SuppressPerformSelectorWarning(
                                         [self.continueButtonItem.target performSelector:self.continueButtonItem.action withObject:self.continueButtonItem];);
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = [RK1SurveyAnswerCell suggestedCellHeightForView:tableView];
    
    switch (self.questionStep.questionType) {
        case RK1QuestionTypeSingleChoice:
        case RK1QuestionTypeMultipleChoice:{
            if ([self.questionStep isFormatFitsChoiceCells]) {
                height = [self heightForChoiceItemOptionAtIndex:indexPath.row];
            } else {
                height = [RK1SurveyAnswerCellForPicker suggestedCellHeightForView:tableView];
            }
        }
            break;
        case RK1QuestionTypeInteger:
        case RK1QuestionTypeDecimal:{
            height = [RK1SurveyAnswerCellForNumber suggestedCellHeightForView:tableView];
        }
            break;
        case RK1QuestionTypeText:{
            height = [RK1SurveyAnswerCellForText suggestedCellHeightForView:tableView];
        }
            break;
        case RK1QuestionTypeTimeOfDay:
        case RK1QuestionTypeTimeInterval:
        case RK1QuestionTypeDate:
        case RK1QuestionTypeDateAndTime:{
            height = [RK1SurveyAnswerCellForPicker suggestedCellHeightForView:tableView];
        }
            break;
        default:{
        }
            break;
    }
    
    return height;
}

- (CGFloat)heightForChoiceItemOptionAtIndex:(NSInteger)index {
    RK1TextChoice *option = [(RK1TextChoiceAnswerFormat *)_answerFormat textChoices][index];
    CGFloat height = [RK1ChoiceViewCell suggestedCellHeightForShortText:option.text LongText:option.detailText inTableView:_tableView];
    return height;
}

#pragma mark - RK1SurveyAnswerCellDelegate

- (void)answerCell:(RK1SurveyAnswerCell *)cell answerDidChangeTo:(id)answer dueUserAction:(BOOL)dueUserAction {
    [self saveAnswer:answer];
    
    if (self.hasChangedAnswer == NO && dueUserAction == YES) {
        self.hasChangedAnswer = YES;
    }
}

- (void)answerCell:(RK1SurveyAnswerCell *)cell invalidInputAlertWithMessage:(NSString *)input {
    [self showValidityAlertWithMessage:input];
}

- (void)answerCell:(RK1SurveyAnswerCell *)cell invalidInputAlertWithTitle:(NSString *)title message:(NSString *)message {
    [self showValidityAlertWithTitle:title message:message];
}

static NSString *const _RK1AnswerRestoreKey = @"answer";
static NSString *const _RK1HasChangedAnswerRestoreKey = @"hasChangedAnswer";
static NSString *const _RK1OriginalAnswerRestoreKey = @"originalAnswer";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:_answer forKey:_RK1AnswerRestoreKey];
    [coder encodeBool:_hasChangedAnswer forKey:_RK1HasChangedAnswerRestoreKey];
    [coder encodeObject:_originalAnswer forKey:_RK1OriginalAnswerRestoreKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    NSSet *decodeableSet = [NSSet setWithObjects:[NSNumber class], [NSString class], [NSDateComponents class], [NSArray class], nil];
    self.answer = [coder decodeObjectOfClasses:decodeableSet forKey:_RK1AnswerRestoreKey];
    self.hasChangedAnswer = [coder decodeBoolForKey:_RK1HasChangedAnswerRestoreKey];
    self.originalAnswer = [coder decodeObjectOfClasses:decodeableSet forKey:_RK1OriginalAnswerRestoreKey];
    
    [self answerDidChange];
}

@end
