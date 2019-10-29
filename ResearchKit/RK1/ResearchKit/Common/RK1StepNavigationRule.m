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


#import "RK1StepNavigationRule.h"
#import "RK1StepNavigationRule_Private.h"

#import "RK1Step.h"
#import "RK1Result.h"
#import "RK1ResultPredicate.h"

#import "RK1Helpers_Internal.h"


NSString *const RK1NullStepIdentifier = @"org.researchkit.step.null";

@implementation RK1StepNavigationRule

- (instancetype)init {
    if ([self isMemberOfClass:[RK1StepNavigationRule class]]) {
        RK1ThrowMethodUnavailableException();
    }
    return [super init];
}

- (NSString *)identifierForDestinationStepWithTaskResult:(RK1TaskResult *)taskResult {
    @throw [NSException exceptionWithName:NSGenericException reason:@"You should override this method in a subclass" userInfo:nil];
}

#pragma mark NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [super init];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    __typeof(self) rule = [[[self class] allocWithZone:zone] init];
    return rule;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    return YES;
}

@end


@interface RK1PredicateStepNavigationRule ()

@property (nonatomic, copy) NSArray<NSPredicate *> *resultPredicates;
@property (nonatomic, copy) NSArray<NSString *> *destinationStepIdentifiers;
@property (nonatomic, copy) NSString *defaultStepIdentifier;

@end


@implementation RK1PredicateStepNavigationRule

+ (instancetype)new {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    RK1ThrowMethodUnavailableException();
}

// Internal init without array validation, for serialization support
- (instancetype)initWithResultPredicates:(NSArray<NSPredicate *> *)resultPredicates
              destinationStepIdentifiers:(NSArray<NSString *> *)destinationStepIdentifiers
                   defaultStepIdentifier:(NSString *)defaultStepIdentifier
                          validateArrays:(BOOL)validateArrays {
    if (validateArrays) {
        RK1ThrowInvalidArgumentExceptionIfNil(resultPredicates);
        RK1ThrowInvalidArgumentExceptionIfNil(destinationStepIdentifiers);
        
        NSUInteger resultPredicatesCount = resultPredicates.count;
        NSUInteger destinationStepIdentifiersCount = destinationStepIdentifiers.count;
        if (resultPredicatesCount == 0) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"resultPredicates cannot be an empty array" userInfo:nil];
        }
        if (resultPredicatesCount != destinationStepIdentifiersCount) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Each predicate in resultPredicates must have a destination step identifier in destinationStepIdentifiers" userInfo:nil];
        }
        RK1ValidateArrayForObjectsOfClass(resultPredicates, [NSPredicate class], @"resultPredicates objects must be of a NSPredicate class kind");
        RK1ValidateArrayForObjectsOfClass(destinationStepIdentifiers, [NSString class], @"destinationStepIdentifiers objects must be of a NSString class kind");
        if (defaultStepIdentifier != nil && ![defaultStepIdentifier isKindOfClass:[NSString class]]) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"defaultStepIdentifier must be of a NSString class kind or nil" userInfo:nil];
        }
    }
    self = [super init];
    if (self) {
        _resultPredicates = [resultPredicates copy];
        _destinationStepIdentifiers = [destinationStepIdentifiers copy];
        _defaultStepIdentifier = [defaultStepIdentifier copy];
    }
    
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)initWithResultPredicates:(NSArray<NSPredicate *> *)resultPredicates
              destinationStepIdentifiers:(NSArray<NSString *> *)destinationStepIdentifiers
                   defaultStepIdentifier:(NSString *)defaultStepIdentifier {
    return [self initWithResultPredicates:resultPredicates
               destinationStepIdentifiers:destinationStepIdentifiers
                        defaultStepIdentifier:defaultStepIdentifier
                           validateArrays:YES];
}
#pragma clang diagnostic pop

- (instancetype)initWithResultPredicates:(NSArray<NSPredicate *> *)resultPredicates
              destinationStepIdentifiers:(NSArray<NSString *> *)destinationStepIdentifiers {
    return [self initWithResultPredicates:resultPredicates
               destinationStepIdentifiers:destinationStepIdentifiers
                    defaultStepIdentifier:nil];
}

