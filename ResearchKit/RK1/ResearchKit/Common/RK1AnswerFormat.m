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


#import "RK1AnswerFormat.h"
#import "RK1AnswerFormat_Internal.h"

#import "RK1ChoiceAnswerFormatHelper.h"
#import "RK1HealthAnswerFormat.h"
#import "RK1Result_Private.h"

#import "RK1Helpers_Internal.h"

@import HealthKit;
@import MapKit;


NSString *const EmailValidationRegularExpressionPattern = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}";

id RK1NullAnswerValue() {
    return [NSNull null];
}

BOOL RK1IsAnswerEmpty(id answer) {
    return  (answer == nil) ||
    (answer == RK1NullAnswerValue()) ||
    ([answer isKindOfClass:[NSArray class]] && ((NSArray *)answer).count == 0);     // Empty answer of choice or value picker
}

NSString *RK1QuestionTypeString(RK1QuestionType questionType) {
#define SQT_CASE(x) case RK1QuestionType ## x : return @RK1_STRINGIFY(RK1QuestionType ## x);
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

NSNumberFormatterStyle RK1NumberFormattingStyleConvert(RK1NumberFormattingStyle style) {
    return style == RK1NumberFormattingStylePercent ? NSNumberFormatterPercentStyle : NSNumberFormatterDecimalStyle;
}


@implementation RK1AnswerDefaultSource {
    NSMutableDictionary *_unitsTable;
}

@synthesize healthStore=_healthStore;

+ (instancetype)sourceWithHealthStore:(HKHealthStore *)healthStore {
    RK1AnswerDefaultSource *source = [[RK1AnswerDefaultSource alloc] initWithHealthStore:healthStore];
    return source;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)init {
    RK1ThrowMethodUnavailableException();
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
            result = RK1HKBloodTypeString(bloodType.bloodType);
        }
        if (result) {
            result = @[result];
        }
    }
    if ([[characteristicType identifier] isEqualToString:HKCharacteristicTypeIdentifierBiologicalSex]) {
        HKBiologicalSexObject *biologicalSex = [_healthStore biologicalSexWithError:error];
        if (biologicalSex && biologicalSex.biologicalSex != HKBiologicalSexNotSet) {
            result = RK1HKBiologicalSexString(biologicalSex.biologicalSex);
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
    if (RK1_IOS_10_WATCHOS_3_AVAILABLE && [[characteristicType identifier] isEqualToString:HKCharacteristicTypeIdentifierWheelchairUse]) {
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

- (void)fetchDefaultValueForAnswerFormat:(RK1AnswerFormat *)answerFormat handler:(void(^)(id defaultValue, NSError *error))handler {
    HKObjectType *objectType = [answerFormat healthKitObjectType];
    BOOL handled = NO;
    if (objectType) {
        if ([HKHealthStore isHealthDataAvailable]) {
            if ([answerFormat isKindOfClass:[RK1HealthKitCharacteristicTypeAnswerFormat class]]) {
                NSError *error = nil;
                id defaultValue = [self defaultValueForCharacteristicType:(HKCharacteristicType *)objectType error:&error];
                handler(defaultValue, error);
                handled = YES;
            } else if ([answerFormat isKindOfClass:[RK1HealthKitQuantityTypeAnswerFormat class]]) {
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

- (HKUnit *)defaultHealthKitUnitForAnswerFormat:(RK1AnswerFormat *)answerFormat {
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

- (void)updateHealthKitUnitForAnswerFormat:(RK1AnswerFormat *)answerFormat force:(BOOL)force {
    HKUnit *unit = [answerFormat healthKitUserUnit];
    HKUnit *healthKitDefault = [self defaultHealthKitUnitForAnswerFormat:answerFormat];
    if (!RK1EqualObjects(unit,healthKitDefault) && (force || (unit == nil))) {
        [answerFormat setHealthKitUserUnit:healthKitDefault];
    }
}

@end


#pragma mark - RK1AnswerFormat

@implementation RK1AnswerFormat

+ (RK1ScaleAnswerFormat *)scaleAnswerFormatWithMaximumValue:(NSInteger)scaleMaximum
                                               minimumValue:(NSInteger)scaleMinimum
                                               defaultValue:(NSInteger)defaultValue
                                                       step:(NSInteger)step
                                                   vertical:(BOOL)vertical
                                    maximumValueDescription:(nullable NSString *)maximumValueDescription
                                    minimumValueDescription:(nullable NSString *)minimumValueDescription {
    return [[RK1ScaleAnswerFormat alloc] initWithMaximumValue:scaleMaximum
                                                 minimumValue:scaleMinimum
                                                 defaultValue:defaultValue
                                                         step:step
                                                     vertical:vertical
                                      maximumValueDescription:maximumValueDescription
                                      minimumValueDescription:minimumValueDescription];
}

+ (RK1ContinuousScaleAnswerFormat *)continuousScaleAnswerFormatWithMaximumValue:(double)scaleMaximum
                                                                   minimumValue:(double)scaleMinimum
                                                                   defaultValue:(double)defaultValue
                                                          maximumFractionDigits:(NSInteger)maximumFractionDigits
                                                                       vertical:(BOOL)vertical
                                                        maximumValueDescription:(nullable NSString *)maximumValueDescription
                                                        minimumValueDescription:(nullable NSString *)minimumValueDescription {
    return [[RK1ContinuousScaleAnswerFormat alloc] initWithMaximumValue:scaleMaximum
                                                           minimumValue:scaleMinimum
                                                           defaultValue:defaultValue
                                                  maximumFractionDigits:maximumFractionDigits
                                                               vertical:vertical
                                                maximumValueDescription:maximumValueDescription
                                                minimumValueDescription:minimumValueDescription];
}

+ (RK1TextScaleAnswerFormat *)textScaleAnswerFormatWithTextChoices:(NSArray<RK1TextChoice *> *)textChoices
                                                      defaultIndex:(NSInteger)defaultIndex
                                                          vertical:(BOOL)vertical {
    return [[RK1TextScaleAnswerFormat alloc] initWithTextChoices:textChoices
                                                    defaultIndex:defaultIndex
                                                        vertical:vertical];
}

+ (RK1BooleanAnswerFormat *)booleanAnswerFormat {
    return [RK1BooleanAnswerFormat new];
}

+ (RK1BooleanAnswerFormat *)booleanAnswerFormatWithYesString:(NSString *)yes noString:(NSString *)no {
    return [[RK1BooleanAnswerFormat alloc] initWithYesString:yes noString:no];
}

+ (RK1ValuePickerAnswerFormat *)valuePickerAnswerFormatWithTextChoices:(NSArray<RK1TextChoice *> *)textChoices {
    return [[RK1ValuePickerAnswerFormat alloc] initWithTextChoices:textChoices];
}

+ (RK1MultipleValuePickerAnswerFormat *)multipleValuePickerAnswerFormatWithValuePickers:(NSArray<RK1ValuePickerAnswerFormat *> *)valuePickers {
    return [[RK1MultipleValuePickerAnswerFormat alloc] initWithValuePickers:valuePickers];
}

+ (RK1ImageChoiceAnswerFormat *)choiceAnswerFormatWithImageChoices:(NSArray<RK1ImageChoice *> *)imageChoices {
    return [[RK1ImageChoiceAnswerFormat alloc] initWithImageChoices:imageChoices];
}

+ (RK1TextChoiceAnswerFormat *)choiceAnswerFormatWithStyle:(RK1ChoiceAnswerStyle)style
                                               textChoices:(NSArray<RK1TextChoice *> *)textChoices {
    return [[RK1TextChoiceAnswerFormat alloc] initWithStyle:style textChoices:textChoices];
}

+ (RK1NumericAnswerFormat *)decimalAnswerFormatWithUnit:(NSString *)unit {
    return [[RK1NumericAnswerFormat alloc] initWithStyle:RK1NumericAnswerStyleDecimal unit:unit minimum:nil maximum:nil];
}
+ (RK1NumericAnswerFormat *)integerAnswerFormatWithUnit:(NSString *)unit {
    return [[RK1NumericAnswerFormat alloc] initWithStyle:RK1NumericAnswerStyleInteger unit:unit minimum:nil maximum:nil];
}

+ (RK1TimeOfDayAnswerFormat *)timeOfDayAnswerFormat {
    return [RK1TimeOfDayAnswerFormat new];
}
+ (RK1TimeOfDayAnswerFormat *)timeOfDayAnswerFormatWithDefaultComponents:(NSDateComponents *)defaultComponents {
    return [[RK1TimeOfDayAnswerFormat alloc] initWithDefaultComponents:defaultComponents];
}

+ (RK1DateAnswerFormat *)dateTimeAnswerFormat {
    return [[RK1DateAnswerFormat alloc] initWithStyle:RK1DateAnswerStyleDateAndTime];
}
+ (RK1DateAnswerFormat *)dateTimeAnswerFormatWithDefaultDate:(NSDate *)defaultDate
                                                 minimumDate:(NSDate *)minimumDate
                                                 maximumDate:(NSDate *)maximumDate
                                                    calendar:(NSCalendar *)calendar {
    return [[RK1DateAnswerFormat alloc] initWithStyle:RK1DateAnswerStyleDateAndTime
                                          defaultDate:defaultDate
                                          minimumDate:minimumDate
                                          maximumDate:maximumDate
                                             calendar:calendar];
}

+ (RK1DateAnswerFormat *)dateAnswerFormat {
    return [[RK1DateAnswerFormat alloc] initWithStyle:RK1DateAnswerStyleDate];
}
+ (RK1DateAnswerFormat *)dateAnswerFormatWithDefaultDate:(NSDate *)defaultDate
                                             minimumDate:(NSDate *)minimumDate
                                             maximumDate:(NSDate *)maximumDate
                                                calendar:(NSCalendar *)calendar  {
    return [[RK1DateAnswerFormat alloc] initWithStyle:RK1DateAnswerStyleDate
                                          defaultDate:defaultDate
                                          minimumDate:minimumDate
                                          maximumDate:maximumDate
                                             calendar:calendar];
}

+ (RK1TextAnswerFormat *)textAnswerFormat {
    return [RK1TextAnswerFormat new];
}

+ (RK1TextAnswerFormat *)textAnswerFormatWithMaximumLength:(NSInteger)maximumLength {
    return [[RK1TextAnswerFormat alloc] initWithMaximumLength:maximumLength];
}

+ (RK1TextAnswerFormat *)textAnswerFormatWithValidationRegularExpression:(NSRegularExpression *)validationRegularExpression
                                                          invalidMessage:(NSString *)invalidMessage {
    return [[RK1TextAnswerFormat alloc] initWithValidationRegularExpression:validationRegularExpression
                                                             invalidMessage:invalidMessage];
}

+ (RK1EmailAnswerFormat *)emailAnswerFormat {
    return [RK1EmailAnswerFormat new];
}

+ (RK1TimeIntervalAnswerFormat *)timeIntervalAnswerFormat {
    return [RK1TimeIntervalAnswerFormat new];
}

+ (RK1TimeIntervalAnswerFormat *)timeIntervalAnswerFormatWithDefaultInterval:(NSTimeInterval)defaultInterval
                                                                        step:(NSInteger)step {
    return [[RK1TimeIntervalAnswerFormat alloc] initWithDefaultInterval:defaultInterval step:step];
}

+ (RK1HeightAnswerFormat *)heightAnswerFormat {
    return [RK1HeightAnswerFormat new];
}

+ (RK1HeightAnswerFormat *)heightAnswerFormatWithMeasurementSystem:(RK1MeasurementSystem)measurementSystem {
    return [[RK1HeightAnswerFormat alloc] initWithMeasurementSystem:measurementSystem];
}

+ (RK1WeightAnswerFormat *)weightAnswerFormat {
    return [RK1WeightAnswerFormat new];
}

+ (RK1WeightAnswerFormat *)weightAnswerFormatWithMeasurementSystem:(RK1MeasurementSystem)measurementSystem {
    return [[RK1WeightAnswerFormat alloc] initWithMeasurementSystem:measurementSystem];
}

+ (RK1WeightAnswerFormat *)weightAnswerFormatWithMeasurementSystem:(RK1MeasurementSystem)measurementSystem
                                                  numericPrecision:(RK1NumericPrecision)numericPrecision {
    return [[RK1WeightAnswerFormat alloc] initWithMeasurementSystem:measurementSystem
                                                   numericPrecision:numericPrecision];
}

+ (RK1WeightAnswerFormat *)weightAnswerFormatWithMeasurementSystem:(RK1MeasurementSystem)measurementSystem
                                                  numericPrecision:(RK1NumericPrecision)numericPrecision
                                                      minimumValue:(double)minimumValue
                                                      maximumValue:(double)maximumValue
                                                    defaultValue:(double)defaultValue {
    return [[RK1WeightAnswerFormat alloc] initWithMeasurementSystem:measurementSystem
                                                   numericPrecision:numericPrecision
                                                       minimumValue:minimumValue
                                                       maximumValue:maximumValue
                                                       defaultValue:defaultValue];
}

+ (RK1LocationAnswerFormat *)locationAnswerFormat {
    return [RK1LocationAnswerFormat new];
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

- (RK1QuestionType)questionType {
    return RK1QuestionTypeNone;
}

- (RK1AnswerFormat *)impliedAnswerFormat {
    return self;
}

- (Class)questionResultClass {
    return [RK1QuestionResult class];
}

- (RK1QuestionResult *)resultWithIdentifier:(NSString *)identifier answer:(id)answer {
    RK1QuestionResult *questionResult = [[[self questionResultClass] alloc] initWithIdentifier:identifier];
    
    /*
     ContinuousScale navigation rules always evaluate to false because the result is different from what is displayed in the UI.
     The fraction digits have to be taken into account in self.answer as well.
     */
    if ([self isKindOfClass:[RK1ContinuousScaleAnswerFormat class]]) {
        NSNumberFormatter* formatter = [(RK1ContinuousScaleAnswerFormat*)self numberFormatter];
        answer = [formatter numberFromString:[formatter stringFromNumber:answer]];
    }
    
    questionResult.answer = answer;
    questionResult.questionType = self.questionType;
    return questionResult;
}

- (BOOL)isAnswerValid:(id)answer {
    RK1AnswerFormat *impliedFormat = [self impliedAnswerFormat];
    return impliedFormat == self ? YES : [impliedFormat isAnswerValid:answer];
}

- (BOOL)isAnswerValidWithString:(NSString *)text {
    RK1AnswerFormat *impliedFormat = [self impliedAnswerFormat];
    return impliedFormat == self ? YES : [impliedFormat isAnswerValidWithString:text];
}

- (NSString *)localizedInvalidValueStringWithAnswerString:(NSString *)text {
    return nil;
}

- (NSString *)stringForAnswer:(id)answer {
    RK1AnswerFormat *impliedFormat = [self impliedAnswerFormat];
    return impliedFormat == self ? nil : [impliedFormat stringForAnswer:answer];
}

@end


#pragma mark - RK1ValuePickerAnswerFormat

static void ork_validateChoices(NSArray *choices) {
    const NSInteger RK1AnswerFormatMinimumNumberOfChoices = 1;
    if (choices.count < RK1AnswerFormatMinimumNumberOfChoices) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"The number of choices cannot be less than %@.", @(RK1AnswerFormatMinimumNumberOfChoices)]
                                     userInfo:nil];
    }
}

static NSArray *ork_processTextChoices(NSArray<RK1TextChoice *> *textChoices) {
    NSMutableArray *choices = [[NSMutableArray alloc] init];
    for (id object in textChoices) {
        // TODO: Remove these first two cases, which we don't really support anymore.
        if ([object isKindOfClass:[NSString class]]) {
            NSString *string = (NSString *)object;
            [choices addObject:[RK1TextChoice choiceWithText:string value:string]];
        } else if ([object isKindOfClass:[RK1TextChoice class]]) {
            [choices addObject:object];
            
        } else if ([object isKindOfClass:[NSArray class]]) {
            
            NSArray *array = (NSArray *)object;
            if (array.count > 1 &&
                [array[0] isKindOfClass:[NSString class]] &&
                [array[1] isKindOfClass:[NSString class]]) {
                
                [choices addObject:[RK1TextChoice choiceWithText:array[0] detailText:array[1] value:array[0] exclusive:NO]];
            } else if (array.count == 1 &&
                       [array[0] isKindOfClass:[NSString class]]) {
                [choices addObject:[RK1TextChoice choiceWithText:array[0] detailText:@"" value:array[0] exclusive:NO]];
            } else {
                @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Eligible array type Choice item should contain one or two NSString object." userInfo:@{@"choice": object }];
            }
        } else {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Eligible choice item's type are RK1TextChoice, NSString, and NSArray" userInfo:@{@"choice": object }];
        }
    }
    return choices;
}


@implementation RK1ValuePickerAnswerFormat {
    RK1ChoiceAnswerFormatHelper *_helper;
    RK1TextChoice *_nullTextChoice;
}

+ (instancetype)new {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)initWithTextChoices:(NSArray<RK1TextChoice *> *)textChoices {
    self = [super init];
    if (self) {
        [self commonInitWithTextChoices:textChoices nullChoice:nil];
    }
    return self;
}

- (instancetype)initWithTextChoices:(NSArray<RK1TextChoice *> *)textChoices nullChoice:(RK1TextChoice *)nullChoice {
    self = [super init];
    if (self) {
        [self commonInitWithTextChoices:textChoices nullChoice:nullChoice];
    }
    return self;
}

- (void)commonInitWithTextChoices:(NSArray<RK1TextChoice *> *)textChoices nullChoice:(RK1TextChoice *)nullChoice {
    _textChoices = ork_processTextChoices(textChoices);
    _nullTextChoice = nullChoice;
    _helper = [[RK1ChoiceAnswerFormatHelper alloc] initWithAnswerFormat:self];
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
            RK1EqualObjects(self.textChoices, castObject.textChoices));
}

- (NSUInteger)hash {
    return super.hash ^ _textChoices.hash;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        RK1_DECODE_OBJ_ARRAY(aDecoder, textChoices, RK1TextChoice);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_OBJ(aCoder, textChoices);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (RK1TextChoice *)nullTextChoice {
    return _nullTextChoice ?: [RK1TextChoice choiceWithText:RK1LocalizedString(@"NULL_ANSWER", nil) value:RK1NullAnswerValue()];
}

- (void)setNullTextChoice:(RK1TextChoice *)nullChoice {
    _nullTextChoice = nullChoice;
}

- (Class)questionResultClass {
    return [RK1ChoiceQuestionResult class];
}

- (RK1QuestionType)questionType {
    return RK1QuestionTypeSingleChoice;
}

- (NSString *)stringForAnswer:(id)answer {
    return [_helper stringForChoiceAnswer:answer];
}

@end


#pragma mark - RK1MultipleValuePickerAnswerFormat

@implementation RK1MultipleValuePickerAnswerFormat

+ (instancetype)new {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)initWithValuePickers:(NSArray<RK1ValuePickerAnswerFormat *> *)valuePickers {
    return [self initWithValuePickers:valuePickers separator:@" "];
}

- (instancetype)initWithValuePickers:(NSArray<RK1ValuePickerAnswerFormat *> *)valuePickers separator:(NSString *)separator {
    self = [super init];
    if (self) {
        for (RK1ValuePickerAnswerFormat *valuePicker in valuePickers) {
            // Do not show placeholder text for multiple component picker
            [valuePicker setNullTextChoice: [RK1TextChoice choiceWithText:@"" value:RK1NullAnswerValue()]];
        }
        _valuePickers = RK1ArrayCopyObjects(valuePickers);
        _separator = [separator copy];
    }
    return self;
}

- (void)validateParameters {
    [super validateParameters];
    for (RK1ValuePickerAnswerFormat *valuePicker in self.valuePickers) {
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
            RK1EqualObjects(self.valuePickers, castObject.valuePickers));
}

- (NSUInteger)hash {
    return super.hash ^ self.valuePickers.hash ^ self.separator.hash;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        RK1_DECODE_OBJ_ARRAY(aDecoder, valuePickers, RK1ValuePickerAnswerFormat);
        RK1_DECODE_OBJ_CLASS(aDecoder, separator, NSString);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_OBJ(aCoder, valuePickers);
    RK1_ENCODE_OBJ(aCoder, separator);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (Class)questionResultClass {
    return [RK1MultipleComponentQuestionResult class];
}

- (RK1QuestionResult *)resultWithIdentifier:(NSString *)identifier answer:(id)answer {
    RK1QuestionResult *questionResult = [super resultWithIdentifier:identifier answer:answer];
    if ([questionResult isKindOfClass:[RK1MultipleComponentQuestionResult class]]) {
        ((RK1MultipleComponentQuestionResult*)questionResult).separator = self.separator;
    }
    return questionResult;
}

- (RK1QuestionType)questionType {
    return RK1QuestionTypeMultiplePicker;
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


#pragma mark - RK1ImageChoiceAnswerFormat

@interface RK1ImageChoiceAnswerFormat () {
    RK1ChoiceAnswerFormatHelper *_helper;
    
}

@end


@implementation RK1ImageChoiceAnswerFormat

+ (instancetype)new {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)initWithImageChoices:(NSArray<RK1ImageChoice *> *)imageChoices {
    self = [super init];
    if (self) {
        NSMutableArray *choices = [[NSMutableArray alloc] init];
        
        for (NSObject *obj in imageChoices) {
            if ([obj isKindOfClass:[RK1ImageChoice class]]) {
                
                [choices addObject:obj];
                
            } else {
                @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Options should be instances of RK1ImageChoice" userInfo:@{ @"option": obj }];
            }
        }
        _imageChoices = choices;
        _helper = [[RK1ChoiceAnswerFormatHelper alloc] initWithAnswerFormat:self];
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
            RK1EqualObjects(self.imageChoices, castObject.imageChoices));
}

- (NSUInteger)hash {
    return super.hash ^ self.imageChoices.hash;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        RK1_DECODE_OBJ_ARRAY(aDecoder, imageChoices, RK1ImageChoice);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_OBJ(aCoder, imageChoices);
    
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (RK1QuestionType)questionType {
    return RK1QuestionTypeSingleChoice;
}

- (Class)questionResultClass {
    return [RK1ChoiceQuestionResult class];
}

- (NSString *)stringForAnswer:(id)answer {
    return [_helper stringForChoiceAnswer:answer];
}

@end


#pragma mark - RK1TextChoiceAnswerFormat

@interface RK1TextChoiceAnswerFormat () {
    
    RK1ChoiceAnswerFormatHelper *_helper;
}

@end


@implementation RK1TextChoiceAnswerFormat

+ (instancetype)new {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)initWithStyle:(RK1ChoiceAnswerStyle)style
                  textChoices:(NSArray<RK1TextChoice *> *)textChoices {
    self = [super init];
    if (self) {
        _style = style;
        _textChoices = ork_processTextChoices(textChoices);
        _helper = [[RK1ChoiceAnswerFormatHelper alloc] initWithAnswerFormat:self];
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
            RK1EqualObjects(self.textChoices, castObject.textChoices) &&
            (_style == castObject.style));
}

- (NSUInteger)hash {
    return super.hash ^ _textChoices.hash ^ _style;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        RK1_DECODE_OBJ_ARRAY(aDecoder, textChoices, RK1TextChoice);
        RK1_DECODE_ENUM(aDecoder, style);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_OBJ(aCoder, textChoices);
    RK1_ENCODE_ENUM(aCoder, style);
    
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (RK1QuestionType)questionType {
    return (_style == RK1ChoiceAnswerStyleSingleChoice) ? RK1QuestionTypeSingleChoice : RK1QuestionTypeMultipleChoice;
}

- (Class)questionResultClass {
    return [RK1ChoiceQuestionResult class];
}

- (NSString *)stringForAnswer:(id)answer {
    return [_helper stringForChoiceAnswer:answer];
}

@end


#pragma mark - RK1TextChoice

@implementation RK1TextChoice {
    NSString *_text;
    id<NSCopying, NSCoding, NSObject> _value;
}

+ (instancetype)new {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    RK1ThrowMethodUnavailableException();
}

+ (instancetype)choiceWithText:(NSString *)text detailText:(NSString *)detailText value:(id<NSCopying, NSCoding, NSObject>)value exclusive:(BOOL)exclusive {
    RK1TextChoice *option = [[RK1TextChoice alloc] initWithText:text detailText:detailText value:value exclusive:exclusive];
    return option;
}

+ (instancetype)choiceWithText:(NSString *)text value:(id<NSCopying, NSCoding, NSObject>)value {
    return [RK1TextChoice choiceWithText:text detailText:nil value:value exclusive:NO];
}

- (instancetype)initWithText:(NSString *)text detailText:(NSString *)detailText value:(id<NSCopying,NSCoding,NSObject>)value exclusive:(BOOL)exclusive {
    self = [super init];
    if (self) {
        _text = [text copy];
        _detailText = [detailText copy];
        _value = value;
        _exclusive = exclusive;
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
    return (RK1EqualObjects(self.text, castObject.text)
            && RK1EqualObjects(self.detailText, castObject.detailText)
            && RK1EqualObjects(self.value, castObject.value)
            && self.exclusive == castObject.exclusive);
}

- (NSUInteger)hash {
    // Ignore the task reference - it's not part of the content of the step
    return _text.hash ^ _detailText.hash ^ _value.hash;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        RK1_DECODE_OBJ_CLASS(aDecoder, text, NSString);
        RK1_DECODE_OBJ_CLASS(aDecoder, detailText, NSString);
        RK1_DECODE_OBJ(aDecoder, value);
        RK1_DECODE_BOOL(aDecoder, exclusive);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    RK1_ENCODE_OBJ(aCoder, text);
    RK1_ENCODE_OBJ(aCoder, value);
    RK1_ENCODE_OBJ(aCoder, detailText);
    RK1_ENCODE_BOOL(aCoder, exclusive);
}

@end


#pragma mark - RK1ImageChoice

@implementation RK1ImageChoice {
    NSString *_text;
    id<NSCopying, NSCoding, NSObject> _value;
}

+ (instancetype)choiceWithNormalImage:(UIImage *)normal selectedImage:(UIImage *)selected text:(NSString *)text value:(id<NSCopying, NSCoding, NSObject>)value {
    return [[RK1ImageChoice alloc] initWithNormalImage:normal selectedImage:selected text:text value:value];
}

+ (instancetype)new {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    RK1ThrowMethodUnavailableException();
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
    return (RK1EqualObjects(self.text, castObject.text)
            && RK1EqualObjects(self.value, castObject.value)
            && RK1EqualObjects(self.normalStateImage, castObject.normalStateImage)
            && RK1EqualObjects(self.selectedStateImage, castObject.selectedStateImage));
}

- (NSUInteger)hash {
    // Ignore the task reference - it's not part of the content of the step.
    return _text.hash ^ _value.hash;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        RK1_DECODE_OBJ_CLASS(aDecoder, text, NSString);
        RK1_DECODE_OBJ(aDecoder, value);
        RK1_DECODE_IMAGE(aDecoder, normalStateImage);
        RK1_DECODE_IMAGE(aDecoder, selectedStateImage);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    RK1_ENCODE_OBJ(aCoder, text);
    RK1_ENCODE_OBJ(aCoder, value);
    RK1_ENCODE_IMAGE(aCoder, normalStateImage);
    RK1_ENCODE_IMAGE(aCoder, selectedStateImage);
}

@end


#pragma mark - RK1BooleanAnswerFormat

@implementation RK1BooleanAnswerFormat

- (instancetype)initWithYesString:(NSString *)yes noString:(NSString *)no {
    self = [super init];
    if (self) {
        _yes = [yes copy];
        _no = [no copy];
    }
    return self;
}

- (RK1QuestionType)questionType {
    return RK1QuestionTypeBoolean;
}

- (RK1AnswerFormat *)impliedAnswerFormat {
    if (!_yes.length) {
        _yes = RK1LocalizedString(@"BOOL_YES", nil);
    }
    if (!_no.length) {
        _no = RK1LocalizedString(@"BOOL_NO", nil);
    }
    
    return [RK1AnswerFormat choiceAnswerFormatWithStyle:RK1ChoiceAnswerStyleSingleChoice
                                            textChoices:@[[RK1TextChoice choiceWithText:_yes value:@(YES)],
                                                          [RK1TextChoice choiceWithText:_no value:@(NO)]]];
}

- (Class)questionResultClass {
    return [RK1BooleanQuestionResult class];
}

- (NSString *)stringForAnswer:(id)answer {
    return [self.impliedAnswerFormat stringForAnswer: @[answer]];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    RK1BooleanAnswerFormat *answerFormat = [super copyWithZone:zone];
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
            RK1EqualObjects(self.yes, castObject.yes) &&
            RK1EqualObjects(self.no, castObject.no));
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        RK1_DECODE_OBJ_CLASS(aDecoder, yes, NSString);
        RK1_DECODE_OBJ_CLASS(aDecoder, no, NSString);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_OBJ(aCoder, yes);
    RK1_ENCODE_OBJ(aCoder, no);
}

@end


#pragma mark - RK1TimeOfDayAnswerFormat

@implementation RK1TimeOfDayAnswerFormat

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

- (RK1QuestionType)questionType {
    return RK1QuestionTypeTimeOfDay;
}

- (Class)questionResultClass {
    return [RK1TimeOfDayQuestionResult class];
}

- (NSDate *)pickerDefaultDate {
    
    if (self.defaultComponents) {
        return RK1TimeOfDayDateFromComponents(self.defaultComponents);
    }
    
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] componentsInTimeZone:[NSTimeZone systemTimeZone] fromDate:[NSDate date]];
    NSDateComponents *newDateComponents = [[NSDateComponents alloc] init];
    newDateComponents.calendar = RK1TimeOfDayReferenceCalendar();
    newDateComponents.hour = dateComponents.hour;
    newDateComponents.minute = dateComponents.minute;
    
    return RK1TimeOfDayDateFromComponents(newDateComponents);
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            RK1EqualObjects(self.defaultComponents, castObject.defaultComponents));
}

- (NSUInteger)hash {
    // Don't bother including everything
    return super.hash & self.defaultComponents.hash;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        RK1_DECODE_OBJ_CLASS(aDecoder, defaultComponents, NSDateComponents);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_OBJ(aCoder, defaultComponents);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (NSString *)stringForAnswer:(id)answer {
    return RK1TimeOfDayStringFromComponents(answer);
}

@end


#pragma mark - RK1DateAnswerFormat

@implementation RK1DateAnswerFormat

- (Class)questionResultClass {
    return [RK1DateQuestionResult class];
}

+ (instancetype)new {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)initWithStyle:(RK1DateAnswerStyle)style {
    self = [self initWithStyle:style defaultDate:nil minimumDate:nil maximumDate:nil calendar:nil];
    return self;
}

- (instancetype)initWithStyle:(RK1DateAnswerStyle)style
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
            RK1EqualObjects(self.defaultDate, castObject.defaultDate) &&
            RK1EqualObjects(self.minimumDate, castObject.minimumDate) &&
            RK1EqualObjects(self.maximumDate, castObject.maximumDate) &&
            RK1EqualObjects(self.calendar, castObject.calendar) &&
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
        case RK1QuestionTypeDate: {
            dfm = RK1ResultDateFormatter();
            break;
        }
        case RK1QuestionTypeTimeOfDay: {
            dfm = RK1ResultTimeFormatter();
            break;
        }
        case RK1QuestionTypeDateAndTime: {
            dfm = RK1ResultDateTimeFormatter();
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
        RK1_DECODE_ENUM(aDecoder, style);
        RK1_DECODE_OBJ_CLASS(aDecoder, minimumDate, NSDate);
        RK1_DECODE_OBJ_CLASS(aDecoder, maximumDate, NSDate);
        RK1_DECODE_OBJ_CLASS(aDecoder, defaultDate, NSDate);
        RK1_DECODE_OBJ_CLASS(aDecoder, calendar, NSCalendar);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_ENUM(aCoder, style);
    RK1_ENCODE_OBJ(aCoder, minimumDate);
    RK1_ENCODE_OBJ(aCoder, maximumDate);
    RK1_ENCODE_OBJ(aCoder, defaultDate);
    RK1_ENCODE_OBJ(aCoder, calendar);
}

- (RK1QuestionType)questionType {
    return (_style == RK1DateAnswerStyleDateAndTime) ? RK1QuestionTypeDateAndTime : RK1QuestionTypeDate;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (NSString *)stringForAnswer:(id)answer {
    return [self stringFromDate:answer];
}

@end


#pragma mark - RK1NumericAnswerFormat

@implementation RK1NumericAnswerFormat

- (Class)questionResultClass {
    return [RK1NumericQuestionResult class];
}

+ (instancetype)new {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)initWithStyle:(RK1NumericAnswerStyle)style {
    self = [self initWithStyle:style unit:nil minimum:nil maximum:nil];
    return self;
}

- (instancetype)initWithStyle:(RK1NumericAnswerStyle)style unit:(NSString *)unit minimum:(NSNumber *)minimum maximum:(NSNumber *)maximum {
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
        RK1_DECODE_ENUM(aDecoder, style);
        RK1_DECODE_OBJ_CLASS(aDecoder, unit, NSString);
        RK1_DECODE_OBJ_CLASS(aDecoder, minimum, NSNumber);
        RK1_DECODE_OBJ_CLASS(aDecoder, maximum, NSNumber);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_ENUM(aCoder, style);
    RK1_ENCODE_OBJ(aCoder, unit);
    RK1_ENCODE_OBJ(aCoder, minimum);
    RK1_ENCODE_OBJ(aCoder, maximum);
    
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    RK1NumericAnswerFormat *answerFormat = [[[self class] allocWithZone:zone] initWithStyle:_style
                                                                                       unit:[_unit copy]
                                                                                    minimum:[_minimum copy]
                                                                                    maximum:[_maximum copy]];
    return answerFormat;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            RK1EqualObjects(self.unit, castObject.unit) &&
            RK1EqualObjects(self.minimum, castObject.minimum) &&
            RK1EqualObjects(self.maximum, castObject.maximum) &&
            (_style == castObject.style));
}

- (NSUInteger)hash {
    // Don't bother including everything - style is the main item
    return [super hash] ^ ([self.unit hash] & _style);
}

- (instancetype)initWithStyle:(RK1NumericAnswerStyle)style unit:(NSString *)unit {
    return [self initWithStyle:style unit:unit minimum:nil maximum:nil];
}

+ (instancetype)decimalAnswerFormatWithUnit:(NSString *)unit {
    return [[RK1NumericAnswerFormat alloc] initWithStyle:RK1NumericAnswerStyleDecimal unit:unit];
}

+ (instancetype)integerAnswerFormatWithUnit:(NSString *)unit {
    return [[RK1NumericAnswerFormat alloc] initWithStyle:RK1NumericAnswerStyleInteger unit:unit];
}

- (RK1QuestionType)questionType {
    return _style == RK1NumericAnswerStyleDecimal ? RK1QuestionTypeDecimal : RK1QuestionTypeInteger;
    
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
    NSNumberFormatter *formatter = RK1DecimalNumberFormatter();
    if (self.minimum && (self.minimum.doubleValue > num.doubleValue)) {
        string = [NSString localizedStringWithFormat:RK1LocalizedString(@"RANGE_ALERT_MESSAGE_BELOW_MAXIMUM", nil), text, [formatter stringFromNumber:self.minimum]];
    } else if (self.maximum && (self.maximum.doubleValue < num.doubleValue)) {
        string = [NSString localizedStringWithFormat:RK1LocalizedString(@"RANGE_ALERT_MESSAGE_ABOVE_MAXIMUM", nil), text, [formatter stringFromNumber:self.maximum]];
    } else {
        string = [NSString localizedStringWithFormat:RK1LocalizedString(@"RANGE_ALERT_MESSAGE_OTHER", nil), text];
    }
    return string;
}

- (NSString *)stringForAnswer:(id)answer {
    NSString *answerString = nil;
    if ([self isAnswerValid:answer]) {
        NSNumberFormatter *formatter = RK1DecimalNumberFormatter();
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
    if (_style == RK1NumericAnswerStyleDecimal) {
        sanitizedText = [self removeDecimalSeparatorsFromText:text numAllowed:1 separator:(NSString *)separator];
    } else if (_style == RK1NumericAnswerStyleInteger) {
        sanitizedText = [self removeDecimalSeparatorsFromText:text numAllowed:0 separator:(NSString *)separator];
    }
    return sanitizedText;
}

@end


#pragma mark - RK1ScaleAnswerFormat

@implementation RK1ScaleAnswerFormat {
    NSNumberFormatter *_numberFormatter;
}

- (Class)questionResultClass {
    return [RK1ScaleQuestionResult class];
}

+ (instancetype)new {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    RK1ThrowMethodUnavailableException();
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

- (NSArray<RK1TextChoice *> *)textChoices {
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
    
    const NSInteger RK1ScaleAnswerFormatMinimumStepSize = 1;
    const NSInteger RK1ScaleAnswerFormatMinimumStepCount = 1;
    const NSInteger RK1ScaleAnswerFormatMaximumStepCount = 13;
    
    const NSInteger RK1ScaleAnswerFormatValueLowerbound = -10000;
    const NSInteger RK1ScaleAnswerFormatValueUpperbound = 10000;
    
    if (_maximum < _minimum) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Expect maximumValue larger than minimumValue"] userInfo:nil];
    }
    
    if (_step < RK1ScaleAnswerFormatMinimumStepSize) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Expect step value not less than than %@.", @(RK1ScaleAnswerFormatMinimumStepSize)]
                                     userInfo:nil];
    }
    
    NSInteger mod = (_maximum - _minimum) % _step;
    if (mod != 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Expect the difference between maximumValue and minimumValue is divisible by step value"] userInfo:nil];
    }
    
    NSInteger steps = (_maximum - _minimum) / _step;
    if (steps < RK1ScaleAnswerFormatMinimumStepCount || steps > RK1ScaleAnswerFormatMaximumStepCount) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Expect the total number of steps between minimumValue and maximumValue more than %@ and no more than %@.", @(RK1ScaleAnswerFormatMinimumStepCount), @(RK1ScaleAnswerFormatMaximumStepCount)]
                                     userInfo:nil];
    }
    
    if (_minimum < RK1ScaleAnswerFormatValueLowerbound) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"minimumValue should not less than %@", @(RK1ScaleAnswerFormatValueLowerbound)]
                                     userInfo:nil];
    }
    
    if (_maximum > RK1ScaleAnswerFormatValueUpperbound) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"maximumValue should not more than %@", @(RK1ScaleAnswerFormatValueUpperbound)]
                                     userInfo:nil];
    }
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        RK1_DECODE_INTEGER(aDecoder, maximum);
        RK1_DECODE_INTEGER(aDecoder, minimum);
        RK1_DECODE_INTEGER(aDecoder, step);
        RK1_DECODE_INTEGER(aDecoder, defaultValue);
        RK1_DECODE_BOOL(aDecoder, vertical);
        RK1_DECODE_OBJ(aDecoder, maximumValueDescription);
        RK1_DECODE_OBJ(aDecoder, minimumValueDescription);
        RK1_DECODE_IMAGE(aDecoder, maximumImage);
        RK1_DECODE_IMAGE(aDecoder, minimumImage);
        RK1_DECODE_OBJ_ARRAY(aDecoder, gradientColors, UIColor);
        RK1_DECODE_OBJ_ARRAY(aDecoder, gradientLocations, NSNumber);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_INTEGER(aCoder, maximum);
    RK1_ENCODE_INTEGER(aCoder, minimum);
    RK1_ENCODE_INTEGER(aCoder, step);
    RK1_ENCODE_INTEGER(aCoder, defaultValue);
    RK1_ENCODE_BOOL(aCoder, vertical);
    RK1_ENCODE_OBJ(aCoder, maximumValueDescription);
    RK1_ENCODE_OBJ(aCoder, minimumValueDescription);
    RK1_ENCODE_IMAGE(aCoder, maximumImage);
    RK1_ENCODE_IMAGE(aCoder, minimumImage);
    RK1_ENCODE_OBJ(aCoder, gradientColors);
    RK1_ENCODE_OBJ(aCoder, gradientLocations);
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
            RK1EqualObjects(self.maximumValueDescription, castObject.maximumValueDescription) &&
            RK1EqualObjects(self.minimumValueDescription, castObject.minimumValueDescription) &&
            RK1EqualObjects(self.maximumImage, castObject.maximumImage) &&
            RK1EqualObjects(self.minimumImage, castObject.minimumImage) &&
            RK1EqualObjects(self.gradientColors, castObject.gradientColors) &&
            RK1EqualObjects(self.gradientLocations, castObject.gradientLocations));
}

