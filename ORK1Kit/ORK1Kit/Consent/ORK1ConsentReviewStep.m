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


#import "ORK1ConsentReviewStep.h"

#import "ORK1ConsentReviewStepViewController.h"

#import "ORK1ConsentDocument_Internal.h"
#import "ORK1ConsentSection_Private.h"
#import "ORK1ConsentSignature.h"
#import "ORK1Step_Private.h"

#import "ORK1Helpers_Internal.h"


@implementation ORK1ConsentReviewStep

+ (Class)stepViewControllerClass {
    return [ORK1ConsentReviewStepViewController class];
}

- (instancetype)initWithIdentifier:(NSString *)identifier signature:(ORK1ConsentSignature *)signature inDocument:(ORK1ConsentDocument *)consentDocument {
    self = [super initWithIdentifier:identifier];
    if (self) {
        _consentDocument = consentDocument;
        _signature = signature;
        _requiresScrollToBottom = NO;
        _autoAgree = NO;
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1ConsentReviewStep *step = [super copyWithZone:zone];
    step->_consentDocument = self.consentDocument;
    step->_signature = self.signature;
    step->_reasonForConsent = self.reasonForConsent;
    step->_requiresScrollToBottom = self.requiresScrollToBottom;
    step->_autoAgree = self.autoAgree;
    return step;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, consentDocument, ORK1ConsentDocument);
        ORK1_DECODE_OBJ_CLASS(aDecoder, signature, ORK1ConsentSignature);
        ORK1_DECODE_OBJ_CLASS(aDecoder, reasonForConsent, NSString);
        ORK1_DECODE_BOOL(aDecoder, requiresScrollToBottom);
        ORK1_DECODE_BOOL(aDecoder, autoAgree);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, consentDocument);
    ORK1_ENCODE_OBJ(aCoder, signature);
    ORK1_ENCODE_OBJ(aCoder, reasonForConsent);
    ORK1_ENCODE_BOOL(aCoder, requiresScrollToBottom);
    ORK1_ENCODE_BOOL(aCoder, autoAgree);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            ORK1EqualObjects(self.consentDocument, castObject.consentDocument) &&
            ORK1EqualObjects(self.signature, castObject.signature) &&
            ORK1EqualObjects(self.reasonForConsent, castObject.reasonForConsent)) &&
            (self.requiresScrollToBottom == castObject.requiresScrollToBottom) &&
            (self.autoAgree == castObject.autoAgree);
}

- (NSUInteger)hash {
    return super.hash ^ self.consentDocument.hash ^ self.signature.hash ^ self.reasonForConsent.hash ^ (_requiresScrollToBottom ? 0xf : 0x0) ^ (_autoAgree ? 0xe : 0x1);
}

- (BOOL)showsProgress {
    return NO;
}

@end
