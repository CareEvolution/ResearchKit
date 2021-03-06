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
#import <ORK1Kit/ORK1Task.h>


typedef NS_ENUM(NSInteger, CEVRK1TaskProgressIndicatorStyle) {
    CEVRK1TaskProgressIndicatorStyleNone,
    CEVRK1TaskProgressIndicatorStyleText,
    CEVRK1TaskProgressIndicatorStyleBar
} ORK1_ENUM_AVAILABLE;

typedef NS_ENUM(NSInteger, CEVRK1TaskProgressBarProgressionMetric) {
    CEVRK1TaskProgressBarProgressionMetricLinear,
    CEVRK1TaskProgressBarProgressionMetricFastToSlow
} ORK1_ENUM_AVAILABLE;


NS_ASSUME_NONNULL_BEGIN

@class ORK1NavigableOrderedTask;

/**
 The `ORK1OrderedTask` class implements all the methods in the `ORK1Task` protocol and represents a 
 task that assumes a fixed order for its steps.
 
 In the ORK1Kit framework, any simple sequential task, such as a survey or an active task, can
 be represented as an ordered task.
 
 If you want further custom conditional behaviors in a task, it can be easier to subclass
 `ORK1OrderedTask` or `ORK1NavigableOrderedTask` and override particular `ORK1Task` methods than it is
 to implement the `ORK1Task` protocol directly. Override the methods `stepAfterStep:withResult:` and
 `stepBeforeStep:withResult:`, and call super for all other methods.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1OrderedTask : NSObject <ORK1Task, NSSecureCoding, NSCopying>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/// @name Initializers

/**
 Returns an initialized ordered task using the specified identifier and array of steps.
 
 @param identifier  The unique identifier for the task.
 @param steps       An array of `ORK1Step` objects in the order in which they should be presented.
 
 @return An initialized ordered task.
 */
- (instancetype)initWithIdentifier:(NSString *)identifier
                             steps:(nullable NSArray<ORK1Step *> *)steps NS_DESIGNATED_INITIALIZER;

/**
 Returns an ordered task initialized from data in the given unarchiver.
 
 An ordered task can be serialized and deserialized with `NSKeyedArchiver`. Note
 that this serialization includes strings that might need to be
 localized.
 
 @param aDecoder    The coder from which to initialize the ordered task.
 
 @return An initialized ordered task.
 */
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

/// @name Properties

/**
 The array of steps in the task. (read-only)
 
 Each element in the array must be a subclass of `ORK1Step`.
 The associated task view controller presents the steps in
 array order.
 */
@property (nonatomic, copy, readonly) NSArray<ORK1Step *> *steps;

/**
 The theme for the task.
 
 Various UI elements may check the theme and use it to apply modifications.
 */
@property (nonatomic, retain, nullable) CEVRK1Theme *cev_theme;

/**
 For steps that will show progress, this determines how progress is displayed in the top navigation bar.
 Choices are .none (hides any progress), .text (e.g., "Step 5 of 20"), or .bar (progress bar)
 
 Default is .text
*/
@property (nonatomic, assign) CEVRK1TaskProgressIndicatorStyle progressIndicatorStyle;

/**
 If taskProgressIndicatorStyle is .bar, this detemines how quickly the bar fills.
 Choices are .linear (e.g., step 1 of 10 should be 10 % filled, step 2 of 10 should be 20 %),
 and .fastToSlow (progress bar grows quickly at beginning and then slows down).
 
 Default is .linear
*/
@property (nonatomic, assign) CEVRK1TaskProgressBarProgressionMetric progressBarProgressionMetric;

/**
 Return a mutated copy of self with the steps included in the given array.
 
 This method is intended to allow for mutating an ordered task (or subclass) while retaining
 the original class and properties that may not be publicly exposed, but with a mutated set
 of steps. An example of where this might be useful is if before performing an `ORK1PredefinedActiveTask`, 
 the app needed to query the participant about medications, diet or sleep. The app
 would need to mutate the steps in order to insert their own steps. While an ORK1OrderedTask could
 then be created with the same identifier and the new steps, subclass information such rules on an
 `ORK1NavigableOrderedTask` would be lost.
 
 @param steps       An array of `ORK1Step` objects in the order in which they should be presented.
 
 @return            An initialized ordered task.
 */
- (instancetype)copyWithSteps:(NSArray <ORK1Step *> *)steps;

/**
 Find the index of a given step.
 
 @param step        The step to look for
 @return            The index position of the step (or NSNotFound if not found)
 */
- (NSUInteger)indexOfStep:(ORK1Step *)step;

@end


