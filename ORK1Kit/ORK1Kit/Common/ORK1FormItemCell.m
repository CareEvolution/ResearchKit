/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 Copyright (c) 2015, Bruce Duncan.
 
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


#import "ORK1FormItemCell.h"

#import "ORK1Caption1Label.h"
#import "ORK1FormTextView.h"
#import "ORK1ImageSelectionView.h"
#import "ORK1LocationSelectionView.h"
#import "ORK1Picker.h"
#import "ORK1ScaleSliderView.h"
#import "ORK1TableContainerView.h"
#import "ORK1TextFieldView.h"

#import "ORK1AnswerFormat_Internal.h"
#import "ORK1FormItem_Internal.h"
#import "ORK1Result_Private.h"

#import "ORK1Accessibility.h"
#import "ORK1Helpers_Internal.h"
#import "ORK1Skin.h"

@import MapKit;


static const CGFloat VerticalMargin = 10.0;
static const CGFloat HorizontalMargin = 15.0;

@interface ORK1FormItemCell ()

- (void)cellInit NS_REQUIRES_SUPER;
- (void)inputValueDidChange NS_REQUIRES_SUPER;
- (void)inputValueDidClear NS_REQUIRES_SUPER;
- (void)defaultAnswerDidChange NS_REQUIRES_SUPER;
- (void)answerDidChange;

// For use when setting the answer in response to user action
- (void)ork_setAnswer:(id)answer;

@property (nonatomic, strong) ORK1Caption1Label *labelLabel;
@property (nonatomic, weak) UITableView *_parentTableView;

// If hasChangedAnswer, then a new defaultAnswer should not change the answer
@property (nonatomic, assign) BOOL hasChangedAnswer;

@end


@interface ORK1SegmentedControl : UISegmentedControl

@end


@implementation ORK1SegmentedControl

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    NSInteger previousSelectedSegmentIndex = self.selectedSegmentIndex;
    [super touchesEnded:touches withEvent:event];
    if (previousSelectedSegmentIndex == self.selectedSegmentIndex) {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

@end


#pragma mark - ORK1FormItemCell

@interface ORK1FormItemCell ()

- (void)showValidityAlertWithMessage:(NSString *)text;

@end


@implementation ORK1FormItemCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
                               formItem:(ORK1FormItem *)formItem
                                 answer:(id)answer
                          maxLabelWidth:(CGFloat)maxLabelWidth
                               delegate:(id<ORK1FormItemCellDelegate>)delegate {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        // Setting the 'delegate' on init is required, as some questions (such as the scale questions)
        // need it when they wish to report their default answers to 'ORK1FormStepViewController'.
        _delegate = delegate;
        
        _maxLabelWidth = maxLabelWidth;
        _answer = [answer copy];
        self.formItem = formItem;
        _labelLabel = [[ORK1Caption1Label alloc] init];
        _labelLabel.text = formItem.text;
        _labelLabel.numberOfLines = 0;
        [self.contentView addSubview:_labelLabel];
        
        [self cellInit];
        [self setAnswer:_answer];
    }
    return self;
}

- (void)setExpectedLayoutWidth:(CGFloat)newWidth {
    if (newWidth != _expectedLayoutWidth) {
        _expectedLayoutWidth = newWidth;
        [self setNeedsUpdateConstraints];
    }
}

- (UITableView *)parentTableView {
    if (nil == __parentTableView) {
        id view = [self superview];
        
        while (view && [view isKindOfClass:[UITableView class]] == NO) {
            view = [view superview];
        }
        __parentTableView = (UITableView *)view;
    }
    return __parentTableView;
}

- (void)cellInit {
    // Subclasses should override this
}

- (void)inputValueDidChange {
    // Subclasses should override this, and should call _setAnswer:
    self.hasChangedAnswer = YES;
}

- (void)inputValueDidClear {
    // Subclasses should override this, and should call _setAnswer:
    self.hasChangedAnswer = YES;
}

- (void)answerDidChange {
}

- (BOOL)isAnswerValid {
    // Subclasses should override this if validation of the answer is required.
    return YES;
}

- (void)defaultAnswerDidChange {
    if (!self.hasChangedAnswer && !self.answer) {
        if (self.answer != _defaultAnswer && _defaultAnswer && ![self.answer isEqual:_defaultAnswer]) {
            self.answer = _defaultAnswer;
            
            // Inform delegate of the change too
            [self ork_setAnswer:_answer];
        }
    }
}

- (void)setDefaultAnswer:(id)defaultAnswer {
    _defaultAnswer = [defaultAnswer copy];
    [self defaultAnswerDidChange];
}

