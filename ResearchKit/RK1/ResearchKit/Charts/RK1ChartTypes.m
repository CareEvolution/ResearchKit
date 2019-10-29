/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 Copyright (c) 2015, James Cox.
 Copyright (c) 2015, Ramsundar Shandilya.
 Copyright (c) 2015-2016, Ricardo Sánchez-Sáez.
 
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


#import "RK1ChartTypes.h"

#import "RK1Helpers_Internal.h"


@implementation RK1ValueRange

- (instancetype)initWithMinimumValue:(double)minimumValue maximumValue:(double)maximumValue {
    if (maximumValue < minimumValue) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"maximumValue cannot be lower than minimumValue"
                                     userInfo:nil];
    }

    self = [super init];
    if (self) {
        _minimumValue = minimumValue;
        _maximumValue = maximumValue;
    }
    return self;
}

- (instancetype)init {
    return [self initWithMinimumValue:RK1DoubleInvalidValue maximumValue:RK1DoubleInvalidValue];
}

- (instancetype)initWithValue:(double)value {
    return [self initWithMinimumValue:value maximumValue:value];
}

- (BOOL)isUnset {
    return (_minimumValue == RK1DoubleInvalidValue && _maximumValue == RK1DoubleInvalidValue);
}

- (BOOL)isEmptyRange {
    return (_minimumValue == _maximumValue);
}

- (NSString *)description {
    NSString *minimumValueString = (_minimumValue == RK1DoubleInvalidValue) ? @"RK1DoubleInvalidValue" : [NSString stringWithFormat:@"%0.0f", _minimumValue] ;
    NSString *maximumValueString = (_maximumValue == RK1DoubleInvalidValue) ? @"RK1DoubleInvalidValue" : [NSString stringWithFormat:@"%0.0f", _maximumValue] ;
    return [NSString stringWithFormat:@"<%@: %p; min = %@; max = %@>", self.class.description, self, minimumValueString, maximumValueString];
}

#pragma mark - Accessibility

- (NSString *)accessibilityLabel {
    if (self.isUnset) {
        return nil;
    }
    
    if (self.isEmptyRange || _minimumValue == _maximumValue) {
        return @(_maximumValue).stringValue;
    } else {
        NSString *rangeFormat = RK1LocalizedString(@"AX_GRAPH_RANGE_FORMAT_%@_%@", nil);
        return [NSString stringWithFormat:rangeFormat, @(_minimumValue).stringValue, @(_maximumValue).stringValue];
    }
}

@end


@implementation RK1ValueStack

- (instancetype)init {
    return [self initWithStackedValues:@[]];
}

- (instancetype)initWithStackedValues:(NSArray<NSNumber *> *)stackedValues {
    self = [super init];
    if (self) {
        if (stackedValues.count == 0) {
            _totalValue = RK1DoubleInvalidValue;
        } else {
            _totalValue = 0;
            for (NSNumber *number in stackedValues) {
                if (![number isKindOfClass:[NSNumber class]]) {
                    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                                   reason:@"stackedValues must only contain NSNumber objects"
                                                 userInfo:nil];
                }
                _totalValue += number.doubleValue;
            }
        }
        _stackedValues = [stackedValues copy];
    }
    return self;
}

- (BOOL)isUnset {
    return !_stackedValues || _stackedValues.count == 0;
}

- (NSString *)description {
    NSMutableString *mutableString = [NSMutableString new];
    [mutableString appendFormat:@"<%@: %p; (", self.class.description, self];
    NSUInteger numberOfStackedValues = _stackedValues.count;
    for (NSInteger index = 0; index < numberOfStackedValues; index++) {
        [mutableString appendFormat:@"%0.0f", _stackedValues[index].doubleValue];
        if (index < numberOfStackedValues - 1) {
            [mutableString appendString:@", "];
        }
    }
    [mutableString appendString:@")>"];
    return [mutableString copy];
}

#pragma mark - Accessibility

- (NSString *)accessibilityLabel {
    if (self.isUnset) {
        return nil;
    }
    
    NSMutableString *mutableString = [[NSMutableString alloc] initWithFormat:@"%@ %@",
                                      RK1LocalizedString(@"AX_GRAPH_STACK_PREFIX", nil), _stackedValues[0].stringValue];
    
    NSUInteger numberOfStackedValues = _stackedValues.count;
    for (NSInteger index = 1; index < numberOfStackedValues; index++) {
        [mutableString appendString:@", "];
        if (index == (numberOfStackedValues - 1)) {
            [mutableString appendString:RK1LocalizedString(@"AX_GRAPH_AND_SEPARATOR", nil)];
        }
        [mutableString appendFormat:@"%@", _stackedValues[index].stringValue];
    }
    return [mutableString copy];
}

@end
