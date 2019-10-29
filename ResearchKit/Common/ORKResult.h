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
@import CoreLocation;
#import <ResearchKitLegacy/ORKTypes.h>


NS_ASSUME_NONNULL_BEGIN

@class ORKLegacyRecorder;
@class ORKLegacyStep;
@class ORKLegacyQuestionStep;
@class ORKLegacyFormItem;
@class ORKLegacyFormStep;
@class ORKLegacyConsentReviewStep;
@class ORKLegacyQuestionResult;
@class ORKLegacyConsentSignature;
@class ORKLegacyConsentDocument;
@class ORKLegacyConsentSignatureResult;
@class ORKLegacyStepResult;
@class ORKLegacyToneAudiometrySample;


/**
 The `ORKLegacyResult` class defines the attributes of a result from one step or a group
 of steps. When you use the ResearchKit framework APIs, you typically get a result from the `result` property
 of either `ORKLegacyTaskViewController` or `ORKLegacyStepViewController`.
 Certain types of results can contain other results, which together express a hierarchy; examples of these types of results are `ORKLegacyCollectionResult` subclasses, such as `ORKLegacyStepResult` and `ORKLegacyTaskResult`.
 
 When you receive a result, you can store it temporarily by archiving it with
 `NSKeyedArchiver`, because all `ORKLegacyResult` objects implement `NSSecureCoding`. If you want to serialize the result object to other formats, you're responsible for implementing this.
 
 The result object hierarchy does not necessarily include all the data collected
 during a task. Some result objects, such as `ORKLegacyFileResult`, may refer to files
 in the filesystem that were generated during the task. These files are easy to find, because they are all
 located in the output directory of the task view controller.
 
 It's recommended that you use `NSFileProtectionComplete` (at a minimum) to protect these files, and that you similarly protect all serialization of `ORKLegacyResult` objects that you write to disk. It is also generally helpful to keep the results together with the referenced files as you submit them to a back-end server. For example, it can be convenient to zip all data corresponding to a particular task result into a single compressed archive.
 
 Every object in the result hierarchy has an identifier that should correspond
 to the identifier of an object in the original step hierarchy. Similarly, every
 object has a start date and an end date that correspond to the range of
 times during which the result was collected. In an `ORKLegacyStepResult` object, for example,
 the start and end dates cover the range of time during which the step view controller was visible on
 screen.
 
 When you implement a new type of step, it is usually helpful to create a new
 `ORKLegacyResult` subclass to hold the type of result data the step can generate, unless it makes sense to use an existing subclass. Return your custom result subclass as one of the results attached to the step's `ORKLegacyStepResult` object.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyResult : NSObject <NSCopying, NSSecureCoding>

/**
 Returns an initialized result using the specified identifier.
 
 Typically, objects such as `ORKLegacyStepViewController` and `ORKLegacyTaskViewController` instantiate result (and `ORKLegacyResult` subclass) objects; you seldom need to instantiate a result object in your code.
 
 @param identifier     The unique identifier of the result.
 */
- (instancetype)initWithIdentifier:(NSString *)identifier;

/**
 A meaningful identifier for the result.
 
 The identifier can be used to identify the question
 that was asked or the task that was completed to produce the result. Typically, the identifier is copied from the originating object by the view controller or recorder that produces it.
 
 For example, a task result receives its identifier from a task,
 a step result receives its identifier from a step,
 and a question result receives its identifier from a step or a form item.
 Results that are generated by recorders also receive an identifier that corresponds to
 that recorder.
 */
@property (nonatomic, copy) NSString *identifier;

/**
 The time when the task, step, or data collection began.
 
 The value of this property is set by the view controller or recorder that produces the result,
 to indicate when data collection started.
 
 Note that for instantaneous items, `startDate` and `endDate` can have the same value, and should
 generally correspond to the end of the instantaneous data collection period.
 */
@property (nonatomic, copy) NSDate *startDate;

/**
 The time when the task, step, or data collection stopped.
 
 The value of this property is set by the view controller or recorder that produces the result,
 to indicate when data collection stopped.
 
 Note that for instantaneous items, `startDate` and `endDate` can have the same value, and should
 generally correspond to the end of the instantaneous data collection period. 
 */
@property (nonatomic, copy) NSDate *endDate;

/**
 Metadata that describes the conditions under which the result was acquired.
 
 The `userInfo` dictionary can be set by the view controller or recorder
 that produces the result. However, it's often a better choice to use a new `ORKLegacyResult` subclass for passing additional information back to code that uses
 the framework, because using
 typed accessors is safer than using a dictionary.
 
 The user info dictionary must contain only keys and values that are suitable for property
 list or JSON serialization.
 */
@property (nonatomic, copy, nullable) NSDictionary *userInfo;

@end


/**
 Values that identify the button that was tapped in a tapping sample.
 */
typedef NS_ENUM(NSInteger, ORKLegacyTappingButtonIdentifier) {

    /// The touch landed outside of the two buttons.
    ORKLegacyTappingButtonIdentifierNone,
    
    /// The touch landed in the left button.
    ORKLegacyTappingButtonIdentifierLeft,
    
    /// The touch landed in the right button.
    ORKLegacyTappingButtonIdentifierRight
} ORKLegacy_ENUM_AVAILABLE;

/**
 The `ORKLegacyTappingSample` class represents a single tap on a button.
 
 The tapping sample object records the location of the tap, the
 button that was tapped, and the time at which the event occurred. A tapping sample is
 included in an `ORKLegacyTappingIntervalResult` object, and is recorded by the
 step view controller for the corresponding task when a tap is
 recognized.
 
 A tapping sample is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize the sample for transmission to a server,
 or to immediately perform analysis on it.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyTappingSample : NSObject <NSCopying, NSSecureCoding>

/**
 A relative timestamp indicating the time of the tap event.
 
 The timestamp is relative to the value of `startDate` in the `ORKLegacyResult` object that includes this
 sample.
 */