- (void)setSavedAnswers:(NSDictionary *)savedAnswers {
    _savedAnswers = savedAnswers;

    if (!_savedAnswers) {
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:@"Saved answers cannot be nil."
                                     userInfo:nil];
    }
    
}

- (BOOL)becomeFirstResponder {
    // Subclasses should override this
    return YES;
}

- (BOOL)resignFirstResponder {
    [super resignFirstResponder];
    // Subclasses should override this
    return YES;
}

- (void)prepareForReuse {
    self.hasChangedAnswer = NO;
    [super prepareForReuse];
}

// Inform delegate of the change
- (void)ork_setAnswer:(id)answer {
    _answer = [answer copy];
    [_delegate formItemCell:self answerDidChangeTo:answer];
}

// Receive change from outside
- (void)setAnswer:(id)answer {
    _answer = [answer copy];
    [self answerDidChange];
}

- (void)showValidityAlertWithMessage:(NSString *)text {
    [self.delegate formItemCell:self invalidInputAlertWithMessage:text];
}

- (void)showErrorAlertWithTitle:(NSString *)title message:(NSString *)message {
    [self.delegate formItemCell:self invalidInputAlertWithTitle:title message:message];
}

@end


#pragma mark - ORK1FormItemTextFieldBasedCell

@interface ORK1FormItemTextFieldBasedCell ()

- (ORK1UnitTextField *)textField;

@property (nonatomic, readonly) ORK1TextFieldView *textFieldView;
@property (nonatomic, assign) BOOL editingHighlight;

@end


@implementation ORK1FormItemTextFieldBasedCell {
    NSMutableArray *_variableConstraints;
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
                               formItem:(ORK1FormItem *)formItem
                                 answer:(id)answer
                          maxLabelWidth:(CGFloat)maxLabelWidth
                               delegate:(id<ORK1FormItemCellDelegate>)delegate{
    self = [super initWithReuseIdentifier:reuseIdentifier
                                 formItem:formItem
                                   answer:answer
                            maxLabelWidth:maxLabelWidth
                                 delegate:delegate];
    if (self != nil) {
        UILabel *label = self.labelLabel;
        label.isAccessibilityElement = NO;
        UITextField *textField = self.textFieldView.textField;
        textField.isAccessibilityElement = YES;
        textField.accessibilityLabel = label.text;
    }
    return self;
}

- (ORK1UnitTextField *)textField {
    return _textFieldView.textField;
}

- (void)cellInit {
    [super cellInit];
    
    _textFieldView = [[ORK1TextFieldView alloc] init];
    
    ORK1UnitTextField *textField = _textFieldView.textField;
    textField.delegate = self;
    textField.placeholder = self.formItem.placeholder;
    
    [self.contentView addSubview:_textFieldView];
    
    self.labelLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _textFieldView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self setUpContentConstraint];
    [self setNeedsUpdateConstraints];
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    [self setNeedsUpdateConstraints];
}

- (void)setUpContentConstraint {
    NSLayoutConstraint *contentConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                         attribute:NSLayoutAttributeWidth
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self
                                                                         attribute:NSLayoutAttributeWidth
                                                                        multiplier:1.0
                                                                          constant:0.0];
    contentConstraint.priority = UILayoutPriorityDefaultHigh;
    contentConstraint.active = YES;
}

