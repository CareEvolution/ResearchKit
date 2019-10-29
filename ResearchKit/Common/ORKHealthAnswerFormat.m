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


#import "ORKHealthAnswerFormat.h"

#import "ORKAnswerFormat_Internal.h"

#import "ORKHelpers_Internal.h"

#import "ORKResult.h"


#pragma mark - ORKLegacyHealthAnswerFormat

ORKLegacyBiologicalSexIdentifier const ORKLegacyBiologicalSexIdentifierFemale = @"HKBiologicalSexFemale";
ORKLegacyBiologicalSexIdentifier const ORKLegacyBiologicalSexIdentifierMale = @"HKBiologicalSexMale";
ORKLegacyBiologicalSexIdentifier const ORKLegacyBiologicalSexIdentifierOther = @"HKBiologicalSexOther";

NSString *ORKLegacyHKBiologicalSexString(HKBiologicalSex biologicalSex) {
    NSString *string = nil;
    switch (biologicalSex) {
        case HKBiologicalSexFemale: string = ORKLegacyBiologicalSexIdentifierFemale; break;
        case HKBiologicalSexMale:   string = ORKLegacyBiologicalSexIdentifierMale;   break;
        case HKBiologicalSexOther:  string = ORKLegacyBiologicalSexIdentifierOther;  break;
        case HKBiologicalSexNotSet: break;
    }
    return string;
}

ORKLegacyBloodTypeIdentifier const ORKLegacyBloodTypeIdentifierAPositive = @"HKBloodTypeAPositive";
ORKLegacyBloodTypeIdentifier const ORKLegacyBloodTypeIdentifierANegative = @"HKBloodTypeANegative";
ORKLegacyBloodTypeIdentifier const ORKLegacyBloodTypeIdentifierBPositive = @"HKBloodTypeBPositive";
ORKLegacyBloodTypeIdentifier const ORKLegacyBloodTypeIdentifierBNegative = @"HKBloodTypeBNegative";
ORKLegacyBloodTypeIdentifier const ORKLegacyBloodTypeIdentifierABPositive = @"HKBloodTypeABPositive";
ORKLegacyBloodTypeIdentifier const ORKLegacyBloodTypeIdentifierABNegative = @"HKBloodTypeABNegative";
ORKLegacyBloodTypeIdentifier const ORKLegacyBloodTypeIdentifierOPositive = @"HKBloodTypeOPositive";
ORKLegacyBloodTypeIdentifier const ORKLegacyBloodTypeIdentifierONegative = @"HKBloodTypeONegative";

NSString *ORKLegacyHKBloodTypeString(HKBloodType bloodType) {
    NSString *string = nil;
    switch (bloodType) {
        case HKBloodTypeAPositive:  string = ORKLegacyBloodTypeIdentifierAPositive;   break;
        case HKBloodTypeANegative:  string = ORKLegacyBloodTypeIdentifierANegative;   break;
        case HKBloodTypeBPositive:  string = ORKLegacyBloodTypeIdentifierBPositive;   break;
        case HKBloodTypeBNegative:  string = ORKLegacyBloodTypeIdentifierBNegative;   break;
        case HKBloodTypeABPositive: string = ORKLegacyBloodTypeIdentifierABPositive;  break;
        case HKBloodTypeABNegative: string = ORKLegacyBloodTypeIdentifierABNegative;  break;
        case HKBloodTypeOPositive:  string = ORKLegacyBloodTypeIdentifierOPositive;   break;
        case HKBloodTypeONegative:  string = ORKLegacyBloodTypeIdentifierONegative;   break;
        case HKBloodTypeNotSet: break;
    }
    return string;
}

@interface ORKLegacyHealthKitCharacteristicTypeAnswerFormat ()

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end


@implementation ORKLegacyHealthKitCharacteristicTypeAnswerFormat {
    ORKLegacyAnswerFormat *_impliedAnswerFormat;
}

+ (instancetype)new {
    ORKLegacyThrowMethodUnavailableException();
}

- (instancetype)init {
    ORKLegacyThrowMethodUnavailableException();
}

