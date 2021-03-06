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


#import <ORK1Kit/ORK1Result.h>
@import MapKit;

@class ORK1PageStep;

NS_ASSUME_NONNULL_BEGIN

/**
 The `ORK1DataResult` is an `ORK1Result` subclass for returning raw `NSData` from a step.
 
 This is considered private, and is not currently used by any of the pre-defined
 active tasks.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1DataResult : ORK1Result

/**
 The MIME contentType for the result.
 */
@property (nonatomic, copy, nullable) NSString *contentType;

/**
 A filename that could be used when archiving.
 */
@property (nonatomic, copy, nullable) NSString *filename;

/**
 The actual data in the result.
 */
@property (nonatomic, copy, nullable) NSData *data;

@end


@interface ORK1Result ()

/**
 A boolean value indicating whether this result can be saved in a save and
 restore procedure.
 
 This is currently considered a private method, but overriding the getter in a result
 is the correct way to prevent this result being considered as saveable for
 the purpose of deciding whether to offer a "Save" option when the user
 cancels a task in progress.
 
 `ORK1Result` subclasses should return YES if they have data that the user
 might want to be able to restore if the task were interrupted and later
 resumed from the current state.
 */
@property (nonatomic, readonly, getter=isSaveable) BOOL saveable;

@end


@interface ORK1QuestionResult ()

// Used internally for unit testing.
+ (nullable Class)answerClass;

// Used internally for unit testing.
@property (nonatomic, strong, nullable) id answer;

@end

@interface ORK1Location ()

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate
                            region:(nullable CLCircularRegion *)region
                         userInput:(nullable NSString *)userInput
                 addressDictionary:(nullable NSDictionary *)addressDictionary;

- (instancetype)initWithPlacemark:(CLPlacemark *)placemark userInput:(NSString *)userInput;

@end

@interface ORK1SignatureResult ()

- (instancetype)initWithSignatureImage:(UIImage *)signatureImage
                         signaturePath:(NSArray <UIBezierPath *> *)signaturePath;

@end


/**
 The `ORK1PageResult` is an `ORK1TaskResult` subclass of a collection of `ORK1StepResult`
 objects. This is considered private, and it is used internally by `ORK1PageStepViewController`
 to track the result set.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1PageResult : ORK1TaskResult

- (instancetype)initWithPageStep:(ORK1PageStep *)step stepResult:(ORK1StepResult*)result;

- (void)addStepResult:(nullable ORK1StepResult *)stepResult;

- (void)removeStepResultWithIdentifier:(NSString *)identifier;

- (void)removeStepResultsAfterStepWithIdentifier:(NSString *)identifier;

- (NSArray <ORK1Result *> *)flattenResults;

- (instancetype)copyWithOutputDirectory:(NSURL *)outputDirectory;

@end


@interface ORK1StepResult ()

@property (nonatomic) BOOL isPreviousResult;

@end


NS_ASSUME_NONNULL_END

