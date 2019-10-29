/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
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


#import "ORKCollector.h"
#import "ORKCollector_Internal.h"
#import "ORKHelpers_Internal.h"
#import "HKSample+ORKJSONDictionary.h"
#import "CMMotionActivity+ORKJSONDictionary.h"
#import "ORKHealthSampleQueryOperation.h"
#import "ORKMotionActivityQueryOperation.h"
#import <CoreMotion/CoreMotion.h>


static NSString *const ItemsKey = @"items";
static NSString *const ItemIdentifierFormat = @"org.researchkit.%@";
static NSString *const ItemIdentifierFormatWithTwoPlaceholders = @"org.researchkit.%@.%@";

@implementation ORKLegacyCollector

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, identifier, NSString);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORKLegacy_ENCODE_OBJ(aCoder, identifier);
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super init];
    if (self) {
        _identifier = identifier;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    ORKLegacyCollector *collector = [[[self class] allocWithZone:zone] initWithIdentifier:_identifier];
    return collector;
}

- (NSData *)serializedDataForObjects:(NSArray *)objects {

    NSDictionary *output = @{ ItemsKey : [self serializableObjectsForObjects:objects] };
    
    NSError *localError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:output
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&localError];
    if (!jsonData) {
        [NSException raise:NSInternalInconsistencyException format:@"Error serializing objects to JSON: %@", [localError localizedDescription]];
        return nil;
    }
    
    return jsonData;
}

- (ORKLegacyOperation *)collectionOperationWithManager:(ORKLegacyDataCollectionManager *)mananger {
    ORKLegacyThrowMethodUnavailableException();
    return nil;
}

- (NSArray *)serializableObjectsForObjects:(NSArray *)objects {
    ORKLegacyThrowMethodUnavailableException();
    return nil;
}

- (BOOL)isEqual:(id)object {
    BOOL classEqual = [self class] == [object class];
    
    __typeof(self) castObject = object;
    return (classEqual &&
            ORKLegacyEqualObjects(_identifier, castObject.identifier));
}

@end


@implementation ORKLegacyHealthCollector : ORKLegacyCollector

- (instancetype)initWithSampleType:(HKSampleType*)sampleType unit:(HKUnit*)unit startDate:(NSDate*)startDate {
    NSString *itemIdentifier = [NSString stringWithFormat:ItemIdentifierFormatWithTwoPlaceholders, sampleType.identifier, unit.unitString];
    self = [super initWithIdentifier:itemIdentifier];
    if (self) {
        _sampleType = sampleType;
        _unit = unit;
        _startDate = startDate;
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ(aDecoder, sampleType);
        ORKLegacy_DECODE_OBJ(aDecoder, unit);
        ORKLegacy_DECODE_OBJ(aDecoder, startDate);
        ORKLegacy_DECODE_OBJ(aDecoder, lastAnchor);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    
    ORKLegacy_ENCODE_OBJ(aCoder, sampleType);
    ORKLegacy_ENCODE_OBJ(aCoder, unit);
    ORKLegacy_ENCODE_OBJ(aCoder, startDate);
    ORKLegacy_ENCODE_OBJ(aCoder, lastAnchor);
}

- (NSArray *)serializableObjectsForObjects:(NSArray<HKSample *> *)objects {
    NSMutableArray *elements = [NSMutableArray arrayWithCapacity:[objects count]];
    for (HKSample *sample in objects) {
        [elements addObject:[sample ork_JSONDictionaryWithOptions:(ORKLegacySampleJSONOptions)(ORKLegacySampleIncludeMetadata|ORKLegacySampleIncludeSource|ORKLegacySampleIncludeUUID) unit:self.unit]];
    }
    
    return elements;
}

- (ORKLegacyOperation*)collectionOperationWithManager:(ORKLegacyDataCollectionManager*)mananger {
    if (! [HKHealthStore isHealthDataAvailable]) {
        return nil;
    }
    
    return [[ORKLegacyHealthSampleQueryOperation alloc] initWithCollector:self mananger:mananger];
}

- (NSArray *)collectableSampleTypes {
    return @[_sampleType];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyHealthCollector *collector = [super copyWithZone:zone];
    collector->_startDate = self.startDate;
    collector->_sampleType = self.sampleType;
    collector->_unit = [self.unit copy];
    collector->_lastAnchor = self.lastAnchor;
    
    return collector;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORKLegacyEqualObjects(_sampleType, castObject.sampleType) &&
            ORKLegacyEqualObjects(_unit, castObject.unit) &&
            ORKLegacyEqualObjects(_startDate, castObject.startDate) &&
            ORKLegacyEqualObjects(_lastAnchor, castObject.lastAnchor));
}

@end


@implementation ORKLegacyHealthCorrelationCollector : ORKLegacyCollector