- (void)updateConstraints {
    [NSLayoutConstraint deactivateConstraints:_variableConstraints];
    [_variableConstraints removeAllObjects];
    
    if (!_variableConstraints) {
        _variableConstraints = [NSMutableArray new];
    }
    
    CGFloat labelWidth = self.maxLabelWidth;
    CGFloat boundWidth = self.expectedLayoutWidth;
    
    NSDictionary *metrics = @{@"vMargin":@(10),
                              @"hMargin":@(self.separatorInset.left),
                              @"hSpacer":@(16), @"vSpacer":@(15),
                              @"labelWidth": @(labelWidth)};
    
    id labelLabel = self.labelLabel;
    id textFieldView = _textFieldView;
    NSDictionary *views = NSDictionaryOfVariableBindings(labelLabel,textFieldView);
    
    CGFloat fieldWidth = _textFieldView.estimatedWidth;
    
    // Leave half space for field, and also to be able to display placeholder in full.
    if ( labelWidth >= 0.5 * boundWidth || (fieldWidth + labelWidth) > 0.9 * boundWidth ) {
        [_variableConstraints addObjectsFromArray:
         [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hMargin-[labelLabel]-hMargin-|"
                                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                                 metrics:metrics
                                                   views:views]];
        
        [_variableConstraints addObjectsFromArray:
         [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hMargin-[textFieldView]|"
                                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                                 metrics:metrics
                                                   views:views]];
        
        [_variableConstraints addObjectsFromArray:
         [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-vMargin-[labelLabel]-vSpacer-[textFieldView]-vMargin-|"
                                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                                 metrics:metrics
                                                   views:views]];
        
    } else {
        [_variableConstraints addObjectsFromArray:
         [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hMargin-[labelLabel(==labelWidth)]-hSpacer-[textFieldView]|"
                                                 options:NSLayoutFormatAlignAllCenterY
                                                 metrics:metrics
                                                   views:views]];
        
        [_variableConstraints addObject:[NSLayoutConstraint constraintWithItem:labelLabel
                                                                     attribute:NSLayoutAttributeCenterY
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.contentView
                                                                     attribute:NSLayoutAttributeCenterY
                                                                    multiplier:1.0
                                                                      constant:0]];
        
        [_variableConstraints addObject:[NSLayoutConstraint constraintWithItem:self.contentView
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                        toItem:labelLabel
                                                                     attribute:NSLayoutAttributeHeight
                                                                    multiplier:1.0
                                                                      constant:0.0]];
        
        [_variableConstraints addObject:[NSLayoutConstraint constraintWithItem:self.contentView
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                        toItem:textFieldView
                                                                     attribute:NSLayoutAttributeHeight
                                                                    multiplier:1.0
                                                                      constant:0.0]];
    }
    
    CGFloat defaultTableCelltHeight = ORK1GetMetricForWindow(ORK1ScreenMetricTableCellDefaultHeight, self.window);
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1.0
                                                                         constant:defaultTableCelltHeight];
    // Lower the priority to avoid conflicts with system supplied UIView-Encapsulated-Layout-Height constraint.
    heightConstraint.priority = 999;
    [_variableConstraints addObject:heightConstraint];
    
    [NSLayoutConstraint activateConstraints:_variableConstraints];
    [super updateConstraints];
}

- (void)setEditingHighlight:(BOOL)editingHighlight {
    _editingHighlight = editingHighlight;
    self.labelLabel.textColor = _editingHighlight ? [self tintColor] : [UIColor blackColor];
    [self textField].textColor = _editingHighlight ? [self tintColor] : [UIColor blackColor];
}

- (void)dealloc {
    [self textField].delegate = nil;
}

- (void)setLabel:(NSString *)label {
    self.labelLabel.text = label;
    self.textField.accessibilityLabel = label;
}

- (NSString *)label {
    return self.labelLabel.text;
}

- (NSString *)formattedValue {
    return nil;
}

- (NSString *)shortenedFormattedValue {
    return [self formattedValue];
}

- (void)updateValueLabel {
    ORK1UnitTextField *textField = [self textField];
    
    if (textField == nil) {
        return;
    }
    
    NSString *formattedValue = [self formattedValue];
    CGFloat formattedWidth = [formattedValue sizeWithAttributes:@{ NSFontAttributeName : textField.font }].width;
    const CGFloat MinInputTextFieldPaddingRight = 6.0;
    
    // Shorten if necessary
    if (formattedWidth > textField.frame.size.width - MinInputTextFieldPaddingRight) {
        formattedValue = [self shortenedFormattedValue];
    }
    
    textField.text = formattedValue;
}

