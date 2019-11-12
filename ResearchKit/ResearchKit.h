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

#import <ResearchKit/ORKDataCollectionManager.h>
#import <ResearchKit/ORKCollector.h>

#import <ResearchKit/ORKDeprecated.h>


// RK1 Additions
#import <ResearchKit/ORK1Types.h>

#import <ResearchKit/ORK1Step.h>
#import <ResearchKit/ORK1ActiveStep.h>
#import <ResearchKit/ORK1ConsentReviewStep.h>
#import <ResearchKit/ORK1ConsentSharingStep.h>
#import <ResearchKit/ORK1FormStep.h>
#import <ResearchKit/ORK1ImageCaptureStep.h>
#import <ResearchKit/ORK1InstructionStep.h>
#import <ResearchKit/ORK1LoginStep.h>
#import <ResearchKit/ORK1NavigablePageStep.h>
#import <ResearchKit/ORK1PageStep.h>
#import <ResearchKit/ORK1PasscodeStep.h>
#import <ResearchKit/ORK1QuestionStep.h>
#import <ResearchKit/ORK1RegistrationStep.h>
#import <ResearchKit/ORK1ReviewStep.h>
#import <ResearchKit/ORK1SignatureStep.h>
#import <ResearchKit/ORK1TableStep.h>
#import <ResearchKit/ORK1TouchAnywhereStep.h>
#import <ResearchKit/ORK1VerificationStep.h>
#import <ResearchKit/ORK1VideoCaptureStep.h>
#import <ResearchKit/ORK1VisualConsentStep.h>
#import <ResearchKit/ORK1WaitStep.h>
#import <ResearchKit/ORK1VideoInstructionStep.h>
#import <ResearchKit/ORK1WebViewStep.h>

#import <ResearchKit/ORK1Task.h>
#import <ResearchKit/ORK1OrderedTask.h>
#import <ResearchKit/ORK1NavigableOrderedTask.h>
#import <ResearchKit/ORK1StepNavigationRule.h>

#import <ResearchKit/ORK1AnswerFormat.h>
#import <ResearchKit/ORK1HealthAnswerFormat.h>

#import <ResearchKit/ORK1Result.h>
#import <ResearchKit/ORK1ResultPredicate.h>

#import <ResearchKit/ORK1TextButton.h>
#import <ResearchKit/ORK1BorderedButton.h>
#import <ResearchKit/ORK1ContinueButton.h>

#import <ResearchKit/ORK1StepViewController.h>
#import <ResearchKit/ORK1ActiveStepViewController.h>
#import <ResearchKit/ORK1CompletionStepViewController.h>
#import <ResearchKit/ORK1FormStepViewController.h>
#import <ResearchKit/ORK1InstructionStepViewController.h>
#import <ResearchKit/ORK1LoginStepViewController.h>
#import <ResearchKit/ORK1PageStepViewController.h>
#import <ResearchKit/ORK1PasscodeViewController.h>
#import <ResearchKit/ORK1QuestionStepViewController.h>
#import <ResearchKit/ORK1TableStepViewController.h>
#import <ResearchKit/ORK1TaskViewController.h>
#import <ResearchKit/ORK1TouchAnywhereStepViewController.h>
#import <ResearchKit/ORK1VerificationStepViewController.h>
#import <ResearchKit/ORK1WaitStepViewController.h>
#import <ResearchKit/ORK1WebViewStepViewController.h>

#import <ResearchKit/ORK1Recorder.h>

#import <ResearchKit/ORK1ConsentDocument.h>
#import <ResearchKit/ORK1ConsentSection.h>
#import <ResearchKit/ORK1ConsentSignature.h>

#import <ResearchKit/ORK1KeychainWrapper.h>

#import <ResearchKit/ORK1ChartTypes.h>
#import <ResearchKit/ORK1BarGraphChartView.h>
#import <ResearchKit/ORK1DiscreteGraphChartView.h>
#import <ResearchKit/ORK1LineGraphChartView.h>
#import <ResearchKit/ORK1PieChartView.h>

#import <ResearchKit/ORK1DataCollectionManager.h>
#import <ResearchKit/ORK1Collector.h>

#import <ResearchKit/ORK1Deprecated.h>

#import <ResearchKit/CEVRKTheme.h>