@property (nonatomic, assign) NSTimeInterval timestamp;

/**
 A duration of the tap event.
 
 The duration store time interval between touch down and touch release events.
 */
@property (nonatomic, assign) NSTimeInterval duration;

/** 
 An enumerated value that indicates which button was tapped, if any.
 
 If the value of this property is `ORKLegacyTappingButtonIdentifierNone`, it indicates that the tap
 was near, but not inside, one of the target buttons.
 */
@property (nonatomic, assign) ORKLegacyTappingButtonIdentifier buttonIdentifier;

/**
 The location of the tap within the step's view.
 
 The location coordinates are relative to a rectangle whose size corresponds to
 the `stepViewSize` in the enclosing `ORKLegacyTappingIntervalResult` object.
 */
@property (nonatomic, assign) CGPoint location;

@end


/**
 The `ORKLegacyTappingIntervalResult` class records the results of a tapping interval test.
 
 The tapping interval result object records an array of touch samples (one for each tap) and also the geometry of the
 task at the time it was displayed. You can use the information in the object for reference in interpreting the touch
 samples.
 
 A tapping interval sample is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyTappingIntervalResult : ORKLegacyResult

/**
 An array of collected samples, in which each item is an `ORKLegacyTappingSample` object that represents a
 tapping event.
 */
@property (nonatomic, copy, nullable) NSArray<ORKLegacyTappingSample *> *samples;

/**
 The size of the bounds of the step view containing the tap targets.
 */
@property (nonatomic) CGSize stepViewSize;

/**
 The frame of the left button, in points, relative to the step view bounds.
 */
@property (nonatomic) CGRect buttonRect1;

/**
 The frame of the right button, in points, relative to the step view bounds.
 */
@property (nonatomic) CGRect buttonRect2;

@end


/**
 The `ORKLegacyPasscodeResult` class records the results of a passcode step.
 
 The passcode result object contains a boolean indicating whether the passcode was saved or not.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyPasscodeResult : ORKLegacyResult

/**
 A boolean indicating if a passcode was saved or not.
 */
@property (nonatomic, assign, getter=isPasscodeSaved) BOOL passcodeSaved;

/**
 A boolean that indicates if the user has enabled/disabled TouchID
 */
@property (nonatomic, assign, getter=isTouchIdEnabled) BOOL touchIdEnabled;

@end

/**
 The `ORKLegacyRangeOfMotionResult` class records the results of a range of motion active task.
 
 An `ORKLegacyRangeOfMotionResult` object records the flexion and extension values in degrees.
 */

ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyRangeOfMotionResult : ORKLegacyResult

/**
 The degrees when bent.
 */
@property (nonatomic, assign) double flexed;

/**
 The degrees when extended.
  */
@property (nonatomic, assign) double extended;

@end


/**
 The `ORKLegacyTowerOfHanoiResult` class records the results of a Tower of Hanoi active task.
 
 An `ORKLegacyTowerOfHanoiResult` object records an array of `ORKLegacyTowerOfHanoiMove` objects (one for each move)
 and a Boolean value representing whether the puzzle was solved or not.
 
 An `ORKLegacyTowerOfHanoiResult` object is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server
 or to immediately perform analysis on it.
 */
@class ORKLegacyTowerOfHanoiMove;

ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyTowerOfHanoiResult : ORKLegacyResult

/**
 A Boolean value indicating whether the puzzle was solved.
 
 The value of this property is `YES` when the puzzle was solved and `NO` otherwise.
 */
@property (nonatomic, assign) BOOL puzzleWasSolved;

/**
 An array of moves, in which each item is an `ORKLegacyTowerOfHanoiMove` object that represents a move.
 */
@property (nonatomic, copy, nullable) NSArray<ORKLegacyTowerOfHanoiMove *> *moves;

@end


/**
 The `ORKLegacyTowerOfHanoiMove` class represents a single move in a Tower of Hanoi puzzle.
 
 The Tower of Hanoi move object records the indexes of the donor and recipient towers
 and the time at which the event occurred. A `towerOfHanoiMove` instance is included in
 an `ORKLegacyTowerOfHanoiResult` object and is recorded by the step view controller for the
 corresponding task when a move is made.
 
 A Tower of Hanoi move is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize the move for transmission to a server,
 or to immediately perform analysis on it.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyTowerOfHanoiMove : NSObject <NSCopying, NSSecureCoding>

/**
 A relative timestamp indicating the time of the tap event. 
 
 The timestamp is relative to the value of `startDate` in the `ORKLegacyResult` object that includes this move.
 The start date of that object represents the time at which the first move was made.
 */
@property (nonatomic, assign) NSTimeInterval timestamp;

/**
 The index of the donor tower in the move.
 
 The Tower of Hanoi puzzle has three towers, and so the value of this property is
 therefore always 0, 1, or 2. The indexes sequentially represent the towers from left to right when they are laid out
 horizontally and from top to bottom when they are layed out vertically. The index for a given tower is consistent
 between changes to and from the horizontal and vertical layouts.
 */
@property (nonatomic,assign) NSUInteger donorTowerIndex;

/**
 The index of the recipient tower in the move. 
 
 The Tower of Hanoi puzzle has three towers, and so the value of this property is
 therefore always 0, 1, or 2. The indexes sequentially represent the towers from left to right when they are laid out
 horizontally and from top to bottom when they are layed out vertically. The index for a given tower is consistent
 between changes to and from the horizontal and vertical layouts.
 */
