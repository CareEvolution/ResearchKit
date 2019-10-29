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


#import "RK1ImageSelectionView.h"

#import "RK1ImageChoiceLabel.h"

#import "RK1ChoiceAnswerFormatHelper.h"

#import "RK1Helpers_Internal.h"
#import "RK1Skin.h"


@interface RK1ChoiceButtonView : UIView

- (instancetype)initWithImageChoice:(RK1ImageChoice *)choice;

@property (nonatomic, strong) UIButton *button;
@property (nonatomic, copy) NSString *labelText;

@end


@implementation RK1ChoiceButtonView

- (instancetype)initWithImageChoice:(RK1ImageChoice *)choice {
    self = [super init];
    if (self) {
        _labelText = choice.text.length > 0 ? choice.text: @" ";
        
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.exclusiveTouch = YES;
       
        if (choice.selectedStateImage) {
            [_button setImage:choice.selectedStateImage forState:UIControlStateSelected];
        }
        
        [_button setImage:choice.normalStateImage forState:UIControlStateNormal];
        
        _button.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        [self addSubview:_button];
        RK1EnableAutoLayoutForViews(@[_button, _button.imageView]);
        [self setUpConstraints];
        
        // Accessibility
        NSString *trimmedText = [self.labelText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ( trimmedText.length == 0 ) {
            self.button.accessibilityLabel = RK1LocalizedString(@"AX_UNLABELED_IMAGE", nil);
        } else {
            self.button.accessibilityLabel = self.labelText;
        }
    }
    return self;
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    NSDictionary *views = @{ @"button": _button };
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[button]|"
                                                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                                                             metrics:nil
                                                                               views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[button]|"
                                                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                                                             metrics:nil
                                                                               views:views]];
    
    UIImage *image = [_button imageForState:UIControlStateNormal];
    if (image.size.height > 0 && image.size.width > 0) {
        // Keep Aspect ratio
        [constraints addObject:[NSLayoutConstraint constraintWithItem:_button
                                                            attribute:NSLayoutAttributeHeight
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:_button.imageView
                                                            attribute:NSLayoutAttributeWidth
                                                           multiplier:image.size.height / image.size.width
                                                             constant:0.0]];
        // button's height <= image
        [constraints addObject:[NSLayoutConstraint constraintWithItem:_button
                                                            attribute:NSLayoutAttributeHeight
                                                            relatedBy:NSLayoutRelationLessThanOrEqual
                                                               toItem:nil attribute:NSLayoutAttributeHeight
                                                           multiplier:1.0
                                                             constant:image.size.height]];
    } else {
        // Keep Aspect ratio
        [constraints addObject:[NSLayoutConstraint constraintWithItem:_button
                                                            attribute:NSLayoutAttributeHeight
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:_button.imageView
                                                            attribute:NSLayoutAttributeWidth
                                                           multiplier:1.0
                                                             constant:0.0]];
        RK1_Log_Warning(@"The size of imageChoice's normal image should not be zero. %@", image);
    }
    
    [NSLayoutConstraint activateConstraints:constraints];
}

@end


static const CGFloat SpacerWidth = 10.0;

@implementation RK1ImageSelectionView {
    RK1ChoiceAnswerFormatHelper *_helper;
    NSArray *_buttonViews;
    RK1ImageChoiceLabel *_choiceLabel;
    RK1ImageChoiceLabel *_placeHolderLabel;
}

- (RK1ImageChoiceLabel *)makeLabel {
    RK1ImageChoiceLabel *label = [[RK1ImageChoiceLabel alloc] init];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    return label;
}

