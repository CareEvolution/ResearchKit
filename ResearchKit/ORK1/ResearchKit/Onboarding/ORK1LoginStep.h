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
#import <ResearchKit/ORK1FormStep.h>


NS_ASSUME_NONNULL_BEGIN

/**
 Constants for the form items included in the login step.
 These allow for convenient retrieval of user's inputted data from the result.
 */
ORK1_EXTERN NSString *const ORK1LoginFormItemIdentifierEmail ORK1_AVAILABLE_DECL;
ORK1_EXTERN NSString *const ORK1LoginFormItemIdentifierPassword ORK1_AVAILABLE_DECL;


/**
 The `ORK1LoginStep` class represents a form step that provides fields commonly used
 for account login.
 
 The login step contains email and password fields.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1LoginStep : ORK1FormStep

- (instancetype)initWithIdentifier:(NSString *)identifier NS_UNAVAILABLE;

- (instancetype)initWithIdentifier:(NSString *)identifier
                             title:(nullable NSString *)title
                              text:(nullable NSString *)text NS_UNAVAILABLE;

/**
 Returns an initialized login step using the specified identifier, title, text, and options.
 
 @param identifier                      The string that identifies the step (see `ORK1Step`).
 @param title                           The title of the form (see `ORK1Step`).
 @param text                            The text shown immediately below the title (see `ORK1Step`).
 @param loginViewControllerClass        The subclassed login step view controller class.
 
 @return An initialized login step object.
 */
- (instancetype)initWithIdentifier:(NSString *)identifier
                             title:(nullable NSString *)title
                              text:(nullable NSString *)text
          loginViewControllerClass:(Class)loginViewControllerClass;

/**
 The view controller subclass used for the step.
 
 The subclass allows you to override button actions in order to provide navigation logic
 for the button items on the step.
 */
@property (nonatomic, readonly) Class loginViewControllerClass;

@end

NS_ASSUME_NONNULL_END
