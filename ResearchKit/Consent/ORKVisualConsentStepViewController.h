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


@import UIKit;
#import <ResearchKitLegacy/ORKDefines.h>
#import <ResearchKitLegacy/ORKStepViewController.h>


NS_ASSUME_NONNULL_BEGIN

@class ORKVisualConsentStepViewController;
@class ORKConsentSection;

/**
 Implement this delegate in order to observe the user's interaction with a visual consent step.
 */
ORK_CLASS_AVAILABLE
@protocol ORKVisualConsentStepViewControllerDelegate<NSObject>

@optional

/**
 Tells the delegate when each section of the consent document is displayed, as the user navigates through them.
 
 @param stepViewController The step view controller providing the callback.
 @param section            The consent section displayed.
 @param index              The index of the consent section.
 */
- (void)visualConsentStepViewController:(ORKVisualConsentStepViewController *)stepViewController didShowSection:(ORKConsentSection *)section sectionIndex:(NSInteger)index;

@end


/**
 The `ORKVisualConsentStepViewController` class is a view controller subclass
 used to manage a visual consent step (`ORKVisualConsentStep`).
 
 You should not need to instantiate a visual consent step view controller directly. Instead, include
 a visual consent step in a task, and present a task view controller for that 
 task.
 */
ORK_CLASS_AVAILABLE
@interface ORKVisualConsentStepViewController : ORKStepViewController

/**
 The delegate for visual consent interactions. This delegate is optional.
 */
@property (nonatomic, weak, nullable) id<ORKVisualConsentStepViewControllerDelegate> visualConsentDelegate;

/**
 The view in which animations are displayed.
 */
@property (nonatomic, strong, nullable) UIView *animationView;

@end

NS_ASSUME_NONNULL_END
