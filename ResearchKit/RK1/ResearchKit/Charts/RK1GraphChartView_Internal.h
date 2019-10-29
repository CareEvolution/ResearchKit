/*
 Copyright (c) 2015, James Cox. All rights reserved.
 Copyright (c) 2016, Ricardo Sánchez-Sáez. All rights reserved.

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


#import "RK1GraphChartView.h"
#import "RK1ChartTypes.h"
#import "RK1Helpers_Private.h"


NS_ASSUME_NONNULL_BEGIN

#if TARGET_INTERFACE_BUILDER

@interface RK1IBGraphChartViewDataSource : NSObject <RK1GraphChartViewDataSource>

@property (nonatomic, strong, nullable) NSArray <NSArray *> *plotPoints;

@end


@interface RK1IBValueRangeGraphChartViewDataSource : RK1IBGraphChartViewDataSource <RK1ValueRangeGraphChartViewDataSource>

@end

#endif


@class RK1XAxisView;

typedef NS_ENUM(NSUInteger, RK1GraphAnimationType) {
    ORkGraphAnimationTypeNone,
    RK1GraphAnimationTypeFade,
    RK1GraphAnimationTypeGrow,
    RK1GraphAnimationTypePop
};

extern const CGFloat RK1GraphChartViewLeftPadding;
extern const CGFloat RK1GraphChartViewPointAndLineWidth;
extern const CGFloat RK1GraphChartViewScrubberMoveAnimationDuration;
extern const CGFloat RK1GraphChartViewAxisTickLength;
extern const CGFloat RK1GraphChartViewYAxisTickPadding;

RK1_INLINE CGFloat scalePixelAdjustment() {
    return (1.0 / [UIScreen mainScreen].scale);
}

RK1_INLINE CAShapeLayer *graphLineLayer() {
    CAShapeLayer *lineLayer = [CAShapeLayer layer];
    lineLayer.fillColor = [UIColor clearColor].CGColor;
    lineLayer.lineJoin = kCALineJoinRound;
    lineLayer.lineCap = kCALineCapRound;
    lineLayer.opacity = 1.0;
    return lineLayer;
}

RK1_INLINE CGFloat xAxisPoint(NSInteger pointIndex, NSInteger numberOfXAxisPoints, CGFloat canvasWidth) {
    return floor((canvasWidth / MAX(1, numberOfXAxisPoints - 1)) * pointIndex);
}

RK1_INLINE CGFloat xOffsetForPlotIndex(NSInteger plotIndex, NSInteger numberOfPlots, CGFloat plotWidth) {
    CGFloat offset = 0;
    if (numberOfPlots % 2 == 0) {
        // Even
        offset = (plotIndex - numberOfPlots / 2 + 0.5) * plotWidth;
    } else {
        // Odd
        offset = (plotIndex - numberOfPlots / 2) * plotWidth;
    }
    return offset;
}


@interface RK1GraphChartView ()

@property (nonatomic) NSMutableArray<NSMutableArray<NSMutableArray<CAShapeLayer *> *> *> *lineLayers;

@property (nonatomic) NSInteger numberOfXAxisPoints;

@property (nonatomic) NSMutableArray<NSMutableArray<NSObject<RK1ValueCollectionType> *> *> *dataPoints; // Actual data

@property (nonatomic) NSMutableArray<NSMutableArray<NSObject<RK1ValueCollectionType> *> *> *yAxisPoints; // Normalized for the plot view height

@property (nonatomic) UIView *plotView; // Holds the plots

@property (nonatomic) UIView *scrubberLine;

@property (nonatomic) BOOL scrubberAccessoryViewsHidden;

@property (nonatomic) BOOL hasDataPoints;

@property (nonatomic) double minimumValue;

@property (nonatomic) double maximumValue;

- (void)sharedInit;

- (void)calculateMinAndMaxValues;

- (NSMutableArray<NSObject<RK1ValueCollectionType> *> *)normalizedCanvasDataPointsForPlotIndex:(NSInteger)plotIndex canvasHeight:(CGFloat)viewHeight;

- (NSInteger)numberOfPlots;

- (NSInteger)numberOfValidValuesForPlotIndex:(NSInteger)plotIndex;

- (NSInteger)scrubbingPlotIndex;

- (double)scrubbingValueForPlotIndex:(NSInteger)plotIndex pointIndex:(NSInteger)pointIndex;

- (double)scrubbingYAxisPointForPlotIndex:(NSInteger)plotIndex pointIndex:(NSInteger)pointIndex;

- (double)scrubbingLabelValueForCanvasXPosition:(CGFloat)xPosition plotIndex:(NSInteger)plotIndex;

- (NSInteger)pointIndexForXPosition:(CGFloat)xPosition plotIndex:(NSInteger)plotIndex;

- (void)updateScrubberViewForXPosition:(CGFloat)xPosition plotIndex:(NSInteger)plotIndex;

- (void)updateScrubberLineAccessories:(CGFloat)xPosition plotIndex:(NSInteger)plotIndex;

- (CGFloat)snappedXPosition:(CGFloat)xPosition plotIndex:(NSInteger)plotIndex;

- (BOOL)isXPositionSnapped:(CGFloat)xPosition plotIndex:(NSInteger)plotIndex;

- (void)updatePlotColors;

- (void)updateLineLayers;

- (void)layoutLineLayers;

- (UIColor *)colorForPlotIndex:(NSInteger)plotIndex subpointIndex:(NSInteger)subpointIndex totalSubpoints:(NSInteger)totalSubpoints;

- (UIColor *)colorForPlotIndex:(NSInteger)plotIndex;

- (void)prepareAnimationsForPlotIndex:(NSInteger)plotIndex;

- (void)animateLayersSequentiallyWithDuration:(NSTimeInterval)duration plotIndex:(NSInteger)plotIndex;

- (void)animateLayer:(CALayer *)layer
             keyPath:(NSString *)keyPath
            duration:(CGFloat)duration
          startDelay:(CGFloat)startDelay
      timingFunction:(CAMediaTimingFunction *)timingFunction;

@end


// Abstract base class for RK1DiscreteGraphChartView and RK1LineGraphChartView
@interface RK1ValueRangeGraphChartView ()

@property (nonatomic) NSMutableArray<NSMutableArray<RK1ValueRange *> *> *dataPoints; // Actual data

@property (nonatomic) NSMutableArray<NSMutableArray<RK1ValueRange *> *> *yAxisPoints; // Normalized for the plot view height

- (void)updatePointLayers;

- (void)layoutPointLayers;

@end

NS_ASSUME_NONNULL_END
