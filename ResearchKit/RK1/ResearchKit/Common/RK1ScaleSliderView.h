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

@class RK1ScaleRangeLabel;
@class RK1ScaleValueLabel;
@class RK1ScaleRangeDescriptionLabel;
@class RK1ScaleRangeImageView;
@class RK1ScaleSliderView;
@protocol RK1ScaleAnswerFormatProvider;

@protocol RK1ScaleSliderViewDelegate <NSObject>

- (void)scaleSliderViewCurrentValueDidChange:(RK1ScaleSliderView *)sliderView;

@end


@interface RK1ScaleSliderView : UIView

- (instancetype)initWithFormatProvider:(id<RK1ScaleAnswerFormatProvider>)formatProvider delegate:(id<RK1ScaleSliderViewDelegate>)delegate;

@property (nonatomic, weak, readonly) id<RK1ScaleSliderViewDelegate> delegate;

@property (nonatomic, strong, readonly) id<RK1ScaleAnswerFormatProvider> formatProvider;

@property (nonatomic, strong, readonly) RK1ScaleRangeLabel *leftRangeLabel;

@property (nonatomic, strong, readonly) RK1ScaleRangeLabel *rightRangeLabel;

@property (nonatomic, strong, readonly) RK1ScaleRangeImageView *leftRangeImageView;

@property (nonatomic, strong, readonly) RK1ScaleRangeImageView *rightRangeImageView;

@property (nonatomic, strong, readonly) RK1ScaleRangeDescriptionLabel *leftRangeDescriptionLabel;

@property (nonatomic, strong, readonly) RK1ScaleRangeDescriptionLabel *rightRangeDescriptionLabel;

@property (nonatomic, strong, readonly) RK1ScaleValueLabel *valueLabel;

// Accepts NSNumber for continous scale or discrete scale.
// Accepts NSArray<id<NSCopying, NSCoding, NSObject>> for text scale.
@property (nonatomic, strong, nullable) id currentAnswerValue;

@end

NS_ASSUME_NONNULL_END
