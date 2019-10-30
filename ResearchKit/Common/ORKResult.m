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

@interface ORK1Result ()

- (NSString *)descriptionPrefixWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces;

@property (nonatomic) NSString *descriptionSuffix;

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces;

@end


@implementation ORK1Result

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
    ORK1_ENCODE_OBJ(aCoder, identifier);
    ORK1_ENCODE_OBJ(aCoder, startDate);
    ORK1_ENCODE_OBJ(aCoder, endDate);
    ORK1_ENCODE_OBJ(aCoder, userInfo);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, identifier, NSString);
        ORK1_DECODE_OBJ_CLASS(aDecoder, startDate, NSDate);
        ORK1_DECODE_OBJ_CLASS(aDecoder, endDate, NSDate);
        ORK1_DECODE_OBJ_CLASS(aDecoder, userInfo, NSDictionary);
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return (ORK1EqualObjects(self.identifier, castObject.identifier)
            && ORK1EqualObjects(self.startDate, castObject.startDate)
            && ORK1EqualObjects(self.endDate, castObject.endDate)
            && ORK1EqualObjects(self.userInfo, castObject.userInfo));
}

- (NSUInteger)hash {
    return _identifier.hash ^ _startDate.hash ^ _endDate.hash ^ _userInfo.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1Result *result = [[[self class] allocWithZone:zone] init];
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
    return [NSString stringWithFormat:@"%@<%@: %p; identifier: \"%@\"", ORK1PaddingWithNumberOfSpaces(numberOfPaddingSpaces), self.class.description, self, self.identifier];
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


@implementation ORK1TappingSample

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORK1_ENCODE_DOUBLE(aCoder, timestamp);
    ORK1_ENCODE_DOUBLE(aCoder, duration);
    ORK1_ENCODE_CGPOINT(aCoder, location);
    ORK1_ENCODE_ENUM(aCoder, buttonIdentifier);

}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORK1_DECODE_DOUBLE(aDecoder, duration);
        ORK1_DECODE_DOUBLE(aDecoder, timestamp);
        ORK1_DECODE_CGPOINT(aDecoder, location);
        ORK1_DECODE_ENUM(aDecoder, buttonIdentifier);
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
    ORK1TappingSample *sample = [[[self class] allocWithZone:zone] init];
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


@implementation ORK1PasscodeResult

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_BOOL(aCoder, passcodeSaved);
    ORK1_ENCODE_BOOL(aCoder, touchIdEnabled);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_BOOL(aDecoder, passcodeSaved);
        ORK1_DECODE_BOOL(aDecoder, touchIdEnabled);
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
    ORK1PasscodeResult *result = [super copyWithZone:zone];
    result.passcodeSaved = self.isPasscodeSaved;
    result.touchIdEnabled = self.isTouchIdEnabled;
    return result;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; passcodeSaved: %d touchIDEnabled: %d%@", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], self.isPasscodeSaved, self.isTouchIdEnabled, self.descriptionSuffix];
}

@end


@implementation ORK1RangeOfMotionResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_DOUBLE(aCoder, flexed);
    ORK1_ENCODE_DOUBLE(aCoder, extended);
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_DOUBLE(aDecoder, flexed);
        ORK1_DECODE_DOUBLE(aDecoder, extended);
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
    ORK1RangeOfMotionResult *result = [super copyWithZone:zone];
    result.flexed = self.flexed;
    result.extended = self.extended;
    return result;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"<%@: flexion: %f; extension: %f>", self.class.description, self.flexed, self.extended];
}

@end


@implementation ORK1TowerOfHanoiResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, moves);
    ORK1_ENCODE_BOOL(aCoder, puzzleWasSolved);
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_ARRAY(aDecoder, moves, ORK1TowerOfHanoiMove);
        ORK1_DECODE_BOOL(aDecoder, puzzleWasSolved);
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
    ORK1EqualObjects(self.moves, castObject.moves);
}

- (NSUInteger)hash {
    return super.hash ^ self.puzzleWasSolved ^ self.moves.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1TowerOfHanoiResult *result = [super copyWithZone:zone];
    result.puzzleWasSolved = self.puzzleWasSolved;
    result.moves = [self.moves copy];
    return result;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; puzzleSolved: %d; moves: %@%@", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], self.puzzleWasSolved, self.moves, self.descriptionSuffix];
}

@end


@implementation ORK1TowerOfHanoiMove

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORK1_ENCODE_DOUBLE(aCoder, timestamp);
    ORK1_ENCODE_INTEGER(aCoder, donorTowerIndex);
    ORK1_ENCODE_INTEGER(aCoder, recipientTowerIndex);
    
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORK1_DECODE_DOUBLE(aDecoder, timestamp);
        ORK1_DECODE_INTEGER(aDecoder, donorTowerIndex);
        ORK1_DECODE_INTEGER(aDecoder, recipientTowerIndex);
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
    ORK1TowerOfHanoiMove *move = [[[self class] allocWithZone:zone] init];
    move.timestamp = self.timestamp;
    move.donorTowerIndex = self.donorTowerIndex;
    move.recipientTowerIndex = self.recipientTowerIndex;
    return move;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; timestamp: %@; donorTower: %@; recipientTower: %@>", self.class.description, self, @(self.timestamp), @(self.donorTowerIndex), @(self.recipientTowerIndex)];
}

