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


#import "RK1LoginStep.h"
#import "RK1LoginStep_Internal.h"

#import "RK1LoginStepViewController.h"

#import "RK1AnswerFormat.h"
#import "RK1Step_Private.h"

#import "RK1Helpers_Internal.h"


NSString *const RK1LoginFormItemIdentifierEmail = @"RK1LoginFormItemEmail";
NSString *const RK1LoginFormItemIdentifierPassword = @"RK1LoginFormItemPassword";

@implementation RK1LoginStep

- (Class)stepViewControllerClass {
    return self.loginViewControllerClass;
}

// Don't throw on -initWithIdentifier: because it's internally used by -copyWithZone:

- (instancetype)initWithIdentifier:(NSString *)identifier
                             title:(nullable NSString *)title
                              text:(nullable NSString *)text {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)initWithIdentifier:(NSString *)identifier
                             title:(NSString *)title
                              text:(NSString *)text
          loginViewControllerClass:(Class)loginViewControllerClass {
    
    NSParameterAssert([loginViewControllerClass isSubclassOfClass:[RK1LoginStepViewController class]]);
    
    self = [super initWithIdentifier:identifier title:title text:text];
    if (self) {
        _loginViewControllerString = NSStringFromClass(loginViewControllerClass);
        self.formItems = [self loginFormItems];
        
        [self validateParameters];
    }
    return self;
}

- (NSArray <RK1FormItem *> *)loginFormItems {
    NSMutableArray *formItems = [NSMutableArray new];
    
    {
        RK1EmailAnswerFormat *answerFormat = [RK1AnswerFormat emailAnswerFormat];
        
        RK1FormItem *item = [[RK1FormItem alloc] initWithIdentifier:RK1LoginFormItemIdentifierEmail
                                                               text:RK1LocalizedString(@"EMAIL_FORM_ITEM_TITLE", nil)
                                                       answerFormat:answerFormat
                                                           optional:NO];
        item.placeholder = RK1LocalizedString(@"EMAIL_FORM_ITEM_PLACEHOLDER", nil);
        
        [formItems addObject:item];
    }
    
    {
        RK1TextAnswerFormat *answerFormat = [RK1AnswerFormat textAnswerFormat];
        answerFormat.multipleLines = NO;
        answerFormat.secureTextEntry = YES;
        answerFormat.autocapitalizationType = UITextAutocapitalizationTypeNone;
        answerFormat.autocorrectionType = UITextAutocorrectionTypeNo;
        answerFormat.spellCheckingType = UITextSpellCheckingTypeNo;
        
        RK1FormItem *item = [[RK1FormItem alloc] initWithIdentifier:RK1LoginFormItemIdentifierPassword
                                                               text:RK1LocalizedString(@"PASSWORD_FORM_ITEM_TITLE", nil)
                                                       answerFormat:answerFormat
                                                           optional:NO];
        item.placeholder = RK1LocalizedString(@"PASSWORD_FORM_ITEM_PLACEHOLDER", nil);
        
        [formItems addObject:item];
    }
    
    return formItems;
}

- (Class)loginViewControllerClass {
    return NSClassFromString(_loginViewControllerString);
}

- (void)validateParameters {
    [super validateParameters];
    
    if (!_loginViewControllerString || !NSClassFromString(_loginViewControllerString)) {
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:@"Unable to find RK1LoginStepViewController subclass."
                                     userInfo:nil];
    }
}

- (BOOL)isOptional {
    // This is necessary because the skip button is used as a `Forgot password?` button.
    return YES;
}

- (BOOL)showsProgress {
    return NO;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        RK1_DECODE_OBJ(aDecoder, loginViewControllerString);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_OBJ(aCoder, loginViewControllerString);
}

- (instancetype)copyWithZone:(NSZone *)zone {
    RK1LoginStep *step = [super copyWithZone:zone];
    step->_loginViewControllerString = [self.loginViewControllerString copy];
    return step;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            RK1EqualObjects(self.loginViewControllerString, castObject.loginViewControllerString));
}

@end
