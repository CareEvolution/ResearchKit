/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 Copyright (c) 2015, Scott Guelich.
 Copyright (c) 2016, Ricardo Sánchez-Sáez.
 Copyright (c) 2017, Medable Inc. All rights reserved.
 Copyright (c) 2017, Macro Yau.
 Copyright (c) 2017, Sage Bionetworks.
 
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


#import "ORK1AnswerFormat.h"
#import "ORK1AnswerFormat_Internal.h"

#import "ORK1ChoiceAnswerFormatHelper.h"
#import "ORK1HealthAnswerFormat.h"
#import "ORK1Result_Private.h"

#import "ORK1Helpers_Internal.h"

@import HealthKit;
@import MapKit;


NSString *const EmailValidationRegularExpressionPattern = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}";

id ORK1NullAnswerValue() {
    return [NSNull null];
}

BOOL ORK1IsAnswerEmpty(id answer) {
    return  (answer == nil) ||
    (answer == ORK1NullAnswerValue()) ||
    ([answer isKindOfClass:[NSArray class]] && ((NSArray *)answer).count == 0);     // Empty answer of choice or value picker
}

NSString *ORK1QuestionTypeString(ORK1QuestionType questionType) {
#define SQT_CASE(x) case ORK1QuestionType ## x : return @ORK1_STRINGIFY(ORK1QuestionType ## x);
    switch (questionType) {
            SQT_CASE(None);
            SQT_CASE(Scale);
            SQT_CASE(SingleChoice);
            SQT_CASE(MultipleChoice);
            SQT_CASE(MultiplePicker);
            SQT_CASE(Decimal);
            SQT_CASE(Integer);
            SQT_CASE(Boolean);
            SQT_CASE(Text);
            SQT_CASE(DateAndTime);
            SQT_CASE(TimeOfDay);
            SQT_CASE(Date);
            SQT_CASE(TimeInterval);
            SQT_CASE(Height);
            SQT_CASE(Weight);
            SQT_CASE(Location);
    }
#undef SQT_CASE
}

NSNumberFormatterStyle ORK1NumberFormattingStyleConvert(ORK1NumberFormattingStyle style) {
    return style == ORK1NumberFormattingStylePercent ? NSNumberFormatterPercentStyle : NSNumberFormatterDecimalStyle;
}


@implementation ORK1AnswerDefaultSource {
    NSMutableDictionary *_unitsTable;
}

@synthesize healthStore=_healthStore;

+ (instancetype)sourceWithHealthStore:(HKHealthStore *)healthStore {
    ORK1AnswerDefaultSource *source = [[ORK1AnswerDefaultSource alloc] initWithHealthStore:healthStore];
    return source;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)init {
    ORK1ThrowMethodUnavailableException();
}
#pragma clang diagnostic pop

- (instancetype)initWithHealthStore:(HKHealthStore *)healthStore {
    self = [super init];
    if (self) {
        _healthStore = healthStore;
        
        if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 8, .minorVersion = 2, .patchVersion = 0}]) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(healthKitUserPreferencesDidChange:)
                                                         name:HKUserPreferencesDidChangeNotification
                                                       object:healthStore];
        }
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)healthKitUserPreferencesDidChange:(NSNotification *)notification {
    _unitsTable = nil;
}

- (id)defaultValueForCharacteristicType:(HKCharacteristicType *)characteristicType error:(NSError **)error {
    id result = nil;
    if ([[characteristicType identifier] isEqualToString:HKCharacteristicTypeIdentifierDateOfBirth]) {
        NSDate *dob = [_healthStore dateOfBirthWithError:error];
        if (dob) {
            result = dob;
        }
    }
    if ([[characteristicType identifier] isEqualToString:HKCharacteristicTypeIdentifierBloodType]) {
        HKBloodTypeObject *bloodType = [_healthStore bloodTypeWithError:error];
        if (bloodType && bloodType.bloodType != HKBloodTypeNotSet) {
            result = ORK1HKBloodTypeString(bloodType.bloodType);
        }
        if (result) {
            result = @[result];
        }
    }
    if ([[characteristicType identifier] isEqualToString:HKCharacteristicTypeIdentifierBiologicalSex]) {
        HKBiologicalSexObject *biologicalSex = [_healthStore biologicalSexWithError:error];
        if (biologicalSex && biologicalSex.biologicalSex != HKBiologicalSexNotSet) {
            result = ORK1HKBiologicalSexString(biologicalSex.biologicalSex);
        }
        if (result) {
            result = @[result];
        }
    }
    if ([[characteristicType identifier] isEqualToString:HKCharacteristicTypeIdentifierFitzpatrickSkinType]) {
        HKFitzpatrickSkinTypeObject *skinType = [_healthStore fitzpatrickSkinTypeWithError:error];
        if (skinType && skinType.skinType != HKFitzpatrickSkinTypeNotSet) {
            result = @(skinType.skinType);
        }
        if (result) {
            result = @[result];
        }
    }
    if (ORK1_IOS_10_WATCHOS_3_AVAILABLE && [[characteristicType identifier] isEqualToString:HKCharacteristicTypeIdentifierWheelchairUse]) {
        HKWheelchairUseObject *wheelchairUse = [_healthStore wheelchairUseWithError:error];
        if (wheelchairUse && wheelchairUse.wheelchairUse != HKWheelchairUseNotSet) {
            result = (wheelchairUse.wheelchairUse == HKWheelchairUseYes) ? @YES : @NO;
        }
        if (result) {
            result = @[result];
        }
    }
    return result;
}

- (void)fetchDefaultValueForQuantityType:(HKQuantityType *)quantityType unit:(HKUnit *)unit handler:(void(^)(id defaultValue, NSError *error))handler {
    if (!unit) {
        handler(nil, nil);
        return;
    }
    
    HKHealthStore *healthStore = _healthStore;
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:quantityType predicate:nil limit:1 sortDescriptors:@[sortDescriptor] resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
            HKQuantitySample *sample = results.firstObject;
            id value = nil;
            if (sample) {
                if (unit == [HKUnit percentUnit]) {
                    value = @(100 * [sample.quantity doubleValueForUnit:unit]);
                } else {
                    value = @([sample.quantity doubleValueForUnit:unit]);
                }
            }
            handler(value, error);
        }];
        [healthStore executeQuery:sampleQuery];
    });
}

- (void)fetchDefaultValueForAnswerFormat:(ORK1AnswerFormat *)answerFormat handler:(void(^)(id defaultValue, NSError *error))handler {
    HKObjectType *objectType = [answerFormat healthKitObjectType];
    BOOL handled = NO;
    if (objectType) {
        if ([HKHealthStore isHealthDataAvailable]) {
            if ([answerFormat isKindOfClass:[ORK1HealthKitCharacteristicTypeAnswerFormat class]]) {
                NSError *error = nil;
                id defaultValue = [self defaultValueForCharacteristicType:(HKCharacteristicType *)objectType error:&error];
                handler(defaultValue, error);
                handled = YES;
            } else if ([answerFormat isKindOfClass:[ORK1HealthKitQuantityTypeAnswerFormat class]]) {
                [self updateHealthKitUnitForAnswerFormat:answerFormat force:NO];
                HKUnit *unit = [answerFormat healthKitUserUnit];
                [self fetchDefaultValueForQuantityType:(HKQuantityType *)objectType unit:unit handler:handler];
                handled = YES;
            }
        }
    }
    if (!handled) {
        handler(nil, nil);
    }
}

- (HKUnit *)defaultHealthKitUnitForAnswerFormat:(ORK1AnswerFormat *)answerFormat {
    __block HKUnit *unit = [answerFormat healthKitUnit];
    HKObjectType *objectType = [answerFormat healthKitObjectType];
    if (![[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 8, .minorVersion = 2, .patchVersion = 0}]) {
        return unit;
    }
    
    if (unit == nil && [objectType isKindOfClass:[HKQuantityType class]] && [HKHealthStore isHealthDataAvailable]) {
        unit = _unitsTable[objectType];
        if (unit) {
            return unit;
        }
        if (!_unitsTable) {
            _unitsTable = [NSMutableDictionary dictionary];
        }
        
        HKQuantityType *quantityType = (HKQuantityType *)objectType;
        
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        [_healthStore preferredUnitsForQuantityTypes:[NSSet setWithObject:quantityType] completion:^(NSDictionary *preferredUnits, NSError *error) {
            
            unit = preferredUnits[quantityType];
            
            dispatch_semaphore_signal(sem);
        }];
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        
        if (unit) {
            _unitsTable[objectType] = unit;
        }
    }
    return unit;
}

- (void)updateHealthKitUnitForAnswerFormat:(ORK1AnswerFormat *)answerFormat force:(BOOL)force {
    HKUnit *unit = [answerFormat healthKitUserUnit];
    HKUnit *healthKitDefault = [self defaultHealthKitUnitForAnswerFormat:answerFormat];
    if (!ORK1EqualObjects(unit,healthKitDefault) && (force || (unit == nil))) {
        [answerFormat setHealthKitUserUnit:healthKitDefault];
    }
}

@end


#pragma mark - ORK1AnswerFormat

@implementation ORK1AnswerFormat

+ (ORK1ScaleAnswerFormat *)scaleAnswerFormatWithMaximumValue:(NSInteger)scaleMaximum
                                               minimumValue:(NSInteger)scaleMinimum
                                               defaultValue:(NSInteger)defaultValue
                                                       step:(NSInteger)step
                                                   vertical:(BOOL)vertical
                                    maximumValueDescription:(nullable NSString *)maximumValueDescription
                                    minimumValueDescription:(nullable NSString *)minimumValueDescription {
    return [[ORK1ScaleAnswerFormat alloc] initWithMaximumValue:scaleMaximum
                                                 minimumValue:scaleMinimum
                                                 defaultValue:defaultValue
                                                         step:step
                                                     vertical:vertical
                                      maximumValueDescription:maximumValueDescription
                                      minimumValueDescription:minimumValueDescription];
}

+ (ORK1ContinuousScaleAnswerFormat *)continuousScaleAnswerFormatWithMaximumValue:(double)scaleMaximum
                                                                   minimumValue:(double)scaleMinimum
                                                                   defaultValue:(double)defaultValue
                                                          maximumFractionDigits:(NSInteger)maximumFractionDigits
                                                                       vertical:(BOOL)vertical
                                                        maximumValueDescription:(nullable NSString *)maximumValueDescription
                                                        minimumValueDescription:(nullable NSString *)minimumValueDescription {
    return [[ORK1ContinuousScaleAnswerFormat alloc] initWithMaximumValue:scaleMaximum
                                                           minimumValue:scaleMinimum
                                                           defaultValue:defaultValue
                                                  maximumFractionDigits:maximumFractionDigits
                                                               vertical:vertical
                                                maximumValueDescription:maximumValueDescription
                                                minimumValueDescription:minimumValueDescription];
}

+ (ORK1TextScaleAnswerFormat *)textScaleAnswerFormatWithTextChoices:(NSArray<ORK1TextChoice *> *)textChoices
                                                      defaultIndex:(NSInteger)defaultIndex
                                                          vertical:(BOOL)vertical {
    return [[ORK1TextScaleAnswerFormat alloc] initWithTextChoices:textChoices
                                                    defaultIndex:defaultIndex
                                                        vertical:vertical];
}

+ (ORK1BooleanAnswerFormat *)booleanAnswerFormat {
    return [ORK1BooleanAnswerFormat new];
}

+ (ORK1BooleanAnswerFormat *)booleanAnswerFormatWithYesString:(NSString *)yes noString:(NSString *)no {
    return [[ORK1BooleanAnswerFormat alloc] initWithYesString:yes noString:no];
}

