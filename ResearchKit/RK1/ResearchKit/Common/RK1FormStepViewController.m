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


#import "RK1FormStepViewController.h"

#import "RK1Caption1Label.h"
#import "RK1ChoiceViewCell.h"
#import "RK1FormItemCell.h"
#import "RK1FormSectionTitleLabel.h"
#import "RK1StepHeaderView_Internal.h"
#import "RK1TableContainerView.h"
#import "RK1TextChoiceCellGroup.h"

#import "RK1NavigationContainerView_Internal.h"
#import "RK1StepViewController_Internal.h"
#import "RK1TaskViewController_Internal.h"

#import "RK1AnswerFormat_Internal.h"
#import "RK1FormItem_Internal.h"
#import "RK1Result_Private.h"
#import "RK1Step_Private.h"
#import "RK1ResultPredicate.h"

#import "RK1Helpers_Internal.h"
#import "RK1Skin.h"


@interface RK1TableCellItem : NSObject

- (instancetype)initWithFormItem:(RK1FormItem *)formItem;
- (instancetype)initWithFormItem:(RK1FormItem *)formItem choiceIndex:(NSUInteger)index;

@property (nonatomic, copy) RK1FormItem *formItem;

@property (nonatomic, copy) RK1AnswerFormat *answerFormat;

@property (nonatomic, readonly) CGFloat labelWidth;

// For choice types only
@property (nonatomic, copy, readonly) RK1TextChoice *choice;

@end


@implementation RK1TableCellItem

- (instancetype)initWithFormItem:(RK1FormItem *)formItem {
    self = [super init];
    if (self) {
        self.formItem = formItem;
        _answerFormat = [[formItem impliedAnswerFormat] copy];
    }
    return self;
}

- (instancetype)initWithFormItem:(RK1FormItem *)formItem choiceIndex:(NSUInteger)index {
    self = [super init];
    if (self) {
        self.formItem = formItem;
        _answerFormat = [[formItem impliedAnswerFormat] copy];
        
        if ([self textChoiceAnswerFormat] != nil) {
            _choice = [self.textChoiceAnswerFormat.textChoices[index] copy];
        }
    }
    return self;
}

- (RK1TextChoiceAnswerFormat *)textChoiceAnswerFormat {
    if ([self.answerFormat isKindOfClass:[RK1TextChoiceAnswerFormat class]]) {
        return (RK1TextChoiceAnswerFormat *)self.answerFormat;
    }
    return nil;
}

- (CGFloat)labelWidth {
    static RK1Caption1Label *sharedLabel;
    
    if (sharedLabel == nil) {
        sharedLabel = [RK1Caption1Label new];
    }
    
    sharedLabel.text = _formItem.text;
    
    return [sharedLabel textRectForBounds:CGRectInfinite limitedToNumberOfLines:1].size.width;
}

@end


@interface RK1TableSection : NSObject

- (instancetype)initWithSectionIndex:(NSUInteger)index;

@property (nonatomic, assign, readonly) NSUInteger index;

@property (nonatomic, copy) NSString *title;

@property (nonatomic, copy, readonly) NSArray<RK1TableCellItem *> *items;
@property (nonatomic, copy, readonly) NSArray<RK1FormItem *> *formItems;

@property (nonatomic, readonly) BOOL hasChoiceRows;

@property (nonatomic, strong) RK1TextChoiceCellGroup *textChoiceCellGroup;

- (void)addFormItem:(RK1FormItem *)item;
- (RK1TableCellItem * _Nullable)cellItemForFormItem:(RK1FormItem *)formItem;

@property (nonatomic, readonly) CGFloat maxLabelWidth;

@end


@implementation RK1TableSection {
    NSMutableDictionary<RK1FormItem *, RK1TableCellItem*> *_cellItemForFormItem;
}

- (instancetype)initWithSectionIndex:(NSUInteger)index {
    self = [super init];
    if (self) {
        _items = [NSMutableArray new];
        _formItems = [NSMutableArray new];
        self.title = nil;
        _index = index;
        _cellItemForFormItem = [NSMutableDictionary new];
    }
    return self;
}

- (void)setTitle:(NSString *)title {
    _title = [[title uppercaseStringWithLocale:[NSLocale currentLocale]] copy];
}

- (void)addFormItem:(RK1FormItem *)item {
    if ([[item impliedAnswerFormat] isKindOfClass:[RK1TextChoiceAnswerFormat class]]) {
        _hasChoiceRows = YES;
        RK1TextChoiceAnswerFormat *textChoiceAnswerFormat = (RK1TextChoiceAnswerFormat *)[item impliedAnswerFormat];
        
        _textChoiceCellGroup = [[RK1TextChoiceCellGroup alloc] initWithTextChoiceAnswerFormat:textChoiceAnswerFormat
                                                                                       answer:nil
                                                                           beginningIndexPath:[NSIndexPath indexPathForRow:0 inSection:_index]
                                                                          immediateNavigation:NO];
        
        [textChoiceAnswerFormat.textChoices enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            RK1TableCellItem *cellItem = [[RK1TableCellItem alloc] initWithFormItem:item choiceIndex:idx];
            [(NSMutableArray *)self.items addObject:cellItem];
        }];
        
    } else {
        RK1TableCellItem *cellItem = [[RK1TableCellItem alloc] initWithFormItem:item];
        [(NSMutableArray *)self.items addObject:cellItem];
        _cellItemForFormItem[item] = cellItem;
    }
    [(NSMutableArray *)self.formItems addObject:item];
}

