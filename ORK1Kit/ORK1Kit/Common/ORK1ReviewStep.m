/*
 Copyright (c) 2015, Oliver Schaefer.
 
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


#import "ORK1ReviewStep.h"
#import "ORK1ReviewStep_Internal.h"

#import "ORK1ReviewStepViewController.h"

#import "ORK1Result.h"

#import "ORK1Helpers_Internal.h"


@implementation ORK1ReviewStep

- (instancetype)initWithIdentifier:(NSString *)identifier
                             steps:(NSArray *)steps
                      resultSource:(id<ORK1TaskResultSource, NSSecureCoding>)resultSource {
    self = [super initWithIdentifier:identifier];
    if (self) {
        _steps = [steps copy];
        _resultSource = resultSource;
        _excludeInstructionSteps = NO;
    }
    return self;
}

+ (instancetype)standaloneReviewStepWithIdentifier:(NSString *)identifier
                                             steps:(NSArray *)steps
                                      resultSource:(id<ORK1TaskResultSource, NSSecureCoding>)resultSource {
    return [[ORK1ReviewStep alloc] initWithIdentifier:identifier steps:steps resultSource:resultSource];
}

+ (instancetype)embeddedReviewStepWithIdentifier:(NSString *)identifier {
    return [[ORK1ReviewStep alloc] initWithIdentifier:identifier steps:nil resultSource:nil];
}

+ (Class)stepViewControllerClass {
    return [ORK1ReviewStepViewController class];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}


- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, steps, NSArray);
        ORK1_DECODE_OBJ(aDecoder, resultSource);
        ORK1_DECODE_BOOL(aDecoder, excludeInstructionSteps);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, steps);
    ORK1_ENCODE_OBJ(aCoder, resultSource);
    ORK1_ENCODE_BOOL(aCoder, excludeInstructionSteps);
}

- (NSUInteger)hash {
    return super.hash ^ _steps.hash ^ _resultSource.hash ^ (_excludeInstructionSteps ? 0xf : 0x0);
}


- (BOOL)isEqual:(id)object {
    __typeof(self) castObject = object;
    return [super isEqual:object] &&
    ORK1EqualObjects(self.steps, castObject.steps) &&
    ORK1EqualObjects(self.resultSource, castObject.resultSource) &&
    self.excludeInstructionSteps == castObject.excludeInstructionSteps;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1ReviewStep *reviewStep = [super copyWithZone:zone];
    reviewStep->_steps = [self.steps copy];
    reviewStep->_resultSource = self.resultSource;
    reviewStep->_excludeInstructionSteps = self.excludeInstructionSteps;
    return reviewStep;
}

- (BOOL)isStandalone {
    return _steps != nil;
}

@end