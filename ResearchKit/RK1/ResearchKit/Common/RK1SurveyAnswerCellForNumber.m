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


#import "RK1SurveyAnswerCellForNumber.h"

#import "RK1TextFieldView.h"

#import "RK1AnswerFormat_Internal.h"
#import "RK1QuestionStep_Internal.h"

#import "RK1Helpers_Internal.h"
#import "RK1Skin.h"


@interface RK1SurveyAnswerCellForNumber ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) RK1TextFieldView *textFieldView;

@end


@implementation RK1SurveyAnswerCellForNumber {
    NSNumberFormatter *_numberFormatter;
}

- (RK1UnitTextField *)textField {
    return _textFieldView.textField;
}

- (void)numberCell_initialize {
    RK1QuestionType questionType = self.step.questionType;
    _numberFormatter = RK1DecimalNumberFormatter();
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localeDidChange:) name:NSCurrentLocaleDidChangeNotification object:nil];
    
    _textFieldView = [[RK1TextFieldView alloc] init];
    RK1UnitTextField *textField =  _textFieldView.textField;
    
    textField.delegate = self;
    textField.allowsSelection = YES;
    
    if (questionType == RK1QuestionTypeDecimal) {
        textField.keyboardType = UIKeyboardTypeDecimalPad;
    } else if (questionType == RK1QuestionTypeInteger) {
        textField.keyboardType = UIKeyboardTypeNumberPad;
    }
    
    [textField addTarget:self action:@selector(valueFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    _containerView = [[UIView alloc] init];
    _containerView.backgroundColor = textField.backgroundColor;
    [_containerView addSubview: _textFieldView];

    [self addSubview:_containerView];
    
    self.layoutMargins = RK1StandardLayoutMarginsForTableViewCell(self);
    RK1EnableAutoLayoutForViews(@[_containerView, _textFieldView]);
    [self setUpConstraints];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)localeDidChange:(NSNotification *)note {
    // On a locale change, re-format the value with the current locale
    _numberFormatter.locale = [NSLocale currentLocale];
    [self answerDidChange];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    self.layoutMargins = RK1StandardLayoutMarginsForTableViewCell(self);
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    NSDictionary *views = NSDictionaryOfVariableBindings(_containerView, _textFieldView);
    
    // Get a full width layout
    [constraints addObject:[self.class fullWidthLayoutConstraint:_containerView]];
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[_containerView]-|"
                                                                             options:(NSLayoutFormatOptions)0
                                                                             metrics:nil
                                                                               views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_containerView(>=0)]-|"
                                                                             options:(NSLayoutFormatOptions)0
                                                                             metrics:nil
                                                                               views:views]];
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_textFieldView]|"
                                                                             options:(NSLayoutFormatOptions)0
                                                                             metrics:nil
                                                                               views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_textFieldView]|"
                                                                             options:(NSLayoutFormatOptions)0
                                                                             metrics:nil
                                                                               views:views]];
    [NSLayoutConstraint activateConstraints:constraints];
}

- (BOOL)becomeFirstResponder {
    return [[self textField] becomeFirstResponder];
}

- (void)prepareView {
    if (self.textField == nil ) {
        [self numberCell_initialize];
    }
    
    [self answerDidChange];
    
    [super prepareView];
}

- (BOOL)isAnswerValid {
    id answer = self.answer;
    
    if (answer == RK1NullAnswerValue()) {
        return YES;
    }
    
    RK1AnswerFormat *answerFormat = [self.step impliedAnswerFormat];
    RK1NumericAnswerFormat *numericFormat = (RK1NumericAnswerFormat *)answerFormat;
    return [numericFormat isAnswerValidWithString:self.textField.text];
}

- (BOOL)shouldContinue {
    BOOL isValid = [self isAnswerValid];

    if (!isValid) {
        [self showValidityAlertWithMessage:[[self.step impliedAnswerFormat] localizedInvalidValueStringWithAnswerString:self.textField.text]];
    }
    
    return isValid;
}

- (void)answerDidChange {
    id answer = self.answer;
    RK1AnswerFormat *answerFormat = [self.step impliedAnswerFormat];
    RK1NumericAnswerFormat *numericFormat = (RK1NumericAnswerFormat *)answerFormat;
    NSString *displayValue = (answer && answer != RK1NullAnswerValue()) ? answer : nil;
    if ([answer isKindOfClass:[NSNumber class]]) {
        displayValue = [_numberFormatter stringFromNumber:answer];
    }
   
    NSString *placeholder = self.step.placeholder ? : RK1LocalizedString(@"PLACEHOLDER_TEXT_OR_NUMBER", nil);

    self.textField.manageUnitAndPlaceholder = YES;
    self.textField.unit = numericFormat.unit;
    self.textField.placeholder = placeholder;
    self.textField.text = displayValue;
}

#pragma mark - UITextFieldDelegate

- (void)valueFieldDidChange:(UITextField *)textField {
    RK1NumericAnswerFormat *answerFormat = (RK1NumericAnswerFormat *)[self.step impliedAnswerFormat];
    NSString *sanitizedText = [answerFormat sanitizedTextFieldText:[textField text] decimalSeparator:[_numberFormatter decimalSeparator]];
    textField.text = sanitizedText;
    [self setAnswerWithText:textField.text];
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    [self ork_setAnswer:RK1NullAnswerValue()];
    return YES;
}

- (void)setAnswerWithText:(NSString *)text {
    BOOL updateInput = NO;
    id answer = RK1NullAnswerValue();
    if (text.length) {
        answer = [[NSDecimalNumber alloc] initWithString:text locale:[NSLocale currentLocale]];
        if (!answer) {
            answer = RK1NullAnswerValue();
            updateInput = YES;
        }
    }
    
    [self ork_setAnswer:answer];
    if (updateInput) {
        [self answerDidChange];
    }
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    BOOL isValid = [self isAnswerValid];
    if (!isValid) {
        [self showValidityAlertWithMessage:[[self.step impliedAnswerFormat] localizedInvalidValueStringWithAnswerString:textField.text]];
    }
    
    return YES;
}

+ (BOOL)shouldDisplayWithSeparators {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    BOOL isValid = [self isAnswerValid];
    
    if (!isValid) {
        [self showValidityAlertWithMessage:[[self.step impliedAnswerFormat] localizedInvalidValueStringWithAnswerString:textField.text]];
        return NO;
    }
    
    [self.textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSString *text = self.textField.text;
    [self setAnswerWithText:text];
}

@end
