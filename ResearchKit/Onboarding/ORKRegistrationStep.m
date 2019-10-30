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


NSString *const ORK1RegistrationFormItemIdentifierEmail = @"ORKRegistrationFormItemEmail";
NSString *const ORK1RegistrationFormItemIdentifierPassword = @"ORKRegistrationFormItemPassword";
NSString *const ORK1RegistrationFormItemIdentifierConfirmPassword = @"ORKRegistrationFormItemConfirmPassword";
NSString *const ORK1RegistrationFormItemIdentifierGivenName = @"ORKRegistrationFormItemGivenName";
NSString *const ORK1RegistrationFormItemIdentifierFamilyName = @"ORKRegistrationFormItemFamilyName";
NSString *const ORK1RegistrationFormItemIdentifierGender = @"ORKRegistrationFormItemGender";
NSString *const ORK1RegistrationFormItemIdentifierDOB = @"ORKRegistrationFormItemDOB";

static id ORK1FindInArrayByFormItemId(NSArray *array, NSString *formItemIdentifier) {
    return findInArrayByKey(array, @"identifier", formItemIdentifier);
}

static NSArray <ORK1FormItem*> *ORK1RegistrationFormItems(ORK1RegistrationStepOption options) {
    NSMutableArray *formItems = [NSMutableArray new];
    
    {
        ORK1EmailAnswerFormat *answerFormat = [ORK1AnswerFormat emailAnswerFormat];
        
        ORK1FormItem *item = [[ORK1FormItem alloc] initWithIdentifier:ORK1RegistrationFormItemIdentifierEmail
                                                               text:ORK1LocalizedString(@"EMAIL_FORM_ITEM_TITLE", nil)
                                                       answerFormat:answerFormat
                                                           optional:NO];
        item.placeholder = ORK1LocalizedString(@"EMAIL_FORM_ITEM_PLACEHOLDER", nil);
        
        [formItems addObject:item];
    }
    
    ORK1FormItem *passwordFormItem;
    {
        ORK1TextAnswerFormat *answerFormat = [ORK1AnswerFormat textAnswerFormat];
        answerFormat.multipleLines = NO;
        answerFormat.secureTextEntry = YES;
        answerFormat.autocapitalizationType = UITextAutocapitalizationTypeNone;
        answerFormat.autocorrectionType = UITextAutocorrectionTypeNo;
        answerFormat.spellCheckingType = UITextSpellCheckingTypeNo;
        
        ORK1FormItem *item = [[ORK1FormItem alloc] initWithIdentifier:ORK1RegistrationFormItemIdentifierPassword
                                                               text:ORK1LocalizedString(@"PASSWORD_FORM_ITEM_TITLE", nil)
                                                       answerFormat:answerFormat
                                                           optional:NO];
        item.placeholder = ORK1LocalizedString(@"PASSWORD_FORM_ITEM_PLACEHOLDER", nil);
        passwordFormItem = item;
        
        [formItems addObject:item];
    }
    
    {
        ORK1FormItem *item = [passwordFormItem confirmationAnswerFormItemWithIdentifier:ORK1RegistrationFormItemIdentifierConfirmPassword
                                                text:ORK1LocalizedString(@"CONFIRM_PASSWORD_FORM_ITEM_TITLE", nil)
                                                errorMessage:ORK1LocalizedString(@"CONFIRM_PASSWORD_ERROR_MESSAGE", nil)];
        item.placeholder = ORK1LocalizedString(@"CONFIRM_PASSWORD_FORM_ITEM_PLACEHOLDER", nil);
        
        [formItems addObject:item];
    }
    
    if (options & (ORK1RegistrationStepIncludeFamilyName | ORK1RegistrationStepIncludeGivenName | ORK1RegistrationStepIncludeDOB | ORK1RegistrationStepIncludeGender)) {
        ORK1FormItem *item = [[ORK1FormItem alloc] initWithSectionTitle:ORK1LocalizedString(@"ADDITIONAL_INFO_SECTION_TITLE", nil)];
        
        [formItems addObject:item];
    }
    
    if (options & ORK1RegistrationStepIncludeGivenName) {
        ORK1TextAnswerFormat *answerFormat = [ORK1AnswerFormat textAnswerFormat];
        answerFormat.multipleLines = NO;
        
        ORK1FormItem *item = [[ORK1FormItem alloc] initWithIdentifier:ORK1RegistrationFormItemIdentifierGivenName
                                                               text:ORK1LocalizedString(@"CONSENT_NAME_GIVEN", nil)
                                                       answerFormat:answerFormat
                                                           optional:NO];
        item.placeholder = ORK1LocalizedString(@"GIVEN_NAME_ITEM_PLACEHOLDER", nil);
        
        [formItems addObject:item];
    }
    
    if (options & ORK1RegistrationStepIncludeFamilyName) {
        ORK1TextAnswerFormat *answerFormat = [ORK1AnswerFormat textAnswerFormat];
        answerFormat.multipleLines = NO;
        
        ORK1FormItem *item = [[ORK1FormItem alloc] initWithIdentifier:ORK1RegistrationFormItemIdentifierFamilyName
                                                               text:ORK1LocalizedString(@"CONSENT_NAME_FAMILY", nil)
                                                       answerFormat:answerFormat
                                                           optional:NO];
        item.placeholder = ORK1LocalizedString(@"FAMILY_NAME_ITEM_PLACEHOLDER", nil);
        
        [formItems addObject:item];
    }
    
    // Adjust order of given name and family name form item cells based on current locale.
    if ((options & ORK1RegistrationStepIncludeGivenName) && (options & ORK1RegistrationStepIncludeFamilyName)) {
        if (ORK1CurrentLocalePresentsFamilyNameFirst()) {
            ORK1FormItem *givenNameFormItem = ORK1FindInArrayByFormItemId(formItems, ORK1RegistrationFormItemIdentifierGivenName);
            ORK1FormItem *familyNameFormItem = ORK1FindInArrayByFormItemId(formItems, ORK1RegistrationFormItemIdentifierFamilyName);
            [formItems exchangeObjectAtIndex:[formItems indexOfObject:givenNameFormItem]
                           withObjectAtIndex:[formItems indexOfObject:familyNameFormItem]];
        }
    }
    
    if (options & ORK1RegistrationStepIncludeGender) {
        NSArray *textChoices = @[[ORK1TextChoice choiceWithText:ORK1LocalizedString(@"GENDER_FEMALE", nil) value:@"female"],
                                 [ORK1TextChoice choiceWithText:ORK1LocalizedString(@"GENDER_MALE", nil) value:@"male"],
                                 [ORK1TextChoice choiceWithText:ORK1LocalizedString(@"GENDER_OTHER", nil) value:@"other"]];
        ORK1ValuePickerAnswerFormat *answerFormat = [ORK1AnswerFormat valuePickerAnswerFormatWithTextChoices:textChoices];
        
        ORK1FormItem *item = [[ORK1FormItem alloc] initWithIdentifier:ORK1RegistrationFormItemIdentifierGender
                                                               text:ORK1LocalizedString(@"GENDER_FORM_ITEM_TITLE", nil)
                                                       answerFormat:answerFormat
                                                           optional:NO];
        item.placeholder = ORK1LocalizedString(@"GENDER_FORM_ITEM_PLACEHOLDER", nil);
        
        [formItems addObject:item];
    }
    
    if (options & ORK1RegistrationStepIncludeDOB) {
        // Calculate default date (20 years from now).
        NSDate *defaultDate = [[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian] dateByAddingUnit:NSCalendarUnitYear
                                                                       value:-20
                                                                      toDate:[NSDate date]
                                                                     options:(NSCalendarOptions)0];
        
        ORK1DateAnswerFormat *answerFormat = [ORK1AnswerFormat dateAnswerFormatWithDefaultDate:defaultDate
                                                                                 minimumDate:nil
                                                                                 maximumDate:[NSDate date]
                                                                                    calendar:[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian]];
        
        ORK1FormItem *item = [[ORK1FormItem alloc] initWithIdentifier:ORK1RegistrationFormItemIdentifierDOB
                                                               text:ORK1LocalizedString(@"DOB_FORM_ITEM_TITLE", nil)
                                                       answerFormat:answerFormat
                                                           optional:NO];
        item.placeholder = ORK1LocalizedString(@"DOB_FORM_ITEM_PLACEHOLDER", nil);
        
        [formItems addObject:item];
    }
    
    return formItems;
}


