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
#import <ResearchKit/ORK1Types.h>


NS_ASSUME_NONNULL_BEGIN

@class ORK1Recorder;
@class ORK1Step;
@class ORK1QuestionStep;
@class ORK1FormItem;
@class ORK1FormStep;
@class ORK1ConsentReviewStep;
@class ORK1QuestionResult;
@class ORK1ConsentSignature;
@class ORK1ConsentDocument;
@class ORK1ConsentSignatureResult;
@class ORK1StepResult;
@class ORK1ToneAudiometrySample;


/**
 The `ORK1Result` class defines the attributes of a result from one step or a group
 of steps. When you use the ResearchKit framework APIs, you typically get a result from the `result` property
 of either `ORK1TaskViewController` or `ORK1StepViewController`.
 Certain types of results can contain other results, which together express a hierarchy; examples of these types of results are `ORK1CollectionResult` subclasses, such as `ORK1StepResult` and `ORK1TaskResult`.
 
 When you receive a result, you can store it temporarily by archiving it with
 `NSKeyedArchiver`, because all `ORK1Result` objects implement `NSSecureCoding`. If you want to serialize the result object to other formats, you're responsible for implementing this.
 
 The result object hierarchy does not necessarily include all the data collected
 during a task. Some result objects, such as `ORK1FileResult`, may refer to files
 in the filesystem that were generated during the task. These files are easy to find, because they are all
 located in the output directory of the task view controller.
 
 It's recommended that you use `NSFileProtectionComplete` (at a minimum) to protect these files, and that you similarly protect all serialization of `ORK1Result` objects that you write to disk. It is also generally helpful to keep the results together with the referenced files as you submit them to a back-end server. For example, it can be convenient to zip all data corresponding to a particular task result into a single compressed archive.
 
 Every object in the result hierarchy has an identifier that should correspond
 to the identifier of an object in the original step hierarchy. Similarly, every
 object has a start date and an end date that correspond to the range of
 times during which the result was collected. In an `ORK1StepResult` object, for example,
 the start and end dates cover the range of time during which the step view controller was visible on
 screen.
 
 When you implement a new type of step, it is usually helpful to create a new
 `ORK1Result` subclass to hold the type of result data the step can generate, unless it makes sense to use an existing subclass. Return your custom result subclass as one of the results attached to the step's `ORK1StepResult` object.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1Result : NSObject <NSCopying, NSSecureCoding>

/**
 Returns an initialized result using the specified identifier.
 
 Typically, objects such as `ORK1StepViewController` and `ORK1TaskViewController` instantiate result (and `ORK1Result` subclass) objects; you seldom need to instantiate a result object in your code.
 
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
 that produces the result. However, it's often a better choice to use a new `ORK1Result` subclass for passing additional information back to code that uses
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
typedef NS_ENUM(NSInteger, ORK1TappingButtonIdentifier) {

    /// The touch landed outside of the two buttons.
    ORK1TappingButtonIdentifierNone,
    
    /// The touch landed in the left button.
    ORK1TappingButtonIdentifierLeft,
    
    /// The touch landed in the right button.
    ORK1TappingButtonIdentifierRight
} ORK1_ENUM_AVAILABLE;

/**
 The `ORK1TappingSample` class represents a single tap on a button.
 
 The tapping sample object records the location of the tap, the
 button that was tapped, and the time at which the event occurred. A tapping sample is
 included in an `ORK1TappingIntervalResult` object, and is recorded by the
 step view controller for the corresponding task when a tap is
 recognized.
 
 A tapping sample is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize the sample for transmission to a server,
 or to immediately perform analysis on it.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1TappingSample : NSObject <NSCopying, NSSecureCoding>

/**
 A relative timestamp indicating the time of the tap event.
 
 The timestamp is relative to the value of `startDate` in the `ORK1Result` object that includes this
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
 
 If the value of this property is `ORK1TappingButtonIdentifierNone`, it indicates that the tap
 was near, but not inside, one of the target buttons.
 */
@property (nonatomic, assign) ORK1TappingButtonIdentifier buttonIdentifier;

/**
 The location of the tap within the step's view.
 
 The location coordinates are relative to a rectangle whose size corresponds to
 the `stepViewSize` in the enclosing `ORK1TappingIntervalResult` object.
 */
