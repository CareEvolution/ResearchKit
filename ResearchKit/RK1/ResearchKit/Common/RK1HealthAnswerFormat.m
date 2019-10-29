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


#import "RK1HealthAnswerFormat.h"

#import "RK1AnswerFormat_Internal.h"

#import "RK1Helpers_Internal.h"

#import "RK1Result.h"


#pragma mark - RK1HealthAnswerFormat

RK1BiologicalSexIdentifier const RK1BiologicalSexIdentifierFemale = @"HKBiologicalSexFemale";
RK1BiologicalSexIdentifier const RK1BiologicalSexIdentifierMale = @"HKBiologicalSexMale";
RK1BiologicalSexIdentifier const RK1BiologicalSexIdentifierOther = @"HKBiologicalSexOther";

NSString *RK1HKBiologicalSexString(HKBiologicalSex biologicalSex) {
    NSString *string = nil;
    switch (biologicalSex) {
        case HKBiologicalSexFemale: string = RK1BiologicalSexIdentifierFemale; break;
        case HKBiologicalSexMale:   string = RK1BiologicalSexIdentifierMale;   break;
        case HKBiologicalSexOther:  string = RK1BiologicalSexIdentifierOther;  break;
        case HKBiologicalSexNotSet: break;
    }
    return string;
}

RK1BloodTypeIdentifier const RK1BloodTypeIdentifierAPositive = @"HKBloodTypeAPositive";
RK1BloodTypeIdentifier const RK1BloodTypeIdentifierANegative = @"HKBloodTypeANegative";
RK1BloodTypeIdentifier const RK1BloodTypeIdentifierBPositive = @"HKBloodTypeBPositive";
RK1BloodTypeIdentifier const RK1BloodTypeIdentifierBNegative = @"HKBloodTypeBNegative";
RK1BloodTypeIdentifier const RK1BloodTypeIdentifierABPositive = @"HKBloodTypeABPositive";
RK1BloodTypeIdentifier const RK1BloodTypeIdentifierABNegative = @"HKBloodTypeABNegative";
RK1BloodTypeIdentifier const RK1BloodTypeIdentifierOPositive = @"HKBloodTypeOPositive";
RK1BloodTypeIdentifier const RK1BloodTypeIdentifierONegative = @"HKBloodTypeONegative";

NSString *RK1HKBloodTypeString(HKBloodType bloodType) {
    NSString *string = nil;
    switch (bloodType) {
        case HKBloodTypeAPositive:  string = RK1BloodTypeIdentifierAPositive;   break;
        case HKBloodTypeANegative:  string = RK1BloodTypeIdentifierANegative;   break;
        case HKBloodTypeBPositive:  string = RK1BloodTypeIdentifierBPositive;   break;
        case HKBloodTypeBNegative:  string = RK1BloodTypeIdentifierBNegative;   break;
        case HKBloodTypeABPositive: string = RK1BloodTypeIdentifierABPositive;  break;
        case HKBloodTypeABNegative: string = RK1BloodTypeIdentifierABNegative;  break;
        case HKBloodTypeOPositive:  string = RK1BloodTypeIdentifierOPositive;   break;
        case HKBloodTypeONegative:  string = RK1BloodTypeIdentifierONegative;   break;
        case HKBloodTypeNotSet: break;
    }
    return string;
}

@interface RK1HealthKitCharacteristicTypeAnswerFormat ()

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end


@implementation RK1HealthKitCharacteristicTypeAnswerFormat {
    RK1AnswerFormat *_impliedAnswerFormat;
}

+ (instancetype)new {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    RK1ThrowMethodUnavailableException();
}

- (BOOL)isHealthKitAnswerFormat {
    return YES;
}

- (RK1QuestionType)questionType {
    return [[self impliedAnswerFormat] questionType];
}

- (HKObjectType *)healthKitObjectType {
    return _characteristicType;
}

- (HKObjectType *)healthKitObjectTypeForAuthorization {
    if (self.shouldRequestAuthorization) {
        return [self healthKitObjectType];
    }
    else {
        return nil;
    }
}

- (Class)questionResultClass {
    return [[self impliedAnswerFormat] questionResultClass];
}

+ (instancetype)answerFormatWithCharacteristicType:(HKCharacteristicType *)characteristicType {
    RK1HealthKitCharacteristicTypeAnswerFormat *format = [[RK1HealthKitCharacteristicTypeAnswerFormat alloc] initWithCharacteristicType:characteristicType];
    return format;
}

