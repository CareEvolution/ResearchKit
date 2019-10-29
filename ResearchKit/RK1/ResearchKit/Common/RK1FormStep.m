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


#import "RK1FormStep.h"

#import "RK1FormStepViewController.h"

#import "RK1AnswerFormat_Internal.h"
#import "RK1FormItem_Internal.h"
#import "RK1Step_Private.h"

#import "RK1Helpers_Internal.h"


@implementation RK1FormStep

+ (Class)stepViewControllerClass {
    return [RK1FormStepViewController class];
}

- (instancetype)initWithIdentifier:(NSString *)identifier
                             title:(NSString *)title
                              text:(NSString *)text {
    self = [super initWithIdentifier:identifier];
    if (self) {
        self.title = title;
        self.text = text;
        self.optional = YES;
        self.useSurveyMode = YES;
    }
    return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super initWithIdentifier:identifier];
    if (self) {
        self.optional = YES;
        self.useSurveyMode = YES;
    }
    return self;
}


- (void)validateParameters {
    [super validateParameters];
    
    for (RK1FormItem *item in _formItems) {
        [item.answerFormat validateParameters];
    }
    
    [self validateIdentifiersUnique];
}

- (void)validateIdentifiersUnique {
    NSArray *uniqueIdentifiers = [_formItems valueForKeyPath:@"@distinctUnionOfObjects.identifier"];
    NSArray *nonUniqueIdentifiers = [_formItems valueForKeyPath:@"@unionOfObjects.identifier"];
    BOOL itemsHaveNonUniqueIdentifiers = ( nonUniqueIdentifiers.count != uniqueIdentifiers.count );
    
    if (itemsHaveNonUniqueIdentifiers) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"Each form item should have a unique identifier" userInfo:nil];
    }
}

- (instancetype)copyWithZone:(NSZone *)zone {
    RK1FormStep *step = [super copyWithZone:zone];
    step.formItems = RK1ArrayCopyObjects(_formItems);
    step.footnote = self.footnote;
    return step;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return isParentSame &&
        RK1EqualObjects(self.formItems, castObject.formItems) &&
        RK1EqualObjects(self.footnote, castObject.footnote);
}

- (NSUInteger)hash {
    return super.hash ^ self.formItems.hash ^ self.footnote.hash;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        RK1_DECODE_OBJ_ARRAY(aDecoder, formItems, RK1FormItem);
        RK1_DECODE_OBJ_CLASS(aDecoder, footnote, NSString);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_OBJ(aCoder, formItems);
    RK1_ENCODE_OBJ(aCoder, footnote);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)setFormItems:(NSArray<RK1FormItem *> *)formItems {
    // unset removed formItems
    for (RK1FormItem *item in _formItems) {
         item.step = nil;
    }
    
    _formItems = formItems;
    
    for (RK1FormItem *item in _formItems) {
        item.step = self;
    }
}

- (NSSet<HKObjectType *> *)requestedHealthKitTypesForReading {
    NSMutableSet<HKObjectType *> *healthTypes = [NSMutableSet set];
    
    for (RK1FormItem *formItem in self.formItems) {
        RK1AnswerFormat *answerFormat = [formItem answerFormat];
        HKObjectType *objType = [answerFormat healthKitObjectTypeForAuthorization];
        if (objType) {
            [healthTypes addObject:objType];
        }
    }
    
    return healthTypes.count ? healthTypes : nil;
}

@end


@implementation RK1FormItem

- (instancetype)initWithIdentifier:(NSString *)identifier text:(NSString *)text answerFormat:(RK1AnswerFormat *)answerFormat {
    return [self initWithIdentifier:identifier text:text answerFormat:answerFormat optional:YES];
}

- (instancetype)initWithIdentifier:(NSString *)identifier text:(NSString *)text answerFormat:(RK1AnswerFormat *)answerFormat optional:(BOOL)optional {
    self = [super init];
    if (self) {
        RK1ThrowInvalidArgumentExceptionIfNil(identifier);
        _identifier = [identifier copy];
        _text = [text copy];
        _answerFormat = [answerFormat copy];
        _optional = optional;
    }
    return self;
}

- (instancetype)initWithSectionTitle:(NSString *)sectionTitle {
    self = [super init];
    if (self) {
        _text = [sectionTitle copy];
    }
    return self;
}

- (RK1FormItem *)confirmationAnswerFormItemWithIdentifier:(NSString *)identifier
                                                     text:(nullable NSString *)text
                                             errorMessage:(NSString *)errorMessage {
    
    if (![self.answerFormat conformsToProtocol:@protocol(RK1ConfirmAnswerFormatProvider)]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"Answer format %@ does not conform to confirmation protocol", self.answerFormat]
                                     userInfo:nil];
    }
    
    RK1AnswerFormat *answerFormat = [(id <RK1ConfirmAnswerFormatProvider>)self.answerFormat
                                     confirmationAnswerFormatWithOriginalItemIdentifier:self.identifier
                                     errorMessage:errorMessage];
    RK1FormItem *item = [[RK1FormItem alloc] initWithIdentifier:identifier
                                                           text:text
                                                   answerFormat:answerFormat
                                                       optional:self.optional];
    return item;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    RK1FormItem *item = [[[self class] allocWithZone:zone] initWithIdentifier:[_identifier copy] text:[_text copy] answerFormat:[_answerFormat copy]];
    item.optional = _optional;
    item.placeholder = _placeholder;
    item.hidePredicate = _hidePredicate;
    return item;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        RK1_DECODE_OBJ_CLASS(aDecoder, identifier, NSString);
        RK1_DECODE_BOOL(aDecoder, optional);
        RK1_DECODE_OBJ_CLASS(aDecoder, text, NSString);
        RK1_DECODE_OBJ_CLASS(aDecoder, placeholder, NSString);
        RK1_DECODE_OBJ_CLASS(aDecoder, answerFormat, RK1AnswerFormat);
        RK1_DECODE_OBJ_CLASS(aDecoder, step, RK1FormStep);
        RK1_DECODE_OBJ_CLASS(aDecoder, hidePredicate, NSPredicate);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    RK1_ENCODE_OBJ(aCoder, identifier);
    RK1_ENCODE_BOOL(aCoder, optional);
    RK1_ENCODE_OBJ(aCoder, text);
    RK1_ENCODE_OBJ(aCoder, placeholder);
    RK1_ENCODE_OBJ(aCoder, answerFormat);
    RK1_ENCODE_OBJ(aCoder, step);
    RK1_ENCODE_OBJ(aCoder, hidePredicate);
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    // Ignore the step reference - it's not part of the content of this item
    __typeof(self) castObject = object;
    return (RK1EqualObjects(self.identifier, castObject.identifier)
            && self.optional == castObject.optional
            && RK1EqualObjects(self.text, castObject.text)
            && RK1EqualObjects(self.placeholder, castObject.placeholder)
            && RK1EqualObjects(self.answerFormat, castObject.answerFormat)
            && RK1EqualObjects(self.hidePredicate, castObject.hidePredicate));
}

- (NSUInteger)hash {
     // Ignore the step reference - it's not part of the content of this item
    return _identifier.hash ^ _text.hash ^ _placeholder.hash ^ _answerFormat.hash ^ (_optional ? 0xf : 0x0) ^ _hidePredicate.hash;
}

- (RK1AnswerFormat *)impliedAnswerFormat {
    return [self.answerFormat impliedAnswerFormat];
}

- (RK1QuestionType)questionType {
    return [[self impliedAnswerFormat] questionType];
}

@end