@end


@implementation ORK1ToneAudiometryResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, outputVolume);
    ORK1_ENCODE_OBJ(aCoder, samples);
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ(aDecoder, outputVolume);
        ORK1_DECODE_OBJ_ARRAY(aDecoder, samples, ORK1ToneAudiometrySample);
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
            ORK1EqualObjects(self.outputVolume, castObject.outputVolume) &&
            ORK1EqualObjects(self.samples, castObject.samples)) ;
}

- (NSUInteger)hash {
    return super.hash ^ self.samples.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1ToneAudiometryResult *result = [super copyWithZone:zone];
    result.outputVolume = [self.outputVolume copy];
    result.samples = [self.samples copy];
    return result;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; outputvolume: %@; samples: %@%@", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], self.outputVolume, self.samples, self.descriptionSuffix];
}

@end


@implementation ORK1ToneAudiometrySample

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORK1_ENCODE_DOUBLE(aCoder, frequency);
    ORK1_ENCODE_ENUM(aCoder, channel);
    ORK1_ENCODE_ENUM(aCoder, channelSelected);
    ORK1_ENCODE_DOUBLE(aCoder, amplitude);
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORK1_DECODE_DOUBLE(aDecoder, frequency);
        ORK1_DECODE_ENUM(aDecoder, channel);
        ORK1_DECODE_ENUM(aDecoder, channelSelected);
        ORK1_DECODE_DOUBLE(aDecoder, amplitude);
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
    ORK1ToneAudiometrySample *sample = [[[self class] allocWithZone:zone] init];
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


@implementation ORK1SpatialSpanMemoryGameTouchSample

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORK1_ENCODE_DOUBLE(aCoder, timestamp);
    ORK1_ENCODE_INTEGER(aCoder, targetIndex);
    ORK1_ENCODE_CGPOINT(aCoder, location);
    ORK1_ENCODE_BOOL(aCoder, correct);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORK1_DECODE_DOUBLE(aDecoder, timestamp);
        ORK1_DECODE_INTEGER(aDecoder, targetIndex);
        ORK1_DECODE_CGPOINT(aDecoder, location);
        ORK1_DECODE_BOOL(aDecoder, correct);
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
    ORK1SpatialSpanMemoryGameTouchSample *sample = [[[self class] allocWithZone:zone] init];
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


@implementation ORK1SpatialSpanMemoryGameRecord

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORK1_ENCODE_UINT32(aCoder, seed);
    ORK1_ENCODE_OBJ(aCoder, sequence);
    ORK1_ENCODE_INTEGER(aCoder, gameSize);
    ORK1_ENCODE_OBJ(aCoder, touchSamples);
    ORK1_ENCODE_INTEGER(aCoder, gameStatus);
    ORK1_ENCODE_INTEGER(aCoder, score);
    ORK1_ENCODE_OBJ(aCoder, targetRects);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORK1_DECODE_UINT32(aDecoder, seed);
        ORK1_DECODE_OBJ_ARRAY(aDecoder, sequence, NSNumber);
        ORK1_DECODE_INTEGER(aDecoder, gameSize);
        ORK1_DECODE_OBJ_ARRAY(aDecoder, touchSamples, ORK1SpatialSpanMemoryGameTouchSample);
        ORK1_DECODE_INTEGER(aDecoder, gameStatus);
        ORK1_DECODE_INTEGER(aDecoder, score);
        ORK1_DECODE_OBJ_ARRAY(aDecoder, targetRects, NSValue);
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return ((self.seed == castObject.seed) &&
            (ORK1EqualObjects(self.sequence, castObject.sequence)) &&
            (ORK1EqualObjects(self.touchSamples, castObject.touchSamples)) &&
            (self.gameSize == castObject.gameSize) &&
            (self.gameStatus == castObject.gameStatus) &&
            (self.score == castObject.score) &&
            (ORK1EqualObjects(self.targetRects, castObject.targetRects)));
}

