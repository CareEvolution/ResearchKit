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


#import "ORKStepNavigationRule.h"
#import "ORKStepNavigationRule_Private.h"

#import "ORKStep.h"
#import "ORKResult.h"
#import "ORKResultPredicate.h"

#import "ORKHelpers_Internal.h"


NSString *const ORKLegacyNullStepIdentifier = @"org.researchkit.step.null";

@implementation ORKLegacyStepNavigationRule

- (instancetype)init {
    if ([self isMemberOfClass:[ORKLegacyStepNavigationRule class]]) {
        ORKLegacyThrowMethodUnavailableException();
    }
    return [super init];
}

- (NSString *)identifierForDestinationStepWithTaskResult:(ORKLegacyTaskResult *)taskResult {
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


@interface ORKLegacyPredicateStepNavigationRule ()

@property (nonatomic, copy) NSArray<NSPredicate *> *resultPredicates;
@property (nonatomic, copy) NSArray<NSString *> *destinationStepIdentifiers;
@property (nonatomic, copy) NSString *defaultStepIdentifier;

@end


@implementation ORKLegacyPredicateStepNavigationRule

+ (instancetype)new {
    ORKLegacyThrowMethodUnavailableException();
}

- (instancetype)init {
    ORKLegacyThrowMethodUnavailableException();
}

// Internal init without array validation, for serialization support
- (instancetype)initWithResultPredicates:(NSArray<NSPredicate *> *)resultPredicates
              destinationStepIdentifiers:(NSArray<NSString *> *)destinationStepIdentifiers
                   defaultStepIdentifier:(NSString *)defaultStepIdentifier
                          validateArrays:(BOOL)validateArrays {
    if (validateArrays) {
        ORKLegacyThrowInvalidArgumentExceptionIfNil(resultPredicates);
        ORKLegacyThrowInvalidArgumentExceptionIfNil(destinationStepIdentifiers);
        
        NSUInteger resultPredicatesCount = resultPredicates.count;
        NSUInteger destinationStepIdentifiersCount = destinationStepIdentifiers.count;
        if (resultPredicatesCount == 0) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"resultPredicates cannot be an empty array" userInfo:nil];
        }
        if (resultPredicatesCount != destinationStepIdentifiersCount) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Each predicate in resultPredicates must have a destination step identifier in destinationStepIdentifiers" userInfo:nil];
        }
        ORKLegacyValidateArrayForObjectsOfClass(resultPredicates, [NSPredicate class], @"resultPredicates objects must be of a NSPredicate class kind");
        ORKLegacyValidateArrayForObjectsOfClass(destinationStepIdentifiers, [NSString class], @"destinationStepIdentifiers objects must be of a NSString class kind");
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

static NSArray *ORKLegacyLeafQuestionResultsFromTaskResult(ORKLegacyTaskResult *ORKLegacyTaskResult) {
    NSMutableArray *leafResults = [NSMutableArray new];
    for (ORKLegacyResult *result in ORKLegacyTaskResult.results) {
        if ([result isKindOfClass:[ORKLegacyCollectionResult class]]) {
            [leafResults addObjectsFromArray:[(ORKLegacyCollectionResult *)result results]];
        }
    }
    return leafResults;
}

// the results array should only contain objects that respond to the 'identifier' method (e.g., ORKLegacyResult objects).
// Usually you want all result objects to be of the same type.
static void ORKLegacyValidateIdentifiersUnique(NSArray *results, NSString *exceptionReason) {
    NSCParameterAssert(results);
    NSCParameterAssert(exceptionReason);

    NSArray *uniqueIdentifiers = [results valueForKeyPath:@"@distinctUnionOfObjects.identifier"];
    BOOL itemsHaveNonUniqueIdentifiers = (results.count != uniqueIdentifiers.count);
    if (itemsHaveNonUniqueIdentifiers) {
        @throw [NSException exceptionWithName:NSGenericException reason:exceptionReason userInfo:nil];
    }
}

- (void)setAdditionalTaskResults:(NSArray *)additionalTaskResults {
    for (ORKLegacyTaskResult *taskResult in additionalTaskResults) {
        ORKLegacyValidateIdentifiersUnique(ORKLegacyLeafQuestionResultsFromTaskResult(taskResult), @"All question results should have unique identifiers");
    }
    _additionalTaskResults = additionalTaskResults;
}

