/*
 Copyright (c) 2017, Apple Inc. All rights reserved.
 
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


#import "ORKStroopStep.h"
#import "ORKStroopStepViewController.h"
#import "ORKHelpers_Internal.h"

NSString *const ORKStroopColorIdentifierRed = @"RED";
NSString *const ORKStroopColorIdentifierGreen = @"GREEN";
NSString *const ORKStroopColorIdentifierBlue = @"BLUE";
NSString *const ORKStroopColorIdentifierYellow = @"YELLOW";
NSString *const ORKStroopColorIdentifierBlack = @"BLACK";

@implementation ORKStroopColor

- (instancetype)init {
    ORKThrowMethodUnavailableException();
}

- (instancetype __nullable)initWithIdentifier:(NSString *)identifier {
    if (self = [super init]) {
        if ([identifier isEqualToString:ORKStroopColorIdentifierRed]) {
            _color = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
            _title = ORKLocalizedString(@"STROOP_COLOR_RED", nil);
        } else if ([identifier isEqualToString:ORKStroopColorIdentifierGreen]) {
            _color = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
            _title = ORKLocalizedString(@"STROOP_COLOR_GREEN", nil);
        } else if ([identifier isEqualToString:ORKStroopColorIdentifierBlue]) {
            _color = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0];
            _title = ORKLocalizedString(@"STROOP_COLOR_BLUE", nil);
        } else if ([identifier isEqualToString:ORKStroopColorIdentifierYellow]) {
            _color = [UIColor colorWithRed:245.0/225.0 green:221.0/225.0 blue:66.0/255.0 alpha:1.0];
            _title = ORKLocalizedString(@"STROOP_COLOR_YELLOW", nil);
        } else if ([identifier isEqualToString:ORKStroopColorIdentifierBlack]) {
            _color = [UIColor blackColor];
            _title = ORKLocalizedString(@"STROOP_COLOR_BLACK", nil);
        } else {
            return nil;
        }
        return self;
    }
    return nil;
}
@end

@implementation ORKStroopTest
@end

@implementation ORKStroopStep

+ (Class)stepViewControllerClass {
    return [ORKStroopStepViewController class];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super initWithIdentifier:identifier];
    if (self) {
        self.shouldVibrateOnStart = YES;
        self.shouldShowDefaultTimer = NO;
        self.shouldContinueOnFinish = YES;
        self.stepDuration = NSIntegerMax;
        self.probabilityOfVisualAndColorAlignment = @(0.5);
        self.stroopStyle = ORKStroopStyleColoredText;
        self.useGridLayoutForButtons = NO;
    }
    return self;
}

- (void)validateParameters {
    [super validateParameters];
    NSInteger minimumAttempts = 3;
    if (self.numberOfAttempts < minimumAttempts) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"number of attempts should be greater or equal to %ld.", (long)minimumAttempts]  userInfo:nil];
    }
    float probabilityOfVisualAndColorAlignment = [self.probabilityOfVisualAndColorAlignment floatValue];
    if (probabilityOfVisualAndColorAlignment < 0 || probabilityOfVisualAndColorAlignment > 1) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"probability of visual and color alignment must be a number between 0 and 1" userInfo:nil];
    }
}

- (BOOL)startsFinished {
    return NO;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKStroopStep *step = [super copyWithZone:zone];
    step.numberOfAttempts = self.numberOfAttempts;
    step.probabilityOfVisualAndColorAlignment = self.probabilityOfVisualAndColorAlignment;
    step.stroopStyle = self.stroopStyle;
    step.useGridLayoutForButtons = self.useGridLayoutForButtons;
    step.nonRandomizedTests = self.nonRandomizedTests;
    return step;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self ) {
        ORK_DECODE_INTEGER(aDecoder, numberOfAttempts);
        ORK_DECODE_OBJ(aDecoder, probabilityOfVisualAndColorAlignment);
        ORK_DECODE_ENUM(aDecoder, stroopStyle);
        ORK_DECODE_BOOL(aDecoder, useGridLayoutForButtons);
        ORK_DECODE_OBJ_ARRAY(aDecoder, nonRandomizedTests, [ORKStroopTest class]);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK_ENCODE_INTEGER(aCoder, numberOfAttempts);
    ORK_ENCODE_OBJ(aCoder, probabilityOfVisualAndColorAlignment);
    ORK_ENCODE_ENUM(aCoder, stroopStyle);
    ORK_ENCODE_BOOL(aCoder, useGridLayoutForButtons);
    ORK_ENCODE_OBJ(aCoder, nonRandomizedTests);
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame && (self.numberOfAttempts == castObject.numberOfAttempts)
            && [self.probabilityOfVisualAndColorAlignment isEqual:castObject.probabilityOfVisualAndColorAlignment]
            && (self.stroopStyle == castObject.stroopStyle)
            && (self.useGridLayoutForButtons == castObject.useGridLayoutForButtons)
            && [self.nonRandomizedTests isEqual:castObject.nonRandomizedTests]);
}

@end
