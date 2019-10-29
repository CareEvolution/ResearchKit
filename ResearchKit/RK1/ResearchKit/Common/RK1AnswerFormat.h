/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 Copyright (c) 2015, Bruce Duncan.
 Copyright (c) 2016, Ricardo Sánchez-Sáez.
 Copyright (c) 2017, Macro Yau.
 Copyright (c) 2017, Sage Bionetworks.
 
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
#import <ResearchKit/RK1Types.h>


NS_ASSUME_NONNULL_BEGIN

@class RK1ScaleAnswerFormat;
@class RK1ContinuousScaleAnswerFormat;
@class RK1TextScaleAnswerFormat;
@class RK1ValuePickerAnswerFormat;
@class RK1MultipleValuePickerAnswerFormat;
@class RK1ImageChoiceAnswerFormat;
@class RK1TextChoiceAnswerFormat;
@class RK1BooleanAnswerFormat;
@class RK1NumericAnswerFormat;
@class RK1TimeOfDayAnswerFormat;
@class RK1DateAnswerFormat;
@class RK1TextAnswerFormat;
@class RK1EmailAnswerFormat;
@class RK1TimeIntervalAnswerFormat;
@class RK1HeightAnswerFormat;
@class RK1WeightAnswerFormat;
@class RK1LocationAnswerFormat;

@class RK1TextChoice;
@class RK1ImageChoice;

/**
 The `RK1AnswerFormat` class is the abstract base class for classes that describe the
 format in which a survey question or form item should be answered. The ResearchKit framework uses
 `RK1QuestionStep` and `RK1FormItem` to represent questions to ask the user. Each
 question must have an associated answer format.
 
 To use an answer format, instantiate the appropriate answer format subclass and
 attach it to a question step or form item. Incorporate the resulting step
 into a task, and present the task with a task view controller.
 
 An answer format is validated when its owning step is validated.
 
 Some answer formats are constructed of other answer formats. When this is the
 case, the answer format can override the method `impliedAnswerFormat` to return
 the answer format that is implied. For example, a Boolean answer format
 is presented in the same way as a single-choice answer format with the
 choices Yes and No mapping to `@(YES)` and `@(NO)`, respectively.
 */
RK1_CLASS_AVAILABLE
@interface RK1AnswerFormat : NSObject <NSSecureCoding, NSCopying>

/// @name Properties

/**
 The type of question. (read-only)
 
 You can use this enumerated value in your Objective-C code to switch on
 a rough approximation of the type of question that is being asked.
 
 Note that answer format subclasses override the getter to return the appropriate question
 type.
 */
@property (readonly) RK1QuestionType questionType;

/// @name Factory methods

+ (RK1ScaleAnswerFormat *)scaleAnswerFormatWithMaximumValue:(NSInteger)scaleMaximum
                                               minimumValue:(NSInteger)scaleMinimum
                                               defaultValue:(NSInteger)defaultValue
                                                       step:(NSInteger)step
                                                   vertical:(BOOL)vertical
                                    maximumValueDescription:(nullable NSString *)maximumValueDescription
                                    minimumValueDescription:(nullable NSString *)minimumValueDescription;

+ (RK1ContinuousScaleAnswerFormat *)continuousScaleAnswerFormatWithMaximumValue:(double)scaleMaximum
                                                                   minimumValue:(double)scaleMinimum
                                                                   defaultValue:(double)defaultValue
                                                          maximumFractionDigits:(NSInteger)maximumFractionDigits
                                                                       vertical:(BOOL)vertical
                                                        maximumValueDescription:(nullable NSString *)maximumValueDescription
                                                        minimumValueDescription:(nullable NSString *)minimumValueDescription;

+ (RK1TextScaleAnswerFormat *)textScaleAnswerFormatWithTextChoices:(NSArray <RK1TextChoice *> *)textChoices
                                                      defaultIndex:(NSInteger)defaultIndex
                                                          vertical:(BOOL)vertical;

+ (RK1BooleanAnswerFormat *)booleanAnswerFormat;

+ (RK1BooleanAnswerFormat *)booleanAnswerFormatWithYesString:(NSString *)yes
                                                    noString:(NSString *)no;

+ (RK1ValuePickerAnswerFormat *)valuePickerAnswerFormatWithTextChoices:(NSArray<RK1TextChoice *> *)textChoices;

+ (RK1MultipleValuePickerAnswerFormat *)multipleValuePickerAnswerFormatWithValuePickers:(NSArray<RK1ValuePickerAnswerFormat *> *)valuePickers;

+ (RK1ImageChoiceAnswerFormat *)choiceAnswerFormatWithImageChoices:(NSArray<RK1ImageChoice *> *)imageChoices;

+ (RK1TextChoiceAnswerFormat *)choiceAnswerFormatWithStyle:(RK1ChoiceAnswerStyle)style
                                               textChoices:(NSArray<RK1TextChoice *> *)textChoices;

+ (RK1NumericAnswerFormat *)decimalAnswerFormatWithUnit:(nullable NSString *)unit;
+ (RK1NumericAnswerFormat *)integerAnswerFormatWithUnit:(nullable NSString *)unit;

+ (RK1TimeOfDayAnswerFormat *)timeOfDayAnswerFormat;
+ (RK1TimeOfDayAnswerFormat *)timeOfDayAnswerFormatWithDefaultComponents:(nullable NSDateComponents *)defaultComponents;

+ (RK1DateAnswerFormat *)dateTimeAnswerFormat;
+ (RK1DateAnswerFormat *)dateTimeAnswerFormatWithDefaultDate:(nullable NSDate *)defaultDate
                                                 minimumDate:(nullable NSDate *)minimumDate
                                                 maximumDate:(nullable NSDate *)maximumDate
                                                    calendar:(nullable NSCalendar *)calendar;

+ (RK1DateAnswerFormat *)dateAnswerFormat;
+ (RK1DateAnswerFormat *)dateAnswerFormatWithDefaultDate:(nullable NSDate *)defaultDate
                                             minimumDate:(nullable NSDate *)minimumDate
                                             maximumDate:(nullable NSDate *)maximumDate
                                                calendar:(nullable NSCalendar *)calendar;

+ (RK1TextAnswerFormat *)textAnswerFormat;

+ (RK1TextAnswerFormat *)textAnswerFormatWithMaximumLength:(NSInteger)maximumLength;

+ (RK1TextAnswerFormat *)textAnswerFormatWithValidationRegularExpression:(NSRegularExpression *)validationRegularExpression
                                                          invalidMessage:(NSString *)invalidMessage;

+ (RK1EmailAnswerFormat *)emailAnswerFormat;

+ (RK1TimeIntervalAnswerFormat *)timeIntervalAnswerFormat;

