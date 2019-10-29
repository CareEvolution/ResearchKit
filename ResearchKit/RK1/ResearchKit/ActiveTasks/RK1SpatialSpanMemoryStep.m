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


#import "RK1SpatialSpanMemoryStep.h"

#import "RK1SpatialSpanMemoryStepViewController.h"

#import "RK1Step_Private.h"

#import "RK1Helpers_Internal.h"


@implementation RK1SpatialSpanMemoryStep

+ (Class)stepViewControllerClass {
    return [RK1SpatialSpanMemoryStepViewController class];
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super initWithIdentifier:identifier];
    if (self) {
        self.shouldStartTimerAutomatically = YES;
        self.shouldContinueOnFinish = YES;
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    RK1SpatialSpanMemoryStep *step = [super copyWithZone:zone];
    step.initialSpan = self.initialSpan;
    step.minimumSpan = self.minimumSpan;
    step.maximumSpan = self.maximumSpan;
    step.playSpeed = self.playSpeed;
    step.maximumTests = self.maximumTests;
    step.maximumConsecutiveFailures = self.maximumConsecutiveFailures;
    step.requireReversal = self.requireReversal;
    step.customTargetImage = self.customTargetImage;
    step.customTargetPluralName = self.customTargetPluralName;
    return step;
}

- (void)validateParameters {
    [super validateParameters];
    
    NSInteger const RK1SpatialSpanMemoryTaskMinimumInitialSpan = 2;
    NSInteger const RK1SpatialSpanMemoryTaskMaximumSpan = 20;
    NSTimeInterval const RK1SpatialSpanMemoryTaskMinimumPlaySpeed = 0.5;
    NSTimeInterval const RK1SpatialSpanMemoryTaskMaximumPlaySpeed = 20;
    NSInteger const RK1SpatialSpanMemoryTaskMinimumMaxTests = 1;
    NSInteger const RK1SpatialSpanMemoryTaskMinimumMaxConsecutiveFailures = 1;
    
    if ( self.initialSpan < RK1SpatialSpanMemoryTaskMinimumInitialSpan) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"initialSpan cannot be less than %@.", @(RK1SpatialSpanMemoryTaskMinimumInitialSpan)]
                                     userInfo:nil];
    }
    
    if ( self.minimumSpan > self.initialSpan) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"initialSpan cannot be less than minimumSpan." userInfo:nil];
    }
    
    if ( self.initialSpan > self.maximumSpan) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"maximumSpan cannot be less than initialSpan." userInfo:nil];
    }
    
    if ( self.maximumSpan > RK1SpatialSpanMemoryTaskMaximumSpan) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"maximumSpan cannot be more than %@.", @(RK1SpatialSpanMemoryTaskMaximumSpan)]
                                     userInfo:nil];
    }
    
    if  (self.playSpeed < RK1SpatialSpanMemoryTaskMinimumPlaySpeed) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"playSpeed cannot be shorter than %@ seconds.", @(RK1SpatialSpanMemoryTaskMinimumPlaySpeed)]
                                     userInfo:nil];
    }
    
    if  (self.playSpeed > RK1SpatialSpanMemoryTaskMaximumPlaySpeed) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"playSpeed cannot be longer than %@ seconds.", @(RK1SpatialSpanMemoryTaskMaximumPlaySpeed)]
                                     userInfo:nil];
    }
    
    if  (self.maximumTests < RK1SpatialSpanMemoryTaskMinimumMaxTests) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"maximumTests cannot be less than %@.", @(RK1SpatialSpanMemoryTaskMinimumMaxTests)]
                                     userInfo:nil];
    }
    
    if  (self.maximumConsecutiveFailures < RK1SpatialSpanMemoryTaskMinimumMaxConsecutiveFailures) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"maximumConsecutiveFailures cannot be less than %@.", @(RK1SpatialSpanMemoryTaskMinimumMaxConsecutiveFailures)]
                                     userInfo:nil];
    }
}

- (BOOL)startsFinished {
    return NO;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        RK1_DECODE_INTEGER(aDecoder, initialSpan);
        RK1_DECODE_INTEGER(aDecoder, minimumSpan);
        RK1_DECODE_INTEGER(aDecoder, maximumSpan);
        RK1_DECODE_INTEGER(aDecoder, playSpeed);
        RK1_DECODE_INTEGER(aDecoder, maximumTests);
        RK1_DECODE_INTEGER(aDecoder, maximumConsecutiveFailures);
        RK1_DECODE_BOOL(aDecoder, requireReversal);
        RK1_DECODE_IMAGE(aDecoder, customTargetImage);
        RK1_DECODE_OBJ_CLASS(aDecoder, customTargetPluralName, NSString);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_INTEGER(aCoder, initialSpan);
    RK1_ENCODE_INTEGER(aCoder, minimumSpan);
    RK1_ENCODE_INTEGER(aCoder, maximumSpan);
    RK1_ENCODE_INTEGER(aCoder, playSpeed);
    RK1_ENCODE_INTEGER(aCoder, maximumTests);
    RK1_ENCODE_INTEGER(aCoder, maximumConsecutiveFailures);
    RK1_ENCODE_BOOL(aCoder, requireReversal);
    RK1_ENCODE_IMAGE(aCoder, customTargetImage);
    RK1_ENCODE_OBJ(aCoder, customTargetPluralName);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            (self.initialSpan == castObject.initialSpan) &&
            (self.minimumSpan == castObject.minimumSpan) &&
            (self.maximumSpan == castObject.maximumSpan) &&
            (self.playSpeed == castObject.playSpeed) &&
            (self.maximumTests == castObject.maximumTests) &&
            (self.maximumConsecutiveFailures == castObject.maximumConsecutiveFailures) &&
            (RK1EqualObjects(self.customTargetPluralName, castObject.customTargetPluralName)) &&
            (self.requireReversal == castObject.requireReversal));
}

- (BOOL)allowsBackNavigation {
    return NO;
}

@end