- (BOOL)isHealthKitAnswerFormat {
    return YES;
}

- (ORKLegacyQuestionType)questionType {
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
    ORKLegacyHealthKitCharacteristicTypeAnswerFormat *format = [[ORKLegacyHealthKitCharacteristicTypeAnswerFormat alloc] initWithCharacteristicType:characteristicType];
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
            ORKLegacyEqualObjects(self.characteristicType, castObject.characteristicType) &&
            ORKLegacyEqualObjects(self.defaultDate, castObject.defaultDate) &&
            ORKLegacyEqualObjects(self.minimumDate, castObject.minimumDate) &&
            ORKLegacyEqualObjects(self.maximumDate, castObject.maximumDate) &&
            ORKLegacyEqualObjects(self.calendar, castObject.calendar));
}

- (NSUInteger)hash {
    return super.hash ^ self.characteristicType.hash ^ self.defaultDate.hash ^ self.minimumDate.hash ^ self.maximumDate.hash ^ self.calendar.hash;
}

// The bare answer format implied by the quantityType or characteristicType.
// This may be ORKLegacyTextChoiceAnswerFormat, ORKLegacyNumericAnswerFormat, or ORKLegacyDateAnswerFormat.
- (ORKLegacyAnswerFormat *)impliedAnswerFormat {
    if (_impliedAnswerFormat) {
        return _impliedAnswerFormat;
    }
    
    if (_characteristicType) {
        NSString *identifier = [_characteristicType identifier];
        if ([identifier isEqualToString:HKCharacteristicTypeIdentifierBiologicalSex]) {
            NSArray *options = @[[ORKLegacyTextChoice choiceWithText:ORKLegacyLocalizedString(@"GENDER_FEMALE", nil) value: ORKLegacyHKBiologicalSexString(HKBiologicalSexFemale)],
                                 [ORKLegacyTextChoice choiceWithText:ORKLegacyLocalizedString(@"GENDER_MALE", nil) value:ORKLegacyHKBiologicalSexString(HKBiologicalSexMale)],
                                 [ORKLegacyTextChoice choiceWithText:ORKLegacyLocalizedString(@"GENDER_OTHER", nil) value:ORKLegacyHKBiologicalSexString(HKBiologicalSexOther)]
                                 ];
            ORKLegacyTextChoiceAnswerFormat *format = [ORKLegacyAnswerFormat choiceAnswerFormatWithStyle:ORKLegacyChoiceAnswerStyleSingleChoice textChoices:options];
            _impliedAnswerFormat = format;
            
        } else if ([identifier isEqualToString:HKCharacteristicTypeIdentifierBloodType]) {
            NSArray *options = @[[ORKLegacyTextChoice choiceWithText:ORKLegacyLocalizedString(@"BLOOD_TYPE_A+", nil) value:ORKLegacyHKBloodTypeString(HKBloodTypeAPositive)],
                                 [ORKLegacyTextChoice choiceWithText:ORKLegacyLocalizedString(@"BLOOD_TYPE_A-", nil) value:ORKLegacyHKBloodTypeString(HKBloodTypeANegative)],
                                 [ORKLegacyTextChoice choiceWithText:ORKLegacyLocalizedString(@"BLOOD_TYPE_B+", nil) value:ORKLegacyHKBloodTypeString(HKBloodTypeBPositive)],
                                 [ORKLegacyTextChoice choiceWithText:ORKLegacyLocalizedString(@"BLOOD_TYPE_B-", nil) value:ORKLegacyHKBloodTypeString(HKBloodTypeBNegative)],
                                 [ORKLegacyTextChoice choiceWithText:ORKLegacyLocalizedString(@"BLOOD_TYPE_AB+", nil) value:ORKLegacyHKBloodTypeString(HKBloodTypeABPositive)],
                                 [ORKLegacyTextChoice choiceWithText:ORKLegacyLocalizedString(@"BLOOD_TYPE_AB-", nil) value:ORKLegacyHKBloodTypeString(HKBloodTypeABNegative)],
                                 [ORKLegacyTextChoice choiceWithText:ORKLegacyLocalizedString(@"BLOOD_TYPE_O+", nil) value:ORKLegacyHKBloodTypeString(HKBloodTypeOPositive)],
                                 [ORKLegacyTextChoice choiceWithText:ORKLegacyLocalizedString(@"BLOOD_TYPE_O-", nil) value:ORKLegacyHKBloodTypeString(HKBloodTypeONegative)]
                                 ];
            ORKLegacyValuePickerAnswerFormat *format = [ORKLegacyAnswerFormat valuePickerAnswerFormatWithTextChoices:options];
            _impliedAnswerFormat = format;
            
        } else if ([identifier isEqualToString:HKCharacteristicTypeIdentifierDateOfBirth]) {
            NSCalendar *calendar = _calendar ? : [NSCalendar currentCalendar];
            NSDate *now = [NSDate date];
            NSDate *defaultDate = _defaultDate ? : [calendar dateByAddingUnit:NSCalendarUnitYear value:-35 toDate:now options:0];
            NSDate *minimumDate = _minimumDate ? : [calendar dateByAddingUnit:NSCalendarUnitYear value:-150 toDate:now options:0];
            NSDate *maximumDate = _maximumDate ? : [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:now options:0];
            
            ORKLegacyDateAnswerFormat *format = [ORKLegacyDateAnswerFormat dateAnswerFormatWithDefaultDate:defaultDate
                                                                                   minimumDate:minimumDate
                                                                                   maximumDate:maximumDate
                                                                                      calendar:calendar];
            _impliedAnswerFormat = format;
        } else if ([identifier isEqualToString:HKCharacteristicTypeIdentifierFitzpatrickSkinType]) {
            NSArray *options = @[[ORKLegacyTextChoice choiceWithText:ORKLegacyLocalizedString(@"FITZPATRICK_SKIN_TYPE_I", nil) value:@(HKFitzpatrickSkinTypeI)],
                                 [ORKLegacyTextChoice choiceWithText:ORKLegacyLocalizedString(@"FITZPATRICK_SKIN_TYPE_II", nil) value:@(HKFitzpatrickSkinTypeII)],
                                 [ORKLegacyTextChoice choiceWithText:ORKLegacyLocalizedString(@"FITZPATRICK_SKIN_TYPE_III", nil) value:@(HKFitzpatrickSkinTypeIII)],
                                 [ORKLegacyTextChoice choiceWithText:ORKLegacyLocalizedString(@"FITZPATRICK_SKIN_TYPE_IV", nil) value:@(HKFitzpatrickSkinTypeIV)],
                                 [ORKLegacyTextChoice choiceWithText:ORKLegacyLocalizedString(@"FITZPATRICK_SKIN_TYPE_V", nil) value:@(HKFitzpatrickSkinTypeV)],
                                 [ORKLegacyTextChoice choiceWithText:ORKLegacyLocalizedString(@"FITZPATRICK_SKIN_TYPE_VI", nil) value:@(HKFitzpatrickSkinTypeVI)],
                                 ];
            ORKLegacyValuePickerAnswerFormat *format = [ORKLegacyAnswerFormat valuePickerAnswerFormatWithTextChoices:options];
            _impliedAnswerFormat = format;
        } else if (ORKLegacy_IOS_10_WATCHOS_3_AVAILABLE && [identifier isEqualToString:HKCharacteristicTypeIdentifierWheelchairUse]) {
            ORKLegacyBooleanAnswerFormat *boolAnswerFormat = [ORKLegacyAnswerFormat booleanAnswerFormat];
            _impliedAnswerFormat = boolAnswerFormat.impliedAnswerFormat;
        }
    }
    return _impliedAnswerFormat;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, characteristicType, HKCharacteristicType);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, defaultDate, NSDate);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, minimumDate, NSDate);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, maximumDate, NSDate);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, calendar, NSCalendar);
        ORKLegacy_DECODE_BOOL(aDecoder, shouldRequestAuthorization);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, characteristicType);
    ORKLegacy_ENCODE_OBJ(aCoder, defaultDate);
    ORKLegacy_ENCODE_OBJ(aCoder, minimumDate);
    ORKLegacy_ENCODE_OBJ(aCoder, maximumDate);
    ORKLegacy_ENCODE_OBJ(aCoder, calendar);
    ORKLegacy_ENCODE_BOOL(aCoder, shouldRequestAuthorization);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end