- (NSUInteger)hash {
    return super.hash ^ [self seed] ^ [self gameSize] ^ [self score] ^ [self gameStatus];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1SpatialSpanMemoryGameRecord *record = [[[self class] allocWithZone:zone] init];
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


@implementation ORK1SpatialSpanMemoryResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_INTEGER(aCoder, score);
    ORK1_ENCODE_INTEGER(aCoder, numberOfGames);
    ORK1_ENCODE_INTEGER(aCoder, numberOfFailures);
    ORK1_ENCODE_OBJ(aCoder, gameRecords);
    
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_INTEGER(aDecoder, score);
        ORK1_DECODE_INTEGER(aDecoder, numberOfGames);
        ORK1_DECODE_INTEGER(aDecoder, numberOfFailures);
        ORK1_DECODE_OBJ_ARRAY(aDecoder, gameRecords, ORK1SpatialSpanMemoryGameRecord);
        
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
            (ORK1EqualObjects(self.gameRecords, castObject.gameRecords)));
}

- (NSUInteger)hash {
    return super.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1SpatialSpanMemoryResult *result = [super copyWithZone:zone];
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


@implementation ORK1TappingIntervalResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, samples);
    ORK1_ENCODE_CGRECT(aCoder, buttonRect1);
    ORK1_ENCODE_CGRECT(aCoder, buttonRect2);
    ORK1_ENCODE_CGSIZE(aCoder, stepViewSize);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_ARRAY(aDecoder, samples, ORK1TappingSample);
        ORK1_DECODE_CGRECT(aDecoder, buttonRect1);
        ORK1_DECODE_CGRECT(aDecoder, buttonRect2);
        ORK1_DECODE_CGSIZE(aDecoder, stepViewSize);
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
            ORK1EqualObjects(self.samples, castObject.samples) &&
            CGRectEqualToRect(self.buttonRect1, castObject.buttonRect1) &&
            CGRectEqualToRect(self.buttonRect2, castObject.buttonRect2) &&
            CGSizeEqualToSize(self.stepViewSize, castObject.stepViewSize));
}

- (NSUInteger)hash {
    return super.hash ^ self.samples.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1TappingIntervalResult *result = [super copyWithZone:zone];
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


@implementation ORK1FileResult

- (BOOL)isSaveable {
    return (_fileURL != nil);
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_URL(aCoder, fileURL);
    ORK1_ENCODE_OBJ(aCoder, contentType);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_URL(aDecoder, fileURL);
        ORK1_DECODE_OBJ_CLASS(aDecoder, contentType, NSString);
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
            ORK1EqualFileURLs(self.fileURL, castObject.fileURL) &&
            ORK1EqualObjects(self.contentType, castObject.contentType));
}

- (NSUInteger)hash {
    return super.hash ^ self.fileURL.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1FileResult *result = [super copyWithZone:zone];
    result.fileURL = [self.fileURL copy];
    result.contentType = [self.contentType copy];
    return result;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; fileURL: %@ (%lld bytes)%@", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], self.fileURL, [[NSFileManager defaultManager] attributesOfItemAtPath:self.fileURL.path error:nil].fileSize, self.descriptionSuffix];
}

@end


@implementation ORK1ReactionTimeResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_DOUBLE(aCoder, timestamp);
    ORK1_ENCODE_OBJ(aCoder, fileResult);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_DOUBLE(aDecoder, timestamp);
        ORK1_DECODE_OBJ_CLASS(aDecoder, fileResult, ORK1FileResult);
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
            ORK1EqualObjects(self.fileResult, castObject.fileResult)) ;
}

- (NSUInteger)hash {
    return super.hash ^ [NSNumber numberWithDouble:self.timestamp].hash ^ self.fileResult.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1ReactionTimeResult *result = [super copyWithZone:zone];
    result.fileResult = [self.fileResult copy];
    result.timestamp = self.timestamp;
    return result;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; timestamp: %f; fileResult: %@%@", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], self.timestamp, self.fileResult.description, self.descriptionSuffix];
}

@end


@implementation ORK1TimedWalkResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_DOUBLE(aCoder, distanceInMeters);
    ORK1_ENCODE_DOUBLE(aCoder, timeLimit);
    ORK1_ENCODE_DOUBLE(aCoder, duration);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_DOUBLE(aDecoder, distanceInMeters);
        ORK1_DECODE_DOUBLE(aDecoder, timeLimit);
        ORK1_DECODE_DOUBLE(aDecoder, duration);
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
    ORK1TimedWalkResult *result = [super copyWithZone:zone];
    result.distanceInMeters = self.distanceInMeters;
    result.timeLimit = self.timeLimit;
    result.duration = self.duration;
    return result;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; distance: %@; timeLimit: %@; duration: %@%@", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], @(self.distanceInMeters), @(self.timeLimit), @(self.duration), self.descriptionSuffix];
}

@end


@implementation ORK1PSATSample

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORK1_ENCODE_BOOL(aCoder, correct);
    ORK1_ENCODE_INTEGER(aCoder, digit);
    ORK1_ENCODE_INTEGER(aCoder, answer);
    ORK1_ENCODE_DOUBLE(aCoder, time);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORK1_DECODE_BOOL(aDecoder, correct);
        ORK1_DECODE_INTEGER(aDecoder, digit);
        ORK1_DECODE_INTEGER(aDecoder, answer);
        ORK1_DECODE_DOUBLE(aDecoder, time);
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
    ORK1PSATSample *sample = [[[self class] allocWithZone:zone] init];
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


