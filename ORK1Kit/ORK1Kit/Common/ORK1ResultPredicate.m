/*
 Copyright (c) 2015, Ricardo Sánchez-Sáez.
 
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


#import "ORK1ResultPredicate.h"

#import "ORK1Helpers_Internal.h"


NSString *const ORK1ResultPredicateTaskIdentifierVariableName = @"ORK1_TASK_IDENTIFIER";


@interface ORK1ResultSelector ()

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end


@implementation ORK1ResultSelector

+ (instancetype)new {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    ORK1ThrowMethodUnavailableException();
}

+ (instancetype)selectorWithTaskIdentifier:(NSString *)taskIdentifier
                            stepIdentifier:(NSString *)stepIdentifier
                          resultIdentifier:(NSString *)resultIdentifier {
    return [[[self class] alloc] initWithTaskIdentifier:taskIdentifier
                                         stepIdentifier:stepIdentifier
                                       resultIdentifier:resultIdentifier];
}

+ (instancetype)selectorWithStepIdentifier:(NSString *)stepIdentifier
                          resultIdentifier:(NSString *)resultIdentifier {
    return [[[self class] alloc] initWithStepIdentifier:stepIdentifier
                                       resultIdentifier:resultIdentifier];
}

+ (instancetype)selectorWithTaskIdentifier:(NSString *)taskIdentifier
                          resultIdentifier:(NSString *)resultIdentifier {
    return [[[self class] alloc] initWithTaskIdentifier:taskIdentifier
                                       resultIdentifier:resultIdentifier];
}

+ (instancetype)selectorWithResultIdentifier:(NSString *)resultIdentifier {
    return [[[self class] alloc] initWithResultIdentifier:resultIdentifier];
}

- (instancetype)initWithTaskIdentifier:(NSString *)taskIdentifier
                        stepIdentifier:(NSString *)stepIdentifier
                      resultIdentifier:(NSString *)resultIdentifier {
    if (self = [super init]) {
        _taskIdentifier = [taskIdentifier copy];
        _stepIdentifier = [stepIdentifier copy];
        _resultIdentifier = [resultIdentifier copy];
    }
    return self;
}

- (instancetype)initWithTaskIdentifier:(NSString *)taskIdentifier
                      resultIdentifier:(NSString *)resultIdentifier {
    return [self initWithTaskIdentifier:taskIdentifier
                         stepIdentifier:nil
                       resultIdentifier:resultIdentifier];
}

- (instancetype)initWithStepIdentifier:(NSString *)stepIdentifier
                      resultIdentifier:(NSString *)resultIdentifier {
    return [self initWithTaskIdentifier:nil
                         stepIdentifier:stepIdentifier
                       resultIdentifier:resultIdentifier];
}


- (instancetype)initWithResultIdentifier:(NSString *)resultIdentifier {
    return [self initWithTaskIdentifier:nil
                         stepIdentifier:nil
                       resultIdentifier:resultIdentifier];
}

- (NSString *)stepIdentifier {
    NSString *stepIdentifier = nil;
    if (_stepIdentifier) {
        stepIdentifier = _stepIdentifier;
    } else {
        stepIdentifier = _resultIdentifier;
    }
    return stepIdentifier;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    __typeof(self) resultIdentifier = [[[self class] allocWithZone:zone] initWithTaskIdentifier:_taskIdentifier
                                                                                 stepIdentifier:_stepIdentifier
                                                                               resultIdentifier:_resultIdentifier];
    return resultIdentifier;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return (ORK1EqualObjects(self.taskIdentifier, castObject.taskIdentifier)
            && ORK1EqualObjects(self.stepIdentifier, castObject.stepIdentifier)
            && ORK1EqualObjects(self.resultIdentifier, castObject.resultIdentifier));
}

- (NSUInteger)hash {
    return _taskIdentifier.hash ^ _stepIdentifier.hash ^ _resultIdentifier.hash;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, taskIdentifier, NSString);
        ORK1_DECODE_OBJ_CLASS(aDecoder, stepIdentifier, NSString);
        ORK1_DECODE_OBJ_CLASS(aDecoder, resultIdentifier, NSString);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORK1_ENCODE_OBJ(aCoder, taskIdentifier);
    ORK1_ENCODE_OBJ(aCoder, stepIdentifier);
    ORK1_ENCODE_OBJ(aCoder, resultIdentifier);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"{%@, %@, %@}",
            _taskIdentifier ? _taskIdentifier : @"<currentTask>",
            _stepIdentifier ? _stepIdentifier : _resultIdentifier,
            _resultIdentifier];
}

@end


@implementation ORK1ResultPredicate

+ (instancetype)new {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    ORK1ThrowMethodUnavailableException();
}

+ (NSPredicate *)predicateMatchingResultSelector:(ORK1ResultSelector *)resultSelector
                         subPredicateFormatArray:(NSArray *)subPredicateFormatArray
                 subPredicateFormatArgumentArray:(NSArray *)subPredicateFormatArgumentArray
                  areSubPredicateFormatsSubquery:(BOOL)areSubPredicateFormatsSubquery {
    ORK1ThrowInvalidArgumentExceptionIfNil(resultSelector);
    
    NSString *taskIdentifier = resultSelector.taskIdentifier;
    NSString *stepIdentifier = resultSelector.stepIdentifier;
    NSString *resultIdentifier = resultSelector.resultIdentifier;
    
    NSMutableString *format = [[NSMutableString alloc] init];
    NSMutableArray *formatArgumentArray = [[NSMutableArray alloc] init];
    
    // Match task identifier
    if (taskIdentifier) {
        [format appendString:@"SUBQUERY(SELF, $x, $x.identifier == %@"];
        [formatArgumentArray addObject:taskIdentifier];
    } else {
        // If taskIdentifier is nil, ORK1PredicateStepNavigationRule will substitute the
        // ORK1ResultPredicateTaskIdentifierSubstitutionVariableName variable by the identifier of the ongoing task
        [format appendFormat:@"SUBQUERY(SELF, $x, $x.identifier == $%@", ORK1ResultPredicateTaskIdentifierVariableName];
    }
    
    {
        // Match question result identifier
        [format appendString:@" AND SUBQUERY($x.results, $y, $y.identifier == %@ AND $y.isPreviousResult == NO AND SUBQUERY($y.results, $z, $z.identifier == %@"];
        [formatArgumentArray addObject:stepIdentifier];
        [formatArgumentArray addObject:resultIdentifier];
        {
            // Add question sub predicates. They can be normal predicates (for question results with only one answer)
            // or part of an additional subquery predicate (for question results with an array of answers, like ORK1ChoiceQuestionResult).
            for (NSString *subPredicateFormat in subPredicateFormatArray) {
                if (!areSubPredicateFormatsSubquery) {
                    if ([subPredicateFormat hasPrefix:@"("]) {
                        /*
                           For complex queries (e.g. TimeOfDay) where nested logic is needed, we will skip the $z. prefix
                           and allow the caller to handle. NOTE: caller will need to prefix any key references with '$z'
                         */
                        [format appendString:@" AND "];
                    } else {
                        [format appendString:@" AND $z."];
                    }
                    [format appendString:subPredicateFormat];
                } else {
                    [format appendString:@" AND SUBQUERY($z."];
                    [format appendString:subPredicateFormat];
                    [format appendString:@").@count > 0"];
                }
            }
            [formatArgumentArray addObjectsFromArray:subPredicateFormatArgumentArray];
        }
        [format appendString:@").@count > 0"];
        [format appendString:@").@count > 0"];
    }
    
    [format appendString:@").@count > 0"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:format argumentArray:formatArgumentArray];
    return predicate;
}