@property (nonatomic, assign) CGPoint location;

@end


/**
 The `ORK1TappingIntervalResult` class records the results of a tapping interval test.
 
 The tapping interval result object records an array of touch samples (one for each tap) and also the geometry of the
 task at the time it was displayed. You can use the information in the object for reference in interpreting the touch
 samples.
 
 A tapping interval sample is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1TappingIntervalResult : ORK1Result

/**
 An array of collected samples, in which each item is an `ORK1TappingSample` object that represents a
 tapping event.
 */
@property (nonatomic, copy, nullable) NSArray<ORK1TappingSample *> *samples;

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
 The `ORK1PasscodeResult` class records the results of a passcode step.
 
 The passcode result object contains a boolean indicating whether the passcode was saved or not.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1PasscodeResult : ORK1Result

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
 The `ORK1RangeOfMotionResult` class records the results of a range of motion active task.
 
 An `ORK1RangeOfMotionResult` object records the flexion and extension values in degrees.
 */

ORK1_CLASS_AVAILABLE
@interface ORK1RangeOfMotionResult : ORK1Result

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
 The `ORK1TowerOfHanoiResult` class records the results of a Tower of Hanoi active task.
 
 An `ORK1TowerOfHanoiResult` object records an array of `ORK1TowerOfHanoiMove` objects (one for each move)
 and a Boolean value representing whether the puzzle was solved or not.
 
 An `ORK1TowerOfHanoiResult` object is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server
 or to immediately perform analysis on it.
 */
@class ORK1TowerOfHanoiMove;

ORK1_CLASS_AVAILABLE
@interface ORK1TowerOfHanoiResult : ORK1Result

/**
 A Boolean value indicating whether the puzzle was solved.
 
 The value of this property is `YES` when the puzzle was solved and `NO` otherwise.
 */
@property (nonatomic, assign) BOOL puzzleWasSolved;

/**
 An array of moves, in which each item is an `ORK1TowerOfHanoiMove` object that represents a move.
 */
@property (nonatomic, copy, nullable) NSArray<ORK1TowerOfHanoiMove *> *moves;

@end


/**
 The `ORK1TowerOfHanoiMove` class represents a single move in a Tower of Hanoi puzzle.
 
 The Tower of Hanoi move object records the indexes of the donor and recipient towers
 and the time at which the event occurred. A `towerOfHanoiMove` instance is included in
 an `ORK1TowerOfHanoiResult` object and is recorded by the step view controller for the
 corresponding task when a move is made.
 
 A Tower of Hanoi move is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize the move for transmission to a server,
 or to immediately perform analysis on it.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1TowerOfHanoiMove : NSObject <NSCopying, NSSecureCoding>

/**
 A relative timestamp indicating the time of the tap event. 
 
 The timestamp is relative to the value of `startDate` in the `ORK1Result` object that includes this move.
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
 The `ORK1ToneAudiometryResult` class records the results of a tone audiometry test.

 The audiometry samples are generated by the framework when the task completes.
 It may be appropriate to serialize them for transmission to a server,
 or to immediately perform analysis on them.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1ToneAudiometryResult : ORK1Result

/**
 The system wide output volume set by the user during the audiometry test.

 A value in the range `0.0` to `1.0`, with `0.0` representing the minimum volume
 and `1.0` representing the maximum volume.
 */
@property (nonatomic, copy, nullable) NSNumber *outputVolume;

/**
 An array of collected samples, in which each item is an `ORK1ToneAudiometrySample`
 object that represents an audiometry sample.
 */
@property (nonatomic, copy, nullable) NSArray<ORK1ToneAudiometrySample *> *samples;

@end


/**
 The `ORK1ToneAudiometrySample` class represents an audio amplitude associated
 with a frequency and a channel.

 The sample object records the amplitude, the frequency, and the channel for the audio
 tone being played. A tone audiometry sample is included in an `ORK1ToneAudiometryResult`
 object, and is recorded by the step view controller for the corresponding task
 when a tap is recognized for a given tone.

 A tone audiometry sample is typically generated by the framework as the task proceeds.
 When the task completes, it may be appropriate to serialize the sample for
 transmission to a server or to immediately perform analysis on it.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1ToneAudiometrySample : NSObject <NSCopying, NSSecureCoding>

/**
 The frequency value in hertz for the tone associated with the sample.
 */