+ (RK1TimeIntervalAnswerFormat *)timeIntervalAnswerFormatWithDefaultInterval:(NSTimeInterval)defaultInterval
                                                                        step:(NSInteger)step;

+ (RK1HeightAnswerFormat *)heightAnswerFormat;

+ (RK1HeightAnswerFormat *)heightAnswerFormatWithMeasurementSystem:(RK1MeasurementSystem)measurementSystem;

+ (RK1WeightAnswerFormat *)weightAnswerFormat;

+ (RK1WeightAnswerFormat *)weightAnswerFormatWithMeasurementSystem:(RK1MeasurementSystem)measurementSystem;

+ (RK1WeightAnswerFormat *)weightAnswerFormatWithMeasurementSystem:(RK1MeasurementSystem)measurementSystem
                                                  numericPrecision:(RK1NumericPrecision)numericPrecision;

+ (RK1WeightAnswerFormat *)weightAnswerFormatWithMeasurementSystem:(RK1MeasurementSystem)measurementSystem
                                                  numericPrecision:(RK1NumericPrecision)numericPrecision
                                                      minimumValue:(double)minimumValue
                                                      maximumValue:(double)maximumValue
                                                      defaultValue:(double)defaultValue;

+ (RK1LocationAnswerFormat *)locationAnswerFormat;

/// @name Validation

/**
 Validates the parameters of the answer format to ensure that they can be displayed.
 
 Typically, this method is called by the validation methods of the owning objects, which are
 themselves called when a step view controller that contains this answer format is
 about to be displayed.
 */
- (void)validateParameters;

/**
 Some answer formats are constructed of other answer formats. This method allows
 a subclass to return a different answer format for use in defining the UI/UX for
 the answer format type. For example, a Boolean answer format is presented in the 
 same way as a single-choice answer format with the choices Yes and No mapping to 
 `@(YES)` and `@(NO)`, respectively, so its `impliedAnswerFormat` is an 
 `RK1TextChoiceAnswerFormat` with those options.
 */
- (RK1AnswerFormat *)impliedAnswerFormat;

@end


/**
 The `RK1ScaleAnswerFormat `class represents an answer format that includes a slider control.
 
 The scale answer format produces an `RK1ScaleQuestionResult` object that contains an integer whose
 value is between the scale's minimum and maximum values, and represents one of the quantized step
 values.

 The following are the rules bound with scale answer format -
 
 * Minimum number of step in a task should not be less than 1.
 * Minimum number of section on a scale (step count) should not be less than 1.
 * Maximum number of section on a scale (step count) should not be more than 13.
 * The lower bound value in scale answer format cannot be lower than - 10000.
 * The upper bound value in scale answer format cannot be more than 10000.

 */
RK1_CLASS_AVAILABLE
@interface RK1ScaleAnswerFormat : RK1AnswerFormat

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 Returns an initialized scale answer format using the specified values.
 
 This method is the designated initializer.
 
 @param maximumValue                The upper bound of the scale.
 @param minimumValue                The lower bound of the scale.
 @param defaultValue                The default value of the scale. If this value is out of range,
                                        the slider is displayed without a default value.
 @param step                        The size of each discrete offset on the scale.
 @param vertical                    Pass `YES` to use a vertical scale; for the default horizontal
                                        scale, pass `NO`.
 @param maximumValueDescription     A localized label to describe the maximum value of the scale.
                                        For none, pass `nil`.
 @param minimumValueDescription     A localized label to describe the minimum value of the scale.
                                        For none, pass `nil`.
 
 @return An initialized scale answer format.
 */
- (instancetype)initWithMaximumValue:(NSInteger)maximumValue
                        minimumValue:(NSInteger)minimumValue
                        defaultValue:(NSInteger)defaultValue
                                step:(NSInteger)step
                            vertical:(BOOL)vertical
             maximumValueDescription:(nullable NSString *)maximumValueDescription
             minimumValueDescription:(nullable NSString *)minimumValueDescription NS_DESIGNATED_INITIALIZER;


/**
 Returns an initialized scale answer format using the specified values.
 
 This method is a convenience initializer.
 
 @param maximumValue    The upper bound of the scale.
 @param minimumValue    The lower bound of the scale.
 @param defaultValue    The default value of the scale. If this value is out of range, the slider is
                            displayed without a default value.
 @param step            The size of each discrete offset on the scale.
 @param vertical        Pass `YES` to use a vertical scale; for the default horizontal scale,
                            pass `NO`.
 
 @return An initialized scale answer format.
 */
- (instancetype)initWithMaximumValue:(NSInteger)maximumValue
                        minimumValue:(NSInteger)minimumValue
                        defaultValue:(NSInteger)defaultValue
                                step:(NSInteger)step
                            vertical:(BOOL)vertical;

/**
 Returns an initialized horizontal scale answer format using the specified values.
 
 This method is a convenience initializer.

 @param maximumValue    The upper bound of the scale.
 @param minimumValue    The lower bound of the scale.
 @param defaultValue    The default value of the scale. If this value is out of range, the slider is
                            displayed without a default value.
 @param step            The size of each discrete offset on the scale.
 
 @return An initialized scale answer format.
 */
- (instancetype)initWithMaximumValue:(NSInteger)maximumValue
                        minimumValue:(NSInteger)minimumValue
                        defaultValue:(NSInteger)defaultValue
                                step:(NSInteger)step;

/**
 The upper bound of the scale. (read-only)
 */
@property (readonly) NSInteger maximum;

/**
 The lower bound of the scale. (read-only)
 */
@property (readonly) NSInteger minimum;

/**
 The size of each discrete offset on the scale. (read-only)
 
 The value of this property should be greater than zero.
 The difference between `maximumValue` and `minimumValue` should be divisible
 by the step value.
 */
@property (readonly) NSInteger step;

/**
 The default value for the slider. (read-only)
 
 If the value of this property is less than `minimum` or greater than `maximum`, the slider has no
 default. Otherwise, the value is rounded to the nearest valid `step` value.
 */
@property (readonly) NSInteger defaultValue;

/**
 A Boolean value indicating whether the scale is oriented vertically. (read-only)
 */
@property (readonly, getter=isVertical) BOOL vertical;

/**
 Number formatter applied to the minimum, maximum, and slider values. Can be overridden by
 subclasses.
 */
@property (readonly) NSNumberFormatter *numberFormatter;

/**
 A localized label to describe the maximum value of the scale. (read-only)
 */
@property (readonly, nullable) NSString *maximumValueDescription;

/**
 A localized label to describe the minimum value of the scale. (read-only)
 */
@property (readonly, nullable) NSString *minimumValueDescription;

/**
 An image for the upper bound of the slider. The recommended image size is 30 x 30 points.
 The maximum range label will not be visible.
 */
@property (strong, nullable) UIImage *maximumImage;

