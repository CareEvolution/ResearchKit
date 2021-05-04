/*
 Copyright (c) 2015, Oliver Schaefer.
 
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


#import "ORK1ReviewStepViewController.h"
#import "ORK1ReviewStepViewController_Internal.h"

#import "ORK1ChoiceViewCell.h"
#import "ORK1NavigationContainerView_Internal.h"
#import "ORK1SelectionTitleLabel.h"
#import "ORK1SelectionSubTitleLabel.h"
#import "ORK1StepHeaderView_Internal.h"
#import "ORK1TableContainerView.h"

#import "ORK1StepViewController_Internal.h"
#import "ORK1TaskViewController_Internal.h"

#import "ORK1AnswerFormat_Internal.h"
#import "ORK1FormStep.h"
#import "ORK1InstructionStep.h"
#import "ORK1QuestionStep.h"
#import "ORK1ReviewStep_Internal.h"
#import "ORK1Result_Private.h"
#import "ORK1Step_Private.h"

#import "ORK1Helpers_Internal.h"
#import "ORK1Skin.h"


@interface ORK1ReviewStepViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) ORK1TableContainerView *tableContainer;

@end



@implementation ORK1ReviewStepViewController {
    ORK1NavigationContainerView *_continueSkipView;
}
 
- (instancetype)initWithReviewStep:(ORK1ReviewStep *)reviewStep steps:(NSArray<ORK1Step *>*)steps resultSource:(id<ORK1TaskResultSource>)resultSource {
    self = [self initWithStep:reviewStep];
    if (self && [self reviewStep]) {
        NSArray<ORK1Step *> *stepsToFilter = [self reviewStep].isStandalone ? [self reviewStep].steps : steps;
        NSMutableArray<ORK1Step *> *filteredSteps = [[NSMutableArray alloc] init];
        ORK1WeakTypeOf(self) weakSelf = self;
        [stepsToFilter enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            ORK1StrongTypeOf(self) strongSelf = weakSelf;
            BOOL includeStep = [obj isKindOfClass:[ORK1QuestionStep class]] || [obj isKindOfClass:[ORK1FormStep class]] || (![[strongSelf reviewStep] excludeInstructionSteps] && [obj isKindOfClass:[ORK1InstructionStep class]]);
            if (includeStep) {
                [filteredSteps addObject:obj];
            }
        }];
        _steps = [filteredSteps copy];
        _resultSource = [self reviewStep].isStandalone ? [self reviewStep].resultSource : resultSource;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.taskViewController setRegisteredScrollView: _tableContainer.tableView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (void)setContinueButtonItem:(UIBarButtonItem *)continueButtonItem {
    [super setContinueButtonItem:continueButtonItem];
    _continueSkipView.continueButtonItem = continueButtonItem;
}

- (void)setLearnMoreButtonItem:(UIBarButtonItem *)learnMoreButtonItem {
    [super setLearnMoreButtonItem:learnMoreButtonItem];
    _tableContainer.stepHeaderView.learnMoreButtonItem = self.learnMoreButtonItem;
}

- (void)setSkipButtonItem:(UIBarButtonItem *)skipButtonItem {
    [super setSkipButtonItem:skipButtonItem];
    _continueSkipView.skipButtonItem = self.skipButtonItem;
}

- (void)stepDidChange {
    [super stepDidChange];
    
    [_tableContainer removeFromSuperview];
    _tableContainer = nil;
    
    _tableContainer.tableView.delegate = nil;
    _tableContainer.tableView.dataSource = nil;
    _continueSkipView = nil;
    
    if ([self reviewStep]) {
        _tableContainer = [[ORK1TableContainerView alloc] initWithFrame:self.view.bounds];
        _tableContainer.tableView.delegate = self;
        _tableContainer.tableView.dataSource = self;
        _tableContainer.tableView.clipsToBounds = YES;

        [self.view addSubview:_tableContainer];
        _tableContainer.tapOffView = self.view;
        
        _tableContainer.stepHeaderView.captionLabel.useSurveyMode = self.step.useSurveyMode;
        _tableContainer.stepHeaderView.captionLabel.text = [self reviewStep].title;
        _tableContainer.stepHeaderView.instructionTextView.textValue = [self reviewStep].text;
        _tableContainer.stepHeaderView.learnMoreButtonItem = self.learnMoreButtonItem;
        
        _continueSkipView = _tableContainer.continueSkipContainerView;
        _continueSkipView.skipButtonItem = self.skipButtonItem;
        _continueSkipView.continueEnabled = YES;
        _continueSkipView.continueButtonItem = self.continueButtonItem;
        _continueSkipView.optional = self.step.optional;
        [_tableContainer setNeedsLayout];
    }
}

- (ORK1ReviewStep *)reviewStep {
    return [self.step isKindOfClass:[ORK1ReviewStep class]] ? (ORK1ReviewStep *) self.step : nil;
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _steps.count > 0 ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _steps.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    tableView.layoutMargins = UIEdgeInsetsZero;
    static NSString *identifier = nil;
    identifier = [NSStringFromClass([self class]) stringByAppendingFormat:@"%@", @(indexPath.row)];
    ORK1ChoiceViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[ORK1ChoiceViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.immediateNavigation = YES;
    ORK1Step *step = _steps[indexPath.row];
    ORK1StepResult *stepResult = [_resultSource stepResultForStepIdentifier:step.identifier];
    cell.shortLabel.text = step.title != nil ? step.title : step.text;
    cell.longLabel.text = [self answerStringForStep:step withStepResult:stepResult];
    return cell;
}

#pragma mark answer string

- (NSString *)answerStringForStep:(ORK1Step *)step withStepResult:(ORK1StepResult *)stepResult {
    NSString *answerString = nil;
    if (step && stepResult && [step.identifier isEqualToString:stepResult.identifier]) {
        if ([step isKindOfClass:[ORK1QuestionStep class]]) {
            ORK1QuestionStep *questionStep = (ORK1QuestionStep *)step;
            if (stepResult.firstResult && [stepResult.firstResult isKindOfClass:[ORK1QuestionResult class]]) {
                ORK1QuestionResult *questionResult = (ORK1QuestionResult *)stepResult.firstResult;
                answerString = [self answerStringForQuestionStep:questionStep withQuestionResult:questionResult];
            }
        } else if ([step isKindOfClass:[ORK1FormStep class]]) {
            answerString = [self answerStringForFormStep:(ORK1FormStep *)step withStepResult:stepResult];
        }
    }
    return answerString;
}

- (NSString *)answerStringForQuestionStep:(ORK1QuestionStep *)questionStep withQuestionResult:(ORK1QuestionResult *)questionResult {
    NSString *answerString = nil;
    if (questionStep && questionResult && questionStep.answerFormat && [questionResult isKindOfClass:questionStep.answerFormat.questionResultClass] && questionResult.answer) {
        answerString = [questionStep.answerFormat stringForAnswer:questionResult.answer];
    }
    return answerString;
}

- (NSString *)answerStringForFormStep:(ORK1FormStep *)formStep withStepResult:(ORK1StepResult *)stepResult {
    NSString *answerString = nil;
    if (formStep && formStep.formItems && stepResult) {
        NSMutableArray *answerStrings = [[NSMutableArray alloc] init];
        for (ORK1FormItem *formItem in formStep.formItems) {
            ORK1Result *formItemResult = [stepResult resultForIdentifier:formItem.identifier];
            if (formItemResult && [formItemResult isKindOfClass:[ORK1QuestionResult class]]) {
                ORK1QuestionResult *questionResult = (ORK1QuestionResult *)formItemResult;
                if (formItem.answerFormat && [questionResult isKindOfClass:formItem.answerFormat.questionResultClass] && questionResult.answer) {
                    NSString *formItemTextString = formItem.text;
                    NSString *formItemAnswerString = [formItem.answerFormat stringForAnswer:questionResult.answer];
                    if (formItemTextString && formItemAnswerString) {
                        [answerStrings addObject:[@[formItemTextString, formItemAnswerString] componentsJoinedByString:@"\n"]];
                    }
                }
            }
        }
        answerString = [answerStrings componentsJoinedByString:@"\n\n"];
    }
    return answerString;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([self.reviewDelegate respondsToSelector:@selector(reviewStepViewController:willReviewStep:)]) {
        [self.reviewDelegate reviewStepViewController:self willReviewStep:_steps[indexPath.row]];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    ORK1Step *step = _steps[indexPath.row];
    ORK1StepResult *stepResult = [_resultSource stepResultForStepIdentifier:step.identifier];
    NSString *shortText = step.title != nil ? step.title : step.text;
    NSString *longText = [self answerStringForStep:step withStepResult:stepResult];
    CGFloat height = [ORK1ChoiceViewCell suggestedCellHeightForShortText:shortText longText:longText showDetailTextIndicator:NO inTableView:_tableContainer.tableView];
    return height;
}

@end

