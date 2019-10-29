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


#import "ORKReviewStepViewController.h"
#import "ORKReviewStepViewController_Internal.h"

#import "ORKChoiceViewCell.h"
#import "ORKNavigationContainerView_Internal.h"
#import "ORKSelectionTitleLabel.h"
#import "ORKSelectionSubTitleLabel.h"
#import "ORKStepHeaderView_Internal.h"
#import "ORKTableContainerView.h"

#import "ORKStepViewController_Internal.h"
#import "ORKTaskViewController_Internal.h"

#import "ORKAnswerFormat_Internal.h"
#import "ORKFormStep.h"
#import "ORKInstructionStep.h"
#import "ORKQuestionStep.h"
#import "ORKReviewStep_Internal.h"
#import "ORKResult_Private.h"
#import "ORKStep_Private.h"

#import "ORKHelpers_Internal.h"
#import "ORKSkin.h"


@interface ORKLegacyReviewStepViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) ORKLegacyTableContainerView *tableContainer;

@end



@implementation ORKLegacyReviewStepViewController {
    ORKLegacyNavigationContainerView *_continueSkipView;
}
 
- (instancetype)initWithReviewStep:(ORKLegacyReviewStep *)reviewStep steps:(NSArray<ORKLegacyStep *>*)steps resultSource:(id<ORKLegacyTaskResultSource>)resultSource {
    self = [self initWithStep:reviewStep];
    if (self && [self reviewStep]) {
        NSArray<ORKLegacyStep *> *stepsToFilter = [self reviewStep].isStandalone ? [self reviewStep].steps : steps;
        NSMutableArray<ORKLegacyStep *> *filteredSteps = [[NSMutableArray alloc] init];
        ORKLegacyWeakTypeOf(self) weakSelf = self;
        [stepsToFilter enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            ORKLegacyStrongTypeOf(self) strongSelf = weakSelf;
            BOOL includeStep = [obj isKindOfClass:[ORKLegacyQuestionStep class]] || [obj isKindOfClass:[ORKLegacyFormStep class]] || (![[strongSelf reviewStep] excludeInstructionSteps] && [obj isKindOfClass:[ORKLegacyInstructionStep class]]);
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
        _tableContainer = [[ORKLegacyTableContainerView alloc] initWithFrame:self.view.bounds];
        _tableContainer.tableView.delegate = self;
        _tableContainer.tableView.dataSource = self;
        _tableContainer.tableView.clipsToBounds = YES;

        [self.view addSubview:_tableContainer];
        _tableContainer.tapOffView = self.view;
        
        _tableContainer.stepHeaderView.captionLabel.useSurveyMode = self.step.useSurveyMode;
        _tableContainer.stepHeaderView.captionLabel.text = [self reviewStep].title;
        _tableContainer.stepHeaderView.instructionLabel.text = [self reviewStep].text;
        _tableContainer.stepHeaderView.learnMoreButtonItem = self.learnMoreButtonItem;
        
        _continueSkipView = _tableContainer.continueSkipContainerView;
        _continueSkipView.skipButtonItem = self.skipButtonItem;
        _continueSkipView.continueEnabled = YES;
        _continueSkipView.continueButtonItem = self.continueButtonItem;
        _continueSkipView.optional = self.step.optional;
        [_tableContainer setNeedsLayout];
    }
}

- (ORKLegacyReviewStep *)reviewStep {
    return [self.step isKindOfClass:[ORKLegacyReviewStep class]] ? (ORKLegacyReviewStep *) self.step : nil;
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
    ORKLegacyChoiceViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[ORKLegacyChoiceViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.immediateNavigation = YES;
    ORKLegacyStep *step = _steps[indexPath.row];
    ORKLegacyStepResult *stepResult = [_resultSource stepResultForStepIdentifier:step.identifier];
    cell.shortLabel.text = step.title != nil ? step.title : step.text;
    cell.longLabel.text = [self answerStringForStep:step withStepResult:stepResult];
    return cell;
}

#pragma mark answer string

- (NSString *)answerStringForStep:(ORKLegacyStep *)step withStepResult:(ORKLegacyStepResult *)stepResult {
    NSString *answerString = nil;
    if (step && stepResult && [step.identifier isEqualToString:stepResult.identifier]) {
        if ([step isKindOfClass:[ORKLegacyQuestionStep class]]) {
            ORKLegacyQuestionStep *questionStep = (ORKLegacyQuestionStep *)step;
            if (stepResult.firstResult && [stepResult.firstResult isKindOfClass:[ORKLegacyQuestionResult class]]) {
                ORKLegacyQuestionResult *questionResult = (ORKLegacyQuestionResult *)stepResult.firstResult;
                answerString = [self answerStringForQuestionStep:questionStep withQuestionResult:questionResult];
            }
        } else if ([step isKindOfClass:[ORKLegacyFormStep class]]) {
            answerString = [self answerStringForFormStep:(ORKLegacyFormStep *)step withStepResult:stepResult];
        }
    }
    return answerString;
}

- (NSString *)answerStringForQuestionStep:(ORKLegacyQuestionStep *)questionStep withQuestionResult:(ORKLegacyQuestionResult *)questionResult {
    NSString *answerString = nil;
    if (questionStep && questionResult && questionStep.answerFormat && [questionResult isKindOfClass:questionStep.answerFormat.questionResultClass] && questionResult.answer) {
        answerString = [questionStep.answerFormat stringForAnswer:questionResult.answer];
    }
    return answerString;
}

- (NSString *)answerStringForFormStep:(ORKLegacyFormStep *)formStep withStepResult:(ORKLegacyStepResult *)stepResult {
    NSString *answerString = nil;
    if (formStep && formStep.formItems && stepResult) {
        NSMutableArray *answerStrings = [[NSMutableArray alloc] init];
        for (ORKLegacyFormItem *formItem in formStep.formItems) {
            ORKLegacyResult *formItemResult = [stepResult resultForIdentifier:formItem.identifier];
            if (formItemResult && [formItemResult isKindOfClass:[ORKLegacyQuestionResult class]]) {
                ORKLegacyQuestionResult *questionResult = (ORKLegacyQuestionResult *)formItemResult;
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
    ORKLegacyStep *step = _steps[indexPath.row];
    ORKLegacyStepResult *stepResult = [_resultSource stepResultForStepIdentifier:step.identifier];
    NSString *shortText = step.title != nil ? step.title : step.text;
    NSString *longText = [self answerStringForStep:step withStepResult:stepResult];
    CGFloat height = [ORKLegacyChoiceViewCell suggestedCellHeightForShortText:shortText LongText:longText inTableView:_tableContainer.tableView];
    return height;
}

@end