@property (nonatomic, assign) double frequency;

/**
 
 The channel, either left or right, for the tone associated with the sample.
 */
@property (nonatomic, assign) ORK1AudioChannel channel;

/**
 The channel selected by the user.
 */

@property (nonatomic, assign) ORK1AudioChannel channelSelected;

/**
 The audio signal amplitude.

 The minimum audio sample amplitude needed for the participant to recognize the sound (a double value between 0 and 1).
 */
@property (nonatomic, assign) double amplitude;

@end


/**
 The `ORK1SpatialSpanMemoryGameTouchSample` class represents a tap during the
 spatial span memory game.
 
 A spatial span memory game touch sample is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1SpatialSpanMemoryGameTouchSample : NSObject <NSCopying, NSSecureCoding>

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
typedef NS_ENUM(NSInteger, ORK1SpatialSpanMemoryGameStatus) {
    
    /// Unknown status. The game is still in progress or has not started.
    ORK1SpatialSpanMemoryGameStatusUnknown,
    
    /// Success. The user has completed the sequence.
    ORK1SpatialSpanMemoryGameStatusSuccess,
    
    /// Failure. The user has completed the sequence incorrectly.
    ORK1SpatialSpanMemoryGameStatusFailure,
    
    /// Timeout. The game timed out during play.
    ORK1SpatialSpanMemoryGameStatusTimeout
} ORK1_ENUM_AVAILABLE;

/**
 The `ORK1SpatialSpanMemoryGameRecord` class records the results of a
 single playable instance of the spatial span memory game.
 
 A spatial span memory game record is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 
 These records are found in the `records` property of an `ORK1SpatialSpanMemoryResult` object.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1SpatialSpanMemoryGameRecord : NSObject <NSCopying, NSSecureCoding>

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
 An array of `ORK1SpatialSpanMemoryGameTouchSample` objects that record the onscreen locations
the user tapped during the game.
 */
@property (nonatomic, copy, nullable) NSArray<ORK1SpatialSpanMemoryGameTouchSample *> *touchSamples;

/**
 A value indicating whether the user completed the sequence and, if the game was not completed, why not.
 */
@property (nonatomic, assign) ORK1SpatialSpanMemoryGameStatus gameStatus;

/**
 An integer that records the number of points obtained during this game toward
 the total score.
 */
@property (nonatomic, assign) NSInteger score;

@end


/**
 The `ORK1SpatialSpanMemoryResult` class represents the result of a spatial span memory step (`ORK1SpatialSpanMemoryStep`).
 
 A spatial span memory result records the score displayed to the user, the number of games, the
 objects recording the actual game, and the user's taps in response
 to the game.
 
 A spatial span memory result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1SpatialSpanMemoryResult : ORK1Result

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
 
 Each item in the array is an `ORK1SpatialSpanMemoryGameRecord` object.
 */
@property (nonatomic, copy, nullable) NSArray<ORK1SpatialSpanMemoryGameRecord *> *gameRecords;

@end