/**
 An image for the lower bound of the slider. The recommended image size is 30 x 30 points.
 The minimum range label will not be visible.
 */
@property (strong, nullable) UIImage *minimumImage;

/**
 The colors to use when drawing a color gradient above the slider. Colors are drawn such that
 lower indexes correspond to the minimum side of the scale, while colors at higher indexes in
 the array corresond to the maximum side of the scale. 
 
 Setting this value to nil results in no gradient being drawn. Defaults to nil.
 
 An example usage would set an array of red and green to visually indicate a scale from bad to good.
 */
@property (copy, nullable) NSArray<UIColor *> *gradientColors;

/**
 Indicates the position of gradient stops for the colors specified in `gradientColors`.
 Gradient stops are specified as values between 0 and 1. The values must be monotonically
 increasing. 
 
 If nil, the stops are spread uniformly across the range. Defaults to nil.
 */
@property (copy, nullable) NSArray<NSNumber *> *gradientLocations;

@end


/**
 The `RK1ContinuousScaleAnswerFormat` class represents an answer format that lets participants
 select a value on a continuous scale.
 
 The continuous scale answer format produces an `RK1ScaleQuestionResult` object that has a
 real-number value.
 */
RK1_CLASS_AVAILABLE
@interface RK1ContinuousScaleAnswerFormat : RK1AnswerFormat

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 Returns an initialized continuous scale answer format using the specified values.
 
 This method is the designated initializer.
 
 @param maximumValue                The upper bound of the scale.
 @param minimumValue                The lower bound of the scale.
 @param defaultValue                The default value of the scale. If this value is out of range,
                                        the slider is displayed without a default value.
 @param maximumFractionDigits       The maximum number of fractional digits to display.
 @param vertical                    Pass `YES` to use a vertical scale; for the default horizontal
                                        scale, pass `NO`.
 @param maximumValueDescription     A localized label to describe the maximum value of the scale.
                                        For none, pass `nil`.
 @param minimumValueDescription     A localized label to describe the minimum value of the scale.
                                        For none, pass `nil`.
 
 @return An initialized scale answer format.
 */
- (instancetype)initWithMaximumValue:(double)maximumValue
                        minimumValue:(double)minimumValue
                        defaultValue:(double)defaultValue
               maximumFractionDigits:(NSInteger)maximumFractionDigits
                            vertical:(BOOL)vertical
             maximumValueDescription:(nullable NSString *)maximumValueDescription
             minimumValueDescription:(nullable NSString *)minimumValueDescription NS_DESIGNATED_INITIALIZER;

/**
 Returns an initialized continuous scale answer format using the specified values.
 
 @param maximumValue            The upper bound of the scale.
 @param minimumValue            The lower bound of the scale.
 @param defaultValue            The default value of the scale. If this value is out of range, the
                                    slider is displayed without a default value.
 @param maximumFractionDigits   The maximum number of fractional digits to display.
 @param vertical                Pass `YES` to use a vertical scale; for the default horizontal scale,
                                    pass `NO`.
 
 @return An initialized scale answer format.
 */
- (instancetype)initWithMaximumValue:(double)maximumValue
                        minimumValue:(double)minimumValue
                        defaultValue:(double)defaultValue
               maximumFractionDigits:(NSInteger)maximumFractionDigits
                            vertical:(BOOL)vertical;

/**
 Returns an initialized horizontal continous scale answer format using the specified values.
 
 This method is a convenience initializer.
 
 @param maximumValue            The upper bound of the scale.
 @param minimumValue            The lower bound of the scale.
 @param defaultValue            The default value of the scale. If this value is out of range, the
                                    slider is displayed without a default value.
 @param maximumFractionDigits   The maximum number of fractional digits to display.
 
 @return An initialized scale answer format.
 */
- (instancetype)initWithMaximumValue:(double)maximumValue
                        minimumValue:(double)minimumValue
                        defaultValue:(double)defaultValue
               maximumFractionDigits:(NSInteger)maximumFractionDigits;

/**
 The upper bound of the scale. (read-only)
 */
@property (readonly) double maximum;

/**
 The lower bound of the scale. (read-only)
 */
@property (readonly) double minimum;

/**
 The default value for the slider. (read-only)
 
 If the value of this property is less than `minimum` or greater than `maximum`, the slider has no 
 default value.
 */
@property (readonly) double defaultValue;

/**
 The maximum number of fractional digits to display. (read-only)
 */
@property (readonly) NSInteger maximumFractionDigits;

/**
 A Boolean value indicating whether the scale is oriented vertically. (read-only)
 */
@property (readonly, getter=isVertical) BOOL vertical;

/**
 A formatting style applied to the minimum, maximum, and slider values.
 */
@property RK1NumberFormattingStyle numberStyle;

/**
 A number formatter applied to the minimum, maximum, and slider values. Can be overridden by
 subclasses.
 */
@property (readonly) NSNumberFormatter *numberFormatter;

/**
 A localized label to describe the maximum value of the scale. (read-only)
 */
@property (readonly, nullable) NSString *maximumValueDescription;

/**
 A localized label to describe the minimum value of the scale. (read-only)
 */
@property (readonly, nullable) NSString *minimumValueDescription;

/**
 An image for the upper bound of the slider. 
 @discussion The recommended image size is 30 x 30 points. The maximum range label will not be visible.
 */
@property (strong, nullable) UIImage *maximumImage;

/**
 An image for the lower bound of the slider. 
 @discussion The recommended image size is 30 x 30 points. The minimum range label will not be visible.
 */
@property (strong, nullable) UIImage *minimumImage;

/**
 The colors to use when drawing a color gradient above the slider. Colors are drawn such that
 lower indexes correspond to the minimum side of the scale, while colors at higher indexes in
 the array corresond to the maximum side of the scale.
 
 Setting this value to nil results in no gradient being drawn. Defaults to nil.
 
 An example usage would set an array of red and green to visually indicate a scale from bad to good.
 */
@property (copy, nullable) NSArray<UIColor *> *gradientColors;

/**
 Indicates the position of gradient stops for the colors specified in `gradientColors`.
 Gradient stops are specified as values between 0 and 1. The values must be monotonically
 increasing.
 
 If nil, the stops are spread uniformly across the range. Defaults to nil.
 */
@property (copy, nullable) NSArray<NSNumber *> *gradientLocations;

@end


/**
 The `RK1TextScaleAnswerFormat` represents an answer format that includes a discrete slider control
 with a text label next to each step.
 
 The scale answer format produces an `RK1ChoiceQuestionResult` object that contains the selected text 
 choice's value. */