@property (nonatomic,assign) NSUInteger recipientTowerIndex;

@end


/**
 The `ORKLegacyToneAudiometryResult` class records the results of a tone audiometry test.

 The audiometry samples are generated by the framework when the task completes.
 It may be appropriate to serialize them for transmission to a server,
 or to immediately perform analysis on them.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyToneAudiometryResult : ORKLegacyResult

/**
 The system wide output volume set by the user during the audiometry test.

 A value in the range `0.0` to `1.0`, with `0.0` representing the minimum volume
 and `1.0` representing the maximum volume.
 */
@property (nonatomic, copy, nullable) NSNumber *outputVolume;

/**
 An array of collected samples, in which each item is an `ORKLegacyToneAudiometrySample`
 object that represents an audiometry sample.
 */
@property (nonatomic, copy, nullable) NSArray<ORKLegacyToneAudiometrySample *> *samples;

@end


/**
 The `ORKLegacyToneAudiometrySample` class represents an audio amplitude associated
 with a frequency and a channel.

 The sample object records the amplitude, the frequency, and the channel for the audio
 tone being played. A tone audiometry sample is included in an `ORKLegacyToneAudiometryResult`
 object, and is recorded by the step view controller for the corresponding task
 when a tap is recognized for a given tone.

 A tone audiometry sample is typically generated by the framework as the task proceeds.
 When the task completes, it may be appropriate to serialize the sample for
 transmission to a server or to immediately perform analysis on it.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyToneAudiometrySample : NSObject <NSCopying, NSSecureCoding>

/**
 The frequency value in hertz for the tone associated with the sample.
 */
@property (nonatomic, assign) double frequency;

/**
 
 The channel, either left or right, for the tone associated with the sample.
 */
@property (nonatomic, assign) ORKLegacyAudioChannel channel;

/**
 The channel selected by the user.
 */

@property (nonatomic, assign) ORKLegacyAudioChannel channelSelected;

/**
 The audio signal amplitude.

 The minimum audio sample amplitude needed for the participant to recognize the sound (a double value between 0 and 1).
 */
@property (nonatomic, assign) double amplitude;

@end


/**
 The `ORKLegacySpatialSpanMemoryGameTouchSample` class represents a tap during the
 spatial span memory game.
 
 A spatial span memory game touch sample is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacySpatialSpanMemoryGameTouchSample : NSObject <NSCopying, NSSecureCoding>

/**
 A timestamp (in seconds) from the beginning of the game.
 */
@property (nonatomic, assign) NSTimeInterval timestamp;

/**
 The index of the target that was tapped.
 
 Usually, this index is a value that ranges between 0 and the number of targets,
 indicating which target was tapped.
 
 If the touch was outside all of the targets, the value of this property is -1.
 */
@property (nonatomic, assign) NSInteger targetIndex;

/**
 A point that records the touch location in the step's view.
 */
@property (nonatomic, assign) CGPoint location;

/**
 A Boolean value indicating whether the tapped target was the correct one.
 
 The value of this property is `YES` when the tapped target is the correct
 one, and `NO` otherwise.
 */
@property (nonatomic, assign, getter=isCorrect) BOOL correct;

@end


/// An enumeration of values that describe the status of a round of the spatial span memory game.
typedef NS_ENUM(NSInteger, ORKLegacySpatialSpanMemoryGameStatus) {
    
    /// Unknown status. The game is still in progress or has not started.
    ORKLegacySpatialSpanMemoryGameStatusUnknown,
    
    /// Success. The user has completed the sequence.
    ORKLegacySpatialSpanMemoryGameStatusSuccess,
    
    /// Failure. The user has completed the sequence incorrectly.
    ORKLegacySpatialSpanMemoryGameStatusFailure,
    
    /// Timeout. The game timed out during play.
    ORKLegacySpatialSpanMemoryGameStatusTimeout
} ORKLegacy_ENUM_AVAILABLE;

/**
 The `ORKLegacySpatialSpanMemoryGameRecord` class records the results of a
 single playable instance of the spatial span memory game.
 
 A spatial span memory game record is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 
 These records are found in the `records` property of an `ORKLegacySpatialSpanMemoryResult` object.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacySpatialSpanMemoryGameRecord : NSObject <NSCopying, NSSecureCoding>

/**
 An integer used as the seed for the sequence.
 
 If you pass a specific seed value to another game, you get the same sequence.
 */
@property (nonatomic, assign) uint32_t seed;

/**
 An array of `NSNumber` objects that represent the sequence that was presented to the user.
 
 The sequence is an array of length `sequenceLength` that contains a random permutation of integers (0..`gameSize`-1)
 */
@property (nonatomic, copy, nullable) NSArray<NSNumber *> *sequence;

/**
 The size of the game.
 
 The game size is the number of targets, such as flowers, in the game.
 */
@property (nonatomic, assign) NSInteger gameSize;

/**
 An array of `NSValue` objects wrapped in `CGRect` that record the frames of the target
 tiles as displayed, relative to the step view.
 */
@property (nonatomic, copy, nullable) NSArray<NSValue *> *targetRects;

/**
 An array of `ORKLegacySpatialSpanMemoryGameTouchSample` objects that record the onscreen locations
the user tapped during the game.
 */
@property (nonatomic, copy, nullable) NSArray<ORKLegacySpatialSpanMemoryGameTouchSample *> *touchSamples;

/**
 A value indicating whether the user completed the sequence and, if the game was not completed, why not.
 */