- (BOOL)becomeFirstResponder {
    return [self.textField becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    BOOL resign = [super resignFirstResponder];
    resign = [self.textField resignFirstResponder] || resign;
    return resign;
}

- (void)inputValueDidClear {
    [self ork_setAnswer:ORK1NullAnswerValue()];
    [super inputValueDidClear];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    // Ask table view to adjust scrollview's position
    self.editingHighlight = YES;
    [self.delegate formItemCellDidBecomeFirstResponder:self];
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    if (textField.text.length > 0 && ![[self.formItem impliedAnswerFormat] isAnswerValidWithString:textField.text]) {
        [self showValidityAlertWithMessage:[[self.formItem impliedAnswerFormat] localizedInvalidValueStringWithAnswerString:textField.text]];
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.editingHighlight = NO;
    [self.delegate formItemCellDidResignFirstResponder:self];
    [self inputValueDidChange];
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    [self inputValueDidClear];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (![[self.formItem impliedAnswerFormat] isAnswerValidWithString:textField.text]) {
        [self showValidityAlertWithMessage:[[self.formItem impliedAnswerFormat] localizedInvalidValueStringWithAnswerString:textField.text]];
        return NO;
    }
    
    [textField resignFirstResponder];
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    return YES;
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement {
    return NO;
}

@end


#pragma mark - ORK1FormItemConfirmTextCell

@implementation ORK1FormItemConfirmTextCell

- (void)setSavedAnswers:(NSDictionary *)savedAnswers {
    [super setSavedAnswers:savedAnswers];
    
    [savedAnswers addObserver:self
                   forKeyPath:[self originalItemIdentifier]
                      options:0
                      context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqual:[self originalItemIdentifier]]) {
        self.textField.text = nil;
        if (self.answer) {
            [self inputValueDidClear];
        }
    }
}

- (BOOL)isAnswerValidWithString:(NSString *)string {
    BOOL isValid = NO;
    if (string.length > 0) {
        NSString *originalItemAnswer = self.savedAnswers[[self originalItemIdentifier]];
        if (!ORK1IsAnswerEmpty(originalItemAnswer) && [originalItemAnswer isEqualToString:string]) {
            isValid = YES;
        }
    }
    return isValid;
}

- (NSString *)originalItemIdentifier {
    ORK1ConfirmTextAnswerFormat *answerFormat = (ORK1ConfirmTextAnswerFormat *)self.formItem.answerFormat;
    return [answerFormat.originalItemIdentifier copy];
}

- (void)dealloc {
    [self.savedAnswers removeObserver:self forKeyPath:[self originalItemIdentifier]];
}

#pragma mark UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [self ork_setAnswer:([self isAnswerValidWithString:text] ? text : @"")];

    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    [super textFieldShouldEndEditing:textField];
    if (![self isAnswerValidWithString:textField.text] && textField.text.length > 0) {
        textField.text = nil;
        if (self.answer) {
            [self inputValueDidClear];
        }
        [self showValidityAlertWithMessage:[self.formItem.answerFormat localizedInvalidValueStringWithAnswerString:textField.text]];
    }
    return YES;
}

@end


#pragma mark - ORK1FormItemTextFieldCell

@implementation ORK1FormItemTextFieldCell

- (void)cellInit {
    [super cellInit];
    self.textField.allowsSelection = YES;
    ORK1TextAnswerFormat *answerFormat = (ORK1TextAnswerFormat *)[self.formItem impliedAnswerFormat];
    self.textField.autocorrectionType = answerFormat.autocorrectionType;
    self.textField.autocapitalizationType = answerFormat.autocapitalizationType;
    self.textField.spellCheckingType = answerFormat.spellCheckingType;
    self.textField.keyboardType = answerFormat.keyboardType;
    self.textField.secureTextEntry = answerFormat.secureTextEntry;
    
    [self answerDidChange];
}

- (void)inputValueDidChange {
    NSString *text = self.textField.text;
    [self ork_setAnswer:text.length ? text : ORK1NullAnswerValue()];
    
    [super inputValueDidChange];
}

- (void)answerDidChange {
    id answer = self.answer;
    
    ORK1TextAnswerFormat *answerFormat = (ORK1TextAnswerFormat *)[self.formItem impliedAnswerFormat];
    if (answer != ORK1NullAnswerValue()) {
        NSString *text = (NSString *)answer;
        NSInteger maxLength = answerFormat.maximumLength;
        BOOL changedValue = NO;
        if (maxLength > 0 && text.length > maxLength) {
            text = [text substringToIndex:maxLength];
            changedValue = YES;
        }
        self.textField.text = text;
        if (changedValue) {
            [self inputValueDidChange];
        }
    } else {
        self.textField.text = nil;
    }
}

#pragma mark UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    ORK1TextAnswerFormat *answerFormat = (ORK1TextAnswerFormat *)[self.formItem impliedAnswerFormat];
    
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    // Only need to validate the text if the user enters a character other than a backspace.
    // For example, if the `textField.text = researchki` and the `text = researchkit`.
    if (textField.text.length < text.length) {
        
        text = [[text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@""];
        
        NSInteger maxLength = answerFormat.maximumLength;
        
        if (maxLength > 0 && text.length > maxLength) {
            [self showValidityAlertWithMessage:[answerFormat localizedInvalidValueStringWithAnswerString:text]];
            return NO;
        }
    }
    
    [self ork_setAnswer:text.length ? text : ORK1NullAnswerValue()];
    [super inputValueDidChange];
    
    return YES;
}

@end


#pragma mark - ORK1FormItemNumericCell

@implementation ORK1FormItemNumericCell {
    NSNumberFormatter *_numberFormatter;
}

- (void)cellInit {
    [super cellInit];
    ORK1QuestionType questionType = [self.formItem questionType];
    self.textField.keyboardType = (questionType == ORK1QuestionTypeInteger) ? UIKeyboardTypeNumberPad : UIKeyboardTypeDecimalPad;
    [self.textField addTarget:self action:@selector(valueFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    self.textField.allowsSelection = YES;
    
    ORK1NumericAnswerFormat *answerFormat = (ORK1NumericAnswerFormat *)[self.formItem impliedAnswerFormat];
    
    self.textField.manageUnitAndPlaceholder = YES;
    self.textField.unit = answerFormat.unit;
    self.textField.placeholder = self.formItem.placeholder;
    
    _numberFormatter = ORK1DecimalNumberFormatter();
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localeDidChange:) name:NSCurrentLocaleDidChangeNotification object:nil];
    
    [self answerDidChange];
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)localeDidChange:(NSNotification *)note {
    // On a locale change, re-format the value with the current locale
    _numberFormatter.locale = [NSLocale currentLocale];
    [self answerDidChange];
}

- (void)inputValueDidChange {
    
    NSString *text = self.textField.text;
    [self setAnswerWithText:text];
    
    [super inputValueDidChange];
}

- (void)answerDidChange {
    id answer = self.answer;
    if (answer && answer != ORK1NullAnswerValue()) {
        NSString *displayValue = answer;
        if ([answer isKindOfClass:[NSNumber class]]) {
            displayValue = [_numberFormatter stringFromNumber:answer];
        }
        self.textField.text = displayValue;
    } else {
        self.textField.text = nil;
    }
}

- (void)setAnswerWithText:(NSString *)text {
    BOOL updateInput = NO;
    id answer = ORK1NullAnswerValue();
    if (text.length) {
        answer = [[NSDecimalNumber alloc] initWithString:text locale:[NSLocale currentLocale]];
        if (!answer) {
            answer = ORK1NullAnswerValue();
            updateInput = YES;
        }
    }
    
    [self ork_setAnswer:answer];
    if (updateInput) {
        [self answerDidChange];
    }
}

#pragma mark UITextFieldDelegate

- (void)valueFieldDidChange:(UITextField *)textField {
    ORK1NumericAnswerFormat *answerFormat = (ORK1NumericAnswerFormat *)[self.formItem impliedAnswerFormat];
    NSString *sanitizedText = [answerFormat sanitizedTextFieldText:[textField text] decimalSeparator:[_numberFormatter decimalSeparator]];
    textField.text = sanitizedText;
    
    [self inputValueDidChange];
}

@end


#pragma mark - ORK1FormItemTextCell

@implementation ORK1FormItemTextCell {
    ORK1FormTextView *_textView;
    CGFloat _lastSeenLineCount;
    NSInteger _maxLength;
}

- (void)cellInit {
    [super cellInit];
    
    _lastSeenLineCount = 1;
    self.labelLabel.text = nil;
    _textView = [[ORK1FormTextView alloc] init];
    _textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    _textView.delegate = self;
    _textView.contentInset = UIEdgeInsetsMake(-5.0, -4.0, -5.0, 0.0);
    _textView.textAlignment = NSTextAlignmentNatural;
    _textView.scrollEnabled = NO;
    _textView.placeholder = self.formItem.placeholder;
    
    [self applyAnswerFormat];
    [self answerDidChange];
    
    [self.contentView addSubview:_textView];
    [self setUpConstraints];
}

- (void)setUpConstraints {
    NSDictionary *views = @{ @"textView": _textView };
    ORK1EnableAutoLayoutForViews(views.allValues);
    NSDictionary *metrics = @{ @"vMargin":@(10), @"hMargin":@(self.separatorInset.left) };
    
    NSMutableArray *constraints = [NSMutableArray new];
    
    [constraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hMargin-[textView]-hMargin-|"
                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                             metrics:metrics
                                               views:views]];
    
    [constraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-vMargin-[textView]-vMargin-|"
                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                             metrics:metrics
                                               views:views]];
    
    
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeHeight
                                                                       multiplier:1.0
                                                                         constant:120.0];
    heightConstraint.priority = UILayoutPriorityDefaultHigh;
    [constraints addObject:heightConstraint];
    
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)applyAnswerFormat {
    ORK1AnswerFormat *answerFormat = [self.formItem impliedAnswerFormat];
    if ([answerFormat isKindOfClass:[ORK1TextAnswerFormat class]]) {
        ORK1TextAnswerFormat *textAnswerFormat = (ORK1TextAnswerFormat *)answerFormat;
        _maxLength = [textAnswerFormat maximumLength];
        _textView.autocorrectionType = textAnswerFormat.autocorrectionType;
        _textView.autocapitalizationType = textAnswerFormat.autocapitalizationType;
        _textView.spellCheckingType = textAnswerFormat.spellCheckingType;
        _textView.keyboardType = textAnswerFormat.keyboardType;
        _textView.secureTextEntry = textAnswerFormat.secureTextEntry;
    } else {
        _maxLength = 0;
    }
}