- (RK1TableCellItem * _Nullable)cellItemForFormItem:(RK1FormItem *)formItem {
    return _cellItemForFormItem[formItem];
}

- (CGFloat)maxLabelWidth {
    CGFloat max = 0;
    for (RK1TableCellItem *item in self.items) {
        if (item.labelWidth > max) {
            max = item.labelWidth;
        }
    }
    return max;
}

@end

@interface RK1FormSectionHeaderView : UIView

- (instancetype)initWithTitle:(NSString *)title tableView:(UITableView *)tableView firstSection:(BOOL)firstSection;

@property (nonatomic, strong) NSLayoutConstraint *leftMarginConstraint;

@property (nonatomic, weak) UITableView *tableView;

@end


@implementation RK1FormSectionHeaderView {
    RK1FormSectionTitleLabel *_label;
    BOOL _firstSection;
}

- (instancetype)initWithTitle:(NSString *)title tableView:(UITableView *)tableView firstSection:(BOOL)firstSection {
    self = [super init];
    if (self) {
        _tableView = tableView;
        _firstSection = firstSection;
        self.backgroundColor = [UIColor whiteColor];
        
        _label = [RK1FormSectionTitleLabel new];
        _label.text = title;
        _label.numberOfLines = 0;
        _label.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_label];
        [self setUpConstraints];
    }
    return self;
}

- (void)setUpConstraints {
    
    const CGFloat LabelFirstBaselineToTop = _firstSection ? 20.0 : 40.0;
    const CGFloat LabelLastBaselineToBottom = -10.0;
    const CGFloat LabelRightMargin = -4.0;
    
    NSMutableArray *constraints = [NSMutableArray new];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_label
                                                        attribute:NSLayoutAttributeFirstBaseline
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeTop
                                                       multiplier:1.0
                                                         constant:LabelFirstBaselineToTop]];
    
    self.leftMarginConstraint = [NSLayoutConstraint constraintWithItem:_label
                                                             attribute:NSLayoutAttributeLeft
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeLeft
                                                            multiplier:1.0
                                                              constant:0.0];
    
    [constraints addObject:self.leftMarginConstraint];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_label
                                                        attribute:NSLayoutAttributeLastBaseline
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeBottom
                                                       multiplier:1.0
                                                         constant:LabelLastBaselineToBottom]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_label
                                                        attribute:NSLayoutAttributeRight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeRight
                                                       multiplier:1.0
                                                         constant:LabelRightMargin]];
    
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)updateConstraints {
    [super updateConstraints];
    self.leftMarginConstraint.constant = _tableView.layoutMargins.left;
}

@end

@interface RK1FormStepViewController () <UITableViewDataSource, UITableViewDelegate, RK1FormItemCellDelegate, RK1TableContainerViewDelegate>

@property (nonatomic, strong) RK1TableContainerView *tableContainer;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) RK1StepHeaderView *headerView;

@property (nonatomic, strong) NSMutableDictionary *savedAnswers;
@property (nonatomic, strong) NSMutableDictionary *savedAnswerDates;
@property (nonatomic, strong) NSMutableDictionary *savedSystemCalendars;
@property (nonatomic, strong) NSMutableDictionary *savedSystemTimeZones;
@property (nonatomic, strong) NSDictionary *originalAnswers;

@property (nonatomic, strong) NSMutableDictionary *savedDefaults;

@end


@implementation RK1FormStepViewController {
    RK1AnswerDefaultSource *_defaultSource;
    RK1NavigationContainerView *_continueSkipView;
    NSMutableSet *_formItemCells;
    NSMutableArray<RK1TableSection *> *_sections;
    NSMutableArray<RK1TableSection *> *_allSections;
    NSMutableArray<RK1FormItem *> *_hiddenFormItems;
    NSMutableArray<RK1TableCellItem *> *_hiddenCellItems;
    BOOL _skipped;
    RK1FormItemCell *_currentFirstResponderCell;
}

- (instancetype)RK1FormStepViewController_initWithResult:(RK1Result *)result {
    _defaultSource = [RK1AnswerDefaultSource sourceWithHealthStore:[HKHealthStore new]];
    if (result) {
        NSAssert([result isKindOfClass:[RK1StepResult class]], @"Expect a RK1StepResult instance");

        NSArray *resultsArray = [(RK1StepResult *)result results];
        for (RK1QuestionResult *result in resultsArray) {
            id answer = result.answer ? : RK1NullAnswerValue();
            [self setAnswer:answer forIdentifier:result.identifier];
        }
        self.originalAnswers = [[NSDictionary alloc] initWithDictionary:self.savedAnswers];
    }
    return self;
}

