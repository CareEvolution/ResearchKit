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


@import XCTest;
@import ResearchKit.Private;

#import "RK1ChoiceAnswerFormatHelper.h"


@interface RK1ChoiceAnswerFormatHelperTests : XCTestCase

@end


@implementation RK1ChoiceAnswerFormatHelperTests

- (NSArray *)textChoices {
    
    static NSArray *choices = nil;
    
    if (choices == nil) {
        choices = @[[RK1TextChoice choiceWithText:@"choice 01" value:@"c1"],
                        [RK1TextChoice choiceWithText:@"choice 02" value:@"c2"],
                        [RK1TextChoice choiceWithText:@"choice 03" value:@"c3"],
                        [RK1TextChoice choiceWithText:@"choice 04" value:@"c4"]];
    }
    
    return choices;
}

- (NSArray *)imageChoices {
    
    static NSArray *choices = nil;
    
    if (choices == nil) {
        choices = @[[RK1ImageChoice choiceWithNormalImage:nil selectedImage:nil text:@"choice 01" value:@"c1"],
                    [RK1ImageChoice choiceWithNormalImage:nil selectedImage:nil text:@"choice 02" value:@"c2"],
                    [RK1ImageChoice choiceWithNormalImage:nil selectedImage:nil text:@"choice 03" value:@"c3"]];
    }
    
    return choices;
}

- (void)testCount {
   
    {
        RK1AnswerFormat *answerFormat = [RK1AnswerFormat choiceAnswerFormatWithStyle:RK1ChoiceAnswerStyleSingleChoice
                                         textChoices:[self textChoices]];
        RK1ChoiceAnswerFormatHelper *formatHelper = [[RK1ChoiceAnswerFormatHelper alloc] initWithAnswerFormat:answerFormat];
        
        XCTAssertEqual(formatHelper.choiceCount, [self textChoices].count, @"");
    }
    
    {
        RK1AnswerFormat *answerFormat = [RK1AnswerFormat choiceAnswerFormatWithImageChoices:[self imageChoices]];
        RK1ChoiceAnswerFormatHelper *formatHelper = [[RK1ChoiceAnswerFormatHelper alloc] initWithAnswerFormat:answerFormat];
        
        XCTAssertEqual(formatHelper.choiceCount, [self imageChoices].count, @"");
    }
    
    {
        RK1AnswerFormat *answerFormat = [RK1AnswerFormat valuePickerAnswerFormatWithTextChoices:[self textChoices]];
        RK1ChoiceAnswerFormatHelper *formatHelper = [[RK1ChoiceAnswerFormatHelper alloc] initWithAnswerFormat:answerFormat];
        
        XCTAssertEqual(formatHelper.choiceCount, [self textChoices].count+1, @"");
    }
}

- (void)testTextChoice {
    {
        NSArray *textChoices = [self textChoices];
        
        RK1AnswerFormat *answerFormat = [RK1AnswerFormat choiceAnswerFormatWithStyle:RK1ChoiceAnswerStyleSingleChoice
                                                               textChoices:textChoices];
        
        
        RK1ChoiceAnswerFormatHelper *formatHelper = [[RK1ChoiceAnswerFormatHelper alloc] initWithAnswerFormat:answerFormat];
        
        [textChoices enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            RK1TextChoice *tc = obj;
            RK1TextChoice *tc2 = [formatHelper textChoiceAtIndex:idx];
            XCTAssertEqual(tc, tc2, @"");
            XCTAssertNil([formatHelper imageChoiceAtIndex:idx],@"");
        }];
    }
    
    {
        NSArray *textChoices = [self textChoices];
        
        RK1AnswerFormat *answerFormat = [RK1AnswerFormat valuePickerAnswerFormatWithTextChoices:textChoices];
        
        
        RK1ChoiceAnswerFormatHelper *formatHelper = [[RK1ChoiceAnswerFormatHelper alloc] initWithAnswerFormat:answerFormat];
        
        [textChoices enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            RK1TextChoice *tc = obj;
            RK1TextChoice *tc2 = [formatHelper textChoiceAtIndex:idx+1];
            XCTAssertEqual(tc, tc2, @"");
            XCTAssertNil([formatHelper imageChoiceAtIndex:idx],@"");
        }];
    }
}

