/*
 Copyright (c) 2017, Nino Guba.
 
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


#import "ORK1WeightPicker.h"
#import "ORK1Result_Private.h"
#import "ORK1AnswerFormat_Internal.h"
#import "ORK1AccessibilityFunctions.h"


@interface ORK1WeightPicker () <UIPickerViewDataSource, UIPickerViewDelegate>

@end


@implementation ORK1WeightPicker {
    UIPickerView *_pickerView;
    ORK1WeightAnswerFormat *_answerFormat;
    id _answer;
    __weak id<ORK1PickerDelegate> _pickerDelegate;
    NSArray *_majorValues;
    NSArray *_minorValues;
    double _canonicalMaximumValue;
    double _canonicalMinimumValue;
}

@synthesize pickerDelegate = _pickerDelegate;

- (instancetype)initWithAnswerFormat:(ORK1WeightAnswerFormat *)answerFormat answer:(id)answer pickerDelegate:(id<ORK1PickerDelegate>)delegate {
    self = [super init];
    if (self) {
        NSAssert([answerFormat isKindOfClass:[ORK1WeightAnswerFormat class]], @"answerFormat should be ORK1WeightAnswerFormat");
                
        // Take into account locale changes so unit string can be updated
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(currentLocaleDidChange:)
                                                     name:NSCurrentLocaleDidChangeNotification object:nil];
        
        _answerFormat = answerFormat;
        _pickerDelegate = delegate;
        self.answer = answer;
        
        _canonicalMaximumValue = ORK1DoubleDefaultValue;
        _canonicalMinimumValue = ORK1DoubleDefaultValue;

        if (_answerFormat.useMetricSystem) {
            _majorValues = [self kilogramValues];
        } else {
            _majorValues = [self poundValues];
        }
        
        if (_answerFormat.numericPrecision == ORK1NumericPrecisionHigh) {
            _minorValues = [self _minorValues];
        }
    }
    return self;
}

- (UIView *)pickerView {
    if (_pickerView == nil) {
        _pickerView = [[UIPickerView alloc] init];
        _pickerView.dataSource = self;
        _pickerView.delegate = self;
        [self setAnswer:_answer];
    }
    return _pickerView;
}

- (void)setAnswer:(id)answer {
    _answer = answer;
    
    if (ORK1IsAnswerEmpty(answer)) {
        answer = [self defaultAnswerValue];
    }
    
    if (_answerFormat.useMetricSystem) {
        if (_answerFormat.numericPrecision != ORK1NumericPrecisionHigh) {
            NSUInteger index = [_majorValues indexOfObject:@((NSInteger)((NSNumber *)answer).doubleValue)];
            if (index == NSNotFound) {
                [self setAnswer:[self defaultAnswerValue]];
                return;
            }
            [_pickerView selectRow:index inComponent:0 animated:NO];
        } else {
            double whole, fraction;
            ORK1KilogramsToWholeAndFraction(((NSNumber *)answer).doubleValue, &whole, &fraction);
            NSUInteger wholeIndex = [_majorValues indexOfObject:@((NSInteger)whole)];
            NSUInteger fractionIndex = [_minorValues indexOfObject:@((NSInteger)fraction)];
            if (wholeIndex == NSNotFound || fractionIndex == NSNotFound) {
                [self setAnswer:[self defaultAnswerValue]];
                return;
            }
            [_pickerView selectRow:wholeIndex inComponent:0 animated:NO];
            [_pickerView selectRow:fractionIndex inComponent:1 animated:NO];
            [_pickerView selectRow:0 inComponent:2 animated:NO];
        }
    } else {
        if (_answerFormat.numericPrecision != ORK1NumericPrecisionHigh) {
            double pounds = ORK1KilogramsToPounds(((NSNumber *)answer).doubleValue);
            NSUInteger poundsIndex = [_majorValues indexOfObject:@((NSInteger)pounds)];
            if (poundsIndex == NSNotFound) {
                [self setAnswer:[self defaultAnswerValue]];
                return;
            }
            [_pickerView selectRow:poundsIndex inComponent:0 animated:NO];
        } else {
            double pounds, ounces;
            ORK1KilogramsToPoundsAndOunces(((NSNumber *)answer).doubleValue, &pounds, &ounces);
            NSUInteger poundsIndex = [_majorValues indexOfObject:@((NSInteger)pounds)];
            NSUInteger ouncesIndex = [_minorValues indexOfObject:@((NSInteger)ounces)];
            if (poundsIndex == NSNotFound || ouncesIndex == NSNotFound) {
                [self setAnswer:[self defaultAnswerValue]];
                return;
            }
            [_pickerView selectRow:poundsIndex inComponent:0 animated:NO];
            [_pickerView selectRow:ouncesIndex inComponent:1 animated:NO];
        }
    }
}

- (id)answer {
    return _answer;
}

- (NSNumber *)defaultAnswerValue {
    double defaultValue = ORK1DoubleDefaultValue;
    if (_answerFormat.defaultValue == ORK1DoubleDefaultValue) {
        if (_answerFormat.useMetricSystem) {
            defaultValue = 60.00; // Default metric weight: 60 kg
        } else {
            defaultValue = 60.33; // Default USC weight: 133 lbs
        }
    } else {
        if (_answerFormat.useMetricSystem) {
            defaultValue = _answerFormat.defaultValue;
        } else {
            defaultValue = ORK1PoundsToKilograms(_answerFormat.defaultValue); // Convert to kg
        }
    }
    // Ensure default value is within bounds
    if ((_canonicalMinimumValue != ORK1DoubleDefaultValue) && (defaultValue < _canonicalMinimumValue)) {
        defaultValue = _canonicalMinimumValue;
    } else if ((_canonicalMaximumValue  != ORK1DoubleDefaultValue) && (defaultValue > _canonicalMaximumValue)) {
        defaultValue = _canonicalMaximumValue;
    }
    
    return @(defaultValue);
}

- (NSNumber *)selectedAnswerValue {
    NSNumber *answer = nil;
    if (_answerFormat.useMetricSystem) {
        NSInteger wholeRow = [_pickerView selectedRowInComponent:0];
        NSNumber *whole = _majorValues[wholeRow];
        if (_answerFormat.numericPrecision != ORK1NumericPrecisionHigh) {
            answer = @( whole.doubleValue );
        } else {
            NSInteger fractionRow = [_pickerView selectedRowInComponent:1];
            NSNumber *fraction = _minorValues[fractionRow];
            answer = @( ORK1WholeAndFractionToKilograms(whole.doubleValue, fraction.doubleValue) );
        }
    } else {
        NSInteger poundsRow = [_pickerView selectedRowInComponent:0];
        NSNumber *pounds = _majorValues[poundsRow];
        if (_answerFormat.numericPrecision != ORK1NumericPrecisionHigh) {
            answer = @( ORK1PoundsToKilograms(pounds.doubleValue) );
        } else {
            NSInteger ouncesRow = [_pickerView selectedRowInComponent:1];
            NSNumber *ounces = _minorValues[ouncesRow];
            answer = @( ORK1PoundsAndOuncesToKilograms(pounds.doubleValue, ounces.doubleValue) );
        }
    }
    
    return answer;
}

- (NSString *)selectedLabelText {
    return [_answerFormat stringForAnswer:_answer];
}

- (void)pickerWillAppear {
    // Report current value, since ORK1WeightPicker always has a value
    [self pickerView];
    [self valueDidChange:self];
    [self accessibilityFocusOnPickerElement];
}

- (void)valueDidChange:(id)sender {
    _answer = [self selectedAnswerValue];
    if ([self.pickerDelegate respondsToSelector:@selector(picker:answerDidChangeTo:)]) {
        [self.pickerDelegate picker:self answerDidChangeTo:_answer];
    }
}

#pragma mark - Accessibility

- (void)accessibilityFocusOnPickerElement {
    if (UIAccessibilityIsVoiceOverRunning()) {
        ORK1AccessibilityPerformBlockAfterDelay(0.75, ^{
            NSArray *axElements = [self.pickerView accessibilityElements];
            if ([axElements count] > 0) {
                UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, [axElements objectAtIndex:0]);
            }
        });
    }
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return (_answerFormat.numericPrecision != ORK1NumericPrecisionHigh) ? 1 : (_answerFormat.useMetricSystem ? 3 : 2);
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    NSInteger numberOfRows = 0;
    if (component == 0) {
        numberOfRows = _majorValues.count;
    } else if (component == 1) {
        numberOfRows = _minorValues.count;
    } else {
        numberOfRows = 1;
    }
    return numberOfRows;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSString *title = nil;
    if (_answerFormat.useMetricSystem) {
        if (component == 0) {
            if (_answerFormat.numericPrecision != ORK1NumericPrecisionHigh) {
                title = [NSString stringWithFormat:@"%@ %@", _majorValues[row], ORK1LocalizedString(@"MEASURING_UNIT_KG", nil)];
            } else {
                title = [NSString stringWithFormat:@"%@", _majorValues[row]];
            }
        } else if (component == 1) {
            NSNumberFormatter *formatter = ORK1DecimalNumberFormatter();
            formatter.minimumIntegerDigits = 2;
            formatter.maximumFractionDigits = 0;
            title = [NSString stringWithFormat:@".%@", [formatter stringFromNumber:_minorValues[row]]];
        } else if (component == 2) {
            title = ORK1LocalizedString(@"MEASURING_UNIT_KG", nil);
        }
    } else {
        if (component == 0) {
            title = [NSString stringWithFormat:@"%@ %@", _majorValues[row], ORK1LocalizedString(@"MEASURING_UNIT_LB", nil)];
        } else {
            title = [NSString stringWithFormat:@"%@ %@", _minorValues[row], ORK1LocalizedString(@"MEASURING_UNIT_OZ", nil)];
        }
    }    
    return title;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    [self valueDidChange:self];
}

- (NSArray *)kilogramValues {
    NSArray *wholeValues = nil;
    NSMutableArray *mutableWholeValues = [[NSMutableArray alloc] init];

    double minimumValue = 0;
    double maximumValue = 657;
    if ((_answerFormat.minimumValue != ORK1DoubleDefaultValue) && (_answerFormat.minimumValue <= maximumValue)) {
        minimumValue = _answerFormat.minimumValue;
    }
    if ((_answerFormat.maximumValue != ORK1DoubleDefaultValue) && (_answerFormat.maximumValue >= minimumValue)) {
        maximumValue = _answerFormat.maximumValue;
    }
    _canonicalMinimumValue = minimumValue;
    _canonicalMaximumValue = maximumValue;
    
    for (double i = minimumValue; i <= maximumValue; i++) {
        [mutableWholeValues addObject:@(i)];
        if (_answerFormat.numericPrecision == ORK1NumericPrecisionDefault) {
            [mutableWholeValues addObject:@(i + 0.5)];
        }
    }
    wholeValues = [mutableWholeValues copy];
    return wholeValues;
}

- (NSArray *)poundValues {
    NSArray *wholeValues = nil;
    NSMutableArray *mutableWholeValues = [[NSMutableArray alloc] init];

    double minimumValue = 0;
    double maximumValue = 1450;
    if ((_answerFormat.minimumValue != ORK1DoubleDefaultValue) && (_answerFormat.minimumValue <= maximumValue)) {
        minimumValue = _answerFormat.minimumValue;
    }
    if ((_answerFormat.maximumValue != ORK1DoubleDefaultValue) && (_answerFormat.maximumValue >= minimumValue)) {
        maximumValue = _answerFormat.maximumValue;
    }
    _canonicalMinimumValue = ORK1PoundsToKilograms(minimumValue); // Convert to kg
    _canonicalMaximumValue = ORK1PoundsToKilograms(maximumValue); // Convert to kg
    
    for (NSInteger i = minimumValue; i <= maximumValue; i++) {
        [mutableWholeValues addObject:[NSNumber numberWithInteger:i]];
    }
    wholeValues = [mutableWholeValues copy];
    return wholeValues;
}

- (NSArray *)_minorValues {
    NSArray *wholeValues = nil;
    NSMutableArray *mutableWholeValues = [[NSMutableArray alloc] init];
    
    NSInteger maximumValue = 99;
    if (!_answerFormat.useMetricSystem) {
        maximumValue = 15;
    }
    for (NSInteger i = 0; i <= maximumValue; i++) {
        [mutableWholeValues addObject:@(i)];
    }
    wholeValues = [mutableWholeValues copy];
    return wholeValues;
}

- (void)currentLocaleDidChange:(NSNotification *)notification {
    [_pickerView reloadAllComponents];
    [self setAnswer:[self defaultAnswerValue]];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end