/**
 The `ORK1PredefinedTaskOption` flags let you exclude particular behaviors from the predefined active
 tasks in the predefined category of `ORK1OrderedTask`.
 
 By default, all predefined tasks include instructions and conclusion steps, and may also include
 one or more data collection recorder configurations. Although not all predefined tasks include all
 of these data collection types, the predefined task option flags can be used to explicitly specify
 that a task option not be included.
 */

typedef NS_OPTIONS(NSUInteger, ORK1PredefinedTaskOption) {
    /// Default behavior.
    ORK1PredefinedTaskOptionNone = 0,
    
    /// Exclude the initial instruction steps.
    ORK1PredefinedTaskOptionExcludeInstructions = (1 << 0),
    
    /// Exclude the conclusion step.
    ORK1PredefinedTaskOptionExcludeConclusion = (1 << 1),
    
    /// Exclude accelerometer data collection.
    ORK1PredefinedTaskOptionExcludeAccelerometer = (1 << 2),
    
    /// Exclude device motion data collection.
    ORK1PredefinedTaskOptionExcludeDeviceMotion = (1 << 3),
    
    /// Exclude pedometer data collection.
    ORK1PredefinedTaskOptionExcludePedometer = (1 << 4),
    
    /// Exclude location data collection.
    ORK1PredefinedTaskOptionExcludeLocation = (1 << 5),
    
    /// Exclude heart rate data collection.
    ORK1PredefinedTaskOptionExcludeHeartRate = (1 << 6),
    
    /// Exclude audio data collection.
    ORK1PredefinedTaskOptionExcludeAudio = (1 << 7)
} ORK1_ENUM_AVAILABLE;

/**
 Values that identify the hand(s) to be used in an active task.
 
 By default, the participant will be asked to use their most affected hand.
 */
typedef NS_OPTIONS(NSUInteger, ORK1PredefinedTaskHandOption) {
    /// Which hand to use is undefined
    ORK1PredefinedTaskHandOptionUnspecified = 0,
    
    /// Task should test the left hand
    ORK1PredefinedTaskHandOptionLeft = 1 << 1,
    
    /// Task should test the right hand
    ORK1PredefinedTaskHandOptionRight = 1 << 2,
    
    /// Task should test both hands (random order)
    ORK1PredefinedTaskHandOptionBoth = ORK1PredefinedTaskHandOptionLeft | ORK1PredefinedTaskHandOptionRight,
} ORK1_ENUM_AVAILABLE;

/**
 The `ORK1TremorActiveTaskOption` flags let you exclude particular steps from the predefined active
 tasks in the predefined Tremor `ORK1OrderedTask`.
 
 By default, all predefined active tasks will be included. The tremor active task option flags can
 be used to explicitly specify that an active task is not to be included.
 */
typedef NS_OPTIONS(NSUInteger, ORK1TremorActiveTaskOption) {
    /// Default behavior.
    ORK1TremorActiveTaskOptionNone = 0,
    
    /// Exclude the hand-in-lap steps.
    ORK1TremorActiveTaskOptionExcludeHandInLap = (1 << 0),
    
    /// Exclude the hand-extended-at-shoulder-height steps.
    ORK1TremorActiveTaskOptionExcludeHandAtShoulderHeight = (1 << 1),
    
    /// Exclude the elbow-bent-at-shoulder-height steps.
    ORK1TremorActiveTaskOptionExcludeHandAtShoulderHeightElbowBent = (1 << 2),
    
    /// Exclude the elbow-bent-touch-nose steps.
    ORK1TremorActiveTaskOptionExcludeHandToNose = (1 << 3),
    
    /// Exclude the queen-wave steps.
    ORK1TremorActiveTaskOptionExcludeQueenWave = (1 << 4)
} ORK1_ENUM_AVAILABLE;

/**
 Values that identify the left or right limb to be used in an active task.
*/
typedef NS_OPTIONS(NSUInteger, ORK1PredefinedTaskLimbOption) {
    /// Which limb to use is undefined
    ORK1PredefinedTaskLimbOptionUnspecified = 0,
    
    /// Task should test the left limb
    ORK1PredefinedTaskLimbOptionLeft = 1 << 1,
    
    /// Task should test the right limb
    ORK1PredefinedTaskLimbOptionRight = 1 << 2,
    
    /// Task should test the both limbs (random order)
    ORK1PredefinedTaskLimbOptionBoth = ORK1PredefinedTaskLimbOptionLeft | ORK1PredefinedTaskLimbOptionRight,
} ORK1_ENUM_AVAILABLE;

typedef NSString * ORK1TrailMakingTypeIdentifier NS_STRING_ENUM;

/// Trail making for Type-A trail where the pattern is 1-2-3-4-5-6-7
ORK1_EXTERN ORK1TrailMakingTypeIdentifier const ORK1TrailMakingTypeIdentifierA;

