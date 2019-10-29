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


@interface ORKLegacyTaskTests : XCTestCase

@end

@interface MethodObject : NSObject
@property (nonatomic) NSString *selectorName;
@property (nonatomic) NSArray *arguments;
@end

@interface TestTaskViewControllerDelegate : NSObject <ORKLegacyTaskViewControllerDelegate>
@property (nonatomic) NSMutableArray <MethodObject *> *methodCalled;
@end

@interface MockTaskViewController : ORKLegacyTaskViewController
@property (nonatomic) NSMutableArray <MethodObject *> *methodCalled;
@end


@implementation ORKLegacyTaskTests {
    NSArray *_orderedTaskStepIdentifiers;
    NSArray *_orderedTaskSteps;
    ORKLegacyOrderedTask *_orderedTask;
    
    NSArray *_navigableOrderedTaskStepIdentifiers;
    NSArray *_navigableOrderedTaskSteps;
    NSMutableDictionary *_stepNavigationRules;
    ORKLegacyNavigableOrderedTask *_navigableOrderedTask;
}

ORKLegacyDefineStringKey(HeadacheChoiceValue);
ORKLegacyDefineStringKey(DizzinessChoiceValue);
ORKLegacyDefineStringKey(NauseaChoiceValue);

ORKLegacyDefineStringKey(SymptomStepIdentifier);
ORKLegacyDefineStringKey(SeverityStepIdentifier);
ORKLegacyDefineStringKey(BlankStepIdentifier);
ORKLegacyDefineStringKey(SevereHeadacheStepIdentifier);
ORKLegacyDefineStringKey(LightHeadacheStepIdentifier);
ORKLegacyDefineStringKey(OtherSymptomStepIdentifier);
ORKLegacyDefineStringKey(EndStepIdentifier);
ORKLegacyDefineStringKey(BlankBStepIdentifier);

ORKLegacyDefineStringKey(OrderedTaskIdentifier);
ORKLegacyDefineStringKey(NavigableOrderedTaskIdentifier);

- (void)generateTaskSteps:(out NSArray **)outSteps stepIdentifiers:(out NSArray **)outStepIdentifiers {
    if (outSteps == NULL || outStepIdentifiers == NULL) {
        return;
    }
    
    NSMutableArray *stepIdentifiers = [NSMutableArray new];
    NSMutableArray *steps = [NSMutableArray new];
    
    ORKLegacyAnswerFormat *answerFormat = nil;
    NSString *stepIdentifier = nil;
    ORKLegacyStep *step = nil;
    
    NSArray *textChoices =
    @[
      [ORKLegacyTextChoice choiceWithText:@"Headache" value:HeadacheChoiceValue],
      [ORKLegacyTextChoice choiceWithText:@"Dizziness" value:DizzinessChoiceValue],
      [ORKLegacyTextChoice choiceWithText:@"Nausea" value:NauseaChoiceValue]
      ];
    
    answerFormat = [ORKLegacyAnswerFormat choiceAnswerFormatWithStyle:ORKLegacyChoiceAnswerStyleSingleChoice
                                                    textChoices:textChoices];
    stepIdentifier = SymptomStepIdentifier;
    step = [ORKLegacyQuestionStep questionStepWithIdentifier:stepIdentifier title:@"What is your symptom?" answer:answerFormat];
    step.optional = NO;
    [stepIdentifiers addObject:stepIdentifier];
    [steps addObject:step];
    
    answerFormat = [ORKLegacyAnswerFormat booleanAnswerFormat];
    stepIdentifier = SeverityStepIdentifier;
    step = [ORKLegacyQuestionStep questionStepWithIdentifier:stepIdentifier title:@"Does your symptom interferes with your daily life?" answer:answerFormat];
    step.optional = NO;
    [stepIdentifiers addObject:stepIdentifier];
    [steps addObject:step];
    
    stepIdentifier = BlankStepIdentifier;
    step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:stepIdentifier];
    step.title = @"This step is intentionally left blank (you should not see it)";
    [stepIdentifiers addObject:stepIdentifier];
    [steps addObject:step];
    
    stepIdentifier = SevereHeadacheStepIdentifier;
    step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:stepIdentifier];
    step.title = @"You have a severe headache";
    [stepIdentifiers addObject:stepIdentifier];
    [steps addObject:step];
    
    stepIdentifier = LightHeadacheStepIdentifier;
    step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:stepIdentifier];
    step.title = @"You have a light headache";
    [stepIdentifiers addObject:stepIdentifier];
    [steps addObject:step];
    
    stepIdentifier = OtherSymptomStepIdentifier;
    step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:stepIdentifier];
    step.title = @"You have other symptom";
    [stepIdentifiers addObject:stepIdentifier];
    [steps addObject:step];
    
    stepIdentifier = EndStepIdentifier;
    step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:stepIdentifier];
    step.title = @"You have finished the task";
    [stepIdentifiers addObject:stepIdentifier];
    [steps addObject:step];
    
    stepIdentifier = BlankBStepIdentifier;
    step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:stepIdentifier];
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
    
    _orderedTask = [[ORKLegacyOrderedTask alloc] initWithIdentifier:OrderedTaskIdentifier
                                                        steps:ORKLegacyArrayCopyObjects(_orderedTaskSteps)]; // deep copy to test step copying and equality
}