@implementation ORK1PSATResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_ENUM(aCoder, presentationMode);
    ORK1_ENCODE_DOUBLE(aCoder, interStimulusInterval);
    ORK1_ENCODE_DOUBLE(aCoder, stimulusDuration);
    ORK1_ENCODE_INTEGER(aCoder, length);
    ORK1_ENCODE_INTEGER(aCoder, totalCorrect);
    ORK1_ENCODE_INTEGER(aCoder, totalDyad);
    ORK1_ENCODE_DOUBLE(aCoder, totalTime);
    ORK1_ENCODE_INTEGER(aCoder, initialDigit);
    ORK1_ENCODE_OBJ(aCoder, samples);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_ENUM(aDecoder, presentationMode);
        ORK1_DECODE_DOUBLE(aDecoder, interStimulusInterval);
        ORK1_DECODE_DOUBLE(aDecoder, stimulusDuration);
        ORK1_DECODE_INTEGER(aDecoder, length);
        ORK1_DECODE_INTEGER(aDecoder, totalCorrect);
        ORK1_DECODE_INTEGER(aDecoder, totalDyad);
        ORK1_DECODE_DOUBLE(aDecoder, totalTime);
        ORK1_DECODE_INTEGER(aDecoder, initialDigit);
        ORK1_DECODE_OBJ_ARRAY(aDecoder, samples, ORK1PSATSample);
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
            ORK1EqualObjects(self.samples, castObject.samples)) ;
}

- (NSUInteger)hash {
    return super.hash ^ self.samples.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1PSATResult *result = [super copyWithZone:zone];
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


@implementation ORK1StroopResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_DOUBLE(aCoder, startTime);
    ORK1_ENCODE_DOUBLE(aCoder, endTime);
    ORK1_ENCODE_OBJ(aCoder, color);
    ORK1_ENCODE_OBJ(aCoder, text);
    ORK1_ENCODE_OBJ(aCoder, colorSelected);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_DOUBLE(aDecoder, startTime);
        ORK1_DECODE_DOUBLE(aDecoder, endTime);
        ORK1_DECODE_OBJ_CLASS(aDecoder, color, NSString);
        ORK1_DECODE_OBJ_CLASS(aDecoder, text, NSString);
        ORK1_DECODE_OBJ_CLASS(aDecoder, colorSelected, NSString);
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
            ORK1EqualObjects(self.color, castObject.color) &&
            ORK1EqualObjects(self.text, castObject.text) &&
            ORK1EqualObjects(self.colorSelected, castObject.colorSelected));
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1StroopResult *result = [super copyWithZone:zone];
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


@implementation ORK1HolePegTestResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_ENUM(aCoder, movingDirection);
    ORK1_ENCODE_BOOL(aCoder, dominantHandTested);
    ORK1_ENCODE_INTEGER(aCoder, numberOfPegs);
    ORK1_ENCODE_INTEGER(aCoder, threshold);
    ORK1_ENCODE_BOOL(aCoder, rotated);
    ORK1_ENCODE_INTEGER(aCoder, totalSuccesses);
    ORK1_ENCODE_INTEGER(aCoder, totalFailures);
    ORK1_ENCODE_DOUBLE(aCoder, totalTime);
    ORK1_ENCODE_DOUBLE(aCoder, totalDistance);
    ORK1_ENCODE_OBJ(aCoder, samples);
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_ENUM(aDecoder, movingDirection);
        ORK1_DECODE_BOOL(aDecoder, dominantHandTested);
        ORK1_DECODE_INTEGER(aDecoder, numberOfPegs);
        ORK1_DECODE_INTEGER(aDecoder, threshold);
        ORK1_DECODE_BOOL(aDecoder, rotated);
        ORK1_DECODE_INTEGER(aDecoder, totalSuccesses);
        ORK1_DECODE_INTEGER(aDecoder, totalFailures);
        ORK1_DECODE_DOUBLE(aDecoder, totalTime);
        ORK1_DECODE_DOUBLE(aDecoder, totalDistance);
        ORK1_DECODE_OBJ_ARRAY(aDecoder, samples, ORK1ToneAudiometrySample);
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
            ORK1EqualObjects(self.samples, castObject.samples)) ;
}

- (NSUInteger)hash {
    return super.hash ^ self.samples.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1HolePegTestResult *result = [super copyWithZone:zone];
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


@implementation ORK1HolePegTestSample

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORK1_ENCODE_DOUBLE(aCoder, time);
    ORK1_ENCODE_DOUBLE(aCoder, distance);
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORK1_DECODE_DOUBLE(aDecoder, time);
        ORK1_DECODE_DOUBLE(aDecoder, distance);
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
    ORK1HolePegTestSample *sample = [[[self class] allocWithZone:zone] init];
    sample.time = self.time;
    sample.distance = self.distance;
    return sample;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; time: %@; distance: %@>", self.class.description, self, @(self.time), @(self.distance)];
}

