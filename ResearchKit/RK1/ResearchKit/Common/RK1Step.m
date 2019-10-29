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


#import "RK1Step.h"
#import "RK1Step_Private.h"

#import "RK1StepViewController.h"

#import "RK1OrderedTask.h"
#import "RK1StepViewController_Internal.h"

#import "RK1Helpers_Internal.h"


@implementation RK1Step

+ (instancetype)new {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super init];
    if (self) {
        RK1ThrowInvalidArgumentExceptionIfNil(identifier);
        _identifier = [identifier copy];
    }
    return self;
}

+ (Class)stepViewControllerClass {
    return [RK1StepViewController class];
}

- (Class)stepViewControllerClass {
    return [[self class] stepViewControllerClass];
}

- (RK1StepViewController *)instantiateStepViewControllerWithResult:(RK1Result *)result {
    Class stepViewControllerClass = [self stepViewControllerClass];
    
    RK1StepViewController *stepViewController = [[stepViewControllerClass alloc] initWithStep:self result:result];
    
    // Set the restoration info using the given class
    stepViewController.restorationIdentifier = self.identifier;
    stepViewController.restorationClass = stepViewControllerClass;
    
    return stepViewController;
}

- (instancetype)copyWithIdentifier:(NSString *)identifier {
    RK1ThrowInvalidArgumentExceptionIfNil(identifier)
    RK1Step *step = [self copy];
    step->_identifier = [identifier copy];
    return step;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    RK1Step *step = [[[self class] allocWithZone:zone] initWithIdentifier:[_identifier copy]];
    step.title = _title;
    step.optional = _optional;
    step.text = _text;
    step.shouldTintImages = _shouldTintImages;
    step.useSurveyMode = _useSurveyMode;
    return step;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    // Ignore the task reference - it's not part of the content of the step.
    __typeof(self) castObject = object;
    return (RK1EqualObjects(self.identifier, castObject.identifier)
            && RK1EqualObjects(self.title, castObject.title)
            && RK1EqualObjects(self.text, castObject.text)
            && (self.optional == castObject.optional)
            && (self.shouldTintImages == castObject.shouldTintImages)
            && (self.useSurveyMode == castObject.useSurveyMode));
}

- (NSUInteger)hash {
    // Ignore the task reference - it's not part of the content of the step.
    return _identifier.hash ^ _title.hash ^ _text.hash ^ (_optional ? 0xf : 0x0);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        RK1_DECODE_OBJ_CLASS(aDecoder, identifier, NSString);
        RK1_DECODE_OBJ_CLASS(aDecoder, title, NSString);
        RK1_DECODE_OBJ_CLASS(aDecoder, text, NSString);
        RK1_DECODE_BOOL(aDecoder, optional);
        RK1_DECODE_OBJ_CLASS(aDecoder, task, RK1OrderedTask);
        RK1_DECODE_BOOL(aDecoder, shouldTintImages);
        RK1_DECODE_BOOL(aDecoder, useSurveyMode);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    RK1_ENCODE_OBJ(aCoder, identifier);
    RK1_ENCODE_OBJ(aCoder, title);
    RK1_ENCODE_OBJ(aCoder, text);
    RK1_ENCODE_BOOL(aCoder, optional);
    RK1_ENCODE_BOOL(aCoder, shouldTintImages);
    RK1_ENCODE_BOOL(aCoder, useSurveyMode);
    if ([_task isKindOfClass:[RK1OrderedTask class]]) {
        RK1_ENCODE_OBJ(aCoder, task);
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %@ %@>", super.description, self.identifier, self.title];
}

- (BOOL)showsProgress {
    return YES;
}

- (BOOL)allowsBackNavigation {
    return YES;
}

- (BOOL)isRestorable {
    return YES;
}

- (void)validateParameters {
    
}

- (RK1PermissionMask)requestedPermissions {
    return RK1PermissionNone;
}

- (NSSet<HKObjectType *> *)requestedHealthKitTypesForReading {
    return nil;
}

@end
