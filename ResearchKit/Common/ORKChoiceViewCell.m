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


#import "ORKChoiceViewCell.h"

#import "ORKSelectionTitleLabel.h"
#import "ORKSelectionSubTitleLabel.h"

#import "ORKAccessibility.h"
#import "ORKHelpers_Internal.h"
#import "ORKSkin.h"


static const CGFloat LabelRightMargin = 44.0;


@implementation ORKLegacyChoiceViewCell {
    UIImageView *_checkView;
    ORKLegacySelectionTitleLabel *_shortLabel;
    ORKLegacySelectionSubTitleLabel *_longLabel;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.clipsToBounds = YES;
        _checkView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"checkmark" inBundle:ORKLegacyBundle() compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.accessoryView = _checkView;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat firstBaselineOffsetFromTop = ORKLegacyGetMetricForWindow(ORKLegacyScreenMetricChoiceCellFirstBaselineOffsetFromTop, self.window);
    CGFloat labelLastBaselineToLabelFirstBaseline = ORKLegacyGetMetricForWindow(ORKLegacyScreenMetricChoiceCellLabelLastBaselineToLabelFirstBaseline, self.window);
    
    CGFloat cellLeftMargin = self.separatorInset.left;

    CGFloat labelWidth =  self.bounds.size.width - (cellLeftMargin + LabelRightMargin);
    CGFloat cellHeight = self.bounds.size.height;
    
    if (self.longLabel.text.length == 0 && self.shortLabel.text.length == 0) {
        self.shortLabel.frame = CGRectZero;
        self.longLabel.frame = CGRectZero;
    } else if (self.longLabel.text.length == 0) {
        self.shortLabel.frame = CGRectMake(cellLeftMargin, 0, labelWidth, cellHeight);
        self.longLabel.frame = CGRectZero;
    } else if (self.shortLabel.text.length == 0) {
        self.longLabel.frame = CGRectMake(cellLeftMargin, 0, labelWidth, cellHeight);
        self.shortLabel.frame = CGRectZero;
    } else {
        {
            self.shortLabel.frame = CGRectMake(cellLeftMargin, 0,
                                               labelWidth, 1);
            
            ORKLegacyAdjustHeightForLabel(self.shortLabel);
            
            CGRect rect = self.shortLabel.frame;
            
            CGFloat shortLabelFirstBaselineApproximateOffsetFromTop = self.shortLabel.font.ascender;
            
            rect.origin.y = firstBaselineOffsetFromTop - shortLabelFirstBaselineApproximateOffsetFromTop;
            self.shortLabel.frame = rect;
        }
        
        {
            self.longLabel.frame = CGRectMake(cellLeftMargin, 0,
                                              labelWidth, 1);
            
            ORKLegacyAdjustHeightForLabel(self.longLabel);
            
            CGRect rect = self.longLabel.frame;
            
            CGFloat shortLabelBaselineApproximateOffsetFromBottom = ABS(self.shortLabel.font.descender);
            CGFloat longLabelApproximateFirstBaselineOffset = self.longLabel.font.ascender;
            
            rect.origin.y = CGRectGetMaxY(self.shortLabel.frame) - shortLabelBaselineApproximateOffsetFromBottom + labelLastBaselineToLabelFirstBaseline - longLabelApproximateFirstBaselineOffset;
    
            self.longLabel.frame = rect;
            
        }
    }
    [self updateSelectedItem];
}

- (ORKLegacySelectionTitleLabel *)shortLabel {
    if (_shortLabel == nil ) {
        _shortLabel = [ORKLegacySelectionTitleLabel new];
        _shortLabel.numberOfLines = 0;
        [self.contentView addSubview:_shortLabel];
    }
    return _shortLabel;
}

- (ORKLegacySelectionSubTitleLabel *)longLabel {
    if (_longLabel == nil) {
        _longLabel = [ORKLegacySelectionSubTitleLabel new];
        _longLabel.numberOfLines = 0;
        _longLabel.textColor = [UIColor ork_darkGrayColor];
        [self.contentView addSubview:_longLabel];
    }
    return _longLabel;
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

+ (CGFloat)suggestedCellHeightForShortText:(NSString *)shortText LongText:(NSString *)longText inTableView:(UITableView *)tableView {
    CGFloat height = 0;
    
    CGFloat firstBaselineOffsetFromTop = ORKLegacyGetMetricForWindow(ORKLegacyScreenMetricChoiceCellFirstBaselineOffsetFromTop, tableView.window);
    CGFloat labelLastBaselineToLabelFirstBaseline = ORKLegacyGetMetricForWindow(ORKLegacyScreenMetricChoiceCellLabelLastBaselineToLabelFirstBaseline, tableView.window);
    CGFloat lastBaselineToBottom = ORKLegacyGetMetricForWindow(ORKLegacyScreenMetricChoiceCellLastBaselineToBottom, tableView.window);
    CGFloat cellLeftMargin =  ORKLegacyStandardLeftMarginForTableViewCell(tableView);
    CGFloat labelWidth =  tableView.bounds.size.width - (cellLeftMargin + LabelRightMargin);
   
    if (shortText.length > 0) {
        static ORKLegacySelectionTitleLabel *shortLabel;
        if (shortLabel == nil) {
            shortLabel = [ORKLegacySelectionTitleLabel new];
            shortLabel.numberOfLines = 0;
        }
        
        shortLabel.frame = CGRectMake(0, 0, labelWidth, 0);
        shortLabel.text = shortText;
        
        ORKLegacyAdjustHeightForLabel(shortLabel);
        CGFloat shortLabelFirstBaselineApproximateOffsetFromTop = shortLabel.font.ascender;
    
        height += firstBaselineOffsetFromTop - shortLabelFirstBaselineApproximateOffsetFromTop + shortLabel.frame.size.height;
    }
    
    if (longText.length > 0) {
        static ORKLegacySelectionSubTitleLabel *longLabel;
        if (longLabel == nil) {
            longLabel = [ORKLegacySelectionSubTitleLabel new];
            longLabel.numberOfLines = 0;
        }
        
        longLabel.frame = CGRectMake(0, 0, labelWidth, 0);
        longLabel.text = longText;
        
        ORKLegacyAdjustHeightForLabel(longLabel);
        
        CGFloat longLabelApproximateFirstBaselineOffset = longLabel.font.ascender;
        
        if (shortText.length > 0) {
            height += labelLastBaselineToLabelFirstBaseline - longLabelApproximateFirstBaselineOffset + longLabel.frame.size.height;
        } else {
            height += firstBaselineOffsetFromTop - longLabelApproximateFirstBaselineOffset + longLabel.frame.size.height;
        }

    }
    
    height += lastBaselineToBottom;
   
    CGFloat minCellHeight = ORKLegacyGetMetricForWindow(ORKLegacyScreenMetricTableCellDefaultHeight, tableView.window);
    
    return MAX(height, minCellHeight);
}

#pragma mark - Accessibility

- (NSString *)accessibilityLabel {
    return ORKLegacyAccessibilityStringForVariables(self.shortLabel.accessibilityLabel, self.longLabel.accessibilityLabel);
}

- (UIAccessibilityTraits)accessibilityTraits {
    return UIAccessibilityTraitButton | (self.selectedItem ? UIAccessibilityTraitSelected : 0);
}

@end