RK1_CLASS_AVAILABLE
@interface RK1TextScaleAnswerFormat : RK1AnswerFormat

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 Returns an initialized text scale answer format using the specified values.
 
 This method is the designated initializer.
 
 @param textChoices                 An array of text choices which will be used to determine the
                                        number of steps in the slider, and
                                    to fill the text label next to each of the steps. The array must
                                        contain between 2 and 8 text choices.
 @param defaultIndex                The default index of the scale. If this value is out of range,
                                        the slider is displayed without a default value.
 @param vertical                    Pass `YES` to use a vertical scale; for the default horizontal
                                        scale, pass `NO`.
 
 @return An initialized text scale answer format.
 */
- (instancetype)initWithTextChoices:(NSArray<RK1TextChoice *> *)textChoices
                       defaultIndex:(NSInteger)defaultIndex
                           vertical:(BOOL)vertical NS_DESIGNATED_INITIALIZER;

/**
 Returns an initialized text scale answer format using the specified values.
 
 This method is a convenience initializer.
 
 @param textChoices                 An array of text choices which will be used to determine the
                                        number of steps in the slider, and
                                    to fill the text label next to each of the steps. The array must
                                        contain between 2 and 8 text choices.
 @param defaultIndex                The default index of the scale. If this value is out of range,
                                        the slider is displayed without a default value.
 
 @return An initialized text scale answer format.
 */
- (instancetype)initWithTextChoices:(NSArray<RK1TextChoice *> *)textChoices
                       defaultIndex:(NSInteger)defaultIndex;

/**
 An array of text choices which provides the text to be shown next to each of the slider steps.
 (read-only)
 */
@property (copy, readonly) NSArray<RK1TextChoice *> *textChoices;

/**
 The default index for the slider. (read-only)
 
 If the value of this property is less than zero or greater than the number of text choices,
 the slider has no default value.
 */
@property (readonly) NSInteger defaultIndex;

/**
 A Boolean value indicating whether the scale is oriented vertically. (read-only)
 */
@property (readonly, getter=isVertical) BOOL vertical;

/**
 The colors to use when drawing a color gradient above the slider. Colors are drawn such that
 lower indexes correspond to the minimum side of the scale, while colors at higher indexes in
 the array corresond to the maximum side of the scale.
 
 Setting this value to nil results in no gradient being drawn. Defaults to nil.
 
 An example usage would set an array of red and green to visually indicate a scale from bad to good.
 */
@property (copy, nullable) NSArray<UIColor *> *gradientColors;

/**
 Indicates the position of gradient stops for the colors specified in `gradientColors`.
 Gradient stops are specified as values between 0 and 1. The values must be monotonically
 increasing.
 
 If nil, the stops are spread uniformly across the range. Defaults to nil.
 */
@property (copy, nullable) NSArray<NSNumber *> *gradientLocations;

@end


/**
 The `RK1ValuePickerAnswerFormat` class represents an answer format that lets participants use a
 value picker to choose from a fixed set of text choices.
 
 When the number of choices is relatively large and the text that describes each choice
 is short, you might want to use the value picker answer format instead of the text choice answer
 format (`RK1TextChoiceAnswerFormat`). When the text that describes each choice is long, or there
 are only a very small number of choices, it's usually better to use the text choice answer format.
 
 Note that the value picker answer format reports itself as being of the single choice question
 type. The value picker answer format produces an `RK1ChoiceQuestionResult` object.
 */
RK1_CLASS_AVAILABLE
@interface RK1ValuePickerAnswerFormat : RK1AnswerFormat

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 Returns a value picker answer format using the specified array of text choices.
 
 Note that the `detailText` property of each choice is ignored. Be sure to create localized text for
 each choice that is short enough to fit in a `UIPickerView` object.
 
 @param textChoices     Array of `RK1TextChoice` objects.
 
 @return An initialized value picker answer format.
 */
- (instancetype)initWithTextChoices:(NSArray<RK1TextChoice *> *)textChoices NS_DESIGNATED_INITIALIZER;

/**
 An array of text choices that represent the options to display in the picker. (read-only)
 
 Note that the `detailText` property of each choice is ignored. Be sure to create localized text for
 each choice that is short enough to fit in a `UIPickerView` object.
 */
@property (copy, readonly) NSArray<RK1TextChoice *> *textChoices;

@end


/**
 The `RK1MultipleValuePickerAnswerFormat` class represents an answer format that lets participants use a
 multiple-component value picker to choose from a fixed set of text choices.
 
 Note that the multiple value picker answer format reports itself as being of the multiple picker question
 type. The multiple-component value picker answer format produces an `RK1MultipleComponentQuestionResult` 
 object where the index into the array matches the array of `RK1ValuePickerAnswerFormat` objects.
 
 For example, if the picker shows two columns with choices of `[[A, B, C], [1, 2, 3, 4]]` and the user picked
 `B` and `3` then this would result in `componentsAnswer = [B, 3]`.
 */
RK1_CLASS_AVAILABLE
@interface RK1MultipleValuePickerAnswerFormat : RK1AnswerFormat

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 Returns a multiple value picker answer format using the specified array of value pickers.
 
 @param valuePickers     Array of `RK1ValuePickerAnswerFormat` objects.
 
 @return An initialized multiple value picker answer format.
 */
- (instancetype)initWithValuePickers:(NSArray<RK1ValuePickerAnswerFormat *> *)valuePickers;

/**
 Returns a multiple value picker answer format using the specified array of value pickers.
 
 @param valuePickers     Array of `RK1ValuePickerAnswerFormat` objects.
 @param separator        String used to separate the components
 
 @return An initialized multiple value picker answer format.
 */
- (instancetype)initWithValuePickers:(NSArray<RK1ValuePickerAnswerFormat *> *)valuePickers separator:(NSString *)separator NS_DESIGNATED_INITIALIZER;

/**
 An array of value pickers that represent the options to display in the picker. (read-only)
 */
@property (copy, readonly) NSArray<RK1ValuePickerAnswerFormat *> *valuePickers;

/**
 A string used to define the separator for the format of the string. Default = " ".
 */
@property (copy, readonly) NSString *separator;

@end


/**
 The `RK1ImageChoiceAnswerFormat` class represents an answer format that lets participants choose
 one image from a fixed set of images in a single choice question.
 
 For example, you might use the image choice answer format to represent a range of moods that range
 from very sad
 to very happy.
 
 The image choice answer format produces an `RK1ChoiceQuestionResult` object.
 */
RK1_CLASS_AVAILABLE
@interface RK1ImageChoiceAnswerFormat : RK1AnswerFormat

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 Returns an initialized image choice answer format using the specified array of images.
 
 @param imageChoices    Array of `RK1ImageChoice` objects.
 
 @return An initialized image choice answer format.
 */
- (instancetype)initWithImageChoices:(NSArray<RK1ImageChoice *> *)imageChoices NS_DESIGNATED_INITIALIZER;