/// Trail making for Type-B trail where the pattern is 1-A-2-B-3-C-4-D-5-E-6-F-7
ORK1_EXTERN ORK1TrailMakingTypeIdentifier const ORK1TrailMakingTypeIdentifierB;


@interface ORK1OrderedTask (ORK1PredefinedActiveTask)

/**
 Returns a predefined task that consists of a fitness check.
 
 In a fitness check task, the participant is asked to walk for a specified duration
 (typically several minutes). During this period, various sensor data is collected and returned by
 the task view controller's delegate. Sensor data can include accelerometer, device motion,
 pedometer, location, and heart rate data where available.
 
 At the conclusion of the walk, if heart rate data is available, the participant is asked to sit
 down and rest for a period. Data collection continues during this period.
 
 By default, the task includes an instruction step that explains what the user needs to do during
 the task, but this can be excluded with `ORK1PredefinedTaskOptionExcludeInstructions`.
 
 Data collected from this task can be used to compute measures of general fitness.
 
 @param identifier              The task identifier to use for this task, appropriate to the study.
 @param intendedUseDescription  A localized string describing the intended use of the data
                                    collected. If the value of this parameter is `nil`, the default
                                    localized text is displayed.
 @param walkDuration            The duration of the walk (the maximum is 10 minutes).
 @param restDuration            The duration of the post walk rest period.
 @param options                 Options that affect the features of the predefined task.
 
 @return An active fitness check task that can be presented with an `ORK1TaskViewController` object.
 */
+ (ORK1OrderedTask *)fitnessCheckTaskWithIdentifier:(NSString *)identifier
                            intendedUseDescription:(nullable NSString *)intendedUseDescription
                                      walkDuration:(NSTimeInterval)walkDuration
                                      restDuration:(NSTimeInterval)restDuration
                                           options:(ORK1PredefinedTaskOption)options;

/**
 Returns a predefined task that consists of a short walk.
 
 In a short walk task, the participant is asked to walk a short distance, which may be indoors.
 Typical uses of the resulting data are to assess stride length, smoothness, sway, or other aspects
 of the participant's gait.
 
 The presentation of the short walk task differs from the fitness check task in that the distance is
 replaced by the number of steps taken, and the walk is split into a series of legs. After each leg,
 the user is asked to turn and reverse direction.
 
 The data collected by this task can include accelerometer, device motion, and pedometer data.
 
 @param identifier              The task identifier to use for this task, appropriate to the study.
 @param intendedUseDescription  A localized string describing the intended use of the data
                                    collected. If the value of this parameter is `nil`, the default
                                    localized text is displayed.
 @param numberOfStepsPerLeg     The number of steps the participant is asked to walk. If the
                                    pedometer is unavailable, a distance is suggested and a suitable
                                    count down timer is displayed for each leg of the walk.
 @param restDuration            The duration of the rest period. When the value of this parameter is
                                    nonzero, the user is asked to stand still for the specified rest
                                    period after the turn sequence has been completed, and baseline
                                    data is collected.
 @param options                 Options that affect the features of the predefined task.
 
 @return An active short walk task that can be presented with an `ORK1TaskViewController` object.
 */
+ (ORK1OrderedTask *)shortWalkTaskWithIdentifier:(NSString *)identifier
                         intendedUseDescription:(nullable NSString *)intendedUseDescription
                            numberOfStepsPerLeg:(NSInteger)numberOfStepsPerLeg
                                   restDuration:(NSTimeInterval)restDuration
                                        options:(ORK1PredefinedTaskOption)options;

/**
 Returns a predefined task that consists of a short walk back and forth.
 
 In a short walk task, the participant is asked to walk a short distance, which may be indoors.
 Typical uses of the resulting data are to assess stride length, smoothness, sway, or other aspects
 of the participant's gait.
 
 The presentation of the back and forth walk task differs from the short walk in that the participant
 is asked to walk back and forth rather than walking in a straight line for a certain number of steps.
 
 The participant is then asked to turn in a full circle and then stand still.
 
 This task is intended to allow the participant to walk in a confined space where the participant
 does not have access to a long hallway to walk in a continuous straight line. Additionally, by asking 
 the participant to turn in a full circle and then stand still, the activity can access balance and 
 concentration.
 
 The data collected by this task can include accelerometer, device motion, and pedometer data.
 
 @param identifier              The task identifier to use for this task, appropriate to the study.
 @param intendedUseDescription  A localized string describing the intended use of the data
 collected. If the value of this parameter is `nil`, the default
 localized text is displayed.
 @param walkDuration            The duration of the walking period.
 @param restDuration            The duration of the rest period. When the value of this parameter is
 nonzero, the user is asked to stand still for the specified rest
 period after the turn sequence has been completed, and baseline
 data is collected.
 @param options                 Options that affect the features of the predefined task.
 
 @return An active short walk task that can be presented with an `ORK1TaskViewController` object.
 */