+ (NSPredicate *)predicateMatchingResultSelector:(ORK1ResultSelector *)resultSelector
                         subPredicateFormatArray:(NSArray *)subPredicateFormatArray
                 subPredicateFormatArgumentArray:(NSArray *)subPredicateFormatArgumentArray {
    return [self predicateMatchingResultSelector:resultSelector
                         subPredicateFormatArray:subPredicateFormatArray
                 subPredicateFormatArgumentArray:subPredicateFormatArgumentArray
                  areSubPredicateFormatsSubquery:NO];
}

+ (NSPredicate *)predicateForNilQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector {
    NSPredicate *nilPredicate = [self predicateMatchingResultSelector:resultSelector
                                              subPredicateFormatArray:@[ @"answer == nil" ]
                                      subPredicateFormatArgumentArray:@[ ]];
    NSPredicate *foundPredicate = [self predicateMatchingResultSelector:resultSelector
                                                subPredicateFormatArray:@[ ]
                                        subPredicateFormatArgumentArray:@[ ]];
    NSPredicate *notFoundPredicate = [NSCompoundPredicate notPredicateWithSubpredicate:foundPredicate];
    return [NSCompoundPredicate orPredicateWithSubpredicates:@[nilPredicate, notFoundPredicate]];
}

+ (NSPredicate *)predicateForScaleQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                                    expectedAnswer:(NSInteger)expectedAnswer {
    return [self predicateForNumericQuestionResultWithResultSelector:resultSelector
                                                      expectedAnswer:expectedAnswer];
}

