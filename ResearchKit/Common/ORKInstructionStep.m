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


#import "ORKInstructionStep.h"

#import "ORKInstructionStepViewController.h"

#import "ORKStep_Private.h"

#import "ORKHelpers_Internal.h"


@implementation ORK1InstructionStep

- (void)setAuxiliaryImage:(UIImage *)auxiliaryImage {
    _auxiliaryImage = auxiliaryImage;
    if (auxiliaryImage) {
        self.shouldTintImages = YES;
    }
}

+ (Class)stepViewControllerClass {
    return [ORK1InstructionStepViewController class];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, detailText, NSString);
        ORK1_DECODE_OBJ_CLASS(aDecoder, footnote, NSString);
        ORK1_DECODE_IMAGE(aDecoder, image);
        ORK1_DECODE_IMAGE(aDecoder, auxiliaryImage);
        ORK1_DECODE_IMAGE(aDecoder, iconImage);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, detailText);
    ORK1_ENCODE_OBJ(aCoder, footnote);
    ORK1_ENCODE_IMAGE(aCoder, image);
    ORK1_ENCODE_IMAGE(aCoder, auxiliaryImage);
    ORK1_ENCODE_IMAGE(aCoder, iconImage);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1InstructionStep *step = [super copyWithZone:zone];
    step.detailText = self.detailText;
    step.footnote = self.footnote;
    step.image = self.image;
    step.auxiliaryImage = self.auxiliaryImage;
    step.iconImage = self.iconImage;
    return step;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return isParentSame &&
        ORK1EqualObjects(self.detailText, castObject.detailText) &&
        ORK1EqualObjects(self.footnote, castObject.footnote) &&
        ORK1EqualObjects(self.image, castObject.image) &&
        ORK1EqualObjects(self.auxiliaryImage, castObject.auxiliaryImage) &&
        ORK1EqualObjects(self.iconImage, castObject.iconImage);
}

- (NSUInteger)hash {
    return super.hash ^ self.detailText.hash ^ self.footnote.hash;
}

@end
