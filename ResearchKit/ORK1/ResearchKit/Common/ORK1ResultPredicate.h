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


@import Foundation;
#import <ResearchKit/ORK1Defines.h>


NS_ASSUME_NONNULL_BEGIN

ORK1_EXTERN NSString *const ORK1ResultPredicateTaskIdentifierVariableName ORK1_AVAILABLE_DECL;

#define ORK1IgnoreDoubleValue (NAN)
#define ORK1IgnoreTimeIntervalValue (ORK1IgnoreDoubleValue)

/**
 The `ORK1ResultSelector` class unequivocally identifies a result within a set of task results.
 
 You must use an instance of this object to specify the question result you are interested in when
 building a result predicate. See `ORK1ResultPredicate` for more information.
 
 A result selector object contains a result identifier and, optionally, a task identifier and a step
 identifier. If the task identifier is `nil`, the selector refers to a result in the ongoing task.
 If you set the step identifier to `nil`, its value will be the same as the result identifier.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1ResultSelector : NSObject <NSSecureCoding, NSCopying>

/*
 The `init` and `new` methods are unavailable.
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 Returns a result selector initialized with the specified arguments.
 
 @param taskIdentifier      An optional task identifier string.
 @param stepIdentifier      An optional step identifier string.
 @param resultIdentifier    The result identifier string.
 
 @return A result selector.
 */
+ (instancetype)selectorWithTaskIdentifier:(nullable NSString *)taskIdentifier
                            stepIdentifier:(nullable NSString *)stepIdentifier
                          resultIdentifier:(NSString *)resultIdentifier;

/**
 Returns a result selector initialized with the specified arguments.
 
 @param taskIdentifier      An optional task identifier string.
 @param resultIdentifier    The result identifier string.
 
 @return A result selector.
 */
+ (instancetype)selectorWithTaskIdentifier:(nullable NSString *)taskIdentifier
                          resultIdentifier:(NSString *)resultIdentifier;

/**
 Returns a result selector initialized with the specified arguments.
 
 @param stepIdentifier      An optional step identifier string.
 @param resultIdentifier    The result identifier string.
 
 @return A result selector.
 */
+ (instancetype)selectorWithStepIdentifier:(nullable NSString *)stepIdentifier
                          resultIdentifier:(NSString *)resultIdentifier;

/**
 Returns a result selector initialized with the specified arguments.
 
 @param resultIdentifier    The result identifier string.
 
 @return A result selector.
 */
+ (instancetype)selectorWithResultIdentifier:(NSString *)resultIdentifier;

/**
 Returns a result selector initialized with the specified arguments.
 
 @param taskIdentifier      An optional task identifier string.
 @param stepIdentifier      An optional step identifier string.
 @param resultIdentifier    The result identifier string.
 
 @return A result selector.
 */
- (instancetype)initWithTaskIdentifier:(nullable NSString *)taskIdentifier
                        stepIdentifier:(nullable NSString *)stepIdentifier
                      resultIdentifier:(NSString *)resultIdentifier NS_DESIGNATED_INITIALIZER;

/**
 Returns a result selector initialized with the specified arguments.
 
 @param taskIdentifier      An optional task identifier string.
 @param resultIdentifier    The result identifier string.
 
 @return A result selector.
 */
- (instancetype)initWithTaskIdentifier:(nullable NSString *)taskIdentifier
                      resultIdentifier:(NSString *)resultIdentifier;

/**
 Returns a result selector initialized with the specified arguments.
 
 @param stepIdentifier      An optional step identifier string.
 @param resultIdentifier    The result identifier string.
 
 @return A result selector.
 */
- (instancetype)initWithStepIdentifier:(nullable NSString *)stepIdentifier
                      resultIdentifier:(NSString *)resultIdentifier;

/**
 Returns a result selector initialized with the specified arguments.
 
 @param resultIdentifier    The result identifier string.
 
 @return A result selector.
 */
- (instancetype)initWithResultIdentifier:(NSString *)resultIdentifier;

/**
 The encapsulated task identifier.
 
 A `nil` value means that the referenced task is the current one.
 */
@property (nonatomic, copy, nullable) NSString *taskIdentifier;

/**
 The encapsulated step identifier.
 
 Setting this property to `nil` makes it have the same value as the result identifier.
 */
@property (nonatomic, copy, nullable) NSString *stepIdentifier;

/**
 The encapsulated result identifier.
 
 This property cannot be `nil`.
 */
@property (nonatomic, copy) NSString *resultIdentifier;

@end