- (instancetype)initWithCorrelationType:(HKCorrelationType *)correlationType
                            sampleTypes:(NSArray *)sampleTypes
                                  units:(NSArray<HKUnit *> *)units
                              startDate:(NSDate *)startDate {
    NSString *itemIdentifier = [NSString stringWithFormat:ItemIdentifierFormat, correlationType.identifier];
    self = [super initWithIdentifier:itemIdentifier];
    if (self) {
        _correlationType = correlationType;
        _sampleTypes = sampleTypes;
        _units = units;
        _startDate = startDate;
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ(aDecoder, correlationType);
        ORKLegacy_DECODE_OBJ_ARRAY(aDecoder, sampleTypes, HKSampleType);
        ORKLegacy_DECODE_OBJ_ARRAY(aDecoder, units, HKUnit);
        ORKLegacy_DECODE_OBJ(aDecoder, startDate);
        ORKLegacy_DECODE_OBJ(aDecoder, lastAnchor);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    
    ORKLegacy_ENCODE_OBJ(aCoder, correlationType);
    ORKLegacy_ENCODE_OBJ(aCoder, sampleTypes);
    ORKLegacy_ENCODE_OBJ(aCoder, units);
    ORKLegacy_ENCODE_OBJ(aCoder, startDate);
    ORKLegacy_ENCODE_OBJ(aCoder, lastAnchor);
}

- (HKSampleType *)sampleType {
    return _correlationType;
}


- (NSArray *)collectableSampleTypes {
    return self.sampleTypes;
}


- (NSArray *)serializableObjectsForObjects:(NSArray<HKCorrelation *> *)objects {
    NSMutableArray *elements = [NSMutableArray arrayWithCapacity:[objects count]];
    for (HKCorrelation *correlation in objects) {
        [elements addObject:[correlation ork_JSONDictionaryWithOptions:(ORKLegacySampleJSONOptions)(ORKLegacySampleIncludeMetadata|ORKLegacySampleIncludeSource|ORKLegacySampleIncludeUUID) sampleTypes:self.sampleTypes units:self.units]];
    }
    
    return elements;
}

- (ORKLegacyOperation *)collectionOperationWithManager:(ORKLegacyDataCollectionManager *)manager {
    if (! [HKHealthStore isHealthDataAvailable]) {
        return nil;
    }
    
    return [[ORKLegacyHealthSampleQueryOperation alloc] initWithCollector:self mananger:manager];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyHealthCorrelationCollector *collector = [super copyWithZone:zone];
    collector->_startDate = self.startDate;
    collector->_correlationType = self.correlationType;
    collector->_sampleTypes = [self.sampleTypes copy];
    collector->_units = [self.units copy];
    collector->_lastAnchor = self.lastAnchor;
    
    return collector;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORKLegacyEqualObjects(_correlationType, castObject.correlationType) &&
            ORKLegacyEqualObjects(_sampleTypes, castObject.sampleTypes) &&
            ORKLegacyEqualObjects(_units, castObject.units) &&
            ORKLegacyEqualObjects(_startDate, castObject.startDate) &&
            ORKLegacyEqualObjects(_lastAnchor, castObject.lastAnchor));
}

@end


@implementation ORKLegacyMotionActivityCollector : ORKLegacyCollector

- (instancetype)initWithStartDate:(NSDate *)startDate {
    NSString *itemIdentifier = [NSString stringWithFormat:ItemIdentifierFormat, @"activity"];
    self = [super initWithIdentifier:itemIdentifier];
    if (self) {
        _startDate = startDate;
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, startDate, NSDate);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, lastDate, NSDate);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, startDate);
    ORKLegacy_ENCODE_OBJ(aCoder, lastDate);
}

- (NSArray *)serializableObjectsForObjects:(NSArray<CMMotionActivity *> *)objects {
    // Expect an array of CMMotionActivity objects
    NSMutableArray *elements = [NSMutableArray arrayWithCapacity:[objects count]];
    for (CMMotionActivity *activity in objects) {
        [elements addObject:[activity ork_JSONDictionary]];
    }
    
    return elements;
}

- (ORKLegacyOperation *)collectionOperationWithManager:(ORKLegacyDataCollectionManager *)mananger {
    if (! [CMMotionActivityManager isActivityAvailable]) {
        return nil;
    }
    
    return [[ORKLegacyMotionActivityQueryOperation alloc] initWithCollector:self queryQueue:nil manager:mananger];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyMotionActivityCollector *collector = [super copyWithZone:zone];
    collector->_startDate = self.startDate;
    collector->_lastDate = self.lastDate;
    
    return collector;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORKLegacyEqualObjects(_startDate, castObject.startDate) &&
            ORKLegacyEqualObjects(_lastDate, castObject.lastDate));
}

@end

