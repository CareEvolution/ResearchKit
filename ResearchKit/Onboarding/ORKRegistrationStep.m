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


#import "ORKRegistrationStep.h"

#import "ORKAnswerFormat_Private.h"

#import "ORKHelpers_Internal.h"


NSString *const ORKLegacyRegistrationFormItemIdentifierEmail = @"ORKRegistrationFormItemEmail";
NSString *const ORKLegacyRegistrationFormItemIdentifierPassword = @"ORKRegistrationFormItemPassword";
NSString *const ORKLegacyRegistrationFormItemIdentifierConfirmPassword = @"ORKRegistrationFormItemConfirmPassword";
NSString *const ORKLegacyRegistrationFormItemIdentifierGivenName = @"ORKRegistrationFormItemGivenName";
NSString *const ORKLegacyRegistrationFormItemIdentifierFamilyName = @"ORKRegistrationFormItemFamilyName";
NSString *const ORKLegacyRegistrationFormItemIdentifierGender = @"ORKRegistrationFormItemGender";
NSString *const ORKLegacyRegistrationFormItemIdentifierDOB = @"ORKRegistrationFormItemDOB";

static id ORKLegacyFindInArrayByFormItemId(NSArray *array, NSString *formItemIdentifier) {
    return findInArrayByKey(array, @"identifier", formItemIdentifier);
}

