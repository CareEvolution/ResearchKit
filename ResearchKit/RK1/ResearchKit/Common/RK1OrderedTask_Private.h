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


#import <ResearchKit/RK1OrderedTask.h>


NS_ASSUME_NONNULL_BEGIN

@class RK1CompletionStep, RK1Step;


FOUNDATION_EXPORT NSString *const RK1Instruction0StepIdentifier;
FOUNDATION_EXPORT NSString *const RK1Instruction1StepIdentifier;
FOUNDATION_EXPORT NSString *const RK1CountdownStepIdentifier;
FOUNDATION_EXPORT NSString *const RK1AudioStepIdentifier;
FOUNDATION_EXPORT NSString *const RK1AudioTooLoudStepIdentifier;
FOUNDATION_EXPORT NSString *const RK1TappingStepIdentifier;
FOUNDATION_EXPORT NSString *const RK1ConclusionStepIdentifier;
FOUNDATION_EXPORT NSString *const RK1FitnessWalkStepIdentifier;
FOUNDATION_EXPORT NSString *const RK1FitnessRestStepIdentifier;
FOUNDATION_EXPORT NSString *const RK1ShortWalkOutboundStepIdentifier;
FOUNDATION_EXPORT NSString *const RK1ShortWalkReturnStepIdentifier;
FOUNDATION_EXPORT NSString *const RK1ShortWalkRestStepIdentifier;
FOUNDATION_EXPORT NSString *const RK1SpatialSpanMemoryStepIdentifier;
FOUNDATION_EXPORT NSString *const RK1StroopStepIdentifier;
FOUNDATION_EXPORT NSString *const RK1ToneAudiometryPracticeStepIdentifier;
FOUNDATION_EXPORT NSString *const RK1ToneAudiometryStepIdentifier;
FOUNDATION_EXPORT NSString *const RK1ReactionTimeStepIdentifier;
FOUNDATION_EXPORT NSString *const RK1HolePegTestDominantPlaceStepIdentifier;
FOUNDATION_EXPORT NSString *const RK1HolePegTestDominantRemoveStepIdentifier;
FOUNDATION_EXPORT NSString *const RK1HolePegTestNonDominantPlaceStepIdentifier;
FOUNDATION_EXPORT NSString *const RK1HolePegTestNonDominantRemoveStepIdentifier;
FOUNDATION_EXPORT NSString *const RK1AudioRecorderIdentifier;
FOUNDATION_EXPORT NSString *const RK1AccelerometerRecorderIdentifier;
FOUNDATION_EXPORT NSString *const RK1PedometerRecorderIdentifier;
FOUNDATION_EXPORT NSString *const RK1DeviceMotionRecorderIdentifier;
FOUNDATION_EXPORT NSString *const RK1LocationRecorderIdentifier;
FOUNDATION_EXPORT NSString *const RK1HeartRateRecorderIdentifier;

FOUNDATION_EXPORT void RK1StepArrayAddStep(NSMutableArray *array, RK1Step *step);

@interface RK1OrderedTask ()

+ (RK1CompletionStep *)makeCompletionStep;

@end

NS_ASSUME_NONNULL_END
