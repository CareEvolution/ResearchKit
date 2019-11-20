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


#import "ORK1HealthAnswerFormat.h"

#import "ORK1AnswerFormat_Internal.h"

#import "ORK1Helpers_Internal.h"

#import "ORK1Result.h"


#pragma mark - ORK1HealthAnswerFormat

ORK1BiologicalSexIdentifier const ORK1BiologicalSexIdentifierFemale = @"HKBiologicalSexFemale";
ORK1BiologicalSexIdentifier const ORK1BiologicalSexIdentifierMale = @"HKBiologicalSexMale";
ORK1BiologicalSexIdentifier const ORK1BiologicalSexIdentifierOther = @"HKBiologicalSexOther";

NSString *ORK1HKBiologicalSexString(HKBiologicalSex biologicalSex) {
    NSString *string = nil;
    switch (biologicalSex) {
        case HKBiologicalSexFemale: string = ORK1BiologicalSexIdentifierFemale; break;
        case HKBiologicalSexMale:   string = ORK1BiologicalSexIdentifierMale;   break;
        case HKBiologicalSexOther:  string = ORK1BiologicalSexIdentifierOther;  break;
        case HKBiologicalSexNotSet: break;
    }
    return string;
}

ORK1BloodTypeIdentifier const ORK1BloodTypeIdentifierAPositive = @"HKBloodTypeAPositive";
ORK1BloodTypeIdentifier const ORK1BloodTypeIdentifierANegative = @"HKBloodTypeANegative";
ORK1BloodTypeIdentifier const ORK1BloodTypeIdentifierBPositive = @"HKBloodTypeBPositive";
ORK1BloodTypeIdentifier const ORK1BloodTypeIdentifierBNegative = @"HKBloodTypeBNegative";
ORK1BloodTypeIdentifier const ORK1BloodTypeIdentifierABPositive = @"HKBloodTypeABPositive";
ORK1BloodTypeIdentifier const ORK1BloodTypeIdentifierABNegative = @"HKBloodTypeABNegative";
ORK1BloodTypeIdentifier const ORK1BloodTypeIdentifierOPositive = @"HKBloodTypeOPositive";
ORK1BloodTypeIdentifier const ORK1BloodTypeIdentifierONegative = @"HKBloodTypeONegative";

NSString *ORK1HKBloodTypeString(HKBloodType bloodType) {
    NSString *string = nil;
    switch (bloodType) {
        case HKBloodTypeAPositive:  string = ORK1BloodTypeIdentifierAPositive;   break;
        case HKBloodTypeANegative:  string = ORK1BloodTypeIdentifierANegative;   break;
        case HKBloodTypeBPositive:  string = ORK1BloodTypeIdentifierBPositive;   break;
        case HKBloodTypeBNegative:  string = ORK1BloodTypeIdentifierBNegative;   break;
        case HKBloodTypeABPositive: string = ORK1BloodTypeIdentifierABPositive;  break;
        case HKBloodTypeABNegative: string = ORK1BloodTypeIdentifierABNegative;  break;
        case HKBloodTypeOPositive:  string = ORK1BloodTypeIdentifierOPositive;   break;
        case HKBloodTypeONegative:  string = ORK1BloodTypeIdentifierONegative;   break;
        case HKBloodTypeNotSet: break;
    }
    return string;
}

@interface ORK1HealthKitCharacteristicTypeAnswerFormat ()

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end


@implementation ORK1HealthKitCharacteristicTypeAnswerFormat {
    ORK1AnswerFormat *_impliedAnswerFormat;
}

+ (instancetype)new {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    ORK1ThrowMethodUnavailableException();
}

- (BOOL)isHealthKitAnswerFormat {
    return YES;
}

