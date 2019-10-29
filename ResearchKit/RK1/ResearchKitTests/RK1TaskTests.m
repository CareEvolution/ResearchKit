/*
 Copyright (c) 2015-2016, Ricardo Sánchez-Sáez.
 
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


@import XCTest;
@import ResearchKit.Private;


@interface RK1TaskTests : XCTestCase

@end

@interface MethodObject : NSObject
@property (nonatomic) NSString *selectorName;
@property (nonatomic) NSArray *arguments;
@end

@interface TestTaskViewControllerDelegate : NSObject <RK1TaskViewControllerDelegate>
@property (nonatomic) NSMutableArray <MethodObject *> *methodCalled;
@end

@interface MockTaskViewController : RK1TaskViewController
@property (nonatomic) NSMutableArray <MethodObject *> *methodCalled;
@end


@implementation RK1TaskTests {
    NSArray *_orderedTaskStepIdentifiers;
    NSArray *_orderedTaskSteps;
    RK1OrderedTask *_orderedTask;
    
    NSArray *_navigableOrderedTaskStepIdentifiers;
    NSArray *_navigableOrderedTaskSteps;
    NSMutableDictionary *_stepNavigationRules;
    RK1NavigableOrderedTask *_navigableOrderedTask;
}

RK1DefineStringKey(HeadacheChoiceValue);
RK1DefineStringKey(DizzinessChoiceValue);
RK1DefineStringKey(NauseaChoiceValue);

RK1DefineStringKey(SymptomStepIdentifier);
RK1DefineStringKey(SeverityStepIdentifier);
RK1DefineStringKey(BlankStepIdentifier);
RK1DefineStringKey(SevereHeadacheStepIdentifier);
RK1DefineStringKey(LightHeadacheStepIdentifier);
RK1DefineStringKey(OtherSymptomStepIdentifier);
RK1DefineStringKey(EndStepIdentifier);
RK1DefineStringKey(BlankBStepIdentifier);

RK1DefineStringKey(OrderedTaskIdentifier);
RK1DefineStringKey(NavigableOrderedTaskIdentifier);

- (void)generateTaskSteps:(out NSArray **)outSteps stepIdentifiers:(out NSArray **)outStepIdentifiers {
    if (outSteps == NULL || outStepIdentifiers == NULL) {
        return;
    }
    
    NSMutableArray *stepIdentifiers = [NSMutableArray new];
    NSMutableArray *steps = [NSMutableArray new];
    
    RK1AnswerFormat *answerFormat = nil;
    NSString *stepIdentifier = nil;
    RK1Step *step = nil;
    
    NSArray *textChoices =
    @[
      [RK1TextChoice choiceWithText:@"Headache" value:HeadacheChoiceValue],
      [RK1TextChoice choiceWithText:@"Dizziness" value:DizzinessChoiceValue],
      [RK1TextChoice choiceWithText:@"Nausea" value:NauseaChoiceValue]
      ];
    
    answerFormat = [RK1AnswerFormat choiceAnswerFormatWithStyle:RK1ChoiceAnswerStyleSingleChoice
                                                    textChoices:textChoices];
    stepIdentifier = SymptomStepIdentifier;
    step = [RK1QuestionStep questionStepWithIdentifier:stepIdentifier title:@"What is your symptom?" answer:answerFormat];
    step.optional = NO;
    [stepIdentifiers addObject:stepIdentifier];
    [steps addObject:step];
    
    answerFormat = [RK1AnswerFormat booleanAnswerFormat];
    stepIdentifier = SeverityStepIdentifier;
    step = [RK1QuestionStep questionStepWithIdentifier:stepIdentifier title:@"Does your symptom interferes with your daily life?" answer:answerFormat];
    step.optional = NO;
    [stepIdentifiers addObject:stepIdentifier];
    [steps addObject:step];
    
    stepIdentifier = BlankStepIdentifier;
    step = [[RK1InstructionStep alloc] initWithIdentifier:stepIdentifier];
    step.title = @"This step is intentionally left blank (you should not see it)";
    [stepIdentifiers addObject:stepIdentifier];
    [steps addObject:step];
    
    stepIdentifier = SevereHeadacheStepIdentifier;
    step = [[RK1InstructionStep alloc] initWithIdentifier:stepIdentifier];
    step.title = @"You have a severe headache";
    [stepIdentifiers addObject:stepIdentifier];
    [steps addObject:step];
    
    stepIdentifier = LightHeadacheStepIdentifier;
    step = [[RK1InstructionStep alloc] initWithIdentifier:stepIdentifier];
    step.title = @"You have a light headache";
    [stepIdentifiers addObject:stepIdentifier];
    [steps addObject:step];
    
    stepIdentifier = OtherSymptomStepIdentifier;
    step = [[RK1InstructionStep alloc] initWithIdentifier:stepIdentifier];
    step.title = @"You have other symptom";
    [stepIdentifiers addObject:stepIdentifier];
    [steps addObject:step];
    
    stepIdentifier = EndStepIdentifier;
    step = [[RK1InstructionStep alloc] initWithIdentifier:stepIdentifier];
    step.title = @"You have finished the task";
    [stepIdentifiers addObject:stepIdentifier];
    [steps addObject:step];
    
    stepIdentifier = BlankBStepIdentifier;
    step = [[RK1InstructionStep alloc] initWithIdentifier:stepIdentifier];
    step.title = @"This step is intentionally left blank (you should not see it)";
    [stepIdentifiers addObject:stepIdentifier];
    [steps addObject:step];
    
    *outSteps = steps;
    *outStepIdentifiers = stepIdentifiers;
}

- (void)setUpOrderedTask {
    NSArray *orderedTaskSteps = nil;
    NSArray *orderedTaskStepIdentifiers = nil;
    [self generateTaskSteps:&orderedTaskSteps stepIdentifiers:&orderedTaskStepIdentifiers];
    _orderedTaskSteps = orderedTaskSteps;
    _orderedTaskStepIdentifiers = orderedTaskStepIdentifiers;
    
    _orderedTask = [[RK1OrderedTask alloc] initWithIdentifier:OrderedTaskIdentifier
                                                        steps:RK1ArrayCopyObjects(_orderedTaskSteps)]; // deep copy to test step copying and equality
}

- (void)setUpNavigableOrderedTask {
    RK1ResultSelector *resultSelector = nil;
    NSArray *navigableOrderedTaskSteps = nil;
    NSArray *navigableOrderedTaskStepIdentifiers = nil;
    [self generateTaskSteps:&navigableOrderedTaskSteps stepIdentifiers:&navigableOrderedTaskStepIdentifiers];
    _navigableOrderedTaskSteps = navigableOrderedTaskSteps;
    _navigableOrderedTaskStepIdentifiers = navigableOrderedTaskStepIdentifiers;
    
    _navigableOrderedTask = [[RK1NavigableOrderedTask alloc] initWithIdentifier:NavigableOrderedTaskIdentifier
                                                                          steps:RK1ArrayCopyObjects(_navigableOrderedTaskSteps)]; // deep copy to test step copying and equality
    
    // Build navigation rules
    _stepNavigationRules = [NSMutableDictionary new];
    // Individual predicates
    
    // User chose headache at the symptom step
    resultSelector = [[RK1ResultSelector alloc] initWithResultIdentifier:SymptomStepIdentifier];
    NSPredicate *predicateHeadache = [RK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                                        expectedAnswerValue:HeadacheChoiceValue];
    // Equivalent to:
    //      [NSPredicate predicateWithFormat:
    //          @"SUBQUERY(SELF, $x, $x.identifier like 'symptom' \
    //                     AND SUBQUERY($x.answer, $y, $y like 'headache').@count > 0).@count > 0"];
    
    // User didn't chose headache at the symptom step
    NSPredicate *predicateNotHeadache = [NSCompoundPredicate notPredicateWithSubpredicate:predicateHeadache];
    
    // User chose YES at the severity step
    resultSelector = [[RK1ResultSelector alloc] initWithResultIdentifier:SeverityStepIdentifier];
    NSPredicate *predicateSevereYes = [RK1ResultPredicate predicateForBooleanQuestionResultWithResultSelector:resultSelector
                                                                                               expectedAnswer:YES];
    // Equivalent to:
    //      [NSPredicate predicateWithFormat:
    //          @"SUBQUERY(SELF, $x, $x.identifier like 'severity' AND $x.answer == YES).@count > 0"];
    
    // User chose NO at the severity step
    NSPredicate *predicateSevereNo = [RK1ResultPredicate predicateForBooleanQuestionResultWithResultSelector:resultSelector
                                                                                              expectedAnswer:NO];
    
    
    // From the "symptom" step, go to "other_symptom" is user didn't chose headache.
    // Otherwise, default to going to next step (when the defaultStepIdentifier argument is omitted,
    // the regular RK1OrderedTask order applies).
    NSMutableArray *resultPredicates = [NSMutableArray new];
    NSMutableArray *destinationStepIdentifiers = [NSMutableArray new];
    
    [resultPredicates addObject:predicateNotHeadache];
    [destinationStepIdentifiers addObject:OtherSymptomStepIdentifier];
    
    RK1PredicateStepNavigationRule *predicateRule =
    [[RK1PredicateStepNavigationRule alloc] initWithResultPredicates:resultPredicates
                                          destinationStepIdentifiers:destinationStepIdentifiers];
    
    [_navigableOrderedTask setNavigationRule:predicateRule forTriggerStepIdentifier:SymptomStepIdentifier];
    _stepNavigationRules[SymptomStepIdentifier] = [predicateRule copy];
    
    // From the "severity" step, go to "severe_headache" or "light_headache" depending on the user answer
    resultPredicates = [NSMutableArray new];
    destinationStepIdentifiers = [NSMutableArray new];
    
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateHeadache, predicateSevereYes]];
    [resultPredicates addObject:predicate];
    [destinationStepIdentifiers addObject:SevereHeadacheStepIdentifier];
    
    predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateHeadache, predicateSevereNo]];
    [resultPredicates addObject:predicate];
    [destinationStepIdentifiers addObject:LightHeadacheStepIdentifier];
    
    predicateRule =
    [[RK1PredicateStepNavigationRule alloc] initWithResultPredicates:resultPredicates
                                          destinationStepIdentifiers:destinationStepIdentifiers
                                               defaultStepIdentifier:OtherSymptomStepIdentifier];
    
    [_navigableOrderedTask setNavigationRule:predicateRule forTriggerStepIdentifier:SeverityStepIdentifier];
    _stepNavigationRules[SeverityStepIdentifier] = [predicateRule copy];
    
    
    // Add end direct rules to skip unneeded steps
    RK1DirectStepNavigationRule *directRule = nil;
    
    directRule = [[RK1DirectStepNavigationRule alloc] initWithDestinationStepIdentifier:EndStepIdentifier];
    
    [_navigableOrderedTask setNavigationRule:directRule forTriggerStepIdentifier:SevereHeadacheStepIdentifier];
    [_navigableOrderedTask setNavigationRule:directRule forTriggerStepIdentifier:LightHeadacheStepIdentifier];
    [_navigableOrderedTask setNavigationRule:directRule forTriggerStepIdentifier:OtherSymptomStepIdentifier];
    
    _stepNavigationRules[SevereHeadacheStepIdentifier] = [directRule copy];
    _stepNavigationRules[LightHeadacheStepIdentifier] = [directRule copy];
    _stepNavigationRules[OtherSymptomStepIdentifier] = [directRule copy];
    
    directRule = [[RK1DirectStepNavigationRule alloc] initWithDestinationStepIdentifier:RK1NullStepIdentifier];
    [_navigableOrderedTask setNavigationRule:directRule forTriggerStepIdentifier:EndStepIdentifier];
    _stepNavigationRules[EndStepIdentifier] = [directRule copy];
}

typedef NS_OPTIONS(NSUInteger, TestsTaskResultOptions) {
    TestsTaskResultOptionSymptomHeadache    = 1 << 0,
    TestsTaskResultOptionSymptomDizziness   = 1 << 1,
    TestsTaskResultOptionSymptomNausea      = 1 << 2,
    
    TestsTaskResultOptionSeverityYes        = 1 << 3,
    TestsTaskResultOptionSeverityNo         = 1 << 4
};

- (RK1TaskResult *)getResultTreeWithTaskIdentifier:(NSString *)taskIdentifier resultOptions:(TestsTaskResultOptions)resultOptions {
    if ( ((resultOptions & TestsTaskResultOptionSymptomDizziness) || (resultOptions & TestsTaskResultOptionSymptomNausea)) && ((resultOptions & TestsTaskResultOptionSeverityYes) || (resultOptions & TestsTaskResultOptionSeverityNo)) ) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"You can only add a severity result for the headache symptom" userInfo:nil];
    }
    
    NSMutableArray *stepResults = [NSMutableArray new];
    
    RK1QuestionResult *questionResult = nil;
    RK1StepResult *stepResult = nil;
    NSString *stepIdentifier = nil;
    
    if (resultOptions & (TestsTaskResultOptionSymptomHeadache | TestsTaskResultOptionSymptomDizziness | TestsTaskResultOptionSymptomNausea)) {
        stepIdentifier = SymptomStepIdentifier;
        questionResult = [[RK1ChoiceQuestionResult alloc] init];
        questionResult.identifier = stepIdentifier;
        if (resultOptions & TestsTaskResultOptionSymptomHeadache) {
            questionResult.answer = @[HeadacheChoiceValue];
        } else if (resultOptions & TestsTaskResultOptionSymptomDizziness) {
            questionResult.answer = @[DizzinessChoiceValue];
        } else if (resultOptions & TestsTaskResultOptionSymptomNausea) {
            questionResult.answer = @[NauseaChoiceValue];
        }
        questionResult.questionType = RK1QuestionTypeSingleChoice;
        
        stepResult = [[RK1StepResult alloc] initWithStepIdentifier:stepIdentifier results:@[questionResult]];
        [stepResults addObject:stepResult];

        if (resultOptions & (TestsTaskResultOptionSymptomDizziness | TestsTaskResultOptionSymptomNausea)) {
            stepResult = [[RK1StepResult alloc] initWithStepIdentifier:OtherSymptomStepIdentifier results:nil];
            [stepResults addObject:stepResult];
        }
    }
    
    if (resultOptions & (TestsTaskResultOptionSeverityYes | TestsTaskResultOptionSeverityNo)) {
        stepIdentifier = SeverityStepIdentifier;
        questionResult = [[RK1BooleanQuestionResult alloc] init];
        questionResult.identifier = stepIdentifier;
        if (resultOptions & TestsTaskResultOptionSeverityYes) {
            questionResult.answer = @(YES);
        } else if (resultOptions & TestsTaskResultOptionSeverityNo) {
            questionResult.answer = @(NO);
        }
        questionResult.questionType = RK1QuestionTypeSingleChoice;
        
        stepResult = [[RK1StepResult alloc] initWithStepIdentifier:stepIdentifier results:@[questionResult]];
        [stepResults addObject:stepResult];
        
        
        if (resultOptions & TestsTaskResultOptionSeverityYes) {
            stepResult = [[RK1StepResult alloc] initWithStepIdentifier:SevereHeadacheStepIdentifier results:nil];
            [stepResults addObject:stepResult];
        } else if (resultOptions & TestsTaskResultOptionSeverityNo) {
            stepResult = [[RK1StepResult alloc] initWithStepIdentifier:LightHeadacheStepIdentifier results:nil];
            [stepResults addObject:stepResult];
        }
    }
    
    stepResult = [[RK1StepResult alloc] initWithStepIdentifier:EndStepIdentifier results:nil];
    [stepResults addObject:stepResult];

    RK1TaskResult *taskResult = [[RK1TaskResult alloc] initWithTaskIdentifier:taskIdentifier
                                                                  taskRunUUID:[NSUUID UUID]
                                                              outputDirectory:[NSURL fileURLWithPath:NSTemporaryDirectory()]];
    taskResult.results = stepResults;
    
    return taskResult;
}

- (void)setUp {
    [super setUp];
    [self setUpOrderedTask];
    [self setUpNavigableOrderedTask];
}

- (void)testOrderedTask {
    RK1TaskResult *mockTaskResult = [[RK1TaskResult alloc] init];
    
    XCTAssertEqualObjects(_orderedTask.identifier, OrderedTaskIdentifier);
    XCTAssertEqualObjects(_orderedTask.steps, _orderedTaskSteps);
    
    NSUInteger expectedTotalProgress = _orderedTaskSteps.count;
    
    for (NSUInteger stepIndex = 0; stepIndex < _orderedTaskStepIdentifiers.count; stepIndex++) {
        RK1Step *currentStep = _orderedTaskSteps[stepIndex];
        XCTAssertEqualObjects(currentStep, [_orderedTask stepWithIdentifier:_orderedTaskStepIdentifiers[stepIndex]]);
        
        const NSUInteger expectedCurrentProgress = stepIndex;
        RK1TaskProgress currentProgress = [_orderedTask progressOfCurrentStep:currentStep withResult:mockTaskResult];
        XCTAssertTrue(currentProgress.total == expectedTotalProgress && currentProgress.current == expectedCurrentProgress);
        
        NSString *expectedPreviousStep = (stepIndex != 0) ? _orderedTaskSteps[stepIndex - 1] : nil;
        NSString *expectedNextStep = (stepIndex < _orderedTaskStepIdentifiers.count - 1) ? _orderedTaskSteps[stepIndex + 1] : nil;
        XCTAssertEqualObjects(expectedPreviousStep, [_orderedTask stepBeforeStep:currentStep withResult:mockTaskResult]);
        XCTAssertEqualObjects(expectedNextStep, [_orderedTask stepAfterStep:currentStep withResult:mockTaskResult]);
    }
    
    // Test duplicate step identifier validation
    XCTAssertNoThrow([_orderedTask validateParameters]);
    
    NSMutableArray *steps = [[NSMutableArray alloc] initWithArray:RK1ArrayCopyObjects(_orderedTaskSteps)];
    RK1Step *step = [[RK1InstructionStep alloc] initWithIdentifier:BlankStepIdentifier];
    [steps addObject:step];
    
    XCTAssertThrows([[RK1OrderedTask alloc] initWithIdentifier:OrderedTaskIdentifier
                                                         steps:steps]);
}

#define getIndividualNavigableOrderedTaskSteps() \
__unused RK1Step *symptomStep = _navigableOrderedTaskSteps[0];\
__unused RK1Step *severityStep = _navigableOrderedTaskSteps[1];\
__unused RK1Step *blankStep = _navigableOrderedTaskSteps[2];\
__unused RK1Step *severeHeadacheStep = _navigableOrderedTaskSteps[3];\
__unused RK1Step *lightHeadacheStep = _navigableOrderedTaskSteps[4];\
__unused RK1Step *otherSymptomStep = _navigableOrderedTaskSteps[5];\
__unused RK1Step *endStep = _navigableOrderedTaskSteps[6];

BOOL (^testStepAfterStep)(RK1NavigableOrderedTask *, RK1TaskResult *, RK1Step *, RK1Step *) =  ^BOOL(RK1NavigableOrderedTask *task, RK1TaskResult *taskResult, RK1Step *fromStep, RK1Step *expectedStep) {
    RK1Step *testedStep = [task stepAfterStep:fromStep withResult:taskResult];
    return (testedStep == nil && expectedStep == nil) || [testedStep isEqual:expectedStep];
};

BOOL (^testStepBeforeStep)(RK1NavigableOrderedTask *, RK1TaskResult *, RK1Step *, RK1Step *) =  ^BOOL(RK1NavigableOrderedTask *task, RK1TaskResult *taskResult, RK1Step *fromStep, RK1Step *expectedStep) {
    RK1Step *testedStep = [task stepBeforeStep:fromStep withResult:taskResult];
    return (testedStep == nil && expectedStep == nil) || [testedStep isEqual:expectedStep];
};

- (void)testNavigableOrderedTask {
    XCTAssertEqualObjects(_navigableOrderedTask.identifier, NavigableOrderedTaskIdentifier);
    XCTAssertEqualObjects(_navigableOrderedTask.steps, _navigableOrderedTaskSteps);
    XCTAssertEqualObjects(_navigableOrderedTask.stepNavigationRules, _stepNavigationRules);
    
    for (NSString *triggerStepIdentifier in [_stepNavigationRules allKeys]) {
        XCTAssertEqualObjects(_stepNavigationRules[triggerStepIdentifier], [_navigableOrderedTask navigationRuleForTriggerStepIdentifier:triggerStepIdentifier]);
    }
    
    RK1DefineStringKey(MockTriggerStepIdentifier);
    RK1DefineStringKey(MockDestinationStepIdentifier);
    
    // Test adding and removing a step navigation rule
    XCTAssertNil([_navigableOrderedTask navigationRuleForTriggerStepIdentifier:MockTriggerStepIdentifier]);
    
    RK1DirectStepNavigationRule *mockNavigationRule = [[RK1DirectStepNavigationRule alloc] initWithDestinationStepIdentifier:MockDestinationStepIdentifier];
    [_navigableOrderedTask setNavigationRule:mockNavigationRule forTriggerStepIdentifier:MockTriggerStepIdentifier];

    XCTAssertEqualObjects([_navigableOrderedTask navigationRuleForTriggerStepIdentifier:MockTriggerStepIdentifier], [mockNavigationRule copy]);

    RK1PredicateSkipStepNavigationRule *mockSkipNavigationRule = [[RK1PredicateSkipStepNavigationRule alloc] initWithResultPredicate:[NSPredicate predicateWithFormat:@"1 == 1"]];
    [_navigableOrderedTask setSkipNavigationRule:mockSkipNavigationRule forStepIdentifier:MockTriggerStepIdentifier];
    
    XCTAssertEqualObjects([_navigableOrderedTask skipNavigationRuleForStepIdentifier:MockTriggerStepIdentifier], [mockSkipNavigationRule copy]);
    
    [_navigableOrderedTask removeSkipNavigationRuleForStepIdentifier:MockTriggerStepIdentifier];
    XCTAssertNil([_navigableOrderedTask skipNavigationRuleForStepIdentifier:MockTriggerStepIdentifier]);
}

- (void)testNavigableOrderedTaskEmpty {
    getIndividualNavigableOrderedTaskSteps();
    
    //
    // Empty task result
    //
    RK1TaskResult *taskResult = [self getResultTreeWithTaskIdentifier:NavigableOrderedTaskIdentifier resultOptions:0];
    
    // Test forward navigation
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, nil, symptomStep));
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, symptomStep, otherSymptomStep));
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, otherSymptomStep, endStep));
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, endStep, nil));
    
    // Test absent backward navigation
    XCTAssertTrue(testStepBeforeStep(_navigableOrderedTask, taskResult, endStep, nil));
    XCTAssertTrue(testStepBeforeStep(_navigableOrderedTask, taskResult, otherSymptomStep, nil));
    XCTAssertTrue(testStepBeforeStep(_navigableOrderedTask, taskResult, symptomStep, nil));
    
    // Test unreachable nodes
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, severityStep, otherSymptomStep));
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, blankStep, severeHeadacheStep));
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, severeHeadacheStep, endStep));
    XCTAssertTrue(testStepBeforeStep(_navigableOrderedTask, taskResult, severeHeadacheStep, nil));
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, lightHeadacheStep, endStep));

}

- (void)testNavigableOrderedTaskHeadache {
    getIndividualNavigableOrderedTaskSteps();
    
    //
    // Only headache symptom question step answered
    //
    RK1TaskResult *taskResult = [self getResultTreeWithTaskIdentifier:NavigableOrderedTaskIdentifier resultOptions:TestsTaskResultOptionSymptomHeadache | TestsTaskResultOptionSeverityYes];
    
    // Test forward navigation
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, nil, symptomStep));
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, symptomStep, severityStep));
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, severityStep, severeHeadacheStep));
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, severeHeadacheStep, endStep));
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, endStep, nil));
    
    // Test backward navigation
    XCTAssertTrue(testStepBeforeStep(_navigableOrderedTask, taskResult, endStep, severeHeadacheStep));
    XCTAssertTrue(testStepBeforeStep(_navigableOrderedTask, taskResult, severeHeadacheStep, severityStep));
    XCTAssertTrue(testStepBeforeStep(_navigableOrderedTask, taskResult, severityStep, symptomStep));
    XCTAssertTrue(testStepBeforeStep(_navigableOrderedTask, taskResult, symptomStep, nil));
}

- (void)testNavigableOrderedTaskDizziness {
    getIndividualNavigableOrderedTaskSteps();
    
    //
    // Only dizziness symptom question answered
    //
    RK1TaskResult *taskResult = [self getResultTreeWithTaskIdentifier:NavigableOrderedTaskIdentifier resultOptions:TestsTaskResultOptionSymptomDizziness];
    
    // Test forward navigation
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, nil, symptomStep));
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, symptomStep, otherSymptomStep));
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, otherSymptomStep, endStep));
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, endStep, nil));
    
    // Test backward navigation
    XCTAssertTrue(testStepBeforeStep(_navigableOrderedTask, taskResult, endStep, otherSymptomStep));
    XCTAssertTrue(testStepBeforeStep(_navigableOrderedTask, taskResult, otherSymptomStep, symptomStep));
    XCTAssertTrue(testStepBeforeStep(_navigableOrderedTask, taskResult, symptomStep, nil));
}

- (void)testNavigableOrderedTaskSevereHeadache {
    getIndividualNavigableOrderedTaskSteps();
    
    //
    // Severe headache sequence
    //
    RK1TaskResult *taskResult = [self getResultTreeWithTaskIdentifier:NavigableOrderedTaskIdentifier resultOptions:TestsTaskResultOptionSymptomHeadache | TestsTaskResultOptionSeverityYes];
    
    // Test forward navigation
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, nil, symptomStep));
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, symptomStep, severityStep));
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, severityStep, severeHeadacheStep));
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, severeHeadacheStep, endStep));
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, endStep, nil));
    
    // Test backward navigation
    XCTAssertTrue(testStepBeforeStep(_navigableOrderedTask, taskResult, endStep, severeHeadacheStep));
    XCTAssertTrue(testStepBeforeStep(_navigableOrderedTask, taskResult, severeHeadacheStep, severityStep));
    XCTAssertTrue(testStepBeforeStep(_navigableOrderedTask, taskResult, severityStep, symptomStep));
    XCTAssertTrue(testStepBeforeStep(_navigableOrderedTask, taskResult, symptomStep, nil));
}

- (void)testNavigableOrderedTaskLightHeadache {
    getIndividualNavigableOrderedTaskSteps();
    
    //
    // Light headache sequence
    //
    RK1TaskResult *taskResult = [self getResultTreeWithTaskIdentifier:NavigableOrderedTaskIdentifier resultOptions:TestsTaskResultOptionSymptomHeadache | TestsTaskResultOptionSeverityNo];
    
    // Test forward navigation
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, nil, symptomStep));
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, symptomStep, severityStep));
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, severityStep, lightHeadacheStep));
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, lightHeadacheStep, endStep));
    XCTAssertTrue(testStepAfterStep(_navigableOrderedTask, taskResult, endStep, nil));
    
    // Test backward navigation
    XCTAssertTrue(testStepBeforeStep(_navigableOrderedTask, taskResult, endStep, lightHeadacheStep));
    XCTAssertTrue(testStepBeforeStep(_navigableOrderedTask, taskResult, lightHeadacheStep, severityStep));
    XCTAssertTrue(testStepBeforeStep(_navigableOrderedTask, taskResult, severityStep, symptomStep));
    XCTAssertTrue(testStepBeforeStep(_navigableOrderedTask, taskResult, symptomStep, nil));
}

- (void)testNavigableOrderedTaskSkip {
    RK1NavigableOrderedTask *skipTask = [_navigableOrderedTask copy];

    getIndividualNavigableOrderedTaskSteps();

    //
    // Light headache sequence
    //
    RK1TaskResult *taskResult = [self getResultTreeWithTaskIdentifier:NavigableOrderedTaskIdentifier resultOptions:TestsTaskResultOptionSymptomHeadache | TestsTaskResultOptionSeverityNo];

    // User chose headache at the symptom step
    RK1ResultSelector *resultSelector = [[RK1ResultSelector alloc] initWithResultIdentifier:SymptomStepIdentifier];
    NSPredicate *predicateHeadache = [RK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                                        expectedAnswerValue:HeadacheChoiceValue];
    RK1PredicateSkipStepNavigationRule *skipRule = [[RK1PredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicateHeadache];
    
    // Skip endStep
    [skipTask setSkipNavigationRule:skipRule forStepIdentifier:EndStepIdentifier];
    
    // Test forward navigation
    XCTAssertTrue(testStepAfterStep(skipTask, taskResult, nil, symptomStep));
    XCTAssertTrue(testStepAfterStep(skipTask, taskResult, symptomStep, severityStep));
    XCTAssertTrue(testStepAfterStep(skipTask, taskResult, severityStep, lightHeadacheStep));
    XCTAssertTrue(testStepAfterStep(skipTask, taskResult, lightHeadacheStep, nil));
    
    
    // Skip lightHeadacheStep
    [skipTask removeSkipNavigationRuleForStepIdentifier:EndStepIdentifier];
    [skipTask setSkipNavigationRule:skipRule forStepIdentifier:LightHeadacheStepIdentifier];
    
    XCTAssertTrue(testStepAfterStep(skipTask, taskResult, nil, symptomStep));
    XCTAssertTrue(testStepAfterStep(skipTask, taskResult, symptomStep, severityStep));
    XCTAssertTrue(testStepAfterStep(skipTask, taskResult, severityStep, endStep));
    XCTAssertTrue(testStepAfterStep(skipTask, taskResult, endStep, nil));

    
    // Skip lightHeadache and endStep
    [skipTask setSkipNavigationRule:skipRule forStepIdentifier:EndStepIdentifier];
    
    XCTAssertTrue(testStepAfterStep(skipTask, taskResult, nil, symptomStep));
    XCTAssertTrue(testStepAfterStep(skipTask, taskResult, symptomStep, severityStep));
    XCTAssertTrue(testStepAfterStep(skipTask, taskResult, severityStep, nil));
}

RK1DefineStringKey(SignConsentStepIdentifier);
RK1DefineStringKey(SignatureIdentifier);

RK1DefineStringKey(ScaleStepIdentifier);
RK1DefineStringKey(ContinuousScaleStepIdentifier);
static const NSInteger IntegerValue = 6;
static const float FloatValue = 6.5;

RK1DefineStringKey(SingleChoiceStepIdentifier);
RK1DefineStringKey(MultipleChoiceStepIdentifier);
RK1DefineStringKey(MixedMultipleChoiceStepIdentifier);
RK1DefineStringKey(SingleChoiceValue);
RK1DefineStringKey(MultipleChoiceValue1);
RK1DefineStringKey(MultipleChoiceValue2);
static const NSInteger MultipleChoiceValue3 = 7;

RK1DefineStringKey(BooleanStepIdentifier);
static const BOOL BooleanValue = YES;

RK1DefineStringKey(TextStepIdentifier);
RK1DefineStringKey(TextValue);
RK1DefineStringKey(OtherTextValue);

RK1DefineStringKey(IntegerNumericStepIdentifier);
RK1DefineStringKey(FloatNumericStepIdentifier);

RK1DefineStringKey(TimeOfDayStepIdentifier);
RK1DefineStringKey(TimeIntervalStepIdentifier);
RK1DefineStringKey(DateStepIdentifier);

RK1DefineStringKey(FormStepIdentifier);

RK1DefineStringKey(TextFormItemIdentifier);
RK1DefineStringKey(NumericFormItemIdentifier);

RK1DefineStringKey(NilTextStepIdentifier);

RK1DefineStringKey(AdditionalTaskIdentifier);
RK1DefineStringKey(AdditionalFormStepIdentifier);
RK1DefineStringKey(AdditionalTextFormItemIdentifier);
RK1DefineStringKey(AdditionalNumericFormItemIdentifier);

RK1DefineStringKey(AdditionalTextStepIdentifier);
RK1DefineStringKey(AdditionalTextValue);

RK1DefineStringKey(MatchedDestinationStepIdentifier);
RK1DefineStringKey(DefaultDestinationStepIdentifier);

static const NSInteger AdditionalIntegerValue = 42;

static NSDate *(^Date)(void) = ^NSDate *{ return [NSDate dateWithTimeIntervalSince1970:60*60*24]; };
static NSDateComponents *(^DateComponents)(void) = ^NSDateComponents *{
    NSDateComponents *dateComponents = [NSDateComponents new];
    dateComponents.hour = 6;
    dateComponents.minute = 6;
    return dateComponents;
};

static RK1QuestionResult *(^getQuestionResult)(NSString *, Class, RK1QuestionType, id) = ^RK1QuestionResult *(NSString *questionResultIdentifier, Class questionResultClass, RK1QuestionType questionType, id answer) {
    RK1QuestionResult *questionResult = [[questionResultClass alloc] init];
    questionResult.identifier = questionResultIdentifier;
    questionResult.answer = answer;
    questionResult.questionType = questionType;
    return questionResult;
};

static RK1StepResult *(^getStepResult)(NSString *, Class, RK1QuestionType, id) = ^RK1StepResult *(NSString *stepIdentifier, Class questionResultClass, RK1QuestionType questionType, id answer) {
    RK1QuestionResult *questionResult = getQuestionResult(stepIdentifier, questionResultClass, questionType, answer);
    RK1StepResult *stepResult = [[RK1StepResult alloc] initWithStepIdentifier:stepIdentifier results:@[questionResult]];
    return stepResult;
};

static RK1StepResult *(^getConsentStepResult)(NSString *, NSString *, BOOL) = ^RK1StepResult *(NSString *stepIdentifier, NSString *signatureIdentifier, BOOL consented) {
    RK1ConsentSignatureResult *consentSignatureResult = [[RK1ConsentSignatureResult alloc] initWithIdentifier:signatureIdentifier];
    consentSignatureResult.consented = consented;
    return [[RK1StepResult alloc] initWithStepIdentifier:stepIdentifier results:@[consentSignatureResult]];
};

- (RK1TaskResult *)getGeneralTaskResultTree {
    NSMutableArray *stepResults = [NSMutableArray new];
    
    [stepResults addObject:getStepResult(ScaleStepIdentifier, [RK1ScaleQuestionResult class], RK1QuestionTypeScale, @(IntegerValue))];
    [stepResults addObject:getStepResult(ContinuousScaleStepIdentifier, [RK1ScaleQuestionResult class], RK1QuestionTypeScale, @(FloatValue))];
    
    [stepResults addObject:getStepResult(SingleChoiceStepIdentifier, [RK1ChoiceQuestionResult class], RK1QuestionTypeSingleChoice, @[SingleChoiceValue])];
    [stepResults addObject:getStepResult(MultipleChoiceStepIdentifier, [RK1ChoiceQuestionResult class], RK1QuestionTypeMultipleChoice, @[MultipleChoiceValue1, MultipleChoiceValue2])];
    [stepResults addObject:getStepResult(MixedMultipleChoiceStepIdentifier, [RK1ChoiceQuestionResult class], RK1QuestionTypeMultipleChoice, @[MultipleChoiceValue1, MultipleChoiceValue2, @(MultipleChoiceValue3)])];
    
    [stepResults addObject:getStepResult(BooleanStepIdentifier, [RK1BooleanQuestionResult class], RK1QuestionTypeBoolean, @(BooleanValue))];
    
    [stepResults addObject:getStepResult(TextStepIdentifier, [RK1TextQuestionResult class], RK1QuestionTypeText, TextValue)];
    
    [stepResults addObject:getStepResult(IntegerNumericStepIdentifier, [RK1NumericQuestionResult class], RK1QuestionTypeInteger, @(IntegerValue))];
    [stepResults addObject:getStepResult(FloatNumericStepIdentifier, [RK1NumericQuestionResult class], RK1QuestionTypeDecimal, @(FloatValue))];
    
    [stepResults addObject:getStepResult(DateStepIdentifier, [RK1DateQuestionResult class], RK1QuestionTypeDate, Date())];
    
    [stepResults addObject:getStepResult(TimeIntervalStepIdentifier, [RK1TimeIntervalQuestionResult class], RK1QuestionTypeTimeInterval, @(IntegerValue))];
    
    [stepResults addObject:getStepResult(TimeOfDayStepIdentifier, [RK1TimeOfDayQuestionResult class], RK1QuestionTypeTimeOfDay, DateComponents())];
    
    // Nil result (simulate skipped step)
    [stepResults addObject:getStepResult(NilTextStepIdentifier, [RK1TextQuestionResult class], RK1QuestionTypeText, nil)];
    
    RK1TaskResult *taskResult = [[RK1TaskResult alloc] initWithTaskIdentifier:OrderedTaskIdentifier
                                                                  taskRunUUID:[NSUUID UUID]
                                                              outputDirectory:[NSURL fileURLWithPath:NSTemporaryDirectory()]];
    taskResult.results = stepResults;
    
    return taskResult;
}

- (RK1TaskResult *)getTaskResultTreeWithConsent:(BOOL)consented {
    NSMutableArray *stepResults = [NSMutableArray new];
    
    [stepResults addObject:getConsentStepResult(SignConsentStepIdentifier, SignatureIdentifier, consented)];
    
    RK1TaskResult *taskResult = [[RK1TaskResult alloc] initWithTaskIdentifier:OrderedTaskIdentifier
                                                                  taskRunUUID:[NSUUID UUID]
                                                              outputDirectory:[NSURL fileURLWithPath:NSTemporaryDirectory()]];
    taskResult.results = stepResults;
    
    return taskResult;
}

- (RK1TaskResult *)getSmallTaskResultTreeWithIsAdditionalTask:(BOOL)isAdditionalTask {
    NSMutableArray *stepResults = [NSMutableArray new];
    
    if (!isAdditionalTask) {
        [stepResults addObject:getStepResult(TextStepIdentifier, [RK1TextQuestionResult class], RK1QuestionTypeText, TextValue)];
    } else {
        [stepResults addObject:getStepResult(AdditionalTextStepIdentifier, [RK1TextQuestionResult class], RK1QuestionTypeText, AdditionalTextValue)];
    }
    
    RK1TaskResult *taskResult = [[RK1TaskResult alloc] initWithTaskIdentifier:!isAdditionalTask ? OrderedTaskIdentifier : AdditionalTaskIdentifier
                                                                  taskRunUUID:[NSUUID UUID]
                                                              outputDirectory:[NSURL fileURLWithPath:NSTemporaryDirectory()]];
    taskResult.results = stepResults;
    
    return taskResult;
}

- (RK1TaskResult *)getSmallFormTaskResultTreeWithIsAdditionalTask:(BOOL)isAdditionalTask {
    NSMutableArray *formItemResults = [NSMutableArray new];
    
    if (!isAdditionalTask) {
        [formItemResults addObject:getQuestionResult(TextFormItemIdentifier, [RK1TextQuestionResult class], RK1QuestionTypeText, TextValue)];
        [formItemResults addObject:getQuestionResult(NumericFormItemIdentifier, [RK1NumericQuestionResult class], RK1QuestionTypeInteger, @(IntegerValue))];
    } else {
        [formItemResults addObject:getQuestionResult(AdditionalTextFormItemIdentifier, [RK1TextQuestionResult class], RK1QuestionTypeText, AdditionalTextValue)];
        [formItemResults addObject:getQuestionResult(AdditionalNumericFormItemIdentifier, [RK1NumericQuestionResult class], RK1QuestionTypeInteger, @(AdditionalIntegerValue))];
    }
    
    RK1StepResult *formStepResult = [[RK1StepResult alloc] initWithStepIdentifier:(!isAdditionalTask ? FormStepIdentifier : AdditionalFormStepIdentifier) results:formItemResults];
    
    RK1TaskResult *taskResult = [[RK1TaskResult alloc] initWithTaskIdentifier:(!isAdditionalTask ? OrderedTaskIdentifier : AdditionalTaskIdentifier)
                                                                  taskRunUUID:[NSUUID UUID]
                                                              outputDirectory:[NSURL fileURLWithPath:NSTemporaryDirectory()]];
    taskResult.results = @[formStepResult];
    
    return taskResult;
}

- (RK1TaskResult *)getSmallTaskResultTreeWithDuplicateStepIdentifiers {
    NSMutableArray *stepResults = [NSMutableArray new];
    
    [stepResults addObject:getStepResult(TextStepIdentifier, [RK1TextQuestionResult class], RK1QuestionTypeText, TextValue)];
    [stepResults addObject:getStepResult(TextStepIdentifier, [RK1TextQuestionResult class], RK1QuestionTypeText, TextValue)];
    
    RK1TaskResult *taskResult = [[RK1TaskResult alloc] initWithTaskIdentifier:OrderedTaskIdentifier
                                                                  taskRunUUID:[NSUUID UUID]
                                                              outputDirectory:[NSURL fileURLWithPath:NSTemporaryDirectory()]];
    taskResult.results = stepResults;
    
    return taskResult;
}

- (void)testPredicateStepNavigationRule {
    NSPredicate *predicate = nil;
    NSPredicate *predicateA = nil;
    NSPredicate *predicateB = nil;
    RK1PredicateStepNavigationRule *predicateRule = nil;
    RK1TaskResult *taskResult = nil;
    RK1TaskResult *additionalTaskResult = nil;
    
    NSArray *resultPredicates = nil;
    NSArray *destinationStepIdentifiers = nil;
    NSString *defaultStepIdentifier = nil;
    
    RK1ResultSelector *resultSelector = nil;
    
    {
        // Test predicate step navigation rule initializers
        resultSelector = [[RK1ResultSelector alloc] initWithResultIdentifier:TextStepIdentifier];
        predicate = [RK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:TextValue];
        resultPredicates = @[ predicate ];
        destinationStepIdentifiers = @[ MatchedDestinationStepIdentifier ];
        predicateRule = [[RK1PredicateStepNavigationRule alloc] initWithResultPredicates:resultPredicates
                                                              destinationStepIdentifiers:destinationStepIdentifiers];
        
        XCTAssertEqualObjects(predicateRule.resultPredicates, RK1ArrayCopyObjects(resultPredicates));
        XCTAssertEqualObjects(predicateRule.destinationStepIdentifiers, RK1ArrayCopyObjects(destinationStepIdentifiers));
        XCTAssertNil(predicateRule.defaultStepIdentifier);
        
        defaultStepIdentifier = DefaultDestinationStepIdentifier;
        predicateRule = [[RK1PredicateStepNavigationRule alloc] initWithResultPredicates:resultPredicates
                                                              destinationStepIdentifiers:destinationStepIdentifiers
                                                                   defaultStepIdentifier:defaultStepIdentifier];
        
        XCTAssertEqualObjects(predicateRule.resultPredicates, RK1ArrayCopyObjects(resultPredicates));
        XCTAssertEqualObjects(predicateRule.destinationStepIdentifiers, RK1ArrayCopyObjects(destinationStepIdentifiers));
        XCTAssertEqualObjects(predicateRule.defaultStepIdentifier, defaultStepIdentifier);
    }
    
    {
        // Predicate matching, no additional task results, matching
        taskResult = [RK1TaskResult new];
        taskResult.identifier = OrderedTaskIdentifier;
        
        resultSelector = [[RK1ResultSelector alloc] initWithResultIdentifier:TextStepIdentifier];
        predicate = [RK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:TextValue];
        predicateRule = [[RK1PredicateStepNavigationRule alloc] initWithResultPredicates:@[ predicate ]
                                                              destinationStepIdentifiers:@[ MatchedDestinationStepIdentifier ]
                                                                   defaultStepIdentifier:DefaultDestinationStepIdentifier];
        
        XCTAssertEqualObjects([predicateRule identifierForDestinationStepWithTaskResult:taskResult], DefaultDestinationStepIdentifier);
        
        taskResult = [self getSmallTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertEqualObjects([predicateRule identifierForDestinationStepWithTaskResult:taskResult], MatchedDestinationStepIdentifier);
    }
    
    {
        // Predicate matching, no additional task results, non matching
        resultSelector = [[RK1ResultSelector alloc] initWithResultIdentifier:TextStepIdentifier];
        predicate = [RK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:OtherTextValue];
        predicateRule = [[RK1PredicateStepNavigationRule alloc] initWithResultPredicates:@[ predicate ]
                                                              destinationStepIdentifiers:@[ MatchedDestinationStepIdentifier ]
                                                                   defaultStepIdentifier:DefaultDestinationStepIdentifier];
        taskResult = [self getSmallTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertEqualObjects([predicateRule identifierForDestinationStepWithTaskResult:taskResult], DefaultDestinationStepIdentifier);
    }
    
    {
        NSPredicate *currentPredicate = nil;
        NSPredicate *additionalPredicate = nil;
        
        // Predicate matching, additional task results
        resultSelector = [[RK1ResultSelector alloc] initWithResultIdentifier:TextStepIdentifier];
        currentPredicate = [RK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                                 expectedString:TextValue];
        
        resultSelector = [[RK1ResultSelector alloc] initWithTaskIdentifier:AdditionalTaskIdentifier
                                                            resultIdentifier:AdditionalTextStepIdentifier];
        additionalPredicate = [RK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                                    expectedString:AdditionalTextValue];
        
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[currentPredicate, additionalPredicate]];
        predicateRule = [[RK1PredicateStepNavigationRule alloc] initWithResultPredicates:@[ predicate ]
                                                              destinationStepIdentifiers:@[ MatchedDestinationStepIdentifier ]
                                                                   defaultStepIdentifier:DefaultDestinationStepIdentifier];
        
        taskResult = [RK1TaskResult new];
        taskResult.identifier = OrderedTaskIdentifier;
        XCTAssertEqualObjects([predicateRule identifierForDestinationStepWithTaskResult:taskResult], DefaultDestinationStepIdentifier);
        
        taskResult = [self getSmallTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertEqualObjects([predicateRule identifierForDestinationStepWithTaskResult:taskResult], DefaultDestinationStepIdentifier);
        
        additionalTaskResult = [self getSmallTaskResultTreeWithIsAdditionalTask:YES];
        predicateRule.additionalTaskResults = @[ additionalTaskResult ];
        XCTAssertEqualObjects([predicateRule identifierForDestinationStepWithTaskResult:taskResult], MatchedDestinationStepIdentifier);
    }
    
    {
        // Test duplicate task identifiers check
        predicateRule.additionalTaskResults = @[ taskResult ];
        XCTAssertThrows([predicateRule identifierForDestinationStepWithTaskResult:taskResult]);
        
        // Test duplicate question result identifiers check
        XCTAssertThrows(predicateRule.additionalTaskResults = @[ [self getSmallTaskResultTreeWithDuplicateStepIdentifiers] ]);
    }
    
    {
        // Form predicate matching, no additional task results, matching
        resultSelector = [[RK1ResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                            resultIdentifier:TextFormItemIdentifier];
        predicateA = [RK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                           expectedString:TextValue];
        
        resultSelector = [[RK1ResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                            resultIdentifier:NumericFormItemIdentifier];
        predicateB = [RK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                              expectedAnswer:IntegerValue];
        
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateA, predicateB]];
        predicateRule = [[RK1PredicateStepNavigationRule alloc] initWithResultPredicates:@[ predicate ]
                                                              destinationStepIdentifiers:@[ MatchedDestinationStepIdentifier ]
                                                                   defaultStepIdentifier:DefaultDestinationStepIdentifier];
        
        taskResult = [self getSmallFormTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertEqualObjects([predicateRule identifierForDestinationStepWithTaskResult:taskResult], MatchedDestinationStepIdentifier);
    }
    
    {
        // Form predicate matching, no additional task results, non matching
        resultSelector = [[RK1ResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                            resultIdentifier:TextFormItemIdentifier];
        predicate = [RK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:OtherTextValue];
        predicateRule = [[RK1PredicateStepNavigationRule alloc] initWithResultPredicates:@[ predicate ]
                                                              destinationStepIdentifiers:@[ MatchedDestinationStepIdentifier ]
                                                                   defaultStepIdentifier:DefaultDestinationStepIdentifier];
        taskResult = [self getSmallFormTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertEqualObjects([predicateRule identifierForDestinationStepWithTaskResult:taskResult], DefaultDestinationStepIdentifier);
    }
    
    {
        NSPredicate *currentPredicate = nil;
        NSPredicate *additionalPredicate = nil;
        
        // Form predicate matching, additional task results
        resultSelector = [[RK1ResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                            resultIdentifier:TextFormItemIdentifier];
        predicateA = [RK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                           expectedString:TextValue];
        
        resultSelector = [[RK1ResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                            resultIdentifier:NumericFormItemIdentifier];
        predicateB = [RK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                              expectedAnswer:IntegerValue];
        
        currentPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateA, predicateB]];
        
        resultSelector = [[RK1ResultSelector alloc] initWithTaskIdentifier:AdditionalTaskIdentifier
                                                              stepIdentifier:AdditionalFormStepIdentifier
                                                            resultIdentifier:AdditionalTextFormItemIdentifier];
        predicateA = [RK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                           expectedString:AdditionalTextValue];
        
        resultSelector = [[RK1ResultSelector alloc] initWithTaskIdentifier:AdditionalTaskIdentifier
                                                              stepIdentifier:AdditionalFormStepIdentifier
                                                            resultIdentifier:AdditionalNumericFormItemIdentifier];
        predicateB = [RK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                              expectedAnswer:AdditionalIntegerValue];
        
        additionalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateA, predicateB]];
        
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[currentPredicate, additionalPredicate]];
        predicateRule = [[RK1PredicateStepNavigationRule alloc] initWithResultPredicates:@[ predicate ]
                                                              destinationStepIdentifiers:@[ MatchedDestinationStepIdentifier ]
                                                                   defaultStepIdentifier:DefaultDestinationStepIdentifier];
        
        taskResult = [self getSmallFormTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertEqualObjects([predicateRule identifierForDestinationStepWithTaskResult:taskResult], DefaultDestinationStepIdentifier);
        
        additionalTaskResult = [self getSmallFormTaskResultTreeWithIsAdditionalTask:YES];
        predicateRule.additionalTaskResults = @[ additionalTaskResult ];
        XCTAssertEqualObjects([predicateRule identifierForDestinationStepWithTaskResult:taskResult], MatchedDestinationStepIdentifier);
    }
}

- (void)testPredicateSkipStepNavigationRule {
    NSPredicate *predicate = nil;
    NSPredicate *predicateA = nil;
    NSPredicate *predicateB = nil;
    RK1PredicateSkipStepNavigationRule *predicateRule = nil;
    RK1TaskResult *taskResult = nil;
    RK1TaskResult *additionalTaskResult = nil;
    
    RK1ResultSelector *resultSelector = nil;
    
    {
        // Test predicate step navigation rule initializers
        resultSelector = [[RK1ResultSelector alloc] initWithResultIdentifier:TextStepIdentifier];
        predicate = [RK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:TextValue];
        predicateRule = [[RK1PredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicate];
        XCTAssertEqualObjects(predicateRule.resultPredicate, predicate);
    }
    
    {
        // Predicate matching, no additional task results, matching
        taskResult = [RK1TaskResult new];
        taskResult.identifier = OrderedTaskIdentifier;
        
        resultSelector = [[RK1ResultSelector alloc] initWithResultIdentifier:TextStepIdentifier];
        predicate = [RK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:TextValue];
        predicateRule = [[RK1PredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicate];
        
        XCTAssertFalse([predicateRule stepShouldSkipWithTaskResult:taskResult]);
        
        taskResult = [self getSmallTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertTrue([predicateRule stepShouldSkipWithTaskResult:taskResult]);
    }
    
    {
        // Predicate matching, no additional task results, non matching
        resultSelector = [[RK1ResultSelector alloc] initWithResultIdentifier:TextStepIdentifier];
        predicate = [RK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:OtherTextValue];
        predicateRule = [[RK1PredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicate];
        taskResult = [self getSmallTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertFalse([predicateRule stepShouldSkipWithTaskResult:taskResult]);
    }

    {
        NSPredicate *currentPredicate = nil;
        NSPredicate *additionalPredicate = nil;
        
        // Predicate matching, additional task results
        resultSelector = [[RK1ResultSelector alloc] initWithResultIdentifier:TextStepIdentifier];
        currentPredicate = [RK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                                 expectedString:TextValue];
        
        resultSelector = [[RK1ResultSelector alloc] initWithTaskIdentifier:AdditionalTaskIdentifier
                                                          resultIdentifier:AdditionalTextStepIdentifier];
        additionalPredicate = [RK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                                    expectedString:AdditionalTextValue];
        
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[currentPredicate, additionalPredicate]];
        predicateRule = [[RK1PredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicate];
        
        taskResult = [RK1TaskResult new];
        taskResult.identifier = OrderedTaskIdentifier;
        XCTAssertFalse([predicateRule stepShouldSkipWithTaskResult:taskResult]);
        
        taskResult = [self getSmallTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertFalse([predicateRule stepShouldSkipWithTaskResult:taskResult]);
        
        additionalTaskResult = [self getSmallTaskResultTreeWithIsAdditionalTask:YES];
        predicateRule.additionalTaskResults = @[ additionalTaskResult ];
        XCTAssertTrue([predicateRule stepShouldSkipWithTaskResult:taskResult]);
    }

    {
        // Test duplicate task identifiers check
        predicateRule.additionalTaskResults = @[ taskResult ];
        XCTAssertThrows([predicateRule stepShouldSkipWithTaskResult:taskResult]);
        
        // Test duplicate question result identifiers check
        XCTAssertThrows(predicateRule.additionalTaskResults = @[ [self getSmallTaskResultTreeWithDuplicateStepIdentifiers] ]);
    }
    
    {
        // Form predicate matching, no additional task results, matching
        resultSelector = [[RK1ResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                          resultIdentifier:TextFormItemIdentifier];
        predicateA = [RK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                           expectedString:TextValue];
        
        resultSelector = [[RK1ResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                          resultIdentifier:NumericFormItemIdentifier];
        predicateB = [RK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                              expectedAnswer:IntegerValue];
        
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateA, predicateB]];
        predicateRule = [[RK1PredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicate];
        
        taskResult = [self getSmallFormTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertTrue([predicateRule stepShouldSkipWithTaskResult:taskResult]);
    }

    {
        // Form predicate matching, no additional task results, non matching
        resultSelector = [[RK1ResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                          resultIdentifier:TextFormItemIdentifier];
        predicate = [RK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:OtherTextValue];
        predicateRule = [[RK1PredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicate];
        
        taskResult = [self getSmallFormTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertFalse([predicateRule stepShouldSkipWithTaskResult:taskResult]);
    }
    
    {
        NSPredicate *currentPredicate = nil;
        NSPredicate *additionalPredicate = nil;
        
        // Form predicate matching, additional task results
        resultSelector = [[RK1ResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                          resultIdentifier:TextFormItemIdentifier];
        predicateA = [RK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                           expectedString:TextValue];
        
        resultSelector = [[RK1ResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                          resultIdentifier:NumericFormItemIdentifier];
        predicateB = [RK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                              expectedAnswer:IntegerValue];
        
        currentPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateA, predicateB]];
        
        resultSelector = [[RK1ResultSelector alloc] initWithTaskIdentifier:AdditionalTaskIdentifier
                                                            stepIdentifier:AdditionalFormStepIdentifier
                                                          resultIdentifier:AdditionalTextFormItemIdentifier];
        predicateA = [RK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                           expectedString:AdditionalTextValue];
        
        resultSelector = [[RK1ResultSelector alloc] initWithTaskIdentifier:AdditionalTaskIdentifier
                                                            stepIdentifier:AdditionalFormStepIdentifier
                                                          resultIdentifier:AdditionalNumericFormItemIdentifier];
        predicateB = [RK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                              expectedAnswer:AdditionalIntegerValue];
        
        additionalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateA, predicateB]];
        
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[currentPredicate, additionalPredicate]];
        predicateRule = [[RK1PredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicate];
        
        taskResult = [self getSmallFormTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertFalse([predicateRule stepShouldSkipWithTaskResult:taskResult]);
        
        additionalTaskResult = [self getSmallFormTaskResultTreeWithIsAdditionalTask:YES];
        predicateRule.additionalTaskResults = @[ additionalTaskResult ];
        XCTAssertTrue([predicateRule stepShouldSkipWithTaskResult:taskResult]);
    }
}

- (void)testDirectStepNavigationRule {
    RK1DirectStepNavigationRule *directRule = nil;
    RK1TaskResult *mockTaskResult = [RK1TaskResult new];
    
    directRule = [[RK1DirectStepNavigationRule alloc] initWithDestinationStepIdentifier:MatchedDestinationStepIdentifier];
    XCTAssertEqualObjects(directRule.destinationStepIdentifier, [MatchedDestinationStepIdentifier copy] );
    XCTAssertEqualObjects([directRule identifierForDestinationStepWithTaskResult:mockTaskResult], [MatchedDestinationStepIdentifier copy]);
    
    directRule = [[RK1DirectStepNavigationRule alloc] initWithDestinationStepIdentifier:RK1NullStepIdentifier];
    XCTAssertEqualObjects(directRule.destinationStepIdentifier, [RK1NullStepIdentifier copy]);
    XCTAssertEqualObjects([directRule identifierForDestinationStepWithTaskResult:mockTaskResult], [RK1NullStepIdentifier copy]);
}

- (void)testResultPredicatesWithTaskIdentifier:(NSString *)taskIdentifier
                         substitutionVariables:(NSDictionary *)substitutionVariables
                                   taskResults:(NSArray *)taskResults {
    // RK1ScaleQuestionResult
    RK1ResultSelector *resultSelector = [[RK1ResultSelector alloc] initWithTaskIdentifier:taskIdentifier
                                                                         resultIdentifier:@""];
    
    resultSelector.resultIdentifier = ScaleStepIdentifier;
    XCTAssertTrue([[RK1ResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector
                                                                          expectedAnswer:IntegerValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[RK1ResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector
                                                                           expectedAnswer:IntegerValue + 1] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    resultSelector.resultIdentifier = ContinuousScaleStepIdentifier;
    XCTAssertTrue([[RK1ResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector
                                                              minimumExpectedAnswerValue:FloatValue - 0.01
                                                              maximumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[RK1ResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector
                                                               minimumExpectedAnswerValue:FloatValue + 0.05
                                                               maximumExpectedAnswerValue:FloatValue + 0.06] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[RK1ResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector
                                                              minimumExpectedAnswerValue:FloatValue - 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[RK1ResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector
                                                               minimumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[RK1ResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector
                                                              maximumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[RK1ResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector
                                                               maximumExpectedAnswerValue:FloatValue - 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // RK1ChoiceQuestionResult (strings)
    resultSelector.resultIdentifier = SingleChoiceStepIdentifier;
    XCTAssertTrue([[RK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                      expectedAnswerValue:SingleChoiceValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[RK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                       expectedAnswerValue:OtherTextValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    resultSelector.resultIdentifier = MultipleChoiceStepIdentifier;
    NSArray *expectedAnswers = nil;
    expectedAnswers = @[MultipleChoiceValue1];
    XCTAssertTrue([[RK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                     expectedAnswerValues:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    expectedAnswers = @[MultipleChoiceValue1, MultipleChoiceValue2];
    XCTAssertTrue([[RK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                     expectedAnswerValues:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    expectedAnswers = @[MultipleChoiceValue1, MultipleChoiceValue2, OtherTextValue];
    XCTAssertFalse([[RK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                      expectedAnswerValues:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    expectedAnswers = @[MultipleChoiceValue1, MultipleChoiceValue2, @(MultipleChoiceValue3)];
    XCTAssertFalse([[RK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                      expectedAnswerValues:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    resultSelector.resultIdentifier = MixedMultipleChoiceStepIdentifier;
    expectedAnswers = @[MultipleChoiceValue1];
    XCTAssertTrue([[RK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                     expectedAnswerValues:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    expectedAnswers = @[@(MultipleChoiceValue3)];
    XCTAssertTrue([[RK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                     expectedAnswerValues:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    expectedAnswers = @[MultipleChoiceValue1, MultipleChoiceValue2, @(MultipleChoiceValue3)];
    XCTAssertTrue([[RK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                     expectedAnswerValues:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    expectedAnswers = @[MultipleChoiceValue1, MultipleChoiceValue2, OtherTextValue];
    XCTAssertFalse([[RK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                      expectedAnswerValues:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // RK1ChoiceQuestionResult (regular expressions)
    resultSelector.resultIdentifier = SingleChoiceStepIdentifier;
    XCTAssertTrue([[RK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                          matchingPattern:@"...gleChoiceValue"] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[RK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                       expectedAnswerValue:@"...SingleChoiceValue"] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    resultSelector.resultIdentifier = MultipleChoiceStepIdentifier;
    expectedAnswers = @[@"...tipleChoiceValue1", @"...tipleChoiceValue2"];
    XCTAssertTrue([[RK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                         matchingPatterns:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    expectedAnswers = @[@"...MultipleChoiceValue1", @"...MultipleChoiceValue2", @"...OtherTextValue"];
    XCTAssertFalse([[RK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                          matchingPatterns:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // RK1BooleanQuestionResult
    resultSelector.resultIdentifier = BooleanStepIdentifier;
    XCTAssertTrue([[RK1ResultPredicate predicateForBooleanQuestionResultWithResultSelector:resultSelector
                                                                            expectedAnswer:BooleanValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[RK1ResultPredicate predicateForBooleanQuestionResultWithResultSelector:resultSelector
                                                                             expectedAnswer:!BooleanValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // RK1TextQuestionResult (strings)
    resultSelector.resultIdentifier = TextStepIdentifier;
    XCTAssertTrue([[RK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                         expectedString:TextValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[RK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:OtherTextValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // RK1TextQuestionResult (regular expressions)
    XCTAssertTrue([[RK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                        matchingPattern:@"...tValue"] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[RK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                         matchingPattern:@"...TextValue"] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // RK1NumericQuestionResult
    resultSelector.resultIdentifier = IntegerNumericStepIdentifier;
    XCTAssertTrue([[RK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                            expectedAnswer:IntegerValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertFalse([[RK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                             expectedAnswer:IntegerValue + 1] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    resultSelector.resultIdentifier = FloatNumericStepIdentifier;
    XCTAssertTrue([[RK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                minimumExpectedAnswerValue:RK1IgnoreDoubleValue
                                                                maximumExpectedAnswerValue:RK1IgnoreDoubleValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[RK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                minimumExpectedAnswerValue:FloatValue - 0.01
                                                                maximumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[RK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                 minimumExpectedAnswerValue:FloatValue + 0.05
                                                                 maximumExpectedAnswerValue:FloatValue + 0.06] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[RK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                minimumExpectedAnswerValue:FloatValue - 0.01
                                                                maximumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[RK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                 minimumExpectedAnswerValue:FloatValue + 0.05
                                                                 maximumExpectedAnswerValue:FloatValue + 0.06] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[RK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                minimumExpectedAnswerValue:FloatValue - 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[RK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                 minimumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[RK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                maximumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[RK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                 maximumExpectedAnswerValue:FloatValue - 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // RK1TimeOfDayQuestionResult
    resultSelector.resultIdentifier = TimeOfDayStepIdentifier;
    NSDateComponents *expectedDateComponentsMinimum = DateComponents();
    NSDateComponents *expectedDateComponentsMaximum = DateComponents();
    XCTAssertTrue([[RK1ResultPredicate predicateForTimeOfDayQuestionResultWithResultSelector:resultSelector
                                                                         minimumExpectedHour:expectedDateComponentsMinimum.hour
                                                                       minimumExpectedMinute:expectedDateComponentsMinimum.minute
                                                                         maximumExpectedHour:expectedDateComponentsMaximum.hour
                                                                       maximumExpectedMinute:expectedDateComponentsMaximum.minute] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    expectedDateComponentsMinimum.minute -= 2;
    expectedDateComponentsMaximum.minute += 2;
    XCTAssertTrue([[RK1ResultPredicate predicateForTimeOfDayQuestionResultWithResultSelector:resultSelector
                                                                         minimumExpectedHour:expectedDateComponentsMinimum.hour
                                                                       minimumExpectedMinute:expectedDateComponentsMinimum.minute
                                                                         maximumExpectedHour:expectedDateComponentsMaximum.hour
                                                                       maximumExpectedMinute:expectedDateComponentsMaximum.minute] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    expectedDateComponentsMinimum.minute += 3;
    XCTAssertFalse([[RK1ResultPredicate predicateForTimeOfDayQuestionResultWithResultSelector:resultSelector
                                                                          minimumExpectedHour:expectedDateComponentsMinimum.hour
                                                                        minimumExpectedMinute:expectedDateComponentsMinimum.minute
                                                                          maximumExpectedHour:expectedDateComponentsMaximum.hour
                                                                        maximumExpectedMinute:expectedDateComponentsMaximum.minute] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    expectedDateComponentsMinimum.minute -= 3;
    expectedDateComponentsMinimum.hour += 1;
    expectedDateComponentsMaximum.hour += 2;
    XCTAssertFalse([[RK1ResultPredicate predicateForTimeOfDayQuestionResultWithResultSelector:resultSelector
                                                                          minimumExpectedHour:expectedDateComponentsMinimum.hour
                                                                        minimumExpectedMinute:expectedDateComponentsMinimum.minute
                                                                          maximumExpectedHour:expectedDateComponentsMaximum.hour
                                                                        maximumExpectedMinute:expectedDateComponentsMaximum.minute] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // RK1TimeIntervalQuestionResult
    resultSelector.resultIdentifier = FloatNumericStepIdentifier;
    XCTAssertTrue([[RK1ResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                     minimumExpectedAnswerValue:RK1IgnoreTimeIntervalValue
                                                                     maximumExpectedAnswerValue:RK1IgnoreTimeIntervalValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[RK1ResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                     minimumExpectedAnswerValue:FloatValue - 0.01
                                                                     maximumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[RK1ResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                      minimumExpectedAnswerValue:FloatValue + 0.05
                                                                      maximumExpectedAnswerValue:FloatValue + 0.06] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[RK1ResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                     minimumExpectedAnswerValue:FloatValue - 0.01
                                                                     maximumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[RK1ResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                      minimumExpectedAnswerValue:FloatValue + 0.05
                                                                      maximumExpectedAnswerValue:FloatValue + 0.06] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[RK1ResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                     minimumExpectedAnswerValue:FloatValue - 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[RK1ResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                      minimumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[RK1ResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                     maximumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[RK1ResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                      maximumExpectedAnswerValue:FloatValue - 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // RK1DateQuestionResult
    resultSelector.resultIdentifier = DateStepIdentifier;
    NSDate *expectedDate = Date();
    XCTAssertTrue([[RK1ResultPredicate predicateForDateQuestionResultWithResultSelector:resultSelector
                                                              minimumExpectedAnswerDate:[expectedDate dateByAddingTimeInterval:-60]
                                                              maximumExpectedAnswerDate:[expectedDate dateByAddingTimeInterval:+60]] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[RK1ResultPredicate predicateForDateQuestionResultWithResultSelector:resultSelector
                                                               minimumExpectedAnswerDate:[expectedDate dateByAddingTimeInterval:+60]
                                                               maximumExpectedAnswerDate:[expectedDate dateByAddingTimeInterval:+120]] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[RK1ResultPredicate predicateForDateQuestionResultWithResultSelector:resultSelector
                                                              minimumExpectedAnswerDate:[expectedDate dateByAddingTimeInterval:-60]
                                                              maximumExpectedAnswerDate:nil] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[RK1ResultPredicate predicateForDateQuestionResultWithResultSelector:resultSelector
                                                               minimumExpectedAnswerDate:[expectedDate dateByAddingTimeInterval:+1]
                                                               maximumExpectedAnswerDate:nil] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[RK1ResultPredicate predicateForDateQuestionResultWithResultSelector:resultSelector
                                                              minimumExpectedAnswerDate:nil
                                                              maximumExpectedAnswerDate:[expectedDate dateByAddingTimeInterval:+60]] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[RK1ResultPredicate predicateForDateQuestionResultWithResultSelector:resultSelector
                                                               minimumExpectedAnswerDate:nil
                                                               maximumExpectedAnswerDate:[expectedDate dateByAddingTimeInterval:-1]] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[RK1ResultPredicate predicateForDateQuestionResultWithResultSelector:resultSelector
                                                              minimumExpectedAnswerDate:nil
                                                              maximumExpectedAnswerDate:nil] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // Result with nil value
    resultSelector.resultIdentifier = NilTextStepIdentifier;
    XCTAssertTrue([[RK1ResultPredicate predicateForNilQuestionResultWithResultSelector:resultSelector] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    resultSelector.resultIdentifier = TextStepIdentifier;
    XCTAssertFalse([[RK1ResultPredicate predicateForNilQuestionResultWithResultSelector:resultSelector] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
}

- (void)testConsentPredicate {
    RK1ResultSelector *resultSelector = [[RK1ResultSelector alloc] initWithTaskIdentifier:OrderedTaskIdentifier
                                                                           stepIdentifier:SignConsentStepIdentifier
                                                                         resultIdentifier:SignatureIdentifier];
    {
        RK1TaskResult *consentedTaskResult = [self getTaskResultTreeWithConsent:YES];
        XCTAssertTrue([[RK1ResultPredicate predicateForConsentWithResultSelector:resultSelector
                                                                      didConsent:YES] evaluateWithObject:@[consentedTaskResult] substitutionVariables:nil]);
        XCTAssertFalse([[RK1ResultPredicate predicateForConsentWithResultSelector:resultSelector
                                                                       didConsent:NO] evaluateWithObject:@[consentedTaskResult] substitutionVariables:nil]);
    }
    
    {
        RK1TaskResult *didNotConsentTaskResult = [self getTaskResultTreeWithConsent:NO];
        
        XCTAssertTrue([[RK1ResultPredicate predicateForConsentWithResultSelector:resultSelector
                                                                      didConsent:NO] evaluateWithObject:@[didNotConsentTaskResult] substitutionVariables:nil]);
        XCTAssertFalse([[RK1ResultPredicate predicateForConsentWithResultSelector:resultSelector
                                                                       didConsent:YES] evaluateWithObject:@[didNotConsentTaskResult] substitutionVariables:nil]);
    }
}

- (void)testResultPredicates {
    RK1TaskResult *taskResult = [self getGeneralTaskResultTree];
    NSArray *taskResults = @[ taskResult ];
    
    // The following two calls are equivalent since 'substitutionVariables' are ignored when you provide a non-nil task identifier
    [self testResultPredicatesWithTaskIdentifier:OrderedTaskIdentifier
                           substitutionVariables:nil
                                     taskResults:taskResults];
    [self testResultPredicatesWithTaskIdentifier:OrderedTaskIdentifier
                           substitutionVariables:@{RK1ResultPredicateTaskIdentifierVariableName: OrderedTaskIdentifier}
                                     taskResults:taskResults];
    // Test nil task identifier variable substitution
    [self testResultPredicatesWithTaskIdentifier:nil
                           substitutionVariables:@{RK1ResultPredicateTaskIdentifierVariableName: OrderedTaskIdentifier}
                                     taskResults:taskResults];
}

- (void)testStepViewControllerWillDisappear {
    TestTaskViewControllerDelegate *delegate = [[TestTaskViewControllerDelegate alloc] init];
    RK1OrderedTask *task = [RK1OrderedTask twoFingerTappingIntervalTaskWithIdentifier:@"test" intendedUseDescription:nil duration:30 handOptions:0 options:0];
    RK1TaskViewController *taskViewController = [[MockTaskViewController alloc] initWithTask:task taskRunUUID:nil];
    taskViewController.delegate = delegate;
    RK1InstructionStepViewController *stepViewController = [[RK1InstructionStepViewController alloc] initWithStep:task.steps.firstObject];
    
    //-- call method under test
    [taskViewController stepViewController:stepViewController didFinishWithNavigationDirection:RK1StepViewControllerNavigationDirectionForward];
    
    // Check that the expected methods were called
    XCTAssertEqual(delegate.methodCalled.count, 1);
    XCTAssertEqualObjects(delegate.methodCalled.firstObject.selectorName, @"taskViewController:stepViewControllerWillDisappear:navigationDirection:");
    NSArray *expectedArgs = @[taskViewController, stepViewController, @(RK1StepViewControllerNavigationDirectionForward)];
    XCTAssertEqualObjects(delegate.methodCalled.firstObject.arguments, expectedArgs);
    
}

- (void)testIndexOfStep {
    RK1OrderedTask *task = [RK1OrderedTask twoFingerTappingIntervalTaskWithIdentifier:@"tapping" intendedUseDescription:nil duration:30 handOptions:0 options:0];
    
    // get the first step
    RK1Step *step0 = [task.steps firstObject];
    XCTAssertNotNil(step0);
    XCTAssertEqual([task indexOfStep:step0], 0);
    
    // get the second step
    RK1Step *step1 = [task stepWithIdentifier:RK1Instruction1StepIdentifier];
    XCTAssertNotNil(step1);
    XCTAssertEqual([task indexOfStep:step1], 1);
    
    // get the last step
    RK1Step *stepLast = [task.steps lastObject];
    XCTAssertNotNil(stepLast);
    XCTAssertEqual([task indexOfStep:stepLast], task.steps.count - 1);
    
    // Look for not found
    RK1Step *stepNF = [[RK1Step alloc] initWithIdentifier:@"foo"];
    XCTAssertEqual([task indexOfStep:stepNF], NSNotFound);
    
}

- (void)testAudioTask_WithSoundCheck {
    RK1NavigableOrderedTask *task = [RK1OrderedTask audioTaskWithIdentifier:@"audio" intendedUseDescription:nil speechInstruction:nil shortSpeechInstruction:nil duration:20 recordingSettings:nil checkAudioLevel:YES options:0];
    
    NSArray *expectedStepIdentifiers = @[RK1Instruction0StepIdentifier,
                                         RK1Instruction1StepIdentifier,
                                         RK1CountdownStepIdentifier,
                                         RK1AudioTooLoudStepIdentifier,
                                         RK1AudioStepIdentifier,
                                         RK1ConclusionStepIdentifier];
    NSArray *stepIdentifiers = [task.steps valueForKey:@"identifier"];
    XCTAssertEqual(stepIdentifiers.count, expectedStepIdentifiers.count);
    XCTAssertEqualObjects(stepIdentifiers, expectedStepIdentifiers);
    
    XCTAssertNotNil([task navigationRuleForTriggerStepIdentifier:RK1CountdownStepIdentifier]);
    XCTAssertNotNil([task navigationRuleForTriggerStepIdentifier:RK1AudioTooLoudStepIdentifier]);
}

- (void)testAudioTask_NoSoundCheck {
    
    RK1NavigableOrderedTask *task = [RK1OrderedTask audioTaskWithIdentifier:@"audio" intendedUseDescription:nil speechInstruction:nil shortSpeechInstruction:nil duration:20 recordingSettings:nil checkAudioLevel:NO options:0];
    
    NSArray *expectedStepIdentifiers = @[RK1Instruction0StepIdentifier,
                                         RK1Instruction1StepIdentifier,
                                         RK1CountdownStepIdentifier,
                                         RK1AudioStepIdentifier,
                                         RK1ConclusionStepIdentifier];
    NSArray *stepIdentifiers = [task.steps valueForKey:@"identifier"];
    XCTAssertEqual(stepIdentifiers.count, expectedStepIdentifiers.count);
    XCTAssertEqualObjects(stepIdentifiers, expectedStepIdentifiers);
    XCTAssertEqual(task.stepNavigationRules.count, 0);
}

- (void)testWalkBackAndForthTask_30SecondDuration {
    
    // Create the task
    RK1OrderedTask *task = [RK1OrderedTask walkBackAndForthTaskWithIdentifier:@"walking" intendedUseDescription:nil walkDuration:30 restDuration:30 options:0];
    
    // Check that the steps match the expected - If these change, it will affect the results and
    // could adversely impact existing studies that are expecting this step order.
    NSArray *expectedStepIdentifiers = @[RK1Instruction0StepIdentifier,
                                         RK1Instruction1StepIdentifier,
                                         RK1CountdownStepIdentifier,
                                         RK1ShortWalkOutboundStepIdentifier,
                                         RK1ShortWalkRestStepIdentifier,
                                         RK1ConclusionStepIdentifier];
    XCTAssertEqual(task.steps.count, expectedStepIdentifiers.count);
    NSArray *stepIdentifiers = [task.steps valueForKey:@"identifier"];
    XCTAssertEqualObjects(stepIdentifiers, expectedStepIdentifiers);
    
    // Check that the active steps include speaking the halfway point
    RK1ActiveStep *walkingStep = (RK1ActiveStep *)[task stepWithIdentifier:RK1ShortWalkOutboundStepIdentifier];
    XCTAssertTrue(walkingStep.shouldSpeakRemainingTimeAtHalfway);
    RK1ActiveStep *restStep = (RK1ActiveStep *)[task stepWithIdentifier:RK1ShortWalkRestStepIdentifier];
    XCTAssertTrue(restStep.shouldSpeakRemainingTimeAtHalfway);
    
}

- (void)testWalkBackAndForthTask_15SecondDuration_NoRest {
    
    // Create the task
    RK1OrderedTask *task = [RK1OrderedTask walkBackAndForthTaskWithIdentifier:@"walking" intendedUseDescription:nil walkDuration:15 restDuration:0 options:0];
    
    // Check that the steps match the expected - If these change, it will affect the results and
    // could adversely impact existing studies that are expecting this step order.
    NSArray *expectedStepIdentifiers = @[RK1Instruction0StepIdentifier,
                                         RK1Instruction1StepIdentifier,
                                         RK1CountdownStepIdentifier,
                                         RK1ShortWalkOutboundStepIdentifier,
                                         RK1ConclusionStepIdentifier];
    XCTAssertEqual(task.steps.count, expectedStepIdentifiers.count);
    NSArray *stepIdentifiers = [task.steps valueForKey:@"identifier"];
    XCTAssertEqualObjects(stepIdentifiers, expectedStepIdentifiers);
    
    // Check that the active steps include speaking the halfway point
    RK1ActiveStep *walkingStep = (RK1ActiveStep *)[task stepWithIdentifier:RK1ShortWalkOutboundStepIdentifier];
    XCTAssertFalse(walkingStep.shouldSpeakRemainingTimeAtHalfway);
    
}

#pragma mark - two-finger tapping with both hands

- (void)testTwoFingerTappingIntervalTaskWithIdentifier_TapHandOptionUndefined {
    
    RK1OrderedTask *task = [RK1OrderedTask twoFingerTappingIntervalTaskWithIdentifier:@"test"
                                                               intendedUseDescription:nil
                                                                             duration:10
                                                                          handOptions:0
                                                                              options:0];
    NSArray *expectedStepIdentifiers = @[RK1Instruction0StepIdentifier,
                                              RK1Instruction1StepIdentifier,
                                              RK1TappingStepIdentifier,
                                              RK1ConclusionStepIdentifier];
    NSArray *stepIdentifiers = [task.steps valueForKey:@"identifier"];
    XCTAssertEqual(stepIdentifiers.count, expectedStepIdentifiers.count);
    XCTAssertEqualObjects(stepIdentifiers, expectedStepIdentifiers);
    
    RK1Step *tappingStep = [task stepWithIdentifier:RK1TappingStepIdentifier];
    XCTAssertFalse(tappingStep.optional);

}

- (void)testTwoFingerTappingIntervalTaskWithIdentifier_TapHandOptionLeft {
    
    RK1OrderedTask *task = [RK1OrderedTask twoFingerTappingIntervalTaskWithIdentifier:@"test"
                                                               intendedUseDescription:nil
                                                                             duration:10
                                                                          handOptions:RK1PredefinedTaskHandOptionLeft
                                                                              options:0];
    // Check assumption around how many steps
    XCTAssertEqual(task.steps.count, 4);
    
    // Check that none of the language or identifiers contain the word "right"
    for (RK1Step *step in task.steps) {
        XCTAssertFalse([step.identifier.lowercaseString hasSuffix:@"right"]);
        XCTAssertFalse([step.title.lowercaseString containsString:@"right"]);
        XCTAssertFalse([step.text.lowercaseString containsString:@"right"]);
    }
    
    NSArray * (^filteredSteps)(NSString*, NSString*) = ^(NSString *part1, NSString *part2) {
        NSString *keyValue = [NSString stringWithFormat:@"%@.%@", part1, part2];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", NSStringFromSelector(@selector(identifier)), keyValue];
        return [task.steps filteredArrayUsingPredicate:predicate];
    };
    
    // Look for instruction step
    NSArray *instructions = filteredSteps(@"instruction1", @"left");
    XCTAssertEqual(instructions.count, 1);
    RK1Step *instructionStep = [instructions firstObject];
    XCTAssertEqualObjects(instructionStep.title, @"Left Hand");
    XCTAssertEqualObjects(instructionStep.text, @"Put your phone on a flat surface. Use two fingers on your left hand to alternately tap the buttons on the screen. Tap one finger, then the other. Try to time your taps to be as even as possible. Keep tapping for 10 seconds.");
    
    // Look for the activity step
    NSArray *tappings = filteredSteps(@"tapping", @"left");
    XCTAssertEqual(tappings.count, 1);
    RK1Step *tappingStep = [tappings firstObject];
    XCTAssertEqualObjects(tappingStep.title, @"Tap the buttons using your LEFT hand.");
    XCTAssertFalse(tappingStep.optional);
    
}

- (void)testTwoFingerTappingIntervalTaskWithIdentifier_TapHandOptionRight {
    
    RK1OrderedTask *task = [RK1OrderedTask twoFingerTappingIntervalTaskWithIdentifier:@"test"
                                                               intendedUseDescription:nil
                                                                             duration:10
                                                                          handOptions:RK1PredefinedTaskHandOptionRight
                                                                              options:0];
    // Check assumption around how many steps
    XCTAssertEqual(task.steps.count, 4);
    
    // Check that none of the language or identifiers contain the word "right"
    for (RK1Step *step in task.steps) {
        XCTAssertFalse([step.identifier.lowercaseString hasSuffix:@"left"]);
        XCTAssertFalse([step.title.lowercaseString containsString:@"left"]);
        XCTAssertFalse([step.text.lowercaseString containsString:@"left"]);
    }
    
    NSArray * (^filteredSteps)(NSString*, NSString*) = ^(NSString *part1, NSString *part2) {
        NSString *keyValue = [NSString stringWithFormat:@"%@.%@", part1, part2];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", NSStringFromSelector(@selector(identifier)), keyValue];
        return [task.steps filteredArrayUsingPredicate:predicate];
    };
    
    // Look for instruction step
    NSArray *instructions = filteredSteps(@"instruction1", @"right");
    XCTAssertEqual(instructions.count, 1);
    RK1Step *instructionStep = [instructions firstObject];
    XCTAssertEqualObjects(instructionStep.title, @"Right Hand");
    XCTAssertEqualObjects(instructionStep.text, @"Put your phone on a flat surface. Use two fingers on your right hand to alternately tap the buttons on the screen. Tap one finger, then the other. Try to time your taps to be as even as possible. Keep tapping for 10 seconds.");
    
    // Look for the activity step
    NSArray *tappings = filteredSteps(@"tapping", @"right");
    XCTAssertEqual(tappings.count, 1);
    RK1Step *tappingStep = [tappings firstObject];
    XCTAssertEqualObjects(tappingStep.title, @"Tap the buttons using your RIGHT hand.");
    XCTAssertFalse(tappingStep.optional);
    
}

- (void)testTwoFingerTappingIntervalTaskWithIdentifier_TapHandOptionBoth {
    NSUInteger leftCount = 0;
    NSUInteger rightCount = 0;
    NSUInteger totalCount = 100;
    NSUInteger threshold = 30;
    
    for (int ii = 0; ii < totalCount; ii++) {
        RK1OrderedTask *task = [RK1OrderedTask twoFingerTappingIntervalTaskWithIdentifier:@"test"
                                                                   intendedUseDescription:nil
                                                                                 duration:10
                                                                              handOptions:RK1PredefinedTaskHandOptionBoth
                                                                                  options:0];
        RK1Step * (^filteredSteps)(NSString*, NSString*) = ^(NSString *part1, NSString *part2) {
            NSString *keyValue = [NSString stringWithFormat:@"%@.%@", part1, part2];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", NSStringFromSelector(@selector(identifier)), keyValue];
            return [[task.steps filteredArrayUsingPredicate:predicate] firstObject];
        };
        
        // Look for instruction steps
        RK1Step *rightInstructionStep = filteredSteps(@"instruction1", @"right");
        XCTAssertNotNil(rightInstructionStep);
        RK1Step *leftInstructionStep = filteredSteps(@"instruction1", @"left");
        XCTAssertNotNil(leftInstructionStep);
        
        // Depending upon the seed (clock time) this will be either the right or left hand
        // Without using OCMock, cannot easily verify that both will display.
        BOOL isRightFirst = [task.steps indexOfObject:rightInstructionStep] < [task.steps indexOfObject:leftInstructionStep];
        if (isRightFirst) {
            rightCount++;
        } else {
            leftCount++;
        }
        
        if ((isRightFirst && rightCount == 1) || (!isRightFirst && leftCount == 1)) {
            
            // Look for instruction steps
            XCTAssertEqualObjects(rightInstructionStep.title, @"Right Hand");
            XCTAssertEqualObjects(leftInstructionStep.title, @"Left Hand");
            
            // Depending upon the seed (clock time) this will be either the right or left hand
            // Without using OCMock, cannot easily verify that both will display.
            if (isRightFirst) {
                XCTAssertEqualObjects(rightInstructionStep.text, @"Put your phone on a flat surface. Use two fingers on your right hand to alternately tap the buttons on the screen. Tap one finger, then the other. Try to time your taps to be as even as possible. Keep tapping for 10 seconds.");
                XCTAssertEqualObjects(leftInstructionStep.text, @"Put your phone on a flat surface. Now repeat the same test using your left hand. Tap one finger, then the other. Try to time your taps to be as even as possible. Keep tapping for 10 seconds.");
            } else {
                XCTAssertEqualObjects(leftInstructionStep.text, @"Put your phone on a flat surface. Use two fingers on your left hand to alternately tap the buttons on the screen. Tap one finger, then the other. Try to time your taps to be as even as possible. Keep tapping for 10 seconds.");
                XCTAssertEqualObjects(rightInstructionStep.text, @"Put your phone on a flat surface. Now repeat the same test using your right hand. Tap one finger, then the other. Try to time your taps to be as even as possible. Keep tapping for 10 seconds.");
            }
            
            // Look for tapping steps
            RK1Step *rightTapStep = filteredSteps(@"tapping", @"right");
            XCTAssertNotNil(rightTapStep);
            XCTAssertEqualObjects(rightTapStep.title, @"Tap the buttons using your RIGHT hand.");
            XCTAssertTrue(rightTapStep.optional);
            
            RK1Step *leftTapStep = filteredSteps(@"tapping", @"left");
            XCTAssertNotNil(leftTapStep);
            XCTAssertEqualObjects(leftTapStep.title, @"Tap the buttons using your LEFT hand.");
            XCTAssertTrue(leftTapStep.optional);
        }
    }
    
    XCTAssertGreaterThan(leftCount, threshold);
    XCTAssertGreaterThan(rightCount, threshold);
}


#pragma mark - Test Tremor Task navigation

- (void)testKeyValueStepModifier {
    
    // Setup the task
    RK1Step *boolStep = [RK1QuestionStep  questionStepWithIdentifier:@"question"
                                                               title:@"Yes or No"
                                                              answer:[RK1AnswerFormat booleanAnswerFormat]];
    
    RK1Step *nextStep = [[RK1InstructionStep alloc] initWithIdentifier:@"nextStep"];
    nextStep.title = @"Yes";

    RK1NavigableOrderedTask *task = [[RK1NavigableOrderedTask alloc] initWithIdentifier:NavigableOrderedTaskIdentifier
                                                                                  steps:@[boolStep, nextStep]];
    
    RK1ResultSelector *resultSelector = [RK1ResultSelector selectorWithStepIdentifier:@"question"
                                                                     resultIdentifier:@"question"];
    NSPredicate *predicate = [RK1ResultPredicate predicateForBooleanQuestionResultWithResultSelector:resultSelector
                                                                                      expectedAnswer:NO];
    RK1StepModifier *stepModifier = [[RK1KeyValueStepModifier alloc] initWithResultPredicate:predicate
                                                                               keyValueMap:@{ @"title" : @"No" }];
    
    [task setStepModifier:stepModifier forStepIdentifier:@"nextStep"];
    
    // -- Check the title if the answer is YES
    RK1BooleanQuestionResult *result = [[RK1BooleanQuestionResult alloc] initWithIdentifier:@"question"];
    result.booleanAnswer = @(YES);
    RK1StepResult *stepResult = [[RK1StepResult alloc] initWithStepIdentifier:@"question" results:@[result]];
    RK1TaskResult *taskResult = [[RK1TaskResult alloc] initWithIdentifier:NavigableOrderedTaskIdentifier];
    taskResult.results = @[stepResult];
    
    // For the case where the answer is YES, then the title should be "Yes" (unmodified)
    RK1Step *yesStep = [task stepAfterStep:boolStep withResult:taskResult];
    XCTAssertEqualObjects(yesStep.title, @"Yes");
    
    // -- Check the title if the answer is NO
    result.booleanAnswer = @(NO);
    stepResult = [[RK1StepResult alloc] initWithStepIdentifier:@"question" results:@[result]];
    taskResult.results = @[stepResult];
    
    // For the case where the answer is NO, then the title should be modified to be "No"
    RK1Step *noStep = [task stepAfterStep:boolStep withResult:taskResult];
    XCTAssertEqualObjects(noStep.title, @"No");
}


@end


@implementation MethodObject
@end

@implementation TestTaskViewControllerDelegate

- (instancetype)init
{
    self = [super init];
    if (self) {
        _methodCalled = [NSMutableArray new];
    }
    return self;
}

- (void)taskViewController:(RK1TaskViewController *)taskViewController didFinishWithReason:(RK1TaskViewControllerFinishReason)reason error:(NSError *)error {
    
    // Add results of method call
    MethodObject *obj = [[MethodObject alloc] init];
    obj.selectorName = NSStringFromSelector(@selector(taskViewController:didFinishWithReason:error:));
    obj.arguments = @[taskViewController ?: [NSNull null],
                      @(reason),
                      error ?: [NSNull null]];
    [self.methodCalled addObject:obj];
}

- (void)taskViewController:(RK1TaskViewController *)taskViewController stepViewControllerWillDisappear:(RK1StepViewController *)stepViewController navigationDirection:(RK1StepViewControllerNavigationDirection)direction {
    // Add results of method call
    MethodObject *obj = [[MethodObject alloc] init];
    obj.selectorName = NSStringFromSelector(@selector(taskViewController:stepViewControllerWillDisappear:navigationDirection:));
    obj.arguments = @[taskViewController ?: [NSNull null],
                      stepViewController ?: [NSNull null],
                      @(direction)];
    [self.methodCalled addObject:obj];
}

@end

@implementation MockTaskViewController

- (void)flipToNextPageFrom:(RK1StepViewController *)fromController {
    // Add results of method call
    MethodObject *obj = [[MethodObject alloc] init];
    obj.selectorName = NSStringFromSelector(@selector(flipToNextPageFrom:));
    obj.arguments = @[fromController ?: [NSNull null]];
    [self.methodCalled addObject:obj];
}

- (void)flipToPreviousPageFrom:(RK1StepViewController *)fromController {
    // Add results of method call
    MethodObject *obj = [[MethodObject alloc] init];
    obj.selectorName = NSStringFromSelector(@selector(flipToPreviousPageFrom:));
    obj.arguments = @[fromController ?: [NSNull null]];
    [self.methodCalled addObject:obj];
}

@end