@property (nonatomic, assign) ORKLegacySpatialSpanMemoryGameStatus gameStatus;

/**
 An integer that records the number of points obtained during this game toward
 the total score.
 */
@property (nonatomic, assign) NSInteger score;

@end


/**
 The `ORKLegacySpatialSpanMemoryResult` class represents the result of a spatial span memory step (`ORKLegacySpatialSpanMemoryStep`).
 
 A spatial span memory result records the score displayed to the user, the number of games, the
 objects recording the actual game, and the user's taps in response
 to the game.
 
 A spatial span memory result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacySpatialSpanMemoryResult : ORKLegacyResult

/**
 The score in the game.
 
 The score is an integer value that monotonically increases during the game, across multiple rounds.
 */
@property (nonatomic, assign) NSInteger score;

/**
 The number of games.
 
 The number of rounds that the user participated in, including successful,
 failed, and timed out rounds.
 */
@property (nonatomic, assign) NSInteger numberOfGames;

/**
 The number of failures.
 
 The number of rounds in which the user participated, but did not correctly
 complete the sequence.
 */
@property (nonatomic, assign) NSInteger numberOfFailures;

/**
 An array that contains the results of the games played.
 
 Each item in the array is an `ORKLegacySpatialSpanMemoryGameRecord` object.
 */
@property (nonatomic, copy, nullable) NSArray<ORKLegacySpatialSpanMemoryGameRecord *> *gameRecords;

@end


/**
 The `ORKLegacyFileResult` class is a result that references the location of a file produced
 during a task.
 
 A file result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize the linked file for transmission
 to the server.
 
 Active steps typically produce file results when CoreMotion or HealthKit are
 serialized to disk using a data logger (`ORKLegacyDataLogger`). Audio recording also produces a file
 result.
 
 When you write a custom step, use files to report results only when the data
 is likely to be too big to hold in memory for the duration of the task. For
 example, fitness tasks that use sensors can be quite long and can generate
 a large number of samples. To compensate for the length of the task, you can stream the samples to disk during
 the task, and return an `ORKLegacyFileResult` object in the result hierarchy, usually as a
 child of an `ORKLegacyStepResult` object.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyFileResult : ORKLegacyResult

/**
 The MIME content type of the result.
 
 For example, `@"application/json"`.
 */
@property (nonatomic, copy, nullable) NSString *contentType;

/**
 The URL of the file produced.
 
 It is the responsibility of the receiver of the result object to delete
 the file when it is no longer needed.
 
 The file is typically written to the output directory of the
 task view controller, so it is common to manage the archiving or cleanup
 of these files by archiving or deleting the entire output directory.
 */
@property (nonatomic, copy, nullable) NSURL *fileURL;

@end


/**
 The `ORKLegacyReactionTimeResult` class represents the result of a single successful attempt within an ORKLegacyReactionTimeStep.
 
 The `timestamp` property is equal to the value of systemUptime (in NSProcessInfo) when the stimulus occurred.
Each entry of motion data in this file contains a time interval which may be directly compared to timestamp in order to determine the elapsed time since the stimulus.
 
 The fileResult property references the motion data recorded from the beginning of the attempt until the threshold acceleration was reached.
Using the time taken to reach the threshold acceleration as the reaction time of a participant will yield a rather crude measurement. Rather, you should devise your own method using the data recorded to obtain an accurate approximation of the true reaction time.
 
 A reaction time result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize the sample for transmission to a server
 or to immediately perform analysis on it.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyReactionTimeResult: ORKLegacyResult

@property (nonatomic, assign) NSTimeInterval timestamp;

@property (nonatomic, strong) ORKLegacyFileResult *fileResult;

@end


/**
 The `ORKLegacyStroopResult` class represents the result of a single successful attempt within an ORKLegacyStroopStep.
 
 A stroop result is typically generated by the framework as the task proceeds. When the task completes, it may be appropriate to serialize the sample for transmission to a server or to immediately perform analysis on it.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyStroopResult: ORKLegacyResult

/**
 The `startTime` property is equal to the start time of the each step.
 */
@property (nonatomic, assign) NSTimeInterval startTime;

/**
  The `endTime` property is equal to the timestamp when user answers a particular step by selecting a color.
 */
@property (nonatomic, assign) NSTimeInterval endTime;

/**
 The `color` property is the color of the question string.
 */
@property (nonatomic, copy) NSString *color;

/**
 The `text` property is the text of the question string.
 */
@property (nonatomic, copy) NSString *text;

/**
 The `colorSelected` corresponds to the button tapped by the user as an answer.
 */
@property (nonatomic, copy, nullable) NSString *colorSelected;

@end

/**
 The `ORKLegacyPSATResult` class records the results of a PSAT test.
 
 The PSAT result object records the initial digit, an array of addition samples, the total of correct answers
 and also various attributes of the PSAT test.
 
 The PSAT samples are generated by the framework as the task proceeds.
 When the task completes, it may be appropriate to serialize them for transmission to a server,
 or to immediately perform analysis on them.
 */
@class ORKLegacyPSATSample;

ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyPSATResult : ORKLegacyResult

/**
 The PSAT presentation mode.
 */
@property (nonatomic, assign) ORKLegacyPSATPresentationMode presentationMode;

/**
 The time interval between two digits presented.
 PSAT-2" is 2 seconds; PSAT-3" is 3 seconds.
 */
@property (nonatomic, assign) NSTimeInterval interStimulusInterval;

/**
 The amount of time a digit is shown on the screen (0 second for PASAT).
 */
@property (nonatomic, assign) NSTimeInterval stimulusDuration;

/**
 The length of the series, that is, the number of additions.
 */
