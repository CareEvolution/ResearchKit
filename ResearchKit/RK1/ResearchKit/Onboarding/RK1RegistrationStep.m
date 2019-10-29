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


#import "RK1RegistrationStep.h"

#import "RK1AnswerFormat_Private.h"

#import "RK1Helpers_Internal.h"


NSString *const RK1RegistrationFormItemIdentifierEmail = @"RK1RegistrationFormItemEmail";
NSString *const RK1RegistrationFormItemIdentifierPassword = @"RK1RegistrationFormItemPassword";
NSString *const RK1RegistrationFormItemIdentifierConfirmPassword = @"RK1RegistrationFormItemConfirmPassword";
NSString *const RK1RegistrationFormItemIdentifierGivenName = @"RK1RegistrationFormItemGivenName";
NSString *const RK1RegistrationFormItemIdentifierFamilyName = @"RK1RegistrationFormItemFamilyName";
NSString *const RK1RegistrationFormItemIdentifierGender = @"RK1RegistrationFormItemGender";
NSString *const RK1RegistrationFormItemIdentifierDOB = @"RK1RegistrationFormItemDOB";

static id RK1FindInArrayByFormItemId(NSArray *array, NSString *formItemIdentifier) {
    return findInArrayByKey(array, @"identifier", formItemIdentifier);
}

