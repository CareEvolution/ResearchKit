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


#import "ORK1ChoiceViewCell.h"

#import "ORK1SelectionTitleLabel.h"
#import "ORK1SelectionSubTitleLabel.h"

#import "ORK1Accessibility.h"
#import "ORK1Helpers_Internal.h"
#import "ORK1AnswerFormat_Internal.h"
#import "ORK1Skin.h"

NSNotificationName const ORK1UpdateChoiceCell = @"ORK1UpdateChoiceCell";
NSString const *ORK1UpdateChoiceCellKeyCell = @"ORK1UpdateChoiceCellKeyCell";

static const CGFloat LabelRightMargin = 44.0;
static const CGFloat DetailTextIndicatorTouchTargetWidth = 30.0;
static const CGFloat DetailTextIndicatorImageWidth = 15.0;
static const CGFloat DetailTextIndicatorPaddingFromLabel = 10.0;


@implementation ORK1ChoiceViewCell {
    UIImageView *_checkView;
    ORK1SelectionTitleLabel *_shortLabel;
    ORK1SelectionSubTitleLabel *_longLabel;
    UIButton *_detailTextIndicator;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.clipsToBounds = YES;
        _checkView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"checkmark" inBundle:ORK1Bundle() compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.accessoryView = _checkView;
        self.showDetailTextIndicator = NO;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat firstBaselineOffsetFromTop = ORK1GetMetricForWindow(ORK1ScreenMetricChoiceCellFirstBaselineOffsetFromTop, self.window);
    CGFloat labelLastBaselineToLabelFirstBaseline = ORK1GetMetricForWindow(ORK1ScreenMetricChoiceCellLabelLastBaselineToLabelFirstBaseline, self.window);
    
    CGFloat cellLeftMargin = self.separatorInset.left;

    CGFloat labelWidth =  self.bounds.size.width - (cellLeftMargin + LabelRightMargin);
    CGFloat shortLabelWidth = [self.shortLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)].width;
    
    // Check for word wrapping
    if (self.showDetailTextIndicator && shortLabelWidth > labelWidth - (DetailTextIndicatorTouchTargetWidth + DetailTextIndicatorPaddingFromLabel)) {
        shortLabelWidth = labelWidth - (DetailTextIndicatorTouchTargetWidth + DetailTextIndicatorPaddingFromLabel);
    } else if (shortLabelWidth > labelWidth) {
        shortLabelWidth = labelWidth;
    }
    
    CGFloat cellHeight = self.bounds.size.height;
    
    [self detailTextIndicator].hidden = !self.showDetailTextIndicator;
    
    if (self.longLabel.text.length == 0 && self.shortLabel.text.length == 0) {
        self.shortLabel.frame = CGRectZero;
        self.longLabel.frame = CGRectZero;
    } else if (self.longLabel.text.length == 0) {
        self.shortLabel.frame = CGRectMake(cellLeftMargin, 0, shortLabelWidth, cellHeight);
        self.detailTextIndicator.frame =
        CGRectMake(
                   cellLeftMargin + shortLabelWidth + DetailTextIndicatorPaddingFromLabel,
                   self.shortLabel.frame.size.height / 2 - DetailTextIndicatorTouchTargetWidth / 2,
                   DetailTextIndicatorTouchTargetWidth,
                   DetailTextIndicatorTouchTargetWidth);
        self.longLabel.frame = CGRectZero;
    } else if (self.shortLabel.text.length == 0) {
        self.longLabel.frame = CGRectMake(cellLeftMargin, 0, labelWidth, cellHeight);
        self.shortLabel.frame = CGRectZero;
    } else {
        {
            self.shortLabel.frame = CGRectMake(cellLeftMargin, 0,
                                               shortLabelWidth, 1);
            
            ORK1AdjustHeightForLabel(self.shortLabel);
            
            CGRect rect = self.shortLabel.frame;
            
            CGFloat shortLabelFirstBaselineApproximateOffsetFromTop = self.shortLabel.font.ascender;
            
            rect.origin.y = firstBaselineOffsetFromTop - shortLabelFirstBaselineApproximateOffsetFromTop;
            self.shortLabel.frame = rect;
            self.detailTextIndicator.frame =
            CGRectMake(
                       cellLeftMargin + shortLabelWidth + 10,
                       self.shortLabel.frame.size.height / 2 - DetailTextIndicatorTouchTargetWidth / 2 + self.shortLabel.frame.origin.y,
                       DetailTextIndicatorTouchTargetWidth,
                       DetailTextIndicatorTouchTargetWidth);
        }
        
        {
            self.longLabel.frame = CGRectMake(cellLeftMargin, 0,
                                              labelWidth, 1);
            
            ORK1AdjustHeightForLabel(self.longLabel);
            
            CGRect rect = self.longLabel.frame;
            
            CGFloat shortLabelBaselineApproximateOffsetFromBottom = ABS(self.shortLabel.font.descender);
            CGFloat longLabelApproximateFirstBaselineOffset = self.longLabel.font.ascender;
            
            rect.origin.y = CGRectGetMaxY(self.shortLabel.frame) - shortLabelBaselineApproximateOffsetFromBottom + labelLastBaselineToLabelFirstBaseline - longLabelApproximateFirstBaselineOffset;
    
            self.longLabel.frame = rect;
            
        }
    }
    [self updateSelectedItem];
}

- (ORK1SelectionTitleLabel *)shortLabel {
    if (_shortLabel == nil ) {
        _shortLabel = [ORK1SelectionTitleLabel new];
        _shortLabel.numberOfLines = 0;
        [self.contentView addSubview:_shortLabel];
    }
    return _shortLabel;
}

