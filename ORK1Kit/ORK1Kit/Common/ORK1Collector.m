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


#import "ORK1Collector.h"
#import "ORK1Collector_Internal.h"
#import "ORK1Helpers_Internal.h"
#import "HKSample+ORK1JSONDictionary.h"
#import "CMMotionActivity+ORK1JSONDictionary.h"
#import "ORK1HealthSampleQueryOperation.h"
#import "ORK1MotionActivityQueryOperation.h"
#import <CoreMotion/CoreMotion.h>


static NSString *const ItemsKey = @"items";
static NSString *const ItemIdentifierFormat = @"org.researchkit.%@";
static NSString *const ItemIdentifierFormatWithTwoPlaceholders = @"org.researchkit.%@.%@";

@implementation ORK1Collector

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, identifier, NSString);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORK1_ENCODE_OBJ(aCoder, identifier);
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super init];
    if (self) {
        _identifier = identifier;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    ORK1Collector *collector = [[[self class] allocWithZone:zone] initWithIdentifier:_identifier];
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

- (ORK1Operation *)collectionOperationWithManager:(ORK1DataCollectionManager *)mananger {
    ORK1ThrowMethodUnavailableException();
    return nil;
}

- (NSArray *)serializableObjectsForObjects:(NSArray *)objects {
    ORK1ThrowMethodUnavailableException();
    return nil;
}

- (BOOL)isEqual:(id)object {
    BOOL classEqual = [self class] == [object class];
    
    __typeof(self) castObject = object;
    return (classEqual &&
            ORK1EqualObjects(_identifier, castObject.identifier));
}

@end


@implementation ORK1HealthCollector : ORK1Collector

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
        ORK1_DECODE_OBJ(aDecoder, sampleType);
        ORK1_DECODE_OBJ(aDecoder, unit);
        ORK1_DECODE_OBJ(aDecoder, startDate);
        ORK1_DECODE_OBJ(aDecoder, lastAnchor);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    
    ORK1_ENCODE_OBJ(aCoder, sampleType);
    ORK1_ENCODE_OBJ(aCoder, unit);
    ORK1_ENCODE_OBJ(aCoder, startDate);
    ORK1_ENCODE_OBJ(aCoder, lastAnchor);
}

- (NSArray *)serializableObjectsForObjects:(NSArray<HKSample *> *)objects {
    NSMutableArray *elements = [NSMutableArray arrayWithCapacity:[objects count]];
    for (HKSample *sample in objects) {
        [elements addObject:[sample ork_JSONDictionaryWithOptions:(ORK1SampleJSONOptions)(ORK1SampleIncludeMetadata|ORK1SampleIncludeSource|ORK1SampleIncludeUUID) unit:self.unit]];
    }
    
    return elements;
}

- (ORK1Operation*)collectionOperationWithManager:(ORK1DataCollectionManager*)mananger {
    if (! [HKHealthStore isHealthDataAvailable]) {
        return nil;
    }
    
    return [[ORK1HealthSampleQueryOperation alloc] initWithCollector:self mananger:mananger];
}

- (NSArray *)collectableSampleTypes {
    return @[_sampleType];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1HealthCollector *collector = [super copyWithZone:zone];
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
            ORK1EqualObjects(_sampleType, castObject.sampleType) &&
            ORK1EqualObjects(_unit, castObject.unit) &&
            ORK1EqualObjects(_startDate, castObject.startDate) &&
            ORK1EqualObjects(_lastAnchor, castObject.lastAnchor));
}

@end


@implementation ORK1HealthCorrelationCollector : ORK1Collector

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
        ORK1_DECODE_OBJ(aDecoder, correlationType);
        ORK1_DECODE_OBJ_ARRAY(aDecoder, sampleTypes, HKSampleType);
        ORK1_DECODE_OBJ_ARRAY(aDecoder, units, HKUnit);
        ORK1_DECODE_OBJ(aDecoder, startDate);
        ORK1_DECODE_OBJ(aDecoder, lastAnchor);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    
    ORK1_ENCODE_OBJ(aCoder, correlationType);
    ORK1_ENCODE_OBJ(aCoder, sampleTypes);
    ORK1_ENCODE_OBJ(aCoder, units);
    ORK1_ENCODE_OBJ(aCoder, startDate);
    ORK1_ENCODE_OBJ(aCoder, lastAnchor);
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
        [elements addObject:[correlation ork_JSONDictionaryWithOptions:(ORK1SampleJSONOptions)(ORK1SampleIncludeMetadata|ORK1SampleIncludeSource|ORK1SampleIncludeUUID) sampleTypes:self.sampleTypes units:self.units]];
    }
    
    return elements;
}

- (ORK1Operation *)collectionOperationWithManager:(ORK1DataCollectionManager *)manager {
    if (! [HKHealthStore isHealthDataAvailable]) {
        return nil;
    }
    
    return [[ORK1HealthSampleQueryOperation alloc] initWithCollector:self mananger:manager];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1HealthCorrelationCollector *collector = [super copyWithZone:zone];
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
            ORK1EqualObjects(_correlationType, castObject.correlationType) &&
            ORK1EqualObjects(_sampleTypes, castObject.sampleTypes) &&
            ORK1EqualObjects(_units, castObject.units) &&
            ORK1EqualObjects(_startDate, castObject.startDate) &&
            ORK1EqualObjects(_lastAnchor, castObject.lastAnchor));
}

@end


@implementation ORK1MotionActivityCollector : ORK1Collector

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
        ORK1_DECODE_OBJ_CLASS(aDecoder, startDate, NSDate);
        ORK1_DECODE_OBJ_CLASS(aDecoder, lastDate, NSDate);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, startDate);
    ORK1_ENCODE_OBJ(aCoder, lastDate);
}

- (NSArray *)serializableObjectsForObjects:(NSArray<CMMotionActivity *> *)objects {
    // Expect an array of CMMotionActivity objects
    NSMutableArray *elements = [NSMutableArray arrayWithCapacity:[objects count]];
    for (CMMotionActivity *activity in objects) {
        [elements addObject:[activity ork_JSONDictionary]];
    }
    
    return elements;
}

- (ORK1Operation *)collectionOperationWithManager:(ORK1DataCollectionManager *)mananger {
    if (! [CMMotionActivityManager isActivityAvailable]) {
        return nil;
    }
    
    return [[ORK1MotionActivityQueryOperation alloc] initWithCollector:self queryQueue:nil manager:mananger];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1MotionActivityCollector *collector = [super copyWithZone:zone];
    collector->_startDate = self.startDate;
    collector->_lastDate = self.lastDate;
    
    return collector;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORK1EqualObjects(_startDate, castObject.startDate) &&
            ORK1EqualObjects(_lastDate, castObject.lastDate));
}

@end

