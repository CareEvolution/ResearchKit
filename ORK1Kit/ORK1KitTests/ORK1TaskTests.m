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
@import ORK1Kit.Private;


@interface ORK1TaskTests : XCTestCase

@end

@interface MethodObject : NSObject
@property (nonatomic) NSString *selectorName;
@property (nonatomic) NSArray *arguments;
@end

@interface TestTaskViewControllerDelegate : NSObject <ORK1TaskViewControllerDelegate>
@property (nonatomic) NSMutableArray <MethodObject *> *methodCalled;
@end

@interface MockTaskViewController : ORK1TaskViewController
@property (nonatomic) NSMutableArray <MethodObject *> *methodCalled;
@end


@implementation ORK1TaskTests {
    NSArray *_orderedTaskStepIdentifiers;
    NSArray *_orderedTaskSteps;
    ORK1OrderedTask *_orderedTask;
    
    NSArray *_navigableOrderedTaskStepIdentifiers;
    NSArray *_navigableOrderedTaskSteps;
    NSMutableDictionary *_stepNavigationRules;
    ORK1NavigableOrderedTask *_navigableOrderedTask;
}

ORK1DefineStringKey(HeadacheChoiceValue);
ORK1DefineStringKey(DizzinessChoiceValue);
ORK1DefineStringKey(NauseaChoiceValue);

ORK1DefineStringKey(SymptomStepIdentifier);
ORK1DefineStringKey(SeverityStepIdentifier);
ORK1DefineStringKey(BlankStepIdentifier);
ORK1DefineStringKey(SevereHeadacheStepIdentifier);
ORK1DefineStringKey(LightHeadacheStepIdentifier);
ORK1DefineStringKey(OtherSymptomStepIdentifier);
ORK1DefineStringKey(EndStepIdentifier);
ORK1DefineStringKey(BlankBStepIdentifier);

ORK1DefineStringKey(OrderedTaskIdentifier);
ORK1DefineStringKey(NavigableOrderedTaskIdentifier);

- (void)generateTaskSteps:(out NSArray **)outSteps stepIdentifiers:(out NSArray **)outStepIdentifiers {
    if (outSteps == NULL || outStepIdentifiers == NULL) {
        return;
    }
    
    NSMutableArray *stepIdentifiers = [NSMutableArray new];
    NSMutableArray *steps = [NSMutableArray new];
    
    ORK1AnswerFormat *answerFormat = nil;
    NSString *stepIdentifier = nil;
    ORK1Step *step = nil;
    
    NSArray *textChoices =
    @[
      [ORK1TextChoice choiceWithText:@"Headache" value:HeadacheChoiceValue],
      [ORK1TextChoice choiceWithText:@"Dizziness" value:DizzinessChoiceValue],
      [ORK1TextChoice choiceWithText:@"Nausea" value:NauseaChoiceValue]
      ];
    
    answerFormat = [ORK1AnswerFormat choiceAnswerFormatWithStyle:ORK1ChoiceAnswerStyleSingleChoice
                                                    textChoices:textChoices];
    stepIdentifier = SymptomStepIdentifier;
    step = [ORK1QuestionStep questionStepWithIdentifier:stepIdentifier title:@"What is your symptom?" answer:answerFormat];
    step.optional = NO;
    [stepIdentifiers addObject:stepIdentifier];
    [steps addObject:step];
    
    answerFormat = [ORK1AnswerFormat booleanAnswerFormat];
    stepIdentifier = SeverityStepIdentifier;
    step = [ORK1QuestionStep questionStepWithIdentifier:stepIdentifier title:@"Does your symptom interferes with your daily life?" answer:answerFormat];
    step.optional = NO;
    [stepIdentifiers addObject:stepIdentifier];
    [steps addObject:step];
    
    stepIdentifier = BlankStepIdentifier;
    step = [[ORK1InstructionStep alloc] initWithIdentifier:stepIdentifier];
    step.title = @"This step is intentionally left blank (you should not see it)";
    [stepIdentifiers addObject:stepIdentifier];
    [steps addObject:step];
    
    stepIdentifier = SevereHeadacheStepIdentifier;
    step = [[ORK1InstructionStep alloc] initWithIdentifier:stepIdentifier];
    step.title = @"You have a severe headache";
    [stepIdentifiers addObject:stepIdentifier];
    [steps addObject:step];
    
    stepIdentifier = LightHeadacheStepIdentifier;
    step = [[ORK1InstructionStep alloc] initWithIdentifier:stepIdentifier];
    step.title = @"You have a light headache";
    [stepIdentifiers addObject:stepIdentifier];
    [steps addObject:step];
    
    stepIdentifier = OtherSymptomStepIdentifier;
    step = [[ORK1InstructionStep alloc] initWithIdentifier:stepIdentifier];
    step.title = @"You have other symptom";
    [stepIdentifiers addObject:stepIdentifier];
    [steps addObject:step];
    
    stepIdentifier = EndStepIdentifier;
    step = [[ORK1InstructionStep alloc] initWithIdentifier:stepIdentifier];
    step.title = @"You have finished the task";
    [stepIdentifiers addObject:stepIdentifier];
    [steps addObject:step];
    
    stepIdentifier = BlankBStepIdentifier;
    step = [[ORK1InstructionStep alloc] initWithIdentifier:stepIdentifier];
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
    
    _orderedTask = [[ORK1OrderedTask alloc] initWithIdentifier:OrderedTaskIdentifier
                                                        steps:ORK1ArrayCopyObjects(_orderedTaskSteps)]; // deep copy to test step copying and equality
}