@end


@implementation ORK1DataResult

- (BOOL)isSaveable {
    return (_data != nil);
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, data);
    ORK1_ENCODE_OBJ(aCoder, filename);
    ORK1_ENCODE_OBJ(aCoder, contentType);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, data, NSData);
        ORK1_DECODE_OBJ_CLASS(aDecoder, filename, NSString);
        ORK1_DECODE_OBJ_CLASS(aDecoder, contentType, NSString);
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
            ORK1EqualObjects(self.data, castObject.data) &&
            ORK1EqualObjects(self.filename, castObject.filename) &&
            ORK1EqualObjects(self.contentType, castObject.contentType));
}

- (NSUInteger)hash {
    return super.hash ^ self.filename.hash ^ self.contentType.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1DataResult *result = [super copyWithZone:zone];
    result.data = self.data;
    result.filename = self.filename;
    result.contentType = self.contentType;

    return result;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; data: %@; filename: %@; contentType: %@%@", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], self.data, self.filename, self.contentType, self.descriptionSuffix];
}

@end


@implementation ORK1ConsentSignatureResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, signature);
    ORK1_ENCODE_BOOL(aCoder, consented);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, signature, ORK1ConsentSignature);
        ORK1_DECODE_BOOL(aDecoder, consented);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1ConsentSignatureResult *result = [super copyWithZone:zone];
    result.signature = _signature;
    result.consented = _consented;
    return result;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORK1EqualObjects(self.signature, castObject.signature) &&
            (self.consented == castObject.consented));
}

- (NSUInteger)hash {
    return super.hash ^ self.signature.hash;
}

- (void)applyToDocument:(ORK1ConsentDocument *)document {
    __block NSUInteger indexToBeReplaced = NSNotFound;
    [[document signatures] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ORK1ConsentSignature *signature = obj;
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


@implementation ORK1QuestionResult

- (BOOL)isSaveable {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_ENUM(aCoder, questionType);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_ENUM(aDecoder, questionType);
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
    ORK1QuestionResult *result = [super copyWithZone:zone];
    result.questionType = self.questionType;
    return result;
}

- (NSObject *)validateAnswer:(id)answer {
    if (answer == ORK1NullAnswerValue()) {
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
            [indentatedAnswerDescription appendFormat:@"%@%@", ORK1PaddingWithNumberOfSpaces(numberOfPaddingSpaces + NumberOfPaddingSpacesForIndentationLevel), answerLineString];
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


@implementation ORK1ScaleQuestionResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, scaleAnswer);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, scaleAnswer, NSNumber);
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
            ORK1EqualObjects(self.scaleAnswer, castObject.scaleAnswer));
}

- (NSUInteger)hash {
    return super.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1ScaleQuestionResult *result = [super copyWithZone:zone];
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


@implementation ORK1ChoiceQuestionResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, choiceAnswers);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_ARRAY(aDecoder, choiceAnswers, NSObject);
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
            ORK1EqualObjects(self.choiceAnswers, castObject.choiceAnswers));
}

- (NSUInteger)hash {
    return super.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1ChoiceQuestionResult *result = [super copyWithZone:zone];
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


@implementation ORK1MultipleComponentQuestionResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, componentsAnswer);
    ORK1_ENCODE_OBJ(aCoder, separator);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_ARRAY(aDecoder, componentsAnswer, NSObject);
        ORK1_DECODE_OBJ_CLASS(aDecoder, separator, NSString);
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
            ORK1EqualObjects(self.componentsAnswer, castObject.componentsAnswer) &&
            ORK1EqualObjects(self.separator, castObject.separator));
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


@implementation ORK1BooleanQuestionResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, booleanAnswer);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, booleanAnswer, NSNumber);
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
            ORK1EqualObjects(self.booleanAnswer, castObject.booleanAnswer));
}

- (NSUInteger)hash {
    return super.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1BooleanQuestionResult *result = [super copyWithZone:zone];
    result->_booleanAnswer = [self.booleanAnswer copyWithZone:zone];
    return result;
}

+ (Class)answerClass {
    return [NSNumber class];
}

- (void)setAnswer:(id)answer {
    if ([answer isKindOfClass:[NSArray class]]) {
        // Because ORK1BooleanAnswerFormat has ORK1ChoiceAnswerFormat as its implied format.
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


@implementation ORK1TextQuestionResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, textAnswer);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, textAnswer, NSString);
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
            ORK1EqualObjects(self.textAnswer, castObject.textAnswer));
}