- (ORK1QuestionType)questionType {
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
    ORK1HealthKitCharacteristicTypeAnswerFormat *format = [[ORK1HealthKitCharacteristicTypeAnswerFormat alloc] initWithCharacteristicType:characteristicType];
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
            ORK1EqualObjects(self.characteristicType, castObject.characteristicType) &&
            ORK1EqualObjects(self.defaultDate, castObject.defaultDate) &&
            ORK1EqualObjects(self.minimumDate, castObject.minimumDate) &&
            ORK1EqualObjects(self.maximumDate, castObject.maximumDate) &&
            ORK1EqualObjects(self.calendar, castObject.calendar));
}

- (NSUInteger)hash {
    return super.hash ^ self.characteristicType.hash ^ self.defaultDate.hash ^ self.minimumDate.hash ^ self.maximumDate.hash ^ self.calendar.hash;
}

// The bare answer format implied by the quantityType or characteristicType.
// This may be ORK1TextChoiceAnswerFormat, ORK1NumericAnswerFormat, or ORK1DateAnswerFormat.
- (ORK1AnswerFormat *)impliedAnswerFormat {
    if (_impliedAnswerFormat) {
        return _impliedAnswerFormat;
    }
    
    if (_characteristicType) {
        NSString *identifier = [_characteristicType identifier];
        if ([identifier isEqualToString:HKCharacteristicTypeIdentifierBiologicalSex]) {
            NSArray *options = @[[ORK1TextChoice choiceWithText:ORK1LocalizedString(@"GENDER_FEMALE", nil) value: ORK1HKBiologicalSexString(HKBiologicalSexFemale)],
                                 [ORK1TextChoice choiceWithText:ORK1LocalizedString(@"GENDER_MALE", nil) value:ORK1HKBiologicalSexString(HKBiologicalSexMale)],
                                 [ORK1TextChoice choiceWithText:ORK1LocalizedString(@"GENDER_OTHER", nil) value:ORK1HKBiologicalSexString(HKBiologicalSexOther)]
                                 ];
            ORK1TextChoiceAnswerFormat *format = [ORK1AnswerFormat choiceAnswerFormatWithStyle:ORK1ChoiceAnswerStyleSingleChoice textChoices:options];
            _impliedAnswerFormat = format;
            
        } else if ([identifier isEqualToString:HKCharacteristicTypeIdentifierBloodType]) {
            NSArray *options = @[[ORK1TextChoice choiceWithText:ORK1LocalizedString(@"BLOOD_TYPE_A+", nil) value:ORK1HKBloodTypeString(HKBloodTypeAPositive)],
                                 [ORK1TextChoice choiceWithText:ORK1LocalizedString(@"BLOOD_TYPE_A-", nil) value:ORK1HKBloodTypeString(HKBloodTypeANegative)],
                                 [ORK1TextChoice choiceWithText:ORK1LocalizedString(@"BLOOD_TYPE_B+", nil) value:ORK1HKBloodTypeString(HKBloodTypeBPositive)],
                                 [ORK1TextChoice choiceWithText:ORK1LocalizedString(@"BLOOD_TYPE_B-", nil) value:ORK1HKBloodTypeString(HKBloodTypeBNegative)],
                                 [ORK1TextChoice choiceWithText:ORK1LocalizedString(@"BLOOD_TYPE_AB+", nil) value:ORK1HKBloodTypeString(HKBloodTypeABPositive)],
                                 [ORK1TextChoice choiceWithText:ORK1LocalizedString(@"BLOOD_TYPE_AB-", nil) value:ORK1HKBloodTypeString(HKBloodTypeABNegative)],
                                 [ORK1TextChoice choiceWithText:ORK1LocalizedString(@"BLOOD_TYPE_O+", nil) value:ORK1HKBloodTypeString(HKBloodTypeOPositive)],
                                 [ORK1TextChoice choiceWithText:ORK1LocalizedString(@"BLOOD_TYPE_O-", nil) value:ORK1HKBloodTypeString(HKBloodTypeONegative)]
                                 ];
            ORK1ValuePickerAnswerFormat *format = [ORK1AnswerFormat valuePickerAnswerFormatWithTextChoices:options];
            _impliedAnswerFormat = format;
            
        } else if ([identifier isEqualToString:HKCharacteristicTypeIdentifierDateOfBirth]) {
            NSCalendar *calendar = _calendar ? : [NSCalendar currentCalendar];
            NSDate *now = [NSDate date];
            NSDate *defaultDate = _defaultDate ? : [calendar dateByAddingUnit:NSCalendarUnitYear value:-35 toDate:now options:0];
            NSDate *minimumDate = _minimumDate ? : [calendar dateByAddingUnit:NSCalendarUnitYear value:-150 toDate:now options:0];
            NSDate *maximumDate = _maximumDate ? : [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:now options:0];
            
            ORK1DateAnswerFormat *format = [ORK1DateAnswerFormat dateAnswerFormatWithDefaultDate:defaultDate
                                                                                   minimumDate:minimumDate
                                                                                   maximumDate:maximumDate
                                                                                      calendar:calendar];
            _impliedAnswerFormat = format;
        } else if ([identifier isEqualToString:HKCharacteristicTypeIdentifierFitzpatrickSkinType]) {
            NSArray *options = @[[ORK1TextChoice choiceWithText:ORK1LocalizedString(@"FITZPATRICK_SKIN_TYPE_I", nil) value:@(HKFitzpatrickSkinTypeI)],
                                 [ORK1TextChoice choiceWithText:ORK1LocalizedString(@"FITZPATRICK_SKIN_TYPE_II", nil) value:@(HKFitzpatrickSkinTypeII)],
                                 [ORK1TextChoice choiceWithText:ORK1LocalizedString(@"FITZPATRICK_SKIN_TYPE_III", nil) value:@(HKFitzpatrickSkinTypeIII)],
                                 [ORK1TextChoice choiceWithText:ORK1LocalizedString(@"FITZPATRICK_SKIN_TYPE_IV", nil) value:@(HKFitzpatrickSkinTypeIV)],
                                 [ORK1TextChoice choiceWithText:ORK1LocalizedString(@"FITZPATRICK_SKIN_TYPE_V", nil) value:@(HKFitzpatrickSkinTypeV)],
                                 [ORK1TextChoice choiceWithText:ORK1LocalizedString(@"FITZPATRICK_SKIN_TYPE_VI", nil) value:@(HKFitzpatrickSkinTypeVI)],
                                 ];
            ORK1ValuePickerAnswerFormat *format = [ORK1AnswerFormat valuePickerAnswerFormatWithTextChoices:options];
            _impliedAnswerFormat = format;
        } else if (ORK1_IOS_10_WATCHOS_3_AVAILABLE && [identifier isEqualToString:HKCharacteristicTypeIdentifierWheelchairUse]) {
            ORK1BooleanAnswerFormat *boolAnswerFormat = [ORK1AnswerFormat booleanAnswerFormat];
            _impliedAnswerFormat = boolAnswerFormat.impliedAnswerFormat;
        }
    }
    return _impliedAnswerFormat;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, characteristicType, HKCharacteristicType);
        ORK1_DECODE_OBJ_CLASS(aDecoder, defaultDate, NSDate);
        ORK1_DECODE_OBJ_CLASS(aDecoder, minimumDate, NSDate);
        ORK1_DECODE_OBJ_CLASS(aDecoder, maximumDate, NSDate);
        ORK1_DECODE_OBJ_CLASS(aDecoder, calendar, NSCalendar);
        ORK1_DECODE_BOOL(aDecoder, shouldRequestAuthorization);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, characteristicType);
    ORK1_ENCODE_OBJ(aCoder, defaultDate);
    ORK1_ENCODE_OBJ(aCoder, minimumDate);
    ORK1_ENCODE_OBJ(aCoder, maximumDate);
    ORK1_ENCODE_OBJ(aCoder, calendar);
    ORK1_ENCODE_BOOL(aCoder, shouldRequestAuthorization);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end


