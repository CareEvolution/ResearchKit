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


#import "ORKVideoCaptureStep.h"
#import "ORKHelpers_Internal.h"
#import "ORKStep_Private.h"
#import "ORKVideoCaptureStepViewController.h"


@implementation ORKLegacyVideoCaptureStep

+ (Class)stepViewControllerClass {
    return [ORKLegacyVideoCaptureStepViewController class];
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super initWithIdentifier:identifier];
    if (self) {
        self.optional = YES;
        self.duration = @120;
        self.audioMute = NO;
        self.flashMode = AVCaptureFlashModeOff;
        self.devicePosition = AVCaptureDevicePositionBack;
    }
    return self;
}

- (void)setDuration:(NSNumber *)duration {
    _duration = MIN(MAX(duration, @1), @1200);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_IMAGE(aDecoder, templateImage);
        ORKLegacy_DECODE_UIEDGEINSETS(aDecoder, templateImageInsets);
        ORKLegacy_DECODE_OBJ(aDecoder, duration);
        ORKLegacy_DECODE_BOOL(aDecoder, audioMute);
        ORKLegacy_DECODE_ENUM(aDecoder, flashMode);
        ORKLegacy_DECODE_ENUM(aDecoder, devicePosition);
        ORKLegacy_DECODE_OBJ(aDecoder, accessibilityHint);
        ORKLegacy_DECODE_OBJ(aDecoder, accessibilityInstructions);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_IMAGE(aCoder, templateImage);
    ORKLegacy_ENCODE_UIEDGEINSETS(aCoder, templateImageInsets);
    ORKLegacy_ENCODE_OBJ(aCoder, duration);
    ORKLegacy_ENCODE_BOOL(aCoder, audioMute);
    ORKLegacy_ENCODE_ENUM(aCoder, flashMode);
    ORKLegacy_ENCODE_ENUM(aCoder, devicePosition);
    ORKLegacy_ENCODE_OBJ(aCoder, accessibilityHint);
    ORKLegacy_ENCODE_OBJ(aCoder, accessibilityInstructions);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyVideoCaptureStep *step = [super copyWithZone:zone];
    step.templateImage = self.templateImage;
    step.templateImageInsets = self.templateImageInsets;
    step.duration = self.duration;
    step.audioMute = self.audioMute;
    step.flashMode = self.flashMode;
    step.devicePosition = self.devicePosition;
    step.accessibilityHint = self.accessibilityHint;
    step.accessibilityInstructions = self.accessibilityInstructions;
    return step;
}

- (NSUInteger)hash {
    return super.hash ^ self.templateImage.hash ^ self.duration.hash ^ self.audioMute ^ self.flashMode ^ self.devicePosition ^ self.accessibilityHint.hash ^ self.accessibilityInstructions.hash;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return isParentSame &&
    ORKLegacyEqualObjects(self.templateImage, castObject.templateImage) &&
    UIEdgeInsetsEqualToEdgeInsets(self.templateImageInsets, castObject.templateImageInsets) &&
    ORKLegacyEqualObjects(self.duration, castObject.duration) &&
    (self.audioMute == castObject.audioMute) &&
    (self.flashMode == castObject.flashMode) &&
    (self.devicePosition == castObject.devicePosition) &&
    ORKLegacyEqualObjects(self.accessibilityHint, castObject.accessibilityHint) &&
    ORKLegacyEqualObjects(self.accessibilityInstructions, castObject.accessibilityInstructions);
}

@end