/**
 The `ORK1ResultPredicate` class provides convenience class methods to build predicates for most of
 the `ORK1QuestionResult` subtypes.
 
 You use result predicates to create `ORK1PredicateStepNavigationRule` objects. The result predicates
 are used to match specific ORK1QuestionResult instances (created in response to the participant's
 answers) and navigate accordingly. You can match results both in an ongoing task or in previously
 completed tasks.
 
 You chose which question result to match by using an `ORK1ResultSelector` object.

 Note that each `ORK1Step` object produces one `ORK1StepResult` collection object. A step
 result produced by an `ORK1QuestionStep` object contains one `ORK1QuestionResult` object which has

 the same identifier as the step that generated it. A step result produced by an `ORK1FormStep`
 object can contain one or more `ORK1QuestionResult` objects that have the identifiers of the
 `ORK1FormItem` objects that generated them.

 For matching a single-question step result, you only need to set the `resultIdentifier` when
 building the result selector object. The `stepIdentifier` will take the same value.
 
 For matching a form item result, you need to build a result selector with a `stepIdentifier` (the
 form step identifier) and a `resultIdentifier` (the form item result identifier).
 
 For matching results in the ongoing task, leave the `taskIdentifier` in the the form step identifier
 as `nil`. For matching results in different tasks, set the `taskIdentifier` appropriately.

 */
ORK1_CLASS_AVAILABLE
@interface ORK1ResultPredicate : NSObject

/*
 The `init` and `new` methods are unavailable. `ORK1ResultPredicate` only provides class methods and
 should not be instantiated.
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 Returns a predicate matching a result of the kind `ORK1QuestionResult` whose answer is `nil`.
 A question result has a `nil` answer if it was generated by a step that was skipped by
 the user or if it was part of a form step and the question was left unanswered.
 
 @param resultSelector      The result selector object which specifies the question result you are
 interested in.
 
 @return A result predicate.
 */
+ (NSPredicate *)predicateForNilQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector;

/**
 Returns a predicate matching a result of type `ORK1ScaleQuestionResult` whose answer is the
 specified integer value.
 
 @param resultSelector      The result selector object which specifies the question result you are
                                interested in.
 @param expectedAnswer      The expected integer value.
 
 @return A result predicate.
 */
+ (NSPredicate *)predicateForScaleQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                                    expectedAnswer:(NSInteger)expectedAnswer;

/**
 Returns a predicate matching a result of type `ORK1ScaleQuestionResult` whose answer is within the
 specified double values.
 
 @param resultSelector              The result selector object which specifies the question result
                                        you are interested in.
 @param minimumExpectedAnswerValue  The minimum expected double value. Pass `ORK1IgnoreDoubleValue`
                                        if you don't want to compare the answer against a maximum
                                        double value.
 @param maximumExpectedAnswerValue  The maximum expected double value. Pass `ORK1IgnoreDoubleValue`
                                        if you don't want to compare the answer against a maximum
                                        double value.
 
 @return A result predicate.
 */
+ (NSPredicate *)predicateForScaleQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                        minimumExpectedAnswerValue:(double)minimumExpectedAnswerValue
                                        maximumExpectedAnswerValue:(double)maximumExpectedAnswerValue;

/**
 Returns a predicate matching a result of type `ORK1ScaleQuestionResult` whose answer is greater than
 or equal to the specified double value.
 
 @param resultSelector              The result selector object which specifies the question result
                                        you are interested in.
 @param minimumExpectedAnswerValue  The minimum expected double value.
 
 @return A result predicate.
 */
+ (NSPredicate *)predicateForScaleQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                        minimumExpectedAnswerValue:(double)minimumExpectedAnswerValue;

/**
 Returns a predicate matching a result of type `ORK1ScaleQuestionResult` whose answer is less than or
 equal to the specified double value.
 
 @param resultSelector              The result selector object which specifies the question result
                                        you are interested in.
 @param maximumExpectedAnswerValue  The maximum expected double value.
 
 @return A result predicate.
 */
+ (NSPredicate *)predicateForScaleQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                        maximumExpectedAnswerValue:(double)maximumExpectedAnswerValue;

/**
 Returns a predicate matching a result of type `ORK1ChoiceQuestionResult` whose answer is equal to
 the specified object.
 
 @param resultSelector          The result selector object which specifies the question result you
                                    are interested in.
 @param expectedAnswerValue     The expected answer object.
 
 @return A result predicate.
 */
+ (NSPredicate *)predicateForChoiceQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                                expectedAnswerValue:(id<NSCopying, NSCoding, NSObject>)expectedAnswerValue;

/**
 Returns a predicate matching a result of type `ORK1ChoiceQuestionResult` whose answers are equal to
 the specified objects.
 
 @param resultSelector          The result selector object which specifies the question result you
                                    are interested in.
 @param expectedAnswerValues    An array with a some or of all of the expected answer objects.
 
 @return A result predicate.
 */