+ (NSPredicate *)predicateForScaleQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                        minimumExpectedAnswerValue:(double)minimumExpectedAnswerValue
                                        maximumExpectedAnswerValue:(double)maximumExpectedAnswerValue {
    return [self predicateForNumericQuestionResultWithResultSelector:resultSelector
                                          minimumExpectedAnswerValue:minimumExpectedAnswerValue
                                          maximumExpectedAnswerValue:maximumExpectedAnswerValue];
}

+ (NSPredicate *)predicateForScaleQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                        minimumExpectedAnswerValue:(double)minimumExpectedAnswerValue {
    return [self predicateForNumericQuestionResultWithResultSelector:resultSelector
                                          minimumExpectedAnswerValue:minimumExpectedAnswerValue];
}

+ (NSPredicate *)predicateForScaleQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                        maximumExpectedAnswerValue:(double)maximumExpectedAnswerValue {
    return [self predicateForNumericQuestionResultWithResultSelector:resultSelector
                                          maximumExpectedAnswerValue:maximumExpectedAnswerValue];
}

+ (NSPredicate *)predicateForChoiceQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                                    expectedAnswers:(NSArray *)expectedAnswers
                                                        usePatterns:(BOOL)usePatterns {
    ORK1ThrowInvalidArgumentExceptionIfNil(expectedAnswers);
    if (expectedAnswers.count == 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"expectedAnswer cannot be empty." userInfo:nil];
    }
    
    NSMutableArray *subPredicateFormatArray = [NSMutableArray new];
    
    NSString *repeatingSubPredicateFormat =
    usePatterns ?
    @"answer, $w, $w matches %@" :
    @"answer, $w, $w == %@";
    
    for (NSInteger i = 0; i < expectedAnswers.count; i++) {
        [subPredicateFormatArray addObject:repeatingSubPredicateFormat];
    }
    
    return [self predicateMatchingResultSelector:resultSelector
                         subPredicateFormatArray:subPredicateFormatArray
                 subPredicateFormatArgumentArray:expectedAnswers
                  areSubPredicateFormatsSubquery:YES];
}

+ (NSPredicate *)predicateForChoiceQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                                expectedAnswerValue:(id<NSCopying, NSCoding, NSObject>)expectedAnswerValue {
    return [self predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                    expectedAnswers:@[ expectedAnswerValue ]
                                                        usePatterns:NO];
}

+ (NSPredicate *)predicateForChoiceQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                               expectedAnswerValues:(NSArray<id<NSCopying, NSCoding, NSObject>> *)expectedAnswerValues {
    return [self predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                    expectedAnswers:expectedAnswerValues
                                                        usePatterns:NO];
}

+ (NSPredicate *)predicateForChoiceQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                                    matchingPattern:(NSString *)pattern {
    return [self predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                    expectedAnswers:@[ pattern ]
                                                        usePatterns:YES];
}

