/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 Copyright (c) 2015, James Cox.
 Copyright (c) 2015, Ricardo Sánchez-Sáez.
 Copyright (c) 2017, Macro Yau.

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
#import "ORK1Defines.h"


NS_ASSUME_NONNULL_BEGIN

@class ORK1ValueRange;
@class ORK1ValueStack;
@class ORK1GraphChartView;

/**
 The graph chart view delegate protocol forwards pan gesture events occuring
 within the bounds of an `ORK1GraphChartView` object.
*/
ORK1_AVAILABLE_DECL
@protocol ORK1GraphChartViewDelegate <NSObject>

@optional
/**
 Notifies the delegate that a pan gesture has begun within the bounds of an `ORK1GraphChartView`
 object.

 @param graphChartView      The graph chart view in which the gesture occurred.
*/
- (void)graphChartViewTouchesBegan:(ORK1GraphChartView *)graphChartView;

/**
 Notifies the delegate of updates in the x-coordinate of an ongoing pan gesture within the bounds
 of an `ORK1GraphChartView` object.

 @param graphChartView      The graph chart view object in which the gesture occurred.
 @param xPosition           The updated x-coordinate of the ongoing pan gesture.
*/
- (void)graphChartView:(ORK1GraphChartView *)graphChartView touchesMovedToXPosition:(CGFloat)xPosition;

/**
 Notifies the delegate that a pan gesture that began within the bounds of an `ORK1GraphChartView`
 object has ended.

@param graphChartView       The graph chart view object in which the gesture occurred.
*/
- (void)graphChartViewTouchesEnded:(ORK1GraphChartView *)graphChartView;

@end


/**
 The abstract `ORK1GraphChartViewDataSource` protocol is the base protocol which conforms the basis
 for the `ORK1ValueRangeGraphChartViewDataSource` and `ORK1ValueStackGraphChartViewDataSource`
 protocols, required to populate the concrete `ORK1GraphChartView` subclass.

 At a minimum, a data source object must implement the `graphChartView:numberOfPointsInPlot:` and
 `graphChartView:plot:valueForPointAtIndex:` methods. These methods return
 the number of points in a plot and the points themselves. Each point in a plot is represented by
 an object of the `ORK1ValueRange` or `ORK1ValueStack` class, depending on the concrete subprotocol.
 
 A data source object may provide additional information to the graph chart view by implementing the
 optional methods.

 When configuring an `ORK1GraphChartView` object, assign your data source to its `dataSource`
 property.
*/
@protocol ORK1GraphChartViewDataSource <NSObject>

@required
/**
 Asks the data source for the number of value points to be plotted by the graph chart view at the
 specified plot index.

 @param graphChartView      The graph chart view asking for the number of value points.
 @param plotIndex           An index number identifying the plot in the graph chart view. This index
                                is 0 in a single-plot graph chart view.

 @return The number of range points in the plot at `plotIndex`.
*/
- (NSInteger)graphChartView:(ORK1GraphChartView *)graphChartView numberOfDataPointsForPlotIndex:(NSInteger)plotIndex;


/**
 Asks the data source for the number of plots to be plotted by the graph chart view.

 @param graphChartView      The graph chart view asking for the number of plots.

 @return The number of plots in the graph chart view.
*/
- (NSInteger)numberOfPlotsInGraphChartView:(ORK1GraphChartView *)graphChartView;

@optional
/**
 Asks the data source for the color of the specified plot.
 
 If this method is not implemented, the first plot uses the graph chart view `tintColor`, and
 all subsequent plots uses the current `referenceLineColor`.
 
 @param graphChartView      The graph chart view asking for the color of the segment.
 @param plotIndex           An index number identifying the plot in the graph chart view. This index
                                is always 0 in single-plot graph chart views.
 
 @return The color of the segment at the specified index in a pie chart view.
 */
- (UIColor *)graphChartView:(ORK1GraphChartView *)graphChartView colorForPlotIndex:(NSInteger)plotIndex;

/**
 Asks the data source for the fill color of the specified plot.
 
 The fill color is only used by `ORK1LineGraphChartView`. If this method is not implemented, the
 chart uses the main color of the specified plot with a 0.4 opacity value.
 
 @param graphChartView      The graph chart view asking for the color of the segment.
 @param plotIndex           An index number identifying the plot in the graph chart view. This index
 is always 0 in single-plot graph chart views.
 
 @return The color of the fill layer at the specified index in a line chart view.
 */
- (UIColor *)graphChartView:(ORK1GraphChartView *)graphChartView fillColorForPlotIndex:(NSInteger)plotIndex;