- (void)setUpNavigableOrderedTask {
    ORK1ResultSelector *resultSelector = nil;
    NSArray *navigableOrderedTaskSteps = nil;
    NSArray *navigableOrderedTaskStepIdentifiers = nil;
    [self generateTaskSteps:&navigableOrderedTaskSteps stepIdentifiers:&navigableOrderedTaskStepIdentifiers];
    _navigableOrderedTaskSteps = navigableOrderedTaskSteps;
    _navigableOrderedTaskStepIdentifiers = navigableOrderedTaskStepIdentifiers;
    
    _navigableOrderedTask = [[ORK1NavigableOrderedTask alloc] initWithIdentifier:NavigableOrderedTaskIdentifier
                                                                          steps:ORK1ArrayCopyObjects(_navigableOrderedTaskSteps)]; // deep copy to test step copying and equality
    
    // Build navigation rules
    _stepNavigationRules = [NSMutableDictionary new];
    // Individual predicates
    
    // User chose headache at the symptom step
    resultSelector = [[ORK1ResultSelector alloc] initWithResultIdentifier:SymptomStepIdentifier];
    NSPredicate *predicateHeadache = [ORK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                                        expectedAnswerValue:HeadacheChoiceValue];
    // Equivalent to:
    //      [NSPredicate predicateWithFormat:
    //          @"SUBQUERY(SELF, $x, $x.identifier like 'symptom' \
    //                     AND SUBQUERY($x.answer, $y, $y like 'headache').@count > 0).@count > 0"];
    
    // User didn't chose headache at the symptom step
    NSPredicate *predicateNotHeadache = [NSCompoundPredicate notPredicateWithSubpredicate:predicateHeadache];
    
    // User chose YES at the severity step
    resultSelector = [[ORK1ResultSelector alloc] initWithResultIdentifier:SeverityStepIdentifier];
    NSPredicate *predicateSevereYes = [ORK1ResultPredicate predicateForBooleanQuestionResultWithResultSelector:resultSelector
                                                                                               expectedAnswer:YES];
    // Equivalent to:
    //      [NSPredicate predicateWithFormat:
    //          @"SUBQUERY(SELF, $x, $x.identifier like 'severity' AND $x.answer == YES).@count > 0"];
    
    // User chose NO at the severity step
    NSPredicate *predicateSevereNo = [ORK1ResultPredicate predicateForBooleanQuestionResultWithResultSelector:resultSelector
                                                                                              expectedAnswer:NO];
    
    
    // From the "symptom" step, go to "other_symptom" is user didn't chose headache.
    // Otherwise, default to going to next step (when the defaultStepIdentifier argument is omitted,
    // the regular ORK1OrderedTask order applies).
    NSMutableArray *resultPredicates = [NSMutableArray new];
    NSMutableArray *destinationStepIdentifiers = [NSMutableArray new];
    
    [resultPredicates addObject:predicateNotHeadache];
    [destinationStepIdentifiers addObject:OtherSymptomStepIdentifier];
    
    ORK1PredicateStepNavigationRule *predicateRule =
    [[ORK1PredicateStepNavigationRule alloc] initWithResultPredicates:resultPredicates
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
    [[ORK1PredicateStepNavigationRule alloc] initWithResultPredicates:resultPredicates
                                          destinationStepIdentifiers:destinationStepIdentifiers
                                               defaultStepIdentifier:OtherSymptomStepIdentifier];
    
    [_navigableOrderedTask setNavigationRule:predicateRule forTriggerStepIdentifier:SeverityStepIdentifier];
    _stepNavigationRules[SeverityStepIdentifier] = [predicateRule copy];
    
    
    // Add end direct rules to skip unneeded steps
    ORK1DirectStepNavigationRule *directRule = nil;
    
    directRule = [[ORK1DirectStepNavigationRule alloc] initWithDestinationStepIdentifier:EndStepIdentifier];
    
    [_navigableOrderedTask setNavigationRule:directRule forTriggerStepIdentifier:SevereHeadacheStepIdentifier];
    [_navigableOrderedTask setNavigationRule:directRule forTriggerStepIdentifier:LightHeadacheStepIdentifier];
    [_navigableOrderedTask setNavigationRule:directRule forTriggerStepIdentifier:OtherSymptomStepIdentifier];
    
    _stepNavigationRules[SevereHeadacheStepIdentifier] = [directRule copy];
    _stepNavigationRules[LightHeadacheStepIdentifier] = [directRule copy];
    _stepNavigationRules[OtherSymptomStepIdentifier] = [directRule copy];
    
    directRule = [[ORK1DirectStepNavigationRule alloc] initWithDestinationStepIdentifier:ORK1NullStepIdentifier];
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

- (ORK1TaskResult *)getResultTreeWithTaskIdentifier:(NSString *)taskIdentifier resultOptions:(TestsTaskResultOptions)resultOptions {
    if ( ((resultOptions & TestsTaskResultOptionSymptomDizziness) || (resultOptions & TestsTaskResultOptionSymptomNausea)) && ((resultOptions & TestsTaskResultOptionSeverityYes) || (resultOptions & TestsTaskResultOptionSeverityNo)) ) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"You can only add a severity result for the headache symptom" userInfo:nil];
    }
    
    NSMutableArray *stepResults = [NSMutableArray new];
    
    ORK1QuestionResult *questionResult = nil;
    ORK1StepResult *stepResult = nil;
    NSString *stepIdentifier = nil;
    
    if (resultOptions & (TestsTaskResultOptionSymptomHeadache | TestsTaskResultOptionSymptomDizziness | TestsTaskResultOptionSymptomNausea)) {
        stepIdentifier = SymptomStepIdentifier;
        questionResult = [[ORK1ChoiceQuestionResult alloc] init];
        questionResult.identifier = stepIdentifier;
        if (resultOptions & TestsTaskResultOptionSymptomHeadache) {
            questionResult.answer = @[HeadacheChoiceValue];
        } else if (resultOptions & TestsTaskResultOptionSymptomDizziness) {
            questionResult.answer = @[DizzinessChoiceValue];
        } else if (resultOptions & TestsTaskResultOptionSymptomNausea) {
            questionResult.answer = @[NauseaChoiceValue];
        }
        questionResult.questionType = ORK1QuestionTypeSingleChoice;
        
        stepResult = [[ORK1StepResult alloc] initWithStepIdentifier:stepIdentifier results:@[questionResult]];
        [stepResults addObject:stepResult];

        if (resultOptions & (TestsTaskResultOptionSymptomDizziness | TestsTaskResultOptionSymptomNausea)) {
            stepResult = [[ORK1StepResult alloc] initWithStepIdentifier:OtherSymptomStepIdentifier results:nil];
            [stepResults addObject:stepResult];
        }
    }
    
    if (resultOptions & (TestsTaskResultOptionSeverityYes | TestsTaskResultOptionSeverityNo)) {
        stepIdentifier = SeverityStepIdentifier;
        questionResult = [[ORK1BooleanQuestionResult alloc] init];
        questionResult.identifier = stepIdentifier;
        if (resultOptions & TestsTaskResultOptionSeverityYes) {
            questionResult.answer = @(YES);
        } else if (resultOptions & TestsTaskResultOptionSeverityNo) {
            questionResult.answer = @(NO);
        }
        questionResult.questionType = ORK1QuestionTypeSingleChoice;
        
        stepResult = [[ORK1StepResult alloc] initWithStepIdentifier:stepIdentifier results:@[questionResult]];
        [stepResults addObject:stepResult];
        
        
        if (resultOptions & TestsTaskResultOptionSeverityYes) {
            stepResult = [[ORK1StepResult alloc] initWithStepIdentifier:SevereHeadacheStepIdentifier results:nil];
            [stepResults addObject:stepResult];
        } else if (resultOptions & TestsTaskResultOptionSeverityNo) {
            stepResult = [[ORK1StepResult alloc] initWithStepIdentifier:LightHeadacheStepIdentifier results:nil];
            [stepResults addObject:stepResult];
        }
    }
    
    stepResult = [[ORK1StepResult alloc] initWithStepIdentifier:EndStepIdentifier results:nil];
    [stepResults addObject:stepResult];

    ORK1TaskResult *taskResult = [[ORK1TaskResult alloc] initWithTaskIdentifier:taskIdentifier
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
    ORK1TaskResult *mockTaskResult = [[ORK1TaskResult alloc] init];
    
    XCTAssertEqualObjects(_orderedTask.identifier, OrderedTaskIdentifier);
    XCTAssertEqualObjects(_orderedTask.steps, _orderedTaskSteps);
    
    NSUInteger expectedTotalProgress = _orderedTaskSteps.count;
    
    for (NSUInteger stepIndex = 0; stepIndex < _orderedTaskStepIdentifiers.count; stepIndex++) {
        ORK1Step *currentStep = _orderedTaskSteps[stepIndex];
        XCTAssertEqualObjects(currentStep, [_orderedTask stepWithIdentifier:_orderedTaskStepIdentifiers[stepIndex]]);
        
        const NSUInteger expectedCurrentProgress = stepIndex;
        ORK1TaskProgress currentProgress = [_orderedTask progressOfCurrentStep:currentStep withResult:mockTaskResult];
        XCTAssertTrue(currentProgress.total == expectedTotalProgress && currentProgress.current == expectedCurrentProgress);
        
        NSString *expectedPreviousStep = (stepIndex != 0) ? _orderedTaskSteps[stepIndex - 1] : nil;
        NSString *expectedNextStep = (stepIndex < _orderedTaskStepIdentifiers.count - 1) ? _orderedTaskSteps[stepIndex + 1] : nil;
        XCTAssertEqualObjects(expectedPreviousStep, [_orderedTask stepBeforeStep:currentStep withResult:mockTaskResult]);
        XCTAssertEqualObjects(expectedNextStep, [_orderedTask stepAfterStep:currentStep withResult:mockTaskResult]);
    }
    
    // Test duplicate step identifier validation
    XCTAssertNoThrow([_orderedTask validateParameters]);
    
    NSMutableArray *steps = [[NSMutableArray alloc] initWithArray:ORK1ArrayCopyObjects(_orderedTaskSteps)];
    ORK1Step *step = [[ORK1InstructionStep alloc] initWithIdentifier:BlankStepIdentifier];
    [steps addObject:step];
    
    XCTAssertThrows([[ORK1OrderedTask alloc] initWithIdentifier:OrderedTaskIdentifier
                                                         steps:steps]);
}

#define getIndividualNavigableOrderedTaskSteps() \
__unused ORK1Step *symptomStep = _navigableOrderedTaskSteps[0];\
__unused ORK1Step *severityStep = _navigableOrderedTaskSteps[1];\
__unused ORK1Step *blankStep = _navigableOrderedTaskSteps[2];\
__unused ORK1Step *severeHeadacheStep = _navigableOrderedTaskSteps[3];\
__unused ORK1Step *lightHeadacheStep = _navigableOrderedTaskSteps[4];\
__unused ORK1Step *otherSymptomStep = _navigableOrderedTaskSteps[5];\
__unused ORK1Step *endStep = _navigableOrderedTaskSteps[6];

BOOL (^testStepAfterStep)(ORK1NavigableOrderedTask *, ORK1TaskResult *, ORK1Step *, ORK1Step *) =  ^BOOL(ORK1NavigableOrderedTask *task, ORK1TaskResult *taskResult, ORK1Step *fromStep, ORK1Step *expectedStep) {
    ORK1Step *testedStep = [task stepAfterStep:fromStep withResult:taskResult];
    return (testedStep == nil && expectedStep == nil) || [testedStep isEqual:expectedStep];
};

BOOL (^testStepBeforeStep)(ORK1NavigableOrderedTask *, ORK1TaskResult *, ORK1Step *, ORK1Step *) =  ^BOOL(ORK1NavigableOrderedTask *task, ORK1TaskResult *taskResult, ORK1Step *fromStep, ORK1Step *expectedStep) {
    ORK1Step *testedStep = [task stepBeforeStep:fromStep withResult:taskResult];
    return (testedStep == nil && expectedStep == nil) || [testedStep isEqual:expectedStep];
};

- (void)testNavigableOrderedTask {
    XCTAssertEqualObjects(_navigableOrderedTask.identifier, NavigableOrderedTaskIdentifier);
    XCTAssertEqualObjects(_navigableOrderedTask.steps, _navigableOrderedTaskSteps);
    XCTAssertEqualObjects(_navigableOrderedTask.stepNavigationRules, _stepNavigationRules);
    
    for (NSString *triggerStepIdentifier in [_stepNavigationRules allKeys]) {
        XCTAssertEqualObjects(_stepNavigationRules[triggerStepIdentifier], [_navigableOrderedTask navigationRuleForTriggerStepIdentifier:triggerStepIdentifier]);
    }
    
    ORK1DefineStringKey(MockTriggerStepIdentifier);
    ORK1DefineStringKey(MockDestinationStepIdentifier);
    
    // Test adding and removing a step navigation rule
    XCTAssertNil([_navigableOrderedTask navigationRuleForTriggerStepIdentifier:MockTriggerStepIdentifier]);
    
    ORK1DirectStepNavigationRule *mockNavigationRule = [[ORK1DirectStepNavigationRule alloc] initWithDestinationStepIdentifier:MockDestinationStepIdentifier];
    [_navigableOrderedTask setNavigationRule:mockNavigationRule forTriggerStepIdentifier:MockTriggerStepIdentifier];

    XCTAssertEqualObjects([_navigableOrderedTask navigationRuleForTriggerStepIdentifier:MockTriggerStepIdentifier], [mockNavigationRule copy]);

    ORK1PredicateSkipStepNavigationRule *mockSkipNavigationRule = [[ORK1PredicateSkipStepNavigationRule alloc] initWithResultPredicate:[NSPredicate predicateWithFormat:@"1 == 1"]];
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
    ORK1TaskResult *taskResult = [self getResultTreeWithTaskIdentifier:NavigableOrderedTaskIdentifier resultOptions:0];
    
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
    ORK1TaskResult *taskResult = [self getResultTreeWithTaskIdentifier:NavigableOrderedTaskIdentifier resultOptions:TestsTaskResultOptionSymptomHeadache | TestsTaskResultOptionSeverityYes];
    
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
    ORK1TaskResult *taskResult = [self getResultTreeWithTaskIdentifier:NavigableOrderedTaskIdentifier resultOptions:TestsTaskResultOptionSymptomDizziness];
    
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
    ORK1TaskResult *taskResult = [self getResultTreeWithTaskIdentifier:NavigableOrderedTaskIdentifier resultOptions:TestsTaskResultOptionSymptomHeadache | TestsTaskResultOptionSeverityYes];
    
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
    ORK1TaskResult *taskResult = [self getResultTreeWithTaskIdentifier:NavigableOrderedTaskIdentifier resultOptions:TestsTaskResultOptionSymptomHeadache | TestsTaskResultOptionSeverityNo];
    
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
    ORK1NavigableOrderedTask *skipTask = [_navigableOrderedTask copy];

    getIndividualNavigableOrderedTaskSteps();

    //
    // Light headache sequence
    //
    ORK1TaskResult *taskResult = [self getResultTreeWithTaskIdentifier:NavigableOrderedTaskIdentifier resultOptions:TestsTaskResultOptionSymptomHeadache | TestsTaskResultOptionSeverityNo];

    // User chose headache at the symptom step
    ORK1ResultSelector *resultSelector = [[ORK1ResultSelector alloc] initWithResultIdentifier:SymptomStepIdentifier];
    NSPredicate *predicateHeadache = [ORK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                                        expectedAnswerValue:HeadacheChoiceValue];
    ORK1PredicateSkipStepNavigationRule *skipRule = [[ORK1PredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicateHeadache];
    
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

ORK1DefineStringKey(SignConsentStepIdentifier);
ORK1DefineStringKey(SignatureIdentifier);

ORK1DefineStringKey(ScaleStepIdentifier);
ORK1DefineStringKey(ContinuousScaleStepIdentifier);
static const NSInteger IntegerValue = 6;
static const float FloatValue = 6.5;

ORK1DefineStringKey(SingleChoiceStepIdentifier);
ORK1DefineStringKey(MultipleChoiceStepIdentifier);
ORK1DefineStringKey(MixedMultipleChoiceStepIdentifier);
ORK1DefineStringKey(SingleChoiceValue);
ORK1DefineStringKey(MultipleChoiceValue1);
ORK1DefineStringKey(MultipleChoiceValue2);
static const NSInteger MultipleChoiceValue3 = 7;

ORK1DefineStringKey(BooleanStepIdentifier);
static const BOOL BooleanValue = YES;

ORK1DefineStringKey(TextStepIdentifier);
ORK1DefineStringKey(TextValue);
ORK1DefineStringKey(OtherTextValue);

ORK1DefineStringKey(IntegerNumericStepIdentifier);
ORK1DefineStringKey(FloatNumericStepIdentifier);

ORK1DefineStringKey(TimeOfDayStepIdentifier);
ORK1DefineStringKey(TimeIntervalStepIdentifier);
ORK1DefineStringKey(DateStepIdentifier);

ORK1DefineStringKey(FormStepIdentifier);

ORK1DefineStringKey(TextFormItemIdentifier);
ORK1DefineStringKey(NumericFormItemIdentifier);

ORK1DefineStringKey(NilTextStepIdentifier);

ORK1DefineStringKey(AdditionalTaskIdentifier);
ORK1DefineStringKey(AdditionalFormStepIdentifier);
ORK1DefineStringKey(AdditionalTextFormItemIdentifier);
ORK1DefineStringKey(AdditionalNumericFormItemIdentifier);

ORK1DefineStringKey(AdditionalTextStepIdentifier);
ORK1DefineStringKey(AdditionalTextValue);

ORK1DefineStringKey(MatchedDestinationStepIdentifier);
ORK1DefineStringKey(DefaultDestinationStepIdentifier);

static const NSInteger AdditionalIntegerValue = 42;

static NSDate *(^Date)(void) = ^NSDate *{ return [NSDate dateWithTimeIntervalSince1970:60*60*24]; };
static NSDateComponents *(^DateComponents)(void) = ^NSDateComponents *{
    NSDateComponents *dateComponents = [NSDateComponents new];
    dateComponents.hour = 6;
    dateComponents.minute = 6;
    return dateComponents;
};

static ORK1QuestionResult *(^getQuestionResult)(NSString *, Class, ORK1QuestionType, id) = ^ORK1QuestionResult *(NSString *questionResultIdentifier, Class questionResultClass, ORK1QuestionType questionType, id answer) {
    ORK1QuestionResult *questionResult = [[questionResultClass alloc] init];
    questionResult.identifier = questionResultIdentifier;
    questionResult.answer = answer;
    questionResult.questionType = questionType;
    return questionResult;
};

static ORK1StepResult *(^getStepResult)(NSString *, Class, ORK1QuestionType, id) = ^ORK1StepResult *(NSString *stepIdentifier, Class questionResultClass, ORK1QuestionType questionType, id answer) {
    ORK1QuestionResult *questionResult = getQuestionResult(stepIdentifier, questionResultClass, questionType, answer);
    ORK1StepResult *stepResult = [[ORK1StepResult alloc] initWithStepIdentifier:stepIdentifier results:@[questionResult]];
    return stepResult;
};

static ORK1StepResult *(^getConsentStepResult)(NSString *, NSString *, BOOL) = ^ORK1StepResult *(NSString *stepIdentifier, NSString *signatureIdentifier, BOOL consented) {
    ORK1ConsentSignatureResult *consentSignatureResult = [[ORK1ConsentSignatureResult alloc] initWithIdentifier:signatureIdentifier];
    consentSignatureResult.consented = consented;
    return [[ORK1StepResult alloc] initWithStepIdentifier:stepIdentifier results:@[consentSignatureResult]];
};

- (ORK1TaskResult *)getGeneralTaskResultTree {
    NSMutableArray *stepResults = [NSMutableArray new];
    
    [stepResults addObject:getStepResult(ScaleStepIdentifier, [ORK1ScaleQuestionResult class], ORK1QuestionTypeScale, @(IntegerValue))];
    [stepResults addObject:getStepResult(ContinuousScaleStepIdentifier, [ORK1ScaleQuestionResult class], ORK1QuestionTypeScale, @(FloatValue))];
    
    [stepResults addObject:getStepResult(SingleChoiceStepIdentifier, [ORK1ChoiceQuestionResult class], ORK1QuestionTypeSingleChoice, @[SingleChoiceValue])];
    [stepResults addObject:getStepResult(MultipleChoiceStepIdentifier, [ORK1ChoiceQuestionResult class], ORK1QuestionTypeMultipleChoice, @[MultipleChoiceValue1, MultipleChoiceValue2])];
    [stepResults addObject:getStepResult(MixedMultipleChoiceStepIdentifier, [ORK1ChoiceQuestionResult class], ORK1QuestionTypeMultipleChoice, @[MultipleChoiceValue1, MultipleChoiceValue2, @(MultipleChoiceValue3)])];
    
    [stepResults addObject:getStepResult(BooleanStepIdentifier, [ORK1BooleanQuestionResult class], ORK1QuestionTypeBoolean, @(BooleanValue))];
    
    [stepResults addObject:getStepResult(TextStepIdentifier, [ORK1TextQuestionResult class], ORK1QuestionTypeText, TextValue)];
    
    [stepResults addObject:getStepResult(IntegerNumericStepIdentifier, [ORK1NumericQuestionResult class], ORK1QuestionTypeInteger, @(IntegerValue))];
    [stepResults addObject:getStepResult(FloatNumericStepIdentifier, [ORK1NumericQuestionResult class], ORK1QuestionTypeDecimal, @(FloatValue))];
    
    [stepResults addObject:getStepResult(DateStepIdentifier, [ORK1DateQuestionResult class], ORK1QuestionTypeDate, Date())];
    
    [stepResults addObject:getStepResult(TimeIntervalStepIdentifier, [ORK1TimeIntervalQuestionResult class], ORK1QuestionTypeTimeInterval, @(IntegerValue))];
    
    [stepResults addObject:getStepResult(TimeOfDayStepIdentifier, [ORK1TimeOfDayQuestionResult class], ORK1QuestionTypeTimeOfDay, DateComponents())];
    
    // Nil result (simulate skipped step)
    [stepResults addObject:getStepResult(NilTextStepIdentifier, [ORK1TextQuestionResult class], ORK1QuestionTypeText, nil)];
    
    ORK1TaskResult *taskResult = [[ORK1TaskResult alloc] initWithTaskIdentifier:OrderedTaskIdentifier
                                                                  taskRunUUID:[NSUUID UUID]
                                                              outputDirectory:[NSURL fileURLWithPath:NSTemporaryDirectory()]];
    taskResult.results = stepResults;
    
    return taskResult;
}

- (ORK1TaskResult *)getTaskResultTreeWithConsent:(BOOL)consented {
    NSMutableArray *stepResults = [NSMutableArray new];
    
    [stepResults addObject:getConsentStepResult(SignConsentStepIdentifier, SignatureIdentifier, consented)];
    
    ORK1TaskResult *taskResult = [[ORK1TaskResult alloc] initWithTaskIdentifier:OrderedTaskIdentifier
                                                                  taskRunUUID:[NSUUID UUID]
                                                              outputDirectory:[NSURL fileURLWithPath:NSTemporaryDirectory()]];
    taskResult.results = stepResults;
    
    return taskResult;
}

- (ORK1TaskResult *)getSmallTaskResultTreeWithIsAdditionalTask:(BOOL)isAdditionalTask {
    NSMutableArray *stepResults = [NSMutableArray new];
    
    if (!isAdditionalTask) {
        [stepResults addObject:getStepResult(TextStepIdentifier, [ORK1TextQuestionResult class], ORK1QuestionTypeText, TextValue)];
    } else {
        [stepResults addObject:getStepResult(AdditionalTextStepIdentifier, [ORK1TextQuestionResult class], ORK1QuestionTypeText, AdditionalTextValue)];
    }
    
    ORK1TaskResult *taskResult = [[ORK1TaskResult alloc] initWithTaskIdentifier:!isAdditionalTask ? OrderedTaskIdentifier : AdditionalTaskIdentifier
                                                                  taskRunUUID:[NSUUID UUID]
                                                              outputDirectory:[NSURL fileURLWithPath:NSTemporaryDirectory()]];
    taskResult.results = stepResults;
    
    return taskResult;
}

- (ORK1TaskResult *)getSmallFormTaskResultTreeWithIsAdditionalTask:(BOOL)isAdditionalTask {
    NSMutableArray *formItemResults = [NSMutableArray new];
    
    if (!isAdditionalTask) {
        [formItemResults addObject:getQuestionResult(TextFormItemIdentifier, [ORK1TextQuestionResult class], ORK1QuestionTypeText, TextValue)];
        [formItemResults addObject:getQuestionResult(NumericFormItemIdentifier, [ORK1NumericQuestionResult class], ORK1QuestionTypeInteger, @(IntegerValue))];
    } else {
        [formItemResults addObject:getQuestionResult(AdditionalTextFormItemIdentifier, [ORK1TextQuestionResult class], ORK1QuestionTypeText, AdditionalTextValue)];
        [formItemResults addObject:getQuestionResult(AdditionalNumericFormItemIdentifier, [ORK1NumericQuestionResult class], ORK1QuestionTypeInteger, @(AdditionalIntegerValue))];
    }
    
    ORK1StepResult *formStepResult = [[ORK1StepResult alloc] initWithStepIdentifier:(!isAdditionalTask ? FormStepIdentifier : AdditionalFormStepIdentifier) results:formItemResults];
    
    ORK1TaskResult *taskResult = [[ORK1TaskResult alloc] initWithTaskIdentifier:(!isAdditionalTask ? OrderedTaskIdentifier : AdditionalTaskIdentifier)
                                                                  taskRunUUID:[NSUUID UUID]
                                                              outputDirectory:[NSURL fileURLWithPath:NSTemporaryDirectory()]];
    taskResult.results = @[formStepResult];
    
    return taskResult;
}

- (ORK1TaskResult *)getSmallTaskResultTreeWithDuplicateStepIdentifiers {
    NSMutableArray *stepResults = [NSMutableArray new];
    
    [stepResults addObject:getStepResult(TextStepIdentifier, [ORK1TextQuestionResult class], ORK1QuestionTypeText, TextValue)];
    [stepResults addObject:getStepResult(TextStepIdentifier, [ORK1TextQuestionResult class], ORK1QuestionTypeText, TextValue)];
    
    ORK1TaskResult *taskResult = [[ORK1TaskResult alloc] initWithTaskIdentifier:OrderedTaskIdentifier
                                                                  taskRunUUID:[NSUUID UUID]
                                                              outputDirectory:[NSURL fileURLWithPath:NSTemporaryDirectory()]];
    taskResult.results = stepResults;
    
    return taskResult;
}

- (void)testPredicateStepNavigationRule {
    NSPredicate *predicate = nil;
    NSPredicate *predicateA = nil;
    NSPredicate *predicateB = nil;
    ORK1PredicateStepNavigationRule *predicateRule = nil;
    ORK1TaskResult *taskResult = nil;
    ORK1TaskResult *additionalTaskResult = nil;
    
    NSArray *resultPredicates = nil;
    NSArray *destinationStepIdentifiers = nil;
    NSString *defaultStepIdentifier = nil;
    
    ORK1ResultSelector *resultSelector = nil;
    
    {
        // Test predicate step navigation rule initializers
        resultSelector = [[ORK1ResultSelector alloc] initWithResultIdentifier:TextStepIdentifier];
        predicate = [ORK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:TextValue];
        resultPredicates = @[ predicate ];
        destinationStepIdentifiers = @[ MatchedDestinationStepIdentifier ];
        predicateRule = [[ORK1PredicateStepNavigationRule alloc] initWithResultPredicates:resultPredicates
                                                              destinationStepIdentifiers:destinationStepIdentifiers];
        
        XCTAssertEqualObjects(predicateRule.resultPredicates, ORK1ArrayCopyObjects(resultPredicates));
        XCTAssertEqualObjects(predicateRule.destinationStepIdentifiers, ORK1ArrayCopyObjects(destinationStepIdentifiers));
        XCTAssertNil(predicateRule.defaultStepIdentifier);
        
        defaultStepIdentifier = DefaultDestinationStepIdentifier;
        predicateRule = [[ORK1PredicateStepNavigationRule alloc] initWithResultPredicates:resultPredicates
                                                              destinationStepIdentifiers:destinationStepIdentifiers
                                                                   defaultStepIdentifier:defaultStepIdentifier];
        
        XCTAssertEqualObjects(predicateRule.resultPredicates, ORK1ArrayCopyObjects(resultPredicates));
        XCTAssertEqualObjects(predicateRule.destinationStepIdentifiers, ORK1ArrayCopyObjects(destinationStepIdentifiers));
        XCTAssertEqualObjects(predicateRule.defaultStepIdentifier, defaultStepIdentifier);
    }
    
    {
        // Predicate matching, no additional task results, matching
        taskResult = [ORK1TaskResult new];
        taskResult.identifier = OrderedTaskIdentifier;
        
        resultSelector = [[ORK1ResultSelector alloc] initWithResultIdentifier:TextStepIdentifier];
        predicate = [ORK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:TextValue];
        predicateRule = [[ORK1PredicateStepNavigationRule alloc] initWithResultPredicates:@[ predicate ]
                                                              destinationStepIdentifiers:@[ MatchedDestinationStepIdentifier ]
                                                                   defaultStepIdentifier:DefaultDestinationStepIdentifier];
        
        XCTAssertEqualObjects([predicateRule identifierForDestinationStepWithTaskResult:taskResult], DefaultDestinationStepIdentifier);
        
        taskResult = [self getSmallTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertEqualObjects([predicateRule identifierForDestinationStepWithTaskResult:taskResult], MatchedDestinationStepIdentifier);
    }
    
    {
        // Predicate matching, no additional task results, non matching
        resultSelector = [[ORK1ResultSelector alloc] initWithResultIdentifier:TextStepIdentifier];
        predicate = [ORK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:OtherTextValue];
        predicateRule = [[ORK1PredicateStepNavigationRule alloc] initWithResultPredicates:@[ predicate ]
                                                              destinationStepIdentifiers:@[ MatchedDestinationStepIdentifier ]
                                                                   defaultStepIdentifier:DefaultDestinationStepIdentifier];
        taskResult = [self getSmallTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertEqualObjects([predicateRule identifierForDestinationStepWithTaskResult:taskResult], DefaultDestinationStepIdentifier);
    }
    
    {
        NSPredicate *currentPredicate = nil;
        NSPredicate *additionalPredicate = nil;
        
        // Predicate matching, additional task results
        resultSelector = [[ORK1ResultSelector alloc] initWithResultIdentifier:TextStepIdentifier];
        currentPredicate = [ORK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                                 expectedString:TextValue];
        
        resultSelector = [[ORK1ResultSelector alloc] initWithTaskIdentifier:AdditionalTaskIdentifier
                                                            resultIdentifier:AdditionalTextStepIdentifier];
        additionalPredicate = [ORK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                                    expectedString:AdditionalTextValue];
        
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[currentPredicate, additionalPredicate]];
        predicateRule = [[ORK1PredicateStepNavigationRule alloc] initWithResultPredicates:@[ predicate ]
                                                              destinationStepIdentifiers:@[ MatchedDestinationStepIdentifier ]
                                                                   defaultStepIdentifier:DefaultDestinationStepIdentifier];
        
        taskResult = [ORK1TaskResult new];
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
        resultSelector = [[ORK1ResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                            resultIdentifier:TextFormItemIdentifier];
        predicateA = [ORK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                           expectedString:TextValue];
        
        resultSelector = [[ORK1ResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                            resultIdentifier:NumericFormItemIdentifier];
        predicateB = [ORK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                              expectedAnswer:IntegerValue];
        
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateA, predicateB]];
        predicateRule = [[ORK1PredicateStepNavigationRule alloc] initWithResultPredicates:@[ predicate ]
                                                              destinationStepIdentifiers:@[ MatchedDestinationStepIdentifier ]
                                                                   defaultStepIdentifier:DefaultDestinationStepIdentifier];
        
        taskResult = [self getSmallFormTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertEqualObjects([predicateRule identifierForDestinationStepWithTaskResult:taskResult], MatchedDestinationStepIdentifier);
    }
    
    {
        // Form predicate matching, no additional task results, non matching
        resultSelector = [[ORK1ResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                            resultIdentifier:TextFormItemIdentifier];
        predicate = [ORK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:OtherTextValue];
        predicateRule = [[ORK1PredicateStepNavigationRule alloc] initWithResultPredicates:@[ predicate ]
                                                              destinationStepIdentifiers:@[ MatchedDestinationStepIdentifier ]
                                                                   defaultStepIdentifier:DefaultDestinationStepIdentifier];
        taskResult = [self getSmallFormTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertEqualObjects([predicateRule identifierForDestinationStepWithTaskResult:taskResult], DefaultDestinationStepIdentifier);
    }
    
    {
        NSPredicate *currentPredicate = nil;
        NSPredicate *additionalPredicate = nil;
        
        // Form predicate matching, additional task results
        resultSelector = [[ORK1ResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                            resultIdentifier:TextFormItemIdentifier];
        predicateA = [ORK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                           expectedString:TextValue];
        
        resultSelector = [[ORK1ResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                            resultIdentifier:NumericFormItemIdentifier];
        predicateB = [ORK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                              expectedAnswer:IntegerValue];
        
        currentPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateA, predicateB]];
        
        resultSelector = [[ORK1ResultSelector alloc] initWithTaskIdentifier:AdditionalTaskIdentifier
                                                              stepIdentifier:AdditionalFormStepIdentifier
                                                            resultIdentifier:AdditionalTextFormItemIdentifier];
        predicateA = [ORK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                           expectedString:AdditionalTextValue];
        
        resultSelector = [[ORK1ResultSelector alloc] initWithTaskIdentifier:AdditionalTaskIdentifier
                                                              stepIdentifier:AdditionalFormStepIdentifier
                                                            resultIdentifier:AdditionalNumericFormItemIdentifier];
        predicateB = [ORK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                              expectedAnswer:AdditionalIntegerValue];
        
        additionalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateA, predicateB]];
        
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[currentPredicate, additionalPredicate]];
        predicateRule = [[ORK1PredicateStepNavigationRule alloc] initWithResultPredicates:@[ predicate ]
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
    ORK1PredicateSkipStepNavigationRule *predicateRule = nil;
    ORK1TaskResult *taskResult = nil;
    ORK1TaskResult *additionalTaskResult = nil;
    
    ORK1ResultSelector *resultSelector = nil;
    
    {
        // Test predicate step navigation rule initializers
        resultSelector = [[ORK1ResultSelector alloc] initWithResultIdentifier:TextStepIdentifier];
        predicate = [ORK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:TextValue];
        predicateRule = [[ORK1PredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicate];
        XCTAssertEqualObjects(predicateRule.resultPredicate, predicate);
    }
    
    {
        // Predicate matching, no additional task results, matching
        taskResult = [ORK1TaskResult new];
        taskResult.identifier = OrderedTaskIdentifier;
        
        resultSelector = [[ORK1ResultSelector alloc] initWithResultIdentifier:TextStepIdentifier];
        predicate = [ORK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:TextValue];
        predicateRule = [[ORK1PredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicate];
        
        XCTAssertFalse([predicateRule stepShouldSkipWithTaskResult:taskResult]);
        
        taskResult = [self getSmallTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertTrue([predicateRule stepShouldSkipWithTaskResult:taskResult]);
    }
    
    {
        // Predicate matching, no additional task results, non matching
        resultSelector = [[ORK1ResultSelector alloc] initWithResultIdentifier:TextStepIdentifier];
        predicate = [ORK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:OtherTextValue];
        predicateRule = [[ORK1PredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicate];
        taskResult = [self getSmallTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertFalse([predicateRule stepShouldSkipWithTaskResult:taskResult]);
    }

    {
        NSPredicate *currentPredicate = nil;
        NSPredicate *additionalPredicate = nil;
        
        // Predicate matching, additional task results
        resultSelector = [[ORK1ResultSelector alloc] initWithResultIdentifier:TextStepIdentifier];
        currentPredicate = [ORK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                                 expectedString:TextValue];
        
        resultSelector = [[ORK1ResultSelector alloc] initWithTaskIdentifier:AdditionalTaskIdentifier
                                                          resultIdentifier:AdditionalTextStepIdentifier];
        additionalPredicate = [ORK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                                    expectedString:AdditionalTextValue];
        
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[currentPredicate, additionalPredicate]];
        predicateRule = [[ORK1PredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicate];
        
        taskResult = [ORK1TaskResult new];
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
        resultSelector = [[ORK1ResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                          resultIdentifier:TextFormItemIdentifier];
        predicateA = [ORK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                           expectedString:TextValue];
        
        resultSelector = [[ORK1ResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                          resultIdentifier:NumericFormItemIdentifier];
        predicateB = [ORK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                              expectedAnswer:IntegerValue];
        
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateA, predicateB]];
        predicateRule = [[ORK1PredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicate];
        
        taskResult = [self getSmallFormTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertTrue([predicateRule stepShouldSkipWithTaskResult:taskResult]);
    }

    {
        // Form predicate matching, no additional task results, non matching
        resultSelector = [[ORK1ResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                          resultIdentifier:TextFormItemIdentifier];
        predicate = [ORK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:OtherTextValue];
        predicateRule = [[ORK1PredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicate];
        
        taskResult = [self getSmallFormTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertFalse([predicateRule stepShouldSkipWithTaskResult:taskResult]);
    }
    
    {
        NSPredicate *currentPredicate = nil;
        NSPredicate *additionalPredicate = nil;
        
        // Form predicate matching, additional task results
        resultSelector = [[ORK1ResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                          resultIdentifier:TextFormItemIdentifier];
        predicateA = [ORK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                           expectedString:TextValue];
        
        resultSelector = [[ORK1ResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                          resultIdentifier:NumericFormItemIdentifier];
        predicateB = [ORK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                              expectedAnswer:IntegerValue];
        
        currentPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateA, predicateB]];
        
        resultSelector = [[ORK1ResultSelector alloc] initWithTaskIdentifier:AdditionalTaskIdentifier
                                                            stepIdentifier:AdditionalFormStepIdentifier
                                                          resultIdentifier:AdditionalTextFormItemIdentifier];
        predicateA = [ORK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                           expectedString:AdditionalTextValue];
        
        resultSelector = [[ORK1ResultSelector alloc] initWithTaskIdentifier:AdditionalTaskIdentifier
                                                            stepIdentifier:AdditionalFormStepIdentifier
                                                          resultIdentifier:AdditionalNumericFormItemIdentifier];
        predicateB = [ORK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                              expectedAnswer:AdditionalIntegerValue];
        
        additionalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateA, predicateB]];
        
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[currentPredicate, additionalPredicate]];
        predicateRule = [[ORK1PredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicate];
        
        taskResult = [self getSmallFormTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertFalse([predicateRule stepShouldSkipWithTaskResult:taskResult]);
        
        additionalTaskResult = [self getSmallFormTaskResultTreeWithIsAdditionalTask:YES];
        predicateRule.additionalTaskResults = @[ additionalTaskResult ];
        XCTAssertTrue([predicateRule stepShouldSkipWithTaskResult:taskResult]);
    }
}

- (void)testDirectStepNavigationRule {
    ORK1DirectStepNavigationRule *directRule = nil;
    ORK1TaskResult *mockTaskResult = [ORK1TaskResult new];
    
    directRule = [[ORK1DirectStepNavigationRule alloc] initWithDestinationStepIdentifier:MatchedDestinationStepIdentifier];
    XCTAssertEqualObjects(directRule.destinationStepIdentifier, [MatchedDestinationStepIdentifier copy] );
    XCTAssertEqualObjects([directRule identifierForDestinationStepWithTaskResult:mockTaskResult], [MatchedDestinationStepIdentifier copy]);
    
    directRule = [[ORK1DirectStepNavigationRule alloc] initWithDestinationStepIdentifier:ORK1NullStepIdentifier];
    XCTAssertEqualObjects(directRule.destinationStepIdentifier, [ORK1NullStepIdentifier copy]);
    XCTAssertEqualObjects([directRule identifierForDestinationStepWithTaskResult:mockTaskResult], [ORK1NullStepIdentifier copy]);
}

- (void)testResultPredicatesWithTaskIdentifier:(NSString *)taskIdentifier
                         substitutionVariables:(NSDictionary *)substitutionVariables
                                   taskResults:(NSArray *)taskResults {
    // ORK1ScaleQuestionResult
    ORK1ResultSelector *resultSelector = [[ORK1ResultSelector alloc] initWithTaskIdentifier:taskIdentifier
                                                                         resultIdentifier:@""];
    
    resultSelector.resultIdentifier = ScaleStepIdentifier;
    XCTAssertTrue([[ORK1ResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector
                                                                          expectedAnswer:IntegerValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORK1ResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector
                                                                           expectedAnswer:IntegerValue + 1] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    resultSelector.resultIdentifier = ContinuousScaleStepIdentifier;
    XCTAssertTrue([[ORK1ResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector
                                                              minimumExpectedAnswerValue:FloatValue - 0.01
                                                              maximumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORK1ResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector
                                                               minimumExpectedAnswerValue:FloatValue + 0.05
                                                               maximumExpectedAnswerValue:FloatValue + 0.06] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORK1ResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector
                                                              minimumExpectedAnswerValue:FloatValue - 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORK1ResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector
                                                               minimumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORK1ResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector
                                                              maximumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORK1ResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector
                                                               maximumExpectedAnswerValue:FloatValue - 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // ORK1ChoiceQuestionResult (strings)
    resultSelector.resultIdentifier = SingleChoiceStepIdentifier;
    XCTAssertTrue([[ORK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                      expectedAnswerValue:SingleChoiceValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                       expectedAnswerValue:OtherTextValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    resultSelector.resultIdentifier = MultipleChoiceStepIdentifier;
    NSArray *expectedAnswers = nil;
    expectedAnswers = @[MultipleChoiceValue1];
    XCTAssertTrue([[ORK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                     expectedAnswerValues:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    expectedAnswers = @[MultipleChoiceValue1, MultipleChoiceValue2];
    XCTAssertTrue([[ORK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                     expectedAnswerValues:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    expectedAnswers = @[MultipleChoiceValue1, MultipleChoiceValue2, OtherTextValue];
    XCTAssertFalse([[ORK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                      expectedAnswerValues:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    expectedAnswers = @[MultipleChoiceValue1, MultipleChoiceValue2, @(MultipleChoiceValue3)];
    XCTAssertFalse([[ORK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                      expectedAnswerValues:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    resultSelector.resultIdentifier = MixedMultipleChoiceStepIdentifier;
    expectedAnswers = @[MultipleChoiceValue1];
    XCTAssertTrue([[ORK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                     expectedAnswerValues:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    expectedAnswers = @[@(MultipleChoiceValue3)];
    XCTAssertTrue([[ORK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                     expectedAnswerValues:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    expectedAnswers = @[MultipleChoiceValue1, MultipleChoiceValue2, @(MultipleChoiceValue3)];
    XCTAssertTrue([[ORK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                     expectedAnswerValues:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    expectedAnswers = @[MultipleChoiceValue1, MultipleChoiceValue2, OtherTextValue];
    XCTAssertFalse([[ORK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                      expectedAnswerValues:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // ORK1ChoiceQuestionResult (regular expressions)
    resultSelector.resultIdentifier = SingleChoiceStepIdentifier;
    XCTAssertTrue([[ORK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                          matchingPattern:@"...gleChoiceValue"] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                       expectedAnswerValue:@"...SingleChoiceValue"] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    resultSelector.resultIdentifier = MultipleChoiceStepIdentifier;
    expectedAnswers = @[@"...tipleChoiceValue1", @"...tipleChoiceValue2"];
    XCTAssertTrue([[ORK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                         matchingPatterns:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    expectedAnswers = @[@"...MultipleChoiceValue1", @"...MultipleChoiceValue2", @"...OtherTextValue"];
    XCTAssertFalse([[ORK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                          matchingPatterns:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // ORK1BooleanQuestionResult
    resultSelector.resultIdentifier = BooleanStepIdentifier;
    XCTAssertTrue([[ORK1ResultPredicate predicateForBooleanQuestionResultWithResultSelector:resultSelector
                                                                            expectedAnswer:BooleanValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORK1ResultPredicate predicateForBooleanQuestionResultWithResultSelector:resultSelector
                                                                             expectedAnswer:!BooleanValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // ORK1TextQuestionResult (strings)
    resultSelector.resultIdentifier = TextStepIdentifier;
    XCTAssertTrue([[ORK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                         expectedString:TextValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:OtherTextValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // ORK1TextQuestionResult (regular expressions)
    XCTAssertTrue([[ORK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                        matchingPattern:@"...tValue"] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORK1ResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                         matchingPattern:@"...TextValue"] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // ORK1NumericQuestionResult
    resultSelector.resultIdentifier = IntegerNumericStepIdentifier;
    XCTAssertTrue([[ORK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                            expectedAnswer:IntegerValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertFalse([[ORK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                             expectedAnswer:IntegerValue + 1] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    resultSelector.resultIdentifier = FloatNumericStepIdentifier;
    XCTAssertTrue([[ORK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                minimumExpectedAnswerValue:ORK1IgnoreDoubleValue
                                                                maximumExpectedAnswerValue:ORK1IgnoreDoubleValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                minimumExpectedAnswerValue:FloatValue - 0.01
                                                                maximumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                 minimumExpectedAnswerValue:FloatValue + 0.05
                                                                 maximumExpectedAnswerValue:FloatValue + 0.06] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                minimumExpectedAnswerValue:FloatValue - 0.01
                                                                maximumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                 minimumExpectedAnswerValue:FloatValue + 0.05
                                                                 maximumExpectedAnswerValue:FloatValue + 0.06] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                minimumExpectedAnswerValue:FloatValue - 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                 minimumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                maximumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORK1ResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                 maximumExpectedAnswerValue:FloatValue - 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // ORK1TimeOfDayQuestionResult
    resultSelector.resultIdentifier = TimeOfDayStepIdentifier;
    NSDateComponents *expectedDateComponentsMinimum = DateComponents();
    NSDateComponents *expectedDateComponentsMaximum = DateComponents();
    XCTAssertTrue([[ORK1ResultPredicate predicateForTimeOfDayQuestionResultWithResultSelector:resultSelector
                                                                         minimumExpectedHour:expectedDateComponentsMinimum.hour
                                                                       minimumExpectedMinute:expectedDateComponentsMinimum.minute
                                                                         maximumExpectedHour:expectedDateComponentsMaximum.hour
                                                                       maximumExpectedMinute:expectedDateComponentsMaximum.minute] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    expectedDateComponentsMinimum.minute -= 2;
    expectedDateComponentsMaximum.minute += 2;
    XCTAssertTrue([[ORK1ResultPredicate predicateForTimeOfDayQuestionResultWithResultSelector:resultSelector
                                                                         minimumExpectedHour:expectedDateComponentsMinimum.hour
                                                                       minimumExpectedMinute:expectedDateComponentsMinimum.minute
                                                                         maximumExpectedHour:expectedDateComponentsMaximum.hour
                                                                       maximumExpectedMinute:expectedDateComponentsMaximum.minute] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    expectedDateComponentsMinimum.minute += 3;
    XCTAssertFalse([[ORK1ResultPredicate predicateForTimeOfDayQuestionResultWithResultSelector:resultSelector
                                                                          minimumExpectedHour:expectedDateComponentsMinimum.hour
                                                                        minimumExpectedMinute:expectedDateComponentsMinimum.minute
                                                                          maximumExpectedHour:expectedDateComponentsMaximum.hour
                                                                        maximumExpectedMinute:expectedDateComponentsMaximum.minute] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    expectedDateComponentsMinimum.minute -= 3;
    expectedDateComponentsMinimum.hour += 1;
    expectedDateComponentsMaximum.hour += 2;
    XCTAssertFalse([[ORK1ResultPredicate predicateForTimeOfDayQuestionResultWithResultSelector:resultSelector
                                                                          minimumExpectedHour:expectedDateComponentsMinimum.hour
                                                                        minimumExpectedMinute:expectedDateComponentsMinimum.minute
                                                                          maximumExpectedHour:expectedDateComponentsMaximum.hour
                                                                        maximumExpectedMinute:expectedDateComponentsMaximum.minute] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // ORK1TimeIntervalQuestionResult
    resultSelector.resultIdentifier = FloatNumericStepIdentifier;
    XCTAssertTrue([[ORK1ResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                     minimumExpectedAnswerValue:ORK1IgnoreTimeIntervalValue
                                                                     maximumExpectedAnswerValue:ORK1IgnoreTimeIntervalValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORK1ResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                     minimumExpectedAnswerValue:FloatValue - 0.01
                                                                     maximumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORK1ResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                      minimumExpectedAnswerValue:FloatValue + 0.05
                                                                      maximumExpectedAnswerValue:FloatValue + 0.06] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORK1ResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                     minimumExpectedAnswerValue:FloatValue - 0.01
                                                                     maximumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORK1ResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                      minimumExpectedAnswerValue:FloatValue + 0.05
                                                                      maximumExpectedAnswerValue:FloatValue + 0.06] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORK1ResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                     minimumExpectedAnswerValue:FloatValue - 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORK1ResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                      minimumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORK1ResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                     maximumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORK1ResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                      maximumExpectedAnswerValue:FloatValue - 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // ORK1DateQuestionResult
    resultSelector.resultIdentifier = DateStepIdentifier;
    NSDate *expectedDate = Date();
    XCTAssertTrue([[ORK1ResultPredicate predicateForDateQuestionResultWithResultSelector:resultSelector
                                                              minimumExpectedAnswerDate:[expectedDate dateByAddingTimeInterval:-60]
                                                              maximumExpectedAnswerDate:[expectedDate dateByAddingTimeInterval:+60]] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORK1ResultPredicate predicateForDateQuestionResultWithResultSelector:resultSelector
                                                               minimumExpectedAnswerDate:[expectedDate dateByAddingTimeInterval:+60]
                                                               maximumExpectedAnswerDate:[expectedDate dateByAddingTimeInterval:+120]] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORK1ResultPredicate predicateForDateQuestionResultWithResultSelector:resultSelector
                                                              minimumExpectedAnswerDate:[expectedDate dateByAddingTimeInterval:-60]
                                                              maximumExpectedAnswerDate:nil] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORK1ResultPredicate predicateForDateQuestionResultWithResultSelector:resultSelector
                                                               minimumExpectedAnswerDate:[expectedDate dateByAddingTimeInterval:+1]
                                                               maximumExpectedAnswerDate:nil] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORK1ResultPredicate predicateForDateQuestionResultWithResultSelector:resultSelector
                                                              minimumExpectedAnswerDate:nil
                                                              maximumExpectedAnswerDate:[expectedDate dateByAddingTimeInterval:+60]] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORK1ResultPredicate predicateForDateQuestionResultWithResultSelector:resultSelector
                                                               minimumExpectedAnswerDate:nil
                                                               maximumExpectedAnswerDate:[expectedDate dateByAddingTimeInterval:-1]] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORK1ResultPredicate predicateForDateQuestionResultWithResultSelector:resultSelector
                                                              minimumExpectedAnswerDate:nil
                                                              maximumExpectedAnswerDate:nil] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // Result with nil value
    resultSelector.resultIdentifier = NilTextStepIdentifier;
    XCTAssertTrue([[ORK1ResultPredicate predicateForNilQuestionResultWithResultSelector:resultSelector] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    resultSelector.resultIdentifier = TextStepIdentifier;
    XCTAssertFalse([[ORK1ResultPredicate predicateForNilQuestionResultWithResultSelector:resultSelector] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
}

- (void)testConsentPredicate {
    ORK1ResultSelector *resultSelector = [[ORK1ResultSelector alloc] initWithTaskIdentifier:OrderedTaskIdentifier
                                                                           stepIdentifier:SignConsentStepIdentifier
                                                                         resultIdentifier:SignatureIdentifier];
    {
        ORK1TaskResult *consentedTaskResult = [self getTaskResultTreeWithConsent:YES];
        XCTAssertTrue([[ORK1ResultPredicate predicateForConsentWithResultSelector:resultSelector
                                                                      didConsent:YES] evaluateWithObject:@[consentedTaskResult] substitutionVariables:nil]);
        XCTAssertFalse([[ORK1ResultPredicate predicateForConsentWithResultSelector:resultSelector
                                                                       didConsent:NO] evaluateWithObject:@[consentedTaskResult] substitutionVariables:nil]);
    }
    
    {
        ORK1TaskResult *didNotConsentTaskResult = [self getTaskResultTreeWithConsent:NO];
        
        XCTAssertTrue([[ORK1ResultPredicate predicateForConsentWithResultSelector:resultSelector
                                                                      didConsent:NO] evaluateWithObject:@[didNotConsentTaskResult] substitutionVariables:nil]);
        XCTAssertFalse([[ORK1ResultPredicate predicateForConsentWithResultSelector:resultSelector
                                                                       didConsent:YES] evaluateWithObject:@[didNotConsentTaskResult] substitutionVariables:nil]);
    }
}

- (void)testResultPredicates {
    ORK1TaskResult *taskResult = [self getGeneralTaskResultTree];
    NSArray *taskResults = @[ taskResult ];
    
    // The following two calls are equivalent since 'substitutionVariables' are ignored when you provide a non-nil task identifier
    [self testResultPredicatesWithTaskIdentifier:OrderedTaskIdentifier
                           substitutionVariables:nil
                                     taskResults:taskResults];
    [self testResultPredicatesWithTaskIdentifier:OrderedTaskIdentifier
                           substitutionVariables:@{ORK1ResultPredicateTaskIdentifierVariableName: OrderedTaskIdentifier}
                                     taskResults:taskResults];
    // Test nil task identifier variable substitution
    [self testResultPredicatesWithTaskIdentifier:nil
                           substitutionVariables:@{ORK1ResultPredicateTaskIdentifierVariableName: OrderedTaskIdentifier}
                                     taskResults:taskResults];
}

- (void)testStepViewControllerWillDisappear {
    TestTaskViewControllerDelegate *delegate = [[TestTaskViewControllerDelegate alloc] init];
    ORK1OrderedTask *task = [ORK1OrderedTask twoFingerTappingIntervalTaskWithIdentifier:@"test" intendedUseDescription:nil duration:30 handOptions:0 options:0];
    ORK1TaskViewController *taskViewController = [[MockTaskViewController alloc] initWithTask:task taskRunUUID:nil];
    taskViewController.delegate = delegate;
    ORK1InstructionStepViewController *stepViewController = [[ORK1InstructionStepViewController alloc] initWithStep:task.steps.firstObject];
    
    //-- call method under test
    [taskViewController stepViewController:stepViewController didFinishWithNavigationDirection:ORK1StepViewControllerNavigationDirectionForward];
    
    // Check that the expected methods were called
    XCTAssertEqual(delegate.methodCalled.count, 1);
    XCTAssertEqualObjects(delegate.methodCalled.firstObject.selectorName, @"taskViewController:stepViewControllerWillDisappear:navigationDirection:");
    NSArray *expectedArgs = @[taskViewController, stepViewController, @(ORK1StepViewControllerNavigationDirectionForward)];
    XCTAssertEqualObjects(delegate.methodCalled.firstObject.arguments, expectedArgs);
    
}

- (void)testIndexOfStep {
    ORK1OrderedTask *task = [ORK1OrderedTask twoFingerTappingIntervalTaskWithIdentifier:@"tapping" intendedUseDescription:nil duration:30 handOptions:0 options:0];
    
    // get the first step
    ORK1Step *step0 = [task.steps firstObject];
    XCTAssertNotNil(step0);
    XCTAssertEqual([task indexOfStep:step0], 0);
    
    // get the second step
    ORK1Step *step1 = [task stepWithIdentifier:ORK1Instruction1StepIdentifier];
    XCTAssertNotNil(step1);
    XCTAssertEqual([task indexOfStep:step1], 1);
    
    // get the last step
    ORK1Step *stepLast = [task.steps lastObject];
    XCTAssertNotNil(stepLast);
    XCTAssertEqual([task indexOfStep:stepLast], task.steps.count - 1);
    
    // Look for not found
    ORK1Step *stepNF = [[ORK1Step alloc] initWithIdentifier:@"foo"];
    XCTAssertEqual([task indexOfStep:stepNF], NSNotFound);
    
}

- (void)testAudioTask_WithSoundCheck {
    ORK1NavigableOrderedTask *task = [ORK1OrderedTask audioTaskWithIdentifier:@"audio" intendedUseDescription:nil speechInstruction:nil shortSpeechInstruction:nil duration:20 recordingSettings:nil checkAudioLevel:YES options:0];
    
    NSArray *expectedStepIdentifiers = @[ORK1Instruction0StepIdentifier,
                                         ORK1Instruction1StepIdentifier,
                                         ORK1CountdownStepIdentifier,
                                         ORK1AudioTooLoudStepIdentifier,
                                         ORK1AudioStepIdentifier,
                                         ORK1ConclusionStepIdentifier];
    NSArray *stepIdentifiers = [task.steps valueForKey:@"identifier"];
    XCTAssertEqual(stepIdentifiers.count, expectedStepIdentifiers.count);
    XCTAssertEqualObjects(stepIdentifiers, expectedStepIdentifiers);
    
    XCTAssertNotNil([task navigationRuleForTriggerStepIdentifier:ORK1CountdownStepIdentifier]);
    XCTAssertNotNil([task navigationRuleForTriggerStepIdentifier:ORK1AudioTooLoudStepIdentifier]);
}

- (void)testAudioTask_NoSoundCheck {
    
    ORK1NavigableOrderedTask *task = [ORK1OrderedTask audioTaskWithIdentifier:@"audio" intendedUseDescription:nil speechInstruction:nil shortSpeechInstruction:nil duration:20 recordingSettings:nil checkAudioLevel:NO options:0];
    
    NSArray *expectedStepIdentifiers = @[ORK1Instruction0StepIdentifier,
                                         ORK1Instruction1StepIdentifier,
                                         ORK1CountdownStepIdentifier,
                                         ORK1AudioStepIdentifier,
                                         ORK1ConclusionStepIdentifier];
    NSArray *stepIdentifiers = [task.steps valueForKey:@"identifier"];
    XCTAssertEqual(stepIdentifiers.count, expectedStepIdentifiers.count);
    XCTAssertEqualObjects(stepIdentifiers, expectedStepIdentifiers);
    XCTAssertEqual(task.stepNavigationRules.count, 0);
}

- (void)testWalkBackAndForthTask_30SecondDuration {
    
    // Create the task
    ORK1OrderedTask *task = [ORK1OrderedTask walkBackAndForthTaskWithIdentifier:@"walking" intendedUseDescription:nil walkDuration:30 restDuration:30 options:0];
    
    // Check that the steps match the expected - If these change, it will affect the results and
    // could adversely impact existing studies that are expecting this step order.
    NSArray *expectedStepIdentifiers = @[ORK1Instruction0StepIdentifier,
                                         ORK1Instruction1StepIdentifier,
                                         ORK1CountdownStepIdentifier,
                                         ORK1ShortWalkOutboundStepIdentifier,
                                         ORK1ShortWalkRestStepIdentifier,
                                         ORK1ConclusionStepIdentifier];
    XCTAssertEqual(task.steps.count, expectedStepIdentifiers.count);
    NSArray *stepIdentifiers = [task.steps valueForKey:@"identifier"];
    XCTAssertEqualObjects(stepIdentifiers, expectedStepIdentifiers);
    
    // Check that the active steps include speaking the halfway point
    ORK1ActiveStep *walkingStep = (ORK1ActiveStep *)[task stepWithIdentifier:ORK1ShortWalkOutboundStepIdentifier];
    XCTAssertTrue(walkingStep.shouldSpeakRemainingTimeAtHalfway);
    ORK1ActiveStep *restStep = (ORK1ActiveStep *)[task stepWithIdentifier:ORK1ShortWalkRestStepIdentifier];
    XCTAssertTrue(restStep.shouldSpeakRemainingTimeAtHalfway);
    
}

- (void)testWalkBackAndForthTask_15SecondDuration_NoRest {
    
    // Create the task
    ORK1OrderedTask *task = [ORK1OrderedTask walkBackAndForthTaskWithIdentifier:@"walking" intendedUseDescription:nil walkDuration:15 restDuration:0 options:0];
    
    // Check that the steps match the expected - If these change, it will affect the results and
    // could adversely impact existing studies that are expecting this step order.
    NSArray *expectedStepIdentifiers = @[ORK1Instruction0StepIdentifier,
                                         ORK1Instruction1StepIdentifier,
                                         ORK1CountdownStepIdentifier,
                                         ORK1ShortWalkOutboundStepIdentifier,
                                         ORK1ConclusionStepIdentifier];
    XCTAssertEqual(task.steps.count, expectedStepIdentifiers.count);
    NSArray *stepIdentifiers = [task.steps valueForKey:@"identifier"];
    XCTAssertEqualObjects(stepIdentifiers, expectedStepIdentifiers);
    
    // Check that the active steps include speaking the halfway point
    ORK1ActiveStep *walkingStep = (ORK1ActiveStep *)[task stepWithIdentifier:ORK1ShortWalkOutboundStepIdentifier];
    XCTAssertFalse(walkingStep.shouldSpeakRemainingTimeAtHalfway);
    
}

#pragma mark - two-finger tapping with both hands

- (void)testTwoFingerTappingIntervalTaskWithIdentifier_TapHandOptionUndefined {
    
    ORK1OrderedTask *task = [ORK1OrderedTask twoFingerTappingIntervalTaskWithIdentifier:@"test"
                                                               intendedUseDescription:nil
                                                                             duration:10
                                                                          handOptions:0
                                                                              options:0];
    NSArray *expectedStepIdentifiers = @[ORK1Instruction0StepIdentifier,
                                              ORK1Instruction1StepIdentifier,
                                              ORK1TappingStepIdentifier,
                                              ORK1ConclusionStepIdentifier];
    NSArray *stepIdentifiers = [task.steps valueForKey:@"identifier"];
    XCTAssertEqual(stepIdentifiers.count, expectedStepIdentifiers.count);
    XCTAssertEqualObjects(stepIdentifiers, expectedStepIdentifiers);
    
    ORK1Step *tappingStep = [task stepWithIdentifier:ORK1TappingStepIdentifier];
    XCTAssertFalse(tappingStep.optional);

}

- (void)testTwoFingerTappingIntervalTaskWithIdentifier_TapHandOptionLeft {
    
    ORK1OrderedTask *task = [ORK1OrderedTask twoFingerTappingIntervalTaskWithIdentifier:@"test"
                                                               intendedUseDescription:nil
                                                                             duration:10
                                                                          handOptions:ORK1PredefinedTaskHandOptionLeft
                                                                              options:0];
    // Check assumption around how many steps
    XCTAssertEqual(task.steps.count, 4);
    
    // Check that none of the language or identifiers contain the word "right"
    for (ORK1Step *step in task.steps) {
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
    ORK1Step *instructionStep = [instructions firstObject];
    XCTAssertEqualObjects(instructionStep.title, @"Left Hand");
    XCTAssertEqualObjects(instructionStep.text, @"Put your phone on a flat surface. Use two fingers on your left hand to alternately tap the buttons on the screen. Tap one finger, then the other. Try to time your taps to be as even as possible. Keep tapping for 10 seconds.");
    
    // Look for the activity step
    NSArray *tappings = filteredSteps(@"tapping", @"left");
    XCTAssertEqual(tappings.count, 1);
    ORK1Step *tappingStep = [tappings firstObject];
    XCTAssertEqualObjects(tappingStep.title, @"Tap the buttons using your LEFT hand.");
    XCTAssertFalse(tappingStep.optional);
    
}

- (void)testTwoFingerTappingIntervalTaskWithIdentifier_TapHandOptionRight {
    
    ORK1OrderedTask *task = [ORK1OrderedTask twoFingerTappingIntervalTaskWithIdentifier:@"test"
                                                               intendedUseDescription:nil
                                                                             duration:10
                                                                          handOptions:ORK1PredefinedTaskHandOptionRight
                                                                              options:0];
    // Check assumption around how many steps
    XCTAssertEqual(task.steps.count, 4);
    
    // Check that none of the language or identifiers contain the word "right"
    for (ORK1Step *step in task.steps) {
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
    ORK1Step *instructionStep = [instructions firstObject];
    XCTAssertEqualObjects(instructionStep.title, @"Right Hand");
    XCTAssertEqualObjects(instructionStep.text, @"Put your phone on a flat surface. Use two fingers on your right hand to alternately tap the buttons on the screen. Tap one finger, then the other. Try to time your taps to be as even as possible. Keep tapping for 10 seconds.");
    
    // Look for the activity step
    NSArray *tappings = filteredSteps(@"tapping", @"right");
    XCTAssertEqual(tappings.count, 1);
    ORK1Step *tappingStep = [tappings firstObject];
    XCTAssertEqualObjects(tappingStep.title, @"Tap the buttons using your RIGHT hand.");
    XCTAssertFalse(tappingStep.optional);
    
}

- (void)testTwoFingerTappingIntervalTaskWithIdentifier_TapHandOptionBoth {
    NSUInteger leftCount = 0;
    NSUInteger rightCount = 0;
    NSUInteger totalCount = 100;
    NSUInteger threshold = 30;
    
    for (int ii = 0; ii < totalCount; ii++) {
        ORK1OrderedTask *task = [ORK1OrderedTask twoFingerTappingIntervalTaskWithIdentifier:@"test"
                                                                   intendedUseDescription:nil
                                                                                 duration:10
                                                                              handOptions:ORK1PredefinedTaskHandOptionBoth
                                                                                  options:0];
        ORK1Step * (^filteredSteps)(NSString*, NSString*) = ^(NSString *part1, NSString *part2) {
            NSString *keyValue = [NSString stringWithFormat:@"%@.%@", part1, part2];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", NSStringFromSelector(@selector(identifier)), keyValue];
            return [[task.steps filteredArrayUsingPredicate:predicate] firstObject];
        };
        
        // Look for instruction steps
        ORK1Step *rightInstructionStep = filteredSteps(@"instruction1", @"right");
        XCTAssertNotNil(rightInstructionStep);
        ORK1Step *leftInstructionStep = filteredSteps(@"instruction1", @"left");
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
            ORK1Step *rightTapStep = filteredSteps(@"tapping", @"right");
            XCTAssertNotNil(rightTapStep);
            XCTAssertEqualObjects(rightTapStep.title, @"Tap the buttons using your RIGHT hand.");
            XCTAssertTrue(rightTapStep.optional);
            
            ORK1Step *leftTapStep = filteredSteps(@"tapping", @"left");
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
    ORK1Step *boolStep = [ORK1QuestionStep  questionStepWithIdentifier:@"question"
                                                               title:@"Yes or No"
                                                              answer:[ORK1AnswerFormat booleanAnswerFormat]];
    
    ORK1Step *nextStep = [[ORK1InstructionStep alloc] initWithIdentifier:@"nextStep"];
    nextStep.title = @"Yes";

    ORK1NavigableOrderedTask *task = [[ORK1NavigableOrderedTask alloc] initWithIdentifier:NavigableOrderedTaskIdentifier
                                                                                  steps:@[boolStep, nextStep]];
    
    ORK1ResultSelector *resultSelector = [ORK1ResultSelector selectorWithStepIdentifier:@"question"
                                                                     resultIdentifier:@"question"];
    NSPredicate *predicate = [ORK1ResultPredicate predicateForBooleanQuestionResultWithResultSelector:resultSelector
                                                                                      expectedAnswer:NO];
    ORK1StepModifier *stepModifier = [[ORK1KeyValueStepModifier alloc] initWithResultPredicate:predicate
                                                                               keyValueMap:@{ @"title" : @"No" }];
    
    [task setStepModifier:stepModifier forStepIdentifier:@"nextStep"];
    
    // -- Check the title if the answer is YES
    ORK1BooleanQuestionResult *result = [[ORK1BooleanQuestionResult alloc] initWithIdentifier:@"question"];
    result.booleanAnswer = @(YES);
    ORK1StepResult *stepResult = [[ORK1StepResult alloc] initWithStepIdentifier:@"question" results:@[result]];
    ORK1TaskResult *taskResult = [[ORK1TaskResult alloc] initWithIdentifier:NavigableOrderedTaskIdentifier];
    taskResult.results = @[stepResult];
    
    // For the case where the answer is YES, then the title should be "Yes" (unmodified)
    ORK1Step *yesStep = [task stepAfterStep:boolStep withResult:taskResult];
    XCTAssertEqualObjects(yesStep.title, @"Yes");
    
    // -- Check the title if the answer is NO
    result.booleanAnswer = @(NO);
    stepResult = [[ORK1StepResult alloc] initWithStepIdentifier:@"question" results:@[result]];
    taskResult.results = @[stepResult];
    
    // For the case where the answer is NO, then the title should be modified to be "No"
    ORK1Step *noStep = [task stepAfterStep:boolStep withResult:taskResult];
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

- (void)taskViewController:(ORK1TaskViewController *)taskViewController didFinishWithReason:(ORK1TaskViewControllerFinishReason)reason error:(NSError *)error {
    
    // Add results of method call
    MethodObject *obj = [[MethodObject alloc] init];
    obj.selectorName = NSStringFromSelector(@selector(taskViewController:didFinishWithReason:error:));
    obj.arguments = @[taskViewController ?: [NSNull null],
                      @(reason),
                      error ?: [NSNull null]];
    [self.methodCalled addObject:obj];
}

- (void)taskViewController:(ORK1TaskViewController *)taskViewController stepViewControllerWillDisappear:(ORK1StepViewController *)stepViewController navigationDirection:(ORK1StepViewControllerNavigationDirection)direction {
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

- (void)flipToNextPageFrom:(ORK1StepViewController *)fromController {
    // Add results of method call
    MethodObject *obj = [[MethodObject alloc] init];
    obj.selectorName = NSStringFromSelector(@selector(flipToNextPageFrom:));
    obj.arguments = @[fromController ?: [NSNull null]];
    [self.methodCalled addObject:obj];
}

- (void)flipToPreviousPageFrom:(ORK1StepViewController *)fromController {
    // Add results of method call
    MethodObject *obj = [[MethodObject alloc] init];
    obj.selectorName = NSStringFromSelector(@selector(flipToPreviousPageFrom:));
    obj.arguments = @[fromController ?: [NSNull null]];
    [self.methodCalled addObject:obj];
}

@end
