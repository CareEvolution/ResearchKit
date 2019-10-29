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
#import "RK1AnswerFormat_Private.h"
#import "RK1ChoiceAnswerFormatHelper.h"


NS_ASSUME_NONNULL_BEGIN

BOOL RK1IsAnswerEmpty(_Nullable id answer);

NSString *RK1HKBiologicalSexString(HKBiologicalSex biologicalSex);
NSString *RK1HKBloodTypeString(HKBloodType bloodType);
NSString *RK1QuestionTypeString(RK1QuestionType questionType);

// Need to mark these as designated initializers to avoid warnings once we designate the others.
#define RK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(C) \
@interface C () \
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER; \
@end

RK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(RK1AnswerFormat)
RK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(RK1ImageChoiceAnswerFormat)
RK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(RK1ValuePickerAnswerFormat)
RK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(RK1MultipleValuePickerAnswerFormat)
RK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(RK1TextChoiceAnswerFormat)
RK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(RK1TextChoice)
RK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(RK1ImageChoice)
RK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(RK1TimeOfDayAnswerFormat)
RK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(RK1DateAnswerFormat)
RK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(RK1TimeOfDayAnswerFormat)
RK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(RK1NumericAnswerFormat)
RK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(RK1ScaleAnswerFormat)
RK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(RK1ContinuousScaleAnswerFormat)
RK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(RK1TextScaleAnswerFormat)
RK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(RK1TextAnswerFormat)
RK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(RK1TimeIntervalAnswerFormat)
RK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(RK1HeightAnswerFormat)
RK1_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(RK1WeightAnswerFormat)


@class RK1QuestionResult;

@interface RK1AnswerFormat ()

- (instancetype)init NS_DESIGNATED_INITIALIZER;

- (BOOL)isHealthKitAnswerFormat;

- (nullable HKObjectType *)healthKitObjectType;
- (nullable HKObjectType *)healthKitObjectTypeForAuthorization;

@property (nonatomic, strong, readonly, nullable) HKUnit *healthKitUnit;

@property (nonatomic, strong, nullable) HKUnit *healthKitUserUnit;

- (BOOL)isAnswerValid:(id)answer;

- (nullable NSString *)localizedInvalidValueStringWithAnswerString:(nullable NSString *)text;

- (nonnull Class)questionResultClass;

- (RK1QuestionResult *)resultWithIdentifier:(NSString *)identifier answer:(id)answer;

- (nullable NSString *)stringForAnswer:(id)answer;

@end


@interface RK1NumericAnswerFormat ()

- (nullable NSString *)sanitizedTextFieldText:(nullable NSString *)text decimalSeparator:(nullable NSString *)separator;

@end


/**
 The `RK1AnswerOption` protocol defines brief option text for a option which can be included within `RK1*ChoiceAnswerFormat`.
 */
@protocol RK1AnswerOption <NSObject>

/**
 Brief option text.
 */
- (NSString *)text;

/**
 The value to be returned if this option is selected.

 Expected to be a scalar type serializable to JSON, e.g. `NSNumber` or `NSString`.
 If no value is provided, the index of the option in the `RK1*ChoiceAnswerFormat` options list will be used.
 */
- (nullable id)value;

@end


@protocol RK1ScaleAnswerFormatProvider <NSObject>

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


@protocol RK1TextScaleAnswerFormatProvider <RK1ScaleAnswerFormatProvider>

- (NSArray<RK1TextChoice *> *)textChoices;
- (RK1TextChoice *)textChoiceAtIndex:(NSUInteger)index;
- (NSUInteger)textChoiceIndexForValue:(id<NSCopying, NSCoding, NSObject>)value;

@end

@protocol RK1ConfirmAnswerFormatProvider <NSObject>

- (RK1AnswerFormat *)confirmationAnswerFormatWithOriginalItemIdentifier:(NSString *)originalItemIdentifier
                                                           errorMessage:(NSString *)errorMessage;

@end


@interface RK1ScaleAnswerFormat () <RK1ScaleAnswerFormatProvider>

@end


@interface RK1ContinuousScaleAnswerFormat () <RK1ScaleAnswerFormatProvider>

@end


@interface RK1TextScaleAnswerFormat () <RK1TextScaleAnswerFormatProvider>

@end


@interface RK1TextChoice () <RK1AnswerOption>

@end

@interface RK1ValuePickerAnswerFormat ()

- (instancetype)initWithTextChoices:(NSArray<RK1TextChoice *> *)textChoices nullChoice:(RK1TextChoice *)nullChoice NS_DESIGNATED_INITIALIZER;

- (RK1TextChoice *)nullTextChoice;

@end


@interface RK1ImageChoice () <RK1AnswerOption>

@end


@interface RK1TimeOfDayAnswerFormat ()

- (NSDate *)pickerDefaultDate;

@end


@interface RK1DateAnswerFormat ()

- (NSDate *)pickerDefaultDate;
- (nullable NSDate *)pickerMinimumDate;
- (nullable NSDate *)pickerMaximumDate;

- (NSCalendar *)currentCalendar;

@end


@interface RK1TimeIntervalAnswerFormat ()

- (NSTimeInterval)pickerDefaultDuration;

@end


@interface RK1TextAnswerFormat () <RK1ConfirmAnswerFormatProvider>

@end


@interface RK1HeightAnswerFormat ()

@property (nonatomic, readonly) BOOL useMetricSystem;

@end


@interface RK1WeightAnswerFormat ()

@property (nonatomic, readonly) BOOL useMetricSystem;

@end


@interface RK1AnswerDefaultSource : NSObject

+ (instancetype)sourceWithHealthStore:(HKHealthStore *)healthStore;
- (instancetype)initWithHealthStore:(HKHealthStore *)healthStore NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, readonly, nullable) HKHealthStore *healthStore;

- (void)fetchDefaultValueForAnswerFormat:(nullable RK1AnswerFormat *)answerFormat handler:(void(^)(id defaultValue, NSError *error))handler;

- (HKUnit *)defaultHealthKitUnitForAnswerFormat:(RK1AnswerFormat *)answerFormat;
- (void)updateHealthKitUnitForAnswerFormat:(RK1AnswerFormat *)answerFormat force:(BOOL)force;

@end


NS_ASSUME_NONNULL_END