@interface ORKLegacyHealthKitQuantityTypeAnswerFormat ()

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end


@implementation ORKLegacyHealthKitQuantityTypeAnswerFormat {
    ORKLegacyAnswerFormat *_impliedAnswerFormat;
    HKUnit *_userUnit;
}

+ (instancetype)new {
    ORKLegacyThrowMethodUnavailableException();
}

- (instancetype)init {
    ORKLegacyThrowMethodUnavailableException();
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

- (ORKLegacyQuestionType)questionType {
    return [[self impliedAnswerFormat] questionType];
}

- (Class)questionResultClass {
    return [[self impliedAnswerFormat] questionResultClass];
}

+ (instancetype)answerFormatWithQuantityType:(HKQuantityType *)quantityType unit:(HKUnit *)unit style:(ORKLegacyNumericAnswerStyle)style {
    ORKLegacyHealthKitQuantityTypeAnswerFormat *format = [[ORKLegacyHealthKitQuantityTypeAnswerFormat alloc] initWithQuantityType:quantityType unit:unit style:style];
    return format;
}

- (instancetype)initWithQuantityType:(HKQuantityType *)quantityType unit:(HKUnit *)unit style:(ORKLegacyNumericAnswerStyle)style {
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
            ORKLegacyEqualObjects(self.quantityType, castObject.quantityType) &&
            ORKLegacyEqualObjects(self.unit, castObject.unit) &&
            (_numericAnswerStyle == castObject.numericAnswerStyle));
}