- (NSUInteger)hash {
    return super.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1TextQuestionResult *result = [super copyWithZone:zone];
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


@implementation ORK1NumericQuestionResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, numericAnswer);
    ORK1_ENCODE_OBJ(aCoder, unit);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, numericAnswer, NSNumber);
        ORK1_DECODE_OBJ_CLASS(aDecoder, unit, NSString);
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
            ORK1EqualObjects(self.numericAnswer, castObject.numericAnswer) &&
            ORK1EqualObjects(self.unit, castObject.unit));
}

- (NSUInteger)hash {
    return super.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1NumericQuestionResult *result = [super copyWithZone:zone];
    result->_unit = [self.unit copyWithZone:zone];
    result->_numericAnswer = [self.numericAnswer copyWithZone:zone];
    return result;
}

+ (Class)answerClass {
    return [NSNumber class];
}

- (void)setAnswer:(id)answer {
    if (answer == ORK1NullAnswerValue()) {
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


@implementation ORK1TimeOfDayQuestionResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, dateComponentsAnswer);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, dateComponentsAnswer, NSDateComponents);
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
            ORK1EqualObjects(self.dateComponentsAnswer, castObject.dateComponentsAnswer));
}

- (NSUInteger)hash {
    return super.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1TimeOfDayQuestionResult *result = [super copyWithZone:zone];
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


@implementation ORK1TimeIntervalQuestionResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, intervalAnswer);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, intervalAnswer, NSNumber);
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
            ORK1EqualObjects(self.intervalAnswer, castObject.intervalAnswer));
}

- (NSUInteger)hash {
    return super.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1TimeIntervalQuestionResult *result = [super copyWithZone:zone];
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


@implementation ORK1DateQuestionResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, calendar);
    ORK1_ENCODE_OBJ(aCoder, timeZone);
    ORK1_ENCODE_OBJ(aCoder, dateAnswer);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, calendar, NSCalendar);
        ORK1_DECODE_OBJ_CLASS(aDecoder, timeZone, NSTimeZone);
        ORK1_DECODE_OBJ_CLASS(aDecoder, dateAnswer, NSDate);
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
            ORK1EqualObjects(self.timeZone, castObject.timeZone) &&
            ORK1EqualObjects(self.calendar, castObject.calendar) &&
            ORK1EqualObjects(self.dateAnswer, castObject.dateAnswer));
}

- (NSUInteger)hash {
    return super.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1DateQuestionResult *result = [super copyWithZone:zone];
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


@interface ORK1CollectionResult ()

- (void)setResultsCopyObjects:(NSArray *)results;

@end


@implementation ORK1CollectionResult

- (BOOL)isSaveable {
    BOOL saveable = NO;
    
    for (ORK1Result *result in _results) {
        if ([result isSaveable]) {
            saveable = YES;
            break;
        }
    }
    return saveable;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, results);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_ARRAY(aDecoder, results, ORK1Result);
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
            ORK1EqualObjects(self.results, castObject.results));
}

- (NSUInteger)hash {
    return super.hash ^ self.results.hash;
}

- (void)setResultsCopyObjects:(NSArray *)results {
    _results = ORK1ArrayCopyObjects(results);
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1CollectionResult *result = [super copyWithZone:zone];
    [result setResultsCopyObjects: self.results];
    return result;
}

- (NSArray *)results {
    if (_results == nil) {
        _results = [NSArray new];
    }
    return _results;
}

- (ORK1Result *)resultForIdentifier:(NSString *)identifier {
    
    if (identifier == nil) {
        return nil;
    }
    
    __block ORK1QuestionResult *result = nil;
    
    // Look through the result set in reverse-order to account for the possibility of
    // multiple results with the same identifier (due to a navigation loop)
    NSEnumerator *enumerator = self.results.reverseObjectEnumerator;
    id obj = enumerator.nextObject;
    while ((result== nil) && (obj != nil)) {
        
        if (NO == [obj isKindOfClass:[ORK1Result class]]) {
            @throw [NSException exceptionWithName:NSGenericException reason:[NSString stringWithFormat: @"Expected result object to be ORK1Result type: %@", obj] userInfo:nil];
        }
        
        NSString *anIdentifier = [(ORK1Result *)obj identifier];
        if ([anIdentifier isEqual:identifier]) {
            result = obj;
        }
        obj = enumerator.nextObject;
    }
    
    return result;
}

- (ORK1Result *)firstResult {
    
    return self.results.firstObject;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    NSMutableString *description = [NSMutableString stringWithFormat:@"%@; results: (", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces]];
    
    NSUInteger numberOfResults = self.results.count;
    [self.results enumerateObjectsUsingBlock:^(ORK1Result *result, NSUInteger idx, BOOL *stop) {
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
    
    [description appendFormat:@"%@)%@", ORK1PaddingWithNumberOfSpaces((numberOfResults == 0) ? 0 : numberOfPaddingSpaces), self.descriptionSuffix];
    return [description copy];
}

@end


@implementation ORK1TaskResult

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
    ORK1_ENCODE_OBJ(aCoder, taskRunUUID);
    ORK1_ENCODE_URL(aCoder, outputDirectory);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, taskRunUUID, NSUUID);
        ORK1_DECODE_URL(aDecoder, outputDirectory);
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
            ORK1EqualObjects(self.taskRunUUID, castObject.taskRunUUID) &&
            ORK1EqualFileURLs(self.outputDirectory, castObject.outputDirectory));
}

