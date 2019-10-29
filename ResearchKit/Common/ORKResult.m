/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 
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


#import "ORKResult.h"

#import "ORKRecorder_Internal.h"

#import "ORKAnswerFormat_Internal.h"
#import "ORKConsentDocument.h"
#import "ORKConsentSignature.h"
#import "ORKFormStep.h"
#import "ORKQuestionStep.h"
#import "ORKPageStep.h"
#import "ORKResult_Private.h"
#import "ORKStep.h"
#import "ORKTask.h"

#import "ORKHelpers_Internal.h"

@import CoreMotion;
@import CoreLocation;


const NSUInteger NumberOfPaddingSpacesForIndentationLevel = 4;

@interface ORKLegacyResult ()

- (NSString *)descriptionPrefixWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces;

@property (nonatomic) NSString *descriptionSuffix;

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces;

@end


@implementation ORKLegacyResult

- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super init];
    if (self) {
        self.identifier = identifier;
        self.startDate = [NSDate date];
        self.endDate = [NSDate date];
    }
    return self;
}

- (BOOL)isSaveable {
    return NO;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORKLegacy_ENCODE_OBJ(aCoder, identifier);
    ORKLegacy_ENCODE_OBJ(aCoder, startDate);
    ORKLegacy_ENCODE_OBJ(aCoder, endDate);
    ORKLegacy_ENCODE_OBJ(aCoder, userInfo);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, identifier, NSString);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, startDate, NSDate);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, endDate, NSDate);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, userInfo, NSDictionary);
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return (ORKLegacyEqualObjects(self.identifier, castObject.identifier)
            && ORKLegacyEqualObjects(self.startDate, castObject.startDate)
            && ORKLegacyEqualObjects(self.endDate, castObject.endDate)
            && ORKLegacyEqualObjects(self.userInfo, castObject.userInfo));
}

- (NSUInteger)hash {
    return _identifier.hash ^ _startDate.hash ^ _endDate.hash ^ _userInfo.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyResult *result = [[[self class] allocWithZone:zone] init];
    result.startDate = [self.startDate copy];
    result.endDate = [self.endDate copy];
    result.userInfo = [self.userInfo copy];
    result.identifier = [self.identifier copy];
    return result;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.startDate = [NSDate date];
        self.endDate = [NSDate date];
    }
    return self;
}

- (NSString *)descriptionPrefixWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@<%@: %p; identifier: \"%@\"", ORKLegacyPaddingWithNumberOfSpaces(numberOfPaddingSpaces), self.class.description, self, self.identifier];
}

- (NSString *)descriptionSuffix {
    return @">";
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@%@", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], self.descriptionSuffix];
}

- (NSString *)description {
    return [self descriptionWithNumberOfPaddingSpaces:0];
}

@end


@implementation ORKLegacyTappingSample

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORKLegacy_ENCODE_DOUBLE(aCoder, timestamp);
    ORKLegacy_ENCODE_DOUBLE(aCoder, duration);
    ORKLegacy_ENCODE_CGPOINT(aCoder, location);
    ORKLegacy_ENCODE_ENUM(aCoder, buttonIdentifier);

}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORKLegacy_DECODE_DOUBLE(aDecoder, duration);
        ORKLegacy_DECODE_DOUBLE(aDecoder, timestamp);
        ORKLegacy_DECODE_CGPOINT(aDecoder, location);
        ORKLegacy_DECODE_ENUM(aDecoder, buttonIdentifier);
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }

    __typeof(self) castObject = object;
    
    return ((self.timestamp == castObject.timestamp) &&
            (self.duration == castObject.duration) &&
            CGPointEqualToPoint(self.location, castObject.location) &&
            (self.buttonIdentifier == castObject.buttonIdentifier));
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyTappingSample *sample = [[[self class] allocWithZone:zone] init];
    sample.timestamp = self.timestamp;
    sample.duration = self.duration;
    sample.location = self.location;
    sample.buttonIdentifier = self.buttonIdentifier;
    return sample;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; button: %@; timestamp: %.03f; timestamp: %.03f; location: %@>", self.class.description, self, @(self.buttonIdentifier), self.timestamp, self.duration, NSStringFromCGPoint(self.location)];
}

@end


@implementation ORKLegacyPasscodeResult

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_BOOL(aCoder, passcodeSaved);
    ORKLegacy_ENCODE_BOOL(aCoder, touchIdEnabled);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_BOOL(aDecoder, passcodeSaved);
        ORKLegacy_DECODE_BOOL(aDecoder, touchIdEnabled);
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];

    __typeof(self) castObject = object;
    return (isParentSame &&
            self.isPasscodeSaved == castObject.isPasscodeSaved &&
            self.isTouchIdEnabled == castObject.isTouchIdEnabled);
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyPasscodeResult *result = [super copyWithZone:zone];
    result.passcodeSaved = self.isPasscodeSaved;
    result.touchIdEnabled = self.isTouchIdEnabled;
    return result;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; passcodeSaved: %d touchIDEnabled: %d%@", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], self.isPasscodeSaved, self.isTouchIdEnabled, self.descriptionSuffix];
}

@end


@implementation ORKLegacyRangeOfMotionResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_DOUBLE(aCoder, flexed);
    ORKLegacy_ENCODE_DOUBLE(aCoder, extended);
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_DOUBLE(aDecoder, flexed);
        ORKLegacy_DECODE_DOUBLE(aDecoder, extended);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    __typeof(self) castObject = object;
    return isParentSame &&
    self.flexed == castObject.flexed &&
    self.extended == castObject.extended;
}

- (NSUInteger)hash {
    return super.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyRangeOfMotionResult *result = [super copyWithZone:zone];
    result.flexed = self.flexed;
    result.extended = self.extended;
    return result;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"<%@: flexion: %f; extension: %f>", self.class.description, self.flexed, self.extended];
}

@end


@implementation ORKLegacyTowerOfHanoiResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, moves);
    ORKLegacy_ENCODE_BOOL(aCoder, puzzleWasSolved);
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ_ARRAY(aDecoder, moves, ORKLegacyTowerOfHanoiMove);
        ORKLegacy_DECODE_BOOL(aDecoder, puzzleWasSolved);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    __typeof(self) castObject = object;
    return isParentSame &&
    self.puzzleWasSolved == castObject.puzzleWasSolved &&
    ORKLegacyEqualObjects(self.moves, castObject.moves);
}

- (NSUInteger)hash {
    return super.hash ^ self.puzzleWasSolved ^ self.moves.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyTowerOfHanoiResult *result = [super copyWithZone:zone];
    result.puzzleWasSolved = self.puzzleWasSolved;
    result.moves = [self.moves copy];
    return result;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; puzzleSolved: %d; moves: %@%@", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], self.puzzleWasSolved, self.moves, self.descriptionSuffix];
}

@end