- (void)testImageChoice {
    {
        NSArray *imageChoices = [self imageChoices];
        
        RK1AnswerFormat *answerFormat = [RK1AnswerFormat choiceAnswerFormatWithImageChoices:imageChoices];
        
        
        RK1ChoiceAnswerFormatHelper *formatHelper = [[RK1ChoiceAnswerFormatHelper alloc] initWithAnswerFormat:answerFormat];
        
        [imageChoices enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            RK1ImageChoice *tc = obj;
            RK1ImageChoice *tc2 = [formatHelper imageChoiceAtIndex:idx];
            XCTAssertEqual(tc, tc2, @"");
            XCTAssertNil([formatHelper textChoiceAtIndex:idx],@"");
        }];
    }
}

- (void)verifyAnswerForSelectedIndexes:(RK1ChoiceAnswerFormatHelper *)formatHelper choices:(NSArray *)choices {
    NSMutableArray *indexArray = [NSMutableArray new];
    
    [choices enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        id answer = [formatHelper answerForSelectedIndex:idx];
        
        XCTAssert([answer isKindOfClass:[NSArray class]]);
        NSArray *answerArray = answer;
        
        id value = ((RK1TextChoice *)choices[idx]).value;
        
        if (value == nil) {
            value = @(idx);
        }
        
        XCTAssert(answerArray.count == 1 && [answerArray.firstObject isEqual:value], @"%@", answerArray);
        
        answer = [formatHelper answerForSelectedIndexes:@[@(idx)]];
        XCTAssert([answer isKindOfClass:[NSArray class]]);
        answerArray = answer;

        XCTAssert(answerArray.count == 1 && [answerArray.firstObject isEqual:value], @"%@", answerArray);
        
        [indexArray addObject:@(idx)];
        
        answer = [formatHelper answerForSelectedIndexes:indexArray];
        XCTAssert([answer isKindOfClass:[NSArray class]]);
        answerArray = answer;

        XCTAssertEqual(answerArray.count, idx + 1, @"%@", answerArray);
        
    }];
}

- (void)testAnswerForSelectedIndexes {
    {
        NSArray *textChoices = [self textChoices];
        
        RK1AnswerFormat *answerFormat = [RK1AnswerFormat valuePickerAnswerFormatWithTextChoices:textChoices];
        
        RK1ChoiceAnswerFormatHelper *formatHelper = [[RK1ChoiceAnswerFormatHelper alloc] initWithAnswerFormat:answerFormat];
        
        id answer = [formatHelper answerForSelectedIndexes:@[@(0)]];
        
        XCTAssert(answer == RK1NullAnswerValue(), @"%@", answer);
        
        answer = [formatHelper answerForSelectedIndex:0];
        
        XCTAssert(answer == RK1NullAnswerValue(), @"%@", answer);
        
        [textChoices enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            id answer = [formatHelper answerForSelectedIndex:idx+1];
            
            id value = ((RK1TextChoice *)textChoices[idx]).value;
            
            if (value == nil) {
                value = @(idx);
            }
            
            XCTAssert([answer isKindOfClass:[NSArray class]]);
            NSArray *answerArray = answer;
            XCTAssert(answerArray.count == 1 && [answerArray.firstObject isEqual:value], @"%@", answer);
            
            answer = [formatHelper answerForSelectedIndexes:@[@(idx+1)]];
            XCTAssert([answer isKindOfClass:[NSArray class]]);
            answerArray = answer;
            
            XCTAssert(answerArray.count == 1 && [answerArray.firstObject isEqual:value], @"%@", answer);
        }];
        
    }
    
    {
        NSArray *textChoices = [self textChoices];
        
        RK1AnswerFormat *answerFormat = [RK1AnswerFormat choiceAnswerFormatWithStyle:RK1ChoiceAnswerStyleSingleChoice
                                                               textChoices:textChoices];
        
        RK1ChoiceAnswerFormatHelper *formatHelper = [[RK1ChoiceAnswerFormatHelper alloc] initWithAnswerFormat:answerFormat];
        
       
        [self verifyAnswerForSelectedIndexes:formatHelper choices:textChoices];
    }
    
    {
        NSArray *imageChoices = [self imageChoices];
        
        RK1AnswerFormat *answerFormat = [RK1AnswerFormat choiceAnswerFormatWithImageChoices:imageChoices];
        
        RK1ChoiceAnswerFormatHelper *formatHelper = [[RK1ChoiceAnswerFormatHelper alloc] initWithAnswerFormat:answerFormat];
        
        [self verifyAnswerForSelectedIndexes:formatHelper choices:imageChoices];
    }
}