@property (nonatomic, assign) NSInteger length;

/**
 The number of correct sums given (out of 'length' possible ones).
 */
@property (nonatomic, assign) NSInteger totalCorrect;

/**
 The number of consecutive correct answers (out of 'length - 1' possible ones).
 Used to overcome the alternate answer strategy.
 */
@property (nonatomic, assign) NSInteger totalDyad;

/**
 The total time needed to answer all additions (that is, the sum of all the samples times).
 */
@property (nonatomic, assign) NSTimeInterval totalTime;

/**
 The initial digit.
 */
@property (nonatomic, assign) NSInteger initialDigit;

/**
 An array of collected samples, in which each item is an `ORKLegacyPSATSample`
 object that represents an addition sample.
 */
@property (nonatomic, copy, nullable) NSArray<ORKLegacyPSATSample *> *samples;

@end


/**
 The `ORKLegacyPSATSample` class represents a numeric answer to an addition question.
 If the answer is correct, the sample object records the presented digit and the numeric answer.
 A PSAT sample is included in an `ORKLegacyPSATResult` object and is recorded
 by the step view controller for the corresponding task.
 
 A PSAT sample is typically generated by the framework as the task proceeds.
 When the task completes, it may be appropriate to serialize the sample for
 transmission to a server, or to immediately perform analysis on it.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyPSATSample : NSObject <NSCopying, NSSecureCoding>

/**
 A Boolean value indicating whether the addition answer was the correct one.
 
 The value of this property is `YES` when the addition result is the correct
 one, and `NO` otherwise.
 */
@property (nonatomic, assign, getter=isCorrect) BOOL correct;

/**
 The presented digit.
 */
@property (nonatomic, assign) NSInteger digit;

/**
 The numeric answer;
 `-1` if no answer is provided.
 */
@property (nonatomic, assign) NSInteger answer;

/**
 The time interval between the new digit and the answer, or test duration if no answer is provided.
 */
@property (nonatomic, assign) NSTimeInterval time;

@end


/**
 The `ORKLegacyHolePegTestResult` class records the results of a hole peg test.
 
 The hole peg test result object records the number of pegs, an array of move samples, the total duration
 and also various attributes of the hole peg test.
 
 The hole peg test samples are generated by the framework as the task proceeds.
 When the task completes, it may be appropriate to serialize them for transmission to a server,
 or to immediately perform analysis on them.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyHolePegTestResult : ORKLegacyResult

/**
 The hole peg test moving direction.
 */
@property (nonatomic, assign) ORKLegacyBodySagittal movingDirection;

/**
 The step is for the dominant hand.
 */
@property (nonatomic, assign, getter = isDominantHandTested) BOOL dominantHandTested;

/**
 The number of pegs to test.
 */
@property (nonatomic, assign) NSInteger numberOfPegs;

/**
 The detection area sensitivity.
 */
@property (nonatomic, assign) double threshold;

/**
 The hole peg test also assesses the rotation capabilities.
 */
@property (nonatomic, assign, getter = isRotated) BOOL rotated;

/**
 The number of succeeded moves (out of `numberOfPegs` possible).
 */
@property (nonatomic, assign) NSInteger totalSuccesses;

/**
 The number of failed moves.
 */
@property (nonatomic, assign) NSInteger totalFailures;

/**
 The total time needed to perform the test step (ie. the sum of all samples time).
 */
@property (nonatomic, assign) NSTimeInterval totalTime;

/**
 The total distance needed to perform the test step (ie. the sum of all samples distance).
 */
@property (nonatomic, assign) double totalDistance;

/**
 An array of collected samples, in which each item is an `ORKLegacyHolePegTestSample`
 object that represents a peg move.
 */
@property (nonatomic, copy, nullable) NSArray *samples;

@end


/**
 The `ORKLegacyHolePegTestSample` class represents a peg move.
 
 The sample object records the duration, and the move distance.
 An hole peg test is included in an `ORKLegacyHolePegTestResult` object, and is recorded
 by the step view controller for the corresponding task.
 
 An hole peg test sample is typically generated by the framework as the task proceeds.
 When the task completes, it may be appropriate to serialize the sample for
 transmission to a server, or to immediately perform analysis on it.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyHolePegTestSample : NSObject <NSCopying, NSSecureCoding>

/**
 The time interval for the peg move.
 */
@property (nonatomic, assign) NSTimeInterval time;

/**
 The peg move distance.
 */
@property (nonatomic, assign) double distance;

@end


/**
 The `ORKLegacyQuestionResult` class is the base class for leaf results from an item that uses an answer format (`ORKLegacyAnswerFormat`).
 
 A question result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 
 See also: `ORKLegacyQuestionStep` and `ORKLegacyFormItem`.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyQuestionResult : ORKLegacyResult

/**
 A value that indicates the type of question the result came from.
 
 The value of `questionType` generally correlates closely with the class, but it can be
 easier to use this value in a switch statement in Objective-C.
 */
@property (nonatomic) ORKLegacyQuestionType questionType;

@end


/**
 The `ORKLegacyScaleQuestionResult` class represents the answer to a continuous or
 discrete-value scale answer format.
 
 A scale question result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyScaleQuestionResult : ORKLegacyQuestionResult

/**
 The answer obtained from the scale question.
 
 The value of this property is `nil` when the user skipped the question or otherwise did not
 enter an answer.
 */
@property (nonatomic, copy, nullable) NSNumber *scaleAnswer;

@end