- (instancetype)initWithStep:(RK1Step *)step {
    self = [super initWithStep:step];
    return [self RK1FormStepViewController_initWithResult:nil];
}

- (instancetype)initWithStep:(RK1Step *)step result:(RK1Result *)result {

    self = [super initWithStep:step];
    return [self RK1FormStepViewController_initWithResult:result];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self stepDidChange];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.taskViewController setRegisteredScrollView:_tableView];
    
    NSMutableSet *types = [NSMutableSet set];
    for (RK1FormItem *item in [self formItems]) {
        RK1AnswerFormat *format = [item answerFormat];
        HKObjectType *objType = [format healthKitObjectTypeForAuthorization];
        if (objType) {
            [types addObject:objType];
        }
    }
    
    BOOL refreshDefaultsPending = NO;
    if (types.count) {
        NSSet<HKObjectType *> *alreadyRequested = [[self taskViewController] requestedHealthTypesForRead];
        if (![types isSubsetOfSet:alreadyRequested]) {
            refreshDefaultsPending = YES;
            [_defaultSource.healthStore requestAuthorizationToShareTypes:nil readTypes:types completion:^(BOOL success, NSError *error) {
                if (!success) {
                    RK1_Log_Debug(@"Authorization: %@",error);
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self refreshDefaults];
                });
            }];
        }
    }
    if (!refreshDefaultsPending) {
        [self refreshDefaults];
    }
    
    // Reset skipped flag - result can now be non-empty
    _skipped = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (void)updateDefaults:(NSMutableDictionary *)defaults {
    _savedDefaults = defaults;
    
    for (RK1FormItemCell *cell in [_tableView visibleCells]) {
        NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
        
        RK1TableSection *section = _sections[indexPath.section];
        RK1TableCellItem *cellItem = [section items][indexPath.row];
        RK1FormItem *formItem = cellItem.formItem;
        if ([cell isKindOfClass:[RK1ChoiceViewCell class]]) {
            id answer = _savedAnswers[formItem.identifier];
            answer = answer ? : _savedDefaults[formItem.identifier];
            
            [section.textChoiceCellGroup setAnswer:answer];
            
            // Answers need to be saved.
            [self setAnswer:answer forIdentifier:formItem.identifier];
            
        } else {
            cell.defaultAnswer = _savedDefaults[formItem.identifier];
        }
    }
    
    _skipped = NO;
    [self updateButtonStates];
    [self notifyDelegateOnResultChange];
}

- (void)refreshDefaults {
    NSArray *formItems = [self formItems];
    RK1AnswerDefaultSource *source = _defaultSource;
    RK1WeakTypeOf(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        __block NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
        for (RK1FormItem *formItem in formItems) {
            [source fetchDefaultValueForAnswerFormat:formItem.answerFormat handler:^(id defaultValue, NSError *error) {
                if (defaultValue != nil) {
                    defaults[formItem.identifier] = defaultValue;
                } else if (error != nil) {
                    RK1_Log_Warning(@"Error fetching default for %@: %@", formItem, error);
                }
                dispatch_semaphore_signal(semaphore);
            }];
        }
        for (__unused RK1FormItem *formItem in formItems) {
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }
        
        // All fetches have completed.
        dispatch_async(dispatch_get_main_queue(), ^{
            RK1StrongTypeOf(weakSelf) strongSelf = weakSelf;
            [strongSelf updateDefaults:defaults];
        });
        
    });
    
    
}

- (void)removeAnswerForIdentifier:(NSString *)identifier {
    if (identifier == nil) {
        return;
    }
    [_savedAnswers removeObjectForKey:identifier];
    _savedAnswerDates[identifier] = [NSDate date];
}

- (void)setAnswer:(id)answer forIdentifier:(NSString *)identifier {
    if (answer == nil || identifier == nil) {
        return;
    }
    if (_savedAnswers == nil) {
        _savedAnswers = [NSMutableDictionary new];
    }
    if (_savedAnswerDates == nil) {
        _savedAnswerDates = [NSMutableDictionary new];
    }
    if (_savedSystemCalendars == nil) {
        _savedSystemCalendars = [NSMutableDictionary new];
    }
    if (_savedSystemTimeZones == nil) {
        _savedSystemTimeZones = [NSMutableDictionary new];
    }
    _savedAnswers[identifier] = answer;
    _savedAnswerDates[identifier] = [NSDate date];
    _savedSystemCalendars[identifier] = [NSCalendar currentCalendar];
    _savedSystemTimeZones[identifier] = [NSTimeZone systemTimeZone];
}