- (void)verifySelectedIndexesForAnswer:(RK1ChoiceAnswerFormatHelper *)formatHelper choices:(NSArray *)choices {
    
    NSArray *indexes = [formatHelper selectedIndexesForAnswer:nil];
    
    XCTAssertEqual(indexes.count, 0, @"%@", indexes);
    
    indexes = [formatHelper selectedIndexesForAnswer:RK1NullAnswerValue()];
    
    XCTAssertEqual(indexes.count, 0, @"%@", indexes);
    
    NSNumber *indexNumber = [formatHelper selectedIndexForAnswer:nil];
    
    XCTAssertNil(indexNumber, @"%@", indexNumber);
    
    indexNumber = [formatHelper selectedIndexForAnswer:RK1NullAnswerValue()];
    
    XCTAssertNil(indexNumber, @"%@", indexNumber);
    
    [choices enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        id value = ((RK1TextChoice *)obj).value;
        
        if (value == nil) {
            value = @(idx);
        }
        
        NSNumber *indexNumber = [formatHelper selectedIndexForAnswer:@[value]];
        
        XCTAssertEqualObjects(indexNumber, @(idx), @"%@ vs %@", indexNumber, @(idx));
        
        NSArray *indexArray = [formatHelper selectedIndexesForAnswer:@[value]];
        
        XCTAssertEqualObjects( indexArray.firstObject, @(idx), @"%@ vs %@", indexArray[0], @(idx));
        
    }];
}

- (void)testSelectedIndexesForAnswer {
    {
        NSArray *textChoices = [self textChoices];
        
        RK1AnswerFormat *answerFormat = [RK1AnswerFormat valuePickerAnswerFormatWithTextChoices:textChoices];
        
        RK1ChoiceAnswerFormatHelper *formatHelper = [[RK1ChoiceAnswerFormatHelper alloc] initWithAnswerFormat:answerFormat];
        
        NSArray *indexes = [formatHelper selectedIndexesForAnswer:nil];
        
        XCTAssertEqualObjects(indexes.firstObject, @(0), @"%@", indexes);
        
        indexes = [formatHelper selectedIndexesForAnswer:RK1NullAnswerValue()];
        
        XCTAssertEqualObjects(indexes.firstObject, @(0), @"%@", indexes);
        
        NSNumber *indexNumber = [formatHelper selectedIndexForAnswer:nil];
        
        XCTAssert([indexNumber isKindOfClass:[NSNumber class]] && indexNumber.unsignedIntegerValue == 0, @"%@", indexNumber);
        
        indexNumber = [formatHelper selectedIndexForAnswer:RK1NullAnswerValue()];
        
        XCTAssert([indexNumber isKindOfClass:[NSNumber class]] && indexNumber.unsignedIntegerValue == 0, @"%@", indexNumber);
        
        [textChoices enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            id value = ((RK1TextChoice *)obj).value;
            
            if (value == nil) {
                value = @(idx);
            }
            
            NSNumber *indexNumber = [formatHelper selectedIndexForAnswer:@[value]];
            
            XCTAssertEqualObjects(indexNumber, @(idx+1), @"%@ vs %@", indexNumber, @(idx+1));
            
            NSArray *indexArray = [formatHelper selectedIndexesForAnswer:@[value]];
            
            XCTAssertEqualObjects(indexArray.firstObject, @(idx+1), @"%@ vs %@", indexArray[0], @(idx+1));
            
        }];
        
    }
    
    {
        NSArray *textChoices = [self textChoices];
        
        RK1AnswerFormat *answerFormat = [RK1AnswerFormat choiceAnswerFormatWithStyle:RK1ChoiceAnswerStyleSingleChoice
                                                               textChoices:textChoices];
        
        RK1ChoiceAnswerFormatHelper *formatHelper = [[RK1ChoiceAnswerFormatHelper alloc] initWithAnswerFormat:answerFormat];
        
       [self verifySelectedIndexesForAnswer:formatHelper choices:textChoices];
        
    }
    
    {
        NSArray *imageChoices = [self imageChoices];
        
        RK1AnswerFormat *answerFormat = [RK1AnswerFormat choiceAnswerFormatWithImageChoices:imageChoices];
        
        RK1ChoiceAnswerFormatHelper *formatHelper = [[RK1ChoiceAnswerFormatHelper alloc] initWithAnswerFormat:answerFormat];
        
        [self verifySelectedIndexesForAnswer:formatHelper choices:imageChoices];
        
    }
}

@end
