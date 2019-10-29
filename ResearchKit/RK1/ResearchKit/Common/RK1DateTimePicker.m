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


#import "RK1DateTimePicker.h"

#import "RK1AnswerFormat_Internal.h"

#import "RK1Helpers_Internal.h"


@interface RK1DateTimePicker ()

@property (nonatomic, strong) RK1AnswerFormat *answerFormat;
@property (nonatomic, strong) NSCalendar *calendar;

@end


@implementation RK1DateTimePicker {
    NSDateFormatter *_labelFormatter;
    UIDatePicker *_pickerView;
    NSDate *_date;
    __weak id<RK1PickerDelegate> _pickerDelegate;
    id _answer;
}

@synthesize pickerDelegate = _pickerDelegate;
@synthesize answer = _answer;

- (instancetype)initWithAnswerFormat:(RK1AnswerFormat *)answerFormat answer:(id)answer pickerDelegate:(id<RK1PickerDelegate>)delegate {
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
        [_pickerView addTarget:self action:@selector(valueDidChange:) forControlEvents:UIControlEventValueChanged];
        self.answerFormat = _answerFormat;
        self.answer = _answer;
    }
    return _pickerView;
}

- (void)setAnswer:(id)answer {
    _answer = answer;
    
    if ([self isTimeOfDay]) {
        RK1TimeOfDayAnswerFormat *timeOfDayAnswerFormat = (RK1TimeOfDayAnswerFormat *)self.answerFormat;
        
        if (answer && answer != RK1NullAnswerValue()) {
            NSDateComponents *timeOfDayComponents = (NSDateComponents *)answer;
            
            NSDate *dateValue = RK1TimeOfDayDateFromComponents(timeOfDayComponents);
            [self setDate:dateValue];
            
        } else {
            [self setDate:[timeOfDayAnswerFormat pickerDefaultDate]];
        }
    } else {
        RK1DateAnswerFormat *dateAnswerFormat = (RK1DateAnswerFormat *)self.answerFormat;
        
        if (answer && answer != RK1NullAnswerValue()) {
            NSDate *defaultDate = (NSDate *)answer;
            [self setDate:defaultDate];
        } else {
            NSDate *defaultDate = [dateAnswerFormat pickerDefaultDate];
            [self setDate:defaultDate];
        }
    }
}

- (void)setAnswerFormat:(RK1AnswerFormat *)answerFormat {
    RK1QuestionType questionType = answerFormat.questionType;
    int datePickerMode = -1;
    switch (questionType) {
        case RK1QuestionTypeDate:
            datePickerMode = UIDatePickerModeDate;
            break;
        case RK1QuestionTypeDateAndTime:
            datePickerMode = UIDatePickerModeDateAndTime;
            break;
        case RK1QuestionTypeTimeOfDay:
            datePickerMode = UIDatePickerModeTime;
            break;
        default:
            break;
    }
    
    NSAssert((datePickerMode >= 0), @"questionType should be Date, DateAndTime, or TimeOfDay.");
    
    _answerFormat = answerFormat;
    
    _pickerView.datePickerMode = datePickerMode;
    
    if ([self isTimeOfDay]) {
        [self setDate:[(RK1TimeOfDayAnswerFormat *)answerFormat pickerDefaultDate]];
    } else {
        RK1DateAnswerFormat *dateAnswerFormat = (RK1DateAnswerFormat *)answerFormat;
        [self setDate:[dateAnswerFormat pickerDefaultDate]];
        _pickerView.calendar = [dateAnswerFormat currentCalendar];
        _calendar = [dateAnswerFormat currentCalendar];
        
        [_pickerView setMinimumDate:[dateAnswerFormat pickerMinimumDate]];
        [_pickerView setMaximumDate:[dateAnswerFormat pickerMaximumDate]];
    }
    
    _labelFormatter = nil;
}

- (void)setDate:(NSDate *)date {
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
        case RK1QuestionTypeDate:
            dateFormat = [NSDateFormatter dateFormatFromTemplate:@"Mdy" options:0 locale:[NSLocale currentLocale]];
            break;
        case RK1QuestionTypeDateAndTime:
            dateFormat = [NSDateFormatter dateFormatFromTemplate:@"yEMdhma" options:0 locale:[NSLocale currentLocale]];
            break;
        case RK1QuestionTypeTimeOfDay:
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
    if (_answer == nil || _answer == RK1NullAnswerValue()) {
        return nil;
    }
    
    return [[self labelFormatter] stringFromDate:_date];
}

- (void)pickerWillAppear {
    // Report current value, since RK1TimeIntervalPicker always has a value
    [self pickerView];
    [self valueDidChange:self];
}

- (void)valueDidChange:(id)sender {
    _date = _pickerView.date;
    
    if ([self isTimeOfDay]) {
        NSDateComponents *answer = RK1TimeOfDayComponentsFromDate([_pickerView date]);
        _answer = answer;
    } else {
        NSDate *dateAnswer = _date;
        _answer = dateAnswer;
    }
    
    if ([self.pickerDelegate respondsToSelector:@selector(picker:answerDidChangeTo:)]) {
        [self.pickerDelegate picker:self answerDidChangeTo:self.answer];
    }
}

- (RK1QuestionType)questionType {
    return self.answerFormat.questionType;
}

- (BOOL)isTimeOfDay {
    return [self questionType] == RK1QuestionTypeTimeOfDay;
}

- (void)currentLocaleDidChange:(NSNotification *)notification {
    _labelFormatter = nil;
    [self valueDidChange:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
