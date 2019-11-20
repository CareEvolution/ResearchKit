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

 
#import "ORK1DiscreteGraphChartView.h"

#import "ORK1ChartTypes.h"
#import "ORK1GraphChartView_Internal.h"

#import "ORK1Helpers_Internal.h"


#if TARGET_INTERFACE_BUILDER

@interface ORK1IBDiscreteGraphChartViewDataSource : ORK1IBValueRangeGraphChartViewDataSource

+ (instancetype)sharedInstance;

@end


@implementation ORK1IBDiscreteGraphChartViewDataSource

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self class] new];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.plotPoints = @[
                            @[
                                [[ORK1ValueRange alloc] initWithMinimumValue:0 maximumValue: 2],
                                [[ORK1ValueRange alloc] initWithMinimumValue:1 maximumValue: 4],
                                [[ORK1ValueRange alloc] initWithMinimumValue:2 maximumValue: 6],
                                [[ORK1ValueRange alloc] initWithMinimumValue:3 maximumValue: 8],
                                [[ORK1ValueRange alloc] initWithMinimumValue:5 maximumValue:10],
                                [[ORK1ValueRange alloc] initWithMinimumValue:8 maximumValue:13]
                              ],
                            @[
                                [[ORK1ValueRange alloc] initWithValue:1],
                                [[ORK1ValueRange alloc] initWithMinimumValue:2 maximumValue:6],
                                [[ORK1ValueRange alloc] initWithMinimumValue:3 maximumValue:10],
                                [[ORK1ValueRange alloc] initWithMinimumValue:5 maximumValue:11],
                                [[ORK1ValueRange alloc] initWithMinimumValue:7 maximumValue:13],
                                [[ORK1ValueRange alloc] initWithMinimumValue:10 maximumValue:13]
                              ]
                            ];
    }
    return self;
}

@end

#endif


@implementation ORK1DiscreteGraphChartView

#pragma mark - Init

- (void)sharedInit {
    [super sharedInit];
    _drawsConnectedRanges = YES;
}

- (void)setDrawsConnectedRanges:(BOOL)drawsConnectedRanges {
    _drawsConnectedRanges = drawsConnectedRanges;
    [super updateLineLayers];
    [super updatePointLayers];
    [super layoutLineLayers];
    [super layoutPointLayers];
}

#pragma mark - Draw

- (BOOL)shouldDrawLinesForPlotIndex:(NSInteger)plotIndex {
    return [self numberOfValidValuesForPlotIndex:plotIndex] > 0 && _drawsConnectedRanges;
}

- (void)updateLineLayersForPlotIndex:(NSInteger)plotIndex {
    NSUInteger pointCount = self.dataPoints[plotIndex].count;
    for (NSUInteger pointIndex = 0; pointIndex < pointCount; pointIndex++) {
        ORK1ValueRange *dataPointValue = self.dataPoints[plotIndex][pointIndex];
        if (!dataPointValue.isUnset && !dataPointValue.isEmptyRange) {
            CAShapeLayer *lineLayer = graphLineLayer();
            lineLayer.strokeColor = [self colorForPlotIndex:plotIndex].CGColor;
            lineLayer.lineWidth = ORK1GraphChartViewPointAndLineWidth;
            
            [self.plotView.layer addSublayer:lineLayer];
            [self.lineLayers[plotIndex] addObject:[NSMutableArray arrayWithObject:lineLayer]];
        }
    }
}

- (void)layoutLineLayersForPlotIndex:(NSInteger)plotIndex {
    NSUInteger lineLayerIndex = 0;
    CGFloat positionOnXAxis = ORK1CGFloatInvalidValue;
    ORK1ValueRange *positionOnYAxis = nil;
    NSUInteger pointCount = self.yAxisPoints[plotIndex].count;
    for (NSUInteger pointIndex = 0; pointIndex < pointCount; pointIndex++) {
        
        ORK1ValueRange *dataPointValue = self.dataPoints[plotIndex][pointIndex];
        
        if (!dataPointValue.isUnset && !dataPointValue.isEmptyRange) {
            
            UIBezierPath *linePath = [UIBezierPath bezierPath];
            
            positionOnXAxis = xAxisPoint(pointIndex, self.numberOfXAxisPoints, self.plotView.bounds.size.width);
            positionOnXAxis += [self xOffsetForPlotIndex:plotIndex];
            positionOnYAxis = self.yAxisPoints[plotIndex][pointIndex];
            
            [linePath moveToPoint:CGPointMake(positionOnXAxis, positionOnYAxis.minimumValue)];
            [linePath addLineToPoint:CGPointMake(positionOnXAxis, positionOnYAxis.maximumValue)];
            
            CAShapeLayer *lineLayer = self.lineLayers[plotIndex][lineLayerIndex][0];
            lineLayer.path = linePath.CGPath;
            lineLayerIndex++;
        }
    }
}

- (CGFloat)xOffsetForPlotIndex:(NSInteger)plotIndex {
    return xOffsetForPlotIndex(plotIndex, [self numberOfPlots], ORK1GraphChartViewPointAndLineWidth);
}
    
- (CGFloat)snappedXPosition:(CGFloat)xPosition plotIndex:(NSInteger)plotIndex {
    return [super snappedXPosition:xPosition plotIndex:plotIndex] + [self xOffsetForPlotIndex:plotIndex];
}
    
- (NSInteger)pointIndexForXPosition:(CGFloat)xPosition plotIndex:(NSInteger)plotIndex {
    return [super pointIndexForXPosition:xPosition - [self xOffsetForPlotIndex:plotIndex] plotIndex:plotIndex];
    }
    
- (BOOL)isXPositionSnapped:(CGFloat)xPosition plotIndex:(NSInteger)plotIndex {
    return [super isXPositionSnapped:xPosition - [self xOffsetForPlotIndex:plotIndex] plotIndex:plotIndex];
}

#pragma mark - Interface Builder designable

- (void)prepareForInterfaceBuilder {
    [super prepareForInterfaceBuilder];
#if TARGET_INTERFACE_BUILDER
    self.dataSource = [ORK1IBDiscreteGraphChartViewDataSource sharedInstance];
#endif
}

@end
