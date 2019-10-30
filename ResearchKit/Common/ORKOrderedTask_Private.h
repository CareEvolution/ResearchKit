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


#import <ResearchKitLegacy/ORKOrderedTask.h>


NS_ASSUME_NONNULL_BEGIN

@class ORK1CompletionStep, ORK1Step;


FOUNDATION_EXPORT NSString *const ORK1Instruction0StepIdentifier;
FOUNDATION_EXPORT NSString *const ORK1Instruction1StepIdentifier;
FOUNDATION_EXPORT NSString *const ORK1CountdownStepIdentifier;
FOUNDATION_EXPORT NSString *const ORK1AudioStepIdentifier;
FOUNDATION_EXPORT NSString *const ORK1AudioTooLoudStepIdentifier;
FOUNDATION_EXPORT NSString *const ORK1TappingStepIdentifier;
FOUNDATION_EXPORT NSString *const ORK1ConclusionStepIdentifier;
FOUNDATION_EXPORT NSString *const ORK1FitnessWalkStepIdentifier;
FOUNDATION_EXPORT NSString *const ORK1FitnessRestStepIdentifier;
FOUNDATION_EXPORT NSString *const ORK1ShortWalkOutboundStepIdentifier;
FOUNDATION_EXPORT NSString *const ORK1ShortWalkReturnStepIdentifier;
FOUNDATION_EXPORT NSString *const ORK1ShortWalkRestStepIdentifier;
FOUNDATION_EXPORT NSString *const ORK1SpatialSpanMemoryStepIdentifier;
FOUNDATION_EXPORT NSString *const ORK1StroopStepIdentifier;
FOUNDATION_EXPORT NSString *const ORK1ToneAudiometryPracticeStepIdentifier;
FOUNDATION_EXPORT NSString *const ORK1ToneAudiometryStepIdentifier;
FOUNDATION_EXPORT NSString *const ORK1ReactionTimeStepIdentifier;
FOUNDATION_EXPORT NSString *const ORK1HolePegTestDominantPlaceStepIdentifier;
FOUNDATION_EXPORT NSString *const ORK1HolePegTestDominantRemoveStepIdentifier;
FOUNDATION_EXPORT NSString *const ORK1HolePegTestNonDominantPlaceStepIdentifier;
FOUNDATION_EXPORT NSString *const ORK1HolePegTestNonDominantRemoveStepIdentifier;
FOUNDATION_EXPORT NSString *const ORK1AudioRecorderIdentifier;
FOUNDATION_EXPORT NSString *const ORK1AccelerometerRecorderIdentifier;
FOUNDATION_EXPORT NSString *const ORK1PedometerRecorderIdentifier;
FOUNDATION_EXPORT NSString *const ORK1DeviceMotionRecorderIdentifier;
FOUNDATION_EXPORT NSString *const ORK1LocationRecorderIdentifier;
FOUNDATION_EXPORT NSString *const ORK1HeartRateRecorderIdentifier;

FOUNDATION_EXPORT void ORK1StepArrayAddStep(NSMutableArray *array, ORK1Step *step);

@interface ORK1OrderedTask ()

+ (ORK1CompletionStep *)makeCompletionStep;

@end

NS_ASSUME_NONNULL_END