// Override to monitor button title change
- (void)setContinueButtonItem:(UIBarButtonItem *)continueButtonItem {
    [super setContinueButtonItem:continueButtonItem];
    _continueSkipView.continueButtonItem = continueButtonItem;
    [self updateButtonStates];
}


- (void)setLearnMoreButtonItem:(UIBarButtonItem *)learnMoreButtonItem {
    [super setLearnMoreButtonItem:learnMoreButtonItem];
    _headerView.learnMoreButtonItem = self.learnMoreButtonItem;
    [_tableContainer setNeedsLayout];
}

- (void)setSkipButtonItem:(UIBarButtonItem *)skipButtonItem {
    [super setSkipButtonItem:skipButtonItem];
    
    _continueSkipView.skipButtonItem = skipButtonItem;
    [self updateButtonStates];
}

- (void)stepDidChange {
    [super stepDidChange];

    [_tableContainer removeFromSuperview];
    _tableContainer = nil;
    
    _tableView.delegate = nil;
    _tableView.dataSource = nil;
    _tableView = nil;
    _formItemCells = nil;
    _headerView = nil;
    _continueSkipView = nil;
    
    if (self.isViewLoaded && self.step) {
        [self buildSections];
        [self hideSections];
        
        _formItemCells = [NSMutableSet new];
        
        _tableContainer = [[RK1TableContainerView alloc] initWithFrame:self.view.bounds];
        _tableContainer.delegate = self;
        [self.view addSubview:_tableContainer];
        _tableContainer.tapOffView = self.view;
        
        _tableView = _tableContainer.tableView;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
        _tableView.estimatedRowHeight = RK1GetMetricForWindow(RK1ScreenMetricTableCellDefaultHeight, self.view.window);
        _tableView.estimatedSectionHeaderHeight = 30.0;
        
        _headerView = _tableContainer.stepHeaderView;
        _headerView.captionLabel.text = [[self formStep] title];
        _headerView.captionLabel.useSurveyMode = [[self formStep] useSurveyMode];
        _headerView.instructionLabel.text = [[self formStep] text];
        _headerView.learnMoreButtonItem = self.learnMoreButtonItem;
        
        _continueSkipView = _tableContainer.continueSkipContainerView;
        _continueSkipView.skipButtonItem = self.skipButtonItem;
        _continueSkipView.continueEnabled = [self continueButtonEnabled];
        _continueSkipView.continueButtonItem = self.continueButtonItem;
        _continueSkipView.optional = self.step.optional;
        _continueSkipView.footnoteLabel.text = [self formStep].footnote;
        if (self.readOnlyMode) {
            _continueSkipView.optional = YES;
            [_continueSkipView setNeverHasContinueButton:YES];
            _continueSkipView.skipEnabled = [self skipButtonEnabled];
            _continueSkipView.skipButton.accessibilityTraits = UIAccessibilityTraitStaticText;
        }

    }
}

- (void)buildSections {
    NSArray *items = [self allFormItems];
    
    _allSections = [NSMutableArray new];
    RK1TableSection *section = nil;
    
    NSArray *singleSectionTypes = @[@(RK1QuestionTypeBoolean),
                                    @(RK1QuestionTypeSingleChoice),
                                    @(RK1QuestionTypeMultipleChoice),
                                    @(RK1QuestionTypeLocation)];

    for (RK1FormItem *item in items) {
        // Section header
        if ([item impliedAnswerFormat] == nil) {
            // Add new section
            section = [[RK1TableSection alloc] initWithSectionIndex:_allSections.count];
            [_allSections addObject:section];
            
            // Save title
            section.title = item.text;
        // Actual item
        } else {
            RK1AnswerFormat *answerFormat = [item impliedAnswerFormat];
            
            BOOL multiCellChoices = ([singleSectionTypes containsObject:@(answerFormat.questionType)] &&
                                     NO == [answerFormat isKindOfClass:[RK1ValuePickerAnswerFormat class]]);
            
            BOOL multilineTextEntry = (answerFormat.questionType == RK1QuestionTypeText && [(RK1TextAnswerFormat *)answerFormat multipleLines]);
            
            BOOL scale = (answerFormat.questionType == RK1QuestionTypeScale);
            
            // Items require individual section
            if (multiCellChoices || multilineTextEntry || scale) {
                // Add new section
                section = [[RK1TableSection alloc]  initWithSectionIndex:_allSections.count];
                [_allSections addObject:section];
                
                // Save title
                section.title = item.text;
    
                [section addFormItem:item];

                // following item should start a new section
                section = nil;
            } else {
                // In case no section available, create new one.
                if (section == nil) {
                    section = [[RK1TableSection alloc]  initWithSectionIndex:_allSections.count];
                    [_allSections addObject:section];
                }
                [section addFormItem:item];
            }
        }
    }
}

- (NSInteger)numberOfAnsweredFormItemsInDictionary:(NSDictionary *)dictionary {
    __block NSInteger nonNilCount = 0;
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id answer, BOOL *stop) {
        if (RK1IsAnswerEmpty(answer) == NO) {
            nonNilCount ++;
        }
    }];
    return nonNilCount;
}