- (void)setUpNavigableOrderedTask {
    ORKLegacyResultSelector *resultSelector = nil;
    NSArray *navigableOrderedTaskSteps = nil;
    NSArray *navigableOrderedTaskStepIdentifiers = nil;
    [self generateTaskSteps:&navigableOrderedTaskSteps stepIdentifiers:&navigableOrderedTaskStepIdentifiers];
    _navigableOrderedTaskSteps = navigableOrderedTaskSteps;
    _navigableOrderedTaskStepIdentifiers = navigableOrderedTaskStepIdentifiers;
    
    _navigableOrderedTask = [[ORKLegacyNavigableOrderedTask alloc] initWithIdentifier:NavigableOrderedTaskIdentifier
                                                                          steps:ORKLegacyArrayCopyObjects(_navigableOrderedTaskSteps)]; // deep copy to test step copying and equality
    
    // Build navigation rules
    _stepNavigationRules = [NSMutableDictionary new];
    // Individual predicates
    
    // User chose headache at the symptom step
    resultSelector = [[ORKLegacyResultSelector alloc] initWithResultIdentifier:SymptomStepIdentifier];
    NSPredicate *predicateHeadache = [ORKLegacyResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                                        expectedAnswerValue:HeadacheChoiceValue];
    // Equivalent to:
    //      [NSPredicate predicateWithFormat:
    //          @"SUBQUERY(SELF, $x, $x.identifier like 'symptom' \
    //                     AND SUBQUERY($x.answer, $y, $y like 'headache').@count > 0).@count > 0"];
    
    // User didn't chose headache at the symptom step
    NSPredicate *predicateNotHeadache = [NSCompoundPredicate notPredicateWithSubpredicate:predicateHeadache];
    
    // User chose YES at the severity step
    resultSelector = [[ORKLegacyResultSelector alloc] initWithResultIdentifier:SeverityStepIdentifier];
    NSPredicate *predicateSevereYes = [ORKLegacyResultPredicate predicateForBooleanQuestionResultWithResultSelector:resultSelector
                                                                                               expectedAnswer:YES];
    // Equivalent to:
    //      [NSPredicate predicateWithFormat:
    //          @"SUBQUERY(SELF, $x, $x.identifier like 'severity' AND $x.answer == YES).@count > 0"];
    
    // User chose NO at the severity step
    NSPredicate *predicateSevereNo = [ORKLegacyResultPredicate predicateForBooleanQuestionResultWithResultSelector:resultSelector
                                                                                              expectedAnswer:NO];
    
    
    // From the "symptom" step, go to "other_symptom" is user didn't chose headache.
    // Otherwise, default to going to next step (when the defaultStepIdentifier argument is omitted,
    // the regular ORKLegacyOrderedTask order applies).
    NSMutableArray *resultPredicates = [NSMutableArray new];
    NSMutableArray *destinationStepIdentifiers = [NSMutableArray new];
    
    [resultPredicates addObject:predicateNotHeadache];
    [destinationStepIdentifiers addObject:OtherSymptomStepIdentifier];
    
    ORKLegacyPredicateStepNavigationRule *predicateRule =
    [[ORKLegacyPredicateStepNavigationRule alloc] initWithResultPredicates:resultPredicates
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
    [[ORKLegacyPredicateStepNavigationRule alloc] initWithResultPredicates:resultPredicates
                                          destinationStepIdentifiers:destinationStepIdentifiers
                                               defaultStepIdentifier:OtherSymptomStepIdentifier];
    
    [_navigableOrderedTask setNavigationRule:predicateRule forTriggerStepIdentifier:SeverityStepIdentifier];
    _stepNavigationRules[SeverityStepIdentifier] = [predicateRule copy];
    
    
    // Add end direct rules to skip unneeded steps
    ORKLegacyDirectStepNavigationRule *directRule = nil;
    
    directRule = [[ORKLegacyDirectStepNavigationRule alloc] initWithDestinationStepIdentifier:EndStepIdentifier];
    
    [_navigableOrderedTask setNavigationRule:directRule forTriggerStepIdentifier:SevereHeadacheStepIdentifier];
    [_navigableOrderedTask setNavigationRule:directRule forTriggerStepIdentifier:LightHeadacheStepIdentifier];
    [_navigableOrderedTask setNavigationRule:directRule forTriggerStepIdentifier:OtherSymptomStepIdentifier];
    
    _stepNavigationRules[SevereHeadacheStepIdentifier] = [directRule copy];
    _stepNavigationRules[LightHeadacheStepIdentifier] = [directRule copy];
    _stepNavigationRules[OtherSymptomStepIdentifier] = [directRule copy];
    
    directRule = [[ORKLegacyDirectStepNavigationRule alloc] initWithDestinationStepIdentifier:ORKLegacyNullStepIdentifier];
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

- (ORKLegacyTaskResult *)getResultTreeWithTaskIdentifier:(NSString *)taskIdentifier resultOptions:(TestsTaskResultOptions)resultOptions {
    if ( ((resultOptions & TestsTaskResultOptionSymptomDizziness) || (resultOptions & TestsTaskResultOptionSymptomNausea)) && ((resultOptions & TestsTaskResultOptionSeverityYes) || (resultOptions & TestsTaskResultOptionSeverityNo)) ) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"You can only add a severity result for the headache symptom" userInfo:nil];
    }
    
    NSMutableArray *stepResults = [NSMutableArray new];
    
    ORKLegacyQuestionResult *questionResult = nil;
    ORKLegacyStepResult *stepResult = nil;
    NSString *stepIdentifier = nil;
    
    if (resultOptions & (TestsTaskResultOptionSymptomHeadache | TestsTaskResultOptionSymptomDizziness | TestsTaskResultOptionSymptomNausea)) {
        stepIdentifier = SymptomStepIdentifier;
        questionResult = [[ORKLegacyChoiceQuestionResult alloc] init];
        questionResult.identifier = stepIdentifier;
        if (resultOptions & TestsTaskResultOptionSymptomHeadache) {
            questionResult.answer = @[HeadacheChoiceValue];
        } else if (resultOptions & TestsTaskResultOptionSymptomDizziness) {
            questionResult.answer = @[DizzinessChoiceValue];
        } else if (resultOptions & TestsTaskResultOptionSymptomNausea) {
            questionResult.answer = @[NauseaChoiceValue];
        }
        questionResult.questionType = ORKLegacyQuestionTypeSingleChoice;
        
        stepResult = [[ORKLegacyStepResult alloc] initWithStepIdentifier:stepIdentifier results:@[questionResult]];
        [stepResults addObject:stepResult];

        if (resultOptions & (TestsTaskResultOptionSymptomDizziness | TestsTaskResultOptionSymptomNausea)) {
            stepResult = [[ORKLegacyStepResult alloc] initWithStepIdentifier:OtherSymptomStepIdentifier results:nil];
            [stepResults addObject:stepResult];
        }
    }
    
    if (resultOptions & (TestsTaskResultOptionSeverityYes | TestsTaskResultOptionSeverityNo)) {
        stepIdentifier = SeverityStepIdentifier;
        questionResult = [[ORKLegacyBooleanQuestionResult alloc] init];
        questionResult.identifier = stepIdentifier;
        if (resultOptions & TestsTaskResultOptionSeverityYes) {
            questionResult.answer = @(YES);
        } else if (resultOptions & TestsTaskResultOptionSeverityNo) {
            questionResult.answer = @(NO);
        }
        questionResult.questionType = ORKLegacyQuestionTypeSingleChoice;
        
        stepResult = [[ORKLegacyStepResult alloc] initWithStepIdentifier:stepIdentifier results:@[questionResult]];
        [stepResults addObject:stepResult];
        
        
        if (resultOptions & TestsTaskResultOptionSeverityYes) {
            stepResult = [[ORKLegacyStepResult alloc] initWithStepIdentifier:SevereHeadacheStepIdentifier results:nil];
            [stepResults addObject:stepResult];
        } else if (resultOptions & TestsTaskResultOptionSeverityNo) {
            stepResult = [[ORKLegacyStepResult alloc] initWithStepIdentifier:LightHeadacheStepIdentifier results:nil];
            [stepResults addObject:stepResult];
        }
    }
    
    stepResult = [[ORKLegacyStepResult alloc] initWithStepIdentifier:EndStepIdentifier results:nil];
    [stepResults addObject:stepResult];

    ORKLegacyTaskResult *taskResult = [[ORKLegacyTaskResult alloc] initWithTaskIdentifier:taskIdentifier
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
    ORKLegacyTaskResult *mockTaskResult = [[ORKLegacyTaskResult alloc] init];
    
    XCTAssertEqualObjects(_orderedTask.identifier, OrderedTaskIdentifier);
    XCTAssertEqualObjects(_orderedTask.steps, _orderedTaskSteps);
    
    NSUInteger expectedTotalProgress = _orderedTaskSteps.count;
    
    for (NSUInteger stepIndex = 0; stepIndex < _orderedTaskStepIdentifiers.count; stepIndex++) {
        ORKLegacyStep *currentStep = _orderedTaskSteps[stepIndex];
        XCTAssertEqualObjects(currentStep, [_orderedTask stepWithIdentifier:_orderedTaskStepIdentifiers[stepIndex]]);
        
        const NSUInteger expectedCurrentProgress = stepIndex;
        ORKLegacyTaskProgress currentProgress = [_orderedTask progressOfCurrentStep:currentStep withResult:mockTaskResult];
        XCTAssertTrue(currentProgress.total == expectedTotalProgress && currentProgress.current == expectedCurrentProgress);
        
        NSString *expectedPreviousStep = (stepIndex != 0) ? _orderedTaskSteps[stepIndex - 1] : nil;
        NSString *expectedNextStep = (stepIndex < _orderedTaskStepIdentifiers.count - 1) ? _orderedTaskSteps[stepIndex + 1] : nil;
        XCTAssertEqualObjects(expectedPreviousStep, [_orderedTask stepBeforeStep:currentStep withResult:mockTaskResult]);
        XCTAssertEqualObjects(expectedNextStep, [_orderedTask stepAfterStep:currentStep withResult:mockTaskResult]);
    }
    
    // Test duplicate step identifier validation
    XCTAssertNoThrow([_orderedTask validateParameters]);
    
    NSMutableArray *steps = [[NSMutableArray alloc] initWithArray:ORKLegacyArrayCopyObjects(_orderedTaskSteps)];
    ORKLegacyStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:BlankStepIdentifier];
    [steps addObject:step];
    
    XCTAssertThrows([[ORKLegacyOrderedTask alloc] initWithIdentifier:OrderedTaskIdentifier
                                                         steps:steps]);
}

#define getIndividualNavigableOrderedTaskSteps() \
__unused ORKLegacyStep *symptomStep = _navigableOrderedTaskSteps[0];\
__unused ORKLegacyStep *severityStep = _navigableOrderedTaskSteps[1];\
__unused ORKLegacyStep *blankStep = _navigableOrderedTaskSteps[2];\
__unused ORKLegacyStep *severeHeadacheStep = _navigableOrderedTaskSteps[3];\
__unused ORKLegacyStep *lightHeadacheStep = _navigableOrderedTaskSteps[4];\
__unused ORKLegacyStep *otherSymptomStep = _navigableOrderedTaskSteps[5];\
__unused ORKLegacyStep *endStep = _navigableOrderedTaskSteps[6];

BOOL (^testStepAfterStep)(ORKLegacyNavigableOrderedTask *, ORKLegacyTaskResult *, ORKLegacyStep *, ORKLegacyStep *) =  ^BOOL(ORKLegacyNavigableOrderedTask *task, ORKLegacyTaskResult *taskResult, ORKLegacyStep *fromStep, ORKLegacyStep *expectedStep) {
    ORKLegacyStep *testedStep = [task stepAfterStep:fromStep withResult:taskResult];
    return (testedStep == nil && expectedStep == nil) || [testedStep isEqual:expectedStep];
};

BOOL (^testStepBeforeStep)(ORKLegacyNavigableOrderedTask *, ORKLegacyTaskResult *, ORKLegacyStep *, ORKLegacyStep *) =  ^BOOL(ORKLegacyNavigableOrderedTask *task, ORKLegacyTaskResult *taskResult, ORKLegacyStep *fromStep, ORKLegacyStep *expectedStep) {
    ORKLegacyStep *testedStep = [task stepBeforeStep:fromStep withResult:taskResult];
    return (testedStep == nil && expectedStep == nil) || [testedStep isEqual:expectedStep];
};

