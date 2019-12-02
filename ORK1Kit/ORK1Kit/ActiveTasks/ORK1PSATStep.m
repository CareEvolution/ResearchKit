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


#import "ORK1PSATStep.h"

#import "ORK1PSATStepViewController.h"

#import "ORK1Helpers_Internal.h"


@implementation ORK1PSATStep

+ (Class)stepViewControllerClass {
    return [ORK1PSATStepViewController class];
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super initWithIdentifier:identifier];
    if (self) {
        self.shouldStartTimerAutomatically = YES;
        self.shouldShowDefaultTimer = NO;
        self.shouldContinueOnFinish = YES;
    }
    return self;
}

- (void)validateParameters {
    [super validateParameters];

    NSTimeInterval const ORK1PSATInterStimulusMinimumInterval = 1.0;
    NSTimeInterval const ORK1PSATInterStimulusMaximumInterval = 5.0;
    
    NSTimeInterval const ORK1PSATStimulusMinimumDuration = 0.2;
    
    NSInteger const ORK1PSATSerieMinimumLength = 10;
    NSInteger const ORK1PSATSerieMaximumLength = 120;

    NSTimeInterval totalDuration = (self.seriesLength + 1) * self.interStimulusInterval;
    if (self.stepDuration != totalDuration) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"step duration must be equal to %@ seconds.", @(totalDuration)] userInfo:nil];
    }
    
    if (!(self.presentationMode & ORK1PSATPresentationModeAuditory) &&
        !(self.presentationMode & ORK1PSATPresentationModeVisual)) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"step presentation mode must be auditory and/or visual." userInfo:nil];
    }
    
    if (self.interStimulusInterval < ORK1PSATInterStimulusMinimumInterval ||
        self.interStimulusInterval > ORK1PSATInterStimulusMaximumInterval) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"inter stimulus interval must be greater than or equal to %@ seconds and less than or equal to %@ seconds.", @(ORK1PSATInterStimulusMinimumInterval), @(ORK1PSATInterStimulusMaximumInterval)] userInfo:nil];
    }
    
    if ((self.presentationMode & ORK1PSATPresentationModeVisual) &&
        (self.stimulusDuration < ORK1PSATStimulusMinimumDuration || self.stimulusDuration > self.interStimulusInterval)) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"stimulus duration must be greater than or equal to %@ seconds and less than or equal to %@ seconds.", @(ORK1PSATStimulusMinimumDuration), @(self.interStimulusInterval)] userInfo:nil];
    }
    
    if (self.seriesLength < ORK1PSATSerieMinimumLength ||
        self.seriesLength > ORK1PSATSerieMaximumLength) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"serie length must be greater than or equal to %@ additions and less than or equal to %@ additions.", @(ORK1PSATSerieMinimumLength), @(ORK1PSATSerieMaximumLength)] userInfo:nil];
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
        ORK1_DECODE_ENUM(aDecoder, presentationMode);
        ORK1_DECODE_DOUBLE(aDecoder, interStimulusInterval);
        ORK1_DECODE_DOUBLE(aDecoder, stimulusDuration);
        ORK1_DECODE_INTEGER(aDecoder, seriesLength);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_ENUM(aCoder, presentationMode);
    ORK1_ENCODE_DOUBLE(aCoder, interStimulusInterval);
    ORK1_ENCODE_DOUBLE(aCoder, stimulusDuration);
    ORK1_ENCODE_INTEGER(aCoder, seriesLength);
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1PSATStep *step = [super copyWithZone:zone];
    step.presentationMode = self.presentationMode;
    step.interStimulusInterval = self.interStimulusInterval;
    step.stimulusDuration = self.stimulusDuration;
    step.seriesLength = self.seriesLength;
    return step;
}

- (NSUInteger)hash {
    return [super hash] ^ self.presentationMode ^ (NSInteger)(self.interStimulusInterval*100) ^ (NSInteger)(self.stimulusDuration*100) ^ self.seriesLength;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            (self.presentationMode == castObject.presentationMode) &&
            (self.interStimulusInterval == castObject.interStimulusInterval) &&
            (self.stimulusDuration == castObject.stimulusDuration) &&
            (self.seriesLength == castObject.seriesLength));
}

@end