- (NSString *)identifierForDestinationStepWithTaskResult:(ORKLegacyTaskResult *)taskResult {
    NSMutableArray *allTaskResults = [[NSMutableArray alloc] initWithObjects:taskResult, nil];
    if (_additionalTaskResults) {
        [allTaskResults addObjectsFromArray:_additionalTaskResults];
    }
    ORKLegacyValidateIdentifiersUnique(allTaskResults, @"All tasks should have unique identifiers");

    NSString *destinationStepIdentifier = nil;
    for (NSInteger i = 0; i < _resultPredicates.count; i++) {
        NSPredicate *predicate = _resultPredicates[i];
        // The predicate can either have:
        // - an ORKLegacyResultPredicateTaskIdentifierVariableName variable which will be substituted by the ongoing task identifier;
        // - a hardcoded task identifier set by the developer (the substitutionVariables dictionary is ignored in this case)
        if ([predicate evaluateWithObject:allTaskResults
                    substitutionVariables:@{ORKLegacyResultPredicateTaskIdentifierVariableName: taskResult.identifier}]) {
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
        ORKLegacy_DECODE_OBJ_ARRAY(aDecoder, resultPredicates, NSPredicate);
        ORKLegacy_DECODE_OBJ_ARRAY(aDecoder, destinationStepIdentifiers, NSString);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, defaultStepIdentifier, NSString);
        ORKLegacy_DECODE_OBJ_ARRAY(aDecoder, additionalTaskResults, ORKLegacyTaskResult);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, resultPredicates);
    ORKLegacy_ENCODE_OBJ(aCoder, destinationStepIdentifiers);
    ORKLegacy_ENCODE_OBJ(aCoder, defaultStepIdentifier);
    ORKLegacy_ENCODE_OBJ(aCoder, additionalTaskResults);
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    __typeof(self) rule = [[[self class] allocWithZone:zone] initWithResultPredicates:ORKLegacyArrayCopyObjects(_resultPredicates)
                                                         destinationStepIdentifiers:ORKLegacyArrayCopyObjects(_destinationStepIdentifiers)
                                                              defaultStepIdentifier:[_defaultStepIdentifier copy]
                                                                     validateArrays:YES];
    rule->_additionalTaskResults = ORKLegacyArrayCopyObjects(_additionalTaskResults);
    return rule;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    __typeof(self) castObject = object;
    return (isParentSame
            && ORKLegacyEqualObjects(self.resultPredicates, castObject.resultPredicates)
            && ORKLegacyEqualObjects(self.destinationStepIdentifiers, castObject.destinationStepIdentifiers)
            && ORKLegacyEqualObjects(self.defaultStepIdentifier, castObject.defaultStepIdentifier)
            && ORKLegacyEqualObjects(self.additionalTaskResults, castObject.additionalTaskResults));
}

- (NSUInteger)hash {
    return _resultPredicates.hash ^ _destinationStepIdentifiers.hash ^ _defaultStepIdentifier.hash ^ _additionalTaskResults.hash;
}

@end


@interface ORKLegacyDirectStepNavigationRule ()

@property (nonatomic, copy) NSString *destinationStepIdentifier;

@end


@implementation ORKLegacyDirectStepNavigationRule

+ (instancetype)new {
    ORKLegacyThrowMethodUnavailableException();
}

- (instancetype)init {
    ORKLegacyThrowMethodUnavailableException();
}

- (instancetype)initWithDestinationStepIdentifier:(NSString *)destinationStepIdentifier {
    ORKLegacyThrowInvalidArgumentExceptionIfNil(destinationStepIdentifier);
    self = [super init];
    if (self) {
        _destinationStepIdentifier = destinationStepIdentifier;
    }
    
    return self;
}

- (NSString *)identifierForDestinationStepWithTaskResult:(ORKLegacyTaskResult *)ORKLegacyTaskResult {
    return _destinationStepIdentifier;
}

#pragma mark NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, destinationStepIdentifier, NSString);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, destinationStepIdentifier);
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
            && ORKLegacyEqualObjects(self.destinationStepIdentifier, castObject.destinationStepIdentifier));
}

- (NSUInteger)hash {
    return _destinationStepIdentifier.hash;
}

@end


@implementation ORKLegacySkipStepNavigationRule

- (instancetype)init {
    if ([self isMemberOfClass:[ORKLegacySkipStepNavigationRule class]]) {
        ORKLegacyThrowMethodUnavailableException();
    }
    return [super init];
}