@implementation ORKLegacyTowerOfHanoiMove

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORKLegacy_ENCODE_DOUBLE(aCoder, timestamp);
    ORKLegacy_ENCODE_INTEGER(aCoder, donorTowerIndex);
    ORKLegacy_ENCODE_INTEGER(aCoder, recipientTowerIndex);
    
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORKLegacy_DECODE_DOUBLE(aDecoder, timestamp);
        ORKLegacy_DECODE_INTEGER(aDecoder, donorTowerIndex);
        ORKLegacy_DECODE_INTEGER(aDecoder, recipientTowerIndex);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    
    return self.timestamp == castObject.timestamp &&
            self.donorTowerIndex == castObject.donorTowerIndex &&
            self.recipientTowerIndex == castObject.recipientTowerIndex;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyTowerOfHanoiMove *move = [[[self class] allocWithZone:zone] init];
    move.timestamp = self.timestamp;
    move.donorTowerIndex = self.donorTowerIndex;
    move.recipientTowerIndex = self.recipientTowerIndex;
    return move;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; timestamp: %@; donorTower: %@; recipientTower: %@>", self.class.description, self, @(self.timestamp), @(self.donorTowerIndex), @(self.recipientTowerIndex)];
}

@end


@implementation ORKLegacyToneAudiometryResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, outputVolume);
    ORKLegacy_ENCODE_OBJ(aCoder, samples);
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ(aDecoder, outputVolume);
        ORKLegacy_DECODE_OBJ_ARRAY(aDecoder, samples, ORKLegacyToneAudiometrySample);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];

    __typeof(self) castObject = object;
    return (isParentSame &&
            ORKLegacyEqualObjects(self.outputVolume, castObject.outputVolume) &&
            ORKLegacyEqualObjects(self.samples, castObject.samples)) ;
}

- (NSUInteger)hash {
    return super.hash ^ self.samples.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyToneAudiometryResult *result = [super copyWithZone:zone];
    result.outputVolume = [self.outputVolume copy];
    result.samples = [self.samples copy];
    return result;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; outputvolume: %@; samples: %@%@", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], self.outputVolume, self.samples, self.descriptionSuffix];
}

@end


@implementation ORKLegacyToneAudiometrySample

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORKLegacy_ENCODE_DOUBLE(aCoder, frequency);
    ORKLegacy_ENCODE_ENUM(aCoder, channel);
    ORKLegacy_ENCODE_ENUM(aCoder, channelSelected);
    ORKLegacy_ENCODE_DOUBLE(aCoder, amplitude);
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORKLegacy_DECODE_DOUBLE(aDecoder, frequency);
        ORKLegacy_DECODE_ENUM(aDecoder, channel);
        ORKLegacy_DECODE_ENUM(aDecoder, channelSelected);
        ORKLegacy_DECODE_DOUBLE(aDecoder, amplitude);
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }

    __typeof(self) castObject = object;

    return ((self.channel == castObject.channel) &&
            (self.channelSelected == castObject.channelSelected) &&
            (ABS(self.frequency - castObject.frequency) < DBL_EPSILON) &&
            (ABS(self.amplitude - castObject.amplitude) < DBL_EPSILON)) ;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyToneAudiometrySample *sample = [[[self class] allocWithZone:zone] init];
    sample.frequency = self.frequency;
    sample.channel = self.channel;
    sample.channelSelected = self.channelSelected;
    sample.amplitude = self.amplitude;
    return sample;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; frequency: %.1lf; channel %@; amplitude: %.4lf; channelSelected: %@;>", self.class.description, self, self.frequency, @(self.channel), self.amplitude, @(self.channelSelected)];
}

@end


@implementation ORKLegacySpatialSpanMemoryGameTouchSample

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORKLegacy_ENCODE_DOUBLE(aCoder, timestamp);
    ORKLegacy_ENCODE_INTEGER(aCoder, targetIndex);
    ORKLegacy_ENCODE_CGPOINT(aCoder, location);
    ORKLegacy_ENCODE_BOOL(aCoder, correct);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORKLegacy_DECODE_DOUBLE(aDecoder, timestamp);
        ORKLegacy_DECODE_INTEGER(aDecoder, targetIndex);
        ORKLegacy_DECODE_CGPOINT(aDecoder, location);
        ORKLegacy_DECODE_BOOL(aDecoder, correct);
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return ((self.timestamp == castObject.timestamp) &&
            (self.targetIndex == castObject.targetIndex) &&
            (CGPointEqualToPoint(self.location, castObject.location)) &&
            (self.isCorrect == castObject.isCorrect));
}

- (NSUInteger)hash {
    return super.hash ^ [self targetIndex] ^ [self isCorrect];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacySpatialSpanMemoryGameTouchSample *sample = [[[self class] allocWithZone:zone] init];
    sample.timestamp = self.timestamp;
    sample.targetIndex = self.targetIndex;
    sample.location = self.location;
    sample.correct = self.isCorrect;
    
    return sample;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; timestamp: %@; targetIndex: %@; location: %@; correct: %@>", self.class.description, self, @(self.timestamp), @(self.targetIndex), NSStringFromCGPoint(self.location), @(self.isCorrect)];
}

@end


@implementation ORKLegacySpatialSpanMemoryGameRecord

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORKLegacy_ENCODE_UINT32(aCoder, seed);
    ORKLegacy_ENCODE_OBJ(aCoder, sequence);
    ORKLegacy_ENCODE_INTEGER(aCoder, gameSize);
    ORKLegacy_ENCODE_OBJ(aCoder, touchSamples);
    ORKLegacy_ENCODE_INTEGER(aCoder, gameStatus);
    ORKLegacy_ENCODE_INTEGER(aCoder, score);
    ORKLegacy_ENCODE_OBJ(aCoder, targetRects);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORKLegacy_DECODE_UINT32(aDecoder, seed);
        ORKLegacy_DECODE_OBJ_ARRAY(aDecoder, sequence, NSNumber);
        ORKLegacy_DECODE_INTEGER(aDecoder, gameSize);
        ORKLegacy_DECODE_OBJ_ARRAY(aDecoder, touchSamples, ORKLegacySpatialSpanMemoryGameTouchSample);
        ORKLegacy_DECODE_INTEGER(aDecoder, gameStatus);
        ORKLegacy_DECODE_INTEGER(aDecoder, score);
        ORKLegacy_DECODE_OBJ_ARRAY(aDecoder, targetRects, NSValue);
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return ((self.seed == castObject.seed) &&
            (ORKLegacyEqualObjects(self.sequence, castObject.sequence)) &&
            (ORKLegacyEqualObjects(self.touchSamples, castObject.touchSamples)) &&
            (self.gameSize == castObject.gameSize) &&
            (self.gameStatus == castObject.gameStatus) &&
            (self.score == castObject.score) &&
            (ORKLegacyEqualObjects(self.targetRects, castObject.targetRects)));
}

- (NSUInteger)hash {
    return super.hash ^ [self seed] ^ [self gameSize] ^ [self score] ^ [self gameStatus];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacySpatialSpanMemoryGameRecord *record = [[[self class] allocWithZone:zone] init];
    record.seed = self.seed;
    record.sequence = [self.sequence copyWithZone:zone];
    record.touchSamples = [self.touchSamples copyWithZone:zone];
    record.gameSize = self.gameSize;
    record.gameStatus = self.gameStatus;
    record.score = self.score;
    record.targetRects = [self.targetRects copyWithZone:zone];
    return record;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; seed: %@; sequence: %@; gameSize: %@; gameStatus: %@; score: %@>", self.class.description, self, @(self.seed), self.sequence, @(self.gameSize), @(self.gameStatus), @(self.score)];
}

@end