+ (ORK1OrderedTask *)walkBackAndForthTaskWithIdentifier:(NSString *)identifier
                                intendedUseDescription:(nullable NSString *)intendedUseDescription
                                          walkDuration:(NSTimeInterval)walkDuration
                                          restDuration:(NSTimeInterval)restDuration
                                               options:(ORK1PredefinedTaskOption)options;

+ (ORK1OrderedTask *)kneeRangeOfMotionTaskWithIdentifier:(NSString *)identifier
                                             limbOption:(ORK1PredefinedTaskLimbOption)limbOption
                                 intendedUseDescription:(nullable NSString *)intendedUseDescription
                                                options:(ORK1PredefinedTaskOption)options;


+ (ORK1OrderedTask *)shoulderRangeOfMotionTaskWithIdentifier:(NSString *)identifier
                                                 limbOption:(ORK1PredefinedTaskLimbOption)limbOption
                                     intendedUseDescription:(nullable NSString *)intendedUseDescription
                                                    options:(ORK1PredefinedTaskOption)options;
/**
 Returns a predefined task that enables an audio recording WITH a check of the audio level.
 
 In an audio recording task, the participant is asked to make some kind of sound
 with their voice, and the audio data is collected.
 
 An audio task can be used to measure properties of the user's voice, such as
 frequency range, or the ability to pronounce certain sounds.
 
 If `checkAudioLevel == YES` then a navigation rule is added to do a simple check of the background
 noise level. If the background noise is too loud, then the participant is instructed to move to a 
 quieter location before trying again.
 
 Data collected in this task consists of audio information.
 
 @param identifier              The task identifier to use for this task, appropriate to the study.
 @param intendedUseDescription  A localized string describing the intended use of the data
 collected. If the value of this parameter is `nil`, default
 localized text is used.
 @param speechInstruction       Instructional content describing what the user needs to do when
 recording begins. If the value of this parameter is `nil`,
 default localized text is used.
 @param shortSpeechInstruction  Instructional content shown during audio recording. If the value of
 this parameter is `nil`, default localized text is used.
 @param duration                The length of the count down timer that runs while audio data is
 collected.
 @param recordingSettings       See "AV Foundation Audio Settings Constants" for possible values.
 @param checkAudioLevel         If `YES` then add navigational rules to check the background noise level.
 @param options                 Options that affect the features of the predefined task.
 
 @return An active audio task that can be presented with an `ORK1TaskViewController` object.
 */
+ (ORK1NavigableOrderedTask *)audioTaskWithIdentifier:(NSString *)identifier
                              intendedUseDescription:(nullable NSString *)intendedUseDescription
                                   speechInstruction:(nullable NSString *)speechInstruction
                              shortSpeechInstruction:(nullable NSString *)shortSpeechInstruction
                                            duration:(NSTimeInterval)duration
                                   recordingSettings:(nullable NSDictionary *)recordingSettings
                                     checkAudioLevel:(BOOL)checkAudioLevel
                                             options:(ORK1PredefinedTaskOption)options;

/**
 @Deprecated
 */
+ (ORK1OrderedTask *)audioTaskWithIdentifier:(NSString *)identifier
                     intendedUseDescription:(nullable NSString *)intendedUseDescription
                          speechInstruction:(nullable NSString *)speechInstruction
                     shortSpeechInstruction:(nullable NSString *)shortSpeechInstruction
                                   duration:(NSTimeInterval)duration
                          recordingSettings:(nullable NSDictionary *)recordingSettings
                                    options:(ORK1PredefinedTaskOption)options __deprecated;

/**
 Returns a predefined task that consists of two finger tapping (Optionally with a hand specified)
 
 In a two finger tapping task, the participant is asked to rhythmically and alternately tap two
 targets on the device screen.
 
 A two finger tapping task can be used to assess basic motor capabilities including speed, accuracy,
 and rhythm.
 
 Data collected in this task includes touch activity and accelerometer information.
 
 @param identifier              The task identifier to use for this task, appropriate to the study.
 @param intendedUseDescription  A localized string describing the intended use of the data
                                collected. If the value of this parameter is `nil`, the default
                                localized text will be displayed.
 @param duration                The length of the count down timer that runs while touch data is
                                collected.
 @param handOptions             Options for determining which hand(s) to test.
 @param options                 Options that affect the features of the predefined task.
 
 @return An active two finger tapping task that can be presented with an `ORK1TaskViewController` object.
 */