/**
 The `ORKLegacyChoiceQuestionResult` class represents the single or multiple choice
 answers from a choice-based answer format.
 
 For example, an `ORKLegacyTextChoiceAnswerFormat` or an `ORKLegacyImageChoiceAnswerFormat`
 format produces an `ORKLegacyChoiceQuestionResult` object.
 
 A choice question result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyChoiceQuestionResult : ORKLegacyQuestionResult

/**
 An array of selected values, from the `value` property of an `ORKLegacyTextChoice` or `ORKLegacyImageChoice` object.
 In the case of a single choice, the array has exactly one entry.
 
 If the user skipped the question, the value of the corresponding array member is `nil`.
 */
@property (nonatomic, copy, nullable) NSArray *choiceAnswers;

@end

/**
 The `ORKLegacyMultipleComponentQuestionResult` class represents the choice
 answers from a multiple-component picker-style choice-based answer format.
 
 For example, an `ORKLegacyMultipleValuePickerAnswerFormat` produces an `ORKLegacyMultipleComponentQuestionResult` object.
 
 A multiple component question result is typically generated by the framework as the task proceeds. 
 When the task completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyMultipleComponentQuestionResult : ORKLegacyQuestionResult

/**
 An array of selected components, from the `value` property of an `ORKLegacyTextChoice` object.
 The array will have the same count as the number of components.
 
 If the user skipped the question, the value of the corresponding array member is `nil`.
 */
@property (nonatomic, copy, nullable) NSArray *componentsAnswer;

/**
 The string separator used to join the components (if applicable)
 */
@property (nonatomic, copy, nullable) NSString *separator;


@end


/**
 The `ORKLegacyBooleanQuestionResult` class represents the answer to a Yes/No question.
 
 A Boolean question result is produced by the task view controller when it presents a question or form
 item with a Boolean answer format (that is, `ORKLegacyBooleanAnswerFormat`).
 
 A Boolean question result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyBooleanQuestionResult : ORKLegacyQuestionResult

/** The answer, or `nil` if the user skipped the question. */
@property (nonatomic, copy, nullable) NSNumber *booleanAnswer;

@end


/**
 The `ORKLegacyTimedWalkResult` class records the results of a Timed Walk test.
 
 The timed walk result object records the duration to complete the trial with a specific distance
 and time limit.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyTimedWalkResult : ORKLegacyResult
/**
 The timed walk distance in meters.
 */
@property (nonatomic, assign) double distanceInMeters;

/**
 The time limit to complete the trials.
 */
@property (nonatomic, assign) NSTimeInterval timeLimit;

/**
 The trial duration (that is, the time taken to do the walk).
 */
@property (nonatomic, assign) NSTimeInterval duration;

@end


/**
 The `ORKLegacyTextQuestionResult` class represents the answer to a question or
 form item that uses an `ORKLegacyTextAnswerFormat` format.
 
 A text question result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server
 or to immediately perform analysis on it.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyTextQuestionResult : ORKLegacyQuestionResult

/** 
 The answer that the user entered.
 
 If the user skipped the question, the value of this property is `nil`.
 */
@property (nonatomic, copy, nullable) NSString *textAnswer;

@end


/**
 The `ORKLegacyNumericQuestionResult` class represents a question or form item that uses an answer format that produces a numeric answer.
 
 Examples of this type of answer format include `ORKLegacyScaleAnswerFormat` and `ORKLegacyNumericAnswerFormat`.
 
 A numeric question result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyNumericQuestionResult : ORKLegacyQuestionResult

/// The number collected, or `nil` if the user skipped the question.
@property (nonatomic, copy, nullable) NSNumber *numericAnswer;

/**
 The unit string displayed to the user when the value was entered, or `nil` if no unit string was displayed.
 */
@property (nonatomic, copy, nullable) NSString *unit;

@end


/**
 The `ORKLegacyTimeOfDayQuestionResult` class represents the result of a question that uses the `ORKLegacyTimeOfDayAnswerFormat` format.
 */

ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyTimeOfDayQuestionResult : ORKLegacyQuestionResult

/**
 The date components picked by the user.
 
 Typically only hour, minute, and AM/PM data are of interest.
 */
@property (nonatomic, copy, nullable) NSDateComponents *dateComponentsAnswer;

@end


/**
 The `ORKLegacyTimeIntervalQuestionResult` class represents the result of a question
 that uses the `ORKLegacyTimeIntervalAnswerFormat` format.
 
 A time interval question result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyTimeIntervalQuestionResult : ORKLegacyQuestionResult

/**
 The selected interval, in seconds.
 
 The value of this property is `nil` if the user skipped the question.
 */
@property (nonatomic, copy, nullable) NSNumber *intervalAnswer;

@end


/**
 The `ORKLegacyDateQuestionResult` class represents the result of a question or form item that asks for a date (`ORKLegacyDateAnswerFormat`).
 
 The calendar and time zone are recorded in addition to the answer itself,
 to give the answer context. Usually, this data corresponds to the current calendar
 and time zone at the time of the activity, but it can be overridden by setting
 these properties explicitly in the `ORKLegacyDateAnswerFormat` object.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyDateQuestionResult : ORKLegacyQuestionResult

/**
 The date that the user entered, or `nil` if the user skipped the question.
 */
@property (nonatomic, copy, nullable) NSDate *dateAnswer;

/**
 The calendar used when selecting date and time.
 
 If the calendar in the `ORKLegacyDateAnswerFormat` object is `nil`, this calendar is the system
 calendar at the time of data entry.
 */
@property (nonatomic, copy, nullable) NSCalendar *calendar;

/**
 The time zone that was current when selecting the date and time.
 */
@property (nonatomic, copy, nullable) NSTimeZone *timeZone;

@end