@implementation ORKLegacySpatialSpanMemoryResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_INTEGER(aCoder, score);
    ORKLegacy_ENCODE_INTEGER(aCoder, numberOfGames);
    ORKLegacy_ENCODE_INTEGER(aCoder, numberOfFailures);
    ORKLegacy_ENCODE_OBJ(aCoder, gameRecords);
    
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_INTEGER(aDecoder, score);
        ORKLegacy_DECODE_INTEGER(aDecoder, numberOfGames);
        ORKLegacy_DECODE_INTEGER(aDecoder, numberOfFailures);
        ORKLegacy_DECODE_OBJ_ARRAY(aDecoder, gameRecords, ORKLegacySpatialSpanMemoryGameRecord);
        
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            (self.score == castObject.score) &&
            (self.numberOfGames == castObject.numberOfGames) &&
            (self.numberOfFailures == castObject.numberOfFailures) &&
            (ORKLegacyEqualObjects(self.gameRecords, castObject.gameRecords)));
}

- (NSUInteger)hash {
    return super.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacySpatialSpanMemoryResult *result = [super copyWithZone:zone];
    result.score = self.score;
    result.numberOfGames = self.numberOfGames;
    result.numberOfFailures = self.numberOfFailures;
    result.gameRecords = [self.gameRecords copyWithZone:zone];
    return result;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; score: %@%@", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], @(self.score), self.descriptionSuffix];
}

@end


@implementation ORKLegacyTappingIntervalResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, samples);
    ORKLegacy_ENCODE_CGRECT(aCoder, buttonRect1);
    ORKLegacy_ENCODE_CGRECT(aCoder, buttonRect2);
    ORKLegacy_ENCODE_CGSIZE(aCoder, stepViewSize);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ_ARRAY(aDecoder, samples, ORKLegacyTappingSample);
        ORKLegacy_DECODE_CGRECT(aDecoder, buttonRect1);
        ORKLegacy_DECODE_CGRECT(aDecoder, buttonRect2);
        ORKLegacy_DECODE_CGSIZE(aDecoder, stepViewSize);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORKLegacyEqualObjects(self.samples, castObject.samples) &&
            CGRectEqualToRect(self.buttonRect1, castObject.buttonRect1) &&
            CGRectEqualToRect(self.buttonRect2, castObject.buttonRect2) &&
            CGSizeEqualToSize(self.stepViewSize, castObject.stepViewSize));
}

- (NSUInteger)hash {
    return super.hash ^ self.samples.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyTappingIntervalResult *result = [super copyWithZone:zone];
    result.samples = [self.samples copy];
    result.buttonRect1 = self.buttonRect1;
    result.buttonRect2 = self.buttonRect2;
    result.stepViewSize = self.stepViewSize;
    return result;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; samples: %@%@", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], self.samples, self.descriptionSuffix];
}

@end


@implementation ORKLegacyFileResult

- (BOOL)isSaveable {
    return (_fileURL != nil);
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_URL(aCoder, fileURL);
    ORKLegacy_ENCODE_OBJ(aCoder, contentType);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_URL(aDecoder, fileURL);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, contentType, NSString);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORKLegacyEqualFileURLs(self.fileURL, castObject.fileURL) &&
            ORKLegacyEqualObjects(self.contentType, castObject.contentType));
}

- (NSUInteger)hash {
    return super.hash ^ self.fileURL.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyFileResult *result = [super copyWithZone:zone];
    result.fileURL = [self.fileURL copy];
    result.contentType = [self.contentType copy];
    return result;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; fileURL: %@ (%lld bytes)%@", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], self.fileURL, [[NSFileManager defaultManager] attributesOfItemAtPath:self.fileURL.path error:nil].fileSize, self.descriptionSuffix];
}

@end


@implementation ORKLegacyReactionTimeResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_DOUBLE(aCoder, timestamp);
    ORKLegacy_ENCODE_OBJ(aCoder, fileResult);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_DOUBLE(aDecoder, timestamp);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, fileResult, ORKLegacyFileResult);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            (self.timestamp == castObject.timestamp) &&
            ORKLegacyEqualObjects(self.fileResult, castObject.fileResult)) ;
}

- (NSUInteger)hash {
    return super.hash ^ [NSNumber numberWithDouble:self.timestamp].hash ^ self.fileResult.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyReactionTimeResult *result = [super copyWithZone:zone];
    result.fileResult = [self.fileResult copy];
    result.timestamp = self.timestamp;
    return result;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; timestamp: %f; fileResult: %@%@", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], self.timestamp, self.fileResult.description, self.descriptionSuffix];
}

@end


@implementation ORKLegacyTimedWalkResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_DOUBLE(aCoder, distanceInMeters);
    ORKLegacy_ENCODE_DOUBLE(aCoder, timeLimit);
    ORKLegacy_ENCODE_DOUBLE(aCoder, duration);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_DOUBLE(aDecoder, distanceInMeters);
        ORKLegacy_DECODE_DOUBLE(aDecoder, timeLimit);
        ORKLegacy_DECODE_DOUBLE(aDecoder, duration);
    }
    return self;
    
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            (self.distanceInMeters == castObject.distanceInMeters) &&
            (self.timeLimit == castObject.timeLimit) &&
            (self.duration == castObject.duration));
}

- (NSUInteger)hash {
    return super.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyTimedWalkResult *result = [super copyWithZone:zone];
    result.distanceInMeters = self.distanceInMeters;
    result.timeLimit = self.timeLimit;
    result.duration = self.duration;
    return result;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; distance: %@; timeLimit: %@; duration: %@%@", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], @(self.distanceInMeters), @(self.timeLimit), @(self.duration), self.descriptionSuffix];
}

@end


@implementation ORKLegacyPSATSample

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORKLegacy_ENCODE_BOOL(aCoder, correct);
    ORKLegacy_ENCODE_INTEGER(aCoder, digit);
    ORKLegacy_ENCODE_INTEGER(aCoder, answer);
    ORKLegacy_ENCODE_DOUBLE(aCoder, time);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORKLegacy_DECODE_BOOL(aDecoder, correct);
        ORKLegacy_DECODE_INTEGER(aDecoder, digit);
        ORKLegacy_DECODE_INTEGER(aDecoder, answer);
        ORKLegacy_DECODE_DOUBLE(aDecoder, time);
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    
    return ((self.isCorrect == castObject.isCorrect) &&
            (self.digit == castObject.digit) &&
            (self.answer == castObject.answer) &&
            (self.time == castObject.time)) ;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyPSATSample *sample = [[[self class] allocWithZone:zone] init];
    sample.correct = self.isCorrect;
    sample.digit = self.digit;
    sample.answer = self.answer;
    sample.time = self.time;
    return sample;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; correct: %@; digit: %@; answer: %@; time: %@>", self.class.description, self, @(self.isCorrect), @(self.digit), @(self.answer), @(self.time)];
}

@end