+ (NSPredicate *)predicateForChoiceQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                               expectedAnswerValues:(NSArray<id<NSCopying, NSCoding, NSObject>> *)expectedAnswerValues;

/**
 Returns a predicate matching a result of type `ORK1ChoiceQuestionResult` whose answer matches the
 specified regular expression pattern. This predicate can solely be used to match choice results
 which only contain string answers.
 
 @param resultSelector      The result selector object which specifies the question result you are
                                interested in.
 @param pattern             An ICU-compliant regular expression pattern that matches the answer string.
 
 @return A result predicate.
 */
+ (NSPredicate *)predicateForChoiceQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                                    matchingPattern:(NSString *)pattern;

/**
 Returns a predicate matching a result of type `ORK1ChoiceQuestionResult` whose answers match the
 specified regular expression patterns.
 
 @param resultSelector      The result selector object which specifies the question result you are
                                interested in.
 @param patterns            An array of ICU-compliant regular expression patterns that match the answer strings.
 
 @return A result predicate.
 */
+ (NSPredicate *)predicateForChoiceQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                                   matchingPatterns:(NSArray<NSString *> *)patterns;

/**
 Returns a predicate matching a result of type `ORK1BooleanQuestionResult` whose answer is the
 specified Boolean value.
 
 @param resultSelector      The result selector object which specifies the question result you are
                                interested in.
 @param expectedAnswer      The expected boolean value.
 
 @return A result predicate.
 */
+ (NSPredicate *)predicateForBooleanQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                                      expectedAnswer:(BOOL)expectedAnswer;

/**

 Returns a predicate matching a result of type `ORK1TextQuestionResult` whose answer is equal to the
 specified string.
 
 @param resultSelector      The result selector object which specifies the question result you are
                                interested in.
 @param expectedString      The expected result string.
 
 @return A result predicate.
 */
+ (NSPredicate *)predicateForTextQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                                   expectedString:(NSString *)expectedString;

/**
 Returns a predicate matching a result of type `ORK1TextQuestionResult` whose answer matches the
 specified regular expression pattern.
 
 @param resultSelector      The result selector object which specifies the question result you are
                                interested in.
 @param pattern             An ICU-compliant regular expression pattern that matches the answer string.
 
 @return A result predicate.
 */
+ (NSPredicate *)predicateForTextQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                                  matchingPattern:(NSString *)pattern;

/**
 Returns a predicate matching a result of type `ORK1NumericQuestionResult` whose answer is the
 specified integer value.
 
 @param resultSelector      The result selector object which specifies the question result you are
                                interested in.
 @param expectedAnswer      The expected integer value.
 
 @return A result predicate.
 */
+ (NSPredicate *)predicateForNumericQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                                      expectedAnswer:(NSInteger)expectedAnswer;

/**
 Returns a predicate matching a result of type `ORK1NumericQuestionResult` whose answer is within the
 specified double values.
 
 @param resultSelector              The result selector object which specifies the question result
                                        you are interested in.
 @param minimumExpectedAnswerValue  The minimum expected double value. Pass `ORK1IgnoreDoubleValue`
                                        if you don't want to compare the answer against a maximum
                                        double value.
 @param maximumExpectedAnswerValue  The maximum expected double value. Pass `ORK1IgnoreDoubleValue`
                                        if you don't want to compare the answer against a minimum
                                        double value.
 
 @return A result predicate.
 */
+ (NSPredicate *)predicateForNumericQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                          minimumExpectedAnswerValue:(double)minimumExpectedAnswerValue
                                          maximumExpectedAnswerValue:(double)maximumExpectedAnswerValue;

/**
 Returns a predicate matching a result of type `ORK1NumericQuestionResult` whose answer is greater
 than or equal to the specified double value.
 
 @param resultSelector              The result selector object which specifies the question result
                                        you are interested in.
 @param minimumExpectedAnswerValue  The minimum expected double value.
 
 @return A result predicate.
 */
+ (NSPredicate *)predicateForNumericQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                          minimumExpectedAnswerValue:(double)minimumExpectedAnswerValue;

/**
 Returns a predicate matching a result of type `ORK1NumericQuestionResult` whose answer is less than
 or equal to the specified double value.
 
 @param resultSelector              The result selector object which specifies the question result
                                        you are interested in.
 @param maximumExpectedAnswerValue  The maximum expected double value.
 
 @return A result predicate.
 */
+ (NSPredicate *)predicateForNumericQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                          maximumExpectedAnswerValue:(double)maximumExpectedAnswerValue;