- (void)testNavigableOrderedTask {
    XCTAssertEqualObjects(_navigableOrderedTask.identifier, NavigableOrderedTaskIdentifier);
    XCTAssertEqualObjects(_navigableOrderedTask.steps, _navigableOrderedTaskSteps);
    XCTAssertEqualObjects(_navigableOrderedTask.stepNavigationRules, _stepNavigationRules);
    
    for (NSString *triggerStepIdentifier in [_stepNavigationRules allKeys]) {
        XCTAssertEqualObjects(_stepNavigationRules[triggerStepIdentifier], [_navigableOrderedTask navigationRuleForTriggerStepIdentifier:triggerStepIdentifier]);
    }
    
    ORKLegacyDefineStringKey(MockTriggerStepIdentifier);
    ORKLegacyDefineStringKey(MockDestinationStepIdentifier);
    
    // Test adding and removing a step navigation rule
    XCTAssertNil([_navigableOrderedTask navigationRuleForTriggerStepIdentifier:MockTriggerStepIdentifier]);
    
    ORKLegacyDirectStepNavigationRule *mockNavigationRule = [[ORKLegacyDirectStepNavigationRule alloc] initWithDestinationStepIdentifier:MockDestinationStepIdentifier];
    [_navigableOrderedTask setNavigationRule:mockNavigationRule forTriggerStepIdentifier:MockTriggerStepIdentifier];

    XCTAssertEqualObjects([_navigableOrderedTask navigationRuleForTriggerStepIdentifier:MockTriggerStepIdentifier], [mockNavigationRule copy]);

    ORKLegacyPredicateSkipStepNavigationRule *mockSkipNavigationRule = [[ORKLegacyPredicateSkipStepNavigationRule alloc] initWithResultPredicate:[NSPredicate predicateWithFormat:@"1 == 1"]];
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
    ORKLegacyTaskResult *taskResult = [self getResultTreeWithTaskIdentifier:NavigableOrderedTaskIdentifier resultOptions:0];
    
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
    ORKLegacyTaskResult *taskResult = [self getResultTreeWithTaskIdentifier:NavigableOrderedTaskIdentifier resultOptions:TestsTaskResultOptionSymptomHeadache | TestsTaskResultOptionSeverityYes];
    
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
    ORKLegacyTaskResult *taskResult = [self getResultTreeWithTaskIdentifier:NavigableOrderedTaskIdentifier resultOptions:TestsTaskResultOptionSymptomDizziness];
    
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
    ORKLegacyTaskResult *taskResult = [self getResultTreeWithTaskIdentifier:NavigableOrderedTaskIdentifier resultOptions:TestsTaskResultOptionSymptomHeadache | TestsTaskResultOptionSeverityYes];
    
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
    ORKLegacyTaskResult *taskResult = [self getResultTreeWithTaskIdentifier:NavigableOrderedTaskIdentifier resultOptions:TestsTaskResultOptionSymptomHeadache | TestsTaskResultOptionSeverityNo];
    
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
    ORKLegacyNavigableOrderedTask *skipTask = [_navigableOrderedTask copy];

    getIndividualNavigableOrderedTaskSteps();

    //
    // Light headache sequence
    //
    ORKLegacyTaskResult *taskResult = [self getResultTreeWithTaskIdentifier:NavigableOrderedTaskIdentifier resultOptions:TestsTaskResultOptionSymptomHeadache | TestsTaskResultOptionSeverityNo];

    // User chose headache at the symptom step
    ORKLegacyResultSelector *resultSelector = [[ORKLegacyResultSelector alloc] initWithResultIdentifier:SymptomStepIdentifier];
    NSPredicate *predicateHeadache = [ORKLegacyResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                                        expectedAnswerValue:HeadacheChoiceValue];
    ORKLegacyPredicateSkipStepNavigationRule *skipRule = [[ORKLegacyPredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicateHeadache];
    
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

ORKLegacyDefineStringKey(SignConsentStepIdentifier);
ORKLegacyDefineStringKey(SignatureIdentifier);

ORKLegacyDefineStringKey(ScaleStepIdentifier);
ORKLegacyDefineStringKey(ContinuousScaleStepIdentifier);
static const NSInteger IntegerValue = 6;
static const float FloatValue = 6.5;

ORKLegacyDefineStringKey(SingleChoiceStepIdentifier);
ORKLegacyDefineStringKey(MultipleChoiceStepIdentifier);
ORKLegacyDefineStringKey(MixedMultipleChoiceStepIdentifier);
ORKLegacyDefineStringKey(SingleChoiceValue);
ORKLegacyDefineStringKey(MultipleChoiceValue1);
ORKLegacyDefineStringKey(MultipleChoiceValue2);
static const NSInteger MultipleChoiceValue3 = 7;

ORKLegacyDefineStringKey(BooleanStepIdentifier);
static const BOOL BooleanValue = YES;

ORKLegacyDefineStringKey(TextStepIdentifier);
ORKLegacyDefineStringKey(TextValue);
ORKLegacyDefineStringKey(OtherTextValue);

ORKLegacyDefineStringKey(IntegerNumericStepIdentifier);
ORKLegacyDefineStringKey(FloatNumericStepIdentifier);

ORKLegacyDefineStringKey(TimeOfDayStepIdentifier);
ORKLegacyDefineStringKey(TimeIntervalStepIdentifier);
ORKLegacyDefineStringKey(DateStepIdentifier);

ORKLegacyDefineStringKey(FormStepIdentifier);

ORKLegacyDefineStringKey(TextFormItemIdentifier);
ORKLegacyDefineStringKey(NumericFormItemIdentifier);

ORKLegacyDefineStringKey(NilTextStepIdentifier);

ORKLegacyDefineStringKey(AdditionalTaskIdentifier);
ORKLegacyDefineStringKey(AdditionalFormStepIdentifier);
ORKLegacyDefineStringKey(AdditionalTextFormItemIdentifier);
ORKLegacyDefineStringKey(AdditionalNumericFormItemIdentifier);

ORKLegacyDefineStringKey(AdditionalTextStepIdentifier);
ORKLegacyDefineStringKey(AdditionalTextValue);

ORKLegacyDefineStringKey(MatchedDestinationStepIdentifier);
ORKLegacyDefineStringKey(DefaultDestinationStepIdentifier);

static const NSInteger AdditionalIntegerValue = 42;

static NSDate *(^Date)(void) = ^NSDate *{ return [NSDate dateWithTimeIntervalSince1970:60*60*24]; };
static NSDateComponents *(^DateComponents)(void) = ^NSDateComponents *{
    NSDateComponents *dateComponents = [NSDateComponents new];
    dateComponents.hour = 6;
    dateComponents.minute = 6;
    return dateComponents;
};

static ORKLegacyQuestionResult *(^getQuestionResult)(NSString *, Class, ORKLegacyQuestionType, id) = ^ORKLegacyQuestionResult *(NSString *questionResultIdentifier, Class questionResultClass, ORKLegacyQuestionType questionType, id answer) {
    ORKLegacyQuestionResult *questionResult = [[questionResultClass alloc] init];
    questionResult.identifier = questionResultIdentifier;
    questionResult.answer = answer;
    questionResult.questionType = questionType;
    return questionResult;
};

static ORKLegacyStepResult *(^getStepResult)(NSString *, Class, ORKLegacyQuestionType, id) = ^ORKLegacyStepResult *(NSString *stepIdentifier, Class questionResultClass, ORKLegacyQuestionType questionType, id answer) {
    ORKLegacyQuestionResult *questionResult = getQuestionResult(stepIdentifier, questionResultClass, questionType, answer);
    ORKLegacyStepResult *stepResult = [[ORKLegacyStepResult alloc] initWithStepIdentifier:stepIdentifier results:@[questionResult]];
    return stepResult;
};

static ORKLegacyStepResult *(^getConsentStepResult)(NSString *, NSString *, BOOL) = ^ORKLegacyStepResult *(NSString *stepIdentifier, NSString *signatureIdentifier, BOOL consented) {
    ORKLegacyConsentSignatureResult *consentSignatureResult = [[ORKLegacyConsentSignatureResult alloc] initWithIdentifier:signatureIdentifier];
    consentSignatureResult.consented = consented;
    return [[ORKLegacyStepResult alloc] initWithStepIdentifier:stepIdentifier results:@[consentSignatureResult]];
};

- (ORKLegacyTaskResult *)getGeneralTaskResultTree {
    NSMutableArray *stepResults = [NSMutableArray new];
    
    [stepResults addObject:getStepResult(ScaleStepIdentifier, [ORKLegacyScaleQuestionResult class], ORKLegacyQuestionTypeScale, @(IntegerValue))];
    [stepResults addObject:getStepResult(ContinuousScaleStepIdentifier, [ORKLegacyScaleQuestionResult class], ORKLegacyQuestionTypeScale, @(FloatValue))];
    
    [stepResults addObject:getStepResult(SingleChoiceStepIdentifier, [ORKLegacyChoiceQuestionResult class], ORKLegacyQuestionTypeSingleChoice, @[SingleChoiceValue])];
    [stepResults addObject:getStepResult(MultipleChoiceStepIdentifier, [ORKLegacyChoiceQuestionResult class], ORKLegacyQuestionTypeMultipleChoice, @[MultipleChoiceValue1, MultipleChoiceValue2])];
    [stepResults addObject:getStepResult(MixedMultipleChoiceStepIdentifier, [ORKLegacyChoiceQuestionResult class], ORKLegacyQuestionTypeMultipleChoice, @[MultipleChoiceValue1, MultipleChoiceValue2, @(MultipleChoiceValue3)])];
    
    [stepResults addObject:getStepResult(BooleanStepIdentifier, [ORKLegacyBooleanQuestionResult class], ORKLegacyQuestionTypeBoolean, @(BooleanValue))];
    
    [stepResults addObject:getStepResult(TextStepIdentifier, [ORKLegacyTextQuestionResult class], ORKLegacyQuestionTypeText, TextValue)];
    
    [stepResults addObject:getStepResult(IntegerNumericStepIdentifier, [ORKLegacyNumericQuestionResult class], ORKLegacyQuestionTypeInteger, @(IntegerValue))];
    [stepResults addObject:getStepResult(FloatNumericStepIdentifier, [ORKLegacyNumericQuestionResult class], ORKLegacyQuestionTypeDecimal, @(FloatValue))];
    
    [stepResults addObject:getStepResult(DateStepIdentifier, [ORKLegacyDateQuestionResult class], ORKLegacyQuestionTypeDate, Date())];
    
    [stepResults addObject:getStepResult(TimeIntervalStepIdentifier, [ORKLegacyTimeIntervalQuestionResult class], ORKLegacyQuestionTypeTimeInterval, @(IntegerValue))];
    
    [stepResults addObject:getStepResult(TimeOfDayStepIdentifier, [ORKLegacyTimeOfDayQuestionResult class], ORKLegacyQuestionTypeTimeOfDay, DateComponents())];
    
    // Nil result (simulate skipped step)
    [stepResults addObject:getStepResult(NilTextStepIdentifier, [ORKLegacyTextQuestionResult class], ORKLegacyQuestionTypeText, nil)];
    
    ORKLegacyTaskResult *taskResult = [[ORKLegacyTaskResult alloc] initWithTaskIdentifier:OrderedTaskIdentifier
                                                                  taskRunUUID:[NSUUID UUID]
                                                              outputDirectory:[NSURL fileURLWithPath:NSTemporaryDirectory()]];
    taskResult.results = stepResults;
    
    return taskResult;
}

- (ORKLegacyTaskResult *)getTaskResultTreeWithConsent:(BOOL)consented {
    NSMutableArray *stepResults = [NSMutableArray new];
    
    [stepResults addObject:getConsentStepResult(SignConsentStepIdentifier, SignatureIdentifier, consented)];
    
    ORKLegacyTaskResult *taskResult = [[ORKLegacyTaskResult alloc] initWithTaskIdentifier:OrderedTaskIdentifier
                                                                  taskRunUUID:[NSUUID UUID]
                                                              outputDirectory:[NSURL fileURLWithPath:NSTemporaryDirectory()]];
    taskResult.results = stepResults;
    
    return taskResult;
}

- (ORKLegacyTaskResult *)getSmallTaskResultTreeWithIsAdditionalTask:(BOOL)isAdditionalTask {
    NSMutableArray *stepResults = [NSMutableArray new];
    
    if (!isAdditionalTask) {
        [stepResults addObject:getStepResult(TextStepIdentifier, [ORKLegacyTextQuestionResult class], ORKLegacyQuestionTypeText, TextValue)];
    } else {
        [stepResults addObject:getStepResult(AdditionalTextStepIdentifier, [ORKLegacyTextQuestionResult class], ORKLegacyQuestionTypeText, AdditionalTextValue)];
    }
    
    ORKLegacyTaskResult *taskResult = [[ORKLegacyTaskResult alloc] initWithTaskIdentifier:!isAdditionalTask ? OrderedTaskIdentifier : AdditionalTaskIdentifier
                                                                  taskRunUUID:[NSUUID UUID]
                                                              outputDirectory:[NSURL fileURLWithPath:NSTemporaryDirectory()]];
    taskResult.results = stepResults;
    
    return taskResult;
}

- (ORKLegacyTaskResult *)getSmallFormTaskResultTreeWithIsAdditionalTask:(BOOL)isAdditionalTask {
    NSMutableArray *formItemResults = [NSMutableArray new];
    
    if (!isAdditionalTask) {
        [formItemResults addObject:getQuestionResult(TextFormItemIdentifier, [ORKLegacyTextQuestionResult class], ORKLegacyQuestionTypeText, TextValue)];
        [formItemResults addObject:getQuestionResult(NumericFormItemIdentifier, [ORKLegacyNumericQuestionResult class], ORKLegacyQuestionTypeInteger, @(IntegerValue))];
    } else {
        [formItemResults addObject:getQuestionResult(AdditionalTextFormItemIdentifier, [ORKLegacyTextQuestionResult class], ORKLegacyQuestionTypeText, AdditionalTextValue)];
        [formItemResults addObject:getQuestionResult(AdditionalNumericFormItemIdentifier, [ORKLegacyNumericQuestionResult class], ORKLegacyQuestionTypeInteger, @(AdditionalIntegerValue))];
    }
    
    ORKLegacyStepResult *formStepResult = [[ORKLegacyStepResult alloc] initWithStepIdentifier:(!isAdditionalTask ? FormStepIdentifier : AdditionalFormStepIdentifier) results:formItemResults];
    
    ORKLegacyTaskResult *taskResult = [[ORKLegacyTaskResult alloc] initWithTaskIdentifier:(!isAdditionalTask ? OrderedTaskIdentifier : AdditionalTaskIdentifier)
                                                                  taskRunUUID:[NSUUID UUID]
                                                              outputDirectory:[NSURL fileURLWithPath:NSTemporaryDirectory()]];
    taskResult.results = @[formStepResult];
    
    return taskResult;
}

- (ORKLegacyTaskResult *)getSmallTaskResultTreeWithDuplicateStepIdentifiers {
    NSMutableArray *stepResults = [NSMutableArray new];
    
    [stepResults addObject:getStepResult(TextStepIdentifier, [ORKLegacyTextQuestionResult class], ORKLegacyQuestionTypeText, TextValue)];
    [stepResults addObject:getStepResult(TextStepIdentifier, [ORKLegacyTextQuestionResult class], ORKLegacyQuestionTypeText, TextValue)];
    
    ORKLegacyTaskResult *taskResult = [[ORKLegacyTaskResult alloc] initWithTaskIdentifier:OrderedTaskIdentifier
                                                                  taskRunUUID:[NSUUID UUID]
                                                              outputDirectory:[NSURL fileURLWithPath:NSTemporaryDirectory()]];
    taskResult.results = stepResults;
    
    return taskResult;
}

- (void)testPredicateStepNavigationRule {
    NSPredicate *predicate = nil;
    NSPredicate *predicateA = nil;
    NSPredicate *predicateB = nil;
    ORKLegacyPredicateStepNavigationRule *predicateRule = nil;
    ORKLegacyTaskResult *taskResult = nil;
    ORKLegacyTaskResult *additionalTaskResult = nil;
    
    NSArray *resultPredicates = nil;
    NSArray *destinationStepIdentifiers = nil;
    NSString *defaultStepIdentifier = nil;
    
    ORKLegacyResultSelector *resultSelector = nil;
    
    {
        // Test predicate step navigation rule initializers
        resultSelector = [[ORKLegacyResultSelector alloc] initWithResultIdentifier:TextStepIdentifier];
        predicate = [ORKLegacyResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:TextValue];
        resultPredicates = @[ predicate ];
        destinationStepIdentifiers = @[ MatchedDestinationStepIdentifier ];
        predicateRule = [[ORKLegacyPredicateStepNavigationRule alloc] initWithResultPredicates:resultPredicates
                                                              destinationStepIdentifiers:destinationStepIdentifiers];
        
        XCTAssertEqualObjects(predicateRule.resultPredicates, ORKLegacyArrayCopyObjects(resultPredicates));
        XCTAssertEqualObjects(predicateRule.destinationStepIdentifiers, ORKLegacyArrayCopyObjects(destinationStepIdentifiers));
        XCTAssertNil(predicateRule.defaultStepIdentifier);
        
        defaultStepIdentifier = DefaultDestinationStepIdentifier;
        predicateRule = [[ORKLegacyPredicateStepNavigationRule alloc] initWithResultPredicates:resultPredicates
                                                              destinationStepIdentifiers:destinationStepIdentifiers
                                                                   defaultStepIdentifier:defaultStepIdentifier];
        
        XCTAssertEqualObjects(predicateRule.resultPredicates, ORKLegacyArrayCopyObjects(resultPredicates));
        XCTAssertEqualObjects(predicateRule.destinationStepIdentifiers, ORKLegacyArrayCopyObjects(destinationStepIdentifiers));
        XCTAssertEqualObjects(predicateRule.defaultStepIdentifier, defaultStepIdentifier);
    }
    
    {
        // Predicate matching, no additional task results, matching
        taskResult = [ORKLegacyTaskResult new];
        taskResult.identifier = OrderedTaskIdentifier;
        
        resultSelector = [[ORKLegacyResultSelector alloc] initWithResultIdentifier:TextStepIdentifier];
        predicate = [ORKLegacyResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:TextValue];
        predicateRule = [[ORKLegacyPredicateStepNavigationRule alloc] initWithResultPredicates:@[ predicate ]
                                                              destinationStepIdentifiers:@[ MatchedDestinationStepIdentifier ]
                                                                   defaultStepIdentifier:DefaultDestinationStepIdentifier];
        
        XCTAssertEqualObjects([predicateRule identifierForDestinationStepWithTaskResult:taskResult], DefaultDestinationStepIdentifier);
        
        taskResult = [self getSmallTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertEqualObjects([predicateRule identifierForDestinationStepWithTaskResult:taskResult], MatchedDestinationStepIdentifier);
    }
    
    {
        // Predicate matching, no additional task results, non matching
        resultSelector = [[ORKLegacyResultSelector alloc] initWithResultIdentifier:TextStepIdentifier];
        predicate = [ORKLegacyResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:OtherTextValue];
        predicateRule = [[ORKLegacyPredicateStepNavigationRule alloc] initWithResultPredicates:@[ predicate ]
                                                              destinationStepIdentifiers:@[ MatchedDestinationStepIdentifier ]
                                                                   defaultStepIdentifier:DefaultDestinationStepIdentifier];
        taskResult = [self getSmallTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertEqualObjects([predicateRule identifierForDestinationStepWithTaskResult:taskResult], DefaultDestinationStepIdentifier);
    }
    
    {
        NSPredicate *currentPredicate = nil;
        NSPredicate *additionalPredicate = nil;
        
        // Predicate matching, additional task results
        resultSelector = [[ORKLegacyResultSelector alloc] initWithResultIdentifier:TextStepIdentifier];
        currentPredicate = [ORKLegacyResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                                 expectedString:TextValue];
        
        resultSelector = [[ORKLegacyResultSelector alloc] initWithTaskIdentifier:AdditionalTaskIdentifier
                                                            resultIdentifier:AdditionalTextStepIdentifier];
        additionalPredicate = [ORKLegacyResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                                    expectedString:AdditionalTextValue];
        
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[currentPredicate, additionalPredicate]];
        predicateRule = [[ORKLegacyPredicateStepNavigationRule alloc] initWithResultPredicates:@[ predicate ]
                                                              destinationStepIdentifiers:@[ MatchedDestinationStepIdentifier ]
                                                                   defaultStepIdentifier:DefaultDestinationStepIdentifier];
        
        taskResult = [ORKLegacyTaskResult new];
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
        resultSelector = [[ORKLegacyResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                            resultIdentifier:TextFormItemIdentifier];
        predicateA = [ORKLegacyResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                           expectedString:TextValue];
        
        resultSelector = [[ORKLegacyResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                            resultIdentifier:NumericFormItemIdentifier];
        predicateB = [ORKLegacyResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                              expectedAnswer:IntegerValue];
        
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateA, predicateB]];
        predicateRule = [[ORKLegacyPredicateStepNavigationRule alloc] initWithResultPredicates:@[ predicate ]
                                                              destinationStepIdentifiers:@[ MatchedDestinationStepIdentifier ]
                                                                   defaultStepIdentifier:DefaultDestinationStepIdentifier];
        
        taskResult = [self getSmallFormTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertEqualObjects([predicateRule identifierForDestinationStepWithTaskResult:taskResult], MatchedDestinationStepIdentifier);
    }
    
    {
        // Form predicate matching, no additional task results, non matching
        resultSelector = [[ORKLegacyResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                            resultIdentifier:TextFormItemIdentifier];
        predicate = [ORKLegacyResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:OtherTextValue];
        predicateRule = [[ORKLegacyPredicateStepNavigationRule alloc] initWithResultPredicates:@[ predicate ]
                                                              destinationStepIdentifiers:@[ MatchedDestinationStepIdentifier ]
                                                                   defaultStepIdentifier:DefaultDestinationStepIdentifier];
        taskResult = [self getSmallFormTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertEqualObjects([predicateRule identifierForDestinationStepWithTaskResult:taskResult], DefaultDestinationStepIdentifier);
    }
    
    {
        NSPredicate *currentPredicate = nil;
        NSPredicate *additionalPredicate = nil;
        
        // Form predicate matching, additional task results
        resultSelector = [[ORKLegacyResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                            resultIdentifier:TextFormItemIdentifier];
        predicateA = [ORKLegacyResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                           expectedString:TextValue];
        
        resultSelector = [[ORKLegacyResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                            resultIdentifier:NumericFormItemIdentifier];
        predicateB = [ORKLegacyResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                              expectedAnswer:IntegerValue];
        
        currentPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateA, predicateB]];
        
        resultSelector = [[ORKLegacyResultSelector alloc] initWithTaskIdentifier:AdditionalTaskIdentifier
                                                              stepIdentifier:AdditionalFormStepIdentifier
                                                            resultIdentifier:AdditionalTextFormItemIdentifier];
        predicateA = [ORKLegacyResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                           expectedString:AdditionalTextValue];
        
        resultSelector = [[ORKLegacyResultSelector alloc] initWithTaskIdentifier:AdditionalTaskIdentifier
                                                              stepIdentifier:AdditionalFormStepIdentifier
                                                            resultIdentifier:AdditionalNumericFormItemIdentifier];
        predicateB = [ORKLegacyResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                              expectedAnswer:AdditionalIntegerValue];
        
        additionalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateA, predicateB]];
        
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[currentPredicate, additionalPredicate]];
        predicateRule = [[ORKLegacyPredicateStepNavigationRule alloc] initWithResultPredicates:@[ predicate ]
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
    ORKLegacyPredicateSkipStepNavigationRule *predicateRule = nil;
    ORKLegacyTaskResult *taskResult = nil;
    ORKLegacyTaskResult *additionalTaskResult = nil;
    
    ORKLegacyResultSelector *resultSelector = nil;
    
    {
        // Test predicate step navigation rule initializers
        resultSelector = [[ORKLegacyResultSelector alloc] initWithResultIdentifier:TextStepIdentifier];
        predicate = [ORKLegacyResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:TextValue];
        predicateRule = [[ORKLegacyPredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicate];
        XCTAssertEqualObjects(predicateRule.resultPredicate, predicate);
    }
    
    {
        // Predicate matching, no additional task results, matching
        taskResult = [ORKLegacyTaskResult new];
        taskResult.identifier = OrderedTaskIdentifier;
        
        resultSelector = [[ORKLegacyResultSelector alloc] initWithResultIdentifier:TextStepIdentifier];
        predicate = [ORKLegacyResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:TextValue];
        predicateRule = [[ORKLegacyPredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicate];
        
        XCTAssertFalse([predicateRule stepShouldSkipWithTaskResult:taskResult]);
        
        taskResult = [self getSmallTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertTrue([predicateRule stepShouldSkipWithTaskResult:taskResult]);
    }
    
    {
        // Predicate matching, no additional task results, non matching
        resultSelector = [[ORKLegacyResultSelector alloc] initWithResultIdentifier:TextStepIdentifier];
        predicate = [ORKLegacyResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:OtherTextValue];
        predicateRule = [[ORKLegacyPredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicate];
        taskResult = [self getSmallTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertFalse([predicateRule stepShouldSkipWithTaskResult:taskResult]);
    }

    {
        NSPredicate *currentPredicate = nil;
        NSPredicate *additionalPredicate = nil;
        
        // Predicate matching, additional task results
        resultSelector = [[ORKLegacyResultSelector alloc] initWithResultIdentifier:TextStepIdentifier];
        currentPredicate = [ORKLegacyResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                                 expectedString:TextValue];
        
        resultSelector = [[ORKLegacyResultSelector alloc] initWithTaskIdentifier:AdditionalTaskIdentifier
                                                          resultIdentifier:AdditionalTextStepIdentifier];
        additionalPredicate = [ORKLegacyResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                                    expectedString:AdditionalTextValue];
        
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[currentPredicate, additionalPredicate]];
        predicateRule = [[ORKLegacyPredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicate];
        
        taskResult = [ORKLegacyTaskResult new];
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
        resultSelector = [[ORKLegacyResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                          resultIdentifier:TextFormItemIdentifier];
        predicateA = [ORKLegacyResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                           expectedString:TextValue];
        
        resultSelector = [[ORKLegacyResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                          resultIdentifier:NumericFormItemIdentifier];
        predicateB = [ORKLegacyResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                              expectedAnswer:IntegerValue];
        
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateA, predicateB]];
        predicateRule = [[ORKLegacyPredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicate];
        
        taskResult = [self getSmallFormTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertTrue([predicateRule stepShouldSkipWithTaskResult:taskResult]);
    }

    {
        // Form predicate matching, no additional task results, non matching
        resultSelector = [[ORKLegacyResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                          resultIdentifier:TextFormItemIdentifier];
        predicate = [ORKLegacyResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:OtherTextValue];
        predicateRule = [[ORKLegacyPredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicate];
        
        taskResult = [self getSmallFormTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertFalse([predicateRule stepShouldSkipWithTaskResult:taskResult]);
    }
    
    {
        NSPredicate *currentPredicate = nil;
        NSPredicate *additionalPredicate = nil;
        
        // Form predicate matching, additional task results
        resultSelector = [[ORKLegacyResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                          resultIdentifier:TextFormItemIdentifier];
        predicateA = [ORKLegacyResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                           expectedString:TextValue];
        
        resultSelector = [[ORKLegacyResultSelector alloc] initWithStepIdentifier:FormStepIdentifier
                                                          resultIdentifier:NumericFormItemIdentifier];
        predicateB = [ORKLegacyResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                              expectedAnswer:IntegerValue];
        
        currentPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateA, predicateB]];
        
        resultSelector = [[ORKLegacyResultSelector alloc] initWithTaskIdentifier:AdditionalTaskIdentifier
                                                            stepIdentifier:AdditionalFormStepIdentifier
                                                          resultIdentifier:AdditionalTextFormItemIdentifier];
        predicateA = [ORKLegacyResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                           expectedString:AdditionalTextValue];
        
        resultSelector = [[ORKLegacyResultSelector alloc] initWithTaskIdentifier:AdditionalTaskIdentifier
                                                            stepIdentifier:AdditionalFormStepIdentifier
                                                          resultIdentifier:AdditionalNumericFormItemIdentifier];
        predicateB = [ORKLegacyResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                              expectedAnswer:AdditionalIntegerValue];
        
        additionalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateA, predicateB]];
        
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[currentPredicate, additionalPredicate]];
        predicateRule = [[ORKLegacyPredicateSkipStepNavigationRule alloc] initWithResultPredicate:predicate];
        
        taskResult = [self getSmallFormTaskResultTreeWithIsAdditionalTask:NO];
        XCTAssertFalse([predicateRule stepShouldSkipWithTaskResult:taskResult]);
        
        additionalTaskResult = [self getSmallFormTaskResultTreeWithIsAdditionalTask:YES];
        predicateRule.additionalTaskResults = @[ additionalTaskResult ];
        XCTAssertTrue([predicateRule stepShouldSkipWithTaskResult:taskResult]);
    }
}

- (void)testDirectStepNavigationRule {
    ORKLegacyDirectStepNavigationRule *directRule = nil;
    ORKLegacyTaskResult *mockTaskResult = [ORKLegacyTaskResult new];
    
    directRule = [[ORKLegacyDirectStepNavigationRule alloc] initWithDestinationStepIdentifier:MatchedDestinationStepIdentifier];
    XCTAssertEqualObjects(directRule.destinationStepIdentifier, [MatchedDestinationStepIdentifier copy] );
    XCTAssertEqualObjects([directRule identifierForDestinationStepWithTaskResult:mockTaskResult], [MatchedDestinationStepIdentifier copy]);
    
    directRule = [[ORKLegacyDirectStepNavigationRule alloc] initWithDestinationStepIdentifier:ORKLegacyNullStepIdentifier];
    XCTAssertEqualObjects(directRule.destinationStepIdentifier, [ORKLegacyNullStepIdentifier copy]);
    XCTAssertEqualObjects([directRule identifierForDestinationStepWithTaskResult:mockTaskResult], [ORKLegacyNullStepIdentifier copy]);
}

- (void)testResultPredicatesWithTaskIdentifier:(NSString *)taskIdentifier
                         substitutionVariables:(NSDictionary *)substitutionVariables
                                   taskResults:(NSArray *)taskResults {
    // ORKLegacyScaleQuestionResult
    ORKLegacyResultSelector *resultSelector = [[ORKLegacyResultSelector alloc] initWithTaskIdentifier:taskIdentifier
                                                                         resultIdentifier:@""];
    
    resultSelector.resultIdentifier = ScaleStepIdentifier;
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector
                                                                          expectedAnswer:IntegerValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector
                                                                           expectedAnswer:IntegerValue + 1] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    resultSelector.resultIdentifier = ContinuousScaleStepIdentifier;
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector
                                                              minimumExpectedAnswerValue:FloatValue - 0.01
                                                              maximumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector
                                                               minimumExpectedAnswerValue:FloatValue + 0.05
                                                               maximumExpectedAnswerValue:FloatValue + 0.06] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector
                                                              minimumExpectedAnswerValue:FloatValue - 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector
                                                               minimumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector
                                                              maximumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForScaleQuestionResultWithResultSelector:resultSelector
                                                               maximumExpectedAnswerValue:FloatValue - 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // ORKLegacyChoiceQuestionResult (strings)
    resultSelector.resultIdentifier = SingleChoiceStepIdentifier;
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                      expectedAnswerValue:SingleChoiceValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                       expectedAnswerValue:OtherTextValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    resultSelector.resultIdentifier = MultipleChoiceStepIdentifier;
    NSArray *expectedAnswers = nil;
    expectedAnswers = @[MultipleChoiceValue1];
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                     expectedAnswerValues:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    expectedAnswers = @[MultipleChoiceValue1, MultipleChoiceValue2];
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                     expectedAnswerValues:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    expectedAnswers = @[MultipleChoiceValue1, MultipleChoiceValue2, OtherTextValue];
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                      expectedAnswerValues:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    expectedAnswers = @[MultipleChoiceValue1, MultipleChoiceValue2, @(MultipleChoiceValue3)];
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                      expectedAnswerValues:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    resultSelector.resultIdentifier = MixedMultipleChoiceStepIdentifier;
    expectedAnswers = @[MultipleChoiceValue1];
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                     expectedAnswerValues:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    expectedAnswers = @[@(MultipleChoiceValue3)];
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                     expectedAnswerValues:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    expectedAnswers = @[MultipleChoiceValue1, MultipleChoiceValue2, @(MultipleChoiceValue3)];
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                     expectedAnswerValues:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    expectedAnswers = @[MultipleChoiceValue1, MultipleChoiceValue2, OtherTextValue];
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                      expectedAnswerValues:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // ORKLegacyChoiceQuestionResult (regular expressions)
    resultSelector.resultIdentifier = SingleChoiceStepIdentifier;
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                          matchingPattern:@"...gleChoiceValue"] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                       expectedAnswerValue:@"...SingleChoiceValue"] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    resultSelector.resultIdentifier = MultipleChoiceStepIdentifier;
    expectedAnswers = @[@"...tipleChoiceValue1", @"...tipleChoiceValue2"];
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                         matchingPatterns:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    expectedAnswers = @[@"...MultipleChoiceValue1", @"...MultipleChoiceValue2", @"...OtherTextValue"];
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                                          matchingPatterns:expectedAnswers] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // ORKLegacyBooleanQuestionResult
    resultSelector.resultIdentifier = BooleanStepIdentifier;
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForBooleanQuestionResultWithResultSelector:resultSelector
                                                                            expectedAnswer:BooleanValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForBooleanQuestionResultWithResultSelector:resultSelector
                                                                             expectedAnswer:!BooleanValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // ORKLegacyTextQuestionResult (strings)
    resultSelector.resultIdentifier = TextStepIdentifier;
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                         expectedString:TextValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                          expectedString:OtherTextValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // ORKLegacyTextQuestionResult (regular expressions)
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                        matchingPattern:@"...tValue"] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForTextQuestionResultWithResultSelector:resultSelector
                                                                         matchingPattern:@"...TextValue"] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // ORKLegacyNumericQuestionResult
    resultSelector.resultIdentifier = IntegerNumericStepIdentifier;
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                            expectedAnswer:IntegerValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                             expectedAnswer:IntegerValue + 1] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    resultSelector.resultIdentifier = FloatNumericStepIdentifier;
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                minimumExpectedAnswerValue:ORKLegacyIgnoreDoubleValue
                                                                maximumExpectedAnswerValue:ORKLegacyIgnoreDoubleValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                minimumExpectedAnswerValue:FloatValue - 0.01
                                                                maximumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                 minimumExpectedAnswerValue:FloatValue + 0.05
                                                                 maximumExpectedAnswerValue:FloatValue + 0.06] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                minimumExpectedAnswerValue:FloatValue - 0.01
                                                                maximumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                 minimumExpectedAnswerValue:FloatValue + 0.05
                                                                 maximumExpectedAnswerValue:FloatValue + 0.06] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                minimumExpectedAnswerValue:FloatValue - 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                 minimumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                maximumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                                 maximumExpectedAnswerValue:FloatValue - 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // ORKLegacyTimeOfDayQuestionResult
    resultSelector.resultIdentifier = TimeOfDayStepIdentifier;
    NSDateComponents *expectedDateComponentsMinimum = DateComponents();
    NSDateComponents *expectedDateComponentsMaximum = DateComponents();
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForTimeOfDayQuestionResultWithResultSelector:resultSelector
                                                                         minimumExpectedHour:expectedDateComponentsMinimum.hour
                                                                       minimumExpectedMinute:expectedDateComponentsMinimum.minute
                                                                         maximumExpectedHour:expectedDateComponentsMaximum.hour
                                                                       maximumExpectedMinute:expectedDateComponentsMaximum.minute] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    expectedDateComponentsMinimum.minute -= 2;
    expectedDateComponentsMaximum.minute += 2;
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForTimeOfDayQuestionResultWithResultSelector:resultSelector
                                                                         minimumExpectedHour:expectedDateComponentsMinimum.hour
                                                                       minimumExpectedMinute:expectedDateComponentsMinimum.minute
                                                                         maximumExpectedHour:expectedDateComponentsMaximum.hour
                                                                       maximumExpectedMinute:expectedDateComponentsMaximum.minute] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    expectedDateComponentsMinimum.minute += 3;
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForTimeOfDayQuestionResultWithResultSelector:resultSelector
                                                                          minimumExpectedHour:expectedDateComponentsMinimum.hour
                                                                        minimumExpectedMinute:expectedDateComponentsMinimum.minute
                                                                          maximumExpectedHour:expectedDateComponentsMaximum.hour
                                                                        maximumExpectedMinute:expectedDateComponentsMaximum.minute] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    expectedDateComponentsMinimum.minute -= 3;
    expectedDateComponentsMinimum.hour += 1;
    expectedDateComponentsMaximum.hour += 2;
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForTimeOfDayQuestionResultWithResultSelector:resultSelector
                                                                          minimumExpectedHour:expectedDateComponentsMinimum.hour
                                                                        minimumExpectedMinute:expectedDateComponentsMinimum.minute
                                                                          maximumExpectedHour:expectedDateComponentsMaximum.hour
                                                                        maximumExpectedMinute:expectedDateComponentsMaximum.minute] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // ORKLegacyTimeIntervalQuestionResult
    resultSelector.resultIdentifier = FloatNumericStepIdentifier;
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                     minimumExpectedAnswerValue:ORKLegacyIgnoreTimeIntervalValue
                                                                     maximumExpectedAnswerValue:ORKLegacyIgnoreTimeIntervalValue] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                     minimumExpectedAnswerValue:FloatValue - 0.01
                                                                     maximumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                      minimumExpectedAnswerValue:FloatValue + 0.05
                                                                      maximumExpectedAnswerValue:FloatValue + 0.06] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                     minimumExpectedAnswerValue:FloatValue - 0.01
                                                                     maximumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                      minimumExpectedAnswerValue:FloatValue + 0.05
                                                                      maximumExpectedAnswerValue:FloatValue + 0.06] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                     minimumExpectedAnswerValue:FloatValue - 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                      minimumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                     maximumExpectedAnswerValue:FloatValue + 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForTimeIntervalQuestionResultWithResultSelector:resultSelector
                                                                      maximumExpectedAnswerValue:FloatValue - 0.01] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // ORKLegacyDateQuestionResult
    resultSelector.resultIdentifier = DateStepIdentifier;
    NSDate *expectedDate = Date();
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForDateQuestionResultWithResultSelector:resultSelector
                                                              minimumExpectedAnswerDate:[expectedDate dateByAddingTimeInterval:-60]
                                                              maximumExpectedAnswerDate:[expectedDate dateByAddingTimeInterval:+60]] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForDateQuestionResultWithResultSelector:resultSelector
                                                               minimumExpectedAnswerDate:[expectedDate dateByAddingTimeInterval:+60]
                                                               maximumExpectedAnswerDate:[expectedDate dateByAddingTimeInterval:+120]] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForDateQuestionResultWithResultSelector:resultSelector
                                                              minimumExpectedAnswerDate:[expectedDate dateByAddingTimeInterval:-60]
                                                              maximumExpectedAnswerDate:nil] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForDateQuestionResultWithResultSelector:resultSelector
                                                               minimumExpectedAnswerDate:[expectedDate dateByAddingTimeInterval:+1]
                                                               maximumExpectedAnswerDate:nil] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForDateQuestionResultWithResultSelector:resultSelector
                                                              minimumExpectedAnswerDate:nil
                                                              maximumExpectedAnswerDate:[expectedDate dateByAddingTimeInterval:+60]] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForDateQuestionResultWithResultSelector:resultSelector
                                                               minimumExpectedAnswerDate:nil
                                                               maximumExpectedAnswerDate:[expectedDate dateByAddingTimeInterval:-1]] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForDateQuestionResultWithResultSelector:resultSelector
                                                              minimumExpectedAnswerDate:nil
                                                              maximumExpectedAnswerDate:nil] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    // Result with nil value
    resultSelector.resultIdentifier = NilTextStepIdentifier;
    XCTAssertTrue([[ORKLegacyResultPredicate predicateForNilQuestionResultWithResultSelector:resultSelector] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
    
    resultSelector.resultIdentifier = TextStepIdentifier;
    XCTAssertFalse([[ORKLegacyResultPredicate predicateForNilQuestionResultWithResultSelector:resultSelector] evaluateWithObject:taskResults substitutionVariables:substitutionVariables]);
}

- (void)testConsentPredicate {
    ORKLegacyResultSelector *resultSelector = [[ORKLegacyResultSelector alloc] initWithTaskIdentifier:OrderedTaskIdentifier
                                                                           stepIdentifier:SignConsentStepIdentifier
                                                                         resultIdentifier:SignatureIdentifier];
    {
        ORKLegacyTaskResult *consentedTaskResult = [self getTaskResultTreeWithConsent:YES];
        XCTAssertTrue([[ORKLegacyResultPredicate predicateForConsentWithResultSelector:resultSelector
                                                                      didConsent:YES] evaluateWithObject:@[consentedTaskResult] substitutionVariables:nil]);
        XCTAssertFalse([[ORKLegacyResultPredicate predicateForConsentWithResultSelector:resultSelector
                                                                       didConsent:NO] evaluateWithObject:@[consentedTaskResult] substitutionVariables:nil]);
    }
    
    {
        ORKLegacyTaskResult *didNotConsentTaskResult = [self getTaskResultTreeWithConsent:NO];
        
        XCTAssertTrue([[ORKLegacyResultPredicate predicateForConsentWithResultSelector:resultSelector
                                                                      didConsent:NO] evaluateWithObject:@[didNotConsentTaskResult] substitutionVariables:nil]);
        XCTAssertFalse([[ORKLegacyResultPredicate predicateForConsentWithResultSelector:resultSelector
                                                                       didConsent:YES] evaluateWithObject:@[didNotConsentTaskResult] substitutionVariables:nil]);
    }
}

- (void)testResultPredicates {
    ORKLegacyTaskResult *taskResult = [self getGeneralTaskResultTree];
    NSArray *taskResults = @[ taskResult ];
    
    // The following two calls are equivalent since 'substitutionVariables' are ignored when you provide a non-nil task identifier
    [self testResultPredicatesWithTaskIdentifier:OrderedTaskIdentifier
                           substitutionVariables:nil
                                     taskResults:taskResults];
    [self testResultPredicatesWithTaskIdentifier:OrderedTaskIdentifier
                           substitutionVariables:@{ORKLegacyResultPredicateTaskIdentifierVariableName: OrderedTaskIdentifier}
                                     taskResults:taskResults];
    // Test nil task identifier variable substitution
    [self testResultPredicatesWithTaskIdentifier:nil
                           substitutionVariables:@{ORKLegacyResultPredicateTaskIdentifierVariableName: OrderedTaskIdentifier}
                                     taskResults:taskResults];
}

- (void)testStepViewControllerWillDisappear {
    TestTaskViewControllerDelegate *delegate = [[TestTaskViewControllerDelegate alloc] init];
    ORKLegacyOrderedTask *task = [ORKLegacyOrderedTask twoFingerTappingIntervalTaskWithIdentifier:@"test" intendedUseDescription:nil duration:30 handOptions:0 options:0];
    ORKLegacyTaskViewController *taskViewController = [[MockTaskViewController alloc] initWithTask:task taskRunUUID:nil];
    taskViewController.delegate = delegate;
    ORKLegacyInstructionStepViewController *stepViewController = [[ORKLegacyInstructionStepViewController alloc] initWithStep:task.steps.firstObject];
    
    //-- call method under test
    [taskViewController stepViewController:stepViewController didFinishWithNavigationDirection:ORKLegacyStepViewControllerNavigationDirectionForward];
    
    // Check that the expected methods were called
    XCTAssertEqual(delegate.methodCalled.count, 1);
    XCTAssertEqualObjects(delegate.methodCalled.firstObject.selectorName, @"taskViewController:stepViewControllerWillDisappear:navigationDirection:");
    NSArray *expectedArgs = @[taskViewController, stepViewController, @(ORKLegacyStepViewControllerNavigationDirectionForward)];
    XCTAssertEqualObjects(delegate.methodCalled.firstObject.arguments, expectedArgs);
    
}

- (void)testIndexOfStep {
    ORKLegacyOrderedTask *task = [ORKLegacyOrderedTask twoFingerTappingIntervalTaskWithIdentifier:@"tapping" intendedUseDescription:nil duration:30 handOptions:0 options:0];
    
    // get the first step
    ORKLegacyStep *step0 = [task.steps firstObject];
    XCTAssertNotNil(step0);
    XCTAssertEqual([task indexOfStep:step0], 0);
    
    // get the second step
    ORKLegacyStep *step1 = [task stepWithIdentifier:ORKLegacyInstruction1StepIdentifier];
    XCTAssertNotNil(step1);
    XCTAssertEqual([task indexOfStep:step1], 1);
    
    // get the last step
    ORKLegacyStep *stepLast = [task.steps lastObject];
    XCTAssertNotNil(stepLast);
    XCTAssertEqual([task indexOfStep:stepLast], task.steps.count - 1);
    
    // Look for not found
    ORKLegacyStep *stepNF = [[ORKLegacyStep alloc] initWithIdentifier:@"foo"];
    XCTAssertEqual([task indexOfStep:stepNF], NSNotFound);
    
}

- (void)testAudioTask_WithSoundCheck {
    ORKLegacyNavigableOrderedTask *task = [ORKLegacyOrderedTask audioTaskWithIdentifier:@"audio" intendedUseDescription:nil speechInstruction:nil shortSpeechInstruction:nil duration:20 recordingSettings:nil checkAudioLevel:YES options:0];
    
    NSArray *expectedStepIdentifiers = @[ORKLegacyInstruction0StepIdentifier,
                                         ORKLegacyInstruction1StepIdentifier,
                                         ORKLegacyCountdownStepIdentifier,
                                         ORKLegacyAudioTooLoudStepIdentifier,
                                         ORKLegacyAudioStepIdentifier,
                                         ORKLegacyConclusionStepIdentifier];
    NSArray *stepIdentifiers = [task.steps valueForKey:@"identifier"];
    XCTAssertEqual(stepIdentifiers.count, expectedStepIdentifiers.count);
    XCTAssertEqualObjects(stepIdentifiers, expectedStepIdentifiers);
    
    XCTAssertNotNil([task navigationRuleForTriggerStepIdentifier:ORKLegacyCountdownStepIdentifier]);
    XCTAssertNotNil([task navigationRuleForTriggerStepIdentifier:ORKLegacyAudioTooLoudStepIdentifier]);
}

- (void)testAudioTask_NoSoundCheck {
    
    ORKLegacyNavigableOrderedTask *task = [ORKLegacyOrderedTask audioTaskWithIdentifier:@"audio" intendedUseDescription:nil speechInstruction:nil shortSpeechInstruction:nil duration:20 recordingSettings:nil checkAudioLevel:NO options:0];
    
    NSArray *expectedStepIdentifiers = @[ORKLegacyInstruction0StepIdentifier,
                                         ORKLegacyInstruction1StepIdentifier,
                                         ORKLegacyCountdownStepIdentifier,
                                         ORKLegacyAudioStepIdentifier,
                                         ORKLegacyConclusionStepIdentifier];
    NSArray *stepIdentifiers = [task.steps valueForKey:@"identifier"];
    XCTAssertEqual(stepIdentifiers.count, expectedStepIdentifiers.count);
    XCTAssertEqualObjects(stepIdentifiers, expectedStepIdentifiers);
    XCTAssertEqual(task.stepNavigationRules.count, 0);
}

- (void)testWalkBackAndForthTask_30SecondDuration {
    
    // Create the task
    ORKLegacyOrderedTask *task = [ORKLegacyOrderedTask walkBackAndForthTaskWithIdentifier:@"walking" intendedUseDescription:nil walkDuration:30 restDuration:30 options:0];
    
    // Check that the steps match the expected - If these change, it will affect the results and
    // could adversely impact existing studies that are expecting this step order.
    NSArray *expectedStepIdentifiers = @[ORKLegacyInstruction0StepIdentifier,
                                         ORKLegacyInstruction1StepIdentifier,
                                         ORKLegacyCountdownStepIdentifier,
                                         ORKLegacyShortWalkOutboundStepIdentifier,
                                         ORKLegacyShortWalkRestStepIdentifier,
                                         ORKLegacyConclusionStepIdentifier];
    XCTAssertEqual(task.steps.count, expectedStepIdentifiers.count);
    NSArray *stepIdentifiers = [task.steps valueForKey:@"identifier"];
    XCTAssertEqualObjects(stepIdentifiers, expectedStepIdentifiers);
    
    // Check that the active steps include speaking the halfway point
    ORKLegacyActiveStep *walkingStep = (ORKLegacyActiveStep *)[task stepWithIdentifier:ORKLegacyShortWalkOutboundStepIdentifier];
    XCTAssertTrue(walkingStep.shouldSpeakRemainingTimeAtHalfway);
    ORKLegacyActiveStep *restStep = (ORKLegacyActiveStep *)[task stepWithIdentifier:ORKLegacyShortWalkRestStepIdentifier];
    XCTAssertTrue(restStep.shouldSpeakRemainingTimeAtHalfway);
    
}

- (void)testWalkBackAndForthTask_15SecondDuration_NoRest {
    
    // Create the task
    ORKLegacyOrderedTask *task = [ORKLegacyOrderedTask walkBackAndForthTaskWithIdentifier:@"walking" intendedUseDescription:nil walkDuration:15 restDuration:0 options:0];
    
    // Check that the steps match the expected - If these change, it will affect the results and
    // could adversely impact existing studies that are expecting this step order.
    NSArray *expectedStepIdentifiers = @[ORKLegacyInstruction0StepIdentifier,
                                         ORKLegacyInstruction1StepIdentifier,
                                         ORKLegacyCountdownStepIdentifier,
                                         ORKLegacyShortWalkOutboundStepIdentifier,
                                         ORKLegacyConclusionStepIdentifier];
    XCTAssertEqual(task.steps.count, expectedStepIdentifiers.count);
    NSArray *stepIdentifiers = [task.steps valueForKey:@"identifier"];
    XCTAssertEqualObjects(stepIdentifiers, expectedStepIdentifiers);
    
    // Check that the active steps include speaking the halfway point
    ORKLegacyActiveStep *walkingStep = (ORKLegacyActiveStep *)[task stepWithIdentifier:ORKLegacyShortWalkOutboundStepIdentifier];
    XCTAssertFalse(walkingStep.shouldSpeakRemainingTimeAtHalfway);
    
}

#pragma mark - two-finger tapping with both hands

- (void)testTwoFingerTappingIntervalTaskWithIdentifier_TapHandOptionUndefined {
    
    ORKLegacyOrderedTask *task = [ORKLegacyOrderedTask twoFingerTappingIntervalTaskWithIdentifier:@"test"
                                                               intendedUseDescription:nil
                                                                             duration:10
                                                                          handOptions:0
                                                                              options:0];
    NSArray *expectedStepIdentifiers = @[ORKLegacyInstruction0StepIdentifier,
                                              ORKLegacyInstruction1StepIdentifier,
                                              ORKLegacyTappingStepIdentifier,
                                              ORKLegacyConclusionStepIdentifier];
    NSArray *stepIdentifiers = [task.steps valueForKey:@"identifier"];
    XCTAssertEqual(stepIdentifiers.count, expectedStepIdentifiers.count);
    XCTAssertEqualObjects(stepIdentifiers, expectedStepIdentifiers);
    
    ORKLegacyStep *tappingStep = [task stepWithIdentifier:ORKLegacyTappingStepIdentifier];
    XCTAssertFalse(tappingStep.optional);

}

- (void)testTwoFingerTappingIntervalTaskWithIdentifier_TapHandOptionLeft {
    
    ORKLegacyOrderedTask *task = [ORKLegacyOrderedTask twoFingerTappingIntervalTaskWithIdentifier:@"test"
                                                               intendedUseDescription:nil
                                                                             duration:10
                                                                          handOptions:ORKLegacyPredefinedTaskHandOptionLeft
                                                                              options:0];
    // Check assumption around how many steps
    XCTAssertEqual(task.steps.count, 4);
    
    // Check that none of the language or identifiers contain the word "right"
    for (ORKLegacyStep *step in task.steps) {
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
    ORKLegacyStep *instructionStep = [instructions firstObject];
    XCTAssertEqualObjects(instructionStep.title, @"Left Hand");
    XCTAssertEqualObjects(instructionStep.text, @"Put your phone on a flat surface. Use two fingers on your left hand to alternately tap the buttons on the screen. Tap one finger, then the other. Try to time your taps to be as even as possible. Keep tapping for 10 seconds.");
    
    // Look for the activity step
    NSArray *tappings = filteredSteps(@"tapping", @"left");
    XCTAssertEqual(tappings.count, 1);
    ORKLegacyStep *tappingStep = [tappings firstObject];
    XCTAssertEqualObjects(tappingStep.title, @"Tap the buttons using your LEFT hand.");
    XCTAssertFalse(tappingStep.optional);
    
}

- (void)testTwoFingerTappingIntervalTaskWithIdentifier_TapHandOptionRight {
    
    ORKLegacyOrderedTask *task = [ORKLegacyOrderedTask twoFingerTappingIntervalTaskWithIdentifier:@"test"
                                                               intendedUseDescription:nil
                                                                             duration:10
                                                                          handOptions:ORKLegacyPredefinedTaskHandOptionRight
                                                                              options:0];
    // Check assumption around how many steps
    XCTAssertEqual(task.steps.count, 4);
    
    // Check that none of the language or identifiers contain the word "right"
    for (ORKLegacyStep *step in task.steps) {
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
    ORKLegacyStep *instructionStep = [instructions firstObject];
    XCTAssertEqualObjects(instructionStep.title, @"Right Hand");
    XCTAssertEqualObjects(instructionStep.text, @"Put your phone on a flat surface. Use two fingers on your right hand to alternately tap the buttons on the screen. Tap one finger, then the other. Try to time your taps to be as even as possible. Keep tapping for 10 seconds.");
    
    // Look for the activity step
    NSArray *tappings = filteredSteps(@"tapping", @"right");
    XCTAssertEqual(tappings.count, 1);
    ORKLegacyStep *tappingStep = [tappings firstObject];
    XCTAssertEqualObjects(tappingStep.title, @"Tap the buttons using your RIGHT hand.");
    XCTAssertFalse(tappingStep.optional);
    
}

- (void)testTwoFingerTappingIntervalTaskWithIdentifier_TapHandOptionBoth {
    NSUInteger leftCount = 0;
    NSUInteger rightCount = 0;
    NSUInteger totalCount = 100;
    NSUInteger threshold = 30;
    
    for (int ii = 0; ii < totalCount; ii++) {
        ORKLegacyOrderedTask *task = [ORKLegacyOrderedTask twoFingerTappingIntervalTaskWithIdentifier:@"test"
                                                                   intendedUseDescription:nil
                                                                                 duration:10
                                                                              handOptions:ORKLegacyPredefinedTaskHandOptionBoth
                                                                                  options:0];
        ORKLegacyStep * (^filteredSteps)(NSString*, NSString*) = ^(NSString *part1, NSString *part2) {
            NSString *keyValue = [NSString stringWithFormat:@"%@.%@", part1, part2];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", NSStringFromSelector(@selector(identifier)), keyValue];
            return [[task.steps filteredArrayUsingPredicate:predicate] firstObject];
        };
        
        // Look for instruction steps
        ORKLegacyStep *rightInstructionStep = filteredSteps(@"instruction1", @"right");
        XCTAssertNotNil(rightInstructionStep);
        ORKLegacyStep *leftInstructionStep = filteredSteps(@"instruction1", @"left");
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
            ORKLegacyStep *rightTapStep = filteredSteps(@"tapping", @"right");
            XCTAssertNotNil(rightTapStep);
            XCTAssertEqualObjects(rightTapStep.title, @"Tap the buttons using your RIGHT hand.");
            XCTAssertTrue(rightTapStep.optional);
            
            ORKLegacyStep *leftTapStep = filteredSteps(@"tapping", @"left");
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
    ORKLegacyStep *boolStep = [ORKLegacyQuestionStep  questionStepWithIdentifier:@"question"
                                                               title:@"Yes or No"
                                                              answer:[ORKLegacyAnswerFormat booleanAnswerFormat]];
    
    ORKLegacyStep *nextStep = [[ORKLegacyInstructionStep alloc] initWithIdentifier:@"nextStep"];
    nextStep.title = @"Yes";

    ORKLegacyNavigableOrderedTask *task = [[ORKLegacyNavigableOrderedTask alloc] initWithIdentifier:NavigableOrderedTaskIdentifier
                                                                                  steps:@[boolStep, nextStep]];
    
    ORKLegacyResultSelector *resultSelector = [ORKLegacyResultSelector selectorWithStepIdentifier:@"question"
                                                                     resultIdentifier:@"question"];
    NSPredicate *predicate = [ORKLegacyResultPredicate predicateForBooleanQuestionResultWithResultSelector:resultSelector
                                                                                      expectedAnswer:NO];
    ORKLegacyStepModifier *stepModifier = [[ORKLegacyKeyValueStepModifier alloc] initWithResultPredicate:predicate
                                                                               keyValueMap:@{ @"title" : @"No" }];
    
    [task setStepModifier:stepModifier forStepIdentifier:@"nextStep"];
    
    // -- Check the title if the answer is YES
    ORKLegacyBooleanQuestionResult *result = [[ORKLegacyBooleanQuestionResult alloc] initWithIdentifier:@"question"];
    result.booleanAnswer = @(YES);
    ORKLegacyStepResult *stepResult = [[ORKLegacyStepResult alloc] initWithStepIdentifier:@"question" results:@[result]];
    ORKLegacyTaskResult *taskResult = [[ORKLegacyTaskResult alloc] initWithIdentifier:NavigableOrderedTaskIdentifier];
    taskResult.results = @[stepResult];
    
    // For the case where the answer is YES, then the title should be "Yes" (unmodified)
    ORKLegacyStep *yesStep = [task stepAfterStep:boolStep withResult:taskResult];
    XCTAssertEqualObjects(yesStep.title, @"Yes");
    
    // -- Check the title if the answer is NO
    result.booleanAnswer = @(NO);
    stepResult = [[ORKLegacyStepResult alloc] initWithStepIdentifier:@"question" results:@[result]];
    taskResult.results = @[stepResult];
    
    // For the case where the answer is NO, then the title should be modified to be "No"
    ORKLegacyStep *noStep = [task stepAfterStep:boolStep withResult:taskResult];
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

- (void)taskViewController:(ORKLegacyTaskViewController *)taskViewController didFinishWithReason:(ORKLegacyTaskViewControllerFinishReason)reason error:(NSError *)error {
    
    // Add results of method call
    MethodObject *obj = [[MethodObject alloc] init];
    obj.selectorName = NSStringFromSelector(@selector(taskViewController:didFinishWithReason:error:));
    obj.arguments = @[taskViewController ?: [NSNull null],
                      @(reason),
                      error ?: [NSNull null]];
    [self.methodCalled addObject:obj];
}

- (void)taskViewController:(ORKLegacyTaskViewController *)taskViewController stepViewControllerWillDisappear:(ORKLegacyStepViewController *)stepViewController navigationDirection:(ORKLegacyStepViewControllerNavigationDirection)direction {
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

- (void)flipToNextPageFrom:(ORKLegacyStepViewController *)fromController {
    // Add results of method call
    MethodObject *obj = [[MethodObject alloc] init];
    obj.selectorName = NSStringFromSelector(@selector(flipToNextPageFrom:));
    obj.arguments = @[fromController ?: [NSNull null]];
    [self.methodCalled addObject:obj];
}

- (void)flipToPreviousPageFrom:(ORKLegacyStepViewController *)fromController {
    // Add results of method call
    MethodObject *obj = [[MethodObject alloc] init];
    obj.selectorName = NSStringFromSelector(@selector(flipToPreviousPageFrom:));
    obj.arguments = @[fromController ?: [NSNull null]];
    [self.methodCalled addObject:obj];
}

@end