/**
 An array of `RK1ImageChoice` objects that represent the available choices. (read-only)
 
 The text of the currently selected choice is displayed on screen. The text for
 each choice is spoken by VoiceOver when an image is highlighted.
 */
@property (copy, readonly) NSArray<RK1ImageChoice *> *imageChoices;

@end


/**
 The `RK1TextChoiceAnswerFormat` class represents an answer format that lets participants choose
 from a fixed set of text choices in a multiple or single choice question.
 
 The text choices are presented in a table view, using one row for each answer.
 The text for each answer is given more prominence than the `detailText` in the row, but
 both are shown.
 
 The text choice answer format produces an `RK1ChoiceQuestionResult` object.
 */
RK1_CLASS_AVAILABLE
@interface RK1TextChoiceAnswerFormat : RK1AnswerFormat

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 Returns an initialized text choice answer format using the specified question style and array of
 text choices.
 
 @param style           The style of question, such as single or multiple choice.
 @param textChoices     An array of `RK1TextChoice` objects.
 
 @return An initialized text choice answer format.
 */
- (instancetype)initWithStyle:(RK1ChoiceAnswerStyle)style
                  textChoices:(NSArray<RK1TextChoice *> *)textChoices NS_DESIGNATED_INITIALIZER;

/**
 The style of the question (that is, single or multiple choice).
 */
@property (readonly) RK1ChoiceAnswerStyle style;

/**
 An array of `RK1TextChoice` objects that represent the choices that are displayed to participants.
 
 The choices are presented as a table view, using one row for each answer.
 The text for each answer is given more prominence than the `detailText` in the row, but
 both are shown.
 */
@property (copy, readonly) NSArray<RK1TextChoice *> *textChoices;

@end


/**
 The `RK1BooleanAnswerFormat` class behaves the same as the `RK1TextChoiceAnswerFormat` class,
 except that it is preconfigured to use only Yes and No answers.
 
 The Boolean answer format produces an `RK1BooleanQuestionResult` object.
 */
RK1_CLASS_AVAILABLE
@interface RK1BooleanAnswerFormat : RK1AnswerFormat

/**
 Returns an initialized Boolean answer format using the specified strings for Yes and No answers.
 
 @param yes         A string that describes the Yes answer.
 @param no          A string that describes the No answer.
 
 @return An initialized Boolean answer format.
 */
- (instancetype)initWithYesString:(NSString *)yes noString:(NSString *)no;

/**
 The string to describe the Yes answer. (read-only)
 */
@property (copy, readonly) NSString *yes;

/**
 The string to describe the No answer. (read-only)
 */
@property (copy, readonly) NSString *no;

@end


/**
 The `RK1TextChoice` class defines the text for a choice in answer formats such
 as `RK1TextChoiceAnswerFormat` and `RK1ValuePickerAnswerFormat`.
 
 When a participant chooses a text choice item, the value recorded in a result
 is specified by the `value` property.
 */
RK1_CLASS_AVAILABLE
@interface RK1TextChoice : NSObject <NSSecureCoding, NSCopying, NSObject>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 Returns a text choice object that includes the specified primary text, detail text,
 and exclusivity.
 
 @param text        The primary text that describes the choice in a localized string.
 @param detailText  The detail text to display below the primary text, in a localized string.
 @param value       The value to record in a result object when this item is selected.
 @param exclusive   Whether this choice is to be considered exclusive within the set of choices.
 
 @return A text choice instance.
 */
+ (instancetype)choiceWithText:(NSString *)text detailText:(nullable NSString *)detailText value:(id<NSCopying, NSCoding, NSObject>)value exclusive:(BOOL)exclusive;

/**
 Returns a choice object that includes the specified primary text.
 
 @param text        The primary text that describes the choice in a localized string.
 @param value       The value to record in a result object when this item is selected.
 
 @return A text choice instance.
 */
+ (instancetype)choiceWithText:(NSString *)text value:(id<NSCopying, NSCoding, NSObject>)value;

/**
 Returns an initialized text choice object using the specified primary text, detail text,
 and exclusivity.
 
 This method is the designated initializer.
 
 @param text        The primary text that describes the choice in a localized string.
 @param detailText  The detail text to display below the primary text, in a localized string.
 @param value       The value to record in a result object when this item is selected.
 @param exclusive   Whether this choice is to be considered exclusive within the set of choices.
 
 @return An initialized text choice.
 */
- (instancetype)initWithText:(NSString *)text
                  detailText:(nullable NSString *)detailText
                       value:(id<NSCopying, NSCoding, NSObject>)value
                    exclusive:(BOOL)exclusive NS_DESIGNATED_INITIALIZER;

/**
 The text that describes the choice in a localized string.
 
 In general, it's best when the text can fit on one line.
  */
@property (copy, readonly) NSString *text;

/**
 The value to return when this choice is selected.
 
 The value of this property is expected to be a scalar property list type, such as `NSNumber`
 or `NSString`. If no value is provided, the index of the option in the options list in the
 answer format is used.
 */
@property (copy, readonly) id<NSCopying, NSCoding, NSObject> value;

/**
 The text that provides additional details about the choice in a localized string.
 
 The detail text can span multiple lines. Note that `RK1ValuePickerAnswerFormat` ignores detail
 text.
  */
@property (copy, readonly, nullable) NSString *detailText;

/**
 In a multiple choice format, this indicates whether this choice requires all other choices to be
 unselected.
 
 In general, this is used to indicate a "None of the above" choice.
 */
@property (readonly) BOOL exclusive;

@end


/**
 The `RK1ImageChoice` class defines a choice that can
 be included in an `RK1ImageChoiceAnswerFormat` object.
 
 Typically, image choices are displayed in a horizontal row, so you need to use appropriate sizes.
 For example, when five image choices are displayed in an `RK1ImageChoiceAnswerFormat`, image sizes
 of about 45 to 60 points allow the images to look good in apps that run on all versions of iPhone.
 
 The text that describes an image choice should be reasonably short. However, only the text for the
 currently selected image choice is displayed, so text that wraps to more than one line
 is supported.
 */
RK1_CLASS_AVAILABLE
@interface RK1ImageChoice : NSObject <NSSecureCoding, NSCopying>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 Returns an image choice that includes the specified images and text.
 
 @param normal      The image to display in the unselected state.
 @param selected    The image to display in the selected state.
 @param text        The text to display when the image is selected.
 @param value       The value to record in a result object when the image is selected.
 
 @return An image choice instance.
 */
+ (instancetype)choiceWithNormalImage:(nullable UIImage *)normal
                        selectedImage:(nullable UIImage *)selected
                                 text:(nullable NSString *)text
                                value:(id<NSCopying, NSCoding, NSObject>)value;

