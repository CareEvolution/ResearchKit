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


#import "RK1VisualConsentStep.h"

#import "RK1VisualConsentStepViewController.h"

#import "RK1ConsentDocument_Internal.h"
#import "RK1Step_Private.h"

#import "RK1Helpers_Internal.h"


@implementation RK1VisualConsentStep

+ (Class)stepViewControllerClass {
    return [RK1VisualConsentStepViewController class];
}

- (instancetype)initWithIdentifier:(NSString *)identifier document:(RK1ConsentDocument *)consentDocument {
    self = [super initWithIdentifier:identifier];
    if (self) {
        self.consentDocument = consentDocument;
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    RK1VisualConsentStep *step = [super copyWithZone:zone];
    step.consentDocument = self.consentDocument;
    return step;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        RK1_DECODE_OBJ_CLASS(aDecoder, consentDocument, RK1ConsentDocument);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    RK1_ENCODE_OBJ(aCoder, consentDocument);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            RK1EqualObjects(self.consentDocument, castObject.consentDocument));
}

- (NSUInteger)hash {
    return super.hash ^ self.consentDocument.hash;
}

- (BOOL)showsProgress {
    return NO;
}

@end