+ (NSPredicate *)predicateForChoiceQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                                   matchingPatterns:(NSArray<NSString *> *)patterns {
    return [self predicateForChoiceQuestionResultWithResultSelector:resultSelector
                                                    expectedAnswers:patterns
                                                        usePatterns:YES];
}

+ (NSPredicate *)predicateForBooleanQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                                      expectedAnswer:(BOOL)expectedAnswer {
    return [self predicateMatchingResultSelector:resultSelector
                         subPredicateFormatArray:@[ @"answer == %@" ]
                 subPredicateFormatArgumentArray:@[ @(expectedAnswer) ]];
}

+ (NSPredicate *)predicateForTextQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                                   expectedString:(NSString *)expectedString {
    ORK1ThrowInvalidArgumentExceptionIfNil(expectedString);
    return [self predicateMatchingResultSelector:resultSelector
                         subPredicateFormatArray:@[ @"answer == %@" ]
                 subPredicateFormatArgumentArray:@[ expectedString ]];
}

+ (NSPredicate *)predicateForTextQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                                  matchingPattern:(NSString *)pattern {
    ORK1ThrowInvalidArgumentExceptionIfNil(pattern);
    return [self predicateMatchingResultSelector:resultSelector
                         subPredicateFormatArray:@[ @"answer matches %@" ]
                 subPredicateFormatArgumentArray:@[ pattern ]];
}

+ (NSPredicate *)predicateForWebViewStepResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                                  expectedString:(NSString *)expectedString {
    ORK1ThrowInvalidArgumentExceptionIfNil(expectedString);
    return [self predicateMatchingResultSelector:resultSelector
                         subPredicateFormatArray:@[ @"result == %@" ]
                 subPredicateFormatArgumentArray:@[ expectedString ]];
}

+ (NSPredicate *)predicateForWebViewStepResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                                 matchingPattern:(NSString *)pattern {
    ORK1ThrowInvalidArgumentExceptionIfNil(pattern);
    return [self predicateMatchingResultSelector:resultSelector
                         subPredicateFormatArray:@[ @"result matches %@" ]
                 subPredicateFormatArgumentArray:@[ pattern ]];
}

+ (NSPredicate *)predicateForNumericQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                                      expectedAnswer:(NSInteger)expectedAnswer {
    return [self predicateMatchingResultSelector:resultSelector
                         subPredicateFormatArray:@[ @"answer == %@" ]
                 subPredicateFormatArgumentArray:@[ @(expectedAnswer) ]];
}

+ (NSPredicate *)predicateForNumericQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                          minimumExpectedAnswerValue:(double)minimumExpectedAnswerValue
                                          maximumExpectedAnswerValue:(double)maximumExpectedAnswerValue {
    NSMutableArray *subPredicateFormatArray = [NSMutableArray new];
    NSMutableArray *subPredicateFormatArgumentArray = [NSMutableArray new];
    
    if (!isnan(minimumExpectedAnswerValue)) {
        [subPredicateFormatArray addObject:@"answer >= %@"];
        [subPredicateFormatArgumentArray addObject:@(minimumExpectedAnswerValue)];
    }
    if (!isnan(maximumExpectedAnswerValue)) {
        [subPredicateFormatArray addObject:@"answer <= %@"];
        [subPredicateFormatArgumentArray addObject:@(maximumExpectedAnswerValue)];
    }
    
    return [self predicateMatchingResultSelector:resultSelector
                         subPredicateFormatArray:subPredicateFormatArray
                 subPredicateFormatArgumentArray:subPredicateFormatArgumentArray];
}

+ (NSPredicate *)predicateForNumericQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                          minimumExpectedAnswerValue:(double)minimumExpectedAnswerValue {
    return [self predicateForNumericQuestionResultWithResultSelector:resultSelector
                                          minimumExpectedAnswerValue:minimumExpectedAnswerValue
                                          maximumExpectedAnswerValue:ORK1IgnoreDoubleValue];
}

