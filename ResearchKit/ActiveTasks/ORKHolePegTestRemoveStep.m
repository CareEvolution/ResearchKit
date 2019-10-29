/*
 Copyright (c) 2015, Shazino SAS. All rights reserved.
 
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


#import "ORKHolePegTestRemoveStep.h"

#import "ORKHolePegTestRemoveStepViewController.h"

#import "ORKHelpers_Internal.h"


@implementation ORKLegacyHolePegTestRemoveStep

+ (Class)stepViewControllerClass {
    return [ORKLegacyHolePegTestRemoveStepViewController class];
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super initWithIdentifier:identifier];
    if (self) {
        self.shouldShowDefaultTimer = NO;
        self.shouldContinueOnFinish = YES;
    }
    return self;
}

- (void)validateParameters {
    [super validateParameters];
    
    int const ORKLegacyHolePegTestMinimumNumberOfPegs = 1;
    
    double const ORKLegacyHolePegTestMinimumThreshold = 0.0f;
    double const ORKLegacyHolePegTestMaximumThreshold = 1.0f;
    
    NSTimeInterval const ORKLegacyHolePegTestMinimumDuration = 1.0f;
    
    if (self.movingDirection != ORKLegacyBodySagittalLeft &&
        self.movingDirection != ORKLegacyBodySagittalRight) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"moving direction should be left or right."] userInfo:nil];
    }
    
    if (self.numberOfPegs < ORKLegacyHolePegTestMinimumNumberOfPegs) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"number of pegs must be greater than or equal to %@.", @(ORKLegacyHolePegTestMinimumNumberOfPegs)] userInfo:nil];
    }
    
    if (self.threshold < ORKLegacyHolePegTestMinimumThreshold ||
        self.threshold > ORKLegacyHolePegTestMaximumThreshold) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"threshold must be greater than or equal to %@ and lower or equal to %@.", @(ORKLegacyHolePegTestMinimumThreshold), @(ORKLegacyHolePegTestMaximumThreshold)] userInfo:nil];
    }
    
    if (self.stepDuration < ORKLegacyHolePegTestMinimumDuration) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"duration cannot be shorter than %@ seconds.", @(ORKLegacyHolePegTestMinimumDuration)] userInfo:nil];
    }
}

- (BOOL)allowsBackNavigation {
    return NO;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_ENUM(aDecoder, movingDirection);
        ORKLegacy_DECODE_BOOL(aDecoder, dominantHandTested);
        ORKLegacy_DECODE_INTEGER(aDecoder, numberOfPegs);
        ORKLegacy_DECODE_DOUBLE(aDecoder, threshold);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_ENUM(aCoder, movingDirection);
    ORKLegacy_ENCODE_BOOL(aCoder, dominantHandTested);
    ORKLegacy_ENCODE_INTEGER(aCoder, numberOfPegs);
    ORKLegacy_ENCODE_DOUBLE(aCoder, threshold);
}

- (instancetype)copyWithZone:(NSZone *)zone {
    __typeof(self) step = [super copyWithZone:zone];
    step.movingDirection = self.movingDirection;
    step.dominantHandTested = self.dominantHandTested;
    step.numberOfPegs = self.numberOfPegs;
    step.threshold = self.threshold;
    return step;
}

- (NSUInteger)hash {
    return [super hash] ^ self.movingDirection ^ self.dominantHandTested ^ self.numberOfPegs ^ (NSInteger)(self.threshold * 100);
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            (self.movingDirection == castObject.movingDirection) &&
            (self.dominantHandTested == castObject.dominantHandTested) &&
            (self.numberOfPegs == castObject.numberOfPegs) &&
            (self.threshold == castObject.threshold));
}

@end