+ (ORK1OrderedTask *)twoFingerTappingIntervalTaskWithIdentifier:(NSString *)identifier
                                        intendedUseDescription:(nullable NSString *)intendedUseDescription
                                                      duration:(NSTimeInterval)duration
                                                   handOptions:(ORK1PredefinedTaskHandOption)handOptions
                                                       options:(ORK1PredefinedTaskOption)options;
/**
 @Deprecated
 */
+ (ORK1OrderedTask *)twoFingerTappingIntervalTaskWithIdentifier:(NSString *)identifier
                                        intendedUseDescription:(nullable NSString *)intendedUseDescription
                                                      duration:(NSTimeInterval)duration
                                                       options:(ORK1PredefinedTaskOption)options __deprecated;

/**
 Returns a predefined task that tests spatial span memory.
 
 In a spatial span memory task, the participant is asked to repeat pattern sequences of increasing
 length in a game-like environment. You can use this task to assess visuospatial memory and
 executive function.

 
 In each round of the task, an array of
 target images are shown in a grid (by default, the images are flowers). The round consists of a
 demonstration phase and an interactive phase. In the demonstration phase, some of the flowers
 change color in a specific sequence. After the demonstration, the user is asked to tap the flowers
 in the same sequence for the interactive phase.
 
 The span (that is, the length of the pattern sequence) is automatically varied during the task,
 increasing after users succeed and decreasing after they fail, within the range specified by
 minimum and maximum values that you specify. You can also customize the speed of sequence playback
 and the shape of the tap target.
 
 A spatial span memory task finishes when the user has either completed the maximum number of tests
 or made the maximum number of errors.
 
 Data collected by the task is in the form of an `ORK1SpatialSpanMemoryResult` object.
 
 @param identifier              The task identifier to use for this task, appropriate to the study.
 @param intendedUseDescription  A localized string describing the intended use of the data
                                    collected. If the value of this parameter is `nil`, the default
                                    localized text is displayed.
 @param initialSpan             The  sequence length of the initial memory pattern.
 @param minimumSpan             The minimum pattern sequence length.
 @param maximumSpan             The maximum pattern sequence length.
 @param playSpeed               The time per sequence item; a smaller value means faster sequence
                                    play.
 @param maximumTests                The maximum number of rounds to conduct.
 @param maximumConsecutiveFailures  The maximum number of consecutive failures the user can make before
                                    the task is terminated.
 @param customTargetImage       The image to use for the task. By default, and if the value of this
                                    parameter is `nil`, the image is a flower. To supply a custom
                                    image, create a template image to which iOS adds the tint color.
 @param customTargetPluralName  The name associated with `customTargetImage`; by default, the value
                                    of this parameter is @"flowers".
 @param requireReversal         A Boolean value that indicates whether to require the user to tap
                                    the sequence in reverse order.
 @param options                 Options that affect the features of the predefined task.
 
 @return An active spatial span memory task that can be presented with an `ORK1TaskViewController` object.
 */
+ (ORK1OrderedTask *)spatialSpanMemoryTaskWithIdentifier:(NSString *)identifier
                                 intendedUseDescription:(nullable NSString *)intendedUseDescription
                                            initialSpan:(NSInteger)initialSpan
                                            minimumSpan:(NSInteger)minimumSpan
                                            maximumSpan:(NSInteger)maximumSpan
                                              playSpeed:(NSTimeInterval)playSpeed
                                               maximumTests:(NSInteger)maximumTests
                                 maximumConsecutiveFailures:(NSInteger)maximumConsecutiveFailures
                                      customTargetImage:(nullable UIImage *)customTargetImage
                                 customTargetPluralName:(nullable NSString *)customTargetPluralName
                                        requireReversal:(BOOL)requireReversal
                                                options:(ORK1PredefinedTaskOption)options;

/**
 Returns a predefined Stroop task that tests participants selective attention and cognitive flexibility.
 
 In a stroop task, the participant is shown a text. The text is a name of a color, but the text is printed in a color that may or may not be denoted by the name. In each attempt of the task, the participant has to press the button that corresponds to the first letter of the color in which the text is printed. The participant has to ignore the name of the color written in the text, but respond based on the color of the text.
 
 A stroop task finishes when the user has completed all the attempts, irrespective of correct or incorrect answers.
 
 Data collected by the task is in the form of an `ORK1StroopResult` object.
 
 @param identifier              The task identifier to use for this task, appropriate to the study.
 @param intendedUseDescription  A localized string describing the intended use of the data
                                collected. If the value of this parameter is `nil`, the default
                                localized text is displayed.
 @param numberOfAttempts        Total number of stroop questions to include in the task.
 @param options                 Options that affect the features of the predefined task.
 */