- (void)setFormItem:(ORK1FormItem *)formItem {
    [super setFormItem:formItem];
    [self applyAnswerFormat];
}

- (void)answerDidChange {
    id answer = self.answer;
    if (answer == ORK1NullAnswerValue()) {
        answer = nil;
    }
    _textView.text = (NSString *)answer;
}

- (BOOL)becomeFirstResponder {
    return [_textView becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    BOOL resign = [super resignFirstResponder];
    return [_textView resignFirstResponder] || resign;
}

- (void)inputValueDidChange {
    NSString *text = _textView.text;
    [self ork_setAnswer:text.length ? text : ORK1NullAnswerValue()];
    [super inputValueDidChange];
}

- (UIColor *)placeholderColor {
    return [UIColor ork_midGrayTintColor];
}

#pragma mark UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    NSInteger lineCount = [textView.text componentsSeparatedByCharactersInSet:
                           [NSCharacterSet newlineCharacterSet]].count;
    
    if (_lastSeenLineCount != lineCount) {
        _lastSeenLineCount = lineCount;
        
        UITableView *tableView = [self parentTableView];
        
        [tableView beginUpdates];
        [tableView endUpdates];
        
        CGRect visibleRect = [textView caretRectForPosition:textView.selectedTextRange.start];
        CGRect convertedVisibleRect = [tableView convertRect:visibleRect fromView:_textView];
        [tableView scrollRectToVisible:convertedVisibleRect animated:YES];
    }
    
    [self inputValueDidChange];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if (textView.textColor == [self placeholderColor]) {
        textView.text = nil;
        textView.textColor = [UIColor blackColor];
    }
    // Ask table view to adjust scrollview's position
    [self.delegate formItemCellDidBecomeFirstResponder:self];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView.text.length == 0) {
        textView.text = self.formItem.placeholder;
        textView.textColor = [self placeholderColor];
    }
    [self.delegate formItemCellDidResignFirstResponder:self];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *string = [textView.text stringByReplacingCharactersInRange:range withString:text];
    
    // Only need to validate the text if the user enters a character other than a backspace.
    // For example, if the `textView.text = researchki` and the `string = researchkit`.
    if (textView.text.length < string.length) {
        
        string = [[string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@""];
        
        if (_maxLength > 0 && string.length > _maxLength) {
            [self showValidityAlertWithMessage:[[self.formItem impliedAnswerFormat] localizedInvalidValueStringWithAnswerString:string]];
            return NO;
        }
    }
    
    return YES;
}