+ (ORK1ValuePickerAnswerFormat *)valuePickerAnswerFormatWithTextChoices:(NSArray<ORK1TextChoice *> *)textChoices {
    return [[ORK1ValuePickerAnswerFormat alloc] initWithTextChoices:textChoices];
}

+ (ORK1MultipleValuePickerAnswerFormat *)multipleValuePickerAnswerFormatWithValuePickers:(NSArray<ORK1ValuePickerAnswerFormat *> *)valuePickers {
    return [[ORK1MultipleValuePickerAnswerFormat alloc] initWithValuePickers:valuePickers];
}

+ (ORK1ImageChoiceAnswerFormat *)choiceAnswerFormatWithImageChoices:(NSArray<ORK1ImageChoice *> *)imageChoices {
    return [[ORK1ImageChoiceAnswerFormat alloc] initWithImageChoices:imageChoices];
}

+ (ORK1TextChoiceAnswerFormat *)choiceAnswerFormatWithStyle:(ORK1ChoiceAnswerStyle)style
                                               textChoices:(NSArray<ORK1TextChoice *> *)textChoices {
    return [[ORK1TextChoiceAnswerFormat alloc] initWithStyle:style textChoices:textChoices];
}

+ (ORK1NumericAnswerFormat *)decimalAnswerFormatWithUnit:(NSString *)unit {
    return [[ORK1NumericAnswerFormat alloc] initWithStyle:ORK1NumericAnswerStyleDecimal unit:unit minimum:nil maximum:nil];
}
+ (ORK1NumericAnswerFormat *)integerAnswerFormatWithUnit:(NSString *)unit {
    return [[ORK1NumericAnswerFormat alloc] initWithStyle:ORK1NumericAnswerStyleInteger unit:unit minimum:nil maximum:nil];
}

+ (ORK1TimeOfDayAnswerFormat *)timeOfDayAnswerFormat {
    return [ORK1TimeOfDayAnswerFormat new];
}
+ (ORK1TimeOfDayAnswerFormat *)timeOfDayAnswerFormatWithDefaultComponents:(NSDateComponents *)defaultComponents {
    return [[ORK1TimeOfDayAnswerFormat alloc] initWithDefaultComponents:defaultComponents];
}

+ (ORK1DateAnswerFormat *)dateTimeAnswerFormat {
    return [[ORK1DateAnswerFormat alloc] initWithStyle:ORK1DateAnswerStyleDateAndTime];
}
+ (ORK1DateAnswerFormat *)dateTimeAnswerFormatWithDefaultDate:(NSDate *)defaultDate
                                                 minimumDate:(NSDate *)minimumDate
                                                 maximumDate:(NSDate *)maximumDate
                                                    calendar:(NSCalendar *)calendar {
    return [[ORK1DateAnswerFormat alloc] initWithStyle:ORK1DateAnswerStyleDateAndTime
                                          defaultDate:defaultDate
                                          minimumDate:minimumDate
                                          maximumDate:maximumDate
                                             calendar:calendar];
}

+ (ORK1DateAnswerFormat *)dateAnswerFormat {
    return [[ORK1DateAnswerFormat alloc] initWithStyle:ORK1DateAnswerStyleDate];
}
+ (ORK1DateAnswerFormat *)dateAnswerFormatWithDefaultDate:(NSDate *)defaultDate
                                             minimumDate:(NSDate *)minimumDate
                                             maximumDate:(NSDate *)maximumDate
                                                calendar:(NSCalendar *)calendar  {
    return [[ORK1DateAnswerFormat alloc] initWithStyle:ORK1DateAnswerStyleDate
                                          defaultDate:defaultDate
                                          minimumDate:minimumDate
                                          maximumDate:maximumDate
                                             calendar:calendar];
}

+ (ORK1TextAnswerFormat *)textAnswerFormat {
    return [ORK1TextAnswerFormat new];
}

+ (ORK1TextAnswerFormat *)textAnswerFormatWithMaximumLength:(NSInteger)maximumLength {
    return [[ORK1TextAnswerFormat alloc] initWithMaximumLength:maximumLength];
}

+ (ORK1TextAnswerFormat *)textAnswerFormatWithValidationRegularExpression:(NSRegularExpression *)validationRegularExpression
                                                          invalidMessage:(NSString *)invalidMessage {
    return [[ORK1TextAnswerFormat alloc] initWithValidationRegularExpression:validationRegularExpression
                                                             invalidMessage:invalidMessage];
}

+ (ORK1EmailAnswerFormat *)emailAnswerFormat {
    return [ORK1EmailAnswerFormat new];
}

+ (ORK1TimeIntervalAnswerFormat *)timeIntervalAnswerFormat {
    return [ORK1TimeIntervalAnswerFormat new];
}

+ (ORK1TimeIntervalAnswerFormat *)timeIntervalAnswerFormatWithDefaultInterval:(NSTimeInterval)defaultInterval
                                                                        step:(NSInteger)step {
    return [[ORK1TimeIntervalAnswerFormat alloc] initWithDefaultInterval:defaultInterval step:step];
}

+ (ORK1HeightAnswerFormat *)heightAnswerFormat {
    return [ORK1HeightAnswerFormat new];
}

+ (ORK1HeightAnswerFormat *)heightAnswerFormatWithMeasurementSystem:(ORK1MeasurementSystem)measurementSystem {
    return [[ORK1HeightAnswerFormat alloc] initWithMeasurementSystem:measurementSystem];
}

+ (ORK1WeightAnswerFormat *)weightAnswerFormat {
    return [ORK1WeightAnswerFormat new];
}

+ (ORK1WeightAnswerFormat *)weightAnswerFormatWithMeasurementSystem:(ORK1MeasurementSystem)measurementSystem {
    return [[ORK1WeightAnswerFormat alloc] initWithMeasurementSystem:measurementSystem];
}

+ (ORK1WeightAnswerFormat *)weightAnswerFormatWithMeasurementSystem:(ORK1MeasurementSystem)measurementSystem
                                                  numericPrecision:(ORK1NumericPrecision)numericPrecision {
    return [[ORK1WeightAnswerFormat alloc] initWithMeasurementSystem:measurementSystem
                                                   numericPrecision:numericPrecision];
}

+ (ORK1WeightAnswerFormat *)weightAnswerFormatWithMeasurementSystem:(ORK1MeasurementSystem)measurementSystem
                                                  numericPrecision:(ORK1NumericPrecision)numericPrecision
                                                      minimumValue:(double)minimumValue
                                                      maximumValue:(double)maximumValue
                                                    defaultValue:(double)defaultValue {
    return [[ORK1WeightAnswerFormat alloc] initWithMeasurementSystem:measurementSystem
                                                   numericPrecision:numericPrecision
                                                       minimumValue:minimumValue
                                                       maximumValue:maximumValue
                                                       defaultValue:defaultValue];
}

+ (ORK1LocationAnswerFormat *)locationAnswerFormat {
    return [ORK1LocationAnswerFormat new];
}

- (void)validateParameters {
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)init {
    return [super init];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    return YES;
}

- (NSUInteger)hash {
    // Ignore the task reference - it's not part of the content of the step.
    return 0;
}

- (BOOL)isHealthKitAnswerFormat {
    return NO;
}

- (HKObjectType *)healthKitObjectType {
    return nil;
}

- (HKObjectType *)healthKitObjectTypeForAuthorization {
    return nil;
}

- (HKUnit *)healthKitUnit {
    return nil;
}

- (HKUnit *)healthKitUserUnit {
    return nil;
}

- (void)setHealthKitUserUnit:(HKUnit *)unit {
    
}

- (ORK1QuestionType)questionType {
    return ORK1QuestionTypeNone;
}

- (ORK1AnswerFormat *)impliedAnswerFormat {
    return self;
}

- (Class)questionResultClass {
    return [ORK1QuestionResult class];
}

- (ORK1QuestionResult *)resultWithIdentifier:(NSString *)identifier answer:(id)answer {
    ORK1QuestionResult *questionResult = [[[self questionResultClass] alloc] initWithIdentifier:identifier];
    
    /*
     ContinuousScale navigation rules always evaluate to false because the result is different from what is displayed in the UI.
     The fraction digits have to be taken into account in self.answer as well.
     */
    if ([self isKindOfClass:[ORK1ContinuousScaleAnswerFormat class]]) {
        NSNumberFormatter* formatter = [(ORK1ContinuousScaleAnswerFormat*)self numberFormatter];
        answer = [formatter numberFromString:[formatter stringFromNumber:answer]];
    }
    
    questionResult.answer = answer;
    questionResult.questionType = self.questionType;
    return questionResult;
}

- (BOOL)isAnswerValid:(id)answer {
    ORK1AnswerFormat *impliedFormat = [self impliedAnswerFormat];
    return impliedFormat == self ? YES : [impliedFormat isAnswerValid:answer];
}

- (BOOL)isAnswerValidWithString:(NSString *)text {
    ORK1AnswerFormat *impliedFormat = [self impliedAnswerFormat];
    return impliedFormat == self ? YES : [impliedFormat isAnswerValidWithString:text];
}

- (NSString *)localizedInvalidValueStringWithAnswerString:(NSString *)text {
    return nil;
}

- (NSString *)stringForAnswer:(id)answer {
    ORK1AnswerFormat *impliedFormat = [self impliedAnswerFormat];
    return impliedFormat == self ? nil : [impliedFormat stringForAnswer:answer];
}

@end


#pragma mark - ORK1ValuePickerAnswerFormat

static void ork_validateChoices(NSArray *choices) {
    const NSInteger ORK1AnswerFormatMinimumNumberOfChoices = 1;
    if (choices.count < ORK1AnswerFormatMinimumNumberOfChoices) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"The number of choices cannot be less than %@.", @(ORK1AnswerFormatMinimumNumberOfChoices)]
                                     userInfo:nil];
    }
}

static NSArray *ork_processTextChoices(NSArray<ORK1TextChoice *> *textChoices) {
    NSMutableArray *choices = [[NSMutableArray alloc] init];
    for (id object in textChoices) {
        // TODO: Remove these first two cases, which we don't really support anymore.
        if ([object isKindOfClass:[NSString class]]) {
            NSString *string = (NSString *)object;
            [choices addObject:[ORK1TextChoice choiceWithText:string value:string]];
        } else if ([object isKindOfClass:[ORK1TextChoice class]]) {
            [choices addObject:object];
            
        } else if ([object isKindOfClass:[NSArray class]]) {
            
            NSArray *array = (NSArray *)object;
            if (array.count > 1 &&
                [array[0] isKindOfClass:[NSString class]] &&
                [array[1] isKindOfClass:[NSString class]]) {
                
                [choices addObject:[ORK1TextChoice choiceWithText:array[0] detailText:array[1] value:array[0] exclusive:NO]];
            } else if (array.count == 1 &&
                       [array[0] isKindOfClass:[NSString class]]) {
                [choices addObject:[ORK1TextChoice choiceWithText:array[0] detailText:@"" value:array[0] exclusive:NO]];
            } else {
                @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Eligible array type Choice item should contain one or two NSString object." userInfo:@{@"choice": object }];
            }
        } else {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Eligible choice item's type are ORK1TextChoice, NSString, and NSArray" userInfo:@{@"choice": object }];
        }
    }
    return choices;
}


@implementation ORK1ValuePickerAnswerFormat {
    ORK1ChoiceAnswerFormatHelper *_helper;
    ORK1TextChoice *_nullTextChoice;
}