+ (ORK1OrderedTask *)stroopTaskWithIdentifier:(NSString *)identifier
                      intendedUseDescription:(nullable NSString *)intendedUseDescription
                            numberOfAttempts:(NSInteger)numberOfAttempts
                                     options:(ORK1PredefinedTaskOption)options;

/**
 Returns a predefined task that tests tone audiometry.

 In a tone audiometry task, the participant is asked to listen to some tones with different audio
 frequencies, playing on different channels (left and right), with the volume being progressively
 increased until the participant taps a button.

 You can use a tone audiometry task to measure properties of the user's hearing, based on their
 reaction to a wide range of frequencies.

 Data collected in this task consists of audio signal amplitude for specific frequencies and
 channels.

 @param identifier              The task identifier to use for this task, appropriate to the study.
 @param intendedUseDescription  A localized string describing the intended use of the data
                                    collected. If the value of this parameter is `nil`, default
                                    localized text is used.
 @param speechInstruction       Instructional content describing what the user needs to do when
                                    recording begins. If the value of this parameter is `nil`,
                                    default localized text is used.
 @param shortSpeechInstruction  Instructional content shown during audio recording. If the value of
                                    this parameter is `nil`, default localized text is used.
 @param toneDuration            The maximum length of the duration for each tone (each tone can be
                                    interrupted sooner, after the participant presses the main
                                    button).
 @param options                 Options that affect the features of the predefined task.

 @return An active tone audiometry task that can be presented with an `ORK1TaskViewController` object.
 */
+ (ORK1OrderedTask *)toneAudiometryTaskWithIdentifier:(NSString *)identifier
                              intendedUseDescription:(nullable NSString *)intendedUseDescription
                                   speechInstruction:(nullable NSString *)speechInstruction
                              shortSpeechInstruction:(nullable NSString *)shortSpeechInstruction
                                        toneDuration:(NSTimeInterval)toneDuration
                                             options:(ORK1PredefinedTaskOption)options;

/**
 Returns a predefined task that tests the participant's reaction time.
 
 In a reaction time task, the participant is asked to move the device sharply in any
 direction in response to a visual cue. You can use this task to accurately assess the participant's
 simple reaction time.
 
 A reaction time task finishes when the participant has completed the required
 number of attempts successfully. An attempt is successful when the participant exerts acceleration
 greater than `thresholdAcceleration` to the device after the stimulus has been delivered and before
 `timeout` has elapsed. An attempt is unsuccessful if acceleration greater than
 `thresholdAcceleration` is applied to the device before the stimulus or if this does not occur
 before `timeout` has elapsed. If unsuccessful, the result is not reported and the participant must
 try again to proceed with the task.
 
 Data collected by the task is in the form of ORK1ReactionTimeResult objects. These
 objects contain a timestamp representing the delivery of the stimulus and an ORK1FileResult, which
 references the motion data collected during an attempt. The researcher can use these to evaluate
 the response to the stimulus and calculate the reaction time.
 
 @param identifier                  The task identifier to use for this task, appropriate to the
                                        study.
 @param intendedUseDescription      A localized string describing the intended use of the data
                                        collected. If the value of this parameter is `nil`, the
                                        default localized text is displayed.
 @param maximumStimulusInterval     The maximum interval before the stimulus is delivered.
 @param minimumStimulusInterval     The minimum interval before the stimulus is delivered.
 @param thresholdAcceleration       The acceleration required to end a reaction time test.
 @param numberOfAttempts            The number of successful attempts required before the task is
                                        complete. The active step result will contain this many
                                        child results if the task is completed.
 @param timeout                     The interval permitted after the stimulus until the test fails,
                                        if the threshold is not reached.
 @param successSoundID              The sound to play after a successful attempt.
 @param timeoutSoundID              The sound to play after an attempt that times out.
 @param failureSoundID              The sound to play after an unsuccessful attempt.
 @param options                 Options that affect the features of the predefined task.
 
 @return An active device motion reaction time task that can be presented with an `ORK1TaskViewController` object.
 */

+ (ORK1OrderedTask *)reactionTimeTaskWithIdentifier:(NSString *)identifier
                            intendedUseDescription:(nullable NSString *)intendedUseDescription
                           maximumStimulusInterval:(NSTimeInterval)maximumStimulusInterval
                           minimumStimulusInterval:(NSTimeInterval)minimumStimulusInterval
                             thresholdAcceleration:(double)thresholdAcceleration
                                  numberOfAttempts:(int)numberOfAttempts
                                           timeout:(NSTimeInterval)timeout
                                      successSound:(UInt32)successSoundID
                                      timeoutSound:(UInt32)timeoutSoundID
                                      failureSound:(UInt32)failureSoundID
                                           options:(ORK1PredefinedTaskOption)options;