- (BOOL)stepShouldSkipWithTaskResult:(ORKLegacyTaskResult *)taskResult {
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


@interface ORKLegacyPredicateSkipStepNavigationRule()

@property (nonatomic) NSPredicate *resultPredicate;

@end


@implementation ORKLegacyPredicateSkipStepNavigationRule

+ (instancetype)new {
    ORKLegacyThrowMethodUnavailableException();
}

- (instancetype)init {
    ORKLegacyThrowMethodUnavailableException();
}

- (instancetype)initWithResultPredicate:(NSPredicate *)resultPredicate {
    ORKLegacyThrowInvalidArgumentExceptionIfNil(resultPredicate);
    self = [super init];
    if (self) {
        _resultPredicate = resultPredicate;
    }
    
    return self;
}

- (void)setAdditionalTaskResults:(NSArray *)additionalTaskResults {
    for (ORKLegacyTaskResult *taskResult in additionalTaskResults) {
        ORKLegacyValidateIdentifiersUnique(ORKLegacyLeafQuestionResultsFromTaskResult(taskResult), @"All question results should have unique identifiers");
    }
    _additionalTaskResults = additionalTaskResults;
}

- (BOOL)stepShouldSkipWithTaskResult:(ORKLegacyTaskResult *)taskResult {
    NSMutableArray *allTaskResults = [[NSMutableArray alloc] initWithObjects:taskResult, nil];
    if (_additionalTaskResults) {
        [allTaskResults addObjectsFromArray:_additionalTaskResults];
    }
    ORKLegacyValidateIdentifiersUnique(allTaskResults, @"All tasks should have unique identifiers");
    
    // The predicate can either have:
    // - an ORKLegacyResultPredicateTaskIdentifierVariableName variable which will be substituted by the ongoing task identifier;
    // - a hardcoded task identifier set by the developer (the substitutionVariables dictionary is ignored in this case)
    BOOL predicateDidMatch = [_resultPredicate evaluateWithObject:allTaskResults
                                           substitutionVariables:@{ORKLegacyResultPredicateTaskIdentifierVariableName: taskResult.identifier}];
    return predicateDidMatch;
}

#pragma mark NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, resultPredicate, NSPredicate);
        ORKLegacy_DECODE_OBJ_ARRAY(aDecoder, additionalTaskResults, ORKLegacyTaskResult);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, resultPredicate);
    ORKLegacy_ENCODE_OBJ(aCoder, additionalTaskResults);
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    typeof(self) rule = [[[self class] allocWithZone:zone] initWithResultPredicate:_resultPredicate];
    rule->_additionalTaskResults = ORKLegacyArrayCopyObjects(_additionalTaskResults);
    return rule;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    __typeof(self) castObject = object;
    return (isParentSame
            && ORKLegacyEqualObjects(self.resultPredicate, castObject.resultPredicate)
            && ORKLegacyEqualObjects(self.additionalTaskResults, castObject.additionalTaskResults));
}

- (NSUInteger)hash {
    return _resultPredicate.hash ^ _additionalTaskResults.hash;
}

@end


@implementation ORKLegacyStepModifier

- (instancetype)init {
    if ([self isMemberOfClass:[ORKLegacyStepModifier class]]) {
        ORKLegacyThrowMethodUnavailableException();
    }
    return [super init];
}

- (void)modifyStep:(ORKLegacyStep *)step withTaskResult:(ORKLegacyTaskResult *)taskResult {
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


@implementation ORKLegacyKeyValueStepModifier

+ (instancetype)new {
    ORKLegacyThrowMethodUnavailableException();
}

- (instancetype)init {
    ORKLegacyThrowMethodUnavailableException();
}

- (instancetype)initWithResultPredicate:(NSPredicate *)resultPredicate
                           keyValueMap:(NSDictionary<NSString *, NSObject *> *)keyValueMap {
    ORKLegacyThrowInvalidArgumentExceptionIfNil(resultPredicate);
    ORKLegacyThrowInvalidArgumentExceptionIfNil(keyValueMap);
    self = [super init];
    if (self) {
        _resultPredicate = [resultPredicate copy];
        _keyValueMap = ORKLegacyMutableDictionaryCopyObjects(keyValueMap);
    }
    return self;
}

- (void)modifyStep:(ORKLegacyStep *)step withTaskResult:(ORKLegacyTaskResult *)taskResult {
    
    // The predicate can either have:
    // - an ORKLegacyResultPredicateTaskIdentifierVariableName variable which will be substituted by the ongoing task identifier;
    // - a hardcoded task identifier set by the developer (the substitutionVariables dictionary is ignored in this case)
    BOOL predicateDidMatch = [_resultPredicate evaluateWithObject:@[taskResult]
                                            substitutionVariables:@{ORKLegacyResultPredicateTaskIdentifierVariableName: taskResult.identifier}];
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
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, resultPredicate, NSPredicate);
        ORKLegacy_DECODE_OBJ_MUTABLE_DICTIONARY(aDecoder, keyValueMap, NSString, NSObject);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, resultPredicate);
    ORKLegacy_ENCODE_OBJ(aCoder, keyValueMap);
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
            && ORKLegacyEqualObjects(self.resultPredicate, castObject.resultPredicate)
            && ORKLegacyEqualObjects(self.keyValueMap, castObject.keyValueMap));
}

- (NSUInteger)hash {
    return _resultPredicate.hash ^ _keyValueMap.hash;
}

@end