@implementation ORK1RegistrationStep

- (instancetype)initWithIdentifier:(NSString *)identifier
                             title:(NSString *)title
                              text:(NSString *)text
passcodeValidationRegularExpression:(NSRegularExpression *)passcodeValidationRegularExpression
            passcodeInvalidMessage:(NSString *)passcodeInvalidMessage
                           options:(ORK1RegistrationStepOption)options {
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
                           options:(ORK1RegistrationStepOption)options {
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
                            options:ORK1RegistrationStepDefault];
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    return [self initWithIdentifier:identifier
                              title:nil
                               text:nil];
}

- (ORK1TextAnswerFormat *)passwordAnswerFormat {
    ORK1FormItem *passwordFormItem = ORK1FindInArrayByFormItemId(self.formItems, ORK1RegistrationFormItemIdentifierPassword);
    ORK1TextAnswerFormat *passwordAnswerFormat = (ORK1TextAnswerFormat *)passwordFormItem.answerFormat;
    return passwordAnswerFormat;
}

- (NSArray <ORK1FormItem *> *)formItems {
    if (![super formItems]) {
        self.formItems = ORK1RegistrationFormItems(_options);
    }
    
    ORK1FormItem *dobFormItem = ORK1FindInArrayByFormItemId([super formItems], ORK1RegistrationFormItemIdentifierDOB);
    ORK1DateAnswerFormat *originalAnswerFormat = (ORK1DateAnswerFormat *)dobFormItem.answerFormat;
    ORK1DateAnswerFormat *modifiedAnswerFormat = [ORK1AnswerFormat dateAnswerFormatWithDefaultDate:originalAnswerFormat.defaultDate
                                                                                     minimumDate:originalAnswerFormat.minimumDate
                                                                                     maximumDate:[NSDate date]
                                                                                        calendar:originalAnswerFormat.calendar];

    dobFormItem = [[ORK1FormItem alloc] initWithIdentifier:ORK1RegistrationFormItemIdentifierDOB
                                                     text:ORK1LocalizedString(@"DOB_FORM_ITEM_TITLE", nil)
                                             answerFormat:modifiedAnswerFormat
                                                 optional:NO];
    dobFormItem.placeholder = ORK1LocalizedString(@"DOB_FORM_ITEM_PLACEHOLDER", nil);
    
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
        // format's `-initWithCode:` method, invoked from super's (ORK1FormStep) implementation.
        ORK1_DECODE_INTEGER(aDecoder, options);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    
    // `passcodeValidationRegularExpression` and `passcodeInvalidMessage` are transparent
    // properties. The corresponding encoding for these properties takes place in the answer format's
    // `-encodeWithCoder:` method, invoked from super's (ORK1FormStep) implementation.
    ORK1_ENCODE_INTEGER(aCoder, options);
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1RegistrationStep *step = [super copyWithZone:zone];
    
    // `passcodeValidationRegularExpression` and `passcodeInvalidMessage` are transparent
    // properties. The corresponding copying of these properties happens in the answer format
    // `-copyWithZone:` method, invoked from the super's (ORK1FormStep) implementation.
    step->_options = self.options;
    return step;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    // `passcodeValidationRegularExpression` and `passcodeInvalidMessage` are transparent
    // properties. The corresponding equality test for these properties takes place in the answer
    // format's `-isEqual:` method, invoked from super's (ORK1FormStep) implementation.
    __typeof(self) castObject = object;
    return (isParentSame &&
            self.options == castObject.options);
}

@end
