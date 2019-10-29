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


#import "ORKFormStep.h"

#import "ORKFormStepViewController.h"

#import "ORKAnswerFormat_Internal.h"
#import "ORKFormItem_Internal.h"
#import "ORKStep_Private.h"

#import "ORKHelpers_Internal.h"


@implementation ORKLegacyFormStep

+ (Class)stepViewControllerClass {
    return [ORKLegacyFormStepViewController class];
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
    
    for (ORKLegacyFormItem *item in _formItems) {
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
    ORKLegacyFormStep *step = [super copyWithZone:zone];
    step.formItems = ORKLegacyArrayCopyObjects(_formItems);
    step.footnote = self.footnote;
    return step;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return isParentSame &&
        ORKLegacyEqualObjects(self.formItems, castObject.formItems) &&
        ORKLegacyEqualObjects(self.footnote, castObject.footnote);
}

- (NSUInteger)hash {
    return super.hash ^ self.formItems.hash ^ self.footnote.hash;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORKLegacy_DECODE_OBJ_ARRAY(aDecoder, formItems, ORKLegacyFormItem);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, footnote, NSString);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORKLegacy_ENCODE_OBJ(aCoder, formItems);
    ORKLegacy_ENCODE_OBJ(aCoder, footnote);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)setFormItems:(NSArray<ORKLegacyFormItem *> *)formItems {
    // unset removed formItems
    for (ORKLegacyFormItem *item in _formItems) {
         item.step = nil;
    }
    
    _formItems = formItems;
    
    for (ORKLegacyFormItem *item in _formItems) {
        item.step = self;
    }
}

- (NSSet<HKObjectType *> *)requestedHealthKitTypesForReading {
    NSMutableSet<HKObjectType *> *healthTypes = [NSMutableSet set];
    
    for (ORKLegacyFormItem *formItem in self.formItems) {
        ORKLegacyAnswerFormat *answerFormat = [formItem answerFormat];
        HKObjectType *objType = [answerFormat healthKitObjectTypeForAuthorization];
        if (objType) {
            [healthTypes addObject:objType];
        }
    }
    
    return healthTypes.count ? healthTypes : nil;
}

@end


@implementation ORKLegacyFormItem

- (instancetype)initWithIdentifier:(NSString *)identifier text:(NSString *)text answerFormat:(ORKLegacyAnswerFormat *)answerFormat {
    return [self initWithIdentifier:identifier text:text answerFormat:answerFormat optional:YES];
}

- (instancetype)initWithIdentifier:(NSString *)identifier text:(NSString *)text answerFormat:(ORKLegacyAnswerFormat *)answerFormat optional:(BOOL)optional {
    self = [super init];
    if (self) {
        ORKLegacyThrowInvalidArgumentExceptionIfNil(identifier);
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

- (ORKLegacyFormItem *)confirmationAnswerFormItemWithIdentifier:(NSString *)identifier
                                                     text:(nullable NSString *)text
                                             errorMessage:(NSString *)errorMessage {
    
    if (![self.answerFormat conformsToProtocol:@protocol(ORKLegacyConfirmAnswerFormatProvider)]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"Answer format %@ does not conform to confirmation protocol", self.answerFormat]
                                     userInfo:nil];
    }
    
    ORKLegacyAnswerFormat *answerFormat = [(id <ORKLegacyConfirmAnswerFormatProvider>)self.answerFormat
                                     confirmationAnswerFormatWithOriginalItemIdentifier:self.identifier
                                     errorMessage:errorMessage];
    ORKLegacyFormItem *item = [[ORKLegacyFormItem alloc] initWithIdentifier:identifier
                                                           text:text
                                                   answerFormat:answerFormat
                                                       optional:self.optional];
    return item;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyFormItem *item = [[[self class] allocWithZone:zone] initWithIdentifier:[_identifier copy] text:[_text copy] answerFormat:[_answerFormat copy]];
    item.optional = _optional;
    item.placeholder = _placeholder;
    item.hidePredicate = _hidePredicate;
    return item;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, identifier, NSString);
        ORKLegacy_DECODE_BOOL(aDecoder, optional);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, text, NSString);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, placeholder, NSString);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, answerFormat, ORKLegacyAnswerFormat);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, step, ORKLegacyFormStep);
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, hidePredicate, NSPredicate);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORKLegacy_ENCODE_OBJ(aCoder, identifier);
    ORKLegacy_ENCODE_BOOL(aCoder, optional);
    ORKLegacy_ENCODE_OBJ(aCoder, text);
    ORKLegacy_ENCODE_OBJ(aCoder, placeholder);
    ORKLegacy_ENCODE_OBJ(aCoder, answerFormat);
    ORKLegacy_ENCODE_OBJ(aCoder, step);
    ORKLegacy_ENCODE_OBJ(aCoder, hidePredicate);
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    // Ignore the step reference - it's not part of the content of this item
    __typeof(self) castObject = object;
    return (ORKLegacyEqualObjects(self.identifier, castObject.identifier)
            && self.optional == castObject.optional
            && ORKLegacyEqualObjects(self.text, castObject.text)
            && ORKLegacyEqualObjects(self.placeholder, castObject.placeholder)
            && ORKLegacyEqualObjects(self.answerFormat, castObject.answerFormat)
            && ORKLegacyEqualObjects(self.hidePredicate, castObject.hidePredicate));
}

- (NSUInteger)hash {
     // Ignore the step reference - it's not part of the content of this item
    return _identifier.hash ^ _text.hash ^ _placeholder.hash ^ _answerFormat.hash ^ (_optional ? 0xf : 0x0) ^ _hidePredicate.hash;
}

- (ORKLegacyAnswerFormat *)impliedAnswerFormat {
    return [self.answerFormat impliedAnswerFormat];
}

- (ORKLegacyQuestionType)questionType {
    return [[self impliedAnswerFormat] questionType];
}

@end