/**
 The `ORKLegacyConsentSignatureResult` class represents a signature obtained during
 a consent review step (`ORKLegacyConsentReviewStep`). The consent signature result is usually found as a child result of the
 `ORKLegacyStepResult` object for the consent review step.
 
 You can apply the result to a document to facilitate the generation of a
 PDF including the signature, or for presentation in a follow-on
 consent review.
 
 A consent signature result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyConsentSignatureResult : ORKLegacyResult

/**
 A copy of the signature obtained.
 
 The signature is a copy of the `signature` property in the originating
 `ORKLegacyConsentReviewStep` object, but also includes any name or signature image collected during
 the consent review step.
 */
@property (nonatomic, copy, nullable) ORKLegacyConsentSignature *signature;

/**
 A boolean value indicating whether the participant consented.
 
 `YES` if the user confirmed consent to the contents of the consent review. Note
 that the signature could still be invalid if the name or signature image is
 empty; this indicates only that the user gave a positive acknowledgement of the
 document.
 */
@property (nonatomic, assign) BOOL consented;

/**
 Applies the signature to the consent document.
 
 This method uses the identifier to look up the matching signature placeholder
 in the consent document and replaces it with this signature. It may throw an exception if
 the document does not contain a signature with a matching identifier.
 
 @param document     The document to which to apply the signature.
 */
- (void)applyToDocument:(ORKLegacyConsentDocument *)document;

@end


/**
 The `ORKLegacyCollectionResult` class represents a result that contains an array of
 child results.
 
 `ORKLegacyCollectionResult` is the superclass of `ORKLegacyTaskResult` and `ORKLegacyStepResult`.
 
 Note that object of this class are not instantiated directly by the ResearchKit framework.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyCollectionResult : ORKLegacyResult

/**
 An array of `ORKLegacyResult` objects that are the children of the result.
 
 For `ORKLegacyTaskResult`, the array contains `ORKLegacyStepResult` objects.
 For `ORKLegacyStepResult` the array contains concrete result objects such as `ORKLegacyFileResult`
 and `ORKLegacyQuestionResult`.
 */
@property (nonatomic, copy, nullable) NSArray<ORKLegacyResult *> *results;

/**
 Looks up the child result containing an identifier that matches the specified identifier.
 
 @param identifier The identifier of the step for which to search.
 
 @return The matching result, or `nil` if none was found.
 */
- (nullable ORKLegacyResult *)resultForIdentifier:(NSString *)identifier;

/**
 The first result.
 
 This is the first result, or `nil` if there are no results.
 */
@property (nonatomic, strong, readonly, nullable) ORKLegacyResult *firstResult;

@end


/**
 `ORKLegacyTaskResultSource` is the protocol for `[ORKLegacyTaskViewController defaultResultSource]`.
 */
@protocol ORKLegacyTaskResultSource <NSObject>

/**
 Returns a step result for the specified step identifier, if one exists.
 
 When it's about to present a step, the task view controller needs to look up a
 suitable default answer. The answer can be used to prepopulate a survey with
 the results obtained on a previous run of the same task, by passing an
 `ORKLegacyTaskResult` object (which itself implements this protocol).
 
 @param stepIdentifier The identifier for which to search.
 
 @return The result for the specified step, or `nil` for none.
 */
- (nullable ORKLegacyStepResult *)stepResultForStepIdentifier:(NSString *)stepIdentifier;

/**
 Should the default result store be used even if there is a previous result? (due to 
 reverse navigation or looping)
 
 By default, the `[ORKLegacyTaskViewController defaultResultSource]` is only queried for a 
 result if the previous result is nil. This allows the result source to override that
 default behavior.
 
 @return `YES` if the default result should be given priority over the previous result.
 */
@optional
- (BOOL)alwaysCheckForDefaultResult;

@end


/**
 An `ORKLegacyTaskResult` object is a collection result that contains all the step results
 generated from one run of a task or ordered task (that is, `ORKLegacyTask` or `ORKLegacyOrderedTask`) in a task view controller.
 
 A task result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 
 The `results` property of the `ORKLegacyCollectionResult` object contains the step results
 for the task.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyTaskResult : ORKLegacyCollectionResult <ORKLegacyTaskResultSource>

/**
 Returns an intialized task result using the specified identifiers and directory.
 
 @param identifier      The identifier of the task that produced this result.
 @param taskRunUUID     The UUID of the run of the task that produced this result.
 @param outputDirectory The directory in which any files referenced by results can be found.
 
 @return An initialized task result.
 */
- (instancetype)initWithTaskIdentifier:(NSString *)identifier
                           taskRunUUID:(NSUUID *)taskRunUUID
                       outputDirectory:(nullable NSURL *)outputDirectory;

/**
 A unique identifier (UUID) for the presentation of the task that generated
 the result.
 
 The unique identifier for a run of the task typically comes directly
 from the task view controller that was used to run the task.
 */
@property (nonatomic, copy, readonly) NSUUID *taskRunUUID;

/**
 The directory in which the generated data files were stored while the task was run.
 
 The directory comes directly from the task view controller that was used to run this
 task. Generally, when archiving the results of a task, it is useful to archive
 all the files found in the output directory.
 
 The file URL also prefixes the file URLs referenced in any child
 `ORKLegacyFileResult` objects.
 */
@property (nonatomic, copy, readonly, nullable) NSURL *outputDirectory;

@end


