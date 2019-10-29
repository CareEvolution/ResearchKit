/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 Copyright (c) 2015, James Cox.
 Copyright (c) 2015, Ricardo Sánchez-Sáez.
 
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


#import "RK1PieChartTitleTextView.h"

#import "RK1PieChartView_Internal.h"

#import "RK1Helpers_Internal.h"
#import "RK1Skin.h"


@implementation RK1PieChartTitleTextView  {
    __weak RK1PieChartView *_parentPieChartView;
    
    NSMutableArray<NSLayoutConstraint *> *_variableConstraints;
}

- (instancetype)initWithFrame:(CGRect)frame {
    RK1ThrowMethodUnavailableException();
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    RK1ThrowMethodUnavailableException();
}
#pragma clang diagnostic pop

- (instancetype)initWithParentPieChartView:(RK1PieChartView *)parentPieChartView {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _parentPieChartView = parentPieChartView;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        _titleLabel = [UILabel new];
        _titleLabel.textColor = RK1Color(RK1ChartDefaultTextColorKey);
        [_titleLabel setTextAlignment:NSTextAlignmentCenter];
        
        _textLabel = [UILabel new];
        _textLabel.textColor = RK1Color(RK1ChartDefaultTextColorKey);
        [_textLabel setTextAlignment:NSTextAlignmentCenter];
        
        _noDataLabel = [UILabel new];
        _noDataLabel.textColor = [UIColor lightGrayColor];
        _noDataLabel.text = RK1LocalizedString(@"CHART_NO_DATA_TEXT", nil);
        _noDataLabel.textAlignment = NSTextAlignmentCenter;
        _noDataLabel.hidden = YES;
        
        [self addSubview:_titleLabel];
        [self addSubview:_textLabel];
        [self addSubview:_noDataLabel];
        
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _noDataLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self setUpConstraints];
        [self setNeedsUpdateConstraints];
    }
    return self;
}

- (void)setUpConstraints {
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_titleLabel
                                                        attribute:NSLayoutAttributeCenterX
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeCenterX
                                                       multiplier:1.0
                                                         constant:0.0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_textLabel
                                                        attribute:NSLayoutAttributeCenterX
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeCenterX
                                                       multiplier:1.0
                                                         constant:0.0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_noDataLabel
                                                        attribute:NSLayoutAttributeCenterX
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeCenterX
                                                       multiplier:1.0
                                                         constant:0.0]];
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)updateConstraints {
    [NSLayoutConstraint deactivateConstraints:_variableConstraints];
    [_variableConstraints removeAllObjects];
    if (!_variableConstraints) {
        _variableConstraints = [NSMutableArray new];
    }
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_titleLabel, _textLabel, _noDataLabel);
    if (_noDataLabel.hidden) {
        [_variableConstraints addObjectsFromArray:
         [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_titleLabel][_textLabel]|"
                                                 options:(NSLayoutFormatOptions)0
                                                 metrics:nil
                                                   views:views]];
    } else {
        [_variableConstraints addObjectsFromArray:
         [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_noDataLabel]|"
                                                 options:(NSLayoutFormatOptions)0
                                                 metrics:nil
                                                   views:views]];
    }
    
    [NSLayoutConstraint activateConstraints:_variableConstraints];
    [super updateConstraints];
}

- (void)showNoDataLabel:(BOOL)showNoDataLabel {
    _titleLabel.hidden = showNoDataLabel;
    _textLabel.hidden = showNoDataLabel;
    _noDataLabel.hidden = !showNoDataLabel;
    [self setNeedsUpdateConstraints];
}

- (void)animateWithDuration:(NSTimeInterval)animationDuration {
    _titleLabel.alpha = 0.0;
    _textLabel.alpha = 0.0;
    _noDataLabel.alpha = 0.0;
    [UIView animateWithDuration:animationDuration
                     animations:^{
                         _titleLabel.alpha = 1.0;
                         _textLabel.alpha = 1.0;
                         _noDataLabel.alpha = 1.0;
                     }];
}

#pragma mark - Accessibility

- (NSArray<id> *)accessibilityElements {
    if (!_titleLabel || !_textLabel || !_noDataLabel) {
        return nil;
    }
    
    NSMutableArray<id> *accessibilityElements = [[NSMutableArray alloc] init];
    if (!_noDataLabel.hidden) {
        [accessibilityElements addObject:_noDataLabel];
    } else {
        [accessibilityElements addObject:_titleLabel];
        [accessibilityElements addObject:_textLabel];
    }
    
    return accessibilityElements;
}

@end
