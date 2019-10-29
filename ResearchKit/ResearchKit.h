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


#import <ResearchKit/ORKTypes.h>

#import <ResearchKit/ORKStep.h>
#import <ResearchKit/ORKActiveStep.h>
#import <ResearchKit/ORKConsentReviewStep.h>
#import <ResearchKit/ORKConsentSharingStep.h>
#import <ResearchKit/ORKFormStep.h>
#import <ResearchKit/ORKImageCaptureStep.h>
#import <ResearchKit/ORKInstructionStep.h>
#import <ResearchKit/ORKLoginStep.h>
#import <ResearchKit/ORKNavigablePageStep.h>
#import <ResearchKit/ORKPageStep.h>
#import <ResearchKit/ORKPasscodeStep.h>
#import <ResearchKit/ORKPDFViewerStep.h>
#import <ResearchKit/ORKQuestionStep.h>
#import <ResearchKit/ORKRegistrationStep.h>
#import <ResearchKit/ORKReviewStep.h>
#import <ResearchKit/ORKSignatureStep.h>
#import <ResearchKit/ORKTableStep.h>
#import <ResearchKit/ORKTouchAnywhereStep.h>
#import <ResearchKit/ORKVerificationStep.h>
#import <ResearchKit/ORKVideoCaptureStep.h>
#import <ResearchKit/ORKVisualConsentStep.h>
#import <ResearchKit/ORKWaitStep.h>
#import <ResearchKit/ORKVideoInstructionStep.h>
#import <ResearchKit/ORKWebViewStep.h>
#import <ResearchKit/ORKEnvironmentSPLMeterStep.h>
#import <ResearchKit/ORKLearnMoreInstructionStep.h>

#import <ResearchKit/ORKTask.h>
#import <ResearchKit/ORKOrderedTask.h>
#import <ResearchKit/ORKOrderedTask+ORKPredefinedActiveTask.h>
#import <ResearchKit/ORKNavigableOrderedTask.h>
#import <ResearchKit/ORKStepNavigationRule.h>

#import <ResearchKit/ORKAnswerFormat.h>
#import <ResearchKit/ORKHealthAnswerFormat.h>

#import <ResearchKit/ORKResult.h>
#import <ResearchKit/ORKActiveTaskResult.h>
#import <ResearchKit/ORKCollectionResult.h>
#import <ResearchKit/ORKConsentSignatureResult.h>
#import <ResearchKit/ORKPasscodeResult.h>
#import <ResearchKit/ORKQuestionResult.h>
#import <ResearchKit/ORKSignatureResult.h>
#import <ResearchKit/ORKVideoInstructionStepResult.h>
#import <ResearchKit/ORKWebViewStepResult.h>
#import <ResearchKit/ORKEnvironmentSPLMeterResult.h>
#import <ResearchKit/ORKResultPredicate.h>

#import <ResearchKit/ORKTextButton.h>
#import <ResearchKit/ORKBorderedButton.h>
#import <ResearchKit/ORKContinueButton.h>

#import <ResearchKit/ORKStepViewController.h>
#import <ResearchKit/ORKActiveStepViewController.h>
#import <ResearchKit/ORKCompletionStepViewController.h>
#import <ResearchKit/ORKFormStepViewController.h>
#import <ResearchKit/ORKInstructionStepViewController.h>
#import <ResearchKit/ORKLoginStepViewController.h>
#import <ResearchKit/ORKPageStepViewController.h>
#import <ResearchKit/ORKPasscodeViewController.h>
#import <ResearchKit/ORKPDFViewerStepViewController.h>
#import <ResearchKit/ORKQuestionStepViewController.h>
#import <ResearchKit/ORKTableStepViewController.h>
#import <ResearchKit/ORKTaskViewController.h>
#import <ResearchKit/ORKTouchAnywhereStepViewController.h>
#import <ResearchKit/ORKVerificationStepViewController.h>
#import <ResearchKit/ORKWaitStepViewController.h>
#import <ResearchKit/ORKWebViewStepViewController.h>

#import <ResearchKit/ORKRecorder.h>

#import <ResearchKit/ORKConsentDocument.h>
#import <ResearchKit/ORKConsentSection.h>
#import <ResearchKit/ORKConsentSignature.h>

#import <ResearchKit/ORKKeychainWrapper.h>

#import <ResearchKit/ORKChartTypes.h>
#import <ResearchKit/ORKBarGraphChartView.h>
#import <ResearchKit/ORKDiscreteGraphChartView.h>
#import <ResearchKit/ORKLineGraphChartView.h>
#import <ResearchKit/ORKPieChartView.h>

#import <ResearchKit/ORKBodyItem.h>
#import <ResearchKit/ORKLearnMoreItem.h>

