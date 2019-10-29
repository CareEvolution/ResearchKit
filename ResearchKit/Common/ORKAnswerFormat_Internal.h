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

BOOL ORKLegacyIsAnswerEmpty(_Nullable id answer);

NSString *ORKLegacyHKBiologicalSexString(HKBiologicalSex biologicalSex);
NSString *ORKLegacyHKBloodTypeString(HKBloodType bloodType);
NSString *ORKLegacyQuestionTypeString(ORKLegacyQuestionType questionType);

// Need to mark these as designated initializers to avoid warnings once we designate the others.
#define ORKLegacy_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(C) \
@interface C () \
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER; \
@end

ORKLegacy_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORKLegacyAnswerFormat)
ORKLegacy_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORKLegacyImageChoiceAnswerFormat)
ORKLegacy_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORKLegacyValuePickerAnswerFormat)
ORKLegacy_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORKLegacyMultipleValuePickerAnswerFormat)
ORKLegacy_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORKLegacyTextChoiceAnswerFormat)
ORKLegacy_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORKLegacyTextChoice)
ORKLegacy_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORKLegacyImageChoice)
ORKLegacy_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORKLegacyTimeOfDayAnswerFormat)
ORKLegacy_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORKLegacyDateAnswerFormat)
ORKLegacy_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORKLegacyTimeOfDayAnswerFormat)
ORKLegacy_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORKLegacyNumericAnswerFormat)
ORKLegacy_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORKLegacyScaleAnswerFormat)
ORKLegacy_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORKLegacyContinuousScaleAnswerFormat)
ORKLegacy_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORKLegacyTextScaleAnswerFormat)
ORKLegacy_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORKLegacyTextAnswerFormat)
ORKLegacy_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORKLegacyTimeIntervalAnswerFormat)
ORKLegacy_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORKLegacyHeightAnswerFormat)
ORKLegacy_DESIGNATE_CODING_AND_SERIALIZATION_INITIALIZERS(ORKLegacyWeightAnswerFormat)


@class ORKLegacyQuestionResult;

@interface ORKLegacyAnswerFormat ()

- (instancetype)init NS_DESIGNATED_INITIALIZER;

- (BOOL)isHealthKitAnswerFormat;

- (nullable HKObjectType *)healthKitObjectType;
- (nullable HKObjectType *)healthKitObjectTypeForAuthorization;

@property (nonatomic, strong, readonly, nullable) HKUnit *healthKitUnit;

@property (nonatomic, strong, nullable) HKUnit *healthKitUserUnit;

- (BOOL)isAnswerValid:(id)answer;

- (nullable NSString *)localizedInvalidValueStringWithAnswerString:(nullable NSString *)text;

- (nonnull Class)questionResultClass;

- (ORKLegacyQuestionResult *)resultWithIdentifier:(NSString *)identifier answer:(id)answer;

- (nullable NSString *)stringForAnswer:(id)answer;

@end


@interface ORKLegacyNumericAnswerFormat ()

- (nullable NSString *)sanitizedTextFieldText:(nullable NSString *)text decimalSeparator:(nullable NSString *)separator;

@end


/**
 The `ORKLegacyAnswerOption` protocol defines brief option text for a option which can be included within `ORKLegacy*ChoiceAnswerFormat`.
 */
@protocol ORKLegacyAnswerOption <NSObject>

/**
 Brief option text.
 */
- (NSString *)text;

/**
 The value to be returned if this option is selected.

 Expected to be a scalar type serializable to JSON, e.g. `NSNumber` or `NSString`.
 If no value is provided, the index of the option in the `ORKLegacy*ChoiceAnswerFormat` options list will be used.
 */
- (nullable id)value;

@end


@protocol ORKLegacyScaleAnswerFormatProvider <NSObject>

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


@protocol ORKLegacyTextScaleAnswerFormatProvider <ORKLegacyScaleAnswerFormatProvider>

- (NSArray<ORKLegacyTextChoice *> *)textChoices;
- (ORKLegacyTextChoice *)textChoiceAtIndex:(NSUInteger)index;
- (NSUInteger)textChoiceIndexForValue:(id<NSCopying, NSCoding, NSObject>)value;

@end

@protocol ORKLegacyConfirmAnswerFormatProvider <NSObject>

- (ORKLegacyAnswerFormat *)confirmationAnswerFormatWithOriginalItemIdentifier:(NSString *)originalItemIdentifier
                                                           errorMessage:(NSString *)errorMessage;

@end


@interface ORKLegacyScaleAnswerFormat () <ORKLegacyScaleAnswerFormatProvider>

@end


@interface ORKLegacyContinuousScaleAnswerFormat () <ORKLegacyScaleAnswerFormatProvider>

@end


@interface ORKLegacyTextScaleAnswerFormat () <ORKLegacyTextScaleAnswerFormatProvider>

@end


@interface ORKLegacyTextChoice () <ORKLegacyAnswerOption>

@end

@interface ORKLegacyValuePickerAnswerFormat ()

- (instancetype)initWithTextChoices:(NSArray<ORKLegacyTextChoice *> *)textChoices nullChoice:(ORKLegacyTextChoice *)nullChoice NS_DESIGNATED_INITIALIZER;

- (ORKLegacyTextChoice *)nullTextChoice;

@end


@interface ORKLegacyImageChoice () <ORKLegacyAnswerOption>

@end


@interface ORKLegacyTimeOfDayAnswerFormat ()

- (NSDate *)pickerDefaultDate;

@end


@interface ORKLegacyDateAnswerFormat ()

- (NSDate *)pickerDefaultDate;
- (nullable NSDate *)pickerMinimumDate;
- (nullable NSDate *)pickerMaximumDate;

- (NSCalendar *)currentCalendar;

@end


@interface ORKLegacyTimeIntervalAnswerFormat ()

- (NSTimeInterval)pickerDefaultDuration;

@end


@interface ORKLegacyTextAnswerFormat () <ORKLegacyConfirmAnswerFormatProvider>

@end


@interface ORKLegacyHeightAnswerFormat ()

@property (nonatomic, readonly) BOOL useMetricSystem;

@end


@interface ORKLegacyWeightAnswerFormat ()

@property (nonatomic, readonly) BOOL useMetricSystem;

@end


@interface ORKLegacyAnswerDefaultSource : NSObject

+ (instancetype)sourceWithHealthStore:(HKHealthStore *)healthStore;
- (instancetype)initWithHealthStore:(HKHealthStore *)healthStore NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, readonly, nullable) HKHealthStore *healthStore;

- (void)fetchDefaultValueForAnswerFormat:(nullable ORKLegacyAnswerFormat *)answerFormat handler:(void(^)(id defaultValue, NSError *error))handler;

- (HKUnit *)defaultHealthKitUnitForAnswerFormat:(ORKLegacyAnswerFormat *)answerFormat;
- (void)updateHealthKitUnitForAnswerFormat:(ORKLegacyAnswerFormat *)answerFormat force:(BOOL)force;

@end


NS_ASSUME_NONNULL_END

