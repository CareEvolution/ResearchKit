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

@class ORKLegacyConsentReviewStep;
@class ORKLegacyConsentSignatureResult;
@class ORKLegacyConsentReviewStepViewController;

/**
 Values that identify different phases of the consent review step. Which phases are shown to the user depend on the configuration of the associated ORKLegacyConsentSignature.
 */
typedef NS_ENUM(NSInteger, ORKLegacyConsentReviewPhase) {
    /// The (optional) phase in which the user enters their name.
    ORKLegacyConsentReviewPhaseName,
    /// The phase in which the consent document is displayed for final review before agreeing.
    ORKLegacyConsentReviewPhaseReviewDocument,
    /// The (optional) phase in which the user enters a signature.
    ORKLegacyConsentReviewPhaseSignature
} ORKLegacy_ENUM_AVAILABLE;

/**
 Implement this delegate in order to observe the user's interaction with a consent review step.
 */
ORKLegacy_CLASS_AVAILABLE
@protocol ORKLegacyConsentReviewStepViewControllerDelegate<NSObject>

@optional

/**
 Tells the delegate when various phases of consent review are displayed.
 
 @param stepViewController The step view controller providing the callback.
 @param phase              The phase of consent review shown to the user.
 @param pageIndex          Indicates the ordering of the phase shown to the user.
 */
- (void)consentReviewStepViewController:(ORKLegacyConsentReviewStepViewController *)stepViewController didShowPhase:(ORKLegacyConsentReviewPhase)phase pageIndex:(NSInteger)pageIndex;

@end


/**
 The `ORKLegacyConsentReviewStepViewController` class is a step view controller subclass
 used to manage a consent review step (`ORKLegacyConsentReviewStep`).
 
 You should not need to instantiate a consent review step view controller directly. Instead, include
 a consent review step in a task, and present a task view controller for that
 task.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyConsentReviewStepViewController : ORKLegacyStepViewController

/**
 Returns an initialized consent review step view controller using the specified review step and result.
 
 @param consentReviewStep       The configured review step.
 @param result                  The initial or previous results for the review step, as appropriate.
 */
- (instancetype)initWithConsentReviewStep:(ORKLegacyConsentReviewStep *)consentReviewStep
                                   result:(nullable ORKLegacyConsentSignatureResult *)result;

/**
 The delegate for consent review interactions. This delegate is optional.
 */
@property (nonatomic, weak, nullable) id<ORKLegacyConsentReviewStepViewControllerDelegate> consentReviewDelegate;

@end

NS_ASSUME_NONNULL_END
