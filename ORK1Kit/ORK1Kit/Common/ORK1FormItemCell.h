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


@import UIKit;


NS_ASSUME_NONNULL_BEGIN

@class ORK1FormItem;
@class ORK1FormItemCell;

@protocol ORK1FormItemCellDelegate <NSObject>

@required
- (void)formItemCell:(ORK1FormItemCell *)cell answerDidChangeTo:(nullable id)answer;
- (void)formItemCellDidBecomeFirstResponder:(ORK1FormItemCell *)cell;
- (void)formItemCellDidResignFirstResponder:(ORK1FormItemCell *)cell;
- (void)formItemCell:(ORK1FormItemCell *)cell invalidInputAlertWithMessage:(NSString *)input;
- (void)formItemCell:(ORK1FormItemCell *)cell invalidInputAlertWithTitle:(NSString *)title message:(NSString *)message;

@end


@interface ORK1FormItemCell : UITableViewCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
                               formItem:(ORK1FormItem *)formItem
                                 answer:(nullable id)answer
                          maxLabelWidth:(CGFloat)maxLabelWidth
                               delegate:(id<ORK1FormItemCellDelegate>)delegate;

@property (nonatomic, weak, readonly) id<ORK1FormItemCellDelegate> delegate;
@property (nonatomic, copy, nullable) id answer;
@property (nonatomic, strong) ORK1FormItem *formItem;
@property (nonatomic, copy, nullable) id defaultAnswer;
@property (nonatomic) CGFloat maxLabelWidth;
@property (nonatomic) CGFloat expectedLayoutWidth;
@property (nonatomic) NSDictionary *savedAnswers;

@end


@interface ORK1FormItemTextFieldBasedCell : ORK1FormItemCell <UITextFieldDelegate>

@end


@interface ORK1FormItemTextFieldCell : ORK1FormItemTextFieldBasedCell

@end


@interface ORK1FormItemConfirmTextCell : ORK1FormItemTextFieldCell

@end


@interface ORK1FormItemNumericCell : ORK1FormItemTextFieldBasedCell

@end


@interface ORK1FormItemTextCell : ORK1FormItemCell <UITextViewDelegate>

@end


@interface ORK1FormItemImageSelectionCell : ORK1FormItemCell

@end


@interface ORK1FormItemPickerCell : ORK1FormItemTextFieldBasedCell

@end


@interface ORK1FormItemScaleCell : ORK1FormItemCell

@end


@interface ORK1FormItemLocationCell : ORK1FormItemCell

@end

NS_ASSUME_NONNULL_END