@implementation ORKLegacyPSATResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_ENUM(aCoder, presentationMode);
    ORKLegacy_ENCODE_DOUBLE(aCoder, interStimulusInterval);
    ORKLegacy_ENCODE_DOUBLE(aCoder, stimulusDuration);
    ORKLegacy_ENCODE_INTEGER(aCoder, length);
    ORKLegacy_ENCODE_INTEGER(aCoder, totalCorrect);
    ORKLegacy_ENCODE_INTEGER(aCoder, totalDyad);
    ORKLegacy_ENCODE_DOUBLE(aCoder, totalTime);
    ORKLegacy_ENCODE_INTEGER(aCoder, initialDigit);
    ORKLegacy_ENCODE_OBJ(aCoder, samples);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_ENUM(aDecoder, presentationMode);
        ORKLegacy_DECODE_DOUBLE(aDecoder, interStimulusInterval);
        ORKLegacy_DECODE_DOUBLE(aDecoder, stimulusDuration);
        ORKLegacy_DECODE_INTEGER(aDecoder, length);
        ORKLegacy_DECODE_INTEGER(aDecoder, totalCorrect);
        ORKLegacy_DECODE_INTEGER(aDecoder, totalDyad);
        ORKLegacy_DECODE_DOUBLE(aDecoder, totalTime);
        ORKLegacy_DECODE_INTEGER(aDecoder, initialDigit);
        ORKLegacy_DECODE_OBJ_ARRAY(aDecoder, samples, ORKLegacyPSATSample);
    }
    return self;
    
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            (self.presentationMode == castObject.presentationMode) &&
            (self.interStimulusInterval == castObject.interStimulusInterval) &&
            (self.stimulusDuration == castObject.stimulusDuration) &&
            (self.length == castObject.length) &&
            (self.totalCorrect == castObject.totalCorrect) &&
            (self.totalDyad == castObject.totalDyad) &&
            (self.totalTime == castObject.totalTime) &&
            (self.initialDigit == castObject.initialDigit) &&
            ORKLegacyEqualObjects(self.samples, castObject.samples)) ;
}

- (NSUInteger)hash {
    return super.hash ^ self.samples.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyPSATResult *result = [super copyWithZone:zone];
    result.presentationMode = self.presentationMode;
    result.interStimulusInterval = self.interStimulusInterval;
    result.stimulusDuration = self.stimulusDuration;
    result.length = self.length;
    result.totalCorrect = self.totalCorrect;
    result.totalDyad = self.totalDyad;
    result.totalTime = self.totalTime;
    result.initialDigit = self.initialDigit;
    result.samples = [self.samples copy];
    return result;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; correct: %@/%@; samples: %@%@", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], @(self.totalCorrect), @(self.length), self.samples, self.descriptionSuffix];
}

@end


@implementation ORKLegacyStroopResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_DOUBLE(aCoder, startTime);
    ORKLegacy_ENCODE_DOUBLE(aCoder, endTime);
    ORKLegacy_ENCODE_OBJ(aCoder, color);
    ORKLegacy_ENCODE_OBJ(aCoder, text);
    ORKLegacy_ENCODE_OBJ(aCoder, colorSelected);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_DOUBLE(aDecoder, startTime);
        ORKLegacy_DECODE_DOUBLE(aDecoder, endTime);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, color, NSString);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, text, NSString);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, colorSelected, NSString);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            (self.startTime == castObject.startTime) &&
            (self.endTime == castObject.endTime) &&
            ORKLegacyEqualObjects(self.color, castObject.color) &&
            ORKLegacyEqualObjects(self.text, castObject.text) &&
            ORKLegacyEqualObjects(self.colorSelected, castObject.colorSelected));
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyStroopResult *result = [super copyWithZone:zone];
    result.startTime = self.startTime;
    result.endTime = self.endTime;
    result -> _color = [self.color copy];
    result -> _text = [self.text copy];
    result -> _colorSelected = [self.colorSelected copy];
    return result;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; color: %@; text: %@; colorselected: %@ %@", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], self.color, self.text, self.colorSelected, self.descriptionSuffix];
}

@end


@implementation ORKLegacyHolePegTestResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_ENUM(aCoder, movingDirection);
    ORKLegacy_ENCODE_BOOL(aCoder, dominantHandTested);
    ORKLegacy_ENCODE_INTEGER(aCoder, numberOfPegs);
    ORKLegacy_ENCODE_INTEGER(aCoder, threshold);
    ORKLegacy_ENCODE_BOOL(aCoder, rotated);
    ORKLegacy_ENCODE_INTEGER(aCoder, totalSuccesses);
    ORKLegacy_ENCODE_INTEGER(aCoder, totalFailures);
    ORKLegacy_ENCODE_DOUBLE(aCoder, totalTime);
    ORKLegacy_ENCODE_DOUBLE(aCoder, totalDistance);
    ORKLegacy_ENCODE_OBJ(aCoder, samples);
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_ENUM(aDecoder, movingDirection);
        ORKLegacy_DECODE_BOOL(aDecoder, dominantHandTested);
        ORKLegacy_DECODE_INTEGER(aDecoder, numberOfPegs);
        ORKLegacy_DECODE_INTEGER(aDecoder, threshold);
        ORKLegacy_DECODE_BOOL(aDecoder, rotated);
        ORKLegacy_DECODE_INTEGER(aDecoder, totalSuccesses);
        ORKLegacy_DECODE_INTEGER(aDecoder, totalFailures);
        ORKLegacy_DECODE_DOUBLE(aDecoder, totalTime);
        ORKLegacy_DECODE_DOUBLE(aDecoder, totalDistance);
        ORKLegacy_DECODE_OBJ_ARRAY(aDecoder, samples, ORKLegacyToneAudiometrySample);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            (self.movingDirection == castObject.movingDirection) &&
            (self.isDominantHandTested == castObject.isDominantHandTested) &&
            (self.numberOfPegs == castObject.numberOfPegs) &&
            (self.threshold == castObject.threshold) &&
            (self.isRotated == castObject.isRotated) &&
            (self.totalSuccesses == castObject.totalSuccesses) &&
            (self.totalFailures == castObject.totalFailures) &&
            (self.totalTime == castObject.totalTime) &&
            (self.totalDistance == castObject.totalDistance) &&
            ORKLegacyEqualObjects(self.samples, castObject.samples)) ;
}

- (NSUInteger)hash {
    return super.hash ^ self.samples.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyHolePegTestResult *result = [super copyWithZone:zone];
    result.movingDirection = self.movingDirection;
    result.dominantHandTested = self.isDominantHandTested;
    result.numberOfPegs = self.numberOfPegs;
    result.threshold = self.threshold;
    result.rotated = self.isRotated;
    result.totalSuccesses = self.totalSuccesses;
    result.totalFailures = self.totalFailures;
    result.totalTime = self.totalTime;
    result.totalDistance = self.totalDistance;
    result.samples = [self.samples copy];
    return result;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; successes: %@; time: %@; samples: %@%@", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], @(self.totalSuccesses), @(self.totalTime), self.samples, self.descriptionSuffix];
}

@end


@implementation ORKLegacyHolePegTestSample

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORKLegacy_ENCODE_DOUBLE(aCoder, time);
    ORKLegacy_ENCODE_DOUBLE(aCoder, distance);
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORKLegacy_DECODE_DOUBLE(aDecoder, time);
        ORKLegacy_DECODE_DOUBLE(aDecoder, distance);
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    
    return ((self.time == castObject.time) &&
            (self.distance == castObject.distance)) ;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyHolePegTestSample *sample = [[[self class] allocWithZone:zone] init];
    sample.time = self.time;
    sample.distance = self.distance;
    return sample;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; time: %@; distance: %@>", self.class.description, self, @(self.time), @(self.distance)];
}

@end


@implementation ORKLegacyDataResult

- (BOOL)isSaveable {
    return (_data != nil);
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, data);
    ORKLegacy_ENCODE_OBJ(aCoder, filename);
    ORKLegacy_ENCODE_OBJ(aCoder, contentType);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, data, NSData);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, filename, NSString);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, contentType, NSString);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORKLegacyEqualObjects(self.data, castObject.data) &&
            ORKLegacyEqualObjects(self.filename, castObject.filename) &&
            ORKLegacyEqualObjects(self.contentType, castObject.contentType));
}