@end


#pragma mark - ORK1FormItemImageSelectionCell

@interface ORK1FormItemImageSelectionCell () <ORK1ImageSelectionViewDelegate>

@end


@implementation ORK1FormItemImageSelectionCell {
    ORK1ImageSelectionView *_selectionView;
}

- (void)cellInit {
    // Subclasses should override this
    
    self.labelLabel.text = nil;
    
    _selectionView = [[ORK1ImageSelectionView alloc] initWithImageChoiceAnswerFormat:(ORK1ImageChoiceAnswerFormat *)self.formItem.answerFormat
                                                                             answer:self.answer];
    _selectionView.delegate = self;
    
    self.contentView.layoutMargins = UIEdgeInsetsMake(VerticalMargin, HorizontalMargin, VerticalMargin, HorizontalMargin);
    
    [self.contentView addSubview:_selectionView];
    [self setUpConstraints];
    
    [super cellInit];
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    NSDictionary *views = @{@"selectionView": _selectionView };
    ORK1EnableAutoLayoutForViews(views.allValues);
    [constraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[selectionView]-|"
                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                             metrics:nil
                                               views:views]];
    [constraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[selectionView]-|"
                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                             metrics:nil
                                               views:views]];
    
    [NSLayoutConstraint activateConstraints:constraints];
}

#pragma mark ORK1ImageSelectionViewDelegate

- (void)selectionViewSelectionDidChange:(ORK1ImageSelectionView *)view {
    [self ork_setAnswer:view.answer];
    [self inputValueDidChange];
}

#pragma mark recover answer

- (void)answerDidChange {
    [super answerDidChange];
    [_selectionView setAnswer:self.answer];
}

@end


#pragma mark - ORK1FormItemScaleCell