static NSArray <ORKLegacyFormItem*> *ORKLegacyRegistrationFormItems(ORKLegacyRegistrationStepOption options) {
    NSMutableArray *formItems = [NSMutableArray new];
    
    {
        ORKLegacyEmailAnswerFormat *answerFormat = [ORKLegacyAnswerFormat emailAnswerFormat];
        
        ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:ORKLegacyRegistrationFormItemIdentifierEmail
                                                               text:ORKLegacyLocalizedString(@"EMAIL_FORM_ITEM_TITLE", nil)
                                                       answerFormat:answerFormat
                                                           optional:NO];
        item.placeholder = ORKLegacyLocalizedString(@"EMAIL_FORM_ITEM_PLACEHOLDER", nil);
        
        [formItems addObject:item];
    }
    
    ORKLegacyFormItem *passwordFormItem;
    {
        ORKLegacyTextAnswerFormat *answerFormat = [ORKLegacyAnswerFormat textAnswerFormat];
        answerFormat.multipleLines = NO;
        answerFormat.secureTextEntry = YES;
        answerFormat.autocapitalizationType = UITextAutocapitalizationTypeNone;
        answerFormat.autocorrectionType = UITextAutocorrectionTypeNo;
        answerFormat.spellCheckingType = UITextSpellCheckingTypeNo;
        
        ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:ORKLegacyRegistrationFormItemIdentifierPassword
                                                               text:ORKLegacyLocalizedString(@"PASSWORD_FORM_ITEM_TITLE", nil)
                                                       answerFormat:answerFormat
                                                           optional:NO];
        item.placeholder = ORKLegacyLocalizedString(@"PASSWORD_FORM_ITEM_PLACEHOLDER", nil);
        passwordFormItem = item;
        
        [formItems addObject:item];
    }
    
    {
        ORKLegacyFormItem *item = [passwordFormItem confirmationAnswerFormItemWithIdentifier:ORKLegacyRegistrationFormItemIdentifierConfirmPassword
                                                text:ORKLegacyLocalizedString(@"CONFIRM_PASSWORD_FORM_ITEM_TITLE", nil)
                                                errorMessage:ORKLegacyLocalizedString(@"CONFIRM_PASSWORD_ERROR_MESSAGE", nil)];
        item.placeholder = ORKLegacyLocalizedString(@"CONFIRM_PASSWORD_FORM_ITEM_PLACEHOLDER", nil);
        
        [formItems addObject:item];
    }
    
    if (options & (ORKLegacyRegistrationStepIncludeFamilyName | ORKLegacyRegistrationStepIncludeGivenName | ORKLegacyRegistrationStepIncludeDOB | ORKLegacyRegistrationStepIncludeGender)) {
        ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithSectionTitle:ORKLegacyLocalizedString(@"ADDITIONAL_INFO_SECTION_TITLE", nil)];
        
        [formItems addObject:item];
    }
    
    if (options & ORKLegacyRegistrationStepIncludeGivenName) {
        ORKLegacyTextAnswerFormat *answerFormat = [ORKLegacyAnswerFormat textAnswerFormat];
        answerFormat.multipleLines = NO;
        
        ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:ORKLegacyRegistrationFormItemIdentifierGivenName
                                                               text:ORKLegacyLocalizedString(@"CONSENT_NAME_GIVEN", nil)
                                                       answerFormat:answerFormat
                                                           optional:NO];
        item.placeholder = ORKLegacyLocalizedString(@"GIVEN_NAME_ITEM_PLACEHOLDER", nil);
        
        [formItems addObject:item];
    }
    
    if (options & ORKLegacyRegistrationStepIncludeFamilyName) {
        ORKLegacyTextAnswerFormat *answerFormat = [ORKLegacyAnswerFormat textAnswerFormat];
        answerFormat.multipleLines = NO;
        
        ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:ORKLegacyRegistrationFormItemIdentifierFamilyName
                                                               text:ORKLegacyLocalizedString(@"CONSENT_NAME_FAMILY", nil)
                                                       answerFormat:answerFormat
                                                           optional:NO];
        item.placeholder = ORKLegacyLocalizedString(@"FAMILY_NAME_ITEM_PLACEHOLDER", nil);
        
        [formItems addObject:item];
    }
    
    // Adjust order of given name and family name form item cells based on current locale.
    if ((options & ORKLegacyRegistrationStepIncludeGivenName) && (options & ORKLegacyRegistrationStepIncludeFamilyName)) {
        if (ORKLegacyCurrentLocalePresentsFamilyNameFirst()) {
            ORKLegacyFormItem *givenNameFormItem = ORKLegacyFindInArrayByFormItemId(formItems, ORKLegacyRegistrationFormItemIdentifierGivenName);
            ORKLegacyFormItem *familyNameFormItem = ORKLegacyFindInArrayByFormItemId(formItems, ORKLegacyRegistrationFormItemIdentifierFamilyName);
            [formItems exchangeObjectAtIndex:[formItems indexOfObject:givenNameFormItem]
                           withObjectAtIndex:[formItems indexOfObject:familyNameFormItem]];
        }
    }
    
    if (options & ORKLegacyRegistrationStepIncludeGender) {
        NSArray *textChoices = @[[ORKLegacyTextChoice choiceWithText:ORKLegacyLocalizedString(@"GENDER_FEMALE", nil) value:@"female"],
                                 [ORKLegacyTextChoice choiceWithText:ORKLegacyLocalizedString(@"GENDER_MALE", nil) value:@"male"],
                                 [ORKLegacyTextChoice choiceWithText:ORKLegacyLocalizedString(@"GENDER_OTHER", nil) value:@"other"]];
        ORKLegacyValuePickerAnswerFormat *answerFormat = [ORKLegacyAnswerFormat valuePickerAnswerFormatWithTextChoices:textChoices];
        
        ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:ORKLegacyRegistrationFormItemIdentifierGender
                                                               text:ORKLegacyLocalizedString(@"GENDER_FORM_ITEM_TITLE", nil)
                                                       answerFormat:answerFormat
                                                           optional:NO];
        item.placeholder = ORKLegacyLocalizedString(@"GENDER_FORM_ITEM_PLACEHOLDER", nil);
        
        [formItems addObject:item];
    }
    
    if (options & ORKLegacyRegistrationStepIncludeDOB) {
        // Calculate default date (20 years from now).
        NSDate *defaultDate = [[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian] dateByAddingUnit:NSCalendarUnitYear
                                                                       value:-20
                                                                      toDate:[NSDate date]
                                                                     options:(NSCalendarOptions)0];
        
        ORKLegacyDateAnswerFormat *answerFormat = [ORKLegacyAnswerFormat dateAnswerFormatWithDefaultDate:defaultDate
                                                                                 minimumDate:nil
                                                                                 maximumDate:[NSDate date]
                                                                                    calendar:[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian]];
        
        ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:ORKLegacyRegistrationFormItemIdentifierDOB
                                                               text:ORKLegacyLocalizedString(@"DOB_FORM_ITEM_TITLE", nil)
                                                       answerFormat:answerFormat
                                                           optional:NO];
        item.placeholder = ORKLegacyLocalizedString(@"DOB_FORM_ITEM_PLACEHOLDER", nil);
        
        [formItems addObject:item];
    }
    
    return formItems;
}


@implementation ORKLegacyRegistrationStep

- (instancetype)initWithIdentifier:(NSString *)identifier
                             title:(NSString *)title
                              text:(NSString *)text