static NSArray *RK1LeafQuestionResultsFromTaskResult(RK1TaskResult *RK1TaskResult) {
    NSMutableArray *leafResults = [NSMutableArray new];
    for (RK1Result *result in RK1TaskResult.results) {
        if ([result isKindOfClass:[RK1CollectionResult class]]) {
            [leafResults addObjectsFromArray:[(RK1CollectionResult *)result results]];
        }
    }
    return leafResults;
}

// the results array should only contain objects that respond to the 'identifier' method (e.g., RK1Result objects).
// Usually you want all result objects to be of the same type.
static void RK1ValidateIdentifiersUnique(NSArray *results, NSString *exceptionReason) {
    NSCParameterAssert(results);
    NSCParameterAssert(exceptionReason);

    NSArray *uniqueIdentifiers = [results valueForKeyPath:@"@distinctUnionOfObjects.identifier"];
    BOOL itemsHaveNonUniqueIdentifiers = (results.count != uniqueIdentifiers.count);
    if (itemsHaveNonUniqueIdentifiers) {
        @throw [NSException exceptionWithName:NSGenericException reason:exceptionReason userInfo:nil];
    }
}

- (void)setAdditionalTaskResults:(NSArray *)additionalTaskResults {
    for (RK1TaskResult *taskResult in additionalTaskResults) {
        RK1ValidateIdentifiersUnique(RK1LeafQuestionResultsFromTaskResult(taskResult), @"All question results should have unique identifiers");
    }
    _additionalTaskResults = additionalTaskResults;
}

- (NSString *)identifierForDestinationStepWithTaskResult:(RK1TaskResult *)taskResult {
    NSMutableArray *allTaskResults = [[NSMutableArray alloc] initWithObjects:taskResult, nil];
    if (_additionalTaskResults) {
        [allTaskResults addObjectsFromArray:_additionalTaskResults];
    }
    RK1ValidateIdentifiersUnique(allTaskResults, @"All tasks should have unique identifiers");

    NSString *destinationStepIdentifier = nil;
    for (NSInteger i = 0; i < _resultPredicates.count; i++) {
        NSPredicate *predicate = _resultPredicates[i];
        // The predicate can either have:
        // - an RK1ResultPredicateTaskIdentifierVariableName variable which will be substituted by the ongoing task identifier;
        // - a hardcoded task identifier set by the developer (the substitutionVariables dictionary is ignored in this case)
        if ([predicate evaluateWithObject:allTaskResults
                    substitutionVariables:@{RK1ResultPredicateTaskIdentifierVariableName: taskResult.identifier}]) {
            destinationStepIdentifier = _destinationStepIdentifiers[i];
            break;
        }
    }
    return destinationStepIdentifier ? : _defaultStepIdentifier;
}

#pragma mark NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        RK1_DECODE_OBJ_ARRAY(aDecoder, resultPredicates, NSPredicate);
        RK1_DECODE_OBJ_ARRAY(aDecoder, destinationStepIdentifiers, NSString);
        RK1_DECODE_OBJ_CLASS(aDecoder, defaultStepIdentifier, NSString);
        RK1_DECODE_OBJ_ARRAY(aDecoder, additionalTaskResults, RK1TaskResult);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_OBJ(aCoder, resultPredicates);
    RK1_ENCODE_OBJ(aCoder, destinationStepIdentifiers);
    RK1_ENCODE_OBJ(aCoder, defaultStepIdentifier);
    RK1_ENCODE_OBJ(aCoder, additionalTaskResults);
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    __typeof(self) rule = [[[self class] allocWithZone:zone] initWithResultPredicates:RK1ArrayCopyObjects(_resultPredicates)
                                                         destinationStepIdentifiers:RK1ArrayCopyObjects(_destinationStepIdentifiers)
                                                              defaultStepIdentifier:[_defaultStepIdentifier copy]
                                                                     validateArrays:YES];
    rule->_additionalTaskResults = RK1ArrayCopyObjects(_additionalTaskResults);
    return rule;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    __typeof(self) castObject = object;
    return (isParentSame
            && RK1EqualObjects(self.resultPredicates, castObject.resultPredicates)
            && RK1EqualObjects(self.destinationStepIdentifiers, castObject.destinationStepIdentifiers)
            && RK1EqualObjects(self.defaultStepIdentifier, castObject.defaultStepIdentifier)
            && RK1EqualObjects(self.additionalTaskResults, castObject.additionalTaskResults));
}