+ (instancetype)new {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)initWithTextChoices:(NSArray<ORK1TextChoice *> *)textChoices {
    self = [super init];
    if (self) {
        [self commonInitWithTextChoices:textChoices nullChoice:nil];
    }
    return self;
}

- (instancetype)initWithTextChoices:(NSArray<ORK1TextChoice *> *)textChoices nullChoice:(ORK1TextChoice *)nullChoice {
    self = [super init];
    if (self) {
        [self commonInitWithTextChoices:textChoices nullChoice:nullChoice];
    }
    return self;
}

- (void)commonInitWithTextChoices:(NSArray<ORK1TextChoice *> *)textChoices nullChoice:(ORK1TextChoice *)nullChoice {
    _textChoices = ork_processTextChoices(textChoices);
    _nullTextChoice = nullChoice;
    _helper = [[ORK1ChoiceAnswerFormatHelper alloc] initWithAnswerFormat:self];
}


- (void)validateParameters {
    [super validateParameters];
    
    ork_validateChoices(_textChoices);
}

- (id)copyWithZone:(NSZone *)zone {
    __typeof(self) copy = [[[self class] alloc] initWithTextChoices:_textChoices nullChoice:_nullTextChoice];
    return copy;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORK1EqualObjects(self.textChoices, castObject.textChoices));
}

- (NSUInteger)hash {
    return super.hash ^ _textChoices.hash;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_ARRAY(aDecoder, textChoices, ORK1TextChoice);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, textChoices);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (ORK1TextChoice *)nullTextChoice {
    return _nullTextChoice ?: [ORK1TextChoice choiceWithText:ORK1LocalizedString(@"NULL_ANSWER", nil) value:ORK1NullAnswerValue()];
}

- (void)setNullTextChoice:(ORK1TextChoice *)nullChoice {
    _nullTextChoice = nullChoice;
}

- (Class)questionResultClass {
    return [ORK1ChoiceQuestionResult class];
}

- (ORK1QuestionType)questionType {
    return ORK1QuestionTypeSingleChoice;
}

- (NSString *)stringForAnswer:(id)answer {
    return [_helper stringForChoiceAnswer:answer];
}

@end


#pragma mark - ORK1MultipleValuePickerAnswerFormat

@implementation ORK1MultipleValuePickerAnswerFormat

+ (instancetype)new {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)initWithValuePickers:(NSArray<ORK1ValuePickerAnswerFormat *> *)valuePickers {
    return [self initWithValuePickers:valuePickers separator:@" "];
}

- (instancetype)initWithValuePickers:(NSArray<ORK1ValuePickerAnswerFormat *> *)valuePickers separator:(NSString *)separator {
    self = [super init];
    if (self) {
        for (ORK1ValuePickerAnswerFormat *valuePicker in valuePickers) {
            // Do not show placeholder text for multiple component picker
            [valuePicker setNullTextChoice: [ORK1TextChoice choiceWithText:@"" value:ORK1NullAnswerValue()]];
        }
        _valuePickers = ORK1ArrayCopyObjects(valuePickers);
        _separator = [separator copy];
    }
    return self;
}

- (void)validateParameters {
    [super validateParameters];
    for (ORK1ValuePickerAnswerFormat *valuePicker in self.valuePickers) {
        [valuePicker validateParameters];
    }
}

- (id)copyWithZone:(NSZone *)zone {
    __typeof(self) copy = [[[self class] alloc] initWithValuePickers:self.valuePickers separator:self.separator];
    return copy;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORK1EqualObjects(self.valuePickers, castObject.valuePickers));
}

- (NSUInteger)hash {
    return super.hash ^ self.valuePickers.hash ^ self.separator.hash;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_ARRAY(aDecoder, valuePickers, ORK1ValuePickerAnswerFormat);
        ORK1_DECODE_OBJ_CLASS(aDecoder, separator, NSString);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, valuePickers);
    ORK1_ENCODE_OBJ(aCoder, separator);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (Class)questionResultClass {
    return [ORK1MultipleComponentQuestionResult class];
}

- (ORK1QuestionResult *)resultWithIdentifier:(NSString *)identifier answer:(id)answer {
    ORK1QuestionResult *questionResult = [super resultWithIdentifier:identifier answer:answer];
    if ([questionResult isKindOfClass:[ORK1MultipleComponentQuestionResult class]]) {
        ((ORK1MultipleComponentQuestionResult*)questionResult).separator = self.separator;
    }
    return questionResult;
}

- (ORK1QuestionType)questionType {
    return ORK1QuestionTypeMultiplePicker;
}

- (NSString *)stringForAnswer:(id)answer {
    if (![answer isKindOfClass:[NSArray class]] || ([(NSArray*)answer count] != self.valuePickers.count)) {
        return nil;
    }
    
    NSArray *answers = (NSArray*)answer;
    __block NSMutableArray <NSString *> *answerTexts = [NSMutableArray new];
    [answers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *text = [self.valuePickers[idx] stringForAnswer:obj];
        if (text != nil) {
            [answerTexts addObject:text];
        } else {
            *stop = YES;
        }
    }];
    
    if (answerTexts.count != self.valuePickers.count) {
        return nil;
    }
    
    return [answerTexts componentsJoinedByString:self.separator];
}

@end


#pragma mark - ORK1ImageChoiceAnswerFormat

@interface ORK1ImageChoiceAnswerFormat () {
    ORK1ChoiceAnswerFormatHelper *_helper;
    
}

@end


@implementation ORK1ImageChoiceAnswerFormat

+ (instancetype)new {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)initWithImageChoices:(NSArray<ORK1ImageChoice *> *)imageChoices {
    self = [super init];
    if (self) {
        NSMutableArray *choices = [[NSMutableArray alloc] init];
        
        for (NSObject *obj in imageChoices) {
            if ([obj isKindOfClass:[ORK1ImageChoice class]]) {
                
                [choices addObject:obj];
                
            } else {
                @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Options should be instances of ORK1ImageChoice" userInfo:@{ @"option": obj }];
            }
        }
        _imageChoices = choices;
        _helper = [[ORK1ChoiceAnswerFormatHelper alloc] initWithAnswerFormat:self];
    }
    return self;
}

- (void)validateParameters {
    [super validateParameters];
    
    ork_validateChoices(_imageChoices);
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORK1EqualObjects(self.imageChoices, castObject.imageChoices));
}

- (NSUInteger)hash {
    return super.hash ^ self.imageChoices.hash;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_ARRAY(aDecoder, imageChoices, ORK1ImageChoice);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, imageChoices);
    
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (ORK1QuestionType)questionType {
    return ORK1QuestionTypeSingleChoice;
}

- (Class)questionResultClass {
    return [ORK1ChoiceQuestionResult class];
}

- (NSString *)stringForAnswer:(id)answer {
    return [_helper stringForChoiceAnswer:answer];
}

@end


#pragma mark - ORK1TextChoiceAnswerFormat

@interface ORK1TextChoiceAnswerFormat () {
    
    ORK1ChoiceAnswerFormatHelper *_helper;
}

@end


@implementation ORK1TextChoiceAnswerFormat

+ (instancetype)new {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)initWithStyle:(ORK1ChoiceAnswerStyle)style
                  textChoices:(NSArray<ORK1TextChoice *> *)textChoices {
    self = [super init];
    if (self) {
        _style = style;
        _textChoices = ork_processTextChoices(textChoices);
        _helper = [[ORK1ChoiceAnswerFormatHelper alloc] initWithAnswerFormat:self];
    }
    return self;
}

- (void)validateParameters {
    [super validateParameters];
    
    ork_validateChoices(_textChoices);
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORK1EqualObjects(self.textChoices, castObject.textChoices) &&
            (_style == castObject.style));
}

- (NSUInteger)hash {
    return super.hash ^ _textChoices.hash ^ _style;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_ARRAY(aDecoder, textChoices, ORK1TextChoice);
        ORK1_DECODE_ENUM(aDecoder, style);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, textChoices);
    ORK1_ENCODE_ENUM(aCoder, style);
    
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (ORK1QuestionType)questionType {
    return (_style == ORK1ChoiceAnswerStyleSingleChoice) ? ORK1QuestionTypeSingleChoice : ORK1QuestionTypeMultipleChoice;
}

- (Class)questionResultClass {
    return [ORK1ChoiceQuestionResult class];
}

- (NSString *)stringForAnswer:(id)answer {
    return [_helper stringForChoiceAnswer:answer];
}

@end


#pragma mark - ORK1TextChoice

@implementation ORK1TextChoice {
    NSString *_text;
    id<NSCopying, NSCoding, NSObject> _value;
}

+ (instancetype)new {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    ORK1ThrowMethodUnavailableException();
}

+ (instancetype)choiceWithText:(NSString *)text detailText:(NSString *)detailText value:(id<NSCopying, NSCoding, NSObject>)value exclusive:(BOOL)exclusive {
    ORK1TextChoice *option = [[ORK1TextChoice alloc] initWithText:text detailText:detailText value:value exclusive:exclusive];
    option.detailTextShouldDisplay = YES;
    return option;
}

+ (instancetype)choiceWithText:(NSString *)text value:(id<NSCopying, NSCoding, NSObject>)value {
    return [ORK1TextChoice choiceWithText:text detailText:nil value:value exclusive:NO];
}

- (instancetype)initWithText:(NSString *)text detailText:(NSString *)detailText value:(id<NSCopying,NSCoding,NSObject>)value exclusive:(BOOL)exclusive {
    self = [super init];
    if (self) {
        _text = [text copy];
        _detailText = [detailText copy];
        _value = value;
        _exclusive = exclusive;
        _detailTextShouldDisplay = YES;
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    // Ignore the task reference - it's not part of the content of the step
    __typeof(self) castObject = object;
    return (ORK1EqualObjects(self.text, castObject.text)
            && ORK1EqualObjects(self.detailText, castObject.detailText)
            && ORK1EqualObjects(self.value, castObject.value)
            && self.exclusive == castObject.exclusive
            && self.detailTextShouldDisplay == castObject.detailTextShouldDisplay);
}

- (NSUInteger)hash {
    // Ignore the task reference - it's not part of the content of the step
    return _text.hash ^ _detailText.hash ^ _value.hash;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, text, NSString);
        ORK1_DECODE_OBJ_CLASS(aDecoder, detailText, NSString);
        ORK1_DECODE_OBJ(aDecoder, value);
        ORK1_DECODE_BOOL(aDecoder, exclusive);
        ORK1_DECODE_BOOL(aDecoder, detailTextShouldDisplay);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORK1_ENCODE_OBJ(aCoder, text);
    ORK1_ENCODE_OBJ(aCoder, value);
    ORK1_ENCODE_OBJ(aCoder, detailText);
    ORK1_ENCODE_BOOL(aCoder, exclusive);
    ORK1_ENCODE_BOOL(aCoder, detailTextShouldDisplay);
}

@end


#pragma mark - ORK1ImageChoice

@implementation ORK1ImageChoice {
    NSString *_text;
    id<NSCopying, NSCoding, NSObject> _value;
}

+ (instancetype)choiceWithNormalImage:(UIImage *)normal selectedImage:(UIImage *)selected text:(NSString *)text value:(id<NSCopying, NSCoding, NSObject>)value {
    return [[ORK1ImageChoice alloc] initWithNormalImage:normal selectedImage:selected text:text value:value];
}