- (instancetype)initWithCharacteristicType:(HKCharacteristicType *)characteristicType {
    self = [super init];
    if (self) {
        // Characteristic types are immutable, so this should be equivalent to -copy
        _characteristicType = characteristicType;
        _shouldRequestAuthorization = YES;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            RK1EqualObjects(self.characteristicType, castObject.characteristicType) &&
            RK1EqualObjects(self.defaultDate, castObject.defaultDate) &&
            RK1EqualObjects(self.minimumDate, castObject.minimumDate) &&
            RK1EqualObjects(self.maximumDate, castObject.maximumDate) &&
            RK1EqualObjects(self.calendar, castObject.calendar));
}

- (NSUInteger)hash {
    return super.hash ^ self.characteristicType.hash ^ self.defaultDate.hash ^ self.minimumDate.hash ^ self.maximumDate.hash ^ self.calendar.hash;
}

// The bare answer format implied by the quantityType or characteristicType.
// This may be RK1TextChoiceAnswerFormat, RK1NumericAnswerFormat, or RK1DateAnswerFormat.
- (RK1AnswerFormat *)impliedAnswerFormat {
    if (_impliedAnswerFormat) {
        return _impliedAnswerFormat;
    }
    
    if (_characteristicType) {
        NSString *identifier = [_characteristicType identifier];
        if ([identifier isEqualToString:HKCharacteristicTypeIdentifierBiologicalSex]) {
            NSArray *options = @[[RK1TextChoice choiceWithText:RK1LocalizedString(@"GENDER_FEMALE", nil) value: RK1HKBiologicalSexString(HKBiologicalSexFemale)],
                                 [RK1TextChoice choiceWithText:RK1LocalizedString(@"GENDER_MALE", nil) value:RK1HKBiologicalSexString(HKBiologicalSexMale)],
                                 [RK1TextChoice choiceWithText:RK1LocalizedString(@"GENDER_OTHER", nil) value:RK1HKBiologicalSexString(HKBiologicalSexOther)]
                                 ];
            RK1TextChoiceAnswerFormat *format = [RK1AnswerFormat choiceAnswerFormatWithStyle:RK1ChoiceAnswerStyleSingleChoice textChoices:options];
            _impliedAnswerFormat = format;
            
        } else if ([identifier isEqualToString:HKCharacteristicTypeIdentifierBloodType]) {
            NSArray *options = @[[RK1TextChoice choiceWithText:RK1LocalizedString(@"BLOOD_TYPE_A+", nil) value:RK1HKBloodTypeString(HKBloodTypeAPositive)],
                                 [RK1TextChoice choiceWithText:RK1LocalizedString(@"BLOOD_TYPE_A-", nil) value:RK1HKBloodTypeString(HKBloodTypeANegative)],
                                 [RK1TextChoice choiceWithText:RK1LocalizedString(@"BLOOD_TYPE_B+", nil) value:RK1HKBloodTypeString(HKBloodTypeBPositive)],
                                 [RK1TextChoice choiceWithText:RK1LocalizedString(@"BLOOD_TYPE_B-", nil) value:RK1HKBloodTypeString(HKBloodTypeBNegative)],
                                 [RK1TextChoice choiceWithText:RK1LocalizedString(@"BLOOD_TYPE_AB+", nil) value:RK1HKBloodTypeString(HKBloodTypeABPositive)],
                                 [RK1TextChoice choiceWithText:RK1LocalizedString(@"BLOOD_TYPE_AB-", nil) value:RK1HKBloodTypeString(HKBloodTypeABNegative)],
                                 [RK1TextChoice choiceWithText:RK1LocalizedString(@"BLOOD_TYPE_O+", nil) value:RK1HKBloodTypeString(HKBloodTypeOPositive)],
                                 [RK1TextChoice choiceWithText:RK1LocalizedString(@"BLOOD_TYPE_O-", nil) value:RK1HKBloodTypeString(HKBloodTypeONegative)]
                                 ];
            RK1ValuePickerAnswerFormat *format = [RK1AnswerFormat valuePickerAnswerFormatWithTextChoices:options];
            _impliedAnswerFormat = format;
            
        } else if ([identifier isEqualToString:HKCharacteristicTypeIdentifierDateOfBirth]) {
            NSCalendar *calendar = _calendar ? : [NSCalendar currentCalendar];
            NSDate *now = [NSDate date];
            NSDate *defaultDate = _defaultDate ? : [calendar dateByAddingUnit:NSCalendarUnitYear value:-35 toDate:now options:0];
            NSDate *minimumDate = _minimumDate ? : [calendar dateByAddingUnit:NSCalendarUnitYear value:-150 toDate:now options:0];
            NSDate *maximumDate = _maximumDate ? : [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:now options:0];
            
            RK1DateAnswerFormat *format = [RK1DateAnswerFormat dateAnswerFormatWithDefaultDate:defaultDate
                                                                                   minimumDate:minimumDate
                                                                                   maximumDate:maximumDate
                                                                                      calendar:calendar];
            _impliedAnswerFormat = format;
        } else if ([identifier isEqualToString:HKCharacteristicTypeIdentifierFitzpatrickSkinType]) {
            NSArray *options = @[[RK1TextChoice choiceWithText:RK1LocalizedString(@"FITZPATRICK_SKIN_TYPE_I", nil) value:@(HKFitzpatrickSkinTypeI)],
                                 [RK1TextChoice choiceWithText:RK1LocalizedString(@"FITZPATRICK_SKIN_TYPE_II", nil) value:@(HKFitzpatrickSkinTypeII)],
                                 [RK1TextChoice choiceWithText:RK1LocalizedString(@"FITZPATRICK_SKIN_TYPE_III", nil) value:@(HKFitzpatrickSkinTypeIII)],
                                 [RK1TextChoice choiceWithText:RK1LocalizedString(@"FITZPATRICK_SKIN_TYPE_IV", nil) value:@(HKFitzpatrickSkinTypeIV)],
                                 [RK1TextChoice choiceWithText:RK1LocalizedString(@"FITZPATRICK_SKIN_TYPE_V", nil) value:@(HKFitzpatrickSkinTypeV)],
                                 [RK1TextChoice choiceWithText:RK1LocalizedString(@"FITZPATRICK_SKIN_TYPE_VI", nil) value:@(HKFitzpatrickSkinTypeVI)],
                                 ];
            RK1ValuePickerAnswerFormat *format = [RK1AnswerFormat valuePickerAnswerFormatWithTextChoices:options];
            _impliedAnswerFormat = format;
        } else if (RK1_IOS_10_WATCHOS_3_AVAILABLE && [identifier isEqualToString:HKCharacteristicTypeIdentifierWheelchairUse]) {
            RK1BooleanAnswerFormat *boolAnswerFormat = [RK1AnswerFormat booleanAnswerFormat];
            _impliedAnswerFormat = boolAnswerFormat.impliedAnswerFormat;
        }
    }
    return _impliedAnswerFormat;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        RK1_DECODE_OBJ_CLASS(aDecoder, characteristicType, HKCharacteristicType);
        RK1_DECODE_OBJ_CLASS(aDecoder, defaultDate, NSDate);
        RK1_DECODE_OBJ_CLASS(aDecoder, minimumDate, NSDate);
        RK1_DECODE_OBJ_CLASS(aDecoder, maximumDate, NSDate);
        RK1_DECODE_OBJ_CLASS(aDecoder, calendar, NSCalendar);
        RK1_DECODE_BOOL(aDecoder, shouldRequestAuthorization);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_OBJ(aCoder, characteristicType);
    RK1_ENCODE_OBJ(aCoder, defaultDate);
    RK1_ENCODE_OBJ(aCoder, minimumDate);
    RK1_ENCODE_OBJ(aCoder, maximumDate);
    RK1_ENCODE_OBJ(aCoder, calendar);
    RK1_ENCODE_BOOL(aCoder, shouldRequestAuthorization);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end


@interface RK1HealthKitQuantityTypeAnswerFormat ()

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end


@implementation RK1HealthKitQuantityTypeAnswerFormat {
    RK1AnswerFormat *_impliedAnswerFormat;
    HKUnit *_userUnit;
}

+ (instancetype)new {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    RK1ThrowMethodUnavailableException();
}

- (BOOL)isHealthKitAnswerFormat {
    return YES;
}

- (HKObjectType *)healthKitObjectType {
    return _quantityType;
}

- (HKObjectType *)healthKitObjectTypeForAuthorization {
    if (self.shouldRequestAuthorization) {
        return [self healthKitObjectType];
    }
    else {
        return nil;
    }
}

- (RK1QuestionType)questionType {
    return [[self impliedAnswerFormat] questionType];
}

- (Class)questionResultClass {
    return [[self impliedAnswerFormat] questionResultClass];
}

+ (instancetype)answerFormatWithQuantityType:(HKQuantityType *)quantityType unit:(HKUnit *)unit style:(RK1NumericAnswerStyle)style {
    RK1HealthKitQuantityTypeAnswerFormat *format = [[RK1HealthKitQuantityTypeAnswerFormat alloc] initWithQuantityType:quantityType unit:unit style:style];
    return format;
}

- (instancetype)initWithQuantityType:(HKQuantityType *)quantityType unit:(HKUnit *)unit style:(RK1NumericAnswerStyle)style {
    self = [super init];
    if (self) {
        // Quantity type and unit are immutable, so this should be equivalent to -copy
        _quantityType = quantityType;
        _unit = unit;
        _numericAnswerStyle = style;
        _shouldRequestAuthorization = YES;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            RK1EqualObjects(self.quantityType, castObject.quantityType) &&
            RK1EqualObjects(self.unit, castObject.unit) &&
            (_numericAnswerStyle == castObject.numericAnswerStyle));
}

- (NSUInteger)hash {
    return super.hash ^ self.quantityType.hash ^ self.unit.hash ^ _numericAnswerStyle;
}

- (RK1AnswerFormat *)impliedAnswerFormat {
    if (_impliedAnswerFormat) {
        return _impliedAnswerFormat;
    }
    
    if (_quantityType) {
        if ([_quantityType.identifier isEqualToString:HKQuantityTypeIdentifierHeight]) {
            RK1HeightAnswerFormat *format = [RK1HeightAnswerFormat heightAnswerFormat];
            _impliedAnswerFormat = format;
            _unit = [HKUnit meterUnitWithMetricPrefix:(HKMetricPrefixCenti)];
        } else if ([_quantityType.identifier isEqualToString:HKQuantityTypeIdentifierBodyMass]) {
            RK1WeightAnswerFormat *format = [RK1WeightAnswerFormat weightAnswerFormat];
            _impliedAnswerFormat = format;
            _unit = [HKUnit gramUnitWithMetricPrefix:(HKMetricPrefixKilo)];
        } else {
            RK1NumericAnswerFormat *format = nil;
            HKUnit *unit = [self healthKitUserUnit];
            if (_numericAnswerStyle == RK1NumericAnswerStyleDecimal) {
                format = [RK1NumericAnswerFormat decimalAnswerFormatWithUnit:[unit localizedUnitString]];
            } else {
                format = [RK1NumericAnswerFormat integerAnswerFormatWithUnit:[unit localizedUnitString]];
            }
            _impliedAnswerFormat = format;
        }
    }
    return _impliedAnswerFormat;
}

- (HKUnit *)healthKitUnit {
    return _unit;
}

- (HKUnit *)healthKitUserUnit {
    return _unit ? : _userUnit;
}

- (void)setHealthKitUserUnit:(HKUnit *)unit {
    if (_unit == nil && _userUnit != unit) {
        _userUnit = unit;
     
        // Clear the implied answer format
        _impliedAnswerFormat = nil;
    }
}

- (id)resultWithIdentifier:(NSString *)identifier answer:(id)answer {
    id result = [super resultWithIdentifier:identifier answer:answer];
    if ([result isKindOfClass:[RK1NumericQuestionResult class]]) {
        RK1NumericQuestionResult *questionResult = (RK1NumericQuestionResult *)result;
        if (questionResult.unit == nil) {
            // The unit should *not* be localized.
            questionResult.unit = [self healthKitUserUnit].unitString;
        }
    }
    return result;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        RK1_DECODE_OBJ_CLASS(aDecoder, quantityType, HKQuantityType);
        RK1_DECODE_OBJ_CLASS(aDecoder, unit, HKUnit);
        RK1_DECODE_ENUM(aDecoder, numericAnswerStyle);
        RK1_DECODE_BOOL(aDecoder, shouldRequestAuthorization);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_OBJ(aCoder, quantityType);
    RK1_ENCODE_ENUM(aCoder, numericAnswerStyle);
    RK1_ENCODE_OBJ(aCoder, unit);
    RK1_ENCODE_BOOL(aCoder, shouldRequestAuthorization);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end


@implementation HKUnit (RK1Localized)

- (NSString *)localizedUnitString {
    NSUnit *unit = [[NSUnit alloc] initWithSymbol:self.unitString];
    if (unit != nil) {
        NSMeasurementFormatter *formatter = [[NSMeasurementFormatter alloc] init];
        formatter.unitOptions = NSMeasurementFormatterUnitOptionsProvidedUnit;
        return [formatter stringFromUnit:unit];
    }
    return self.unitString;
}

@end