- (NSUInteger)hash {
    return _resultPredicates.hash ^ _destinationStepIdentifiers.hash ^ _defaultStepIdentifier.hash ^ _additionalTaskResults.hash;
}

@end


@interface RK1DirectStepNavigationRule ()

@property (nonatomic, copy) NSString *destinationStepIdentifier;

@end


@implementation RK1DirectStepNavigationRule

+ (instancetype)new {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)initWithDestinationStepIdentifier:(NSString *)destinationStepIdentifier {
    RK1ThrowInvalidArgumentExceptionIfNil(destinationStepIdentifier);
    self = [super init];
    if (self) {
        _destinationStepIdentifier = destinationStepIdentifier;
    }
    
    return self;
}

- (NSString *)identifierForDestinationStepWithTaskResult:(RK1TaskResult *)RK1TaskResult {
    return _destinationStepIdentifier;
}

#pragma mark NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        RK1_DECODE_OBJ_CLASS(aDecoder, destinationStepIdentifier, NSString);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_OBJ(aCoder, destinationStepIdentifier);
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    __typeof(self) rule = [[[self class] allocWithZone:zone] initWithDestinationStepIdentifier:[_destinationStepIdentifier copy]];
    return rule;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    __typeof(self) castObject = object;
    return (isParentSame
            && RK1EqualObjects(self.destinationStepIdentifier, castObject.destinationStepIdentifier));
}

- (NSUInteger)hash {
    return _destinationStepIdentifier.hash;
}

@end


@implementation RK1SkipStepNavigationRule

- (instancetype)init {
    if ([self isMemberOfClass:[RK1SkipStepNavigationRule class]]) {
        RK1ThrowMethodUnavailableException();
    }
    return [super init];
}

- (BOOL)stepShouldSkipWithTaskResult:(RK1TaskResult *)taskResult {
    @throw [NSException exceptionWithName:NSGenericException reason:@"You should override this method in a subclass" userInfo:nil];
}

#pragma mark NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [super init];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    typeof(self) rule = [[[self class] allocWithZone:zone] init];
    return rule;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    return YES;
}

@end


@interface RK1PredicateSkipStepNavigationRule()

@property (nonatomic) NSPredicate *resultPredicate;

@end


@implementation RK1PredicateSkipStepNavigationRule

+ (instancetype)new {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)initWithResultPredicate:(NSPredicate *)resultPredicate {
    RK1ThrowInvalidArgumentExceptionIfNil(resultPredicate);
    self = [super init];
    if (self) {
        _resultPredicate = resultPredicate;
    }
    
    return self;
}

- (void)setAdditionalTaskResults:(NSArray *)additionalTaskResults {
    for (RK1TaskResult *taskResult in additionalTaskResults) {
        RK1ValidateIdentifiersUnique(RK1LeafQuestionResultsFromTaskResult(taskResult), @"All question results should have unique identifiers");
    }
    _additionalTaskResults = additionalTaskResults;
}

- (BOOL)stepShouldSkipWithTaskResult:(RK1TaskResult *)taskResult {
    NSMutableArray *allTaskResults = [[NSMutableArray alloc] initWithObjects:taskResult, nil];
    if (_additionalTaskResults) {
        [allTaskResults addObjectsFromArray:_additionalTaskResults];
    }
    RK1ValidateIdentifiersUnique(allTaskResults, @"All tasks should have unique identifiers");
    
    // The predicate can either have:
    // - an RK1ResultPredicateTaskIdentifierVariableName variable which will be substituted by the ongoing task identifier;
    // - a hardcoded task identifier set by the developer (the substitutionVariables dictionary is ignored in this case)
    BOOL predicateDidMatch = [_resultPredicate evaluateWithObject:allTaskResults
                                           substitutionVariables:@{RK1ResultPredicateTaskIdentifierVariableName: taskResult.identifier}];
    return predicateDidMatch;
}

