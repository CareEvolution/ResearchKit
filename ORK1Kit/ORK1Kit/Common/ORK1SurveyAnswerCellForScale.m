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


#import "ORK1SurveyAnswerCellForScale.h"

#import "ORK1ScaleSlider.h"
#import "ORK1ScaleSliderView.h"

#import "ORK1AnswerFormat_Internal.h"
#import "ORK1QuestionStep_Internal.h"

#import "ORK1Skin.h"


@interface ORK1SurveyAnswerCellForScale () <ORK1ScaleSliderViewDelegate>

@property (nonatomic, strong) ORK1ScaleSliderView *sliderView;
@property (nonatomic, strong) id<ORK1ScaleAnswerFormatProvider> formatProvider;

@end


@implementation ORK1SurveyAnswerCellForScale

- (id<ORK1ScaleAnswerFormatProvider>)formatProvider {
    if (_formatProvider == nil) {
        _formatProvider = (id<ORK1ScaleAnswerFormatProvider>)[self.step impliedAnswerFormat];
    }
    return _formatProvider;
}

- (void)prepareView {
    [super prepareView];
    
    id<ORK1ScaleAnswerFormatProvider> formatProvider = self.formatProvider;
    
    if (_sliderView == nil) {
        _sliderView = [[ORK1ScaleSliderView alloc] initWithFormatProvider:formatProvider delegate:self];
        
        [self addSubview:_sliderView];
        
        self.sliderView.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = @{ @"sliderView": _sliderView };
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[sliderView]|"
                                                                     options:NSLayoutFormatDirectionLeadingToTrailing
                                                                     metrics:nil
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[sliderView]|"
                                                                     options:NSLayoutFormatDirectionLeadingToTrailing
                                                                     metrics:nil
                                                                       views:views]];
        
        // Get a full width layout
        NSLayoutConstraint *widthConstraint = [self.class fullWidthLayoutConstraint:_sliderView];
        [self addConstraints:@[widthConstraint]];
    }
    
    [self answerDidChange];
}

- (void)answerDidChange {
    id<ORK1ScaleAnswerFormatProvider> formatProvider = self.formatProvider;
    id answer = self.answer;
    if (answer && answer != ORK1NullAnswerValue()) {
        [_sliderView setCurrentAnswerValue:answer];
    } else {
        if (answer == nil && [formatProvider defaultAnswer]) {
            [self.sliderView setCurrentAnswerValue:[formatProvider defaultAnswer]];
            [self ork_setAnswer:self.sliderView.currentAnswerValue];
        } else {
           [self.sliderView setCurrentAnswerValue:nil];
        }
    }
}

- (NSArray *)suggestedCellHeightConstraintsForView:(UIView *)view {
    return @[];
}

- (void)scaleSliderViewCurrentValueDidChange:(ORK1ScaleSliderView *)sliderView {
    [self ork_setAnswer:sliderView.currentAnswerValue];
}

@end