- (NSUInteger)hash {
    return super.hash ^ self.taskRunUUID.hash ^ self.outputDirectory.hash;
}


- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1TaskResult *result = [super copyWithZone:zone];
    result->_taskRunUUID = [self.taskRunUUID copy];
    result->_outputDirectory =  [self.outputDirectory copy];
    return result;
}

- (ORK1StepResult *)stepResultForStepIdentifier:(NSString *)stepIdentifier {
    return (ORK1StepResult *)[self resultForIdentifier:stepIdentifier];
}

@end


@implementation ORK1Location

+ (instancetype)new {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    ORK1ThrowMethodUnavailableException();
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
    ORK1_ENCODE_OBJ(aCoder, userInput);
    ORK1_ENCODE_COORDINATE(aCoder, coordinate);
    ORK1_ENCODE_OBJ(aCoder, addressDictionary);

    [aCoder encodeObject:@(_region.center.latitude) forKey:RegionCenterLatitudeKey];
    [aCoder encodeObject:@(_region.center.longitude) forKey:RegionCenterLongitudeKey];
    [aCoder encodeObject:_region.identifier forKey:RegionIdentifierKey];
    [aCoder encodeObject:@(_region.radius) forKey:RegionRadiusKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, userInput, NSString);
        ORK1_DECODE_COORDINATE(aDecoder, coordinate);
        ORK1_DECODE_OBJ_CLASS(aDecoder, addressDictionary, NSDictionary);
        ORK1_DECODE_OBJ_CLASS(aDecoder, region, CLCircularRegion);
        
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
    return (ORK1EqualObjects(self.userInput, castObject.userInput) &&
            ORK1EqualObjects(self.addressDictionary, castObject.addressDictionary) &&
            ORK1EqualObjects(self.region, castObject.region) &&
            ORK1EqualObjects([NSValue valueWithMKCoordinate:self.coordinate], [NSValue valueWithMKCoordinate:castObject.coordinate]));
}

@end


@implementation ORK1LocationQuestionResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, locationAnswer);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, locationAnswer, ORK1Location);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame && ORK1EqualObjects(self.locationAnswer, castObject.locationAnswer));
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1LocationQuestionResult *result = [super copyWithZone:zone];
    result->_locationAnswer = [self.locationAnswer copy];
    return result;
}

+ (Class)answerClass {
    return [ORK1Location class];
}

- (void)setAnswer:(id)answer {
    answer = [self validateAnswer:answer];
    self.locationAnswer = [answer copy];
}

- (id)answer {
    return self.locationAnswer;
}

@end


@implementation ORK1StepResult

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
    ORK1_ENCODE_OBJ(aCoder, enabledAssistiveTechnology);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, enabledAssistiveTechnology, NSString);
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
            ORK1EqualObjects(self.enabledAssistiveTechnology, castObject.enabledAssistiveTechnology));
}

- (NSUInteger)hash {
    return super.hash ^ _enabledAssistiveTechnology.hash;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1StepResult *result = [super copyWithZone:zone];
    result->_enabledAssistiveTechnology = [_enabledAssistiveTechnology copy];
    return result;
}

- (NSString *)descriptionPrefixWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; enabledAssistiveTechnology: %@", [super descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], _enabledAssistiveTechnology ? : @"None"];
}

@end


@implementation ORK1SignatureResult

- (instancetype)initWithSignatureImage:(UIImage *)signatureImage
                         signaturePath:(NSArray <UIBezierPath *> *)signaturePath {
    self = [super init];
    if (self) {
        _signatureImage = [signatureImage copy];
        _signaturePath = ORK1ArrayCopyObjects(signaturePath);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_IMAGE(aCoder, signatureImage);
    ORK1_ENCODE_OBJ(aCoder, signaturePath);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_IMAGE(aDecoder, signatureImage);
        ORK1_DECODE_OBJ_ARRAY(aDecoder, signaturePath, UIBezierPath);
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
            ORK1EqualObjects(self.signatureImage, castObject.signatureImage) &&
            ORK1EqualObjects(self.signaturePath, castObject.signaturePath));
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1SignatureResult *result = [super copyWithZone:zone];
    result->_signatureImage = [_signatureImage copy];
    result->_signaturePath = ORK1ArrayCopyObjects(_signaturePath);
    return result;
}

@end


