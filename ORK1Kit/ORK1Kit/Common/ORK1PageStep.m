/*
 Copyright (c) 2016, Sage Bionetworks
 
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

#import "ORK1PageStep_Private.h"
#import "ORK1Helpers_Internal.h"
#import "ORK1PageStepViewController.h"
#import "ORK1Result.h"


@implementation ORK1PageStep

- (instancetype)initWithIdentifier:(NSString *)identifier {
    return [self initWithIdentifier:identifier steps:@[]];
}

- (instancetype)initWithIdentifier:(NSString *)identifier steps:(NSArray<ORK1Step *> *)steps {
    self = [super initWithIdentifier:identifier];
    if (self) {
        [self ork_initializePageTask:[[ORK1OrderedTask alloc] initWithIdentifier:identifier steps:steps]];
    }
    return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier pageTask:(ORK1OrderedTask *)task {
    self = [super initWithIdentifier:identifier];
    if (self) {
        [self ork_initializePageTask:task];
    }
    return self;
}

- (void)ork_initializePageTask:(ORK1OrderedTask *)task {
    _pageTask = [task copy];
    [self validateParameters];
}

- (NSArray<ORK1Step *> *)steps {
    return self.pageTask.steps;
}

#pragma mark - view controller instantiation

+ (Class)stepViewControllerClass {
    return [ORK1PageStepViewController class];
}

#pragma mark - permissions

- (ORK1PermissionMask)requestedPermissions {
    if ([self.pageTask respondsToSelector:@selector(requestedPermissions)]) {
        return [self.pageTask requestedPermissions];
    }
    return ORK1PermissionNone;
}

- (NSSet<HKObjectType *> *)requestedHealthKitTypesForReading {
    if ([self.pageTask respondsToSelector:@selector(requestedHealthKitTypesForReading)]) {
        return [self.pageTask requestedHealthKitTypesForReading];
    }
    return nil;
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1PageStep *copy = [super copyWithZone:zone];
    copy->_pageTask = [_pageTask copyWithZone:zone];
    return copy;
}

#pragma mark - Equality

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return ([super isEqual:object]
            && ORK1EqualObjects(self.pageTask, castObject.pageTask));
}

- (NSUInteger)hash {
    return [super hash] ^ [self.pageTask hash];
}

#pragma mark - step handling

- (void)validateParameters {
    if ([self.pageTask respondsToSelector:@selector(validateParameters)]) {
        [self.pageTask validateParameters];
    }
}

- (ORK1Step *)stepAfterStepWithIdentifier:(NSString *)identifier withResult:(ORK1TaskResult *)result {
    ORK1Step *step = (identifier != nil) ? [self stepWithIdentifier:identifier] : nil;
    return [self.pageTask stepAfterStep:step withResult:result];
}

- (ORK1Step *)stepBeforeStepWithIdentifier:(NSString *)identifier withResult:(ORK1TaskResult *)result {
    ORK1Step *step = (identifier != nil) ? [self stepWithIdentifier:identifier] : nil;
    return [self.pageTask stepBeforeStep:step withResult:result];
}

- (ORK1Step *)stepWithIdentifier:(NSString *)identifier {
    return [self.pageTask stepWithIdentifier:identifier];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, pageTask);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, pageTask, ORK1OrderedTask);
    }
    return self;
}


@end