/**
 The `ORK1FileResult` class is a result that references the location of a file produced
 during a task.
 
 A file result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize the linked file for transmission
 to the server.
 
 Active steps typically produce file results when CoreMotion or HealthKit are
 serialized to disk using a data logger (`ORK1DataLogger`). Audio recording also produces a file
 result.
 
 When you write a custom step, use files to report results only when the data
 is likely to be too big to hold in memory for the duration of the task. For
 example, fitness tasks that use sensors can be quite long and can generate
 a large number of samples. To compensate for the length of the task, you can stream the samples to disk during
 the task, and return an `ORK1FileResult` object in the result hierarchy, usually as a
 child of an `ORK1StepResult` object.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1FileResult : ORK1Result

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
 The `ORK1ReactionTimeResult` class represents the result of a single successful attempt within an ORK1ReactionTimeStep.
 
 The `timestamp` property is equal to the value of systemUptime (in NSProcessInfo) when the stimulus occurred.
Each entry of motion data in this file contains a time interval which may be directly compared to timestamp in order to determine the elapsed time since the stimulus.
 
 The fileResult property references the motion data recorded from the beginning of the attempt until the threshold acceleration was reached.
Using the time taken to reach the threshold acceleration as the reaction time of a participant will yield a rather crude measurement. Rather, you should devise your own method using the data recorded to obtain an accurate approximation of the true reaction time.
 
 A reaction time result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize the sample for transmission to a server
 or to immediately perform analysis on it.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1ReactionTimeResult: ORK1Result

@property (nonatomic, assign) NSTimeInterval timestamp;

@property (nonatomic, strong) ORK1FileResult *fileResult;

@end


/**
 The `ORK1StroopResult` class represents the result of a single successful attempt within an ORK1StroopStep.
 
 A stroop result is typically generated by the framework as the task proceeds. When the task completes, it may be appropriate to serialize the sample for transmission to a server or to immediately perform analysis on it.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1StroopResult: ORK1Result

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
 The `ORK1PSATResult` class records the results of a PSAT test.
 
 The PSAT result object records the initial digit, an array of addition samples, the total of correct answers
 and also various attributes of the PSAT test.
 
 The PSAT samples are generated by the framework as the task proceeds.
 When the task completes, it may be appropriate to serialize them for transmission to a server,
 or to immediately perform analysis on them.
 */
@class ORK1PSATSample;

ORK1_CLASS_AVAILABLE
@interface ORK1PSATResult : ORK1Result

/**
 The PSAT presentation mode.
 */
@property (nonatomic, assign) ORK1PSATPresentationMode presentationMode;

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
 An array of collected samples, in which each item is an `ORK1PSATSample`
 object that represents an addition sample.
 */
@property (nonatomic, copy, nullable) NSArray<ORK1PSATSample *> *samples;

@end


/**
 The `ORK1PSATSample` class represents a numeric answer to an addition question.
 If the answer is correct, the sample object records the presented digit and the numeric answer.
 A PSAT sample is included in an `ORK1PSATResult` object and is recorded
 by the step view controller for the corresponding task.
 
 A PSAT sample is typically generated by the framework as the task proceeds.
 When the task completes, it may be appropriate to serialize the sample for
 transmission to a server, or to immediately perform analysis on it.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1PSATSample : NSObject <NSCopying, NSSecureCoding>

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
 The `ORK1HolePegTestResult` class records the results of a hole peg test.
 
 The hole peg test result object records the number of pegs, an array of move samples, the total duration
 and also various attributes of the hole peg test.
 
 The hole peg test samples are generated by the framework as the task proceeds.
 When the task completes, it may be appropriate to serialize them for transmission to a server,
 or to immediately perform analysis on them.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1HolePegTestResult : ORK1Result

/**
 The hole peg test moving direction.
 */
@property (nonatomic, assign) ORK1BodySagittal movingDirection;

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
 An array of collected samples, in which each item is an `ORK1HolePegTestSample`
 object that represents a peg move.
 */
@property (nonatomic, copy, nullable) NSArray *samples;

@end


/**
 The `ORK1HolePegTestSample` class represents a peg move.
 
 The sample object records the duration, and the move distance.
 An hole peg test is included in an `ORK1HolePegTestResult` object, and is recorded
 by the step view controller for the corresponding task.
 
 An hole peg test sample is typically generated by the framework as the task proceeds.
 When the task completes, it may be appropriate to serialize the sample for
 transmission to a server, or to immediately perform analysis on it.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1HolePegTestSample : NSObject <NSCopying, NSSecureCoding>

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
 The `ORK1QuestionResult` class is the base class for leaf results from an item that uses an answer format (`ORK1AnswerFormat`).
 
 A question result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 
 See also: `ORK1QuestionStep` and `ORK1FormItem`.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1QuestionResult : ORK1Result

/**
 A value that indicates the type of question the result came from.
 
 The value of `questionType` generally correlates closely with the class, but it can be
 easier to use this value in a switch statement in Objective-C.
 */
@property (nonatomic) ORK1QuestionType questionType;

@end


/**
 The `ORK1ScaleQuestionResult` class represents the answer to a continuous or
 discrete-value scale answer format.
 
 A scale question result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1ScaleQuestionResult : ORK1QuestionResult

/**
 The answer obtained from the scale question.
 
 The value of this property is `nil` when the user skipped the question or otherwise did not
 enter an answer.
 */
