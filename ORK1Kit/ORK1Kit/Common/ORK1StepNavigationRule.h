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


@import Foundation;
#import <ORK1Kit/ORK1Defines.h>


NS_ASSUME_NONNULL_BEGIN

/**
 The `ORK1NullStepIdentifier` constant can be used as the destination step identifier for any
 `ORK1StepNavigationRule` concrete subclass to denote that the ongoing task should end after the
 navigation rule is triggered.
 */
ORK1_EXTERN NSString *const ORK1NullStepIdentifier ORK1_AVAILABLE_DECL;

NSString *const ORK1CancelStepIndentifier = @"FinishStep.Cancel";
NSString *const ORK1CancelAndSaveStepIdentifier = @"FinishStep.CancelAndSave";
NSString *const ORK1CancelAndDiscardStepIdentifier = @"FinishStep.CancelAndDiscard";
NSString *const ORK1CompleteStepIdentifier = @"FinishStep.Complete";

@class ORK1Step;
@class ORK1Result;
@class ORK1TaskResult;
@class ORK1ResultPredicate;

/**
 The `ORK1StepNavigationRule` class is the abstract base class for concrete step navigation rules.
 
 Step navigation rules can be used within an `ORK1NavigableOrderedTask` object. You assign step
 navigation rules to be triggered by the task steps. Each step can have one rule at most.

 Subclasses must implement the `identifierForDestinationStepWithTaskResult:` method, which returns
 the identifier of the destination step for the rule.
 
 Two concrete subclasses are included: `ORK1PredicateStepNavigationRule` can match any answer
 combination in the results of the ongoing task and jump accordingly; `ORK1DirectStepNavigationRule`
 unconditionally navigates to the step specified by the destination step identifier.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1StepNavigationRule : NSObject <NSCopying, NSSecureCoding>

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

/**
 Returns the target step identifier.
 
 Subclasses must implement this method to calculate the next step based on the passed task result.
 The `ORK1NullStepIdentifier` constant can be returned to indicate that the ongoing task should end
 after the step navigation rule is triggered.
 
 @param taskResult      The up-to-date task result, used for calculating the destination step.
 
 @return The identifier of the destination step.
 */
- (NSString *)identifierForDestinationStepWithTaskResult:(ORK1TaskResult *)taskResult;

@end


/**
 The `ORK1PredicateStepNavigationRule` can be used to match any answer combination in the results of
 the ongoing task (or in those of previously completed tasks) and jump accordingly. You must provide
 one or more result predicates (each predicate can match one or more step results within the task).
 
 Predicate step navigation rules contain an arbitrary number of result predicates with a
 corresponding number of destination step identifiers, plus an optional default step identifier that
 is used if none of the result predicates match. One result predicate can match one or more question
 results; if matching several question results, that predicate can belong to the same or to
 different task results). This rule allows you to define arbitrarily complex task navigation
 behaviors.
 
 The `ORK1ResultPredicate` class provides convenience class methods to build predicates for all the
 `ORK1QuestionResult` subtypes. Predicates must supply both the task result identifier and the
 question result identifier, in addition to one or more expected answers.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1PredicateStepNavigationRule : ORK1StepNavigationRule

/*
 The `init` and `new` methods are unavailable.
 
 `ORK1StepNavigationRule` classes should be initialized with custom designated initializers on each
 subclass.
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 Returns an initialized predicate step navigation rule using the specified result predicates,
 destination step identifiers, and an optional default step identifier.
 
 @param resultPredicates            An array of result predicates. Each result predicate can match
                                        one or more question results in the ongoing task result or
                                        in any of the additional task results.
 @param destinationStepIdentifiers  An array of possible destination step identifiers. This array
                                        must contain one step identifier for each of the predicates
                                        in the result predicates parameters. If you want for a
                                        certain predicate match to end te task, you achieve that by
                                        using the `ORK1NullStepIdentifier` constant.
 @param defaultStepIdentifier       The identifier of the step, which is used if none of the
                                        result predicates match. If this argument is `nil` and none
                                        of the predicates match, the default ordered task navigation
                                        behavior takes place (that is, the task goes to the next
                                        step in order).
 
 @return An initialized predicate step navigation rule.
 */