/**
 Returns a predefined task that consists of a Tower of Hanoi puzzle.
 
 In a Tower of Hanoi task, the participant is asked to solve the classic puzzle in as few moves as possible.
 You can use this task to assess the participant's problem-solving skills.
 
 A Tower of Hanoi task finishes when the participant has completed the puzzle correctly or concedes that he or she cannot solve it.
 
 Data collected by the task is in the form of an `ORK1TowerOfHanoiResult` object. Data collected in this task consists of how many moves were taken and whether the puzzle was successfully completed or not.
 
 @param identifier                  The task identifier to use for this task, appropriate to the study.
 @param intendedUseDescription      A localized string describing the intended use of the data
                                    collected. If the value of this parameter is `nil`, the
                                    default localized text is displayed.
 @param numberOfDisks               The number of disks in the puzzle; the default value for this property is 3.
 @param options                     Options that affect the features of the predefined task.
 
 @return An active device motion reaction time task that can be presented with an `ORK1TaskViewController` object.
 */
+ (ORK1OrderedTask *)towerOfHanoiTaskWithIdentifier:(NSString *)identifier
                            intendedUseDescription:(nullable NSString *)intendedUseDescription
                                     numberOfDisks:(NSUInteger)numberOfDisks
                                           options:(ORK1PredefinedTaskOption)options;

/**
 Returns a predefined task that consists of a timed walk.
 
 In a timed walk task, the participant is asked to walk for a specific distance as quickly as
 possible, but safely. The task is immediately administered again by having the patient walk back
 the same distance.
 A timed walk task can be used to measure lower extremity function.
 
 The presentation of the timed walk task differs from both the fitness check task and the short
 walk task in that the distance is fixed. After a first walk, the user is asked to turn and reverse
 direction.
 
 The data collected by this task can include accelerometer, device motion, pedometer data,
 and location where available.
 
 Data collected by the task is in the form of an `ORK1TimedWalkResult` object.
 
 @param identifier                  The task identifier to use for this task, appropriate to the study.
 @param intendedUseDescription      A localized string describing the intended use of the data
                                      collected. If the value of this parameter is `nil`, the default
                                      localized text is displayed.
 @param distanceInMeters            The timed walk distance in meters.
 @param timeLimit                   The time limit to complete the trials.
 @param includeAssistiveDeviceForm  A Boolean value that indicates whether to inlude the form step
                                      about the usage of an assistive device.
 @param options                     Options that affect the features of the predefined task.
 
 @return An active timed walk task that can be presented with an `ORK1TaskViewController` object.
 */
+ (ORK1OrderedTask *)timedWalkTaskWithIdentifier:(NSString *)identifier
                         intendedUseDescription:(nullable NSString *)intendedUseDescription
                               distanceInMeters:(double)distanceInMeters
                                      timeLimit:(NSTimeInterval)timeLimit
                     includeAssistiveDeviceForm:(BOOL)includeAssistiveDeviceForm
                                        options:(ORK1PredefinedTaskOption)options;

/**
 Returns a predefined task that consists of a timed walk, with a distinct turn around step.

 In a timed walk task, the participant is asked to walk for a specific distance as quickly as
 possible, but safely. Then the participant is asked to turn around. The task is immediately
 administered again by having the patient walk back the same distance.
 A timed walk task can be used to measure lower extremity function.

 The presentation of the timed walk task differs from both the fitness check task and the short
 walk task in that the distance is fixed. After a first walk, the user is asked to turn, then reverse
 direction.

 The data collected by this task can include accelerometer, device motion, pedometer data,
 and location where available.

 Data collected by the task is in the form of an `ORK1TimedWalkResult` object.

 @param identifier                  The task identifier to use for this task, appropriate to the study.
 @param intendedUseDescription      A localized string describing the intended use of the data
 collected. If the value of this parameter is `nil`, the default
 localized text is displayed.
 @param distanceInMeters            The timed walk distance in meters.
 @param timeLimit                   The time limit to complete the trials.
 @param turnAroundTimeLimit         The time limit to complete the turn around step.
 @param includeAssistiveDeviceForm  A Boolean value that indicates whether to inlude the form step
 about the usage of an assistive device.
 @param options                     Options that affect the features of the predefined task.

 @return An active timed walk task that can be presented with an `ORK1TaskViewController` object.
 */
+ (ORK1OrderedTask *)timedWalkTaskWithIdentifier:(NSString *)identifier
                         intendedUseDescription:(nullable NSString *)intendedUseDescription
                               distanceInMeters:(double)distanceInMeters
                                      timeLimit:(NSTimeInterval)timeLimit
                            turnAroundTimeLimit:(NSTimeInterval)turnAroundTimeLimit
                     includeAssistiveDeviceForm:(BOOL)includeAssistiveDeviceForm
                                        options:(ORK1PredefinedTaskOption)options;