/**
 Asks the data source which plot the scrubber should snap to in multigraph chart views.
 
 If this method is not implemented, the scrubber snaps over the first plot.
 
 @param graphChartView      The graph chart view asking for the scrubbing plot index.
 
 @return The index of the plot that the scrubber should snap to.
 */
- (NSInteger)scrubbingPlotIndexForGraphChartView:(ORK1GraphChartView *)graphChartView;

/**
 Asks the data source for the upper limit of the y-axis drawn by the graph chart view.

 If this method is not implemented, the greatest `maximumValue` of all `ORK1ValueRange` instances
 returned in `graphChartView:plot:valueForPointAtIndex:` is used.

 See also: `graphChartView:plot:valueForPointAtIndex:`.

 @param graphChartView      The graph chart view asking for the maximum value.

 @return The maximum value of the y-axis drawn by `graphChartView`.
*/
- (double)maximumValueForGraphChartView:(ORK1GraphChartView *)graphChartView;

/**
 Asks the data source for the lower limit of the y-axis drawn by the graph chart view.

 If this method is not implemented, the smallest `minimumValue` of all ORK1ValueRange instances
 returned in `graphChartView:plot:valueForPointAtIndex:` is used.

 See also: `graphChartView:plot:valueForPointAtIndex:`.

 @param graphChartView      The graph chart view asking for the minimum value.

 @return The minimum value of the y-axis drawn by `graphChartView`.
*/
- (double)minimumValueForGraphChartView:(ORK1GraphChartView *)graphChartView;

/**
 Asks the data source for the number of divisions in the x-axis. The value is ignored if it is lower
 than the number of data points. A title appearing adjacent to each
 division may optionally be returned by the `graphChartView:titleForXAxisAtPointIndex:` method.

 @param graphChartView      The graph chart view asking for the number of divisions in its x-axis.

 @return The number of divisions in the x-axis for `graphChartView`.
*/
- (NSInteger)numberOfDivisionsInXAxisForGraphChartView:(ORK1GraphChartView *)graphChartView;

/**
 Asks the data source for the title to be displayed adjacent to each division in the x-axis (the
 number returned by `numberOfDivisionsInXAxisForGraphChartView:`). You can return `nil` from this
 method if you don't want to display a title for the specified point index.

 If this method is not implemented, the x-axis has no titles.

 See also: `numberOfDivisionsInXAxisForGraphChartView:`.

 @param graphChartView  The graph chart view asking for the title.
 @param pointIndex      The index of the specified x-axis division.

 @return The title string to be displayed adjacent to each division of the x-axis of the graph chart
 view.
*/
- (nullable NSString *)graphChartView:(ORK1GraphChartView *)graphChartView titleForXAxisAtPointIndex:(NSInteger)pointIndex;

/**
 Asks the data source if the vertical reference line at the specified point index should be drawn..
 
 If this method is not implemented, the graph chart view will draw all vertical reference lines.
 
 @param graphChartView  The graph view asking for the tile.
 @param pointIndex      The index corresponding to the number returned by
                            `numberOfDivisionsInXAxisForGraphChartView:`.
 
 @return Whether the graph chart view should draw the vertical reference line.
 */
- (BOOL)graphChartView:(ORK1GraphChartView *)graphChartView drawsVerticalReferenceLineAtPointIndex:(NSInteger)pointIndex;


/**
 Asks the data source if the plot at specified index should display circular indicators on its data points.
 
 This only applys to `ORK1LineGrapthChartView`.
 If this method is not implemented, point indicators will be drawn for all plots.
 
 @param graphChartView  The graph view asking whether point indicators should be drawn.
 @param plotIndex       An index number identifying the plot in the graph chart view. This index
 is always 0 in single-plot graph chart views.
 
 @return Whether the graph chart view should draw point indicators for its points.
 */
- (BOOL)graphChartView:(ORK1GraphChartView *)graphChartView drawsPointIndicatorsForPlotIndex:(NSInteger)plotIndex;


/**
 Asks the data source for the unit label for the given plot index so VoiceOver's description of the graph can be read with units.
 
 If this method is not implemented, VoiceOver will speak the graph value without units.
 
 @param graphChartView  The graph view asking for its unit label
 @param plotIndex       An index number identifying the plot in the graph chart view. This index
 is always 0 in single-plot graph chart views.
 
 @return An appropriate unit label for the given plot.
 */
- (NSString *)graphChartView:(ORK1GraphChartView *)graphChartView accessibilityUnitLabelForPlotIndex:(NSInteger)plotIndex;