+ (instancetype)new {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)initWithNormalImage:(UIImage *)normal selectedImage:(UIImage *)selected text:(NSString *)text value:(id<NSCopying,NSCoding,NSObject>)value {
    self = [super init];
    if (self) {
        _text = [text copy];
        _value = value;
        _normalStateImage = normal;
        _selectedStateImage = selected;
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSString *)text {
    return _text;
}

- (id<NSCopying, NSCoding>)value {
    return _value;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    // Ignore the task reference - it's not part of the content of the step.
    
    __typeof(self) castObject = object;
    return (ORK1EqualObjects(self.text, castObject.text)
            && ORK1EqualObjects(self.value, castObject.value)
            && ORK1EqualObjects(self.normalStateImage, castObject.normalStateImage)
            && ORK1EqualObjects(self.selectedStateImage, castObject.selectedStateImage));
}

- (NSUInteger)hash {
    // Ignore the task reference - it's not part of the content of the step.
    return _text.hash ^ _value.hash;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, text, NSString);
        ORK1_DECODE_OBJ(aDecoder, value);
        ORK1_DECODE_IMAGE(aDecoder, normalStateImage);
        ORK1_DECODE_IMAGE(aDecoder, selectedStateImage);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORK1_ENCODE_OBJ(aCoder, text);
    ORK1_ENCODE_OBJ(aCoder, value);
    ORK1_ENCODE_IMAGE(aCoder, normalStateImage);
    ORK1_ENCODE_IMAGE(aCoder, selectedStateImage);
}

@end


#pragma mark - ORK1BooleanAnswerFormat

@implementation ORK1BooleanAnswerFormat

- (instancetype)initWithYesString:(NSString *)yes noString:(NSString *)no {
    self = [super init];
    if (self) {
        _yes = [yes copy];
        _no = [no copy];
    }
    return self;
}

- (ORK1QuestionType)questionType {
    return ORK1QuestionTypeBoolean;
}

- (ORK1AnswerFormat *)impliedAnswerFormat {
    if (!_yes.length) {
        _yes = ORK1LocalizedString(@"BOOL_YES", nil);
    }
    if (!_no.length) {
        _no = ORK1LocalizedString(@"BOOL_NO", nil);
    }
    
    return [ORK1AnswerFormat choiceAnswerFormatWithStyle:ORK1ChoiceAnswerStyleSingleChoice
                                            textChoices:@[[ORK1TextChoice choiceWithText:_yes value:@(YES)],
                                                          [ORK1TextChoice choiceWithText:_no value:@(NO)]]];
}

- (Class)questionResultClass {
    return [ORK1BooleanQuestionResult class];
}

- (NSString *)stringForAnswer:(id)answer {
    return [self.impliedAnswerFormat stringForAnswer: @[answer]];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1BooleanAnswerFormat *answerFormat = [super copyWithZone:zone];
    answerFormat->_yes = [_yes copy];
    answerFormat->_no = [_no copy];
    return answerFormat;
}

- (NSUInteger)hash {
    return super.hash ^ _yes.hash ^ _no.hash;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORK1EqualObjects(self.yes, castObject.yes) &&
            ORK1EqualObjects(self.no, castObject.no));
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, yes, NSString);
        ORK1_DECODE_OBJ_CLASS(aDecoder, no, NSString);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, yes);
    ORK1_ENCODE_OBJ(aCoder, no);
}

@end


#pragma mark - ORK1TimeOfDayAnswerFormat

@implementation ORK1TimeOfDayAnswerFormat

- (instancetype)init {
    self = [self initWithDefaultComponents:nil];
    return self;
}

- (instancetype)initWithDefaultComponents:(NSDateComponents *)defaultComponents {
    self = [super init];
    if (self) {
        _defaultComponents = [defaultComponents copy];
    }
    return self;
}

- (ORK1QuestionType)questionType {
    return ORK1QuestionTypeTimeOfDay;
}

- (Class)questionResultClass {
    return [ORK1TimeOfDayQuestionResult class];
}

- (NSDate *)pickerDefaultDate {
    
    if (self.defaultComponents) {
        return ORK1TimeOfDayDateFromComponents(self.defaultComponents);
    }
    
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] componentsInTimeZone:[NSTimeZone systemTimeZone] fromDate:[NSDate date]];
    NSDateComponents *newDateComponents = [[NSDateComponents alloc] init];
    newDateComponents.calendar = ORK1TimeOfDayReferenceCalendar();
    newDateComponents.hour = dateComponents.hour;
    newDateComponents.minute = dateComponents.minute;
    
    return ORK1TimeOfDayDateFromComponents(newDateComponents);
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORK1EqualObjects(self.defaultComponents, castObject.defaultComponents));
}

- (NSUInteger)hash {
    // Don't bother including everything
    return super.hash & self.defaultComponents.hash;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, defaultComponents, NSDateComponents);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, defaultComponents);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (NSString *)stringForAnswer:(id)answer {
    return ORK1TimeOfDayStringFromComponents(answer);
}

@end


#pragma mark - ORK1DateAnswerFormat

@implementation ORK1DateAnswerFormat

- (Class)questionResultClass {
    return [ORK1DateQuestionResult class];
}

+ (instancetype)new {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)initWithStyle:(ORK1DateAnswerStyle)style {
    self = [self initWithStyle:style defaultDate:nil minimumDate:nil maximumDate:nil calendar:nil];
    return self;
}

- (instancetype)initWithStyle:(ORK1DateAnswerStyle)style
                  defaultDate:(NSDate *)defaultDate
                  minimumDate:(NSDate *)minimum
                  maximumDate:(NSDate *)maximum
                     calendar:(NSCalendar *)calendar {
    self = [super init];
    if (self) {
        _style = style;
        _defaultDate = [defaultDate copy];
        _minimumDate = [minimum copy];
        _maximumDate = [maximum copy];
        _calendar = [calendar copy];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORK1EqualObjects(self.defaultDate, castObject.defaultDate) &&
            ORK1EqualObjects(self.minimumDate, castObject.minimumDate) &&
            ORK1EqualObjects(self.maximumDate, castObject.maximumDate) &&
            ORK1EqualObjects(self.calendar, castObject.calendar) &&
            (_style == castObject.style));
}

- (NSUInteger)hash {
    // Don't bother including everything - style is the main item.
    return ([super hash] & [self.defaultDate hash]) ^ _style;
}

- (NSCalendar *)currentCalendar {
    return (_calendar ? : [NSCalendar currentCalendar]);
}

- (NSDateFormatter *)resultDateFormatter {
    NSDateFormatter *dfm = nil;
    switch (self.questionType) {
        case ORK1QuestionTypeDate: {
            dfm = ORK1ResultDateFormatter();
            break;
        }
        case ORK1QuestionTypeTimeOfDay: {
            dfm = ORK1ResultTimeFormatter();
            break;
        }
        case ORK1QuestionTypeDateAndTime: {
            dfm = ORK1ResultDateTimeFormatter();
            break;
        }
        default:
            break;
    }
    dfm = [dfm copy];
    dfm.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    return dfm;
}

- (NSString *)stringFromDate:(NSDate *)date {
    NSDateFormatter *dfm = [self resultDateFormatter];
    return [dfm stringFromDate:date];
}

- (NSDate *)dateFromString:(NSString *)string {
    NSDateFormatter *dfm = [self resultDateFormatter];
    return [dfm dateFromString:string];
}

- (NSDate *)pickerDefaultDate {
    return (self.defaultDate ? : [NSDate date]);
    
}

- (NSDate *)pickerMinimumDate {
    return self.minimumDate;
}

- (NSDate *)pickerMaximumDate {
    return self.maximumDate;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_ENUM(aDecoder, style);
        ORK1_DECODE_OBJ_CLASS(aDecoder, minimumDate, NSDate);
        ORK1_DECODE_OBJ_CLASS(aDecoder, maximumDate, NSDate);
        ORK1_DECODE_OBJ_CLASS(aDecoder, defaultDate, NSDate);
        ORK1_DECODE_OBJ_CLASS(aDecoder, calendar, NSCalendar);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_ENUM(aCoder, style);
    ORK1_ENCODE_OBJ(aCoder, minimumDate);
    ORK1_ENCODE_OBJ(aCoder, maximumDate);
    ORK1_ENCODE_OBJ(aCoder, defaultDate);
    ORK1_ENCODE_OBJ(aCoder, calendar);
}

- (ORK1QuestionType)questionType {
    return (_style == ORK1DateAnswerStyleDateAndTime) ? ORK1QuestionTypeDateAndTime : ORK1QuestionTypeDate;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (NSString *)stringForAnswer:(id)answer {
    return [self stringFromDate:answer];
}

@end


#pragma mark - ORK1NumericAnswerFormat

@implementation ORK1NumericAnswerFormat

- (Class)questionResultClass {
    return [ORK1NumericQuestionResult class];
}

+ (instancetype)new {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)initWithStyle:(ORK1NumericAnswerStyle)style {
    self = [self initWithStyle:style unit:nil minimum:nil maximum:nil];
    return self;
}

- (instancetype)initWithStyle:(ORK1NumericAnswerStyle)style unit:(NSString *)unit minimum:(NSNumber *)minimum maximum:(NSNumber *)maximum {
    self = [super init];
    if (self) {
        _style = style;
        _unit = [unit copy];
        self.minimum = minimum;
        self.maximum = maximum;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_ENUM(aDecoder, style);
        ORK1_DECODE_OBJ_CLASS(aDecoder, unit, NSString);
        ORK1_DECODE_OBJ_CLASS(aDecoder, minimum, NSNumber);
        ORK1_DECODE_OBJ_CLASS(aDecoder, maximum, NSNumber);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_ENUM(aCoder, style);
    ORK1_ENCODE_OBJ(aCoder, unit);
    ORK1_ENCODE_OBJ(aCoder, minimum);
    ORK1_ENCODE_OBJ(aCoder, maximum);
    
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1NumericAnswerFormat *answerFormat = [[[self class] allocWithZone:zone] initWithStyle:_style
                                                                                       unit:[_unit copy]
                                                                                    minimum:[_minimum copy]
                                                                                    maximum:[_maximum copy]];
    return answerFormat;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORK1EqualObjects(self.unit, castObject.unit) &&
            ORK1EqualObjects(self.minimum, castObject.minimum) &&
            ORK1EqualObjects(self.maximum, castObject.maximum) &&
            (_style == castObject.style));
}

- (NSUInteger)hash {
    // Don't bother including everything - style is the main item
    return [super hash] ^ ([self.unit hash] & _style);
}

- (instancetype)initWithStyle:(ORK1NumericAnswerStyle)style unit:(NSString *)unit {
    return [self initWithStyle:style unit:unit minimum:nil maximum:nil];
}

+ (instancetype)decimalAnswerFormatWithUnit:(NSString *)unit {
    return [[ORK1NumericAnswerFormat alloc] initWithStyle:ORK1NumericAnswerStyleDecimal unit:unit];
}

+ (instancetype)integerAnswerFormatWithUnit:(NSString *)unit {
    return [[ORK1NumericAnswerFormat alloc] initWithStyle:ORK1NumericAnswerStyleInteger unit:unit];
}

- (ORK1QuestionType)questionType {
    return _style == ORK1NumericAnswerStyleDecimal ? ORK1QuestionTypeDecimal : ORK1QuestionTypeInteger;
    
}

- (BOOL)isAnswerValid:(id)answer {
    BOOL isValid = NO;
    if ([answer isKindOfClass:[NSNumber class]]) {
        return [self isAnswerValidWithNumber:(NSNumber *)answer];
    }
    return isValid;
}

- (BOOL)isAnswerValidWithNumber:(NSNumber *)number {
    BOOL isValid = NO;
    if (number) {
        isValid = YES;
        if (isnan(number.doubleValue)) {
            isValid = NO;
        } else if (self.minimum && (self.minimum.doubleValue > number.doubleValue)) {
            isValid = NO;
        } else if (self.maximum && (self.maximum.doubleValue < number.doubleValue)) {
            isValid = NO;
        }
    }
    return isValid;
}

- (BOOL)isAnswerValidWithString:(NSString *)text {
    BOOL isValid = NO;
    if (text.length > 0) {
        NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithString:text locale:[NSLocale currentLocale]];
        isValid = [self isAnswerValidWithNumber:number];
    }
    return isValid;
}