- (RK1QuestionType)questionType {
    return RK1QuestionTypeScale;
}

- (NSString *)stringForAnswer:(id)answer {
    return [self localizedStringForNumber:answer];
}

@end


#pragma mark - RK1ContinuousScaleAnswerFormat

@implementation RK1ContinuousScaleAnswerFormat {
    NSNumberFormatter *_numberFormatter;
}

- (Class)questionResultClass {
    return [RK1ScaleQuestionResult class];
}

+ (instancetype)new {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    RK1ThrowMethodUnavailableException();
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

- (NSArray<RK1TextChoice *> *)textChoices {
    return nil;
}

- (NSNumberFormatter *)numberFormatter {
    if (!_numberFormatter) {
        _numberFormatter = [[NSNumberFormatter alloc] init];
        _numberFormatter.numberStyle = RK1NumberFormattingStyleConvert(_numberStyle);
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
    
    const double RK1ScaleAnswerFormatValueLowerbound = -10000;
    const double RK1ScaleAnswerFormatValueUpperbound = 10000;
    
    // Just clamp maximumFractionDigits to be 0-4. This is all aimed at keeping the maximum
    // number of digits down to 6 or less.
    _maximumFractionDigits = MAX(_maximumFractionDigits, 0);
    _maximumFractionDigits = MIN(_maximumFractionDigits, 4);
    
    double effectiveUpperbound = RK1ScaleAnswerFormatValueUpperbound * pow(0.1, _maximumFractionDigits);
    double effectiveLowerbound = RK1ScaleAnswerFormatValueLowerbound * pow(0.1, _maximumFractionDigits);
    
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
        RK1_DECODE_DOUBLE(aDecoder, maximum);
        RK1_DECODE_DOUBLE(aDecoder, minimum);
        RK1_DECODE_DOUBLE(aDecoder, defaultValue);
        RK1_DECODE_INTEGER(aDecoder, maximumFractionDigits);
        RK1_DECODE_BOOL(aDecoder, vertical);
        RK1_DECODE_ENUM(aDecoder, numberStyle);
        RK1_DECODE_OBJ(aDecoder, maximumValueDescription);
        RK1_DECODE_OBJ(aDecoder, minimumValueDescription);
        RK1_DECODE_IMAGE(aDecoder, maximumImage);
        RK1_DECODE_IMAGE(aDecoder, minimumImage);
        RK1_DECODE_OBJ_ARRAY(aDecoder, gradientColors, UIColor);
        RK1_DECODE_OBJ_ARRAY(aDecoder, gradientLocations, NSNumber);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_DOUBLE(aCoder, maximum);
    RK1_ENCODE_DOUBLE(aCoder, minimum);
    RK1_ENCODE_DOUBLE(aCoder, defaultValue);
    RK1_ENCODE_INTEGER(aCoder, maximumFractionDigits);
    RK1_ENCODE_BOOL(aCoder, vertical);
    RK1_ENCODE_ENUM(aCoder, numberStyle);
    RK1_ENCODE_OBJ(aCoder, maximumValueDescription);
    RK1_ENCODE_OBJ(aCoder, minimumValueDescription);
    RK1_ENCODE_IMAGE(aCoder, maximumImage);
    RK1_ENCODE_IMAGE(aCoder, minimumImage);
    RK1_ENCODE_OBJ(aCoder, gradientColors);
    RK1_ENCODE_OBJ(aCoder, gradientLocations);
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
            RK1EqualObjects(self.maximumValueDescription, castObject.maximumValueDescription) &&
            RK1EqualObjects(self.minimumValueDescription, castObject.minimumValueDescription) &&
            RK1EqualObjects(self.maximumImage, castObject.maximumImage) &&
            RK1EqualObjects(self.minimumImage, castObject.minimumImage) &&
            RK1EqualObjects(self.gradientColors, castObject.gradientColors) &&
            RK1EqualObjects(self.gradientLocations, castObject.gradientLocations));
}

- (RK1QuestionType)questionType {
    return RK1QuestionTypeScale;
}

- (NSString *)stringForAnswer:(id)answer {
    return [self localizedStringForNumber:answer];
}

@end


#pragma mark - RK1TextScaleAnswerFormat

@interface RK1TextScaleAnswerFormat () {
    
    RK1ChoiceAnswerFormatHelper *_helper;
}

@end


@implementation RK1TextScaleAnswerFormat {
    NSNumberFormatter *_numberFormatter;
}

- (Class)questionResultClass {
    return [RK1ChoiceQuestionResult class];
}

+ (instancetype)new {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)initWithTextChoices:(NSArray<RK1TextChoice *> *)textChoices
                       defaultIndex:(NSInteger)defaultIndex
                           vertical:(BOOL)vertical {
    self = [super init];
    if (self) {
        _textChoices = [textChoices copy];
        _defaultIndex = defaultIndex;
        _vertical = vertical;
        _helper = [[RK1ChoiceAnswerFormatHelper alloc] initWithAnswerFormat:self];
        
        [self validateParameters];
    }
    return self;
}

- (instancetype)initWithTextChoices:(NSArray<RK1TextChoice *> *)textChoices
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

- (RK1TextChoice *)textChoiceAtIndex:(NSUInteger)index {
    
    if (index >= _textChoices.count) {
        return nil;
    }
    return _textChoices[index];
}

- (RK1TextChoice *)textChoiceForValue:(id<NSCopying, NSCoding, NSObject>)value {
    __block RK1TextChoice *choice = nil;
    
    [_textChoices enumerateObjectsUsingBlock:^(RK1TextChoice * _Nonnull textChoice, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([textChoice.value isEqual:value]) {
            choice = textChoice;
            *stop = YES;
        }
    }];
    
    return choice;
}

- (NSUInteger)textChoiceIndexForValue:(id<NSCopying, NSCoding, NSObject>)value {
    RK1TextChoice *choice = [self textChoiceForValue:value];
    return choice ? [_textChoices indexOfObject:choice] : NSNotFound;
}

- (void)validateParameters {
    [super validateParameters];
    
    if (_textChoices.count < 2) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Must have a minimum of 2 text choices." userInfo:nil];
    } else if (_textChoices.count > 8) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Cannot have more than 8 text choices." userInfo:nil];
    }
    
    RK1ValidateArrayForObjectsOfClass(_textChoices, [RK1TextChoice class], @"Text choices must be of class RK1TextChoice.");
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        RK1_DECODE_OBJ_ARRAY(aDecoder, textChoices, RK1TextChoice);
        RK1_DECODE_OBJ_ARRAY(aDecoder, gradientColors, UIColor);
        RK1_DECODE_OBJ_ARRAY(aDecoder, gradientLocations, NSNumber);
        RK1_DECODE_INTEGER(aDecoder, defaultIndex);
        RK1_DECODE_BOOL(aDecoder, vertical);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_OBJ(aCoder, textChoices);
    RK1_ENCODE_OBJ(aCoder, gradientColors);
    RK1_ENCODE_OBJ(aCoder, gradientLocations);
    RK1_ENCODE_INTEGER(aCoder, defaultIndex);
    RK1_ENCODE_BOOL(aCoder, vertical);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            RK1EqualObjects(self.textChoices, castObject.textChoices) &&
            (_defaultIndex == castObject.defaultIndex) &&
            (_vertical == castObject.vertical) &&
            RK1EqualObjects(self.gradientColors, castObject.gradientColors) &&
            RK1EqualObjects(self.gradientLocations, castObject.gradientLocations));
}