/**
 Asks the data source for the accessibilityLabel at a given point on the x-axis
 
 This is used in cases where the UI may be displaying a shortened form (e.g. M, T, W, etc. for days of the week), but VoiceOver should be speaking the longer form. If this method isn't implemented, VoiceOver will speak the label displayed in the UI for the given index.
 
 @param graphChartView  The graph view asking for its unit label
 @param pointIndex      The index corresponding to the number returned by `numberOfDivisionsInXAxisForGraphChartView:`.
 
 @return An appropriate accessibility label for the given index of the graph.
 */
- (NSString *)graphChartView:(ORK1GraphChartView *)graphChartView accessibilityLabelForXAxisAtPointIndex:(NSInteger)pointIndex;

@end


/**
 An object that adopts the `ORK1ValueRangeGraphChartViewDataSource` protocol is responsible for
 providing data in the form of `ORK1ValueRange` values required to populate an
 `ORK1ValueRangeGraphChartView` concrete subclass, such as `ORK1LineGraphChartView` and
 `ORK1DiscreteGraphChartView`.
 */
ORK1_AVAILABLE_DECL
@protocol ORK1ValueRangeGraphChartViewDataSource <ORK1GraphChartViewDataSource>

@required

/**
 Asks the data source for the value range to be plotted at the specified point index for the
 specified plot.
 
 @param graphChartView      The graph chart view that is asking for the value range.
 @param pointIndex          An index number identifying the value range in the graph chart view.
 @param plotIndex           An index number identifying the plot in the graph chart view. This index
                                is 0 in a single-plot graph chart view.
 
 @return The value range specified by `pointIndex` in the plot specified by `plotIndex` for the
 specified graph chart view`.
 */
- (ORK1ValueRange *)graphChartView:(ORK1GraphChartView *)graphChartView dataPointForPointIndex:(NSInteger)pointIndex plotIndex:(NSInteger)plotIndex;

@end


/**
 An object that adopts the `ORK1ValueStackGraphChartViewDataSource` protocol is responsible for
 providing data in the form of `ORK1ValueStack` values required to populate an `ORK1BarGraphChartView`
 object.
 */
ORK1_AVAILABLE_DECL
@protocol ORK1ValueStackGraphChartViewDataSource <ORK1GraphChartViewDataSource>

@required

/**
 Asks the data source for the value stack to be plotted at the specified point index for the
 specified plot.
 
 @param graphChartView      The graph chart view that is asking for the value stack.
 @param pointIndex          An index number identifying the value stack in the graph chart view.
 @param plotIndex           An index number identifying the plot in the graph chart view. This index
 is 0 in a single-plot graph chart view.
 
 @return The value stack specified by `pointIndex` in the plot specified by `plotIndex` for the
 specified graph chart view`.
 */
- (ORK1ValueStack *)graphChartView:(ORK1GraphChartView *)graphChartView dataPointForPointIndex:(NSInteger)pointIndex plotIndex:(NSInteger)plotIndex;

@end


/**
 The `ORK1GraphChartView` class is an abstract class which holds properties and methods common to
 concrete subclasseses.
 
 You should not instantiate this class directly; use one of the subclasses instead. The concrete
 subclasses are `ORK1LineGraphChartView`, `ORK1DiscreteGraphChartView`, and `ORK1BarGraphChartView`.
*/
ORK1_CLASS_AVAILABLE
IB_DESIGNABLE
@interface ORK1GraphChartView : UIView

/**
 The minimum value of the y-axis.

 You can provide this value to an instance of `ORK1GraphChartView` by implementing the optional
 `minimumValueForGraphChartView:` method of the `ORK1GraphChartViewDataSource` protocol.

 If `minimumValueForGraphChartView:` is not implemented, the minimum value is assigned to the
 smallest value of the `minimumValue` property of all `ORK1ValueRange` instances returned by the
 graph chart view data source.
*/
@property (nonatomic, readonly) double minimumValue;

/**
 The maximum value of the y-axis.

 You can provide this value instance of `ORK1GraphChartView` by implementing the
 optional `maximumValueForGraphChartView:` method of the `ORK1GraphChartViewDataSource` protocol.

 If `maximumValueForGraphChartView:` is not implemented, the maximum value is assigned to the
 largest value of the `maximumValue` property of all `ORK1ValueRange` instances returned by the
 graph chart view data source.
*/
@property (nonatomic, readonly) double maximumValue;

/**
 A Boolean value indicating whether the graph chart view should draw horizontal reference lines.

 The default value of this property is NO.
 */
@property (nonatomic) IBInspectable BOOL showsHorizontalReferenceLines;

