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
@import ORK1Kit.Private;


@interface ORK1AnswerFormatTests : XCTestCase

@end

@protocol ORK1ComfirmAnswerFormat_Private <NSObject>

@property (nonatomic, copy, readonly) NSString *originalItemIdentifier;
@property (nonatomic, copy, readonly) NSString *errorMessage;

@end


@implementation ORK1AnswerFormatTests

- (void)testValidEmailAnswerFormat {
    // Test email regular expression validation with correct input.
    XCTAssert([[ORK1EmailAnswerFormat emailAnswerFormat] isAnswerValidWithString:@"someone@researchkit.org"]);
    XCTAssert([[ORK1EmailAnswerFormat emailAnswerFormat] isAnswerValidWithString:@"some.one@researchkit.org"]);
    XCTAssert([[ORK1EmailAnswerFormat emailAnswerFormat] isAnswerValidWithString:@"someone@researchkit.org.uk"]);
    XCTAssert([[ORK1EmailAnswerFormat emailAnswerFormat] isAnswerValidWithString:@"some_one@researchkit.org"]);
    XCTAssert([[ORK1EmailAnswerFormat emailAnswerFormat] isAnswerValidWithString:@"some-one@researchkit.org"]);
    XCTAssert([[ORK1EmailAnswerFormat emailAnswerFormat] isAnswerValidWithString:@"someone1@researchkit.org"]);
    XCTAssert([[ORK1EmailAnswerFormat emailAnswerFormat] isAnswerValidWithString:@"Someone1@ORK1Kit.org"]);
}

- (void)testInvalidEmailAnswerFormat {
    // Test email regular expression validation with incorrect input.
    XCTAssertFalse([[ORK1EmailAnswerFormat emailAnswerFormat] isAnswerValidWithString:@"emailtest"]);
    XCTAssertFalse([[ORK1EmailAnswerFormat emailAnswerFormat] isAnswerValidWithString:@"emailtest@"]);
    XCTAssertFalse([[ORK1EmailAnswerFormat emailAnswerFormat] isAnswerValidWithString:@"emailtest@researchkit"]);
    XCTAssertFalse([[ORK1EmailAnswerFormat emailAnswerFormat] isAnswerValidWithString:@"emailtest@.org"]);
    XCTAssertFalse([[ORK1EmailAnswerFormat emailAnswerFormat] isAnswerValidWithString:@"12345"]);
}

- (void)testInvalidRegularExpressionAnswerFormat {
    
    // Setup an answer format
    ORK1TextAnswerFormat *answerFormat = [ORK1AnswerFormat textAnswerFormat];
    answerFormat.multipleLines = NO;
    answerFormat.keyboardType = UIKeyboardTypeASCIICapable;
    NSRegularExpression *validationRegularExpression =
    [NSRegularExpression regularExpressionWithPattern:@"^[A-F,0-9]+$"
                                              options:(NSRegularExpressionOptions)0
                                                error:nil];
    answerFormat.validationRegularExpression = validationRegularExpression;
    answerFormat.invalidMessage = @"Only hexidecimal values in uppercase letters are accepted.";
    answerFormat.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    XCTAssertFalse([answerFormat isAnswerValidWithString:@"Q2"]);
    XCTAssertFalse([answerFormat isAnswerValidWithString:@"abcd"]);
    XCTAssertTrue([answerFormat isAnswerValidWithString:@"ABCD1234FFED0987654321"]);
}

