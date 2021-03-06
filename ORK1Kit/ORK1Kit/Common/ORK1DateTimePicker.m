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


#import "ORK1DateTimePicker.h"

#import "ORK1AnswerFormat_Internal.h"

#import "ORK1Helpers_Internal.h"


@interface ORK1DateTimePicker ()

@property (nonatomic, strong) ORK1AnswerFormat *answerFormat;
@property (nonatomic, strong) NSCalendar *calendar;

@end


@implementation ORK1DateTimePicker {
    NSDateFormatter *_labelFormatter;
    UIDatePicker *_pickerView;
    NSDate *_date;
    __weak id<ORK1PickerDelegate> _pickerDelegate;
    id _answer;
}

@synthesize pickerDelegate = _pickerDelegate;
@synthesize answer = _answer;

- (instancetype)initWithAnswerFormat:(ORK1AnswerFormat *)answerFormat answer:(id)answer pickerDelegate:(id<ORK1PickerDelegate>)delegate {
    self = [super init];
    if (self) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentLocaleDidChange:) name:NSCurrentLocaleDidChangeNotification object:nil];
        
        self.answerFormat = answerFormat;
        self.answer = answer;
        self.pickerDelegate = delegate;
        
    }
    return self;
}

- (UIDatePicker *)pickerView {
    if (_pickerView == nil) {
        _pickerView = [[UIDatePicker alloc] init];
        if (@available(iOS 14, *)) {
            _pickerView.preferredDatePickerStyle = UIDatePickerStyleWheels;
        }
        [_pickerView addTarget:self action:@selector(valueDidChange:) forControlEvents:UIControlEventValueChanged];
        self.answerFormat = _answerFormat;
        self.answer = _answer;
    }
    return _pickerView;
}

- (void)setAnswer:(id)answer {
    _answer = answer;
    
    if ([self isTimeOfDay]) {
        ORK1TimeOfDayAnswerFormat *timeOfDayAnswerFormat = (ORK1TimeOfDayAnswerFormat *)self.answerFormat;
        
        if (answer && answer != ORK1NullAnswerValue()) {
            NSDateComponents *timeOfDayComponents = (NSDateComponents *)answer;
            
            NSDate *dateValue = ORK1TimeOfDayDateFromComponents(timeOfDayComponents);
            [self setDate:dateValue];
            
        } else {
            [self setDate:[timeOfDayAnswerFormat pickerDefaultDate]];
        }
    } else {
        ORK1DateAnswerFormat *dateAnswerFormat = (ORK1DateAnswerFormat *)self.answerFormat;
        
        if (answer && answer != ORK1NullAnswerValue()) {
            NSDate *defaultDate = (NSDate *)answer;
            [self setDate:defaultDate];
        } else {
            NSDate *defaultDate = [dateAnswerFormat pickerDefaultDate];
            [self setDate:defaultDate];
        }
    }
}

- (void)setAnswerFormat:(ORK1AnswerFormat *)answerFormat {
    ORK1QuestionType questionType = answerFormat.questionType;
    int datePickerMode = -1;
    switch (questionType) {
        case ORK1QuestionTypeDate:
            datePickerMode = UIDatePickerModeDate;
            break;
        case ORK1QuestionTypeDateAndTime:
            datePickerMode = UIDatePickerModeDateAndTime;
            break;
        case ORK1QuestionTypeTimeOfDay:
            datePickerMode = UIDatePickerModeTime;
            break;
        default:
            break;
    }
    
    NSAssert((datePickerMode >= 0), @"questionType should be Date, DateAndTime, or TimeOfDay.");
    
    _answerFormat = answerFormat;
    
    _pickerView.datePickerMode = datePickerMode;
    
    if ([self isTimeOfDay]) {
        [self setDate:[(ORK1TimeOfDayAnswerFormat *)answerFormat pickerDefaultDate]];
    } else {
        ORK1DateAnswerFormat *dateAnswerFormat = (ORK1DateAnswerFormat *)answerFormat;
        _pickerView.calendar = [dateAnswerFormat currentCalendar];
        _calendar = [dateAnswerFormat currentCalendar];
        
        [_pickerView setMinimumDate:[dateAnswerFormat pickerMinimumDate]];
        [_pickerView setMaximumDate:[dateAnswerFormat pickerMaximumDate]];
        
        [self setDate:[dateAnswerFormat pickerDefaultDate]];
    }
    
    _labelFormatter = nil;
}

- (void)setDate:(NSDate *)date {
    if ([self.answerFormat isKindOfClass:[ORK1DateAnswerFormat class]]) {
        ORK1DateAnswerFormat *format = (ORK1DateAnswerFormat *)self.answerFormat;
        if (format.minimumDate && [date compare:format.minimumDate] == NSOrderedAscending) {
            date = format.minimumDate;
        }
        if (format.maximumDate && [date compare:format.maximumDate] == NSOrderedDescending) {
            date = format.maximumDate;
        }
    }
    _date = date;
    _pickerView.date = date;
}

- (NSDateFormatter *)labelFormatter {
    if (_labelFormatter) {
        _labelFormatter.calendar = self.calendar;
        return _labelFormatter;
    }
    
    NSString *dateFormat = nil;
    switch ([self questionType]) {
        case ORK1QuestionTypeDate:
            dateFormat = [NSDateFormatter dateFormatFromTemplate:@"Mdy" options:0 locale:[NSLocale currentLocale]];
            break;
        case ORK1QuestionTypeDateAndTime:
            dateFormat = [NSDateFormatter dateFormatFromTemplate:@"yEMdhma" options:0 locale:[NSLocale currentLocale]];
            break;
        case ORK1QuestionTypeTimeOfDay:
            dateFormat = [NSDateFormatter dateFormatFromTemplate:@"hma" options:0 locale:[NSLocale currentLocale]];
            break;
        default:
            break;
    }
    
    if (dateFormat != nil) {
        NSDateFormatter *dfm = [NSDateFormatter new];
        dfm.dateFormat = dateFormat;
        dfm.calendar = self.calendar;
        
        _labelFormatter = dfm;
    }
    
    return _labelFormatter;
}

- (NSString *)selectedLabelText {
    if (_answer == nil || _answer == ORK1NullAnswerValue()) {
        return nil;
    }
    
    return [[self labelFormatter] stringFromDate:_date];
}

- (void)pickerWillAppear {
    // Report current value, since ORK1TimeIntervalPicker always has a value
    [self pickerView];
    [self valueDidChange:self];
}

- (void)valueDidChange:(id)sender {
    _date = _pickerView.date;
    
    if ([self isTimeOfDay]) {
        NSDateComponents *answer = ORK1TimeOfDayComponentsFromDate([_pickerView date]);
        _answer = answer;
    } else {
        NSDate *dateAnswer = _date;
        _answer = dateAnswer;
    }
    
    if ([self.pickerDelegate respondsToSelector:@selector(picker:answerDidChangeTo:)]) {
        [self.pickerDelegate picker:self answerDidChangeTo:self.answer];
    }
}

- (ORK1QuestionType)questionType {
    return self.answerFormat.questionType;
}

- (BOOL)isTimeOfDay {
    return [self questionType] == ORK1QuestionTypeTimeOfDay;
}

- (void)currentLocaleDidChange:(NSNotification *)notification {
    _labelFormatter = nil;
    [self valueDidChange:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