- (NSUInteger)hash {
    return super.hash ^ self.quantityType.hash ^ self.unit.hash ^ _numericAnswerStyle;
}

- (ORKLegacyAnswerFormat *)impliedAnswerFormat {
    if (_impliedAnswerFormat) {
        return _impliedAnswerFormat;
    }
    
    if (_quantityType) {
        if ([_quantityType.identifier isEqualToString:HKQuantityTypeIdentifierHeight]) {
            ORKLegacyHeightAnswerFormat *format = [ORKLegacyHeightAnswerFormat heightAnswerFormat];
            _impliedAnswerFormat = format;
            _unit = [HKUnit meterUnitWithMetricPrefix:(HKMetricPrefixCenti)];
        } else if ([_quantityType.identifier isEqualToString:HKQuantityTypeIdentifierBodyMass]) {
            ORKLegacyWeightAnswerFormat *format = [ORKLegacyWeightAnswerFormat weightAnswerFormat];
            _impliedAnswerFormat = format;
            _unit = [HKUnit gramUnitWithMetricPrefix:(HKMetricPrefixKilo)];
        } else {
            ORKLegacyNumericAnswerFormat *format = nil;
            HKUnit *unit = [self healthKitUserUnit];
            if (_numericAnswerStyle == ORKLegacyNumericAnswerStyleDecimal) {
                format = [ORKLegacyNumericAnswerFormat decimalAnswerFormatWithUnit:[unit localizedUnitString]];
            } else {
                format = [ORKLegacyNumericAnswerFormat integerAnswerFormatWithUnit:[unit localizedUnitString]];
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
    if ([result isKindOfClass:[ORKLegacyNumericQuestionResult class]]) {
        ORKLegacyNumericQuestionResult *questionResult = (ORKLegacyNumericQuestionResult *)result;
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
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, quantityType, HKQuantityType);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, unit, HKUnit);
        ORKLegacy_DECODE_ENUM(aDecoder, numericAnswerStyle);
        ORKLegacy_DECODE_BOOL(aDecoder, shouldRequestAuthorization);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, quantityType);
    ORKLegacy_ENCODE_ENUM(aCoder, numericAnswerStyle);
    ORKLegacy_ENCODE_OBJ(aCoder, unit);
    ORKLegacy_ENCODE_BOOL(aCoder, shouldRequestAuthorization);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end


@implementation HKUnit (ORKLegacyLocalized)

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
