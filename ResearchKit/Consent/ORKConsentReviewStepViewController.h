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


@import Foundation;
#import <ResearchKitLegacy/ORKDefines.h>
#import <ResearchKitLegacy/ORKStepViewController.h>


NS_ASSUME_NONNULL_BEGIN

@class ORK1ConsentReviewStep;
@class ORK1ConsentSignatureResult;
@class ORK1ConsentReviewStepViewController;

/**
 Values that identify different phases of the consent review step. Which phases are shown to the user depend on the configuration of the associated ORK1ConsentSignature.
 */
typedef NS_ENUM(NSInteger, ORK1ConsentReviewPhase) {
    /// The (optional) phase in which the user enters their name.
    ORK1ConsentReviewPhaseName,
    /// The phase in which the consent document is displayed for final review before agreeing.
    ORK1ConsentReviewPhaseReviewDocument,
    /// The (optional) phase in which the user enters a signature.
    ORK1ConsentReviewPhaseSignature
} ORK1_ENUM_AVAILABLE;

/**
 Implement this delegate in order to observe the user's interaction with a consent review step.
 */
ORK1_CLASS_AVAILABLE
@protocol ORK1ConsentReviewStepViewControllerDelegate<NSObject>

@optional

/**
 Tells the delegate when various phases of consent review are displayed.
 
 @param stepViewController The step view controller providing the callback.
 @param phase              The phase of consent review shown to the user.
 @param pageIndex          Indicates the ordering of the phase shown to the user.
 */
- (void)consentReviewStepViewController:(ORK1ConsentReviewStepViewController *)stepViewController didShowPhase:(ORK1ConsentReviewPhase)phase pageIndex:(NSInteger)pageIndex;

@end


/**
 The `ORK1ConsentReviewStepViewController` class is a step view controller subclass
 used to manage a consent review step (`ORK1ConsentReviewStep`).
 
 You should not need to instantiate a consent review step view controller directly. Instead, include
 a consent review step in a task, and present a task view controller for that
 task.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1ConsentReviewStepViewController : ORK1StepViewController

/**
 Returns an initialized consent review step view controller using the specified review step and result.
 
 @param consentReviewStep       The configured review step.
 @param result                  The initial or previous results for the review step, as appropriate.
 */
- (instancetype)initWithConsentReviewStep:(ORK1ConsentReviewStep *)consentReviewStep
                                   result:(nullable ORK1ConsentSignatureResult *)result;

/**
 The delegate for consent review interactions. This delegate is optional.
 */
@property (nonatomic, weak, nullable) id<ORK1ConsentReviewStepViewControllerDelegate> consentReviewDelegate;

@end

NS_ASSUME_NONNULL_END