- (NSString *)localizedInvalidValueStringWithAnswerString:(NSString *)text {
    if (!text.length) {
        return nil;
    }
    NSDecimalNumber *num = [NSDecimalNumber decimalNumberWithString:text locale:[NSLocale currentLocale]];
    if (!num) {
        return nil;
    }
    NSString *string = nil;
    NSNumberFormatter *formatter = ORK1DecimalNumberFormatter();
    if (self.minimum && (self.minimum.doubleValue > num.doubleValue)) {
        string = [NSString localizedStringWithFormat:ORK1LocalizedString(@"RANGE_ALERT_MESSAGE_BELOW_MAXIMUM", nil), text, [formatter stringFromNumber:self.minimum]];
    } else if (self.maximum && (self.maximum.doubleValue < num.doubleValue)) {
        string = [NSString localizedStringWithFormat:ORK1LocalizedString(@"RANGE_ALERT_MESSAGE_ABOVE_MAXIMUM", nil), text, [formatter stringFromNumber:self.maximum]];
    } else {
        string = [NSString localizedStringWithFormat:ORK1LocalizedString(@"RANGE_ALERT_MESSAGE_OTHER", nil), text];
    }
    return string;
}

- (NSString *)stringForAnswer:(id)answer {
    NSString *answerString = nil;
    if ([self isAnswerValid:answer]) {
        NSNumberFormatter *formatter = ORK1DecimalNumberFormatter();
        answerString = [formatter stringFromNumber:answer];
        if (self.unit && self.unit.length > 0) {
            answerString = [NSString stringWithFormat:@"%@ %@", answerString, self.unit];
        }
    }
    return answerString;
}

#pragma mark - Text Sanitization

- (NSString *)removeDecimalSeparatorsFromText:(NSString *)text numAllowed:(NSInteger)numAllowed separator:(NSString *)decimalSeparator {
    NSMutableString *scanningText = [text mutableCopy];
    NSMutableString *sanitizedText = [[NSMutableString alloc] init];
    BOOL finished = NO;
    while (!finished) {
        NSRange range = [scanningText rangeOfString:decimalSeparator];
        if (range.length == 0) {
            // If our range's length is 0, there are no more decimal separators
            [sanitizedText appendString:scanningText];
            finished = YES;
        } else if (numAllowed <= 0) {
            // If we found a decimal separator and no more are allowed, remove the substring
            [scanningText deleteCharactersInRange:range];
        } else {
            NSInteger maxRange = NSMaxRange(range);
            NSString *processedString = [scanningText substringToIndex:maxRange];
            [sanitizedText appendString:processedString];
            [scanningText deleteCharactersInRange:NSMakeRange(0, maxRange)];
            --numAllowed;
        }
    }
    return sanitizedText;
}

- (NSString *)sanitizedTextFieldText:(NSString *)text decimalSeparator:(NSString *)separator {
    NSString *sanitizedText = text;
    if (_style == ORK1NumericAnswerStyleDecimal) {
        sanitizedText = [self removeDecimalSeparatorsFromText:text numAllowed:1 separator:(NSString *)separator];
    } else if (_style == ORK1NumericAnswerStyleInteger) {
        sanitizedText = [self removeDecimalSeparatorsFromText:text numAllowed:0 separator:(NSString *)separator];
    }
    return sanitizedText;
}

@end


#pragma mark - ORK1ScaleAnswerFormat

@implementation ORK1ScaleAnswerFormat {
    NSNumberFormatter *_numberFormatter;
}

- (Class)questionResultClass {
    return [ORK1ScaleQuestionResult class];
}

+ (instancetype)new {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)initWithMaximumValue:(NSInteger)maximumValue
                        minimumValue:(NSInteger)minimumValue
                        defaultValue:(NSInteger)defaultValue
                                step:(NSInteger)step
                            vertical:(BOOL)vertical
             maximumValueDescription:(nullable NSString *)maximumValueDescription
             minimumValueDescription:(nullable NSString *)minimumValueDescription {
    self = [super init];
    if (self) {
        _minimum = minimumValue;
        _maximum = maximumValue;
        _defaultValue = defaultValue;
        _step = step;
        _vertical = vertical;
        _maximumValueDescription = maximumValueDescription;
        _minimumValueDescription = minimumValueDescription;
        
        [self validateParameters];
    }
    return self;
}

- (instancetype)initWithMaximumValue:(NSInteger)maximumValue
                        minimumValue:(NSInteger)minimumValue
                        defaultValue:(NSInteger)defaultValue
                                step:(NSInteger)step
                            vertical:(BOOL)vertical {
    return [self initWithMaximumValue:maximumValue
                         minimumValue:minimumValue
                         defaultValue:defaultValue
                                 step:step
                             vertical:vertical
              maximumValueDescription:nil
              minimumValueDescription:nil];
}

- (instancetype)initWithMaximumValue:(NSInteger)maximumValue
                        minimumValue:(NSInteger)minimumValue
                        defaultValue:(NSInteger)defaultValue
                                step:(NSInteger)step {
    return [self initWithMaximumValue:maximumValue
                         minimumValue:minimumValue
                         defaultValue:defaultValue
                                 step:step
                             vertical:NO
              maximumValueDescription:nil
              minimumValueDescription:nil];
}

- (NSNumber *)minimumNumber {
    return @(_minimum);
}
- (NSNumber *)maximumNumber {
    return @(_maximum);
}
- (NSNumber *)defaultAnswer {
    if ( _defaultValue > _maximum || _defaultValue < _minimum) {
        return nil;
    }
    
    NSInteger integer = round( (double)( _defaultValue - _minimum ) / (double)_step ) * _step + _minimum;
    
    return @(integer);
}
- (NSString *)localizedStringForNumber:(NSNumber *)number {
    return [self.numberFormatter stringFromNumber:number];
}

- (NSArray<ORK1TextChoice *> *)textChoices {
    return nil;
}

- (NSNumberFormatter *)numberFormatter {
    if (!_numberFormatter) {
        _numberFormatter = [[NSNumberFormatter alloc] init];
        _numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        _numberFormatter.locale = [NSLocale autoupdatingCurrentLocale];
        _numberFormatter.maximumFractionDigits = 0;
    }
    return _numberFormatter;
}

- (NSInteger)numberOfSteps {
    return (_maximum - _minimum) / _step;
}

- (NSNumber *)normalizedValueForNumber:(NSNumber *)number {
    return @(number.integerValue);
}

- (void)validateParameters {
    [super validateParameters];
    
    const NSInteger ORK1ScaleAnswerFormatMinimumStepSize = 1;
    const NSInteger ORK1ScaleAnswerFormatMinimumStepCount = 1;
    const NSInteger ORK1ScaleAnswerFormatMaximumStepCount = 13;
    
    const NSInteger ORK1ScaleAnswerFormatValueLowerbound = -10000;
    const NSInteger ORK1ScaleAnswerFormatValueUpperbound = 10000;
    
    if (_maximum < _minimum) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Expect maximumValue larger than minimumValue"] userInfo:nil];
    }
    
    if (_step < ORK1ScaleAnswerFormatMinimumStepSize) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Expect step value not less than than %@.", @(ORK1ScaleAnswerFormatMinimumStepSize)]
                                     userInfo:nil];
    }
    
    NSInteger mod = (_maximum - _minimum) % _step;
    if (mod != 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Expect the difference between maximumValue and minimumValue is divisible by step value"] userInfo:nil];
    }
    
    NSInteger steps = (_maximum - _minimum) / _step;
    if (steps < ORK1ScaleAnswerFormatMinimumStepCount || steps > ORK1ScaleAnswerFormatMaximumStepCount) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Expect the total number of steps between minimumValue and maximumValue more than %@ and no more than %@.", @(ORK1ScaleAnswerFormatMinimumStepCount), @(ORK1ScaleAnswerFormatMaximumStepCount)]
                                     userInfo:nil];
    }
    
    if (_minimum < ORK1ScaleAnswerFormatValueLowerbound) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"minimumValue should not less than %@", @(ORK1ScaleAnswerFormatValueLowerbound)]
                                     userInfo:nil];
    }
    
    if (_maximum > ORK1ScaleAnswerFormatValueUpperbound) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"maximumValue should not more than %@", @(ORK1ScaleAnswerFormatValueUpperbound)]
                                     userInfo:nil];
    }
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_INTEGER(aDecoder, maximum);
        ORK1_DECODE_INTEGER(aDecoder, minimum);
        ORK1_DECODE_INTEGER(aDecoder, step);
        ORK1_DECODE_INTEGER(aDecoder, defaultValue);
        ORK1_DECODE_BOOL(aDecoder, vertical);
        ORK1_DECODE_OBJ(aDecoder, maximumValueDescription);
        ORK1_DECODE_OBJ(aDecoder, minimumValueDescription);
        ORK1_DECODE_IMAGE(aDecoder, maximumImage);
        ORK1_DECODE_IMAGE(aDecoder, minimumImage);
        ORK1_DECODE_OBJ_ARRAY(aDecoder, gradientColors, UIColor);
        ORK1_DECODE_OBJ_ARRAY(aDecoder, gradientLocations, NSNumber);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_INTEGER(aCoder, maximum);
    ORK1_ENCODE_INTEGER(aCoder, minimum);
    ORK1_ENCODE_INTEGER(aCoder, step);
    ORK1_ENCODE_INTEGER(aCoder, defaultValue);
    ORK1_ENCODE_BOOL(aCoder, vertical);
    ORK1_ENCODE_OBJ(aCoder, maximumValueDescription);
    ORK1_ENCODE_OBJ(aCoder, minimumValueDescription);
    ORK1_ENCODE_IMAGE(aCoder, maximumImage);
    ORK1_ENCODE_IMAGE(aCoder, minimumImage);
    ORK1_ENCODE_OBJ(aCoder, gradientColors);
    ORK1_ENCODE_OBJ(aCoder, gradientLocations);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            (_maximum == castObject.maximum) &&
            (_minimum == castObject.minimum) &&
            (_step == castObject.step) &&
            (_defaultValue == castObject.defaultValue) &&
            ORK1EqualObjects(self.maximumValueDescription, castObject.maximumValueDescription) &&
            ORK1EqualObjects(self.minimumValueDescription, castObject.minimumValueDescription) &&
            ORK1EqualObjects(self.maximumImage, castObject.maximumImage) &&
            ORK1EqualObjects(self.minimumImage, castObject.minimumImage) &&
            ORK1EqualObjects(self.gradientColors, castObject.gradientColors) &&
            ORK1EqualObjects(self.gradientLocations, castObject.gradientLocations));
}

- (ORK1QuestionType)questionType {
    return ORK1QuestionTypeScale;
}

- (NSString *)stringForAnswer:(id)answer {
    return [self localizedStringForNumber:answer];
}

@end


#pragma mark - ORK1ContinuousScaleAnswerFormat

@implementation ORK1ContinuousScaleAnswerFormat {
    NSNumberFormatter *_numberFormatter;
}

- (Class)questionResultClass {
    return [ORK1ScaleQuestionResult class];
}