@property (nonatomic, copy, nullable) NSNumber *scaleAnswer;

@end


/**
 The `ORK1ChoiceQuestionResult` class represents the single or multiple choice
 answers from a choice-based answer format.
 
 For example, an `ORK1TextChoiceAnswerFormat` or an `ORK1ImageChoiceAnswerFormat`
 format produces an `ORK1ChoiceQuestionResult` object.
 
 A choice question result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1ChoiceQuestionResult : ORK1QuestionResult

/**
 An array of selected values, from the `value` property of an `ORK1TextChoice` or `ORK1ImageChoice` object.
 In the case of a single choice, the array has exactly one entry.
 
 If the user skipped the question, the value of the corresponding array member is `nil`.
 */
@property (nonatomic, copy, nullable) NSArray *choiceAnswers;

@end

/**
 The `ORK1MultipleComponentQuestionResult` class represents the choice
 answers from a multiple-component picker-style choice-based answer format.
 
 For example, an `ORK1MultipleValuePickerAnswerFormat` produces an `ORK1MultipleComponentQuestionResult` object.
 
 A multiple component question result is typically generated by the framework as the task proceeds. 
 When the task completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1MultipleComponentQuestionResult : ORK1QuestionResult

/**
 An array of selected components, from the `value` property of an `ORK1TextChoice` object.
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
 The `ORK1BooleanQuestionResult` class represents the answer to a Yes/No question.
 
 A Boolean question result is produced by the task view controller when it presents a question or form
 item with a Boolean answer format (that is, `ORK1BooleanAnswerFormat`).
 
 A Boolean question result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1BooleanQuestionResult : ORK1QuestionResult

/** The answer, or `nil` if the user skipped the question. */
@property (nonatomic, copy, nullable) NSNumber *booleanAnswer;

@end


/**
 The `ORK1TimedWalkResult` class records the results of a Timed Walk test.
 
 The timed walk result object records the duration to complete the trial with a specific distance
 and time limit.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1TimedWalkResult : ORK1Result
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
 The `ORK1TextQuestionResult` class represents the answer to a question or
 form item that uses an `ORK1TextAnswerFormat` format.
 
 A text question result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server
 or to immediately perform analysis on it.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1TextQuestionResult : ORK1QuestionResult

/** 
 The answer that the user entered.
 
 If the user skipped the question, the value of this property is `nil`.
 */
@property (nonatomic, copy, nullable) NSString *textAnswer;

@end


/**
 The `ORK1NumericQuestionResult` class represents a question or form item that uses an answer format that produces a numeric answer.
 
 Examples of this type of answer format include `ORK1ScaleAnswerFormat` and `ORK1NumericAnswerFormat`.
 
 A numeric question result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1NumericQuestionResult : ORK1QuestionResult

/// The number collected, or `nil` if the user skipped the question.
@property (nonatomic, copy, nullable) NSNumber *numericAnswer;

/**
 The unit string displayed to the user when the value was entered, or `nil` if no unit string was displayed.
 */
@property (nonatomic, copy, nullable) NSString *unit;

@end


/**
 The `ORK1TimeOfDayQuestionResult` class represents the result of a question that uses the `ORK1TimeOfDayAnswerFormat` format.
 */

ORK1_CLASS_AVAILABLE
@interface ORK1TimeOfDayQuestionResult : ORK1QuestionResult

/**
 The date components picked by the user.
 
 Typically only hour, minute, and AM/PM data are of interest.
 */
@property (nonatomic, copy, nullable) NSDateComponents *dateComponentsAnswer;

@end


/**
 The `ORK1TimeIntervalQuestionResult` class represents the result of a question
 that uses the `ORK1TimeIntervalAnswerFormat` format.
 
 A time interval question result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1TimeIntervalQuestionResult : ORK1QuestionResult

/**
 The selected interval, in seconds.
 
 The value of this property is `nil` if the user skipped the question.
 */
@property (nonatomic, copy, nullable) NSNumber *intervalAnswer;

@end