#import <ResearchKit/ORKDataCollectionManager.h>
#import <ResearchKit/ORKCollector.h>

#import <ResearchKit/ORKTouchAbilityTouch.h>
#import <ResearchKit/ORKTouchAbilityTrack.h>
#import <ResearchKit/ORKTouchAbilityGestureRecoginzerEvent.h>
#import <ResearchKit/ORKTouchAbilityTrial.h>
#import <ResearchKit/ORKTouchAbilityTapTrial.h>
#import <ResearchKit/ORKTouchAbilityLongPressTrial.h>
#import <ResearchKit/ORKTouchAbilitySwipeTrial.h>
#import <ResearchKit/ORKTouchAbilityScrollTrial.h>
#import <ResearchKit/ORKTouchAbilityPinchTrial.h>
#import <ResearchKit/ORKTouchAbilityRotationTrial.h>

#import <ResearchKit/ORKDeprecated.h>


// RK1 Additions
#import <ResearchKit/RK1Types.h>

#import <ResearchKit/RK1Step.h>
#import <ResearchKit/RK1ActiveStep.h>
#import <ResearchKit/RK1ConsentReviewStep.h>
#import <ResearchKit/RK1ConsentSharingStep.h>
#import <ResearchKit/RK1FormStep.h>
#import <ResearchKit/RK1ImageCaptureStep.h>
#import <ResearchKit/RK1InstructionStep.h>
#import <ResearchKit/RK1LoginStep.h>
#import <ResearchKit/RK1NavigablePageStep.h>
#import <ResearchKit/RK1PageStep.h>
#import <ResearchKit/RK1PasscodeStep.h>
#import <ResearchKit/RK1QuestionStep.h>
#import <ResearchKit/RK1RegistrationStep.h>
#import <ResearchKit/RK1ReviewStep.h>
#import <ResearchKit/RK1SignatureStep.h>
#import <ResearchKit/RK1TableStep.h>
#import <ResearchKit/RK1TouchAnywhereStep.h>
#import <ResearchKit/RK1VerificationStep.h>
#import <ResearchKit/RK1VideoCaptureStep.h>
#import <ResearchKit/RK1VisualConsentStep.h>
#import <ResearchKit/RK1WaitStep.h>
#import <ResearchKit/RK1VideoInstructionStep.h>
#import <ResearchKit/RK1WebViewStep.h>

#import <ResearchKit/RK1Task.h>
#import <ResearchKit/RK1OrderedTask.h>
#import <ResearchKit/RK1NavigableOrderedTask.h>
#import <ResearchKit/RK1StepNavigationRule.h>

#import <ResearchKit/RK1AnswerFormat.h>
#import <ResearchKit/RK1HealthAnswerFormat.h>

#import <ResearchKit/RK1Result.h>
#import <ResearchKit/RK1ResultPredicate.h>

#import <ResearchKit/RK1TextButton.h>
#import <ResearchKit/RK1BorderedButton.h>
#import <ResearchKit/RK1ContinueButton.h>

#import <ResearchKit/RK1StepViewController.h>
#import <ResearchKit/RK1ActiveStepViewController.h>
#import <ResearchKit/RK1CompletionStepViewController.h>
#import <ResearchKit/RK1FormStepViewController.h>
#import <ResearchKit/RK1InstructionStepViewController.h>
#import <ResearchKit/RK1LoginStepViewController.h>
#import <ResearchKit/RK1PageStepViewController.h>
#import <ResearchKit/RK1PasscodeViewController.h>
#import <ResearchKit/RK1QuestionStepViewController.h>
#import <ResearchKit/RK1TableStepViewController.h>
#import <ResearchKit/RK1TaskViewController.h>
#import <ResearchKit/RK1TouchAnywhereStepViewController.h>
#import <ResearchKit/RK1VerificationStepViewController.h>
#import <ResearchKit/RK1WaitStepViewController.h>
#import <ResearchKit/RK1WebViewStepViewController.h>

#import <ResearchKit/RK1Recorder.h>

#import <ResearchKit/RK1ConsentDocument.h>
#import <ResearchKit/RK1ConsentSection.h>
#import <ResearchKit/RK1ConsentSignature.h>

#import <ResearchKit/RK1KeychainWrapper.h>

#import <ResearchKit/RK1ChartTypes.h>
#import <ResearchKit/RK1BarGraphChartView.h>
#import <ResearchKit/RK1DiscreteGraphChartView.h>
#import <ResearchKit/RK1LineGraphChartView.h>
#import <ResearchKit/RK1PieChartView.h>

#import <ResearchKit/RK1DataCollectionManager.h>
#import <ResearchKit/RK1Collector.h>

#import <ResearchKit/RK1Deprecated.h>

#import <ResearchKit/CEVRKTheme.h>