- (NSInteger)numberOfAnsweredFormItems {
    return [self numberOfAnsweredFormItemsInDictionary:self.savedAnswers];
}

- (BOOL)allAnsweredFormItemsAreValid {
    for (RK1FormItem *item in [self formItems]) {
        id answer = _savedAnswers[item.identifier];
        if (RK1IsAnswerEmpty(answer) == NO && ![item.impliedAnswerFormat isAnswerValid:answer]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)allNonOptionalFormItemsHaveAnswers {
    RK1TaskResult *taskResult = self.taskViewController.result;
    for (RK1FormItem *item in [self formItems]) {
        BOOL hideFormItem = [item.hidePredicate evaluateWithObject:@[taskResult]
                                             substitutionVariables:@{RK1ResultPredicateTaskIdentifierVariableName : taskResult.identifier}];
        if (!item.optional && !hideFormItem) {
            id answer = _savedAnswers[item.identifier];
            if (RK1IsAnswerEmpty(answer) || ![item.impliedAnswerFormat isAnswerValid:answer]) {
                return NO;
            }
        }
    }
    return YES;
}

- (BOOL)continueButtonEnabled {
    BOOL enabled = ([self numberOfAnsweredFormItems] > 0
                    && [self allAnsweredFormItemsAreValid]
                    && [self allNonOptionalFormItemsHaveAnswers]);
    if (self.isBeingReviewed) {
        enabled = enabled && ![self.savedAnswers isEqualToDictionary:self.originalAnswers];
    }
    return enabled;
}

- (BOOL)skipButtonEnabled {
    BOOL enabled = self.formStep.optional;
    if (self.isBeingReviewed) {
        enabled = self.readOnlyMode ? NO : enabled && [self numberOfAnsweredFormItemsInDictionary:self.originalAnswers] > 0;
    }
    return enabled;
}

- (void)hideSections {
    NSArray<RK1TableSection *> *oldSections = _sections;
    _sections = [NSMutableArray new];
    
    NSArray *oldHiddenCellItems = _hiddenCellItems;
    
    _hiddenCellItems = [NSMutableArray new];
    _hiddenFormItems = [NSMutableArray new];
    
    RK1TaskResult *taskResult = self.taskViewController.result;
    
    NSMutableIndexSet *sectionsToInsert = [NSMutableIndexSet indexSet];
    NSMutableIndexSet *sectionsToDelete = [NSMutableIndexSet indexSet];
    NSMutableIndexSet *sectionsToUpdateCells = [NSMutableIndexSet indexSet];
    
    for (RK1TableSection *section in _allSections) {
        BOOL hideSection = YES;
        for (RK1FormItem *formItem in section.formItems) {
            BOOL formItemIsHidden = [formItem.hidePredicate evaluateWithObject:@[taskResult]
                                                         substitutionVariables:@{RK1ResultPredicateTaskIdentifierVariableName : taskResult.identifier}];
            RK1TableCellItem *cellItem = [section cellItemForFormItem:formItem];
            if (formItemIsHidden) {
                if (cellItem) {
                    [_hiddenCellItems addObject:cellItem];
                }
                [_hiddenFormItems addObject:formItem];
            } else {
                hideSection = NO;
            }
        }
        if (!hideSection) {
            [_sections addObject:section];
            if (![oldSections containsObject:section]) {
                [sectionsToInsert addIndex:_sections.count - 1];
            }
            if (section.formItems.count > 1 && ![oldHiddenCellItems isEqualToArray:_hiddenCellItems]) {
                [sectionsToUpdateCells addIndex:_sections.count - 1];
            }
        } else {
            if ([oldSections containsObject:section]) {
                [sectionsToDelete addIndex:[oldSections indexOfObject:section]];
            }
        }
    }
    
    if (_tableView != nil) {
        if (sectionsToInsert.count == 0 && sectionsToDelete.count == 0  && sectionsToUpdateCells.count == 0) {
            return;
        }
        [_tableView beginUpdates];
        if (sectionsToDelete.count > 0) {
            [_tableView deleteSections:sectionsToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        if (sectionsToInsert.count > 0) {
            [_tableView insertSections:sectionsToInsert withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        [_tableView endUpdates];
        if (sectionsToUpdateCells.count > 0) {
            [_tableView reloadSections:sectionsToUpdateCells withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

- (NSIndexPath *)unhiddenIndexPathForIndexPath:(NSIndexPath *)hiddenIndexPath {
    return [NSIndexPath indexPathForRow:hiddenIndexPath.row inSection:[_allSections indexOfObject:_sections[hiddenIndexPath.section]]];
}

- (void)updateButtonStates {
    _continueSkipView.continueEnabled = [self continueButtonEnabled];
    _continueSkipView.skipEnabled = [self skipButtonEnabled];
}

#pragma mark Helpers

- (RK1FormStep *)formStep {
    NSAssert(!self.step || [self.step isKindOfClass:[RK1FormStep class]], nil);
    return (RK1FormStep *)self.step;
}

- (NSArray *)allFormItems {
    return [[self formStep] formItems];
}

- (NSArray *)formItems {
    NSArray *formItems = [self allFormItems];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:formItems.count];
    for (RK1FormItem *item in formItems) {
        if (item.answerFormat != nil) {
            [array addObject:item];
        }
    }
    
    return [array copy];
}

- (void)showValidityAlertWithMessage:(NSString *)text {
    // Ignore if our answer is null
    if (_skipped) {
        return;
    }
    
    [super showValidityAlertWithMessage:text];
}

- (RK1StepResult *)result {
    RK1StepResult *parentResult = [super result];
    
    NSArray *items = [self formItems];
    
    // "Now" is the end time of the result, which is either actually now,
    // or the last time we were in the responder chain.
    NSDate *now = parentResult.endDate;
    
    NSMutableArray *qResults = [NSMutableArray new];
    for (RK1FormItem *item in items) {
        
        if ([_hiddenFormItems containsObject:item]) {
            continue;
        }

        // Skipped forms report a "null" value for every item -- by skipping, the user has explicitly said they don't want
        // to report any values from this form.
        
        id answer = RK1NullAnswerValue();
        NSDate *answerDate = now;
        NSCalendar *systemCalendar = [NSCalendar currentCalendar];
        NSTimeZone *systemTimeZone = [NSTimeZone systemTimeZone];
        if (!_skipped) {
            answer = _savedAnswers[item.identifier];
            answerDate = _savedAnswerDates[item.identifier] ? : now;
            systemCalendar = _savedSystemCalendars[item.identifier];
            NSAssert(answer == nil || answer == RK1NullAnswerValue() || systemCalendar != nil, @"systemCalendar NOT saved");
            systemTimeZone = _savedSystemTimeZones[item.identifier];
            NSAssert(answer == nil || answer == RK1NullAnswerValue() || systemTimeZone != nil, @"systemTimeZone NOT saved");
        }
        
        RK1QuestionResult *result = [item.answerFormat resultWithIdentifier:item.identifier answer:answer];
        RK1AnswerFormat *impliedAnswerFormat = [item impliedAnswerFormat];
        
        if ([impliedAnswerFormat isKindOfClass:[RK1DateAnswerFormat class]]) {
            RK1DateQuestionResult *dqr = (RK1DateQuestionResult *)result;
            if (dqr.dateAnswer) {
                NSCalendar *usedCalendar = [(RK1DateAnswerFormat *)impliedAnswerFormat calendar] ? : systemCalendar;
                dqr.calendar = [NSCalendar calendarWithIdentifier:usedCalendar.calendarIdentifier];
                dqr.timeZone = systemTimeZone;
            }
        } else if ([impliedAnswerFormat isKindOfClass:[RK1NumericAnswerFormat class]]) {
            RK1NumericQuestionResult *nqr = (RK1NumericQuestionResult *)result;
            if (nqr.unit == nil) {
                nqr.unit = [(RK1NumericAnswerFormat *)impliedAnswerFormat unit];
            }
        }
        
        result.startDate = answerDate;
        result.endDate = answerDate;

        [qResults addObject:result];
    }
    
    parentResult.results = [parentResult.results arrayByAddingObjectsFromArray:qResults] ? : qResults;
    
    return parentResult;
}

- (void)skipForward {
    // This _skipped flag is a hack so that the -result method can return an empty
    // result after the skip action, without having to generate the result
    // in advance.
    _skipped = YES;
    [self notifyDelegateOnResultChange];
    
    [super skipForward];
}

- (void)goBackward {
    if (self.isBeingReviewed) {
        self.savedAnswers = [[NSMutableDictionary alloc] initWithDictionary:self.originalAnswers];
    }
    [super goBackward];
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _sections.count;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    RK1TableSection *sectionObject = (RK1TableSection *)_sections[section];
    return sectionObject.items.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *unhiddenIndexPath = [self unhiddenIndexPathForIndexPath:indexPath];
    NSString *identifier = [NSString stringWithFormat:@"%ld-%ld",(long)unhiddenIndexPath.section, (long)unhiddenIndexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    RK1TableSection *section = (RK1TableSection *)_sections[indexPath.section];
    RK1TableCellItem *cellItem = [section items][indexPath.row];
    
    if (cell == nil) {
        RK1FormItem *formItem = cellItem.formItem;
        id answer = _savedAnswers[formItem.identifier];
        
        if (section.textChoiceCellGroup) {
            [section.textChoiceCellGroup setAnswer:answer];
            cell = [section.textChoiceCellGroup cellAtIndexPath:unhiddenIndexPath withReuseIdentifier:identifier];
        } else {
            RK1AnswerFormat *answerFormat = [cellItem.formItem impliedAnswerFormat];
            RK1QuestionType type = answerFormat.questionType;
            
            Class class = nil;
            switch (type) {
                case RK1QuestionTypeSingleChoice:
                case RK1QuestionTypeMultipleChoice: {
                    if ([formItem.impliedAnswerFormat isKindOfClass:[RK1ImageChoiceAnswerFormat class]]) {
                        class = [RK1FormItemImageSelectionCell class];
                    } else if ([formItem.impliedAnswerFormat isKindOfClass:[RK1ValuePickerAnswerFormat class]]) {
                        class = [RK1FormItemPickerCell class];
                    }
                    break;
                }
                    
                case RK1QuestionTypeDateAndTime:
                case RK1QuestionTypeDate:
                case RK1QuestionTypeTimeOfDay:
                case RK1QuestionTypeTimeInterval:
                case RK1QuestionTypeMultiplePicker:
                case RK1QuestionTypeHeight:
                case RK1QuestionTypeWeight: {
                    class = [RK1FormItemPickerCell class];
                    break;
                }
                    
                case RK1QuestionTypeDecimal:
                case RK1QuestionTypeInteger: {
                    class = [RK1FormItemNumericCell class];
                    break;
                }
                    
                case RK1QuestionTypeText: {
                    if ([formItem.answerFormat isKindOfClass:[RK1ConfirmTextAnswerFormat class]]) {
                        class = [RK1FormItemConfirmTextCell class];
                    } else {
                        RK1TextAnswerFormat *textFormat = (RK1TextAnswerFormat *)answerFormat;
                        if (!textFormat.multipleLines) {
                            class = [RK1FormItemTextFieldCell class];
                        } else {
                            class = [RK1FormItemTextCell class];
                        }
                    }
                    break;
                }
                    
                case RK1QuestionTypeScale: {
                    class = [RK1FormItemScaleCell class];
                    break;
                }
                    
                case RK1QuestionTypeLocation: {
                    class = [RK1FormItemLocationCell class];
                    break;
                }
                    
                default:
                    NSAssert(NO, @"SHOULD NOT FALL IN HERE %@ %@", @(type), answerFormat);
                    break;
            }
            
            if (class) {
                if ([class isSubclassOfClass:[RK1ChoiceViewCell class]]) {
                    NSAssert(NO, @"SHOULD NOT FALL IN HERE");
                } else {
                    RK1FormItemCell *formCell = nil;
                    formCell = [[class alloc] initWithReuseIdentifier:identifier formItem:formItem answer:answer maxLabelWidth:section.maxLabelWidth delegate:self];
                    [_formItemCells addObject:formCell];
                    [formCell setExpectedLayoutWidth:self.tableView.bounds.size.width];
                    formCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    formCell.defaultAnswer = _savedDefaults[formItem.identifier];
                    if (!_savedAnswers) {
                        _savedAnswers = [NSMutableDictionary new];
                    }
                    formCell.savedAnswers = _savedAnswers;
                    cell = formCell;
                }
            }
        }
    }
    cell.userInteractionEnabled = !self.readOnlyMode;
    cell.hidden = [_hiddenCellItems containsObject:cellItem];
    return cell;
}

- (BOOL)isChoiceSelected:(id)value atIndex:(NSUInteger)index answer:(id)answer {
    BOOL isSelected = NO;
    if (answer != nil && answer != RK1NullAnswerValue()) {
        if ([answer isKindOfClass:[NSArray class]]) {
            if (value) {
                isSelected = [(NSArray *)answer containsObject:value];
            } else {
                isSelected = [(NSArray *)answer containsObject:@(index)];
            }
        } else {
            if (value) {
                isSelected = ([answer isEqual:value]);
            } else {
                isSelected = (((NSNumber *)answer).integerValue == index);
            }
        }
    }
    return isSelected;
}

#pragma mark UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    RK1FormItemCell *cell = (RK1FormItemCell *)[tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:[RK1FormItemCell class]]) {
        [cell becomeFirstResponder];
    } else {
        // Dismiss other textField's keyboard
        [tableView endEditing:NO];
        
        RK1TableSection *section = _sections[indexPath.section];
        RK1TableCellItem *cellItem = section.items[indexPath.row];
        [section.textChoiceCellGroup didSelectCellAtIndexPath:[self unhiddenIndexPathForIndexPath:indexPath]];
        id answer = ([cellItem.formItem.answerFormat isKindOfClass:[RK1BooleanAnswerFormat class]]) ? [section.textChoiceCellGroup answerForBoolean] : [section.textChoiceCellGroup answer];
        NSString *formItemIdentifier = cellItem.formItem.identifier;
        if (answer && formItemIdentifier) {
            [self setAnswer:answer forIdentifier:formItemIdentifier];
        } else if (answer == nil && formItemIdentifier) {
            [self removeAnswerForIdentifier:formItemIdentifier];
        }
        
        _skipped = NO;
        [self updateButtonStates];
        [self notifyDelegateOnResultChange];
    }
    [self hideSections];
    [_tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    RK1TableCellItem *cellItem = ([_sections[indexPath.section] items][indexPath.row]);
    CGFloat cellHeight = [_hiddenCellItems containsObject:cellItem] ? 0 : UITableViewAutomaticDimension;
    if ([[self tableView:tableView cellForRowAtIndexPath:indexPath] isKindOfClass:[RK1ChoiceViewCell class]]) {
        return [RK1ChoiceViewCell suggestedCellHeightForShortText:cellItem.choice.text LongText:cellItem.choice.detailText inTableView:_tableView];
    }
    return cellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSString *title = _sections[section].title;
    // Make first section header view zero height when there is no title
    return (title.length > 0) ? UITableViewAutomaticDimension : ((section == 0) ? 0 : UITableViewAutomaticDimension);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *title = _sections[section].title;
    
    RK1FormSectionHeaderView *view = (RK1FormSectionHeaderView *)[tableView dequeueReusableHeaderFooterViewWithIdentifier:@(section).stringValue];
    
    if (view == nil) {
        // Do not create a header view if first section header has no title
        if (title.length > 0 || section > 0) {
            view = [[RK1FormSectionHeaderView alloc] initWithTitle:title tableView:tableView firstSection:(section == 0)];
        }
    }

    return view;
}

#pragma mark RK1FormItemCellDelegate

- (void)formItemCellDidBecomeFirstResponder:(RK1FormItemCell *)cell {
    _currentFirstResponderCell = cell;
    NSIndexPath *path = [_tableView indexPathForCell:cell];
    if (path) {
        [_tableContainer scrollCellVisible:cell animated:YES];
    }
}

- (void)formItemCellDidResignFirstResponder:(RK1FormItemCell *)cell {
    if (_currentFirstResponderCell == cell) {
        _currentFirstResponderCell = nil;
    }
}

- (void)formItemCell:(RK1FormItemCell *)cell invalidInputAlertWithMessage:(NSString *)input {
    [self showValidityAlertWithMessage:input];
}

- (void)formItemCell:(RK1FormItemCell *)cell invalidInputAlertWithTitle:(NSString *)title message:(NSString *)message {
    [self showValidityAlertWithTitle:title message:message];
}

- (void)formItemCell:(RK1FormItemCell *)cell answerDidChangeTo:(id)answer {
    if (answer && cell.formItem.identifier) {
        [self setAnswer:answer forIdentifier:cell.formItem.identifier];
    } else if (answer == nil && cell.formItem.identifier) {
        [self removeAnswerForIdentifier:cell.formItem.identifier];
    }
    
    _skipped = NO;
    [self updateButtonStates];
    [self notifyDelegateOnResultChange];
}

#pragma mark RK1TableContainerViewDelegate

- (UITableViewCell *)currentFirstResponderCellForTableContainerView:(RK1TableContainerView *)tableContainerView {
    return _currentFirstResponderCell;
}

#pragma mark UIStateRestoration

static NSString *const _RK1SavedAnswersRestoreKey = @"savedAnswers";
static NSString *const _RK1SavedAnswerDatesRestoreKey = @"savedAnswerDates";
static NSString *const _RK1SavedSystemCalendarsRestoreKey = @"savedSystemCalendars";
static NSString *const _RK1SavedSystemTimeZonesRestoreKey = @"savedSystemTimeZones";
static NSString *const _RK1OriginalAnswersRestoreKey = @"originalAnswers";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:_savedAnswers forKey:_RK1SavedAnswersRestoreKey];
    [coder encodeObject:_savedAnswerDates forKey:_RK1SavedAnswerDatesRestoreKey];
    [coder encodeObject:_savedSystemCalendars forKey:_RK1SavedSystemCalendarsRestoreKey];
    [coder encodeObject:_savedSystemTimeZones forKey:_RK1SavedSystemTimeZonesRestoreKey];
    [coder encodeObject:_originalAnswers forKey:_RK1OriginalAnswersRestoreKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    _savedAnswers = [coder decodeObjectOfClass:[NSMutableDictionary class] forKey:_RK1SavedAnswersRestoreKey];
    _savedAnswerDates = [coder decodeObjectOfClass:[NSMutableDictionary class] forKey:_RK1SavedAnswerDatesRestoreKey];
    _savedSystemCalendars = [coder decodeObjectOfClass:[NSMutableDictionary class] forKey:_RK1SavedSystemCalendarsRestoreKey];
    _savedSystemTimeZones = [coder decodeObjectOfClass:[NSMutableDictionary class] forKey:_RK1SavedSystemTimeZonesRestoreKey];
    _originalAnswers = [coder decodeObjectOfClass:[NSMutableDictionary class] forKey:_RK1OriginalAnswersRestoreKey];
}

#pragma mark Rotate

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    for (RK1FormItemCell *cell in _formItemCells) {
        [cell setExpectedLayoutWidth:size.width];
    }
}

@end
