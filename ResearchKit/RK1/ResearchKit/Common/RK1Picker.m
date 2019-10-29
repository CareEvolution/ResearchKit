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


#import "RK1Picker.h"

#import "RK1DateTimePicker.h"
#import "RK1HeightPicker.h"
#import "RK1WeightPicker.h"
#import "RK1TimeIntervalPicker.h"
#import "RK1ValuePicker.h"
#import "RK1MultipleValuePicker.h"

#import "RK1AnswerFormat.h"

/**
 Creates a picker appropriate to the type required by answerformat
 
 @param answerFormat   An RK1AnswerFormat object which specified the format of the result
 @param answer         The current answer (to set as the picker's current result)
 @param delegate       A delegate who conforms to RK1PickerDelegate
 
 @return The picker object
 */
id<RK1Picker> createRK1Picker(RK1AnswerFormat *answerFormat, id answer, id<RK1PickerDelegate> delegate) {
    id<RK1Picker> picker;
    
    if ([answerFormat isKindOfClass:[RK1ValuePickerAnswerFormat class]]) {
        picker = [[RK1ValuePicker alloc] initWithAnswerFormat:answerFormat answer:answer pickerDelegate:delegate];
    } else if ([answerFormat isKindOfClass:[RK1TimeIntervalAnswerFormat class]]) {
        picker = [[RK1TimeIntervalPicker alloc] initWithAnswerFormat:answerFormat answer:answer pickerDelegate:delegate];
    } else if ([answerFormat isKindOfClass:[RK1DateAnswerFormat class]] || [answerFormat isKindOfClass:[RK1TimeOfDayAnswerFormat class]]) {
        picker = [[RK1DateTimePicker alloc] initWithAnswerFormat:answerFormat answer:answer pickerDelegate:delegate];
    } else if ([answerFormat isKindOfClass:[RK1HeightAnswerFormat class]]) {
        picker = [[RK1HeightPicker alloc] initWithAnswerFormat:answerFormat answer:answer pickerDelegate:delegate];
    } else if ([answerFormat isKindOfClass:[RK1WeightAnswerFormat class]]) {
        picker = [[RK1WeightPicker alloc] initWithAnswerFormat:answerFormat answer:answer pickerDelegate:delegate];
    } else if ([answerFormat isKindOfClass:[RK1MultipleValuePickerAnswerFormat class]]) {
        picker = [[RK1MultipleValuePicker alloc] initWithAnswerFormat:answerFormat answer:answer pickerDelegate:delegate];
    }

    return picker;
}


@implementation RK1Picker : NSObject

/**
 Creates a picker appropriate to the type required by answerformat
 
 @param answerFormat   An RK1AnswerFormat object which specified the format of the result
 @param answer         A default answer (to set as the picker's current result), or nil if no answer specified.
 @param delegate       A delegate who conforms to RK1PickerDelegate
 
 @return The picker object
 */
+ (id<RK1Picker>)pickerWithAnswerFormat:(RK1AnswerFormat *)answerFormat answer:(id)answer delegate:(id<RK1PickerDelegate>) delegate {
    id<RK1Picker> picker;
    
    if ([answerFormat isKindOfClass:[RK1ValuePickerAnswerFormat class]]) {
        picker = [[RK1ValuePicker alloc] initWithAnswerFormat:answerFormat answer:answer pickerDelegate:delegate];
    } else if ([answerFormat isKindOfClass:[RK1TimeIntervalAnswerFormat class]]) {
        picker = [[RK1TimeIntervalPicker alloc] initWithAnswerFormat:answerFormat answer:answer pickerDelegate:delegate];
    } else if ([answerFormat isKindOfClass:[RK1DateAnswerFormat class]] || [answerFormat isKindOfClass:[RK1TimeOfDayAnswerFormat class]]) {
        picker = [[RK1DateTimePicker alloc] initWithAnswerFormat:answerFormat answer:answer pickerDelegate:delegate];
    } else if ([answerFormat isKindOfClass:[RK1HeightAnswerFormat class]]) {
        picker = [[RK1HeightPicker alloc] initWithAnswerFormat:answerFormat answer:answer pickerDelegate:delegate];
    } else if ([answerFormat isKindOfClass:[RK1WeightAnswerFormat class]]) {
        picker = [[RK1WeightPicker alloc] initWithAnswerFormat:answerFormat answer:answer pickerDelegate:delegate];
    } else if ([answerFormat isKindOfClass:[RK1MultipleValuePickerAnswerFormat class]]) {
        picker = [[RK1MultipleValuePicker alloc] initWithAnswerFormat:answerFormat answer:answer pickerDelegate:delegate];
    }
    
    return picker;
}

@end
