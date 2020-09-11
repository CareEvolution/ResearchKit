/*
 Copyright (c) 2020, CareEvolution, Inc.
 
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


#import <ORK1Kit/ORK1Step.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The `ORK1DocumentReviewStep` represents a class that displays a read-only preview of a file
 produced by a previous step. The referenced step should produce an `ORK1FileResult`.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1DocumentReviewStep : ORK1Step

- (instancetype)initWithIdentifier:(NSString *)identifier NS_UNAVAILABLE;

/**
 Returns an initialized document review step using the specified identifier
 and source step identifier.
  
 @param identifier                          The string that identifies the step (see `ORK1Step`).
 @param sourceStepIdentifier    The identifier of a previous step (e.g. an `ORK1DocumentSelectionStep` that produced the result that should be displayed by this step.
 
 @return An initialized document review step object.
 */
- (instancetype)initWithIdentifier:(NSString *)identifier sourceStepIdentifier:(NSString *)sourceStepIdentifier NS_DESIGNATED_INITIALIZER;

/**
 Returns a document review step initialized from data in the given unarchiver.
 
 A document review step can be serialized and deserialized with `NSKeyedArchiver`. Note
 that this serialization includes strings that might need to be localized.
 
 @param aDecoder    The coder from which to initialize the ordered task.
 
 @return An initialized document review step.
 */
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

/**
 The identifier of a previous step (e.g. an `ORK1DocumentSelectionStep` that produced the result that should be displayed by this step.
 */
@property (nonatomic, copy) NSString *sourceStepIdentifier;

/**
 The text to display if the source step's `ORK1FileResult` is missing, empty, or has an unsupported file type.
 If nil, the step's `text` property is displayed instead.
 */
@property (nonatomic, copy, nullable) NSString *noFileText;

@end

NS_ASSUME_NONNULL_END
