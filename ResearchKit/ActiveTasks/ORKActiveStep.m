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


#import "ORKActiveStep.h"
#import "ORKActiveStep_Internal.h"

#import "ORKActiveStepViewController.h"
#import "ORKRecorder_Private.h"

#import "ORKStep_Private.h"

#import "ORKHelpers_Internal.h"


@implementation ORKLegacyActiveStep

+ (Class)stepViewControllerClass {
    return [ORKLegacyActiveStepViewController class];
}

- (BOOL)startsFinished {
    return (_stepDuration == 0);
}

- (BOOL)hasCountDown {
    return (_stepDuration > 0) && _shouldShowDefaultTimer;
}

- (BOOL)hasTitle {
    NSString *title = self.title;
    return  (title != nil && title.length > 0);
}

- (BOOL)hasText {
    NSString *text = self.text;
    return  (text != nil && text.length > 0);
}

- (BOOL)hasVoice {
    BOOL hasSpokenInstruction = (_spokenInstruction != nil && _spokenInstruction.length > 0);
    BOOL hasFinishedSpokenInstruction = (_finishedSpokenInstruction != nil && _finishedSpokenInstruction.length > 0);
    return  (hasSpokenInstruction || hasFinishedSpokenInstruction);
}

- (BOOL)isRestorable {
    return NO;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super initWithIdentifier:identifier];
    if (self) {
        self.shouldShowDefaultTimer = YES;
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyActiveStep *step = [super copyWithZone:zone];
    step.stepDuration = self.stepDuration;
    step.shouldStartTimerAutomatically = self.shouldStartTimerAutomatically;
    step.shouldSpeakCountDown = self.shouldSpeakCountDown;
    step.shouldSpeakRemainingTimeAtHalfway = self.shouldSpeakRemainingTimeAtHalfway;
    step.shouldShowDefaultTimer = self.shouldShowDefaultTimer;
    step.shouldPlaySoundOnStart = self.shouldPlaySoundOnStart;
    step.shouldPlaySoundOnFinish = self.shouldPlaySoundOnFinish;
    step.shouldVibrateOnStart = self.shouldVibrateOnStart;
    step.shouldVibrateOnFinish = self.shouldVibrateOnFinish;
    step.shouldUseNextAsSkipButton = self.shouldUseNextAsSkipButton;
    step.shouldContinueOnFinish = self.shouldContinueOnFinish;
    step.spokenInstruction = self.spokenInstruction;
    step.finishedSpokenInstruction = self.finishedSpokenInstruction;
    step.recorderConfigurations = [self.recorderConfigurations copy];
    step.image = self.image;
    return step;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self ) {
        ORKLegacy_DECODE_DOUBLE(aDecoder, stepDuration);
        ORKLegacy_DECODE_BOOL(aDecoder, shouldStartTimerAutomatically);
        ORKLegacy_DECODE_BOOL(aDecoder, shouldSpeakCountDown);
        ORKLegacy_DECODE_BOOL(aDecoder, shouldSpeakRemainingTimeAtHalfway);
        ORKLegacy_DECODE_BOOL(aDecoder, shouldShowDefaultTimer);
        ORKLegacy_DECODE_BOOL(aDecoder, shouldPlaySoundOnStart);
        ORKLegacy_DECODE_BOOL(aDecoder, shouldPlaySoundOnFinish);
        ORKLegacy_DECODE_BOOL(aDecoder, shouldVibrateOnStart);
        ORKLegacy_DECODE_BOOL(aDecoder, shouldVibrateOnFinish);
        ORKLegacy_DECODE_BOOL(aDecoder, shouldUseNextAsSkipButton);
        ORKLegacy_DECODE_BOOL(aDecoder, shouldContinueOnFinish);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, spokenInstruction, NSString);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, finishedSpokenInstruction, NSString);
        ORKLegacy_DECODE_IMAGE(aDecoder, image);
        ORKLegacy_DECODE_OBJ_ARRAY(aDecoder, recorderConfigurations, ORKLegacyRecorderConfiguration);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_DOUBLE(aCoder, stepDuration);
    ORKLegacy_ENCODE_BOOL(aCoder, shouldStartTimerAutomatically);
    ORKLegacy_ENCODE_BOOL(aCoder, shouldSpeakCountDown);
    ORKLegacy_ENCODE_BOOL(aCoder, shouldSpeakRemainingTimeAtHalfway);
    ORKLegacy_ENCODE_BOOL(aCoder, shouldShowDefaultTimer);
    ORKLegacy_ENCODE_BOOL(aCoder, shouldPlaySoundOnStart);
    ORKLegacy_ENCODE_BOOL(aCoder, shouldPlaySoundOnFinish);
    ORKLegacy_ENCODE_BOOL(aCoder, shouldVibrateOnStart);
    ORKLegacy_ENCODE_BOOL(aCoder, shouldVibrateOnFinish);
    ORKLegacy_ENCODE_BOOL(aCoder, shouldUseNextAsSkipButton);
    ORKLegacy_ENCODE_BOOL(aCoder, shouldContinueOnFinish);
    ORKLegacy_ENCODE_IMAGE(aCoder, image);
    ORKLegacy_ENCODE_OBJ(aCoder, spokenInstruction);
    ORKLegacy_ENCODE_OBJ(aCoder, finishedSpokenInstruction);
    ORKLegacy_ENCODE_OBJ(aCoder, recorderConfigurations);
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORKLegacyEqualObjects(self.spokenInstruction, castObject.spokenInstruction) &&
            ORKLegacyEqualObjects(self.finishedSpokenInstruction, castObject.finishedSpokenInstruction) &&
            ORKLegacyEqualObjects(self.recorderConfigurations, castObject.recorderConfigurations) &&
            ORKLegacyEqualObjects(self.image, castObject.image) &&
            (self.stepDuration == castObject.stepDuration) &&
            (self.shouldShowDefaultTimer == castObject.shouldShowDefaultTimer) &&
            (self.shouldStartTimerAutomatically == castObject.shouldStartTimerAutomatically) &&
            (self.shouldSpeakCountDown == castObject.shouldSpeakCountDown) &&
            (self.shouldSpeakRemainingTimeAtHalfway == castObject.shouldSpeakRemainingTimeAtHalfway) &&
            (self.shouldPlaySoundOnStart == castObject.shouldPlaySoundOnStart) &&
            (self.shouldPlaySoundOnFinish == castObject.shouldPlaySoundOnFinish) &&
            (self.shouldVibrateOnStart == castObject.shouldVibrateOnStart) &&
            (self.shouldVibrateOnFinish == castObject.shouldVibrateOnFinish) &&
            (self.shouldContinueOnFinish == castObject.shouldContinueOnFinish) &&
            (self.shouldUseNextAsSkipButton == castObject.shouldUseNextAsSkipButton));
}

- (NSSet<HKObjectType *> *)requestedHealthKitTypesForReading {
    NSMutableSet<HKObjectType *> *set = [NSMutableSet set];
    for (ORKLegacyRecorderConfiguration *config in self.recorderConfigurations) {
        NSSet<HKObjectType *> *subset = [config requestedHealthKitTypesForReading];
        if (subset) {
            [set unionSet:subset];
        }
    }
    return set;
}

- (ORKLegacyPermissionMask)requestedPermissions {
    ORKLegacyPermissionMask mask = [super requestedPermissions];
    for (ORKLegacyRecorderConfiguration *config in self.recorderConfigurations) {
        mask |= [config requestedPermissionMask];
    }
    return mask;
}

@end
