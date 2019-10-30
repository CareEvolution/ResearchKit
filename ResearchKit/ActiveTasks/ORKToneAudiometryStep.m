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


#import "ORKToneAudiometryStep.h"

#import "ORKToneAudiometryStepViewController.h"

#import "ORKHelpers_Internal.h"


@implementation ORK1ToneAudiometryStep

+ (Class)stepViewControllerClass {
    return [ORK1ToneAudiometryStepViewController class];
}

- (void)validateParameters {
    [super validateParameters];

    NSTimeInterval const ORK1ToneAudiometryTaskToneMinimumDuration = 5.0;

    if (self.toneDuration < ORK1ToneAudiometryTaskToneMinimumDuration) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"tone duration cannot be shorter than %@ seconds.", @(ORK1ToneAudiometryTaskToneMinimumDuration)]  userInfo:nil];
    }
}

- (BOOL)startsFinished {
    return NO;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1ToneAudiometryStep *step = [super copyWithZone:zone];
    step.toneDuration = self.toneDuration;
    return step;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_DOUBLE(aDecoder, toneDuration);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_DOUBLE(aCoder, toneDuration);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];

    __typeof(self) castObject = object;
    return (isParentSame &&
            (self.toneDuration == castObject.toneDuration)) ;
}

@end
