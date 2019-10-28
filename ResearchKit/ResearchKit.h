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


#import <ResearchKitLegacy/ORKTypes.h>

#import <ResearchKitLegacy/ORKStep.h>
#import <ResearchKitLegacy/ORKActiveStep.h>
#import <ResearchKitLegacy/ORKConsentReviewStep.h>
#import <ResearchKitLegacy/ORKConsentSharingStep.h>
#import <ResearchKitLegacy/ORKFormStep.h>
#import <ResearchKitLegacy/ORKImageCaptureStep.h>
#import <ResearchKitLegacy/ORKInstructionStep.h>
#import <ResearchKitLegacy/ORKLoginStep.h>
#import <ResearchKitLegacy/ORKNavigablePageStep.h>
#import <ResearchKitLegacy/ORKPageStep.h>
#import <ResearchKitLegacy/ORKPasscodeStep.h>
#import <ResearchKitLegacy/ORKQuestionStep.h>
#import <ResearchKitLegacy/ORKRegistrationStep.h>
#import <ResearchKitLegacy/ORKReviewStep.h>
#import <ResearchKitLegacy/ORKSignatureStep.h>
#import <ResearchKitLegacy/ORKTableStep.h>
#import <ResearchKitLegacy/ORKTouchAnywhereStep.h>
#import <ResearchKitLegacy/ORKVerificationStep.h>
#import <ResearchKitLegacy/ORKVideoCaptureStep.h>
#import <ResearchKitLegacy/ORKVisualConsentStep.h>
#import <ResearchKitLegacy/ORKWaitStep.h>
#import <ResearchKitLegacy/ORKVideoInstructionStep.h>
#import <ResearchKitLegacy/ORKWebViewStep.h>

#import <ResearchKitLegacy/ORKTask.h>
#import <ResearchKitLegacy/ORKOrderedTask.h>
#import <ResearchKitLegacy/ORKNavigableOrderedTask.h>
#import <ResearchKitLegacy/ORKStepNavigationRule.h>

#import <ResearchKitLegacy/ORKAnswerFormat.h>
#import <ResearchKitLegacy/ORKHealthAnswerFormat.h>

#import <ResearchKitLegacy/ORKResult.h>
#import <ResearchKitLegacy/ORKResultPredicate.h>

#import <ResearchKitLegacy/ORKTextButton.h>
#import <ResearchKitLegacy/ORKBorderedButton.h>
#import <ResearchKitLegacy/ORKContinueButton.h>

#import <ResearchKitLegacy/ORKStepViewController.h>
#import <ResearchKitLegacy/ORKActiveStepViewController.h>
#import <ResearchKitLegacy/ORKCompletionStepViewController.h>
#import <ResearchKitLegacy/ORKFormStepViewController.h>
#import <ResearchKitLegacy/ORKInstructionStepViewController.h>
#import <ResearchKitLegacy/ORKLoginStepViewController.h>
#import <ResearchKitLegacy/ORKPageStepViewController.h>
#import <ResearchKitLegacy/ORKPasscodeViewController.h>
#import <ResearchKitLegacy/ORKQuestionStepViewController.h>
#import <ResearchKitLegacy/ORKTableStepViewController.h>
#import <ResearchKitLegacy/ORKTaskViewController.h>
#import <ResearchKitLegacy/ORKTouchAnywhereStepViewController.h>
#import <ResearchKitLegacy/ORKVerificationStepViewController.h>
#import <ResearchKitLegacy/ORKWaitStepViewController.h>
#import <ResearchKitLegacy/ORKWebViewStepViewController.h>

#import <ResearchKitLegacy/ORKRecorder.h>

#import <ResearchKitLegacy/ORKConsentDocument.h>
#import <ResearchKitLegacy/ORKConsentSection.h>
#import <ResearchKitLegacy/ORKConsentSignature.h>

#import <ResearchKitLegacy/ORKKeychainWrapper.h>

#import <ResearchKitLegacy/ORKChartTypes.h>
#import <ResearchKitLegacy/ORKBarGraphChartView.h>
#import <ResearchKitLegacy/ORKDiscreteGraphChartView.h>
#import <ResearchKitLegacy/ORKLineGraphChartView.h>
#import <ResearchKitLegacy/ORKPieChartView.h>

#import <ResearchKitLegacy/ORKDataCollectionManager.h>
#import <ResearchKitLegacy/ORKCollector.h>

#import <ResearchKitLegacy/ORKDeprecated.h>

#import <ResearchKitLegacy/CEVRKTheme.h>