/**
 A Boolean value indicating whether the graph chart view should draw vertical reference lines.

 The default value of this property is NO.
*/
@property (nonatomic) IBInspectable BOOL showsVerticalReferenceLines;

/**
 The delegate is notified of pan gesture events occuring within the bounds of the graph chart
 view.

 See the `ORK1GraphChartViewDelegate` protocol.
*/
@property (nonatomic, weak, nullable) id <ORK1GraphChartViewDelegate> delegate;

/**
 The data source responsible for providing the data required to populate the graph chart view.

 See the `ORK1GraphChartViewDataSource` protocol.
*/
@property (nonatomic, weak) id <ORK1GraphChartViewDataSource> dataSource;

/**
 The color of the axes drawn by the graph chart view.
 
 The default value for this property is a light gray color. Setting this property to `nil`
 resets it to its default value.
*/
@property (nonatomic, strong, null_resettable) IBInspectable UIColor *axisColor;

/**
 The color of the vertical axis titles.
 
 The default value for this property is a light gray color. Setting this property to `nil` resets it
 to its default value.

 @note The horizontal axis titles use the current `tintColor`.
*/
@property (nonatomic, strong, null_resettable) IBInspectable UIColor *verticalAxisTitleColor;

/**
 The color of the reference lines.
 
 The default value for this property is a light gray color. Setting this property to `nil` resets it
 to its default value.
*/
@property (nonatomic, strong, null_resettable) IBInspectable UIColor *referenceLineColor;

/**
 The background color of the thumb on the scrubber line.
 
 The default value for this property is a white color. Setting this property to `nil` resets it to
 its default value.
*/
@property (nonatomic, strong, null_resettable) IBInspectable UIColor *scrubberThumbColor;

/**
 The color of the scrubber line.
 
 The default value for this property is a gray color. Setting this property to `nil` resets it to
 its default value.
*/
@property (nonatomic, strong, null_resettable) IBInspectable UIColor *scrubberLineColor;

/**
 The string that is displayed if no data points are provided by the data source.
 
 The default value for this property is an appropriate message string. Setting this property to
 `nil` resets it to its default value.
*/
@property (nonatomic, copy, null_resettable) IBInspectable NSString *noDataText;

/**
 An image to be optionally displayed in place of the maximum value label on the y-axis.
 
 The default value for this property is `nil`.
*/
@property (nonatomic, strong, nullable) IBInspectable UIImage *maximumValueImage;

/**
 An image to be optionally displayed in place of the minimum value label on the y-axis.
 
 The default value for this property is `nil`.
*/
@property (nonatomic, strong, nullable) IBInspectable UIImage *minimumValueImage;

/**
 The long press gesture recognizer that is used for scrubbing by the graph chart view. You can use
 this property to prioritize your own gesture recognizers.
 
 This object is instatiated and added to the view when it is created.
 */
@property (nonatomic, strong, readonly) UILongPressGestureRecognizer *longPressGestureRecognizer;

/**
 The gesture recognizer that is used for scrubbing by the graph chart view.
 
 This object is instatiated and added to the view when it is created.
 */
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *panGestureRecognizer;

/**
 The number of decimal places that is used on the y-axis and scrubber value labels.
 
 The default value of this property is 0.
 */
@property (nonatomic) NSUInteger decimalPlaces;

/**
 Animates the graph when it first displays on the screen.
 
 You can optionally call this method from the `viewWillAppear:` implementation of the view
 controller that owns the graph chart view.
 
 @param animationDuration       The duration of the appearing animation.
 */
- (void)animateWithDuration:(NSTimeInterval)animationDuration;

/**
 Reloads the plotted data.
 
 Call this method to reload the data and re-plot the graph. You should call it if the data provided by the dataSource changes.
*/
- (void)reloadData;

@end


/**
 The `ORK1ValueRangeGraphChartView` class is an abstract class which holds a data source comforming
 to the `ORK1ValueRangeGraphChartViewDataSource` protocol, common to concrete subclasseses.
 
 You should not instantiate this class directly; use one of the subclasses instead. The concrete
 subclasses are `ORK1LineGraphChartView` and `ORK1DiscreteGraphChartView`.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1ValueRangeGraphChartView : ORK1GraphChartView

/**
 The data source responsible for providing the data required to populate the graph chart view.
 
 See the `ORK1ValueRangeGraphChartViewDataSource` protocol.
 */
@property (nonatomic, weak) id <ORK1ValueRangeGraphChartViewDataSource> dataSource;

@end

NS_ASSUME_NONNULL_END