@implementation ORK1VideoInstructionStepResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeFloat:self.playbackStoppedTime forKey:@"playbackStoppedTime"];
    ORK1_ENCODE_BOOL(aCoder, playbackCompleted);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.playbackStoppedTime = [aDecoder decodeFloatForKey:@"playbackStoppedTime"];
        ORK1_DECODE_BOOL(aDecoder, playbackCompleted);
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
    ORK1VideoInstructionStepResult *result = [super copyWithZone:zone];
    result->_playbackStoppedTime = self.playbackStoppedTime;
    result->_playbackCompleted = self.playbackCompleted;
    return result;
}

@end


@implementation ORK1PageResult

- (instancetype)initWithPageStep:(ORK1PageStep *)step stepResult:(ORK1StepResult*)result {
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
                for (ORK1Result *subresult in filteredResults) {
                    ORK1Result *copy = [subresult copy];
                    copy.identifier = [subresult.identifier substringFromIndex:prefix.length];
                    [subresults addObject:copy];
                }
                [results addObject:[[ORK1StepResult alloc] initWithStepIdentifier:identifier results:subresults]];
            }
        }
        self.results = results;
    }
    return self;
}

- (void)addStepResult:(ORK1StepResult *)stepResult {
    if (stepResult == nil) {
        return;
    }
    
    // Remove previous step result and add the new one
    NSMutableArray *results = [self.results mutableCopy] ?: [NSMutableArray new];
    ORK1Result *previousResult = [self resultForIdentifier:stepResult.identifier];
    if (previousResult) {
        [results removeObject:previousResult];
    }
    [results addObject:stepResult];
    self.results = results;
}

- (void)removeStepResultWithIdentifier:(NSString *)identifier {
    ORK1Result *result = [self resultForIdentifier:identifier];
    if (result != nil) {
        NSMutableArray *results = [self.results mutableCopy];
        [results removeObject:result];
        self.results = results;
    }
}

- (void)removeStepResultsAfterStepWithIdentifier:(NSString *)identifier {
    ORK1Result *result = [self resultForIdentifier:identifier];
    if (result != nil) {
        NSUInteger idx = [self.results indexOfObject:result];
        if (idx != NSNotFound) {
            self.results = [self.results subarrayWithRange:NSMakeRange(0, idx)];
        }
    }
}

- (NSArray <ORK1Result *> *)flattenResults {
    NSMutableArray *results = [NSMutableArray new];
    for (ORK1Result *result in self.results) {
        if ([result isKindOfClass:[ORK1StepResult class]]) {
            ORK1StepResult *stepResult = (ORK1StepResult *)result;
            if (stepResult.results.count > 0) {
                // For each subresult in this step, append the step identifier onto the result
                for (ORK1Result *result in stepResult.results) {
                    ORK1Result *copy = [result copy];
                    NSString *subIdentifier = result.identifier ?: [NSString stringWithFormat:@"%@", @(result.hash)];
                    copy.identifier = [NSString stringWithFormat:@"%@.%@", stepResult.identifier, subIdentifier];
                    [results addObject:copy];
                }
            } else {
                // If this is an empty step result then add a base class instance with this identifier
                [results addObject:[[ORK1Result alloc] initWithIdentifier:stepResult.identifier]];
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


@implementation ORK1TrailmakingResult

- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super initWithIdentifier:identifier];
    if (self) {
        _taps = @[];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_INTEGER(aCoder, numberOfErrors);
    ORK1_ENCODE_OBJ(aCoder, taps);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_INTEGER(aDecoder, numberOfErrors);
        ORK1_DECODE_OBJ_ARRAY(aDecoder, taps, ORK1TrailmakingTap);
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
            ORK1EqualObjects(self.taps, castObject.taps));
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1TrailmakingResult *result = [super copyWithZone:zone];
    result.numberOfErrors = self.numberOfErrors;
    result.taps = ORK1ArrayCopyObjects(self.taps);
    return result;
}

@end


@implementation ORK1TrailmakingTap

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORK1_ENCODE_DOUBLE(aCoder, timestamp);
    ORK1_ENCODE_INTEGER(aCoder, index);
    ORK1_ENCODE_BOOL(aCoder, incorrect);
    
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORK1_DECODE_DOUBLE(aDecoder, timestamp);
        ORK1_DECODE_INTEGER(aDecoder, index);
        ORK1_DECODE_BOOL(aDecoder, incorrect);
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
    ORK1TrailmakingTap *tap = [[[self class] allocWithZone:zone] init];
    tap.timestamp = self.timestamp;
    tap.index = self.index;
    tap.incorrect = self.incorrect;
    return tap;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; timestamp: %@; index: %@; error: %@>", self.class.description, self, @(self.timestamp), @(self.index), @(self.incorrect)];
}

@end

@implementation ORK1WebViewStepResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, result);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, result, NSString);
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
    ORK1WebViewStepResult *result = [super copyWithZone:zone];
    result->_result = self.result;
    return result;
}

@end