/**
 Returns an initialized image choice using the specified images and text.
 
 This method is the designated initializer.
 
 @param normal      The image to display in the unselected state.
 @param selected    The image to display in the selected state.
 @param text        The text to display when the image is selected.
 @param value       The value to record in a result object when the image is selected.
 
 @return An initialized image choice.
 */
- (instancetype)initWithNormalImage:(nullable UIImage *)normal
                      selectedImage:(nullable UIImage *)selected
                               text:(nullable NSString *)text
                              value:(id<NSCopying, NSCoding, NSObject>)value NS_DESIGNATED_INITIALIZER;

/**
 The image to display when the choice is not selected. (read-only)
 
 The size of the unselected image depends on the number of choices you need to display. As a
 general rule, it's recommended that you start by creating an image that measures 44 x 44 points,
 and adjust it if necessary.
 */
@property (strong, readonly) UIImage *normalStateImage;

/**
 The image to display when the choice is selected. (read-only)
 
 For best results, the selected image should be the same size as the unselected image (that is,
 the value of the `normalStateImage` property).
 If you don't specify a selected image, the default `UIButton` behavior is used to
 indicate the selection state of the item.
 */
@property (strong, readonly, nullable) UIImage *selectedStateImage;

/**
 The text to display when the image is selected, in a localized string. (read-only)
 
 Note that the text you supply may be spoken by VoiceOver even when the item is not selected.
  */
@property (copy, readonly, nullable) NSString *text;

/**
 The value to return when the image is selected. (read-only)
 
 The value of this property is expected to be a scalar property list type, such as `NSNumber` or
 `NSString`. If no value is provided, the index of the option in the `RK1ImageChoiceAnswerFormat`
 options list is used.
 */
@property (copy, readonly) id<NSCopying, NSCoding, NSObject> value;

@end


/**
 The style of answer for an `RK1NumericAnswerFormat` object, which controls the keyboard that is
 presented during numeric entry.
 */
typedef NS_ENUM(NSInteger, RK1NumericAnswerStyle) {

    /**
     A decimal question type asks the participant to enter a decimal number.
     */
    RK1NumericAnswerStyleDecimal,
    
    /**
     An integer question type asks the participant to enter an integer number.
     */
    RK1NumericAnswerStyleInteger
} RK1_ENUM_AVAILABLE;

/**
 The `RK1NumericAnswerFormat` class defines the attributes for a numeric
 answer format that participants enter using a numeric keyboard.
 
 If you specify maximum or minimum values and the user enters a value outside the
 specified range, the question step view controller does not allow navigation
 until the participant provides a value that is within the valid range.
 
 Questions and form items that use this answer format produce an
 `RK1NumericQuestionResult` object.
 */
RK1_CLASS_AVAILABLE
@interface RK1NumericAnswerFormat : RK1AnswerFormat

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 Returns an initialized numeric answer format using the specified style.
 
 @param style       The style of the numeric answer (decimal or integer).
 
 @return An initialized numeric answer format.
 */
- (instancetype)initWithStyle:(RK1NumericAnswerStyle)style;

/**
 Returns an initialized numeric answer format using the specified style and unit designation.
 
 @param style       The style of the numeric answer (decimal or integer).
 @param unit        A string that displays a localized version of the unit designation.
 
 @return An initialized numeric answer format.
 */
- (instancetype)initWithStyle:(RK1NumericAnswerStyle)style
                         unit:(nullable NSString *)unit;

/**
Returns an initialized numeric answer format using the specified style, unit designation, and range
 values.
 
 This method is the designated initializer.
 
 @param style       The style of the numeric answer (decimal or integer).
 @param unit        A string that displays a localized version of the unit designation.
 @param minimum     The minimum value to apply, or `nil` if none is specified.
 @param maximum     The maximum value to apply, or `nil` if none is specified.
 
 @return An initialized numeric answer format.
 */
- (instancetype)initWithStyle:(RK1NumericAnswerStyle)style
                         unit:(nullable NSString *)unit
                      minimum:(nullable NSNumber *)minimum
                      maximum:(nullable NSNumber *)maximum NS_DESIGNATED_INITIALIZER;

/**
 The style of numeric entry (decimal or integer). (read-only)
 */
@property (readonly) RK1NumericAnswerStyle style;

/**
 A string that displays a localized version of the unit designation next to the numeric value.
 (read-only)
 
 Examples of unit designations are days, lbs, and liters.
 The unit string is included in the `RK1NumericQuestionResult` object.
  */
@property (copy, readonly, nullable) NSString *unit;

/**
 The minimum allowed value for the numeric answer.
 
 The default value of this property is `nil`, which means that no minimum value is displayed.
 */
@property (copy, nullable) NSNumber *minimum;

/**
 The maximum allowed value for the numeric answer.
 
 The default value of this property is `nil`, which means that no maximum value is displayed.
 */
@property (copy, nullable) NSNumber *maximum;

@end


/**
 The `RK1TimeOfDayAnswerFormat` class represents the answer format for questions that require users
 to enter a time of day.
 
 A time of day answer format produces an `RK1TimeOfDayQuestionResult` object.
 */
RK1_CLASS_AVAILABLE
@interface RK1TimeOfDayAnswerFormat : RK1AnswerFormat

/**
 Returns an initialized time of day answer format using the specified default value.
 
 This method is the designated initializer.
 
 @param defaultComponents   The default value with which to configure the picker.
 
 @return An initialized time of day answer format.
 */
- (instancetype)initWithDefaultComponents:(nullable NSDateComponents *)defaultComponents NS_DESIGNATED_INITIALIZER;

/**
 The default time of day to display in the picker. (read-only)
 
 Note that both the hour and minute components are observed. If the value of this property is `nil`,
 the picker displays the current time of day.
 */
@property (nonatomic, copy, readonly, nullable) NSDateComponents *defaultComponents;

@end


/**
 The style of date picker to use in an `RK1DateAnswerFormat` object.
 */
typedef NS_ENUM(NSInteger, RK1DateAnswerStyle) {

    /**
     The date and time question type asks participants to choose a time or a combination of date
     and time, from a picker.
     */
    RK1DateAnswerStyleDateAndTime,
    
    /**
     The date question type asks participants to choose a particular date from a picker.
     */
    RK1DateAnswerStyleDate
} RK1_ENUM_AVAILABLE;

/**
 The `RK1DateAnswerFormat` class represents the answer format for questions that require users
 to enter a date, or a date and time.
 
 A date answer format produces an `RK1DateQuestionResult` object.
 */
RK1_CLASS_AVAILABLE
@interface RK1DateAnswerFormat : RK1AnswerFormat

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 Returns an initialized date answer format using the specified date style.
 
 @param style           The style of date answer, such as date, or date and time.
 
 @return An initialized date answer format.
 */
- (instancetype)initWithStyle:(RK1DateAnswerStyle)style;

