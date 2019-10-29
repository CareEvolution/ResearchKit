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


#import "RK1ConsentSharingStep.h"

#import "RK1ConsentSharingStepViewController.h"

#import "RK1Step_Private.h"

#import "RK1AnswerFormat.h"
#import "RK1Helpers_Internal.h"


@implementation RK1ConsentSharingStep

+ (Class)stepViewControllerClass {
    return [RK1ConsentSharingStepViewController class];
}

- (BOOL)showsProgress {
    return NO;
}

- (BOOL)useSurveyMode {
    return NO;
}

- (instancetype)initWithIdentifier:(NSString *)identifier
      investigatorShortDescription:(NSString *)investigatorShortDescription
       investigatorLongDescription:(NSString *)investigatorLongDescription
     localizedLearnMoreHTMLContent:(NSString *)localizedLearnMoreHTMLContent {
    self = [super initWithIdentifier:identifier];
    if (self) {
        if ( investigatorShortDescription.length == 0 ) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"investigatorShortDescription should not be empty." userInfo:nil];
        }
        if ( investigatorLongDescription.length == 0 ) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"investigatorLongDescription should not be empty." userInfo:nil];
        }
        if ( localizedLearnMoreHTMLContent.length == 0 ) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"localizedLearnMoreHTMLContent should not be empty." userInfo:nil];
        }
        
        self.answerFormat = [RK1AnswerFormat choiceAnswerFormatWithStyle:RK1ChoiceAnswerStyleSingleChoice textChoices:
                             @[[RK1TextChoice choiceWithText:[NSString localizedStringWithFormat:RK1LocalizedString(@"CONSENT_SHARE_WIDELY_%@",nil), investigatorShortDescription] value:@(YES)],
                               [RK1TextChoice choiceWithText:[NSString localizedStringWithFormat:RK1LocalizedString(@"CONSENT_SHARE_ONLY_%@",nil), investigatorLongDescription] value:@(NO)],
                               ]];
        self.optional = NO;
        self.useSurveyMode = NO;
        self.title = RK1LocalizedString(@"CONSENT_SHARING_TITLE", nil);
        self.text = [NSString localizedStringWithFormat:RK1LocalizedString(@"CONSENT_SHARING_DESCRIPTION_%@", nil), investigatorLongDescription];
        
        self.localizedLearnMoreHTMLContent = localizedLearnMoreHTMLContent;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return isParentSame &&
    RK1EqualObjects(self.localizedLearnMoreHTMLContent, castObject.localizedLearnMoreHTMLContent);
}

- (instancetype)copyWithZone:(NSZone *)zone {
    RK1ConsentSharingStep *step = [super copyWithZone:zone];
    step.localizedLearnMoreHTMLContent = self.localizedLearnMoreHTMLContent;
    return step;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        RK1_DECODE_OBJ_CLASS(aDecoder, localizedLearnMoreHTMLContent, NSString);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    
    RK1_ENCODE_OBJ(aCoder, localizedLearnMoreHTMLContent);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end
