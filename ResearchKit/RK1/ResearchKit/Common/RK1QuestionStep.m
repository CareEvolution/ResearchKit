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


#import "RK1QuestionStep.h"

#import "RK1QuestionStepViewController.h"

#import "RK1AnswerFormat_Internal.h"
#import "RK1Step_Private.h"

#import "RK1Helpers_Internal.h"


@implementation RK1QuestionStep

+ (Class)stepViewControllerClass {
    return [RK1QuestionStepViewController class];
}

+ (instancetype)questionStepWithIdentifier:(NSString *)identifier
                                  title:(NSString *)title
                                    answer:(RK1AnswerFormat *)answer {
    
    RK1QuestionStep *step = [[RK1QuestionStep alloc] initWithIdentifier:identifier];
    step.title = title;
    step.answerFormat = answer;
    return step;
}

+ (instancetype)questionStepWithIdentifier:(NSString *)identifier
                                     title:(nullable NSString *)title
                                      text:(nullable NSString *)text
                                    answer:(nullable RK1AnswerFormat *)answerFormat {

    RK1QuestionStep *step = [[RK1QuestionStep alloc] initWithIdentifier:identifier];
    step.title = title;
    step.text = text;
    step.answerFormat = answerFormat;
    return step;
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    
    self = [super initWithIdentifier:identifier];
    if (self) {
        self.optional = YES;
        self.useSurveyMode = YES;
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.optional = YES;
        self.useSurveyMode = YES;
    }
    return self;
}

- (void)validateParameters {
    [super validateParameters];
    
    if([self.answerFormat isKindOfClass:[RK1ConfirmTextAnswerFormat class]]) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"RK1ConfirmTextAnswerFormat can only be used with an RK1FormStep."
                                     userInfo:nil];
    }
    
    [[self impliedAnswerFormat] validateParameters];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    RK1QuestionStep *questionStep = [super copyWithZone:zone];
    questionStep.answerFormat = [self.answerFormat copy];
    questionStep.placeholder = [self.placeholder copy];
    return questionStep;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return isParentSame &&
    RK1EqualObjects(self.answerFormat, castObject.answerFormat) &&
    RK1EqualObjects(self.placeholder, castObject.placeholder);
}

- (NSUInteger)hash {
    return super.hash ^ self.answerFormat.hash;
}

- (RK1QuestionType)questionType {
    RK1AnswerFormat *impliedFormat = [self impliedAnswerFormat];
    return impliedFormat.questionType;
}

- (RK1AnswerFormat *)impliedAnswerFormat {
    return [self.answerFormat impliedAnswerFormat];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        RK1_DECODE_OBJ_CLASS(aDecoder, answerFormat, RK1AnswerFormat);
        RK1_DECODE_OBJ_CLASS(aDecoder, placeholder, NSString);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    
    RK1_ENCODE_OBJ(aCoder, answerFormat);
    RK1_ENCODE_OBJ(aCoder, placeholder);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isFormatImmediateNavigation {
    RK1QuestionType questionType = self.questionType;
    return (self.optional == NO) && ((questionType == RK1QuestionTypeBoolean) || (questionType == RK1QuestionTypeSingleChoice));
}

- (BOOL)isFormatChoiceWithImageOptions {
    return [[self impliedAnswerFormat] isKindOfClass:[RK1ImageChoiceAnswerFormat class]];
}

- (BOOL)isFormatChoiceValuePicker {
    return [[self impliedAnswerFormat] isKindOfClass:[RK1ValuePickerAnswerFormat class]];
}

- (BOOL)isFormatTextfield {
    RK1AnswerFormat *impliedAnswerFormat = [self impliedAnswerFormat];
    return [impliedAnswerFormat isKindOfClass:[RK1TextAnswerFormat class]] && ![(RK1TextAnswerFormat *)impliedAnswerFormat multipleLines];
}

- (BOOL)isFormatFitsChoiceCells {
    return ((self.questionType == RK1QuestionTypeSingleChoice && ![self isFormatChoiceWithImageOptions] && ![self isFormatChoiceValuePicker]) ||
            (self.questionType == RK1QuestionTypeMultipleChoice && ![self isFormatChoiceWithImageOptions]) ||
            self.questionType == RK1QuestionTypeBoolean);
}

- (BOOL)formatRequiresTableView {
    return [self isFormatFitsChoiceCells];
}

- (NSSet<HKObjectType *> *)requestedHealthKitTypesForReading {
    HKObjectType *objType = [[self answerFormat] healthKitObjectTypeForAuthorization];
    return (objType != nil) ? [NSSet setWithObject:objType] : nil;
}

@end