- (NSUInteger)hash {
    return super.hash ^ self.filename.hash ^ self.contentType.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyDataResult *result = [super copyWithZone:zone];
    result.data = self.data;
    result.filename = self.filename;
    result.contentType = self.contentType;

    return result;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; data: %@; filename: %@; contentType: %@%@", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], self.data, self.filename, self.contentType, self.descriptionSuffix];
}

@end


@implementation ORKLegacyConsentSignatureResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, signature);
    ORKLegacy_ENCODE_BOOL(aCoder, consented);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, signature, ORKLegacyConsentSignature);
        ORKLegacy_DECODE_BOOL(aDecoder, consented);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyConsentSignatureResult *result = [super copyWithZone:zone];
    result.signature = _signature;
    result.consented = _consented;
    return result;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORKLegacyEqualObjects(self.signature, castObject.signature) &&
            (self.consented == castObject.consented));
}

- (NSUInteger)hash {
    return super.hash ^ self.signature.hash;
}

- (void)applyToDocument:(ORKLegacyConsentDocument *)document {
    __block NSUInteger indexToBeReplaced = NSNotFound;
    [[document signatures] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ORKLegacyConsentSignature *signature = obj;
        if ([signature.identifier isEqualToString:self.signature.identifier]) {
            indexToBeReplaced = idx;
            *stop = YES;
        }
    }];
    
    if (indexToBeReplaced != NSNotFound) {
        NSMutableArray *signatures = [[document signatures] mutableCopy];
        signatures[indexToBeReplaced] = [_signature copy];
        document.signatures = signatures;
    }
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; signature: %@; consented: %d%@", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], self.signature, self.consented, self.descriptionSuffix];
}

@end


@implementation ORKLegacyQuestionResult

- (BOOL)isSaveable {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_ENUM(aCoder, questionType);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_ENUM(aDecoder, questionType);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            (_questionType == castObject.questionType));
}

- (NSUInteger)hash {
    return super.hash ^ ((id<NSObject>)self.answer).hash ^ _questionType;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyQuestionResult *result = [super copyWithZone:zone];
    result.questionType = self.questionType;
    return result;
}

- (NSObject *)validateAnswer:(id)answer {
    if (answer == ORKLegacyNullAnswerValue()) {
        answer = nil;
    }
    NSParameterAssert(!answer || [answer isKindOfClass:[[self class] answerClass]]);
    return answer;
}

+ (Class)answerClass {
    return nil;
}

- (void)setAnswer:(id)answer {
}

- (id)answer {
    return nil;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    NSMutableString *description = [NSMutableString stringWithFormat:@"%@; answer:", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces]];
    id answer = self.answer;
    if ([answer isKindOfClass:[NSArray class]]
        || [answer isKindOfClass:[NSDictionary class]]
        || [answer isKindOfClass:[NSSet class]]
        || [answer isKindOfClass:[NSOrderedSet class]]) {
        NSMutableString *indentatedAnswerDescription = [NSMutableString new];
        NSString *answerDescription = [answer description];
        NSArray *answerLines = [answerDescription componentsSeparatedByString:@"\n"];
        const NSUInteger numberOfAnswerLines = answerLines.count;
        [answerLines enumerateObjectsUsingBlock:^(NSString *answerLineString, NSUInteger idx, BOOL *stop) {
            [indentatedAnswerDescription appendFormat:@"%@%@", ORKLegacyPaddingWithNumberOfSpaces(numberOfPaddingSpaces + NumberOfPaddingSpacesForIndentationLevel), answerLineString];
            if (idx != numberOfAnswerLines - 1) {
                [indentatedAnswerDescription appendString:@"\n"];
            }
        }];
        
        [description appendFormat:@"\n%@>", indentatedAnswerDescription];
    } else {
        [description appendFormat:@" %@%@", answer, self.descriptionSuffix];
    }
    
    return [description copy];
}

@end


@implementation ORKLegacyScaleQuestionResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, scaleAnswer);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, scaleAnswer, NSNumber);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORKLegacyEqualObjects(self.scaleAnswer, castObject.scaleAnswer));
}

- (NSUInteger)hash {
    return super.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyScaleQuestionResult *result = [super copyWithZone:zone];
    result->_scaleAnswer = [self.scaleAnswer copyWithZone:zone];
    return result;
}

+ (Class)answerClass {
    return [NSNumber class];
}

- (void)setAnswer:(id)answer {
    answer = [self validateAnswer:answer];
    self.scaleAnswer = answer;
}

- (id)answer {
    return self.scaleAnswer;
}

@end


@implementation ORKLegacyChoiceQuestionResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, choiceAnswers);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ_ARRAY(aDecoder, choiceAnswers, NSObject);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORKLegacyEqualObjects(self.choiceAnswers, castObject.choiceAnswers));
}

- (NSUInteger)hash {
    return super.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyChoiceQuestionResult *result = [super copyWithZone:zone];
    result->_choiceAnswers = [self.choiceAnswers copyWithZone:zone];
    return result;
}

+ (Class)answerClass {
    return [NSArray class];
}

- (void)setAnswer:(id)answer {
    answer = [self validateAnswer:answer];
    self.choiceAnswers = answer;
}

- (id)answer {
    return self.choiceAnswers;
}

@end


@implementation ORKLegacyMultipleComponentQuestionResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, componentsAnswer);
    ORKLegacy_ENCODE_OBJ(aCoder, separator);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ_ARRAY(aDecoder, componentsAnswer, NSObject);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, separator, NSString);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORKLegacyEqualObjects(self.componentsAnswer, castObject.componentsAnswer) &&
            ORKLegacyEqualObjects(self.separator, castObject.separator));
}

- (NSUInteger)hash {
    return super.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    __typeof(self) copy = [super copyWithZone:zone];
    copy.componentsAnswer = self.componentsAnswer;
    copy.separator = self.separator;
    return copy;
}

+ (Class)answerClass {
    return [NSArray class];
}

- (void)setAnswer:(id)answer {
    answer = [self validateAnswer:answer];
    self.componentsAnswer = answer;
}

- (id)answer {
    return self.componentsAnswer;
}

@end


@implementation ORKLegacyBooleanQuestionResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, booleanAnswer);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, booleanAnswer, NSNumber);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORKLegacyEqualObjects(self.booleanAnswer, castObject.booleanAnswer));
}

- (NSUInteger)hash {
    return super.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyBooleanQuestionResult *result = [super copyWithZone:zone];
    result->_booleanAnswer = [self.booleanAnswer copyWithZone:zone];
    return result;
}

+ (Class)answerClass {
    return [NSNumber class];
}

- (void)setAnswer:(id)answer {
    if ([answer isKindOfClass:[NSArray class]]) {
        // Because ORKLegacyBooleanAnswerFormat has ORKLegacyChoiceAnswerFormat as its implied format.
        NSArray *answerArray = answer;
        NSAssert(answerArray.count <= 1, @"Should be no more than one answer");
        answer = answerArray.firstObject;
    }
    answer = [self validateAnswer:answer];
    self.booleanAnswer = answer;
}

- (id)answer {
    return self.booleanAnswer;
}

@end


@implementation ORKLegacyTextQuestionResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, textAnswer);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, textAnswer, NSString);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORKLegacyEqualObjects(self.textAnswer, castObject.textAnswer));
}

