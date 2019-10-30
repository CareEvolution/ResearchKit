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


#import "DynamicTask.h"

@import ResearchKitLegacy.Private;


@interface DynamicTask ()

@property (nonatomic, strong) ORK1InstructionStep *step1;
@property (nonatomic, strong) ORK1QuestionStep *step2;
@property (nonatomic, strong) ORK1QuestionStep *step3a;
@property (nonatomic, strong) ORK1QuestionStep *step3b;
@property (nonatomic, strong) ORK1ActiveStep *step4;

@end


@implementation DynamicTask

- (instancetype)init {
    self = [super init];
    if (self) {

    }
    return self;
}

- (NSString *)identifier {
    return @"DynamicTask01";
}

/*
 A custom implementation of `ORK1Task` must implement `stepAfterStep:withResult:`
 and `stepBeforeStep:withResult:` so that they are internally consistent. This
 can be a little tricky. In most cases we recommend subclassing `ORK1OrderedTask`
 and overriding it in the specific situations where you need to customize
 behavior.
 */
- (ORK1Step *)stepAfterStep:(ORK1Step *)step withResult:(id<ORK1TaskResultSource>)result {
    NSString *identifier = step.identifier;
    if (step == nil) {
        return self.step1;
    } else if ([identifier isEqualToString:self.step1.identifier]) {
        return self.step2;
    } else if ([identifier isEqualToString:self.step2.identifier]) {
        ORK1StepResult *stepResult = [result stepResultForStepIdentifier:step.identifier];
        ORK1QuestionResult *result = (ORK1QuestionResult *)(stepResult.results.count > 0 ? stepResult.results.firstObject : nil);
        if (result.answer != nil) {
            if ([((NSArray *)result.answer).firstObject isEqualToString:@"route1"])
            {
                return self.step3a;
            } else {
                return self.step3b;
            }
        }
    } else if ([identifier isEqualToString:self.step3a.identifier] || [identifier isEqualToString:self.step3b.identifier]) {
        ORK1StepResult *stepResult = [result stepResultForStepIdentifier:step.identifier];
        ORK1QuestionResult *result = (ORK1QuestionResult *)[stepResult firstResult];
        if (result.answer != nil) {
            if (((NSNumber *)result.answer).boolValue) {
                return self.step4;
            }
        }
    }
    return nil;
}

- (ORK1Step *)stepBeforeStep:(ORK1Step *)step withResult:(ORK1TaskResult *)result {
    NSString *identifier = step.identifier;
    if (identifier == nil || [identifier isEqualToString:self.step1.identifier]) {
        return nil;
    } else if ([identifier isEqualToString:self.step2.identifier]) {
        return self.step1;
    } else if ([identifier isEqualToString:self.step3a.identifier] || [identifier isEqualToString:self.step3b.identifier]) {
        return self.step2;
    } else if ([identifier isEqualToString:self.step4.identifier] ) {
        ORK1QuestionResult *questionResult = (ORK1QuestionResult *)[[result stepResultForStepIdentifier:self.step3a.identifier] firstResult];
        
        if (questionResult != nil) {
             return self.step3a;
        } else {
            return self.step3b;
        }
    }
    
    return nil;
}

// Explicitly hide progress indication for all steps in this dynamic task.
- (ORK1TaskProgress)progressOfCurrentStep:(ORK1Step *)step withResultProvider:(NSArray *)surveyResults {
    return (ORK1TaskProgress){.total = 0, .current = 0};
}

- (ORK1InstructionStep *)step1 {
    if (_step1 == nil) {
        _step1 = [[ORK1InstructionStep alloc] initWithIdentifier:@"step1"];
        _step1.title = @"Dynamic Task";
        _step1.text = @"This is an example of a dynamic task providing a custom implementation of ORK1Task.";
    }
    return _step1;
}

- (ORK1QuestionStep *)step2 {
    if (_step2 == nil) {
        _step2 = [[ORK1QuestionStep alloc] initWithIdentifier:@"step2"];
        _step2.title = @"Which route do you prefer?";
        _step2.text = @"Please choose from the options below:";
        _step2.answerFormat = [ORK1AnswerFormat choiceAnswerFormatWithStyle:ORK1ChoiceAnswerStyleSingleChoice textChoices:@[@"route1", @"route2"]];
        _step2.optional = NO;
    }
    return _step2;
}

- (ORK1QuestionStep *)step3a {
    if (_step3a == nil) {
        _step3a = [[ORK1QuestionStep alloc] initWithIdentifier:@"step3a"];
        _step3a.title = @"You chose route1. Was this correct?";
        _step3a.answerFormat = [ORK1BooleanAnswerFormat new];
        _step3a.optional = NO;
    }
    return _step3a;
}

- (ORK1QuestionStep *)step3b {
    if (_step3b == nil) {
        _step3b = [[ORK1QuestionStep alloc] initWithIdentifier:@"step3b"];
        _step3b.title = @"You chose route2. Was this correct?";
        _step3b.answerFormat = [ORK1BooleanAnswerFormat new];
        _step3b.optional = NO;
    }
    return _step3b;
}

- (ORK1ActiveStep *)step4 {
    if (_step4 == nil) {
        _step4 = [[ORK1ActiveStep alloc] initWithIdentifier:@"step4"];
        _step4.title = @"Thank you.";
        _step4.spokenInstruction = @"Thank you.";
    }
    return _step4;
}

@synthesize cev_theme;

@end