static NSArray <RK1FormItem*> *RK1RegistrationFormItems(RK1RegistrationStepOption options) {
    NSMutableArray *formItems = [NSMutableArray new];
    
    {
        RK1EmailAnswerFormat *answerFormat = [RK1AnswerFormat emailAnswerFormat];
        
        RK1FormItem *item = [[RK1FormItem alloc] initWithIdentifier:RK1RegistrationFormItemIdentifierEmail
                                                               text:RK1LocalizedString(@"EMAIL_FORM_ITEM_TITLE", nil)
                                                       answerFormat:answerFormat
                                                           optional:NO];
        item.placeholder = RK1LocalizedString(@"EMAIL_FORM_ITEM_PLACEHOLDER", nil);
        
        [formItems addObject:item];
    }
    
    RK1FormItem *passwordFormItem;
    {
        RK1TextAnswerFormat *answerFormat = [RK1AnswerFormat textAnswerFormat];
        answerFormat.multipleLines = NO;
        answerFormat.secureTextEntry = YES;
        answerFormat.autocapitalizationType = UITextAutocapitalizationTypeNone;
        answerFormat.autocorrectionType = UITextAutocorrectionTypeNo;
        answerFormat.spellCheckingType = UITextSpellCheckingTypeNo;
        
        RK1FormItem *item = [[RK1FormItem alloc] initWithIdentifier:RK1RegistrationFormItemIdentifierPassword
                                                               text:RK1LocalizedString(@"PASSWORD_FORM_ITEM_TITLE", nil)
                                                       answerFormat:answerFormat
                                                           optional:NO];
        item.placeholder = RK1LocalizedString(@"PASSWORD_FORM_ITEM_PLACEHOLDER", nil);
        passwordFormItem = item;
        
        [formItems addObject:item];
    }
    
    {
        RK1FormItem *item = [passwordFormItem confirmationAnswerFormItemWithIdentifier:RK1RegistrationFormItemIdentifierConfirmPassword
                                                text:RK1LocalizedString(@"CONFIRM_PASSWORD_FORM_ITEM_TITLE", nil)
                                                errorMessage:RK1LocalizedString(@"CONFIRM_PASSWORD_ERROR_MESSAGE", nil)];
        item.placeholder = RK1LocalizedString(@"CONFIRM_PASSWORD_FORM_ITEM_PLACEHOLDER", nil);
        
        [formItems addObject:item];
    }
    
    if (options & (RK1RegistrationStepIncludeFamilyName | RK1RegistrationStepIncludeGivenName | RK1RegistrationStepIncludeDOB | RK1RegistrationStepIncludeGender)) {
        RK1FormItem *item = [[RK1FormItem alloc] initWithSectionTitle:RK1LocalizedString(@"ADDITIONAL_INFO_SECTION_TITLE", nil)];
        
        [formItems addObject:item];
    }
    
    if (options & RK1RegistrationStepIncludeGivenName) {
        RK1TextAnswerFormat *answerFormat = [RK1AnswerFormat textAnswerFormat];
        answerFormat.multipleLines = NO;
        
        RK1FormItem *item = [[RK1FormItem alloc] initWithIdentifier:RK1RegistrationFormItemIdentifierGivenName
                                                               text:RK1LocalizedString(@"CONSENT_NAME_GIVEN", nil)
                                                       answerFormat:answerFormat
                                                           optional:NO];
        item.placeholder = RK1LocalizedString(@"GIVEN_NAME_ITEM_PLACEHOLDER", nil);
        
        [formItems addObject:item];
    }
    
    if (options & RK1RegistrationStepIncludeFamilyName) {
        RK1TextAnswerFormat *answerFormat = [RK1AnswerFormat textAnswerFormat];
        answerFormat.multipleLines = NO;
        
        RK1FormItem *item = [[RK1FormItem alloc] initWithIdentifier:RK1RegistrationFormItemIdentifierFamilyName
                                                               text:RK1LocalizedString(@"CONSENT_NAME_FAMILY", nil)
                                                       answerFormat:answerFormat
                                                           optional:NO];
        item.placeholder = RK1LocalizedString(@"FAMILY_NAME_ITEM_PLACEHOLDER", nil);
        
        [formItems addObject:item];
    }
    
    // Adjust order of given name and family name form item cells based on current locale.
    if ((options & RK1RegistrationStepIncludeGivenName) && (options & RK1RegistrationStepIncludeFamilyName)) {
        if (RK1CurrentLocalePresentsFamilyNameFirst()) {
            RK1FormItem *givenNameFormItem = RK1FindInArrayByFormItemId(formItems, RK1RegistrationFormItemIdentifierGivenName);
            RK1FormItem *familyNameFormItem = RK1FindInArrayByFormItemId(formItems, RK1RegistrationFormItemIdentifierFamilyName);
            [formItems exchangeObjectAtIndex:[formItems indexOfObject:givenNameFormItem]
                           withObjectAtIndex:[formItems indexOfObject:familyNameFormItem]];
        }
    }
    
    if (options & RK1RegistrationStepIncludeGender) {
        NSArray *textChoices = @[[RK1TextChoice choiceWithText:RK1LocalizedString(@"GENDER_FEMALE", nil) value:@"female"],
                                 [RK1TextChoice choiceWithText:RK1LocalizedString(@"GENDER_MALE", nil) value:@"male"],
                                 [RK1TextChoice choiceWithText:RK1LocalizedString(@"GENDER_OTHER", nil) value:@"other"]];
        RK1ValuePickerAnswerFormat *answerFormat = [RK1AnswerFormat valuePickerAnswerFormatWithTextChoices:textChoices];
        
        RK1FormItem *item = [[RK1FormItem alloc] initWithIdentifier:RK1RegistrationFormItemIdentifierGender
                                                               text:RK1LocalizedString(@"GENDER_FORM_ITEM_TITLE", nil)
                                                       answerFormat:answerFormat
                                                           optional:NO];
        item.placeholder = RK1LocalizedString(@"GENDER_FORM_ITEM_PLACEHOLDER", nil);
        
        [formItems addObject:item];
    }
    
    if (options & RK1RegistrationStepIncludeDOB) {
        // Calculate default date (20 years from now).
        NSDate *defaultDate = [[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian] dateByAddingUnit:NSCalendarUnitYear
                                                                       value:-20
                                                                      toDate:[NSDate date]
                                                                     options:(NSCalendarOptions)0];
        
        RK1DateAnswerFormat *answerFormat = [RK1AnswerFormat dateAnswerFormatWithDefaultDate:defaultDate
                                                                                 minimumDate:nil
                                                                                 maximumDate:[NSDate date]
                                                                                    calendar:[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian]];
        
        RK1FormItem *item = [[RK1FormItem alloc] initWithIdentifier:RK1RegistrationFormItemIdentifierDOB
                                                               text:RK1LocalizedString(@"DOB_FORM_ITEM_TITLE", nil)
                                                       answerFormat:answerFormat
                                                           optional:NO];
        item.placeholder = RK1LocalizedString(@"DOB_FORM_ITEM_PLACEHOLDER", nil);
        
        [formItems addObject:item];
    }
    
    return formItems;
}