@interface ORK1FormItemScaleCell () <ORK1ScaleSliderViewDelegate>

@end


@implementation ORK1FormItemScaleCell {
    ORK1ScaleSliderView *_sliderView;
    id<ORK1ScaleAnswerFormatProvider> _formatProvider;
}

- (id<ORK1ScaleAnswerFormatProvider>)formatProvider {
    if (_formatProvider == nil) {
        _formatProvider = (id<ORK1ScaleAnswerFormatProvider>)[self.formItem.answerFormat impliedAnswerFormat];
    }
    return _formatProvider;
}

- (void)cellInit {
    self.labelLabel.text = nil;
    
    _sliderView = [[ORK1ScaleSliderView alloc] initWithFormatProvider:(ORK1ScaleAnswerFormat *)self.formItem.answerFormat delegate:self];
    
    [self.contentView addSubview:_sliderView];
    [self setUpConstraints];
    
    [super cellInit];
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    NSDictionary *views = @{ @"sliderView": _sliderView };
    ORK1EnableAutoLayoutForViews(views.allValues);
    [constraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[sliderView]|"
                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                             metrics:nil
                                               views:views]];
    [constraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[sliderView]|"
                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                             metrics:nil
                                               views:views]];
    
    [NSLayoutConstraint activateConstraints:constraints];
}

#pragma mark recover answer

- (void)answerDidChange {
    [super answerDidChange];
    
    id<ORK1ScaleAnswerFormatProvider> formatProvider = self.formatProvider;
    id answer = self.answer;
    if (answer && answer != ORK1NullAnswerValue()) {
        
        [_sliderView setCurrentAnswerValue:answer];

    } else {
        if (answer == nil && [formatProvider defaultAnswer]) {
            [_sliderView setCurrentAnswerValue:[formatProvider defaultAnswer]];
            [self ork_setAnswer:_sliderView.currentAnswerValue];
        } else {
            [_sliderView setCurrentAnswerValue:nil];
        }
    }
}

- (void)scaleSliderViewCurrentValueDidChange:(ORK1ScaleSliderView *)sliderView {
    
    [self ork_setAnswer:sliderView.currentAnswerValue];
    [super inputValueDidChange];
}

@end


#pragma mark - ORK1FormItemPickerCell

@interface ORK1FormItemPickerCell () <ORK1PickerDelegate>

@end


@implementation ORK1FormItemPickerCell {
    id<ORK1Picker> _picker;
}


- (void)setFormItem:(ORK1FormItem *)formItem {
    ORK1AnswerFormat *answerFormat = formItem.impliedAnswerFormat;
    
    if (!(!formItem ||
          [answerFormat isKindOfClass:[ORK1DateAnswerFormat class]] ||
          [answerFormat isKindOfClass:[ORK1TimeOfDayAnswerFormat class]] ||
          [answerFormat isKindOfClass:[ORK1TimeIntervalAnswerFormat class]] ||
          [answerFormat isKindOfClass:[ORK1ValuePickerAnswerFormat class]] ||
          [answerFormat isKindOfClass:[ORK1MultipleValuePickerAnswerFormat class]] ||
          [answerFormat isKindOfClass:[ORK1HeightAnswerFormat class]] ||
          [answerFormat isKindOfClass:[ORK1WeightAnswerFormat class]])) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"formItem.answerFormat should be an ORK1DateAnswerFormat, ORK1TimeOfDayAnswerFormat, ORK1TimeIntervalAnswerFormat, ORK1ValuePicker, ORK1MultipleValuePickerAnswerFormat, ORK1HeightAnswerFormat, or ORK1WeightAnswerFormat instance" userInfo:nil];
    }
    [super setFormItem:formItem];
}

- (void)setDefaultAnswer:(id)defaultAnswer {
    ORK1_Log_Debug(@"%@", defaultAnswer);
    [super setDefaultAnswer:defaultAnswer];
}

- (void)answerDidChange {
    self.picker.answer = self.answer;
    self.textField.text = self.picker.selectedLabelText;
}

- (id<ORK1Picker>)picker {
    if (_picker == nil) {
        ORK1AnswerFormat *answerFormat = [self.formItem impliedAnswerFormat];
        _picker = [ORK1Picker pickerWithAnswerFormat:answerFormat answer:self.answer delegate:self];
    }
    
    return _picker;
}

- (void)inputValueDidChange {
    if (!_picker) {
        return;
    }
    
    self.textField.text = [_picker selectedLabelText];
    
    [self ork_setAnswer:_picker.answer];
    
    [self.textField setSelectedTextRange:nil];
    
    [super inputValueDidChange];
}

