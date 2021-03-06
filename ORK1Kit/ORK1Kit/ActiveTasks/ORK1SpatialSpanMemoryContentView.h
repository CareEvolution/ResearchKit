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


#import "ORK1CustomStepView_Internal.h"
#import "ORK1SpatialSpanTargetView.h"


NS_ASSUME_NONNULL_BEGIN

typedef struct {
    NSInteger width;
    NSInteger height;
} ORK1GridSize;

@class ORK1SpatialSpanMemoryGameView;

@protocol ORK1SpatialSpanMemoryGameViewDelegate<NSObject>

- (void)gameView:(ORK1SpatialSpanMemoryGameView *)gameView didTapTileWithIndex:(NSInteger)tileIndex recognizer:(UITapGestureRecognizer *)recognizer;

@end


@interface ORK1SpatialSpanMemoryGameView : UIView <ORK1SpatialSpanTargetViewDelegate>

@property (nonatomic, weak, nullable) id<ORK1SpatialSpanMemoryGameViewDelegate> delegate;

@property (nonatomic, assign) ORK1GridSize gridSize;

@property (nonatomic, readonly) NSInteger numberOfTiles;

@property (nonatomic, readonly, nullable) NSArray *tileViews;

@property (nonatomic, strong, nullable) UIImage *customTargetImage;

- (void)resetTilesAnimated:(BOOL)animated;

- (void)setState:(ORK1SpatialSpanTargetState)state forTileIndex:(NSInteger)tileIndex animated:(BOOL)animated;
- (ORK1SpatialSpanTargetState)stateForTileIndex:(NSInteger)tileIndex;

@end


@interface ORK1SpatialSpanMemoryContentView : ORK1ActiveStepCustomView

@property (nonatomic, strong, readonly) ORK1SpatialSpanMemoryGameView *gameView;

@property (nonatomic, assign, getter=isFooterHidden) BOOL footerHidden;

@property (nonatomic, strong, nullable) NSString *capitalizedPluralItemDescription;

// Things that can be shown in the footer.
@property (nonatomic, assign) NSInteger numberOfItems;
@property (nonatomic, assign) NSInteger score;
@property (nonatomic, strong, nullable) UIBarButtonItem *buttonItem;

@end

NS_ASSUME_NONNULL_END