- (ORK1SelectionSubTitleLabel *)longLabel {
    if (_longLabel == nil) {
        _longLabel = [ORK1SelectionSubTitleLabel new];
        _longLabel.numberOfLines = 0;
        _longLabel.textColor = [UIColor ork_darkGrayColor];
        [self.contentView addSubview:_longLabel];
    }
    return _longLabel;
}

- (UIButton *)detailTextIndicator {
    if (_detailTextIndicator == nil) {
        _detailTextIndicator = [UIButton buttonWithType:UIButtonTypeInfoDark];
        CGFloat inset = (DetailTextIndicatorTouchTargetWidth - DetailTextIndicatorImageWidth) / 2;
        _detailTextIndicator.imageEdgeInsets = UIEdgeInsetsMake(inset, inset, inset, inset);
        [self.contentView addSubview:_detailTextIndicator];
        [_detailTextIndicator addTarget:self action:@selector(toggleDetailText) forControlEvents:UIControlEventTouchUpInside];
    }
    return _detailTextIndicator;
}

- (void)toggleDetailText {
    self.choice.detailTextShouldDisplay = !self.choice.detailTextShouldDisplay;
    NSNotification *notification = [NSNotification notificationWithName:ORK1UpdateChoiceCell object:nil userInfo:@{ORK1UpdateChoiceCellKeyCell : self}];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    [self updateSelectedItem];
}

- (void)updateSelectedItem {
    if (_immediateNavigation == NO) {
        self.accessoryView.hidden = _selectedItem ? NO : YES;
        self.shortLabel.textColor = _selectedItem ? [self tintColor] : [UIColor blackColor];
        self.longLabel.textColor = _selectedItem ? [[self tintColor] colorWithAlphaComponent:192.0 / 255.0] : [UIColor ork_darkGrayColor];
    }
}

- (void)setImmediateNavigation:(BOOL)immediateNavigation {
    _immediateNavigation = immediateNavigation;
    
    if (_immediateNavigation == YES) {
        self.accessoryView = nil;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
}

- (void)setSelectedItem:(BOOL)selectedItem {
    _selectedItem = selectedItem;
    [self updateSelectedItem];
}

+ (CGFloat)suggestedCellHeightForShortText:(NSString *)shortText longText:(NSString *)longText showDetailTextIndicator:(BOOL)showDetailTextIndicator inTableView:(UITableView *)tableView {
    CGFloat height = 0;
    
    CGFloat firstBaselineOffsetFromTop = ORK1GetMetricForWindow(ORK1ScreenMetricChoiceCellFirstBaselineOffsetFromTop, tableView.window);
    CGFloat labelLastBaselineToLabelFirstBaseline = ORK1GetMetricForWindow(ORK1ScreenMetricChoiceCellLabelLastBaselineToLabelFirstBaseline, tableView.window);
    CGFloat lastBaselineToBottom = ORK1GetMetricForWindow(ORK1ScreenMetricChoiceCellLastBaselineToBottom, tableView.window);
    CGFloat cellLeftMargin =  ORK1StandardLeftMarginForTableViewCell(tableView);
    CGFloat labelWidth =  tableView.bounds.size.width - (cellLeftMargin + LabelRightMargin);
   
    if (shortText.length > 0) {
        static ORK1SelectionTitleLabel *shortLabel;
        if (shortLabel == nil) {
            shortLabel = [ORK1SelectionTitleLabel new];
            shortLabel.numberOfLines = 0;
        }
        
        if (showDetailTextIndicator) {
            shortLabel.frame = CGRectMake(0, 0, labelWidth - (DetailTextIndicatorTouchTargetWidth + DetailTextIndicatorPaddingFromLabel), 0);
        } else {
            shortLabel.frame = CGRectMake(0, 0, labelWidth, 0);
        }
        shortLabel.text = shortText;
        
        ORK1AdjustHeightForLabel(shortLabel);
        CGFloat shortLabelFirstBaselineApproximateOffsetFromTop = shortLabel.font.ascender;
    
        height += firstBaselineOffsetFromTop - shortLabelFirstBaselineApproximateOffsetFromTop + shortLabel.frame.size.height;
    }
    
    if (longText.length > 0) {
        static ORK1SelectionSubTitleLabel *longLabel;
        if (longLabel == nil) {
            longLabel = [ORK1SelectionSubTitleLabel new];
            longLabel.numberOfLines = 0;
        }
        
        longLabel.frame = CGRectMake(0, 0, labelWidth, 0);
        longLabel.text = longText;
        
        ORK1AdjustHeightForLabel(longLabel);
        
        CGFloat longLabelApproximateFirstBaselineOffset = longLabel.font.ascender;
        
        if (shortText.length > 0) {
            height += labelLastBaselineToLabelFirstBaseline - longLabelApproximateFirstBaselineOffset + longLabel.frame.size.height;
        } else {
            height += firstBaselineOffsetFromTop - longLabelApproximateFirstBaselineOffset + longLabel.frame.size.height;
        }

    }
    
    height += lastBaselineToBottom;
   
    CGFloat minCellHeight = ORK1GetMetricForWindow(ORK1ScreenMetricTableCellDefaultHeight, tableView.window);
    
    return MAX(height, minCellHeight);
}

#pragma mark - Accessibility

- (NSString *)accessibilityLabel {
    return ORK1AccessibilityStringForVariables(self.shortLabel.accessibilityLabel, self.longLabel.accessibilityLabel);
}

- (UIAccessibilityTraits)accessibilityTraits {
    return UIAccessibilityTraitButton | (self.selectedItem ? UIAccessibilityTraitSelected : 0);
}

@end
