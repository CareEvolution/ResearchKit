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


#import "ORK1HolePegTestRemoveStep.h"

#import "ORK1HolePegTestRemoveStepViewController.h"

#import "ORK1Helpers_Internal.h"


@implementation ORK1HolePegTestRemoveStep

+ (Class)stepViewControllerClass {
    return [ORK1HolePegTestRemoveStepViewController class];
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
    
    int const ORK1HolePegTestMinimumNumberOfPegs = 1;
    
    double const ORK1HolePegTestMinimumThreshold = 0.0f;
    double const ORK1HolePegTestMaximumThreshold = 1.0f;
    
    NSTimeInterval const ORK1HolePegTestMinimumDuration = 1.0f;
    
    if (self.movingDirection != ORK1BodySagittalLeft &&
        self.movingDirection != ORK1BodySagittalRight) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"moving direction should be left or right."] userInfo:nil];
    }
    
    if (self.numberOfPegs < ORK1HolePegTestMinimumNumberOfPegs) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"number of pegs must be greater than or equal to %@.", @(ORK1HolePegTestMinimumNumberOfPegs)] userInfo:nil];
    }
    
    if (self.threshold < ORK1HolePegTestMinimumThreshold ||
        self.threshold > ORK1HolePegTestMaximumThreshold) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"threshold must be greater than or equal to %@ and lower or equal to %@.", @(ORK1HolePegTestMinimumThreshold), @(ORK1HolePegTestMaximumThreshold)] userInfo:nil];
    }
    
    if (self.stepDuration < ORK1HolePegTestMinimumDuration) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"duration cannot be shorter than %@ seconds.", @(ORK1HolePegTestMinimumDuration)] userInfo:nil];
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
        ORK1_DECODE_ENUM(aDecoder, movingDirection);
        ORK1_DECODE_BOOL(aDecoder, dominantHandTested);
        ORK1_DECODE_INTEGER(aDecoder, numberOfPegs);
        ORK1_DECODE_DOUBLE(aDecoder, threshold);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_ENUM(aCoder, movingDirection);
    ORK1_ENCODE_BOOL(aCoder, dominantHandTested);
    ORK1_ENCODE_INTEGER(aCoder, numberOfPegs);
    ORK1_ENCODE_DOUBLE(aCoder, threshold);
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