- (instancetype)initWithResultPredicates:(NSArray<NSPredicate *> *)resultPredicates
              destinationStepIdentifiers:(NSArray<NSString *> *)destinationStepIdentifiers
                   defaultStepIdentifier:(nullable NSString *)defaultStepIdentifier NS_DESIGNATED_INITIALIZER NS_SWIFT_UNAVAILABLE("Use the Swift init(resultPredicatesAndDestinationStepIdentifiers: [(NSPredicate, String)], defaultStepIdentifierOrNil: String?) initializer instead.");

/**
 Returns an initialized predicate step navigation rule using the specified result predicates and
 destination step identifiers.
 
 @param resultPredicates            An array of result predicates. Each result predicate can match
                                        one or more question results in the ongoing task result or
                                        in any of the additional task results.
 @param destinationStepIdentifiers  An array of possible destination step identifiers. This array
                                        must contain one step identifier for each of the predicates
                                        in the result predicates parameters.
 
 @return An initialized predicate step navigation rule.
 */
- (instancetype)initWithResultPredicates:(NSArray<NSPredicate *> *)resultPredicates
              destinationStepIdentifiers:(NSArray<NSString *> *)destinationStepIdentifiers NS_SWIFT_UNAVAILABLE("Use the Swift init(resultPredicatesAndDestinationStepIdentifiers: [(NSPredicate, String)], defaultStepIdentifierOrNil: String?) initializer instead.");

/**
 Returns a new predicate step navigation rule that was initialized from data in the given 
 unarchiver.
 
 @param aDecoder    The coder from which to initialize the step navigation rule.
 
 @return A new predicate step navigation rule.
 */
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

/**
 An optional array of additional task results.
 
 With this property, a task can have different navigation behavior depending on the results of
 related tasks that the user may have already completed. The predicate step navigation rule can use
 the question results within these tasks, in addition to the current task question results, to match
 the result predicates.
 
 You must ensure that all the task result identifiers are unique and that they are different from
 the ongoing task result identifier. Also ensure that no task result contains question
 results with duplicate identifiers. Question results *can have* equal identifiers provided that
 they belong to different task results.
 
 Each object in the array should be of the `ORK1TaskResult` class.
 */
@property (nonatomic, copy, nullable) NSArray<ORK1TaskResult *> *additionalTaskResults;

/**
 The array of result predicates. 
 
 @discussion This property contains one result predicate for each of the step identifiers in the
 `destinationStepIdentifiers` property.
*/
@property (nonatomic, copy, readonly) NSArray<NSPredicate *> *resultPredicates;

/**
 The array of destination step identifiers. It contains one step identifier for each of the
 predicates in the `resultPredicates` parameter.
 */
@property (nonatomic, copy, readonly) NSArray<NSString *> *destinationStepIdentifiers;

/**
 The identifier of the step that is used if none of the result predicates match.
 */
@property (nonatomic, copy, readonly, nullable) NSString *defaultStepIdentifier;

@end


/**
 The `ORK1DirectStepNavigationRule` class can be used to unconditionally jump to a destination step
 specified by its identifier or to finish the task early.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1DirectStepNavigationRule : ORK1StepNavigationRule

/*
 The `init` and `new` methods are unavailable.
 
 `ORK1StepNavigationRule` classes should be initialized with custom designated initializers on each
 subclass.
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 Returns an initialized direct-step navigation rule using the specified destination step identifier.
 
 @param destinationStepIdentifier   The identifier of the destination step. Pass the
                                        `ORK1NullStepIdentifier` constant if you want to finish the
                                        ongoing task when the direct-step navigation rule is
                                        triggered.
 
 @return A direct-step navigation rule.
 */
- (instancetype)initWithDestinationStepIdentifier:(NSString *)destinationStepIdentifier NS_DESIGNATED_INITIALIZER;

/**
 Returns a new direct-step navigation rule initialized from data in a given unarchiver.
 
 @param aDecoder    The coder from which to initialize the step navigation rule.
 
 @return A new direct-step navigation rule.
 */
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

/**
 The identifier of the destination step.
 */
@property (nonatomic, copy, readonly) NSString *destinationStepIdentifier;

@end