+ (instancetype)new {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)initWithMaximumValue:(double)maximumValue
                        minimumValue:(double)minimumValue
                        defaultValue:(double)defaultValue
               maximumFractionDigits:(NSInteger)maximumFractionDigits
                            vertical:(BOOL)vertical
             maximumValueDescription:(nullable NSString *)maximumValueDescription
             minimumValueDescription:(nullable NSString *)minimumValueDescription {
    self = [super init];
    if (self) {
        _minimum = minimumValue;
        _maximum = maximumValue;
        _defaultValue = defaultValue;
        _maximumFractionDigits = maximumFractionDigits;
        _vertical = vertical;
        _maximumValueDescription = maximumValueDescription;
        _minimumValueDescription = minimumValueDescription;
        
        [self validateParameters];
    }
    return self;
}

- (instancetype)initWithMaximumValue:(double)maximumValue
                        minimumValue:(double)minimumValue
                        defaultValue:(double)defaultValue
               maximumFractionDigits:(NSInteger)maximumFractionDigits
                            vertical:(BOOL)vertical {
    return [self initWithMaximumValue:maximumValue
                         minimumValue:minimumValue
                         defaultValue:defaultValue
                maximumFractionDigits:maximumFractionDigits
                             vertical:vertical
              maximumValueDescription:nil
              minimumValueDescription:nil];
}

- (instancetype)initWithMaximumValue:(double)maximumValue
                        minimumValue:(double)minimumValue
                        defaultValue:(double)defaultValue
               maximumFractionDigits:(NSInteger)maximumFractionDigits {
    return [self initWithMaximumValue:maximumValue
                         minimumValue:minimumValue
                         defaultValue:defaultValue
                maximumFractionDigits:maximumFractionDigits
                             vertical:NO
              maximumValueDescription:nil
              minimumValueDescription:nil];
}

- (NSNumber *)minimumNumber {
    return @(_minimum);
}
- (NSNumber *)maximumNumber {
    return @(_maximum);
}
- (NSNumber *)defaultAnswer {
    if ( _defaultValue > _maximum || _defaultValue < _minimum) {
        return nil;
    }
    return @(_defaultValue);
}
- (NSString *)localizedStringForNumber:(NSNumber *)number {
    return [self.numberFormatter stringFromNumber:number];
}

- (NSArray<ORK1TextChoice *> *)textChoices {
    return nil;
}

- (NSNumberFormatter *)numberFormatter {
    if (!_numberFormatter) {
        _numberFormatter = [[NSNumberFormatter alloc] init];
        _numberFormatter.numberStyle = ORK1NumberFormattingStyleConvert(_numberStyle);
        _numberFormatter.maximumFractionDigits = _maximumFractionDigits;
    }
    return _numberFormatter;
}

- (NSInteger)numberOfSteps {
    return 0;
}

- (NSNumber *)normalizedValueForNumber:(NSNumber *)number {
    return number;
}

- (void)validateParameters {
    [super validateParameters];
    
    const double ORK1ScaleAnswerFormatValueLowerbound = -10000;
    const double ORK1ScaleAnswerFormatValueUpperbound = 10000;
    
    // Just clamp maximumFractionDigits to be 0-4. This is all aimed at keeping the maximum
    // number of digits down to 6 or less.
    _maximumFractionDigits = MAX(_maximumFractionDigits, 0);
    _maximumFractionDigits = MIN(_maximumFractionDigits, 4);
    
    double effectiveUpperbound = ORK1ScaleAnswerFormatValueUpperbound * pow(0.1, _maximumFractionDigits);
    double effectiveLowerbound = ORK1ScaleAnswerFormatValueLowerbound * pow(0.1, _maximumFractionDigits);
    
    if (_maximum <= _minimum) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Expect maximumValue larger than minimumValue"] userInfo:nil];
    }
    
    if (_minimum < effectiveLowerbound) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"minimumValue should not less than %@ with %@ fractional digits", @(effectiveLowerbound), @(_maximumFractionDigits)]
                                     userInfo:nil];
    }
    
    if (_maximum > effectiveUpperbound) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"maximumValue should not more than %@ with %@ fractional digits", @(effectiveUpperbound), @(_maximumFractionDigits)]
                                     userInfo:nil];
    }
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_DOUBLE(aDecoder, maximum);
        ORK1_DECODE_DOUBLE(aDecoder, minimum);
        ORK1_DECODE_DOUBLE(aDecoder, defaultValue);
        ORK1_DECODE_INTEGER(aDecoder, maximumFractionDigits);
        ORK1_DECODE_BOOL(aDecoder, vertical);
        ORK1_DECODE_ENUM(aDecoder, numberStyle);
        ORK1_DECODE_OBJ(aDecoder, maximumValueDescription);
        ORK1_DECODE_OBJ(aDecoder, minimumValueDescription);
        ORK1_DECODE_IMAGE(aDecoder, maximumImage);
        ORK1_DECODE_IMAGE(aDecoder, minimumImage);
        ORK1_DECODE_OBJ_ARRAY(aDecoder, gradientColors, UIColor);
        ORK1_DECODE_OBJ_ARRAY(aDecoder, gradientLocations, NSNumber);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_DOUBLE(aCoder, maximum);
    ORK1_ENCODE_DOUBLE(aCoder, minimum);
    ORK1_ENCODE_DOUBLE(aCoder, defaultValue);
    ORK1_ENCODE_INTEGER(aCoder, maximumFractionDigits);
    ORK1_ENCODE_BOOL(aCoder, vertical);
    ORK1_ENCODE_ENUM(aCoder, numberStyle);
    ORK1_ENCODE_OBJ(aCoder, maximumValueDescription);
    ORK1_ENCODE_OBJ(aCoder, minimumValueDescription);
    ORK1_ENCODE_IMAGE(aCoder, maximumImage);
    ORK1_ENCODE_IMAGE(aCoder, minimumImage);
    ORK1_ENCODE_OBJ(aCoder, gradientColors);
    ORK1_ENCODE_OBJ(aCoder, gradientLocations);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            (_maximum == castObject.maximum) &&
            (_minimum == castObject.minimum) &&
            (_defaultValue == castObject.defaultValue) &&
            (_maximumFractionDigits == castObject.maximumFractionDigits) &&
            (_numberStyle == castObject.numberStyle) &&
            ORK1EqualObjects(self.maximumValueDescription, castObject.maximumValueDescription) &&
            ORK1EqualObjects(self.minimumValueDescription, castObject.minimumValueDescription) &&
            ORK1EqualObjects(self.maximumImage, castObject.maximumImage) &&
            ORK1EqualObjects(self.minimumImage, castObject.minimumImage) &&
            ORK1EqualObjects(self.gradientColors, castObject.gradientColors) &&
            ORK1EqualObjects(self.gradientLocations, castObject.gradientLocations));
}

- (ORK1QuestionType)questionType {
    return ORK1QuestionTypeScale;
}

- (NSString *)stringForAnswer:(id)answer {
    return [self localizedStringForNumber:answer];
}

@end


#pragma mark - ORK1TextScaleAnswerFormat

@interface ORK1TextScaleAnswerFormat () {
    
    ORK1ChoiceAnswerFormatHelper *_helper;
}

@end


@implementation ORK1TextScaleAnswerFormat {
    NSNumberFormatter *_numberFormatter;
}

- (Class)questionResultClass {
    return [ORK1ChoiceQuestionResult class];
}

+ (instancetype)new {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)initWithTextChoices:(NSArray<ORK1TextChoice *> *)textChoices
                       defaultIndex:(NSInteger)defaultIndex
                           vertical:(BOOL)vertical {
    self = [super init];
    if (self) {
        _textChoices = [textChoices copy];
        _defaultIndex = defaultIndex;
        _vertical = vertical;
        _helper = [[ORK1ChoiceAnswerFormatHelper alloc] initWithAnswerFormat:self];
        
        [self validateParameters];
    }
    return self;
}

- (instancetype)initWithTextChoices:(NSArray<ORK1TextChoice *> *)textChoices
                       defaultIndex:(NSInteger)defaultIndex{
    return [self initWithTextChoices:textChoices
                        defaultIndex:defaultIndex
                            vertical:NO];
}

- (NSNumber *)minimumNumber {
    return @(1);
}
- (NSNumber *)maximumNumber {
    return @(_textChoices.count);
}
- (id<NSObject, NSCopying, NSCoding>)defaultAnswer {
    if (_defaultIndex < 0 || _defaultIndex >= _textChoices.count) {
        return nil;
    }
    id<NSCopying, NSCoding, NSObject> value = [self textChoiceAtIndex:_defaultIndex].value;
    return value ? @[value] : nil;
}
- (NSString *)localizedStringForNumber:(NSNumber *)number {
    return [self.numberFormatter stringFromNumber:number];
}
- (NSString *)minimumValueDescription {
    return _textChoices.firstObject.text;
}
- (NSString *)maximumValueDescription {
    return _textChoices.lastObject.text;
}
- (UIImage *)minimumImage {
    return nil;
}
- (UIImage *)maximumImage {
    return nil;
}

- (NSNumberFormatter *)numberFormatter {
    if (!_numberFormatter) {
        _numberFormatter = [[NSNumberFormatter alloc] init];
        _numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        _numberFormatter.locale = [NSLocale autoupdatingCurrentLocale];
        _numberFormatter.maximumFractionDigits = 0;
    }
    return _numberFormatter;
}

- (NSInteger)numberOfSteps {
    return _textChoices.count - 1;
}

- (NSNumber *)normalizedValueForNumber:(NSNumber *)number {
    return @([number integerValue]);
}

- (ORK1TextChoice *)textChoiceAtIndex:(NSUInteger)index {
    
    if (index >= _textChoices.count) {
        return nil;
    }
    return _textChoices[index];
}

- (ORK1TextChoice *)textChoiceForValue:(id<NSCopying, NSCoding, NSObject>)value {
    __block ORK1TextChoice *choice = nil;
    
    [_textChoices enumerateObjectsUsingBlock:^(ORK1TextChoice * _Nonnull textChoice, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([textChoice.value isEqual:value]) {
            choice = textChoice;
            *stop = YES;
        }
    }];
    
    return choice;
}

- (NSUInteger)textChoiceIndexForValue:(id<NSCopying, NSCoding, NSObject>)value {
    ORK1TextChoice *choice = [self textChoiceForValue:value];
    return choice ? [_textChoices indexOfObject:choice] : NSNotFound;
}

- (void)validateParameters {
    [super validateParameters];
    
    if (_textChoices.count < 2) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Must have a minimum of 2 text choices." userInfo:nil];
    } else if (_textChoices.count > 8) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Cannot have more than 8 text choices." userInfo:nil];
    }
    
    ORK1ValidateArrayForObjectsOfClass(_textChoices, [ORK1TextChoice class], @"Text choices must be of class ORK1TextChoice.");
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_ARRAY(aDecoder, textChoices, ORK1TextChoice);
        ORK1_DECODE_OBJ_ARRAY(aDecoder, gradientColors, UIColor);
        ORK1_DECODE_OBJ_ARRAY(aDecoder, gradientLocations, NSNumber);
        ORK1_DECODE_INTEGER(aDecoder, defaultIndex);
        ORK1_DECODE_BOOL(aDecoder, vertical);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, textChoices);
    ORK1_ENCODE_OBJ(aCoder, gradientColors);
    ORK1_ENCODE_OBJ(aCoder, gradientLocations);
    ORK1_ENCODE_INTEGER(aCoder, defaultIndex);
    ORK1_ENCODE_BOOL(aCoder, vertical);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORK1EqualObjects(self.textChoices, castObject.textChoices) &&
            (_defaultIndex == castObject.defaultIndex) &&
            (_vertical == castObject.vertical) &&
            ORK1EqualObjects(self.gradientColors, castObject.gradientColors) &&
            ORK1EqualObjects(self.gradientLocations, castObject.gradientLocations));
}