+ (NSPredicate *)predicateForNumericQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                          maximumExpectedAnswerValue:(double)maximumExpectedAnswerValue {
    return [self predicateForNumericQuestionResultWithResultSelector:resultSelector
                                          minimumExpectedAnswerValue:ORK1IgnoreDoubleValue
                                          maximumExpectedAnswerValue:maximumExpectedAnswerValue];
}

+ (NSPredicate *)predicateForTimeOfDayQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                               minimumExpectedHour:(NSInteger)minimumExpectedHour
                                             minimumExpectedMinute:(NSInteger)minimumExpectedMinute
                                               maximumExpectedHour:(NSInteger)maximumExpectedHour
                                             maximumExpectedMinute:(NSInteger)maximumExpectedMinute {
return [self predicateMatchingResultSelector:resultSelector
                     subPredicateFormatArray:@[ @"($z.answer.hour > %@ OR ($z.answer.hour == %@ AND $z.answer.minute >= %@)) AND ($z.answer.hour < %@ OR ($z.answer.hour == %@ AND $z.answer.minute <= %@))" ]
             subPredicateFormatArgumentArray:@[ @(minimumExpectedHour),
                                                @(minimumExpectedHour),
                                                @(minimumExpectedMinute),
                                                @(maximumExpectedHour),
                                                @(maximumExpectedHour),
                                                @(maximumExpectedMinute) ]];
}

+ (NSPredicate *)predicateForTimeIntervalQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                               minimumExpectedAnswerValue:(NSTimeInterval)minimumExpectedAnswerValue
                                               maximumExpectedAnswerValue:(NSTimeInterval)maximumExpectedAnswerValue {
    return [self predicateForNumericQuestionResultWithResultSelector:resultSelector
                                          minimumExpectedAnswerValue:minimumExpectedAnswerValue
                                          maximumExpectedAnswerValue:maximumExpectedAnswerValue];
}

+ (NSPredicate *)predicateForTimeIntervalQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                               minimumExpectedAnswerValue:(NSTimeInterval)minimumExpectedAnswerValue {
    return [self predicateForNumericQuestionResultWithResultSelector:resultSelector
                                          minimumExpectedAnswerValue:minimumExpectedAnswerValue];
}

+ (NSPredicate *)predicateForTimeIntervalQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                               maximumExpectedAnswerValue:(NSTimeInterval)maximumExpectedAnswerValue {
    return [self predicateForNumericQuestionResultWithResultSelector:resultSelector
                                          maximumExpectedAnswerValue:maximumExpectedAnswerValue];
}

+ (NSPredicate *)predicateForDateQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                        minimumExpectedAnswerDate:(nullable NSDate *)minimumExpectedAnswerDate
                                        maximumExpectedAnswerDate:(nullable NSDate *)maximumExpectedAnswerDate {
    NSMutableArray *subPredicateFormatArray = [NSMutableArray new];
    NSMutableArray *subPredicateFormatArgumentArray = [NSMutableArray new];
    
    if (minimumExpectedAnswerDate) {
        [subPredicateFormatArray addObject:@"answer >= %@"];
        [subPredicateFormatArgumentArray addObject:minimumExpectedAnswerDate];
    }
    if (maximumExpectedAnswerDate) {
        [subPredicateFormatArray addObject:@"answer <= %@"];
        [subPredicateFormatArgumentArray addObject:maximumExpectedAnswerDate];
    }
    
    return [self predicateMatchingResultSelector:resultSelector
                         subPredicateFormatArray:subPredicateFormatArray
                 subPredicateFormatArgumentArray:subPredicateFormatArgumentArray];
}

+ (NSPredicate *)predicateForConsentWithResultSelector:(ORK1ResultSelector *)resultSelector didConsent:(BOOL)didConsent {
    return [self predicateMatchingResultSelector:resultSelector
                         subPredicateFormatArray:@[ @"consented == %@" ]
                 subPredicateFormatArgumentArray:@[ @(didConsent) ]];
}

@end