@interface ORK1HealthKitQuantityTypeAnswerFormat ()

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end


@implementation ORK1HealthKitQuantityTypeAnswerFormat {
    ORK1AnswerFormat *_impliedAnswerFormat;
    HKUnit *_userUnit;
}

+ (instancetype)new {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    ORK1ThrowMethodUnavailableException();
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

- (ORK1QuestionType)questionType {
    return [[self impliedAnswerFormat] questionType];
}

- (Class)questionResultClass {
    return [[self impliedAnswerFormat] questionResultClass];
}

+ (instancetype)answerFormatWithQuantityType:(HKQuantityType *)quantityType unit:(HKUnit *)unit style:(ORK1NumericAnswerStyle)style {
    ORK1HealthKitQuantityTypeAnswerFormat *format = [[ORK1HealthKitQuantityTypeAnswerFormat alloc] initWithQuantityType:quantityType unit:unit style:style];
    return format;
}

- (instancetype)initWithQuantityType:(HKQuantityType *)quantityType unit:(HKUnit *)unit style:(ORK1NumericAnswerStyle)style {
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
            ORK1EqualObjects(self.quantityType, castObject.quantityType) &&
            ORK1EqualObjects(self.unit, castObject.unit) &&
            (_numericAnswerStyle == castObject.numericAnswerStyle));
}