/**
 The `ORK1DateQuestionResult` class represents the result of a question or form item that asks for a date (`ORK1DateAnswerFormat`).
 
 The calendar and time zone are recorded in addition to the answer itself,
 to give the answer context. Usually, this data corresponds to the current calendar
 and time zone at the time of the activity, but it can be overridden by setting
 these properties explicitly in the `ORK1DateAnswerFormat` object.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1DateQuestionResult : ORK1QuestionResult

/**
 The date that the user entered, or `nil` if the user skipped the question.
 */
@property (nonatomic, copy, nullable) NSDate *dateAnswer;

/**
 The calendar used when selecting date and time.
 
 If the calendar in the `ORK1DateAnswerFormat` object is `nil`, this calendar is the system
 calendar at the time of data entry.
 */
@property (nonatomic, copy, nullable) NSCalendar *calendar;

/**
 The time zone that was current when selecting the date and time.
 */
@property (nonatomic, copy, nullable) NSTimeZone *timeZone;

@end


/**
 The `ORK1ConsentSignatureResult` class represents a signature obtained during
 a consent review step (`ORK1ConsentReviewStep`). The consent signature result is usually found as a child result of the
 `ORK1StepResult` object for the consent review step.
 
 You can apply the result to a document to facilitate the generation of a
 PDF including the signature, or for presentation in a follow-on
 consent review.
 
 A consent signature result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1ConsentSignatureResult : ORK1Result

/**
 A copy of the signature obtained.
 
 The signature is a copy of the `signature` property in the originating
 `ORK1ConsentReviewStep` object, but also includes any name or signature image collected during
 the consent review step.
 */
@property (nonatomic, copy, nullable) ORK1ConsentSignature *signature;

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
- (void)applyToDocument:(ORK1ConsentDocument *)document;

@end


/**
 The `ORK1CollectionResult` class represents a result that contains an array of
 child results.
 
 `ORK1CollectionResult` is the superclass of `ORK1TaskResult` and `ORK1StepResult`.
 
 Note that object of this class are not instantiated directly by the ResearchKit framework.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1CollectionResult : ORK1Result

/**
 An array of `ORK1Result` objects that are the children of the result.
 
 For `ORK1TaskResult`, the array contains `ORK1StepResult` objects.
 For `ORK1StepResult` the array contains concrete result objects such as `ORK1FileResult`
 and `ORK1QuestionResult`.
 */
@property (nonatomic, copy, nullable) NSArray<ORK1Result *> *results;

/**
 Looks up the child result containing an identifier that matches the specified identifier.
 
 @param identifier The identifier of the step for which to search.
 
 @return The matching result, or `nil` if none was found.
 */
- (nullable ORK1Result *)resultForIdentifier:(NSString *)identifier;

/**
 The first result.
 
 This is the first result, or `nil` if there are no results.
 */
@property (nonatomic, strong, readonly, nullable) ORK1Result *firstResult;

@end


/**
 `ORK1TaskResultSource` is the protocol for `[ORK1TaskViewController defaultResultSource]`.
 */
@protocol ORK1TaskResultSource <NSObject>

/**
 Returns a step result for the specified step identifier, if one exists.
 
 When it's about to present a step, the task view controller needs to look up a
 suitable default answer. The answer can be used to prepopulate a survey with
 the results obtained on a previous run of the same task, by passing an
 `ORK1TaskResult` object (which itself implements this protocol).
 
 @param stepIdentifier The identifier for which to search.
 
 @return The result for the specified step, or `nil` for none.
 */
- (nullable ORK1StepResult *)stepResultForStepIdentifier:(NSString *)stepIdentifier;

/**
 Should the default result store be used even if there is a previous result? (due to 
 reverse navigation or looping)
 
 By default, the `[ORK1TaskViewController defaultResultSource]` is only queried for a 
 result if the previous result is nil. This allows the result source to override that
 default behavior.
 
 @return `YES` if the default result should be given priority over the previous result.
 */
@optional
- (BOOL)alwaysCheckForDefaultResult;

@end


/**
 An `ORK1TaskResult` object is a collection result that contains all the step results
 generated from one run of a task or ordered task (that is, `ORK1Task` or `ORK1OrderedTask`) in a task view controller.
 
 A task result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 
 The `results` property of the `ORK1CollectionResult` object contains the step results
 for the task.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1TaskResult : ORK1CollectionResult <ORK1TaskResultSource>

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
 `ORK1FileResult` objects.
 */