/**
 Returns a predefined task that consists of the paced serial addition test (PSAT).
 
 In a PSAT task, the participant is asked to add a new digit to the one immediately before it
 every 2 or 3 seconds.
 
 A PSAT task can be used to measure the cognitive function that assesses auditory and/or
 visual information processing speed and flexibility, as well as calculation ability.
 
 Data collected by the task is in the form of an `ORK1PSATResult` object.
 
 @param identifier              The task identifier to use for this task, appropriate to the study.
 @param intendedUseDescription  A localized string describing the intended use of the data
                                  collected. If the value of this parameter is `nil`, the default
                                  localized text is displayed.
 @param presentationMode        The presentation mode of the PSAT test (auditory or visual or both).
 @param interStimulusInterval   The time interval between two digits presented.
 @param stimulusDuration        The time duration the digit is shown on screen (only for
                                    visual PSAT, that is PVSAT and PAVSAT).
 @param seriesLength            The number of digits that will be presented during the task.
 @param options                 Options that affect the features of the predefined task.
 
 @return An active PSAT task that can be presented with an `ORK1TaskViewController` object.
 
 */
+ (ORK1OrderedTask *)PSATTaskWithIdentifier:(NSString *)identifier
                    intendedUseDescription:(nullable NSString *)intendedUseDescription
                          presentationMode:(ORK1PSATPresentationMode)presentationMode
                     interStimulusInterval:(NSTimeInterval)interStimulusInterval
                          stimulusDuration:(NSTimeInterval)stimulusDuration
                              seriesLength:(NSInteger)seriesLength
                                   options:(ORK1PredefinedTaskOption)options;

/**
 Returns a predefined task that measures hand tremor.
 
 In a tremor assessment task, the participant is asked to hold the device with their most affected 
 hand in various positions while accelerometer and motion data are captured.
 
 @param identifier              The task identifier to use for this task, appropriate to the study.
 @param intendedUseDescription  A localized string describing the intended use of the data
                                  collected. If the value of this parameter is `nil`, the default
                                  localized text is displayed.
 @param activeStepDuration      The duration for each active step in the task.
 @param activeTaskOptions       Options that affect which active steps are presented for this task.
 @param handOptions             Options for determining which hand(s) to test.
 @param options                 Options that affect the features of the predefined task.
 
 @return An active tremor test task that can be presented with an `ORK1TaskViewController` object.
 */
+ (ORK1NavigableOrderedTask *)tremorTestTaskWithIdentifier:(NSString *)identifier
                                   intendedUseDescription:(nullable NSString *)intendedUseDescription
                                       activeStepDuration:(NSTimeInterval)activeStepDuration
                                        activeTaskOptions:(ORK1TremorActiveTaskOption)activeTaskOptions
                                              handOptions:(ORK1PredefinedTaskHandOption)handOptions
                                                  options:(ORK1PredefinedTaskOption)options;

/**
 Returns a predefined task that measures visual attention and task switching.
 
 In a trail making test, the participant is asked to connect a series of cicles labeled 1,2,3... or
 1,A,2,B,3,C... and time to complete the test is recorded.
 
 `ORK1TrailMakingTypeIdentifierA` uses the pattern: 1-2-3-4-5-6-7.
 `ORK1TrailMakingTypeIdentifierB` uses the pattern: 1-A-2-B-3-C-4-D-5-E-6-F-7
 
 @param identifier              The task identifier to use for this task, appropriate to the study.
 @param intendedUseDescription  A localized string describing the intended use of the data
                                  collected. If the value of this parameter is `nil`, the default
                                  localized text is displayed.
 @param trailmakingInstruction  Instructional content describing what the user needs to do when
                                  the task begins. If the value of this parameter is `nil`,
 @param trailType               Type of trail to display. Either `ORK1TrailMakingTypeIdentifierA` or `ORK1TrailMakingTypeIdentifierB`
 @param options                 Options that affect the features of the predefined task.
 
 @return An active trail making test task that can be presented with an `ORK1TaskViewController` object.
 */
+ (ORK1OrderedTask *)trailmakingTaskWithIdentifier:(NSString *)identifier
                           intendedUseDescription:(nullable NSString *)intendedUseDescription
                           trailmakingInstruction:(nullable NSString *)trailmakingInstruction
                                        trailType:(ORK1TrailMakingTypeIdentifier)trailType
                                          options:(ORK1PredefinedTaskOption)options;

@end

NS_ASSUME_NONNULL_END