/**
 Returns an initialized date answer format using the specified answer style and default date values.
 
 This method is the designated initializer.
 
 @param style           The style of date answer, such as date, or date and time.
 @param defaultDate     The default date to display. When the value of this parameter is `nil`, the
                            picker displays the current time.
 @param minimumDate     The minimum date that is accessible in the picker. If the value of this 
                            parameter is `nil`, there is no minimum.
 @param maximumDate     The maximum date that is accessible in the picker. If the value of this 
                            parameter is `nil`, there is no maximum.
 @param calendar        The calendar to use. If the value of this parameter is `nil`, the picker
                            uses the default calendar for the current locale.
 
 @return An initialized date answer format.
 */
- (instancetype)initWithStyle:(RK1DateAnswerStyle)style
                  defaultDate:(nullable NSDate *)defaultDate
                  minimumDate:(nullable NSDate *)minimumDate
                  maximumDate:(nullable NSDate *)maximumDate
                     calendar:(nullable NSCalendar *)calendar NS_DESIGNATED_INITIALIZER;

/**
 The style of date entry.
 */
@property (readonly) RK1DateAnswerStyle style;

/**
 The date to use as the default.
 
 The date is displayed in the user's time zone.
 When the value of this property is `nil`, the current time is used as the default.
 */
@property (copy, readonly, nullable) NSDate *defaultDate;

/**
 The minimum allowed date.
 
When the value of this property is `nil`, there is no minimum.
 */
@property (copy, readonly, nullable) NSDate *minimumDate;

/**
 The maximum allowed date.
 
 When the value of this property is `nil`, there is no maximum.
 */
@property (copy, readonly, nullable) NSDate *maximumDate;

/**
 The calendar to use in the picker.
 
 When the value of this property is `nil`, the picker uses the default calendar for the current
 locale.
 */
@property (copy, readonly, nullable) NSCalendar *calendar;

@end


/**
 The `RK1TextAnswerFormat` class represents the answer format for questions that collect a text
 response
 from the user.
 
 An `RK1TextAnswerFormat` object produces an `RK1TextQuestionResult` object.
 */
RK1_CLASS_AVAILABLE
@interface RK1TextAnswerFormat : RK1AnswerFormat

/**
 Returns an initialized text answer format using the regular expression.
 
 This method is one of the designated initializers.
 
 @param validationRegularExpression     The regular expression used to validate the text.
 @param invalidMessage                  The text presented to the user when invalid input is received.
 
 @return An initialized validated text answer format.
 */
- (instancetype)initWithValidationRegularExpression:(NSRegularExpression *)validationRegularExpression
                                     invalidMessage:(NSString *)invalidMessage NS_DESIGNATED_INITIALIZER;

/**
 Returns an initialized text answer format using the specified maximum string length.
 
 This method is one of the designated initializers.
 
 @param maximumLength   The maximum number of characters to accept. When the value of this parameter
                            is 0, there is no maximum.
 
 @return An initialized text answer format.
 */
- (instancetype)initWithMaximumLength:(NSInteger)maximumLength NS_DESIGNATED_INITIALIZER;

/**
 The regular expression used to validate user's input.
 
 The default value is nil. If set to nil, no validation will be performed.
 */
@property (nonatomic, copy, nullable) NSRegularExpression *validationRegularExpression;

/**
 The text presented to the user when invalid input is received.
 
 The default value is nil.
 */
@property (nonatomic, copy, nullable) NSString *invalidMessage;

/**
 The maximum length of the text users can enter.
 
 When the value of this property is 0, there is no maximum.
 */
@property NSInteger maximumLength;

/**
 A Boolean value indicating whether to expect more than one line of input.
 
 By default, the value of this property is `YES`.
 */
@property BOOL multipleLines;

/**
 The autocapitalization type that applies to the user's input.
 
 By default, the value of this property is `UITextAutocapitalizationTypeSentences`.
 */
@property UITextAutocapitalizationType autocapitalizationType;

/**
 The autocorrection type that applies to the user's input.
 
 By default, the value of this property is `UITextAutocorrectionTypeDefault`.
 */
@property UITextAutocorrectionType autocorrectionType;

/**
 The spell checking type that applies to the user's input.
 
 By default, the value of this property is `UITextSpellCheckingTypeDefault`.
 */
@property UITextSpellCheckingType spellCheckingType;

/**
 The keyboard type that applies to the user's input.
 
 By default, the value of this property is `UIKeyboardTypeDefault`.
 */
@property UIKeyboardType keyboardType;

/**
 Identifies whether the text object should hide the text being entered.
 
 By default, the value of this property is NO.
 */
@property (nonatomic,getter=isSecureTextEntry) BOOL secureTextEntry;

@end


/**
 The `RK1EmailAnswerFormat` class represents the answer format for questions that collect an email
 response from the user.
 
 An `RK1EmailAnswerFormat` object produces an `RK1TextQuestionResult` object.
 */
RK1_CLASS_AVAILABLE
@interface RK1EmailAnswerFormat : RK1AnswerFormat

@end


/**
 The `RK1TimeIntervalAnswerFormat` class represents the answer format for questions that ask users
  to specify a time interval.
 
 The time interval answer format is suitable for time intervals up to 24 hours. If you need to track
 time intervals of longer duration, use a different answer format, such as
 `RK1ValuePickerAnswerFormat`.
 
 Note that the time interval answer format does not support the selection of 0.
 
 A time interval answer format produces an `RK1TimeIntervalQuestionResult` object.
 */
RK1_CLASS_AVAILABLE
@interface RK1TimeIntervalAnswerFormat : RK1AnswerFormat

/**
 Returns an initialized time interval answer format using the specified default interval and step 
 value.
 
 This method is the designated initializer.
 
 @param defaultInterval     The default value to display in the picker.
 @param step                The step in the interval, in minutes. The value of this parameter must
                                be between 1 and 30.
 
 @return An initialized time interval answer format.
 */
- (instancetype)initWithDefaultInterval:(NSTimeInterval)defaultInterval
                                   step:(NSInteger)step NS_DESIGNATED_INITIALIZER;

/**
 The initial time interval displayed in the picker.
 */
@property (readonly) NSTimeInterval defaultInterval;

/**
 The size of the allowed step in the interval, in minutes.
 
 By default, the value of this property is 1. The minimum value is 1, and the maximum value is 30.
 */
@property (readonly) NSInteger step;

@end


/**
 The `RK1HeightAnswerFormat` class represents the answer format for questions that require users
 to enter a height.
 
 A height answer format produces an `RK1NumericQuestionResult` object. The result is always reported
 in the metric system using the `cm` unit.
 */
RK1_CLASS_AVAILABLE
@interface RK1HeightAnswerFormat : RK1AnswerFormat