passcodeValidationRegularExpression:(NSRegularExpression *)passcodeValidationRegularExpression
            passcodeInvalidMessage:(NSString *)passcodeInvalidMessage
                           options:(ORKLegacyRegistrationStepOption)options {
    self = [super initWithIdentifier:identifier title:title text:text];
    if (self) {
        _options = options;
        self.passcodeValidationRegularExpression = passcodeValidationRegularExpression;
        self.passcodeInvalidMessage = passcodeInvalidMessage;
        self.optional = NO;
    }
    return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier
                             title:(NSString *)title
                              text:(NSString *)text
                           options:(ORKLegacyRegistrationStepOption)options {
    return [self initWithIdentifier:identifier
                              title:title
                               text:text
passcodeValidationRegularExpression:nil
             passcodeInvalidMessage:nil
                            options:options];
}

- (instancetype)initWithIdentifier:(NSString *)identifier
                             title:(NSString *)title
                              text:(NSString *)text {
    return [self initWithIdentifier:identifier
                              title:title
                               text:text
                            options:ORKLegacyRegistrationStepDefault];
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    return [self initWithIdentifier:identifier
                              title:nil
                               text:nil];
}

- (ORKLegacyTextAnswerFormat *)passwordAnswerFormat {
    ORKLegacyFormItem *passwordFormItem = ORKLegacyFindInArrayByFormItemId(self.formItems, ORKLegacyRegistrationFormItemIdentifierPassword);
    ORKLegacyTextAnswerFormat *passwordAnswerFormat = (ORKLegacyTextAnswerFormat *)passwordFormItem.answerFormat;
    return passwordAnswerFormat;
}

- (NSArray <ORKLegacyFormItem *> *)formItems {
    if (![super formItems]) {
        self.formItems = ORKLegacyRegistrationFormItems(_options);
    }
    
    ORKLegacyFormItem *dobFormItem = ORKLegacyFindInArrayByFormItemId([super formItems], ORKLegacyRegistrationFormItemIdentifierDOB);
    ORKLegacyDateAnswerFormat *originalAnswerFormat = (ORKLegacyDateAnswerFormat *)dobFormItem.answerFormat;
    ORKLegacyDateAnswerFormat *modifiedAnswerFormat = [ORKLegacyAnswerFormat dateAnswerFormatWithDefaultDate:originalAnswerFormat.defaultDate
                                                                                     minimumDate:originalAnswerFormat.minimumDate
                                                                                     maximumDate:[NSDate date]
                                                                                        calendar:originalAnswerFormat.calendar];

    dobFormItem = [[ORKLegacyFormItem alloc] initWithIdentifier:ORKLegacyRegistrationFormItemIdentifierDOB
                                                     text:ORKLegacyLocalizedString(@"DOB_FORM_ITEM_TITLE", nil)
                                             answerFormat:modifiedAnswerFormat
                                                 optional:NO];
    dobFormItem.placeholder = ORKLegacyLocalizedString(@"DOB_FORM_ITEM_PLACEHOLDER", nil);
    
    return [super formItems];
}

- (NSRegularExpression *)passcodeValidationRegularExpression {
    return [self passwordAnswerFormat].validationRegularExpression;
}

- (void)setPasscodeValidationRegularExpression:(NSRegularExpression *)passcodeValidationRegularExpression {
    [self passwordAnswerFormat].validationRegularExpression = passcodeValidationRegularExpression;
}

- (NSString *)passcodeInvalidMessage {
    return [self passwordAnswerFormat].invalidMessage;
}

- (void)setPasscodeInvalidMessage:(NSString *)passcodeInvalidMessage {
    [self passwordAnswerFormat].invalidMessage = passcodeInvalidMessage;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        // `passcodeValidationRegularExpression` and `passcodeInvalidMessage` are transparent
        // properties. The corresponding decoding for these properties takes place in the answer
        // format's `-initWithCode:` method, invoked from super's (ORKLegacyFormStep) implementation.
        ORKLegacy_DECODE_INTEGER(aDecoder, options);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    
    // `passcodeValidationRegularExpression` and `passcodeInvalidMessage` are transparent
    // properties. The corresponding encoding for these properties takes place in the answer format's
    // `-encodeWithCoder:` method, invoked from super's (ORKLegacyFormStep) implementation.
    ORKLegacy_ENCODE_INTEGER(aCoder, options);
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyRegistrationStep *step = [super copyWithZone:zone];
    
    // `passcodeValidationRegularExpression` and `passcodeInvalidMessage` are transparent
    // properties. The corresponding copying of these properties happens in the answer format
    // `-copyWithZone:` method, invoked from the super's (ORKLegacyFormStep) implementation.
    step->_options = self.options;
    return step;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    // `passcodeValidationRegularExpression` and `passcodeInvalidMessage` are transparent
    // properties. The corresponding equality test for these properties takes place in the answer
    // format's `-isEqual:` method, invoked from super's (ORKLegacyFormStep) implementation.
    __typeof(self) castObject = object;
    return (isParentSame &&
            self.options == castObject.options);
}

@end