- (NSUInteger)hash {
    return super.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyTextQuestionResult *result = [super copyWithZone:zone];
    result->_textAnswer = [self.textAnswer copyWithZone:zone];
    return result;
}

+ (Class)answerClass {
    return [NSString class];
}

- (void)setAnswer:(id)answer {
    answer = [self validateAnswer:answer];
    self.textAnswer = answer;
}

- (id)answer {
    return self.textAnswer;
}

@end


@implementation ORKLegacyNumericQuestionResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, numericAnswer);
    ORKLegacy_ENCODE_OBJ(aCoder, unit);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, numericAnswer, NSNumber);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, unit, NSString);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORKLegacyEqualObjects(self.numericAnswer, castObject.numericAnswer) &&
            ORKLegacyEqualObjects(self.unit, castObject.unit));
}

- (NSUInteger)hash {
    return super.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyNumericQuestionResult *result = [super copyWithZone:zone];
    result->_unit = [self.unit copyWithZone:zone];
    result->_numericAnswer = [self.numericAnswer copyWithZone:zone];
    return result;
}

+ (Class)answerClass {
    return [NSNumber class];
}

- (void)setAnswer:(id)answer {
    if (answer == ORKLegacyNullAnswerValue()) {
        answer = nil;
    }
    NSAssert(!answer || [answer isKindOfClass:[[self class] answerClass]], @"Answer should be of class %@", NSStringFromClass([[self class] answerClass]));
    self.numericAnswer = answer;
}

- (id)answer {
    return self.numericAnswer;
}

- (NSString *)descriptionSuffix {
    return [NSString stringWithFormat:@" %@>", _unit];
}

@end


@implementation ORKLegacyTimeOfDayQuestionResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, dateComponentsAnswer);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, dateComponentsAnswer, NSDateComponents);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORKLegacyEqualObjects(self.dateComponentsAnswer, castObject.dateComponentsAnswer));
}

- (NSUInteger)hash {
    return super.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyTimeOfDayQuestionResult *result = [super copyWithZone:zone];
    result->_dateComponentsAnswer = [self.dateComponentsAnswer copyWithZone:zone];
    return result;
}

+ (Class)answerClass {
    return [NSDateComponents class];
}

- (void)setAnswer:(id)answer {
    NSDateComponents *dateComponents = (NSDateComponents *)[self validateAnswer:answer];
    // For time of day, the day, month and year should be zero
    dateComponents.day = 0;
    dateComponents.month = 0;
    dateComponents.year = 0;
    self.dateComponentsAnswer = dateComponents;
}

- (id)answer {
    return self.dateComponentsAnswer;
}

@end


@implementation ORKLegacyTimeIntervalQuestionResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, intervalAnswer);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, intervalAnswer, NSNumber);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORKLegacyEqualObjects(self.intervalAnswer, castObject.intervalAnswer));
}

- (NSUInteger)hash {
    return super.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyTimeIntervalQuestionResult *result = [super copyWithZone:zone];
    result->_intervalAnswer = [self.intervalAnswer copyWithZone:zone];
    return result;
}

+ (Class)answerClass {
    return [NSNumber class];
}

- (void)setAnswer:(id)answer {
    answer = [self validateAnswer:answer];
    self.intervalAnswer = answer;
}

- (id)answer {
    return self.intervalAnswer;
}

@end


@implementation ORKLegacyDateQuestionResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, calendar);
    ORKLegacy_ENCODE_OBJ(aCoder, timeZone);
    ORKLegacy_ENCODE_OBJ(aCoder, dateAnswer);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, calendar, NSCalendar);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, timeZone, NSTimeZone);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, dateAnswer, NSDate);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}


- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORKLegacyEqualObjects(self.timeZone, castObject.timeZone) &&
            ORKLegacyEqualObjects(self.calendar, castObject.calendar) &&
            ORKLegacyEqualObjects(self.dateAnswer, castObject.dateAnswer));
}

- (NSUInteger)hash {
    return super.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyDateQuestionResult *result = [super copyWithZone:zone];
    result->_calendar = [self.calendar copyWithZone:zone];
    result->_timeZone = [self.timeZone copyWithZone:zone];
    result->_dateAnswer = [self.dateAnswer copyWithZone:zone];
    return result;
}

+ (Class)answerClass {
    return [NSDate class];
}

- (void)setAnswer:(id)answer {
    answer = [self validateAnswer:answer];
    self.dateAnswer = answer;
}

- (id)answer {
    return self.dateAnswer;
}

@end


@interface ORKLegacyCollectionResult ()

- (void)setResultsCopyObjects:(NSArray *)results;

@end


@implementation ORKLegacyCollectionResult

- (BOOL)isSaveable {
    BOOL saveable = NO;
    
    for (ORKLegacyResult *result in _results) {
        if ([result isSaveable]) {
            saveable = YES;
            break;
        }
    }
    return saveable;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, results);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ_ARRAY(aDecoder, results, ORKLegacyResult);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORKLegacyEqualObjects(self.results, castObject.results));
}

- (NSUInteger)hash {
    return super.hash ^ self.results.hash;
}

- (void)setResultsCopyObjects:(NSArray *)results {
    _results = ORKLegacyArrayCopyObjects(results);
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyCollectionResult *result = [super copyWithZone:zone];
    [result setResultsCopyObjects: self.results];
    return result;
}

- (NSArray *)results {
    if (_results == nil) {
        _results = [NSArray new];
    }
    return _results;
}

- (ORKLegacyResult *)resultForIdentifier:(NSString *)identifier {
    
    if (identifier == nil) {
        return nil;
    }
    
    __block ORKLegacyQuestionResult *result = nil;
    
    // Look through the result set in reverse-order to account for the possibility of
    // multiple results with the same identifier (due to a navigation loop)
    NSEnumerator *enumerator = self.results.reverseObjectEnumerator;
    id obj = enumerator.nextObject;
    while ((result== nil) && (obj != nil)) {
        
        if (NO == [obj isKindOfClass:[ORKLegacyResult class]]) {
            @throw [NSException exceptionWithName:NSGenericException reason:[NSString stringWithFormat: @"Expected result object to be ORKLegacyResult type: %@", obj] userInfo:nil];
        }
        
        NSString *anIdentifier = [(ORKLegacyResult *)obj identifier];
        if ([anIdentifier isEqual:identifier]) {
            result = obj;
        }
        obj = enumerator.nextObject;
    }
    
    return result;
}

- (ORKLegacyResult *)firstResult {
    
    return self.results.firstObject;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    NSMutableString *description = [NSMutableString stringWithFormat:@"%@; results: (", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces]];
    
    NSUInteger numberOfResults = self.results.count;
    [self.results enumerateObjectsUsingBlock:^(ORKLegacyResult *result, NSUInteger idx, BOOL *stop) {
        if (idx == 0) {
            [description appendString:@"\n"];
        }
        [description appendFormat:@"%@", [result descriptionWithNumberOfPaddingSpaces:numberOfPaddingSpaces + NumberOfPaddingSpacesForIndentationLevel]];
        if (idx != numberOfResults - 1) {
            [description appendString:@",\n"];
        } else {
            [description appendString:@"\n"];
        }
    }];
    
    [description appendFormat:@"%@)%@", ORKLegacyPaddingWithNumberOfSpaces((numberOfResults == 0) ? 0 : numberOfPaddingSpaces), self.descriptionSuffix];
    return [description copy];
}