- (ORK1QuestionType)questionType {
    return ORK1QuestionTypeScale;
}

- (NSString *)stringForAnswer:(id)answer {
    return [_helper stringForChoiceAnswer:answer];
}

@end


#pragma mark - ORK1TextAnswerFormat

@implementation ORK1TextAnswerFormat

- (Class)questionResultClass {
    return [ORK1TextQuestionResult class];
}

- (void)commonInit {
    _autocapitalizationType = UITextAutocapitalizationTypeSentences;
    _autocorrectionType = UITextAutocorrectionTypeDefault;
    _spellCheckingType = UITextSpellCheckingTypeDefault;
    _keyboardType = UIKeyboardTypeDefault;
    _multipleLines = YES;
}

- (instancetype)initWithMaximumLength:(NSInteger)maximumLength {
    self = [super init];
    if (self) {
        _maximumLength = maximumLength;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithValidationRegularExpression:(NSRegularExpression *)validationRegularExpression
                                     invalidMessage:(NSString *)invalidMessage {
    self = [super init];
    if (self) {
        _validationRegularExpression = [validationRegularExpression copy];
        _invalidMessage = [invalidMessage copy];
        _maximumLength = 0;
        [self commonInit];
    }
    return self;
}

- (instancetype)init {
    self = [self initWithMaximumLength:0];
    return self;
}

- (ORK1QuestionType)questionType {
    return ORK1QuestionTypeText;
}

- (void)validateParameters {
    [super validateParameters];
    
    if ( (!self.validationRegularExpression && self.invalidMessage) ||
        (self.validationRegularExpression && !self.invalidMessage) ) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"Both regular expression and invalid message properties must be set."
                                     userInfo:nil];
    }
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1TextAnswerFormat *answerFormat = [[[self class] allocWithZone:zone] init];
    answerFormat->_maximumLength = _maximumLength;
    answerFormat->_validationRegularExpression = [_validationRegularExpression copy];
    answerFormat->_invalidMessage = [_invalidMessage copy];
    answerFormat->_autocapitalizationType = _autocapitalizationType;
    answerFormat->_autocorrectionType = _autocorrectionType;
    answerFormat->_spellCheckingType = _spellCheckingType;
    answerFormat->_keyboardType = _keyboardType;
    answerFormat->_multipleLines = _multipleLines;
    answerFormat->_secureTextEntry = _secureTextEntry;
    return answerFormat;
}

- (BOOL)isAnswerValid:(id)answer {
    BOOL isValid = NO;
    if ([answer isKindOfClass:[NSString class]]) {
        isValid = [self isAnswerValidWithString:(NSString *)answer];
    }
    return isValid;
}

- (BOOL)isAnswerValidWithString:(NSString *)text {
    BOOL isValid = YES;
    if (text && text.length > 0) {
        isValid = ([self isTextLengthValidWithString:text] && [self isTextRegularExpressionValidWithString:text]);
    }
    return isValid;
}

- (BOOL)isTextLengthValidWithString:(NSString *)text {
    return (_maximumLength == 0 || text.length <= _maximumLength);
}

- (BOOL)isTextRegularExpressionValidWithString:(NSString *)text {
    BOOL isValid = YES;
    if (self.validationRegularExpression) {
        NSUInteger regularExpressionMatches = [_validationRegularExpression numberOfMatchesInString:text
                                                                                            options:(NSMatchingOptions)0
                                                                                              range:NSMakeRange(0, [text length])];
        isValid = (regularExpressionMatches != 0);
    }
    return isValid;
}

- (NSString *)localizedInvalidValueStringWithAnswerString:(NSString *)text {
    NSString *string = @"";
    if (![self isTextLengthValidWithString:text]) {
        string = [NSString localizedStringWithFormat:ORK1LocalizedString(@"TEXT_ANSWER_EXCEEDING_MAX_LENGTH_ALERT_MESSAGE", nil), ORK1LocalizedStringFromNumber(@(_maximumLength))];
    }
    if (![self isTextRegularExpressionValidWithString:text]) {
        if (string.length > 0) {
            string = [string stringByAppendingString:@"\n"];
        }
        string = [string stringByAppendingString:[NSString localizedStringWithFormat:ORK1LocalizedString(_invalidMessage, nil), text]];
    }
    return string;
}


- (ORK1AnswerFormat *)confirmationAnswerFormatWithOriginalItemIdentifier:(NSString *)originalItemIdentifier
                                                           errorMessage:(NSString *)errorMessage {
    
    NSAssert(!self.multipleLines, @"Confirmation Answer Format is not currently defined for ORK1TextAnswerFormat with multiple lines.");
    
    ORK1TextAnswerFormat *answerFormat = [[ORK1ConfirmTextAnswerFormat alloc] initWithOriginalItemIdentifier:originalItemIdentifier errorMessage:errorMessage];
    
    // Copy from ORK1TextAnswerFormat being confirmed
    answerFormat->_maximumLength = _maximumLength;
    answerFormat->_keyboardType = _keyboardType;
    answerFormat->_multipleLines = _multipleLines;
    answerFormat->_secureTextEntry = _secureTextEntry;
    answerFormat->_autocapitalizationType = _autocapitalizationType;
    
    // Always set to no autocorrection or spell checking
    answerFormat->_autocorrectionType = UITextAutocorrectionTypeNo;
    answerFormat->_spellCheckingType = UITextSpellCheckingTypeNo;
    
    return answerFormat;
}

#pragma mark NSSecureCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _multipleLines = YES;
        ORK1_DECODE_INTEGER(aDecoder, maximumLength);
        ORK1_DECODE_OBJ_CLASS(aDecoder, validationRegularExpression, NSRegularExpression);
        ORK1_DECODE_OBJ_CLASS(aDecoder, invalidMessage, NSString);
        ORK1_DECODE_ENUM(aDecoder, autocapitalizationType);
        ORK1_DECODE_ENUM(aDecoder, autocorrectionType);
        ORK1_DECODE_ENUM(aDecoder, spellCheckingType);
        ORK1_DECODE_ENUM(aDecoder, keyboardType);
        ORK1_DECODE_BOOL(aDecoder, multipleLines);
        ORK1_DECODE_BOOL(aDecoder, secureTextEntry);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_INTEGER(aCoder, maximumLength);
    ORK1_ENCODE_OBJ(aCoder, validationRegularExpression);
    ORK1_ENCODE_OBJ(aCoder, invalidMessage);
    ORK1_ENCODE_ENUM(aCoder, autocapitalizationType);
    ORK1_ENCODE_ENUM(aCoder, autocorrectionType);
    ORK1_ENCODE_ENUM(aCoder, spellCheckingType);
    ORK1_ENCODE_ENUM(aCoder, keyboardType);
    ORK1_ENCODE_BOOL(aCoder, multipleLines);
    ORK1_ENCODE_BOOL(aCoder, secureTextEntry);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            (self.maximumLength == castObject.maximumLength &&
             ORK1EqualObjects(self.validationRegularExpression, castObject.validationRegularExpression) &&
             ORK1EqualObjects(self.invalidMessage, castObject.invalidMessage) &&
             self.autocapitalizationType == castObject.autocapitalizationType &&
             self.autocorrectionType == castObject.autocorrectionType &&
             self.spellCheckingType == castObject.spellCheckingType &&
             self.keyboardType == castObject.keyboardType &&
             self.multipleLines == castObject.multipleLines) &&
            self.secureTextEntry == castObject.secureTextEntry);
}

static NSString *const kSecureTextEntryEscapeString = @"*";

- (NSString *)stringForAnswer:(id)answer {
    NSString *answerString = nil;
    if ([self isAnswerValid:answer]) {
        answerString = _secureTextEntry ? [@"" stringByPaddingToLength:((NSString *)answer).length withString:kSecureTextEntryEscapeString startingAtIndex:0] : answer;
    }
    return answerString;
}

@end


#pragma mark - ORK1EmailAnswerFormat

@implementation ORK1EmailAnswerFormat {
    ORK1TextAnswerFormat *_impliedAnswerFormat;
}

- (ORK1QuestionType)questionType {
    return ORK1QuestionTypeText;
}

- (Class)questionResultClass {
    return [ORK1TextQuestionResult class];
}

- (ORK1AnswerFormat *)impliedAnswerFormat {
    if (!_impliedAnswerFormat) {
        NSRegularExpression *validationRegularExpression =
        [NSRegularExpression regularExpressionWithPattern:EmailValidationRegularExpressionPattern
                                                  options:(NSRegularExpressionOptions)0
                                                    error:nil];
        NSString *invalidMessage = ORK1LocalizedString(@"INVALID_EMAIL_ALERT_MESSAGE", nil);
        _impliedAnswerFormat = [ORK1TextAnswerFormat textAnswerFormatWithValidationRegularExpression:validationRegularExpression
                                                                                     invalidMessage:invalidMessage];
        _impliedAnswerFormat.keyboardType = UIKeyboardTypeEmailAddress;
        _impliedAnswerFormat.multipleLines = NO;
        _impliedAnswerFormat.spellCheckingType = UITextSpellCheckingTypeNo;
        _impliedAnswerFormat.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _impliedAnswerFormat.autocorrectionType = UITextAutocorrectionTypeNo;
    }
    return _impliedAnswerFormat;
}

- (NSString *)stringForAnswer:(id)answer {
    return [self.impliedAnswerFormat stringForAnswer:answer];
}

@end


#pragma mark - ORK1ConfirmTextAnswerFormat

@implementation ORK1ConfirmTextAnswerFormat

+ (instancetype)new {
    ORK1ThrowMethodUnavailableException();
}

// Don't throw on -init nor -initWithMaximumLength: because they're internally used by -copyWithZone:

- (instancetype)initWithValidationRegularExpression:(NSRegularExpression *)validationRegularExpression
                                     invalidMessage:(NSString *)invalidMessage {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)initWithOriginalItemIdentifier:(NSString *)originalItemIdentifier
                                  errorMessage:(NSString *)errorMessage {
    
    NSParameterAssert(originalItemIdentifier);
    NSParameterAssert(errorMessage);
    
    self = [super init];
    if (self) {
        _originalItemIdentifier = [originalItemIdentifier copy];
        _errorMessage = [errorMessage copy];
    }
    return self;
}

- (BOOL)isAnswerValid:(id)answer {
    BOOL isValid = NO;
    if ([answer isKindOfClass:[NSString class]]) {
        NSString *stringAnswer = (NSString *)answer;
        isValid = (stringAnswer.length > 0);
    }
    return isValid;
}

- (NSString *)localizedInvalidValueStringWithAnswerString:(NSString *)text {
    return self.errorMessage;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1ConfirmTextAnswerFormat *answerFormat = [super copyWithZone:zone];
    answerFormat->_originalItemIdentifier = [_originalItemIdentifier copy];
    answerFormat->_errorMessage = [_errorMessage copy];
    return answerFormat;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, originalItemIdentifier, NSString);
        ORK1_DECODE_OBJ_CLASS(aDecoder, errorMessage, NSString);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, originalItemIdentifier);
    ORK1_ENCODE_OBJ(aCoder, errorMessage);
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORK1EqualObjects(self.originalItemIdentifier, castObject.originalItemIdentifier) &&
            ORK1EqualObjects(self.errorMessage, castObject.errorMessage));
}

