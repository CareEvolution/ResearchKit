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


@import HealthKit;
#import "ORKAnswerFormat_Private.h"
#import "ORKChoiceAnswerFormatHelper.h"


NS_ASSUME_NONNULL_BEGIN

BOOL ORK1IsAnswerEmpty(_Nullable id answer);

NSString *ORK1HKBiologicalSexString(HKBiologicalSex biologicalSex);
NSString *ORK1HKBloodTypeString(HKBloodType bloodType);
NSString *ORK1QuestionTypeString(ORK1QuestionType questionType);

// Need to mark these as designated initializers to avoid warnings once we designate the others.
#define ORK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(C) \
@interface C () \
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER; \
@end

ORK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORK1AnswerFormat)
ORK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORK1ImageChoiceAnswerFormat)
ORK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORK1ValuePickerAnswerFormat)
ORK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORK1MultipleValuePickerAnswerFormat)
ORK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORK1TextChoiceAnswerFormat)
ORK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORK1TextChoice)
ORK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORK1ImageChoice)
ORK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORK1TimeOfDayAnswerFormat)
ORK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORK1DateAnswerFormat)
ORK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORK1TimeOfDayAnswerFormat)
ORK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORK1NumericAnswerFormat)
ORK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORK1ScaleAnswerFormat)
ORK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORK1ContinuousScaleAnswerFormat)
ORK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORK1TextScaleAnswerFormat)
ORK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORK1TextAnswerFormat)
ORK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORK1TimeIntervalAnswerFormat)
ORK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORK1HeightAnswerFormat)
ORK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORK1WeightAnswerFormat)


@class ORK1QuestionResult;

@interface ORK1AnswerFormat ()

- (instancetype)init NS_DESIGNATED_INITIALIZER;

- (BOOL)isHealthKitAnswerFormat;

- (nullable HKObjectType *)healthKitObjectType;
- (nullable HKObjectType *)healthKitObjectTypeForAuthorization;

@property (nonatomic, strong, readonly, nullable) HKUnit *healthKitUnit;

@property (nonatomic, strong, nullable) HKUnit *healthKitUserUnit;

- (BOOL)isAnswerValid:(id)answer;

- (nullable NSString *)localizedInvalidValueStringWithAnswerString:(nullable NSString *)text;

- (nonnull Class)questionResultClass;

- (ORK1QuestionResult *)resultWithIdentifier:(NSString *)identifier answer:(id)answer;

- (nullable NSString *)stringForAnswer:(id)answer;

@end


@interface ORK1NumericAnswerFormat ()

- (nullable NSString *)sanitizedTextFieldText:(nullable NSString *)text decimalSeparator:(nullable NSString *)separator;

@end


/**
 The `ORK1AnswerOption` protocol defines brief option text for a option which can be included within `ORK1*ChoiceAnswerFormat`.
 */
@protocol ORK1AnswerOption <NSObject>

/**
 Brief option text.
 */
- (NSString *)text;

/**
 The value to be returned if this option is selected.

 Expected to be a scalar type serializable to JSON, e.g. `NSNumber` or `NSString`.
 If no value is provided, the index of the option in the `ORK1*ChoiceAnswerFormat` options list will be used.
 */
- (nullable id)value;

@end


@protocol ORK1ScaleAnswerFormatProvider <NSObject>

- (nullable NSNumber *)minimumNumber;
- (nullable NSNumber *)maximumNumber;
- (nullable id)defaultAnswer;
- (nullable NSString *)localizedStringForNumber:(nullable NSNumber *)number;
- (NSInteger)numberOfSteps;
- (nullable NSNumber *)normalizedValueForNumber:(nullable NSNumber *)number;
- (BOOL)isVertical;
- (NSString *)maximumValueDescription;
- (NSString *)minimumValueDescription;
- (UIImage *)maximumImage;
- (UIImage *)minimumImage;
- (nullable NSArray<UIColor *> *)gradientColors;
- (nullable NSArray<NSNumber *> *)gradientLocations;

@end


@protocol ORK1TextScaleAnswerFormatProvider <ORK1ScaleAnswerFormatProvider>

- (NSArray<ORK1TextChoice *> *)textChoices;
- (ORK1TextChoice *)textChoiceAtIndex:(NSUInteger)index;
- (NSUInteger)textChoiceIndexForValue:(id<NSCopying, NSCoding, NSObject>)value;

@end

@protocol ORK1ConfirmAnswerFormatProvider <NSObject>

- (ORK1AnswerFormat *)confirmationAnswerFormatWithOriginalItemIdentifier:(NSString *)originalItemIdentifier
                                                           errorMessage:(NSString *)errorMessage;

@end


@interface ORK1ScaleAnswerFormat () <ORK1ScaleAnswerFormatProvider>

@end


@interface ORK1ContinuousScaleAnswerFormat () <ORK1ScaleAnswerFormatProvider>

@end


@interface ORK1TextScaleAnswerFormat () <ORK1TextScaleAnswerFormatProvider>

@end


@interface ORK1TextChoice () <ORK1AnswerOption>

@end

@interface ORK1ValuePickerAnswerFormat ()

- (instancetype)initWithTextChoices:(NSArray<ORK1TextChoice *> *)textChoices nullChoice:(ORK1TextChoice *)nullChoice NS_DESIGNATED_INITIALIZER;

- (ORK1TextChoice *)nullTextChoice;

@end


@interface ORK1ImageChoice () <ORK1AnswerOption>

@end


@interface ORK1TimeOfDayAnswerFormat ()

- (NSDate *)pickerDefaultDate;

@end


@interface ORK1DateAnswerFormat ()

- (NSDate *)pickerDefaultDate;
- (nullable NSDate *)pickerMinimumDate;
- (nullable NSDate *)pickerMaximumDate;

- (NSCalendar *)currentCalendar;

@end


@interface ORK1TimeIntervalAnswerFormat ()

- (NSTimeInterval)pickerDefaultDuration;

@end


@interface ORK1TextAnswerFormat () <ORK1ConfirmAnswerFormatProvider>

@end


@interface ORK1HeightAnswerFormat ()

@property (nonatomic, readonly) BOOL useMetricSystem;

@end


@interface ORK1WeightAnswerFormat ()

@property (nonatomic, readonly) BOOL useMetricSystem;

@end


@interface ORK1AnswerDefaultSource : NSObject

+ (instancetype)sourceWithHealthStore:(HKHealthStore *)healthStore;
- (instancetype)initWithHealthStore:(HKHealthStore *)healthStore NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, readonly, nullable) HKHealthStore *healthStore;

- (void)fetchDefaultValueForAnswerFormat:(nullable ORK1AnswerFormat *)answerFormat handler:(void(^)(id defaultValue, NSError *error))handler;

- (HKUnit *)defaultHealthKitUnitForAnswerFormat:(ORK1AnswerFormat *)answerFormat;
- (void)updateHealthKitUnitForAnswerFormat:(ORK1AnswerFormat *)answerFormat force:(BOOL)force;

@end


NS_ASSUME_NONNULL_END