/**
 Returns a predicate matching a result of type `ORK1TimeOfDayQuestionResult` whose answer is within
 the specified hour and minute values.
 
 Note that `ORK1TimeOfDayQuestionResult` internally stores its answer as an `NSDateComponents` object.
 If you are interested in additional components, you must build the predicate manually.
 
 @param resultSelector          The result selector object which specifies the question result you
                                    are interested in.
 @param minimumExpectedHour     The minimum expected hour component value.
 @param minimumExpectedMinute   The minimum expected minute component value.
 @param maximumExpectedHour     The maximum integer hour component value.
 @param maximumExpectedMinute   The maximum expected minute component value.
 
 @return A result predicate.
 */
+ (NSPredicate *)predicateForTimeOfDayQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                                   minimumExpectedHour:(NSInteger)minimumExpectedHour
                                                 minimumExpectedMinute:(NSInteger)minimumExpectedMinute
                                                   maximumExpectedHour:(NSInteger)maximumExpectedHour
                                                 maximumExpectedMinute:(NSInteger)maximumExpectedMinute;

/**
 Returns a predicate matching a result of type `ORK1TimeIntervalQuestionResult` whose answer is
within the specified `NSTimeInterval` values.
 
 @param resultSelector              The result selector object which specifies the question result
                                        you are interested in.
 @param minimumExpectedAnswerValue  The minimum expected `NSTimeInterval` value. Pass
                                        `ORK1IgnoreTimeIntervlValue` if you don't want to compare the
                                        answer against a maximum `NSTimeInterval` value.
 @param maximumExpectedAnswerValue  The maximum expected `NSTimeInterval` value. Pass
                                        `ORK1IgnoreTimeIntervlValue` if you don't want to compare the
                                        answer against a minimum `NSTimeInterval` value.
 
 @return A result predicate.
 */
+ (NSPredicate *)predicateForTimeIntervalQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                               minimumExpectedAnswerValue:(NSTimeInterval)minimumExpectedAnswerValue
                                               maximumExpectedAnswerValue:(NSTimeInterval)maximumExpectedAnswerValue;

/**
 Returns a predicate matching a result of type `ORK1TimeIntervalQuestionResult` whose answer is the
 specified integer value.
 
 @param resultSelector              The result selector object which specifies the question result
                                        you are interested in.
 @param minimumExpectedAnswerValue  The minimum expected `NSTimeInterval` value.
 
 @return A result predicate.
 */
+ (NSPredicate *)predicateForTimeIntervalQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                               minimumExpectedAnswerValue:(NSTimeInterval)minimumExpectedAnswerValue;

/**
 Returns a predicate matching a result of type `ORK1TimeIntervalQuestionResult` whose answer is the
 specified integer value.
 
 @param resultSelector              The result selector object which specifies the question result
                                        you are interested in.
 @param maximumExpectedAnswerValue  The maximum expected `NSTimeInterval` value.
 
 @return A result predicate.
 */
+ (NSPredicate *)predicateForTimeIntervalQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                               maximumExpectedAnswerValue:(NSTimeInterval)maximumExpectedAnswerValue;

/**
 Returns a predicate matching a result of type `ORK1DateQuestionResult` whose answer is a date within
 the specified dates.
 
 @param resultSelector              The result selector object which specifies the question result
                                        you are interested in.
 @param minimumExpectedAnswerDate   The minimum expected date. Pass `nil` if you don't want to
                                        compare the answer against a minimum date.
 @param maximumExpectedAnswerDate   The maximum expected date. Pass `nil` if you don't want to
                                        compare the answer against a maximum date.
 
 @return A result predicate.
 */
+ (NSPredicate *)predicateForDateQuestionResultWithResultSelector:(ORK1ResultSelector *)resultSelector
                                        minimumExpectedAnswerDate:(nullable NSDate *)minimumExpectedAnswerDate
                                        maximumExpectedAnswerDate:(nullable NSDate *)maximumExpectedAnswerDate;

/**
 Returns a predicate matching a result of type `ORK1ConsentSignatureResult` whose `consented` value 
 matches the specified boolean value.
 
 @param resultSelector              The result selector object which specifies the question result 
                                        you are interested in. Note that when creating this result
                                        selector you must provide the desired step identifier as the
                                        `stepIdentifier` argument and the corresponding signature
                                        identifier as the `resultIdentifier` argument). The step
                                        identifier will normally refer to the result of a
                                        `ORK1ConsentReviewStep` and the signature identifier will
                                        refer to the contained `ORK1ConsentSignatureResult`
                                        corresponding to the signature collected by the consent
                                        review step.
 @return A result predicate.
 */
+ (NSPredicate *)predicateForConsentWithResultSelector:(ORK1ResultSelector *)resultSelector
                                            didConsent:(BOOL)didConsent;

@end

NS_ASSUME_NONNULL_END