@implementation RK1RegistrationStep

- (instancetype)initWithIdentifier:(NSString *)identifier
                             title:(NSString *)title
                              text:(NSString *)text
passcodeValidationRegularExpression:(NSRegularExpression *)passcodeValidationRegularExpression
            passcodeInvalidMessage:(NSString *)passcodeInvalidMessage
                           options:(RK1RegistrationStepOption)options {
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
                           options:(RK1RegistrationStepOption)options {
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
                            options:RK1RegistrationStepDefault];
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    return [self initWithIdentifier:identifier
                              title:nil
                               text:nil];
}

- (RK1TextAnswerFormat *)passwordAnswerFormat {
    RK1FormItem *passwordFormItem = RK1FindInArrayByFormItemId(self.formItems, RK1RegistrationFormItemIdentifierPassword);
    RK1TextAnswerFormat *passwordAnswerFormat = (RK1TextAnswerFormat *)passwordFormItem.answerFormat;
    return passwordAnswerFormat;
}

- (NSArray <RK1FormItem *> *)formItems {
    if (![super formItems]) {
        self.formItems = RK1RegistrationFormItems(_options);
    }
    
    RK1FormItem *dobFormItem = RK1FindInArrayByFormItemId([super formItems], RK1RegistrationFormItemIdentifierDOB);
    RK1DateAnswerFormat *originalAnswerFormat = (RK1DateAnswerFormat *)dobFormItem.answerFormat;
    RK1DateAnswerFormat *modifiedAnswerFormat = [RK1AnswerFormat dateAnswerFormatWithDefaultDate:originalAnswerFormat.defaultDate
                                                                                     minimumDate:originalAnswerFormat.minimumDate
                                                                                     maximumDate:[NSDate date]
                                                                                        calendar:originalAnswerFormat.calendar];

    dobFormItem = [[RK1FormItem alloc] initWithIdentifier:RK1RegistrationFormItemIdentifierDOB
                                                     text:RK1LocalizedString(@"DOB_FORM_ITEM_TITLE", nil)
                                             answerFormat:modifiedAnswerFormat
                                                 optional:NO];
    dobFormItem.placeholder = RK1LocalizedString(@"DOB_FORM_ITEM_PLACEHOLDER", nil);
    
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
        // format's `-initWithCode:` method, invoked from super's (RK1FormStep) implementation.
        RK1_DECODE_INTEGER(aDecoder, options);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    
    // `passcodeValidationRegularExpression` and `passcodeInvalidMessage` are transparent
    // properties. The corresponding encoding for these properties takes place in the answer format's
    // `-encodeWithCoder:` method, invoked from super's (RK1FormStep) implementation.
    RK1_ENCODE_INTEGER(aCoder, options);
}

- (instancetype)copyWithZone:(NSZone *)zone {
    RK1RegistrationStep *step = [super copyWithZone:zone];
    
    // `passcodeValidationRegularExpression` and `passcodeInvalidMessage` are transparent
    // properties. The corresponding copying of these properties happens in the answer format
    // `-copyWithZone:` method, invoked from the super's (RK1FormStep) implementation.
    step->_options = self.options;
    return step;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    // `passcodeValidationRegularExpression` and `passcodeInvalidMessage` are transparent
    // properties. The corresponding equality test for these properties takes place in the answer
    // format's `-isEqual:` method, invoked from super's (RK1FormStep) implementation.
    __typeof(self) castObject = object;
    return (isParentSame &&
            self.options == castObject.options);
}

@end