@end


@implementation ORKLegacyTaskResult

- (instancetype)initWithTaskIdentifier:(NSString *)identifier
                       taskRunUUID:(NSUUID *)taskRunUUID
                   outputDirectory:(NSURL *)outputDirectory {
    self = [super initWithIdentifier:identifier];
    if (self) {
        self->_taskRunUUID = [taskRunUUID copy];
        self->_outputDirectory = [outputDirectory copy];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, taskRunUUID);
    ORKLegacy_ENCODE_URL(aCoder, outputDirectory);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, taskRunUUID, NSUUID);
        ORKLegacy_DECODE_URL(aDecoder, outputDirectory);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORKLegacyEqualObjects(self.taskRunUUID, castObject.taskRunUUID) &&
            ORKLegacyEqualFileURLs(self.outputDirectory, castObject.outputDirectory));
}

- (NSUInteger)hash {
    return super.hash ^ self.taskRunUUID.hash ^ self.outputDirectory.hash;
}


- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyTaskResult *result = [super copyWithZone:zone];
    result->_taskRunUUID = [self.taskRunUUID copy];
    result->_outputDirectory =  [self.outputDirectory copy];
    return result;
}

- (ORKLegacyStepResult *)stepResultForStepIdentifier:(NSString *)stepIdentifier {
    return (ORKLegacyStepResult *)[self resultForIdentifier:stepIdentifier];
}

@end


@implementation ORKLegacyLocation

+ (instancetype)new {
    ORKLegacyThrowMethodUnavailableException();
}

- (instancetype)init {
    ORKLegacyThrowMethodUnavailableException();
}

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate
                            region:(CLCircularRegion *)region
                         userInput:(NSString *)userInput
                 addressDictionary:(NSDictionary *)addressDictionary {
    self = [super init];
    if (self) {
        _coordinate = coordinate;
        _region = region;
        _userInput = [userInput copy];
        _addressDictionary = [addressDictionary copy];
    }
    return self;
}

- (instancetype)initWithPlacemark:(CLPlacemark *)placemark userInput:(NSString *)userInput {
    self = [super init];
    if (self) {
        _coordinate = placemark.location.coordinate;
        _userInput =  [userInput copy];
        _region = (CLCircularRegion *)placemark.region;
        _addressDictionary = [placemark.addressDictionary copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    // This object is not mutable
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

static NSString *const RegionCenterLatitudeKey = @"region.center.latitude";
static NSString *const RegionCenterLongitudeKey = @"region.center.longitude";
static NSString *const RegionRadiusKey = @"region.radius";
static NSString *const RegionIdentifierKey = @"region.identifier";

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORKLegacy_ENCODE_OBJ(aCoder, userInput);
    ORKLegacy_ENCODE_COORDINATE(aCoder, coordinate);
    ORKLegacy_ENCODE_OBJ(aCoder, addressDictionary);

    [aCoder encodeObject:@(_region.center.latitude) forKey:RegionCenterLatitudeKey];
    [aCoder encodeObject:@(_region.center.longitude) forKey:RegionCenterLongitudeKey];
    [aCoder encodeObject:_region.identifier forKey:RegionIdentifierKey];
    [aCoder encodeObject:@(_region.radius) forKey:RegionRadiusKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, userInput, NSString);
        ORKLegacy_DECODE_COORDINATE(aDecoder, coordinate);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, addressDictionary, NSDictionary);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, region, CLCircularRegion);
        
        NSNumber *latitude = [aDecoder decodeObjectOfClass:[NSNumber class] forKey:RegionCenterLatitudeKey];
        NSNumber *longitude = [aDecoder decodeObjectOfClass:[NSNumber class] forKey:RegionCenterLongitudeKey];
        NSNumber *radius = [aDecoder decodeObjectOfClass:[NSNumber class] forKey:RegionRadiusKey];
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue);
        _region = [[CLCircularRegion alloc] initWithCenter:coordinate
                                                    radius:radius.doubleValue
                                                identifier:[aDecoder decodeObjectOfClass:[NSString class] forKey:RegionIdentifierKey]];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return (ORKLegacyEqualObjects(self.userInput, castObject.userInput) &&
            ORKLegacyEqualObjects(self.addressDictionary, castObject.addressDictionary) &&
            ORKLegacyEqualObjects(self.region, castObject.region) &&
            ORKLegacyEqualObjects([NSValue valueWithMKCoordinate:self.coordinate], [NSValue valueWithMKCoordinate:castObject.coordinate]));
}

@end


@implementation ORKLegacyLocationQuestionResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, locationAnswer);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, locationAnswer, ORKLegacyLocation);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame && ORKLegacyEqualObjects(self.locationAnswer, castObject.locationAnswer));
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyLocationQuestionResult *result = [super copyWithZone:zone];
    result->_locationAnswer = [self.locationAnswer copy];
    return result;
}

+ (Class)answerClass {
    return [ORKLegacyLocation class];
}

- (void)setAnswer:(id)answer {
    answer = [self validateAnswer:answer];
    self.locationAnswer = [answer copy];
}

- (id)answer {
    return self.locationAnswer;
}

@end


@implementation ORKLegacyStepResult

- (instancetype)initWithStepIdentifier:(NSString *)stepIdentifier results:(NSArray *)results {
    self = [super initWithIdentifier:stepIdentifier];
    if (self) {
        [self setResultsCopyObjects:results];
        [self updateEnabledAssistiveTechnology];
    }
    return self;
}

- (void)updateEnabledAssistiveTechnology {
    if (UIAccessibilityIsVoiceOverRunning()) {
        _enabledAssistiveTechnology = [UIAccessibilityNotificationVoiceOverIdentifier copy];
    } else if (UIAccessibilityIsSwitchControlRunning()) {
        _enabledAssistiveTechnology = [UIAccessibilityNotificationSwitchControlIdentifier copy];
    }
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, enabledAssistiveTechnology);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, enabledAssistiveTechnology, NSString);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORKLegacyEqualObjects(self.enabledAssistiveTechnology, castObject.enabledAssistiveTechnology));
}

- (NSUInteger)hash {
    return super.hash ^ _enabledAssistiveTechnology.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyStepResult *result = [super copyWithZone:zone];
    result->_enabledAssistiveTechnology = [_enabledAssistiveTechnology copy];
    return result;
}

- (NSString *)descriptionPrefixWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; enabledAssistiveTechnology: %@", [super descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], _enabledAssistiveTechnology ? : @"None"];
}

@end


@implementation ORKLegacySignatureResult