@end


#pragma mark - ORK1TimeIntervalAnswerFormat

@implementation ORK1TimeIntervalAnswerFormat

- (Class)questionResultClass {
    return [ORK1TimeIntervalQuestionResult class];
}

- (instancetype)init {
    self = [self initWithDefaultInterval:0 step:1];
    return self;
}

- (instancetype)initWithDefaultInterval:(NSTimeInterval)defaultInterval step:(NSInteger)step {
    self = [super init];
    if (self) {
        _defaultInterval = defaultInterval;
        _step = step;
        [self validateParameters];
    }
    return self;
}

- (ORK1QuestionType)questionType {
    return ORK1QuestionTypeTimeInterval;
}

- (NSTimeInterval)pickerDefaultDuration {
    
    NSTimeInterval value = MAX([self defaultInterval], 0);
    
    // imitate UIDatePicker's behavior
    NSTimeInterval stepInSeconds = _step * 60;
    value  = floor(value/stepInSeconds)*stepInSeconds;
    
    return value;
}

- (void)validateParameters {
    [super validateParameters];
    
    const NSInteger ORK1TimeIntervalAnswerFormatStepLowerBound = 1;
    const NSInteger ORK1TimeIntervalAnswerFormatStepUpperBound = 30;
    
    if (_step < ORK1TimeIntervalAnswerFormatStepLowerBound || _step > ORK1TimeIntervalAnswerFormatStepUpperBound) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Step should be between %@ and %@.", @(ORK1TimeIntervalAnswerFormatStepLowerBound), @(ORK1TimeIntervalAnswerFormatStepUpperBound)] userInfo:nil];
    }
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_DOUBLE(aDecoder, defaultInterval);
        ORK1_DECODE_DOUBLE(aDecoder, step);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_DOUBLE(aCoder, defaultInterval);
    ORK1_ENCODE_DOUBLE(aCoder, step);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            (_defaultInterval == castObject.defaultInterval) &&
            (_step == castObject.step));
}

- (NSString *)stringForAnswer:(id)answer {
    return [ORK1TimeIntervalLabelFormatter() stringFromTimeInterval:((NSNumber *)answer).floatValue];
}

@end


#pragma mark - ORK1HeightAnswerFormat

@implementation ORK1HeightAnswerFormat

- (Class)questionResultClass {
    return [ORK1NumericQuestionResult class];
}

- (NSString *)canonicalUnitString {
    return @"cm";
}

- (ORK1NumericQuestionResult *)resultWithIdentifier:(NSString *)identifier answer:(NSNumber *)answer {
    ORK1NumericQuestionResult *questionResult = (ORK1NumericQuestionResult *)[super resultWithIdentifier:identifier answer:answer];
    // Use canonical unit because we expect results to be consistent regardless of the user locale
    questionResult.unit = [self canonicalUnitString];
    return questionResult;
}

- (instancetype)init {
    self = [self initWithMeasurementSystem:ORK1MeasurementSystemLocal];
    return self;
}

- (instancetype)initWithMeasurementSystem:(ORK1MeasurementSystem)measurementSystem {
    self = [super init];
    if (self) {
        _measurementSystem = measurementSystem;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            (self.measurementSystem == castObject.measurementSystem));
}

- (NSUInteger)hash {
    return super.hash ^ _measurementSystem;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_ENUM(aDecoder, measurementSystem);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_ENUM(aCoder, measurementSystem);
}

- (ORK1QuestionType)questionType {
    return ORK1QuestionTypeHeight;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)useMetricSystem {
    return _measurementSystem == ORK1MeasurementSystemMetric
    || (_measurementSystem == ORK1MeasurementSystemLocal && ((NSNumber *)[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem]).boolValue);
}

- (NSString *)stringForAnswer:(id)answer {
    NSString *answerString = nil;
    
    if (!ORK1IsAnswerEmpty(answer)) {
        NSNumberFormatter *formatter = ORK1DecimalNumberFormatter();
        if (self.useMetricSystem) {
            answerString = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:answer], ORK1LocalizedString(@"MEASURING_UNIT_CM", nil)];
        } else {
            double feet, inches;
            ORK1CentimetersToFeetAndInches(((NSNumber *)answer).doubleValue, &feet, &inches);
            NSString *feetString = [formatter stringFromNumber:@(feet)];
            NSString *inchesString = [formatter stringFromNumber:@(inches)];
            answerString = [NSString stringWithFormat:@"%@ %@, %@ %@",
                            feetString, ORK1LocalizedString(@"MEASURING_UNIT_FT", nil), inchesString, ORK1LocalizedString(@"MEASURING_UNIT_IN", nil)];
        }
    }
    return answerString;
}

@end


#pragma mark - ORK1WeightAnswerFormat

@implementation ORK1WeightAnswerFormat

- (Class)questionResultClass {
    return [ORK1NumericQuestionResult class];
}

- (NSString *)canonicalUnitString {
    return @"kg";
}

- (ORK1NumericQuestionResult *)resultWithIdentifier:(NSString *)identifier answer:(NSNumber *)answer {
    ORK1NumericQuestionResult *questionResult = (ORK1NumericQuestionResult *)[super resultWithIdentifier:identifier answer:answer];
    // Use canonical unit because we expect results to be consistent regardless of the user locale
    questionResult.unit = [self canonicalUnitString];
    return questionResult;
}

- (instancetype)init {
    return [self initWithMeasurementSystem:ORK1MeasurementSystemLocal
                          numericPrecision:ORK1NumericPrecisionDefault
                              minimumValue:ORK1DoubleDefaultValue
                              maximumValue:ORK1DoubleDefaultValue
                              defaultValue:ORK1DoubleDefaultValue];
}

- (instancetype)initWithMeasurementSystem:(ORK1MeasurementSystem)measurementSystem {
    return [self initWithMeasurementSystem:measurementSystem
                          numericPrecision:ORK1NumericPrecisionDefault
                              minimumValue:ORK1DoubleDefaultValue
                              maximumValue:ORK1DoubleDefaultValue
                              defaultValue:ORK1DoubleDefaultValue];
}

- (instancetype)initWithMeasurementSystem:(ORK1MeasurementSystem)measurementSystem
                         numericPrecision:(ORK1NumericPrecision)numericPrecision {
    return [self initWithMeasurementSystem:measurementSystem
                          numericPrecision:numericPrecision
                              minimumValue:ORK1DoubleDefaultValue
                              maximumValue:ORK1DoubleDefaultValue
                              defaultValue:ORK1DoubleDefaultValue];
}

- (instancetype)initWithMeasurementSystem:(ORK1MeasurementSystem)measurementSystem
                         numericPrecision:(ORK1NumericPrecision)numericPrecision
                             minimumValue:(double)minimumValue
                             maximumValue:(double)maximumValue
                             defaultValue:(double)defaultValue {
    if ((defaultValue != ORK1DoubleDefaultValue) && ((defaultValue < minimumValue) || (defaultValue > maximumValue))) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"defaultValue must be between minimumValue and maximumValue."
                                     userInfo:nil];
    }

    self = [super init];
    if (self) {
        _measurementSystem = measurementSystem;
        _numericPrecision = numericPrecision;
        _minimumValue = minimumValue;
        _maximumValue = maximumValue;
        _defaultValue = defaultValue;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            (self.measurementSystem == castObject.measurementSystem) &&
            (self.numericPrecision == castObject.numericPrecision) &&
            (self.minimumValue == castObject.minimumValue) &&
            (self.maximumValue == castObject.maximumValue) &&
            (self.defaultValue == castObject.defaultValue));
}

- (NSUInteger)hash {
    // Ignore minimumValue, maximumValue and defaultValue as they're unimportant
    return super.hash ^ _measurementSystem ^ _numericPrecision;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_ENUM(aDecoder, measurementSystem);
        ORK1_DECODE_ENUM(aDecoder, numericPrecision);
        ORK1_DECODE_DOUBLE(aDecoder, minimumValue);
        ORK1_DECODE_DOUBLE(aDecoder, maximumValue);
        ORK1_DECODE_DOUBLE(aDecoder, defaultValue);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_ENUM(aCoder, measurementSystem);
    ORK1_ENCODE_ENUM(aCoder, numericPrecision);
    ORK1_ENCODE_DOUBLE(aCoder, minimumValue);
    ORK1_ENCODE_DOUBLE(aCoder, maximumValue);
    ORK1_ENCODE_DOUBLE(aCoder, defaultValue);
}

- (ORK1QuestionType)questionType {
    return ORK1QuestionTypeWeight;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)useMetricSystem {
    return _measurementSystem == ORK1MeasurementSystemMetric || (_measurementSystem == ORK1MeasurementSystemLocal && ((NSNumber *)[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem]).boolValue);
}

- (NSString *)stringForAnswer:(id)answer {
    NSString *answerString = nil;
    
    if (!ORK1IsAnswerEmpty(answer)) {
        NSNumberFormatter *formatter = ORK1DecimalNumberFormatter();
        if (self.useMetricSystem) {
            answerString = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:answer], ORK1LocalizedString(@"MEASURING_UNIT_KG", nil)];
        } else {
            if (self.numericPrecision != ORK1NumericPrecisionHigh) {
                double pounds = ORK1KilogramsToPounds(((NSNumber *)answer).doubleValue);
                NSString *poundsString = [formatter stringFromNumber:@(pounds)];
                answerString = [NSString stringWithFormat:@"%@ %@", poundsString, ORK1LocalizedString(@"MEASURING_UNIT_LB", nil)];
            } else {
                double pounds, ounces;
                ORK1KilogramsToPoundsAndOunces(((NSNumber *)answer).doubleValue, &pounds, &ounces);
                NSString *poundsString = [formatter stringFromNumber:@(pounds)];
                NSString *ouncesString = [formatter stringFromNumber:@(ounces)];
                answerString = [NSString stringWithFormat:@"%@ %@, %@ %@", poundsString, ORK1LocalizedString(@"MEASURING_UNIT_LB", nil), ouncesString, ORK1LocalizedString(@"MEASURING_UNIT_OZ", nil)];
            }
        }
    }
    return answerString;
}

@end


#pragma mark - ORK1LocationAnswerFormat

@implementation ORK1LocationAnswerFormat

- (instancetype)init {
    self = [super init];
    if (self) {
        _useCurrentLocation = YES;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_BOOL(aDecoder, useCurrentLocation);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_BOOL(aCoder, useCurrentLocation);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (ORK1QuestionType)questionType {
    return ORK1QuestionTypeLocation;
}

- (Class)questionResultClass {
    return [ORK1LocationQuestionResult class];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1LocationAnswerFormat *locationAnswerFormat = [[[self class] allocWithZone:zone] init];
    locationAnswerFormat->_useCurrentLocation = _useCurrentLocation;
    return locationAnswerFormat;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            _useCurrentLocation == castObject.useCurrentLocation);
}

static NSString *const formattedAddressLinesKey = @"FormattedAddressLines";

- (NSString *)stringForAnswer:(id)answer {
    NSString *answerString = nil;
    if ([answer isKindOfClass:[ORK1Location class]]) {
        ORK1Location *location = answer;
        // access address dictionary directly since 'ABCreateStringWithAddressDictionary:' is deprecated in iOS9
        NSArray<NSString *> *addressLines = [location.addressDictionary valueForKey:formattedAddressLinesKey];
        answerString = addressLines ? [addressLines componentsJoinedByString:@"\n"] :
        MKStringFromMapPoint(MKMapPointForCoordinate(location.coordinate));
    }
    return answerString;
}

@end