- (RK1QuestionType)questionType {
    return RK1QuestionTypeScale;
}

- (NSString *)stringForAnswer:(id)answer {
    return [_helper stringForChoiceAnswer:answer];
}

@end


#pragma mark - RK1TextAnswerFormat

@implementation RK1TextAnswerFormat

- (Class)questionResultClass {
    return [RK1TextQuestionResult class];
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

- (RK1QuestionType)questionType {
    return RK1QuestionTypeText;
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
    RK1TextAnswerFormat *answerFormat = [[[self class] allocWithZone:zone] init];
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
        string = [NSString localizedStringWithFormat:RK1LocalizedString(@"TEXT_ANSWER_EXCEEDING_MAX_LENGTH_ALERT_MESSAGE", nil), RK1LocalizedStringFromNumber(@(_maximumLength))];
    }
    if (![self isTextRegularExpressionValidWithString:text]) {
        if (string.length > 0) {
            string = [string stringByAppendingString:@"\n"];
        }
        string = [string stringByAppendingString:[NSString localizedStringWithFormat:RK1LocalizedString(_invalidMessage, nil), text]];
    }
    return string;
}


- (RK1AnswerFormat *)confirmationAnswerFormatWithOriginalItemIdentifier:(NSString *)originalItemIdentifier
                                                           errorMessage:(NSString *)errorMessage {
    
    NSAssert(!self.multipleLines, @"Confirmation Answer Format is not currently defined for RK1TextAnswerFormat with multiple lines.");
    
    RK1TextAnswerFormat *answerFormat = [[RK1ConfirmTextAnswerFormat alloc] initWithOriginalItemIdentifier:originalItemIdentifier errorMessage:errorMessage];
    
    // Copy from RK1TextAnswerFormat being confirmed
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
        RK1_DECODE_INTEGER(aDecoder, maximumLength);
        RK1_DECODE_OBJ_CLASS(aDecoder, validationRegularExpression, NSRegularExpression);
        RK1_DECODE_OBJ_CLASS(aDecoder, invalidMessage, NSString);
        RK1_DECODE_ENUM(aDecoder, autocapitalizationType);
        RK1_DECODE_ENUM(aDecoder, autocorrectionType);
        RK1_DECODE_ENUM(aDecoder, spellCheckingType);
        RK1_DECODE_ENUM(aDecoder, keyboardType);
        RK1_DECODE_BOOL(aDecoder, multipleLines);
        RK1_DECODE_BOOL(aDecoder, secureTextEntry);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_INTEGER(aCoder, maximumLength);
    RK1_ENCODE_OBJ(aCoder, validationRegularExpression);
    RK1_ENCODE_OBJ(aCoder, invalidMessage);
    RK1_ENCODE_ENUM(aCoder, autocapitalizationType);
    RK1_ENCODE_ENUM(aCoder, autocorrectionType);
    RK1_ENCODE_ENUM(aCoder, spellCheckingType);
    RK1_ENCODE_ENUM(aCoder, keyboardType);
    RK1_ENCODE_BOOL(aCoder, multipleLines);
    RK1_ENCODE_BOOL(aCoder, secureTextEntry);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            (self.maximumLength == castObject.maximumLength &&
             RK1EqualObjects(self.validationRegularExpression, castObject.validationRegularExpression) &&
             RK1EqualObjects(self.invalidMessage, castObject.invalidMessage) &&
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


#pragma mark - RK1EmailAnswerFormat

@implementation RK1EmailAnswerFormat {
    RK1TextAnswerFormat *_impliedAnswerFormat;
}

- (RK1QuestionType)questionType {
    return RK1QuestionTypeText;
}

- (Class)questionResultClass {
    return [RK1TextQuestionResult class];
}

- (RK1AnswerFormat *)impliedAnswerFormat {
    if (!_impliedAnswerFormat) {
        NSRegularExpression *validationRegularExpression =
        [NSRegularExpression regularExpressionWithPattern:EmailValidationRegularExpressionPattern
                                                  options:(NSRegularExpressionOptions)0
                                                    error:nil];
        NSString *invalidMessage = RK1LocalizedString(@"INVALID_EMAIL_ALERT_MESSAGE", nil);
        _impliedAnswerFormat = [RK1TextAnswerFormat textAnswerFormatWithValidationRegularExpression:validationRegularExpression
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


#pragma mark - RK1ConfirmTextAnswerFormat

@implementation RK1ConfirmTextAnswerFormat

+ (instancetype)new {
    RK1ThrowMethodUnavailableException();
}

// Don't throw on -init nor -initWithMaximumLength: because they're internally used by -copyWithZone:

- (instancetype)initWithValidationRegularExpression:(NSRegularExpression *)validationRegularExpression
                                     invalidMessage:(NSString *)invalidMessage {
    RK1ThrowMethodUnavailableException();
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
    RK1ConfirmTextAnswerFormat *answerFormat = [super copyWithZone:zone];
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
        RK1_DECODE_OBJ_CLASS(aDecoder, originalItemIdentifier, NSString);
        RK1_DECODE_OBJ_CLASS(aDecoder, errorMessage, NSString);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_OBJ(aCoder, originalItemIdentifier);
    RK1_ENCODE_OBJ(aCoder, errorMessage);
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            RK1EqualObjects(self.originalItemIdentifier, castObject.originalItemIdentifier) &&
            RK1EqualObjects(self.errorMessage, castObject.errorMessage));
}

@end


#pragma mark - RK1TimeIntervalAnswerFormat

@implementation RK1TimeIntervalAnswerFormat

- (Class)questionResultClass {
    return [RK1TimeIntervalQuestionResult class];
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

- (RK1QuestionType)questionType {
    return RK1QuestionTypeTimeInterval;
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
    
    const NSInteger RK1TimeIntervalAnswerFormatStepLowerBound = 1;
    const NSInteger RK1TimeIntervalAnswerFormatStepUpperBound = 30;
    
    if (_step < RK1TimeIntervalAnswerFormatStepLowerBound || _step > RK1TimeIntervalAnswerFormatStepUpperBound) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Step should be between %@ and %@.", @(RK1TimeIntervalAnswerFormatStepLowerBound), @(RK1TimeIntervalAnswerFormatStepUpperBound)] userInfo:nil];
    }
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        RK1_DECODE_DOUBLE(aDecoder, defaultInterval);
        RK1_DECODE_DOUBLE(aDecoder, step);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_DOUBLE(aCoder, defaultInterval);
    RK1_ENCODE_DOUBLE(aCoder, step);
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
    return [RK1TimeIntervalLabelFormatter() stringFromTimeInterval:((NSNumber *)answer).floatValue];
}

@end


#pragma mark - RK1HeightAnswerFormat

@implementation RK1HeightAnswerFormat

- (Class)questionResultClass {
    return [RK1NumericQuestionResult class];
}

- (NSString *)canonicalUnitString {
    return @"cm";
}

- (RK1NumericQuestionResult *)resultWithIdentifier:(NSString *)identifier answer:(NSNumber *)answer {
    RK1NumericQuestionResult *questionResult = (RK1NumericQuestionResult *)[super resultWithIdentifier:identifier answer:answer];
    // Use canonical unit because we expect results to be consistent regardless of the user locale
    questionResult.unit = [self canonicalUnitString];
    return questionResult;
}

- (instancetype)init {
    self = [self initWithMeasurementSystem:RK1MeasurementSystemLocal];
    return self;
}

- (instancetype)initWithMeasurementSystem:(RK1MeasurementSystem)measurementSystem {
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
        RK1_DECODE_ENUM(aDecoder, measurementSystem);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_ENUM(aCoder, measurementSystem);
}

- (RK1QuestionType)questionType {
    return RK1QuestionTypeHeight;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)useMetricSystem {
    return _measurementSystem == RK1MeasurementSystemMetric
    || (_measurementSystem == RK1MeasurementSystemLocal && ((NSNumber *)[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem]).boolValue);
}

- (NSString *)stringForAnswer:(id)answer {
    NSString *answerString = nil;
    
    if (!RK1IsAnswerEmpty(answer)) {
        NSNumberFormatter *formatter = RK1DecimalNumberFormatter();
        if (self.useMetricSystem) {
            answerString = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:answer], RK1LocalizedString(@"MEASURING_UNIT_CM", nil)];
        } else {
            double feet, inches;
            RK1CentimetersToFeetAndInches(((NSNumber *)answer).doubleValue, &feet, &inches);
            NSString *feetString = [formatter stringFromNumber:@(feet)];
            NSString *inchesString = [formatter stringFromNumber:@(inches)];
            answerString = [NSString stringWithFormat:@"%@ %@, %@ %@",
                            feetString, RK1LocalizedString(@"MEASURING_UNIT_FT", nil), inchesString, RK1LocalizedString(@"MEASURING_UNIT_IN", nil)];
        }
    }
    return answerString;
}

@end


#pragma mark - RK1WeightAnswerFormat

@implementation RK1WeightAnswerFormat

- (Class)questionResultClass {
    return [RK1NumericQuestionResult class];
}

- (NSString *)canonicalUnitString {
    return @"kg";
}

- (RK1NumericQuestionResult *)resultWithIdentifier:(NSString *)identifier answer:(NSNumber *)answer {
    RK1NumericQuestionResult *questionResult = (RK1NumericQuestionResult *)[super resultWithIdentifier:identifier answer:answer];
    // Use canonical unit because we expect results to be consistent regardless of the user locale
    questionResult.unit = [self canonicalUnitString];
    return questionResult;
}

- (instancetype)init {
    return [self initWithMeasurementSystem:RK1MeasurementSystemLocal
                          numericPrecision:RK1NumericPrecisionDefault
                              minimumValue:RK1DoubleDefaultValue
                              maximumValue:RK1DoubleDefaultValue
                              defaultValue:RK1DoubleDefaultValue];
}

- (instancetype)initWithMeasurementSystem:(RK1MeasurementSystem)measurementSystem {
    return [self initWithMeasurementSystem:measurementSystem
                          numericPrecision:RK1NumericPrecisionDefault
                              minimumValue:RK1DoubleDefaultValue
                              maximumValue:RK1DoubleDefaultValue
                              defaultValue:RK1DoubleDefaultValue];
}

- (instancetype)initWithMeasurementSystem:(RK1MeasurementSystem)measurementSystem
                         numericPrecision:(RK1NumericPrecision)numericPrecision {
    return [self initWithMeasurementSystem:measurementSystem
                          numericPrecision:numericPrecision
                              minimumValue:RK1DoubleDefaultValue
                              maximumValue:RK1DoubleDefaultValue
                              defaultValue:RK1DoubleDefaultValue];
}

- (instancetype)initWithMeasurementSystem:(RK1MeasurementSystem)measurementSystem
                         numericPrecision:(RK1NumericPrecision)numericPrecision
                             minimumValue:(double)minimumValue
                             maximumValue:(double)maximumValue
                             defaultValue:(double)defaultValue {
    if ((defaultValue != RK1DoubleDefaultValue) && ((defaultValue < minimumValue) || (defaultValue > maximumValue))) {
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
        RK1_DECODE_ENUM(aDecoder, measurementSystem);
        RK1_DECODE_ENUM(aDecoder, numericPrecision);
        RK1_DECODE_DOUBLE(aDecoder, minimumValue);
        RK1_DECODE_DOUBLE(aDecoder, maximumValue);
        RK1_DECODE_DOUBLE(aDecoder, defaultValue);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_ENUM(aCoder, measurementSystem);
    RK1_ENCODE_ENUM(aCoder, numericPrecision);
    RK1_ENCODE_DOUBLE(aCoder, minimumValue);
    RK1_ENCODE_DOUBLE(aCoder, maximumValue);
    RK1_ENCODE_DOUBLE(aCoder, defaultValue);
}

- (RK1QuestionType)questionType {
    return RK1QuestionTypeWeight;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)useMetricSystem {
    return _measurementSystem == RK1MeasurementSystemMetric || (_measurementSystem == RK1MeasurementSystemLocal && ((NSNumber *)[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem]).boolValue);
}

- (NSString *)stringForAnswer:(id)answer {
    NSString *answerString = nil;
    
    if (!RK1IsAnswerEmpty(answer)) {
        NSNumberFormatter *formatter = RK1DecimalNumberFormatter();
        if (self.useMetricSystem) {
            answerString = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:answer], RK1LocalizedString(@"MEASURING_UNIT_KG", nil)];
        } else {
            if (self.numericPrecision != RK1NumericPrecisionHigh) {
                double pounds = RK1KilogramsToPounds(((NSNumber *)answer).doubleValue);
                NSString *poundsString = [formatter stringFromNumber:@(pounds)];
                answerString = [NSString stringWithFormat:@"%@ %@", poundsString, RK1LocalizedString(@"MEASURING_UNIT_LB", nil)];
            } else {
                double pounds, ounces;
                RK1KilogramsToPoundsAndOunces(((NSNumber *)answer).doubleValue, &pounds, &ounces);
                NSString *poundsString = [formatter stringFromNumber:@(pounds)];
                NSString *ouncesString = [formatter stringFromNumber:@(ounces)];
                answerString = [NSString stringWithFormat:@"%@ %@, %@ %@", poundsString, RK1LocalizedString(@"MEASURING_UNIT_LB", nil), ouncesString, RK1LocalizedString(@"MEASURING_UNIT_OZ", nil)];
            }
        }
    }
    return answerString;
}

@end


#pragma mark - RK1LocationAnswerFormat

@implementation RK1LocationAnswerFormat

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
        RK1_DECODE_BOOL(aDecoder, useCurrentLocation);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_BOOL(aCoder, useCurrentLocation);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (RK1QuestionType)questionType {
    return RK1QuestionTypeLocation;
}

- (Class)questionResultClass {
    return [RK1LocationQuestionResult class];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    RK1LocationAnswerFormat *locationAnswerFormat = [[[self class] allocWithZone:zone] init];
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
    if ([answer isKindOfClass:[RK1Location class]]) {
        RK1Location *location = answer;
        // access address dictionary directly since 'ABCreateStringWithAddressDictionary:' is deprecated in iOS9
        NSArray<NSString *> *addressLines = [location.addressDictionary valueForKey:formattedAddressLinesKey];
        answerString = addressLines ? [addressLines componentsJoinedByString:@"\n"] :
        MKStringFromMapPoint(MKMapPointForCoordinate(location.coordinate));
    }
    return answerString;
}

@end