@property (nonatomic, copy, readonly, nullable) NSURL *outputDirectory;

@end


/**
 The `ORK1StepResult` class represents a collection result produced by a step view controller to
 hold all child results produced by the step.
 
 A step result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 
 For example, an `ORK1QuestionStep` object produces an `ORK1QuestionResult` object that becomes
 a child of the `ORK1StepResult` object. Similarly, an `ORK1ActiveStep` object may produce individual
 child result objects for each of the recorder configurations that was active
 during that step.
 
 The `results` property of the `ORK1CollectionResult` object contains the step results
 for the task.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1StepResult : ORK1CollectionResult


/**
 Returns an initialized step result using the specified identifier.
 
 @param stepIdentifier      The identifier of the step.
 @param results             The array of child results. The value of this parameter can be `nil` or empty
            if no results were collected.
 
 @return An initialized step result.
 */
- (instancetype)initWithStepIdentifier:(NSString *)stepIdentifier results:(nullable NSArray<ORK1Result *> *)results;

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
 The `ORK1Location` class represents the location addess obtained from a locaton question.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1Location : NSObject <NSCopying, NSSecureCoding>

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
 The `ORK1LocationQuestionResult` class represents the result of a question or form item that asks for a location (`ORK1LocationAnswerFormat`).
 
 A Location question result is produced by the task view controller when it presents a question or form
 item with a Location answer format (that is, `ORK1LocationAnswerFormat`).
 
 A Location question result is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize it for transmission to a server,
 or to immediately perform analysis on it.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1LocationQuestionResult : ORK1QuestionResult

/**
 The answer representing the coordinate and the address of a specific location.
 */
@property (nonatomic, copy, nullable) ORK1Location *locationAnswer;

@end

/**
 The `ORK1SignatureResult` class represents the result of a signature step (`ORK1SignatureStep`).
 
 A signature result is produced by the task view controller when it presents a signature step.

 */
ORK1_CLASS_AVAILABLE
@interface ORK1SignatureResult : ORK1Result

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
 The `ORK1TrailmakingTap` class represents a single tap in a trail making test.
 
 The Trailmaking tap move object records the indexes of tap, if it was in error or not
 and the time at which the event occurred. A `trailmakingTap` instance is included in
 an `ORK1TrailmakingResult` object and is recorded by the step view controller for the
 corresponding task when a tap is made.
 
 A trail making tap is typically generated by the framework as the task proceeds. When the task
 completes, it may be appropriate to serialize the move for transmission to a server,
 or to immediately perform analysis on it.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1TrailmakingTap : NSObject <NSCopying, NSSecureCoding>

/**
 A relative timestamp indicating the time of the tap event.
 
 The timestamp is relative to the value of `startDate` in the `ORK1Result` object that includes this move.
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
 The `ORK1TrailmakingResult` class represents the result of a signature step (`ORK1TrailmakingStep`).
 
 
 A trail making result is produced by the task view controller when it presents a trail making step.
 
 */
ORK1_CLASS_AVAILABLE
@interface ORK1TrailmakingResult : ORK1Result

/** 
 An array of all taps completed during the test
 */
@property (nonatomic, copy) NSArray <ORK1TrailmakingTap *> *taps;

/** 
 The number of errors generated during the test
 */
@property (nonatomic) NSUInteger numberOfErrors;

@end


/**
 The `ORK1VideoInstructionStepResult` class represents the result of a video insruction step (`ORK1VideoInstructionStep`).
 
 A video instruction result is produced by the task view controller when it presents a video instruction step.
 
 */
ORK1_CLASS_AVAILABLE
@interface ORK1VideoInstructionStepResult : ORK1Result

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
 The `ORK1WebViewStepResult` class represents the result of a web view step (`ORK1WebViewStep`).
 
 A web view result is produced by the task view controller when it presents a web view step.
 
 */
ORK1_CLASS_AVAILABLE
@interface ORK1WebViewStepResult : ORK1Result

/**
 The answer produced by the webview.
 */
@property (nonatomic, nullable) NSString* result;

@end

NS_ASSUME_NONNULL_END