- (instancetype)initWithImageChoiceAnswerFormat:(RK1ImageChoiceAnswerFormat *)answerFormat answer:(id)answer {
    self = [self init];
    if (self) {
        
        NSAssert([answerFormat isKindOfClass:[RK1ImageChoiceAnswerFormat class]], @"answerFormat should be an instance of RK1ImageChoiceAnswerFormat");
        
        _helper = [[RK1ChoiceAnswerFormatHelper alloc] initWithAnswerFormat:answerFormat];
        
        _placeHolderLabel = [self makeLabel];
        _placeHolderLabel.text = [RK1LocalizedString(@"PLACEHOLDER_IMAGE_CHOICES", nil) stringByAppendingString:@""];
        _placeHolderLabel.textColor = [UIColor ork_midGrayTintColor];
        
        _choiceLabel = [self makeLabel];
        
        [self resetLabelText];
        
        [self addSubview:_choiceLabel];
        [self addSubview:_placeHolderLabel];
        
        NSMutableArray *buttonViews = [NSMutableArray new];
        NSMutableArray *labelTextArray = [NSMutableArray new];
        
        NSArray *imageChoices = answerFormat.imageChoices;
        for (RK1ImageChoice *imageChoice in imageChoices) {
            if (imageChoice.text) {
                [labelTextArray addObject:imageChoice.text];
            }
            
            RK1ChoiceButtonView *buttonView = [[RK1ChoiceButtonView alloc] initWithImageChoice:imageChoice];
            [buttonView.button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [buttonViews addObject:buttonView];
            [self addSubview:buttonView];
        }
        
        _choiceLabel.textArray = labelTextArray;
        _buttonViews = buttonViews;
        
        for (UILabel *label in @[_choiceLabel, _placeHolderLabel]) {
            label.isAccessibilityElement = NO;
        }
        
        RK1EnableAutoLayoutForViews(@[_placeHolderLabel, _choiceLabel]);
        RK1EnableAutoLayoutForViews(_buttonViews);
        [self setUpConstraints];
    }
    return self;
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    [constraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_choiceLabel]-|"
                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                             metrics:nil
                                               views:@{@"_choiceLabel": _choiceLabel}]];
    [constraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_placeHolderLabel]-|"
                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                             metrics:nil
                                               views:@{@"_placeHolderLabel": _placeHolderLabel}]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_placeHolderLabel
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_choiceLabel
                                                        attribute:NSLayoutAttributeCenterY
                                                       multiplier:1.0
                                                         constant:0.0]];

    RK1ChoiceButtonView *previousView = nil;
    for (RK1ChoiceButtonView *buttonView in _buttonViews) {
        NSDictionary *views = NSDictionaryOfVariableBindings(buttonView, _choiceLabel);
        
        [constraints addObjectsFromArray:
         [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[buttonView]-30-[_choiceLabel]-|"
                                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                                 metrics:nil
                                                   views:views]];
        
        if (previousView) {
            // ButtonView left trailing
            [constraints addObject:[NSLayoutConstraint constraintWithItem:buttonView
                                                                attribute:NSLayoutAttributeLeft
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:previousView
                                                                attribute:NSLayoutAttributeRight
                                                               multiplier:1.0
                                                                 constant:SpacerWidth]];
            
            // All ButtonViews has equal width
            [constraints addObject:[NSLayoutConstraint constraintWithItem:buttonView
                                                                attribute:NSLayoutAttributeWidth
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:previousView
                                                                attribute:NSLayoutAttributeWidth
                                                               multiplier:1.0
                                                                 constant:0.0]];
            
        } else {
            // ButtonView left trailing
            [constraints addObject:[NSLayoutConstraint constraintWithItem:buttonView
                                                                attribute:NSLayoutAttributeLeft
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self
                                                                attribute:NSLayoutAttributeLeft
                                                               multiplier:1.0
                                                                 constant:SpacerWidth]];
        }
        previousView = buttonView;
    }
    
    if (previousView) {
        // ButtonView right trailing
        [constraints addObject:[NSLayoutConstraint constraintWithItem:previousView
                                                            attribute:NSLayoutAttributeRight
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self
                                                            attribute:NSLayoutAttributeRight
                                                           multiplier:1.0
                                                             constant:-SpacerWidth]];
    }
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)setAnswer:(id)answer {
    _answer = answer;
    
    NSArray *selectedIndexes = [_helper selectedIndexesForAnswer:answer];
    
    [self setSelectedIndexes:selectedIndexes];
}

- (void)resetLabelText {
    _placeHolderLabel.hidden = NO;
    _choiceLabel.hidden = !_placeHolderLabel.hidden;
    
}

- (void)setLabelText:(NSString *)text {
    _choiceLabel.text = text;
    _choiceLabel.textColor = [UIColor blackColor];
    
    _choiceLabel.hidden = NO;
    _placeHolderLabel.hidden = !_choiceLabel.hidden;
    
}

- (IBAction)buttonTapped:(UIButton *)button {
    button.selected = !button.selected;
    
    if (button.selected) {
        [_buttonViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
             RK1ChoiceButtonView *buttonView = obj;
             if (buttonView.button != button) {
                 buttonView.button.selected = NO;
             } else {
                 [self setLabelText:buttonView.labelText];
             }
             
         }];
        
    } else {
        [self resetLabelText];
    }
    
    _answer = [_helper answerForSelectedIndexes:[self selectedIndexes]];
    
    if ([_delegate respondsToSelector:@selector(selectionViewSelectionDidChange:)]) {
        [_delegate selectionViewSelectionDidChange:self];
    }
}

- (NSArray *)selectedIndexes {
    NSMutableArray *array = [NSMutableArray new];
    
    [_buttonViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         RK1ChoiceButtonView *buttonView = obj;
         if (buttonView.button.selected)
         {
             [array addObject:@(idx)];
         }
     }];
    
    return [array copy];
}

- (void)setSelectedIndexes:(NSArray *)selectedIndexes {
    [selectedIndexes enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
        if (![object isKindOfClass:[NSNumber class]]) {
            @throw [NSException exceptionWithName:NSGenericException reason:@"selectedIndexes should only containt objects of the NSNumber kind" userInfo:nil];
        }
        NSNumber *number = object;
        if (number.unsignedIntegerValue < _buttonViews.count) {
            RK1ChoiceButtonView *buttonView = _buttonViews[number.unsignedIntegerValue];
            [buttonView button].selected = YES;
            [self setLabelText:buttonView.labelText];
        }
    }];
}

- (BOOL)isAccessibilityElement {
    return NO;
}

@end