#pragma mark NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        RK1_DECODE_OBJ_CLASS(aDecoder, resultPredicate, NSPredicate);
        RK1_DECODE_OBJ_ARRAY(aDecoder, additionalTaskResults, RK1TaskResult);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_OBJ(aCoder, resultPredicate);
    RK1_ENCODE_OBJ(aCoder, additionalTaskResults);
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    typeof(self) rule = [[[self class] allocWithZone:zone] initWithResultPredicate:_resultPredicate];
    rule->_additionalTaskResults = RK1ArrayCopyObjects(_additionalTaskResults);
    return rule;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    __typeof(self) castObject = object;
    return (isParentSame
            && RK1EqualObjects(self.resultPredicate, castObject.resultPredicate)
            && RK1EqualObjects(self.additionalTaskResults, castObject.additionalTaskResults));
}

- (NSUInteger)hash {
    return _resultPredicate.hash ^ _additionalTaskResults.hash;
}

@end


@implementation RK1StepModifier

- (instancetype)init {
    if ([self isMemberOfClass:[RK1StepModifier class]]) {
        RK1ThrowMethodUnavailableException();
    }
    return [super init];
}

- (void)modifyStep:(RK1Step *)step withTaskResult:(RK1TaskResult *)taskResult {
    @throw [NSException exceptionWithName:NSGenericException reason:@"You should override this method in a subclass" userInfo:nil];
}

#pragma mark NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [super init];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    return [[[self class] allocWithZone:zone] init];
}

- (NSUInteger)hash {
    return [[self class] hash];
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    return YES;
}

@end


@implementation RK1KeyValueStepModifier

+ (instancetype)new {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)initWithResultPredicate:(NSPredicate *)resultPredicate
                           keyValueMap:(NSDictionary<NSString *, NSObject *> *)keyValueMap {
    RK1ThrowInvalidArgumentExceptionIfNil(resultPredicate);
    RK1ThrowInvalidArgumentExceptionIfNil(keyValueMap);
    self = [super init];
    if (self) {
        _resultPredicate = [resultPredicate copy];
        _keyValueMap = RK1MutableDictionaryCopyObjects(keyValueMap);
    }
    return self;
}

- (void)modifyStep:(RK1Step *)step withTaskResult:(RK1TaskResult *)taskResult {
    
    // The predicate can either have:
    // - an RK1ResultPredicateTaskIdentifierVariableName variable which will be substituted by the ongoing task identifier;
    // - a hardcoded task identifier set by the developer (the substitutionVariables dictionary is ignored in this case)
    BOOL predicateDidMatch = [_resultPredicate evaluateWithObject:@[taskResult]
                                            substitutionVariables:@{RK1ResultPredicateTaskIdentifierVariableName: taskResult.identifier}];
    if (predicateDidMatch) {
        for (NSString *key in self.keyValueMap.allKeys) {
            @try {
                [step setValue:self.keyValueMap[key] forKey:key];
            } @catch (NSException *exception) {
                NSAssert1(NO, @"You are attempting to set a key-value that is not key-value compliant. %@", exception);
            }
        }
    }
}

#pragma mark NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        RK1_DECODE_OBJ_CLASS(aDecoder, resultPredicate, NSPredicate);
        RK1_DECODE_OBJ_MUTABLE_DICTIONARY(aDecoder, keyValueMap, NSString, NSObject);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_OBJ(aCoder, resultPredicate);
    RK1_ENCODE_OBJ(aCoder, keyValueMap);
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    return [[[self class] allocWithZone:zone] initWithResultPredicate:self.resultPredicate
                                                          keyValueMap:self.keyValueMap];
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    __typeof(self) castObject = object;
    return (isParentSame
            && RK1EqualObjects(self.resultPredicate, castObject.resultPredicate)
            && RK1EqualObjects(self.keyValueMap, castObject.keyValueMap));
}

- (NSUInteger)hash {
    return _resultPredicate.hash ^ _keyValueMap.hash;
}

@end
