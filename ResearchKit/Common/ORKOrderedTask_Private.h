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

@class ORKLegacyCompletionStep, ORKLegacyStep;


FOUNDATION_EXPORT NSString *const ORKLegacyInstruction0StepIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyInstruction1StepIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyCountdownStepIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyAudioStepIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyAudioTooLoudStepIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyTappingStepIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyConclusionStepIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyFitnessWalkStepIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyFitnessRestStepIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyShortWalkOutboundStepIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyShortWalkReturnStepIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyShortWalkRestStepIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacySpatialSpanMemoryStepIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyStroopStepIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyToneAudiometryPracticeStepIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyToneAudiometryStepIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyReactionTimeStepIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyHolePegTestDominantPlaceStepIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyHolePegTestDominantRemoveStepIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyHolePegTestNonDominantPlaceStepIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyHolePegTestNonDominantRemoveStepIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyAudioRecorderIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyAccelerometerRecorderIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyPedometerRecorderIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyDeviceMotionRecorderIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyLocationRecorderIdentifier;
FOUNDATION_EXPORT NSString *const ORKLegacyHeartRateRecorderIdentifier;

FOUNDATION_EXPORT void ORKLegacyStepArrayAddStep(NSMutableArray *array, ORKLegacyStep *step);

@interface ORKLegacyOrderedTask ()

+ (ORKLegacyCompletionStep *)makeCompletionStep;

@end

NS_ASSUME_NONNULL_END
