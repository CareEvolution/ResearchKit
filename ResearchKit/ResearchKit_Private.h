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


#import <ResearchKitLegacy/ResearchKit.h>

#import <ResearchKitLegacy/ORKHelpers_Private.h>

// Active step support
#import <ResearchKitLegacy/ORKDataLogger.h>
#import <ResearchKitLegacy/ORKErrors.h>

#import <ResearchKitLegacy/ORKAnswerFormat_Private.h>
#import <ResearchKitLegacy/ORKConsentSection_Private.h>
#import <ResearchKitLegacy/ORKOrderedTask_Private.h>
#import <ResearchKitLegacy/ORKPageStep_Private.h>
#import <ResearchKitLegacy/ORKRecorder_Private.h>
#import <ResearchKitLegacy/ORKResult_Private.h>
#import <ResearchKitLegacy/ORKStepNavigationRule_Private.h>
#import <ResearchKitLegacy/ORKAudioLevelNavigationRule.h>

#import <ResearchKitLegacy/ORKAudioStep.h>
#import <ResearchKitLegacy/ORKCompletionStep.h>
#import <ResearchKitLegacy/ORKCountdownStep.h>
#import <ResearchKitLegacy/ORKFitnessStep.h>
#import <ResearchKitLegacy/ORKHolePegTestPlaceStep.h>
#import <ResearchKitLegacy/ORKHolePegTestRemoveStep.h>
#import <ResearchKitLegacy/ORKPSATStep.h>
#import <ResearchKitLegacy/ORKRangeOfMotionStep.h>
#import <ResearchKitLegacy/ORKReactionTimeStep.h>
#import <ResearchKitLegacy/ORKShoulderRangeOfMotionStep.h>
#import <ResearchKitLegacy/ORKSpatialSpanMemoryStep.h>
#import <ResearchKitLegacy/ORKStroopStep.h>
#import <ResearchKitLegacy/ORKTappingIntervalStep.h>
#import <ResearchKitLegacy/ORKTimedWalkStep.h>
#import <ResearchKitLegacy/ORKToneAudiometryPracticeStep.h>
#import <ResearchKitLegacy/ORKToneAudiometryStep.h>
#import <ResearchKitLegacy/ORKTowerOfHanoiStep.h>
#import <ResearchKitLegacy/ORKTrailmakingStep.h>
#import <ResearchKitLegacy/ORKWalkingTaskStep.h>

#import <ResearchKitLegacy/ORKTaskViewController_Private.h>
#import <ResearchKitLegacy/ORKQuestionStepViewController_Private.h>

#import <ResearchKitLegacy/ORKAudioStepViewController.h>
#import <ResearchKitLegacy/ORKConsentReviewStepViewController.h>
#import <ResearchKitLegacy/ORKConsentSharingStepViewController.h>
#import <ResearchKitLegacy/ORKCountdownStepViewController.h>
#import <ResearchKitLegacy/ORKFitnessStepViewController.h>
#import <ResearchKitLegacy/ORKHolePegTestPlaceStepViewController.h>
#import <ResearchKitLegacy/ORKHolePegTestRemoveStepViewController.h>
#import <ResearchKitLegacy/ORKImageCaptureStepViewController.h>
#import <ResearchKitLegacy/ORKPasscodeStepViewController.h>
#import <ResearchKitLegacy/ORKPSATStepViewController.h>
#import <ResearchKitLegacy/ORKQuestionStepViewController.h>
#import <ResearchKitLegacy/ORKReviewStepViewController.h>
#import <ResearchKitLegacy/ORKSignatureStepViewController.h>
#import <ResearchKitLegacy/ORKSpatialSpanMemoryStepViewController.h>
#import <ResearchKitLegacy/ORKStroopStepViewController.h>
#import <ResearchKitLegacy/ORKTappingIntervalStepViewController.h>
#import <ResearchKitLegacy/ORKToneAudiometryPracticeStepViewController.h>
#import <ResearchKitLegacy/ORKToneAudiometryStepViewController.h>
#import <ResearchKitLegacy/ORKTimedWalkStepViewController.h>
#import <ResearchKitLegacy/ORKVisualConsentStepViewController.h>
#import <ResearchKitLegacy/ORKWalkingTaskStepViewController.h>
#import <ResearchKitLegacy/ORKVideoInstructionStepViewController.h>

#import <ResearchKitLegacy/ORKAccelerometerRecorder.h>
#import <ResearchKitLegacy/ORKAudioRecorder.h>
#import <ResearchKitLegacy/ORKDeviceMotionRecorder.h>
#import <ResearchKitLegacy/ORKHealthQuantityTypeRecorder.h>
#import <ResearchKitLegacy/ORKLocationRecorder.h>
#import <ResearchKitLegacy/ORKPedometerRecorder.h>
#import <ResearchKitLegacy/ORKTouchRecorder.h>

// For custom steps
#import <ResearchKitLegacy/ORKCustomStepView.h>