/**
 The `ORKLegacyStepResult` class represents a collection result produced by a step view controller to
 hold all child results produced by the step.
 
 A step result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 
 For example, an `ORKLegacyQuestionStep` object produces an `ORKLegacyQuestionResult` object that becomes
 a child of the `ORKLegacyStepResult` object. Similarly, an `ORKLegacyActiveStep` object may produce individual
 child result objects for each of the recorder configurations that was active
 during that step.
 
 The `results` property of the `ORKLegacyCollectionResult` object contains the step results
 for the task.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyStepResult : ORKLegacyCollectionResult


/**
 Returns an initialized step result using the specified identifier.
 
 @param stepIdentifier      The identifier of the step.
 @param results             The array of child results. The value of this parameter can be `nil` or empty
            if no results were collected.
 
 @return An initialized step result.
 */
- (instancetype)initWithStepIdentifier:(NSString *)stepIdentifier results:(nullable NSArray<ORKLegacyResult *> *)results;

/**
 This property indicates whether the Voice Over or Switch Control assistive technologies were active
 while performing the corresponding step.
 
 This information can be used, for example, to take into consideration the extra time needed by
 handicapped participants to complete some tasks, such as the Tower of Hanoi activity.
 
 The property can have the following values:
 - `UIAccessibilityNotificationVoiceOverIdentifier` if Voice Over was active
 - `UIAccessibilityNotificationSwitchControlIdentifier` if Switch Control was active
 
 Note that the Voice Over and Switch Control assistive technologies are mutually exclusive.
 
 If the property is `nil`, none of these assistive technologies was used.
 */
@property (nonatomic, copy, readonly, nullable) NSString *enabledAssistiveTechnology;

@end


/**
 The `ORKLegacyLocation` class represents the location addess obtained from a locaton question.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyLocation : NSObject <NSCopying, NSSecureCoding>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 The geographical coordinate information.
 */
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

/**
 The region describes the size of the placemark of the location.
 */
@property (nonatomic, copy, readonly, nullable) CLCircularRegion *region;

/**
 The human readable address typed in by user.
 */
@property (nonatomic, copy, readonly, nullable) NSString *userInput;

/**
 The address dicitonary for this coordinate from MapKit.
 */
@property (nonatomic, copy, readonly, nullable) NSDictionary *addressDictionary;

@end


/**
 The `ORKLegacyLocationQuestionResult` class represents the result of a question or form item that asks for a location (`ORKLegacyLocationAnswerFormat`).
 
 A Location question result is produced by the task view controller when it presents a question or form
 item with a Location answer format (that is, `ORKLegacyLocationAnswerFormat`).
 
 A Location question result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyLocationQuestionResult : ORKLegacyQuestionResult

/**
 The answer representing the coordinate and the address of a specific location.
 */
@property (nonatomic, copy, nullable) ORKLegacyLocation *locationAnswer;

@end

/**
 The `ORKLegacySignatureResult` class represents the result of a signature step (`ORKLegacySignatureStep`).
 
 A signature result is produced by the task view controller when it presents a signature step.

 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacySignatureResult : ORKLegacyResult

/**
 The signature image generated by this step.
 */
@property (nonatomic, nullable) UIImage *signatureImage;

/**
 The bezier path components used to create the signature image.
 */
@property (nonatomic, copy, nullable) NSArray <UIBezierPath *> *signaturePath;

@end


/**
 The `ORKLegacyTrailmakingTap` class represents a single tap in a trail making test.
 
 The Trailmaking tap move object records the indexes of tap, if it was in error or not
 and the time at which the event occurred. A `trailmakingTap` instance is included in
 an `ORKLegacyTrailmakingResult` object and is recorded by the step view controller for the
 corresponding task when a tap is made.
 
 A trail making tap is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize the move for transmission to a server,
 or to immediately perform analysis on it.
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyTrailmakingTap : NSObject <NSCopying, NSSecureCoding>

/**
 A relative timestamp indicating the time of the tap event.
 
 The timestamp is relative to the value of `startDate` in the `ORKLegacyResult` object that includes this move.
 The start date of that object represents the time at which the first move was made.
 */
@property (nonatomic, assign) NSTimeInterval timestamp;

/**
 The index of the button tapped.
 */
@property (nonatomic,assign) NSUInteger index;

/**
 If the button was tapped in error.
 */
@property (nonatomic, assign) BOOL incorrect;

@end


/**
 The `ORKLegacyTrailmakingResult` class represents the result of a signature step (`ORKLegacyTrailmakingStep`).
 
 
 A trail making result is produced by the task view controller when it presents a trail making step.
 
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyTrailmakingResult : ORKLegacyResult

/** 
 An array of all taps completed during the test
 */
@property (nonatomic, copy) NSArray <ORKLegacyTrailmakingTap *> *taps;

/** 
 The number of errors generated during the test
 */
@property (nonatomic) NSUInteger numberOfErrors;

@end


/**
 The `ORKLegacyVideoInstructionStepResult` class represents the result of a video insruction step (`ORKLegacyVideoInstructionStep`).
 
 A video instruction result is produced by the task view controller when it presents a video instruction step.
 
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyVideoInstructionStepResult : ORKLegacyResult

/**
 The time (in seconds) after video playback stopped, or NaN if the video was never played.
 */
@property (nonatomic) Float64 playbackStoppedTime;

/**
 Returns 'YES' if the video was watched until the end, or 'NO' if video playback was stopped half way.
 */
@property (nonatomic) BOOL playbackCompleted;

@end


/**
 The `ORKLegacyWebViewStepResult` class represents the result of a web view step (`ORKLegacyWebViewStep`).
 
 A web view result is produced by the task view controller when it presents a web view step.
 
 */
ORKLegacy_CLASS_AVAILABLE
@interface ORKLegacyWebViewStepResult : ORKLegacyResult

/**
 The answer produced by the webview.
 */
@property (nonatomic, nullable) NSString* result;

@end

NS_ASSUME_NONNULL_END