- (NSUInteger)hash {
    return super.hash ^ self.quantityType.hash ^ self.unit.hash ^ _numericAnswerStyle;
}

- (ORK1AnswerFormat *)impliedAnswerFormat {
    if (_impliedAnswerFormat) {
        return _impliedAnswerFormat;
    }
    
    if (_quantityType) {
        if ([_quantityType.identifier isEqualToString:HKQuantityTypeIdentifierHeight]) {
            ORK1HeightAnswerFormat *format = [ORK1HeightAnswerFormat heightAnswerFormat];
            _impliedAnswerFormat = format;
            _unit = [HKUnit meterUnitWithMetricPrefix:(HKMetricPrefixCenti)];
        } else if ([_quantityType.identifier isEqualToString:HKQuantityTypeIdentifierBodyMass]) {
            ORK1WeightAnswerFormat *format = [ORK1WeightAnswerFormat weightAnswerFormat];
            _impliedAnswerFormat = format;
            _unit = [HKUnit gramUnitWithMetricPrefix:(HKMetricPrefixKilo)];
        } else {
            ORK1NumericAnswerFormat *format = nil;
            HKUnit *unit = [self healthKitUserUnit];
            if (_numericAnswerStyle == ORK1NumericAnswerStyleDecimal) {
                format = [ORK1NumericAnswerFormat decimalAnswerFormatWithUnit:[unit localizedUnitString]];
            } else {
                format = [ORK1NumericAnswerFormat integerAnswerFormatWithUnit:[unit localizedUnitString]];
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
    if ([result isKindOfClass:[ORK1NumericQuestionResult class]]) {
        ORK1NumericQuestionResult *questionResult = (ORK1NumericQuestionResult *)result;
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
        ORK1_DECODE_OBJ_CLASS(aDecoder, quantityType, HKQuantityType);
        ORK1_DECODE_OBJ_CLASS(aDecoder, unit, HKUnit);
        ORK1_DECODE_ENUM(aDecoder, numericAnswerStyle);
        ORK1_DECODE_BOOL(aDecoder, shouldRequestAuthorization);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, quantityType);
    ORK1_ENCODE_ENUM(aCoder, numericAnswerStyle);
    ORK1_ENCODE_OBJ(aCoder, unit);
    ORK1_ENCODE_BOOL(aCoder, shouldRequestAuthorization);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end


@implementation HKUnit (ORK1Localized)

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