/**
 Returns an initialized height answer format using the measurement system specified in the current
 locale.
 
 @return An initialized height answer format.
 */
- (instancetype)init;

/**
 Returns an initialized height answer format using the specified measurement system.
 
 This method is the designated initializer.
 
 @param measurementSystem   The measurement system to use. See `RK1MeasurementSystem` for the
                                accepted values.
 
 @return An initialized height answer format.
 */
- (instancetype)initWithMeasurementSystem:(RK1MeasurementSystem)measurementSystem NS_DESIGNATED_INITIALIZER;

/**
 The measurement system used by the answer format.
 */
@property (readonly) RK1MeasurementSystem measurementSystem;

@end


/**
 The `RK1WeightAnswerFormat` class represents the answer format for questions that require users
 to enter a weight.
 
 A weight answer format produces an `RK1NumericQuestionResult` object. The result is always reported
 in the metric system using the `kg` unit.
 */
RK1_CLASS_AVAILABLE
@interface RK1WeightAnswerFormat : RK1AnswerFormat

/**
 Returns an initialized weight answer format using the measurement system specified in the current
 locale.
 
 @return An initialized weight answer format.
 */
- (instancetype)init;

/**
 Returns an initialized weight answer format using the specified measurement system.
 
 This method is the designated initializer.
 
 @param measurementSystem   The measurement system to use. See `RK1MeasurementSystem` for the
 accepted values.
 
 @return An initialized weight answer format.
 */
- (instancetype)initWithMeasurementSystem:(RK1MeasurementSystem)measurementSystem;

/**
 Returns an initialized weight answer format using the specified measurement system and numeric
 precision.
 
 @param measurementSystem       The measurement system to use. See `RK1MeasurementSystem` for the
                                    accepted values.
 @param numericPrecision        The numeric precision used by the picker. If you pass
                                    `RK1NumericPrecisionDefault`, the picker will use 0.5 kg
                                    increments for the metric measurement system and whole pound
                                    increments for the USC measurement system, which mimics the
                                    default iOS behavior. If you pass `RK1NumericPrecisionLow`, the
                                    picker will use 1 kg increments for the metric measurement
                                    system and whole pound increments for the USC measurement
                                    system. If you pass `RK1NumericPrecisionHigher`, the picker
                                    use 0.01 gr increments for the metric measurement system,
                                    and ounce increments for the USC measurement system.
 
 @return An initialized weight answer format.
 */
- (instancetype)initWithMeasurementSystem:(RK1MeasurementSystem)measurementSystem
                         numericPrecision:(RK1NumericPrecision)numericPrecision;

/**
 Returns an initialized weight answer format using the specified measurement system, numeric
 precision, and default, minimum and maximum values.
 
 @param measurementSystem       The measurement system to use. See `RK1MeasurementSystem` for the
                                    accepted values.
 @param numericPrecision        The numeric precision used by the picker. If you pass
                                    `RK1NumericPrecisionDefault`, the picker will use 0.5 kg
                                    increments for the metric measurement system and whole pound
                                    increments for the USC measurement system, which mimics the
                                    default iOS behavior. If you pass `RK1NumericPrecisionLow`, the
                                    picker will use 1 kg increments for the metric measurement
                                    system and whole pound increments for the USC measurement
                                    system. If you pass `RK1NumericPrecisionHigher`, the picker
                                    use 0.01 gr increments for the metric measurement system,
                                    and ounce increments for the USC measurement system.
 @param minimumValue            The minimum value that is displayed in the picker. If you specify
                                    `RK1DefaultValue`, the minimum values are 0 kg when using the
                                    metric measurement system and 0 lbs when using the USC
                                    measurement system.
 @param maximumValue            The maximum value that is displayed in the picker. If you specify
                                    `RK1DefaultValue`, the maximum values are 657 kg when using the
                                    metric measurement system and 1,450 lbs when using the USC
                                    measurement system.
 @param defaultValue            The default value to be initially selected in the picker. If you
                                    specify `RK1DefaultValue`, the initally selected values are
                                    60 kg when using the metric measurement system and 133 lbs when
                                    using the USC measurement system. This value must be between
                                    `minimumValue` and `maximumValue`.
 
 @return An initialized weight answer format.
 */
- (instancetype)initWithMeasurementSystem:(RK1MeasurementSystem)measurementSystem
                         numericPrecision:(RK1NumericPrecision)numericPrecision
                             minimumValue:(double)minimumValue
                             maximumValue:(double)maximumValue
                             defaultValue:(double)defaultValue NS_DESIGNATED_INITIALIZER;

/**
 Indicates the measurement system used by the answer format.
 */
@property (readonly) RK1MeasurementSystem measurementSystem;

/**
 The numeric precision used by the picker.
 
 An `RK1NumericPrecisionDefault` value indicates that the picker will use 0.5 kg increments for the
 metric measurement system and whole pound increments for the USC measurement system, which mimics
 the default iOS behavior. An `RK1NumericPrecisionLow` value indicates that the picker will use
 1 kg increments for the metric measurement system and whole pound increments for the USC
 measurement system. An `RK1NumericPrecisionHigher` value indicates that the picker will use
 0.01 gr increments for the metric measurement system and ounce increments for the USC measurement
 system.
 
 The default value of this property is `RK1NumericPrecisionDefault`.
 */
@property (readonly, getter=isAdditionalPrecision) RK1NumericPrecision numericPrecision;

/**
 The minimum value that is displayed in the picker.
 
 When this property has a value equal to `RK1DefaultValue`, the minimum values are 0 kg when using
 the metric measurement system and 0 lbs when using the USC measurement system.
 */
@property (readonly) double minimumValue;

/**
 The maximum value that is displayed in the picker.
 
 When this property has a value equal to `RK1DefaultValue`, the maximum values are 657 kg when using
 the metric measurement system and 1,450 lbs when using the USC measurement system.
 */
@property (readonly) double maximumValue;

/**
 The default value to initially selected in the picker.
 
 When this property has a value equal to `RK1DefaultValue`, the initally selected values are 60 kg
 when using the metric measurement system and 133 lbs when using the USC measurement system. This
 value must be between `minimumValue` and `maximumValue`.
 */
@property (readonly) double defaultValue;

@end


/**
 The `RK1LocationAnswerFormat` class represents the answer format for questions that collect a location response
 from the user.
 
 An `RK1LocationAnswerFormat` object produces an `RK1LocationQuestionResult` object.
 */
RK1_CLASS_AVAILABLE
@interface RK1LocationAnswerFormat : RK1AnswerFormat

/**
 Indicates whether or not the user's current location should be automatically entered the first time they tap on the input field.
 
 By default, this value is YES.
 */
@property (nonatomic, assign) BOOL useCurrentLocation;

@end


NS_ASSUME_NONNULL_END
