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


#import "ORKTimedWalkStep.h"

#import "ORKTimedWalkStepViewController.h"


@implementation ORK1TimedWalkStep

+ (Class)stepViewControllerClass {
    return [ORK1TimedWalkStepViewController class];
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super initWithIdentifier:identifier];
    if (self) {
        self.shouldStartTimerAutomatically = YES;
        self.shouldShowDefaultTimer = NO;
        self.shouldPlaySoundOnStart = YES;
        self.shouldPlaySoundOnFinish = YES;
        self.shouldVibrateOnStart = YES;
        self.shouldVibrateOnFinish = YES;
    }
    return self;
}

- (void)validateParameters {
    [super validateParameters];
    
    double const ORK1TimedWalkMinimumDistanceInMeters = 1.0;
    double const ORK1TimedWalkMaximumDistanceInMeters = 10000.0;
    
    NSTimeInterval const ORK1TimedWalkMinimumDuration = 1.0;
    
    if (self.distanceInMeters < ORK1TimedWalkMinimumDistanceInMeters ||
        self.distanceInMeters > ORK1TimedWalkMaximumDistanceInMeters) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"timed walk distance must be greater than or equal to %@ meters and less than or equal to %@ meters.", @(ORK1TimedWalkMinimumDistanceInMeters), @(ORK1TimedWalkMaximumDistanceInMeters)] userInfo:nil];
    }
    
    if (self.stepDuration < ORK1TimedWalkMinimumDuration) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"duration cannot be shorter than %@ seconds.", @(ORK1TimedWalkMinimumDuration)] userInfo:nil];
    }
}

- (BOOL)allowsBackNavigation {
    return NO;
}

@end