/**
 The `ORK1SkipStepNavigationRule` class is the abstract base class for concrete skip step navigation
 rules.
 
 Skip step navigation rules can be used within an `ORK1NavigableOrderedTask` object. You assign skip
 step navigation rules to be triggered before a task step is shown. Each step can have one skip rule
 at most.
 
 Subclasses must implement the `identifierForDestinationStepWithTaskResult:` method, which returns
 the identifier of the destination step for the rule.
 
 Two concrete subclasses are included: `ORK1PredicateStepNavigationRule` can match any answer
 combination in the results of the ongoing task and jump accordingly; `ORK1DirectStepNavigationRule`
 unconditionally navigates to the step specified by the destination step identifier.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1SkipStepNavigationRule : NSObject <NSCopying, NSSecureCoding>

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

/**
 Returns whether the targeted step should skip.
 
 Subclasses must implement this method to calculate if the targeted step should skip based on the
 passed task result.
 
 @param taskResult      The up-to-date task result, used for calculating whether the task should
                            skip.
 
 @return YES if the step should skip.
 */
- (BOOL)stepShouldSkipWithTaskResult:(ORK1TaskResult *)taskResult;

@end

ORK1_CLASS_AVAILABLE
@interface ORK1PredicateSkipStepNavigationRule : ORK1SkipStepNavigationRule

/*
 The `init` and `new` methods are unavailable.
 
 `ORK1StepNavigationRule` classes should be initialized with custom designated initializers on each
 subclass.
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 Returns an initialized predicate skip step navigation rule using the specified result predicate.
 
 @param resultPredicate     A result predicate. If the result predicate matches, the step
                                will skip.
 
 @return An initialized skip predicate step navigation rule.
 */
- (instancetype)initWithResultPredicate:(NSPredicate *)resultPredicate NS_DESIGNATED_INITIALIZER;

/**
 Returns a new predicate step navigation rule that was initialized from data in the given
 unarchiver.
 
 @param aDecoder    The coder from which to initialize the step navigation rule.
 
 @return A new predicate skip step navigation rule.
 */
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

/**
 An optional array of additional task results.
 
 With this property, a task can have different navigation behavior depending on the results of
 related tasks that the user may have already completed. The predicate skip step navigation rule can
 use the question results within these tasks, in addition to the current task question results, to
 match the result predicates.
 
 You must ensure that all the task result identifiers are unique and that they are different from
 the ongoing task result identifier. Also ensure that no task result contains question
 results with duplicate identifiers. Question results *can have* equal identifiers provided that
 they belong to different task results.
 
 Each object in the array should be of the `ORK1TaskResult` class.
 */
@property (nonatomic, copy, nullable) NSArray<ORK1TaskResult *> *additionalTaskResults;

/**
 The result predicate to match.
 */
@property (nonatomic, strong, readonly) NSPredicate *resultPredicate;

@end


/**
 The `ORK1StepModifier` class is an abstract base class for an object that can be used to modify a step
 if a given navigation rule is matched.
 
 Step modifiers can be used within an `ORK1NavigableOrderedTask` object. You assign step modifiers 
 to be triggered after a task step is shown. Each step can have one step modifier at most.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1StepModifier: NSObject <NSCopying, NSSecureCoding>

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

/**
 Modify the steps for a task.
 
 @param step            The step that is associated with this modifier
 @param taskResult      The current task result
 */
- (void)modifyStep:(ORK1Step *)step withTaskResult:(ORK1TaskResult *)taskResult;

@end


/**
 The `ORK1KeyValueStepModifier` class is an class for an object that can be used to modify a step
 if a given navigation rule is matched.
 
 Step modifiers can be used within an `ORK1NavigableOrderedTask` object. You assign step modifiers
 to be triggered after a task step is shown. Each step can have one step modifier at most.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1KeyValueStepModifier: ORK1StepModifier

/*
 The `init` and `new` methods are unavailable.
 
 `ORK1StepNavigationRule` classes should be initialized with custom designated initializers on each
 subclass.
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 The result predicate to match.
 */
@property (nonatomic, strong, readonly) NSPredicate *resultPredicate;

/**
 A key-value mapping to apply to the modified step if the result predicate matches.
 The keys in this are assumed to map using key-value coding.
 
 See https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/KeyValueCoding/
 */
@property (nonatomic, strong, readonly) NSDictionary<NSString *, NSObject *> *keyValueMap;

/**
 Returns a new step modifier.
 
 @param resultPredicate   The result predicate to use to determine if the step should be modified
 @param keyValueMap       The mapping dictionary for this object
 @return                  A new step modifier
 */
- (instancetype)initWithResultPredicate:(NSPredicate *)resultPredicate
                           keyValueMap:(NSDictionary<NSString *, NSObject *> *)keyValueMap NS_DESIGNATED_INITIALIZER;

/**
 Returns a new step modifier.
 
 @param aDecoder    The coder from which to initialize the step navigation rule.
 @return            A new step modifier
 */
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