#pragma mark ORK1PickerDelegate

- (void)picker:(id)picker answerDidChangeTo:(id)answer {
    [self inputValueDidChange];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // hide keyboard
        [textField resignFirstResponder];
        
        // clear value
        [self inputValueDidClear];
        
        // reset picker
        [self answerDidChange];
    });
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    BOOL shouldBeginEditing = [super textFieldShouldBeginEditing:textField];
    
    if (shouldBeginEditing) {
        if (self.textFieldView.inputView == nil) {
            self.textField.inputView = self.picker.pickerView;
        }
        
        [self.picker pickerWillAppear];
    }
    
    return shouldBeginEditing;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return NO;
}

@end


#pragma mark - ORK1FormItemLocationCell

@interface ORK1FormItemLocationCell () <ORK1LocationSelectionViewDelegate>

@property (nonatomic, assign) BOOL editingHighlight;

@end


@implementation ORK1FormItemLocationCell {
    ORK1LocationSelectionView *_selectionView;
    NSLayoutConstraint *_heightConstraint;
    NSLayoutConstraint *_bottomConstraint;
}

- (void)cellInit {
    [super cellInit];
    
    _selectionView = [[ORK1LocationSelectionView alloc] initWithFormMode:YES
                                                     useCurrentLocation:((ORK1LocationAnswerFormat *)self.formItem.answerFormat).useCurrentLocation
                                                          leadingMargin:self.separatorInset.left];
    _selectionView.delegate = self;
    
    [self.contentView addSubview:_selectionView];

    if (self.formItem.placeholder != nil) {
        [_selectionView setPlaceholderText:self.formItem.placeholder];
    }
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    NSDictionary *dictionary = @{@"_selectionView":_selectionView};
    ORK1EnableAutoLayoutForViews([dictionary allValues]);
    NSDictionary *metrics = @{@"verticalMargin":@(VerticalMargin), @"horizontalMargin":@(self.separatorInset.left), @"verticalMarginBottom":@(VerticalMargin - (1.0 / [UIScreen mainScreen].scale))};
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_selectionView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:metrics views:dictionary]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_selectionView]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:metrics views:dictionary]];
    _bottomConstraint = [NSLayoutConstraint constraintWithItem:_selectionView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    [constraints addObject:_bottomConstraint];
    _heightConstraint = [NSLayoutConstraint constraintWithItem:_selectionView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_selectionView.intrinsicContentSize.height];
    _heightConstraint.priority = UILayoutPriorityDefaultHigh;
    [constraints addObject:_heightConstraint];
    
    [self.contentView addConstraints:constraints];
}

- (void)setFormItem:(ORK1FormItem *)formItem {
    [super setFormItem:formItem];
    
    if (_selectionView) {
        [_selectionView setPlaceholderText:formItem.placeholder];
    }
}

- (void)answerDidChange {
    _selectionView.answer = self.answer;
}

- (void)setEditingHighlight:(BOOL)editingHighlight {
    _editingHighlight = editingHighlight;
    [_selectionView setTextColor:( _editingHighlight ? [self tintColor] : [UIColor blackColor])];
}

- (void)locationSelectionViewDidBeginEditing:(ORK1LocationSelectionView *)view {
    self.editingHighlight = YES;
    [_selectionView showMapViewIfNecessary];
    [self.delegate formItemCellDidBecomeFirstResponder:self];
}

- (void)locationSelectionViewDidEndEditing:(ORK1LocationSelectionView *)view {
    self.editingHighlight = NO;
    [self.delegate formItemCellDidResignFirstResponder:self];
}

- (void)locationSelectionViewDidChange:(ORK1LocationSelectionView *)view {
    [self inputValueDidChange];
}

- (void)locationSelectionViewNeedsResize:(ORK1LocationSelectionView *)view {
    UITableView *tableView = [self parentTableView];
    
    _heightConstraint.constant = _selectionView.intrinsicContentSize.height;
    _bottomConstraint.constant = -(VerticalMargin - (1.0 / [UIScreen mainScreen].scale));
    
    [tableView beginUpdates];
    [tableView endUpdates];

}

- (void)locationSelectionView:(ORK1LocationSelectionView *)view didFailWithErrorTitle:(NSString *)title message:(NSString *)message {
    [self showErrorAlertWithTitle:title message:message];
}

- (void)inputValueDidChange {
    [self ork_setAnswer:_selectionView.answer];
    [super inputValueDidChange];
}

- (BOOL)becomeFirstResponder {
    return [_selectionView becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    return [_selectionView resignFirstResponder];
}

@end