- (instancetype)initWithSignatureImage:(UIImage *)signatureImage
                         signaturePath:(NSArray <UIBezierPath *> *)signaturePath {
    self = [super init];
    if (self) {
        _signatureImage = [signatureImage copy];
        _signaturePath = ORKLegacyArrayCopyObjects(signaturePath);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_IMAGE(aCoder, signatureImage);
    ORKLegacy_ENCODE_OBJ(aCoder, signaturePath);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_IMAGE(aDecoder, signatureImage);
        ORKLegacy_DECODE_OBJ_ARRAY(aDecoder, signaturePath, UIBezierPath);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (NSUInteger)hash {
    return super.hash ^ self.signatureImage.hash ^ self.signaturePath.hash;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORKLegacyEqualObjects(self.signatureImage, castObject.signatureImage) &&
            ORKLegacyEqualObjects(self.signaturePath, castObject.signaturePath));
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacySignatureResult *result = [super copyWithZone:zone];
    result->_signatureImage = [_signatureImage copy];
    result->_signaturePath = ORKLegacyArrayCopyObjects(_signaturePath);
    return result;
}

@end


@implementation ORKLegacyVideoInstructionStepResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeFloat:self.playbackStoppedTime forKey:@"playbackStoppedTime"];
    ORKLegacy_ENCODE_BOOL(aCoder, playbackCompleted);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.playbackStoppedTime = [aDecoder decodeFloatForKey:@"playbackStoppedTime"];
        ORKLegacy_DECODE_BOOL(aDecoder, playbackCompleted);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (NSUInteger)hash {
    NSNumber *playbackStoppedTime = [NSNumber numberWithFloat:self.playbackStoppedTime];
    return super.hash ^ [playbackStoppedTime hash] ^ self.playbackCompleted;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            self.playbackStoppedTime == castObject.playbackStoppedTime &&
            self.playbackCompleted == castObject.playbackCompleted);
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyVideoInstructionStepResult *result = [super copyWithZone:zone];
    result->_playbackStoppedTime = self.playbackStoppedTime;
    result->_playbackCompleted = self.playbackCompleted;
    return result;
}

@end


@implementation ORKLegacyPageResult

- (instancetype)initWithPageStep:(ORKLegacyPageStep *)step stepResult:(ORKLegacyStepResult*)result {
    self = [super initWithTaskIdentifier:step.identifier taskRunUUID:[NSUUID UUID] outputDirectory:nil];
    if (self) {
        NSArray <NSString *> *stepIdentifiers = [step.steps valueForKey:@"identifier"];
        NSMutableArray *results = [NSMutableArray new];
        for (NSString *identifier in stepIdentifiers) {
            NSString *prefix = [NSString stringWithFormat:@"%@.", identifier];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier BEGINSWITH %@", prefix];
            NSArray *filteredResults = [result.results filteredArrayUsingPredicate:predicate];
            if (filteredResults.count > 0) {
                NSMutableArray *subresults = [NSMutableArray new];
                for (ORKLegacyResult *subresult in filteredResults) {
                    ORKLegacyResult *copy = [subresult copy];
                    copy.identifier = [subresult.identifier substringFromIndex:prefix.length];
                    [subresults addObject:copy];
                }
                [results addObject:[[ORKLegacyStepResult alloc] initWithStepIdentifier:identifier results:subresults]];
            }
        }
        self.results = results;
    }
    return self;
}

- (void)addStepResult:(ORKLegacyStepResult *)stepResult {
    if (stepResult == nil) {
        return;
    }
    
    // Remove previous step result and add the new one
    NSMutableArray *results = [self.results mutableCopy] ?: [NSMutableArray new];
    ORKLegacyResult *previousResult = [self resultForIdentifier:stepResult.identifier];
    if (previousResult) {
        [results removeObject:previousResult];
    }
    [results addObject:stepResult];
    self.results = results;
}

- (void)removeStepResultWithIdentifier:(NSString *)identifier {
    ORKLegacyResult *result = [self resultForIdentifier:identifier];
    if (result != nil) {
        NSMutableArray *results = [self.results mutableCopy];
        [results removeObject:result];
        self.results = results;
    }
}

- (void)removeStepResultsAfterStepWithIdentifier:(NSString *)identifier {
    ORKLegacyResult *result = [self resultForIdentifier:identifier];
    if (result != nil) {
        NSUInteger idx = [self.results indexOfObject:result];
        if (idx != NSNotFound) {
            self.results = [self.results subarrayWithRange:NSMakeRange(0, idx)];
        }
    }
}

- (NSArray <ORKLegacyResult *> *)flattenResults {
    NSMutableArray *results = [NSMutableArray new];
    for (ORKLegacyResult *result in self.results) {
        if ([result isKindOfClass:[ORKLegacyStepResult class]]) {
            ORKLegacyStepResult *stepResult = (ORKLegacyStepResult *)result;
            if (stepResult.results.count > 0) {
                // For each subresult in this step, append the step identifier onto the result
                for (ORKLegacyResult *result in stepResult.results) {
                    ORKLegacyResult *copy = [result copy];
                    NSString *subIdentifier = result.identifier ?: [NSString stringWithFormat:@"%@", @(result.hash)];
                    copy.identifier = [NSString stringWithFormat:@"%@.%@", stepResult.identifier, subIdentifier];
                    [results addObject:copy];
                }
            } else {
                // If this is an empty step result then add a base class instance with this identifier
                [results addObject:[[ORKLegacyResult alloc] initWithIdentifier:stepResult.identifier]];
            }
        } else {
            // If this is *not* a step result then just add it as-is
            [results addObject:result];
        }
    }
    return [results copy];
}

- (instancetype)copyWithOutputDirectory:(NSURL *)outputDirectory {
    typeof(self) copy = [[[self class] alloc] initWithTaskIdentifier:self.identifier taskRunUUID:self.taskRunUUID outputDirectory:outputDirectory];
    copy.results = self.results;
    return copy;
}

@end


@implementation ORKLegacyTrailmakingResult

- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super initWithIdentifier:identifier];
    if (self) {
        _taps = @[];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_INTEGER(aCoder, numberOfErrors);
    ORKLegacy_ENCODE_OBJ(aCoder, taps);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_INTEGER(aDecoder, numberOfErrors);
        ORKLegacy_DECODE_OBJ_ARRAY(aDecoder, taps, ORKLegacyTrailmakingTap);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (NSUInteger)hash {
    return super.hash ^ self.numberOfErrors ^ self.taps.hash;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            self.numberOfErrors == castObject.numberOfErrors &&
            ORKLegacyEqualObjects(self.taps, castObject.taps));
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyTrailmakingResult *result = [super copyWithZone:zone];
    result.numberOfErrors = self.numberOfErrors;
    result.taps = ORKLegacyArrayCopyObjects(self.taps);
    return result;
}

@end


@implementation ORKLegacyTrailmakingTap

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORKLegacy_ENCODE_DOUBLE(aCoder, timestamp);
    ORKLegacy_ENCODE_INTEGER(aCoder, index);
    ORKLegacy_ENCODE_BOOL(aCoder, incorrect);
    
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORKLegacy_DECODE_DOUBLE(aDecoder, timestamp);
        ORKLegacy_DECODE_INTEGER(aDecoder, index);
        ORKLegacy_DECODE_BOOL(aDecoder, incorrect);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (NSUInteger)hash {
    return [super hash] ^ (NSUInteger)self.timestamp*100 ^ self.index;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    
    return self.timestamp == castObject.timestamp &&
           self.index == castObject.index &&
           self.incorrect == castObject.incorrect;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyTrailmakingTap *tap = [[[self class] allocWithZone:zone] init];
    tap.timestamp = self.timestamp;
    tap.index = self.index;
    tap.incorrect = self.incorrect;
    return tap;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; timestamp: %@; index: %@; error: %@>", self.class.description, self, @(self.timestamp), @(self.index), @(self.incorrect)];
}

@end

@implementation ORKLegacyWebViewStepResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, result);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, result, NSString);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (NSUInteger)hash {
    return super.hash ^ [self.result hash];
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            [self.result isEqualToString:castObject.result]);
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyWebViewStepResult *result = [super copyWithZone:zone];
    result->_result = self.result;
    return result;
}

@end