- (void)testConfirmAnswerFormat {
    
    // Setup an answer format
    ORK1TextAnswerFormat *answerFormat = [ORK1AnswerFormat textAnswerFormat];
    answerFormat.multipleLines = NO;
    answerFormat.secureTextEntry = YES;
    answerFormat.keyboardType = UIKeyboardTypeASCIICapable;
    answerFormat.maximumLength = 12;
    NSRegularExpression *validationRegularExpression =
    [NSRegularExpression regularExpressionWithPattern:@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[$@$!%*?&])[A-Za-z\\d$@$!%*?&]{10,}"
                                              options:(NSRegularExpressionOptions)0
                                                error:nil];
    answerFormat.validationRegularExpression = validationRegularExpression;
    answerFormat.invalidMessage = @"Invalid password";
    answerFormat.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    
    // Note: setting these up incorrectly for a password to test that the values are *not* copied.
    // DO NOT setup a real password field with these options.
    answerFormat.autocorrectionType = UITextAutocorrectionTypeDefault;
    answerFormat.spellCheckingType = UITextSpellCheckingTypeDefault;
    
    
    ORK1FormItem *item = [[ORK1FormItem alloc] initWithIdentifier:@"foo" text:@"enter value" answerFormat:answerFormat optional:NO];
    
    // -- method under test
    ORK1FormItem *confirmItem = [item confirmationAnswerFormItemWithIdentifier:@"bar"
                                                                         text:@"enter again"
                                                                 errorMessage:@"doesn't match"];
    
    XCTAssertEqualObjects(confirmItem.identifier, @"bar");
    XCTAssertEqualObjects(confirmItem.text, @"enter again");
    XCTAssertFalse(confirmItem.optional);
    
    // Inspect the answer format
    ORK1AnswerFormat *confirmFormat = confirmItem.answerFormat;
    
    // ORK1AnswerFormat that is returned should be a subclass of ORK1TextAnswerFormat.
    // The actual subclass that is returned is private to the API and should not be accessed directly.
    XCTAssertNotNil(confirmFormat);
    XCTAssertTrue([confirmFormat isKindOfClass:[ORK1TextAnswerFormat class]]);
    if (![confirmFormat isKindOfClass:[ORK1TextAnswerFormat class]]) { return; }
    
    ORK1TextAnswerFormat *confirmAnswer = (ORK1TextAnswerFormat*)confirmFormat;
    
    // These properties should match the original format
    XCTAssertFalse(confirmAnswer.multipleLines);
    XCTAssertTrue(confirmAnswer.secureTextEntry);
    XCTAssertEqual(confirmAnswer.keyboardType, UIKeyboardTypeASCIICapable);
    XCTAssertEqual(confirmAnswer.maximumLength, 12);
    
    // This property should match the input answer format so that cases that
    // require all-upper or all-lower (for whatever reason) can be met.
    XCTAssertEqual(confirmAnswer.autocapitalizationType, UITextAutocapitalizationTypeAllCharacters);
    
    // These properties should always be set to not autocorrect
    XCTAssertEqual(confirmAnswer.autocorrectionType, UITextAutocorrectionTypeNo);
    XCTAssertEqual(confirmAnswer.spellCheckingType, UITextSpellCheckingTypeNo);
    
    // These properties should be nil
    XCTAssertNil(confirmAnswer.validationRegularExpression);
    XCTAssertNil(confirmAnswer.invalidMessage);
    
    // Check that the confirmation answer format responds to the internal methods
    XCTAssertTrue([confirmFormat respondsToSelector:@selector(originalItemIdentifier)]);
    XCTAssertTrue([confirmFormat respondsToSelector:@selector(errorMessage)]);
    if (![confirmFormat respondsToSelector:@selector(originalItemIdentifier)] ||
        ![confirmFormat respondsToSelector:@selector(errorMessage)]) {
        return;
    }
    
    NSString *originalItemIdentifier = [(id)confirmFormat originalItemIdentifier];
    XCTAssertEqualObjects(originalItemIdentifier, @"foo");
    
    NSString *errorMessage = [(id)confirmFormat errorMessage];
    XCTAssertEqualObjects(errorMessage, @"doesn't match");
    
}

- (void)testConfirmAnswerFormat_Optional_YES {
    
    // Setup an answer format
    ORK1TextAnswerFormat *answerFormat = [ORK1AnswerFormat textAnswerFormat];
    answerFormat.multipleLines = NO;
    
    ORK1FormItem *item = [[ORK1FormItem alloc] initWithIdentifier:@"foo" text:@"enter value" answerFormat:answerFormat optional:YES];
    
    // -- method under test
    ORK1FormItem *confirmItem = [item confirmationAnswerFormItemWithIdentifier:@"bar"
                                                                         text:@"enter again"
                                                                 errorMessage:@"doesn't match"];
    
    // Check that the confirm item optional value matches the input item
    XCTAssertTrue(confirmItem.optional);
    
}

- (void)testConfirmAnswerFormat_MultipleLines_YES {
    
    // Setup an answer format
    ORK1TextAnswerFormat *answerFormat = [ORK1AnswerFormat textAnswerFormat];
    answerFormat.multipleLines = YES;
    
    ORK1FormItem *item = [[ORK1FormItem alloc] initWithIdentifier:@"foo" text:@"enter value" answerFormat:answerFormat optional:YES];
    
    // -- method under test
    XCTAssertThrows([item confirmationAnswerFormItemWithIdentifier:@"bar"
                                                              text:@"enter again"
                                                      errorMessage:@"doesn't match"]);
    
}

@end
