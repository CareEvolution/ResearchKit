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


@import Foundation;
#import <ORK1Kit/ORK1Defines.h>


NS_ASSUME_NONNULL_BEGIN

/**
 An enumeration of values that identify the different types of questions that the ORK1Kit
 framework supports.
 */
typedef NS_ENUM(NSInteger, ORK1QuestionType) {
    /**
     No question.
     */
    ORK1QuestionTypeNone,
    
    /**
     The scale question type asks participants to place a mark at an appropriate position on a
     continuous or discrete line.
     */
    ORK1QuestionTypeScale,
    
    /**
     In a single choice question, the participant can pick only one predefined option.
     */
    ORK1QuestionTypeSingleChoice,
    
    /**
     In a multiple choice question, the participant can pick one or more predefined options.
     */
    ORK1QuestionTypeMultipleChoice,
    
    /**
     In a multiple component choice picker, the participant can pick one choice from each component.
     */
    ORK1QuestionTypeMultiplePicker,
    
    /**
     The decimal question type asks the participant to enter a decimal number.
     */
    ORK1QuestionTypeDecimal,
    
    /**
     The integer question type asks the participant to enter an integer number.
     */
    ORK1QuestionTypeInteger,
    
    /**
     The Boolean question type asks the participant to enter Yes or No (or the appropriate
     equivalents).
     */
    ORK1QuestionTypeBoolean,
    
    /**
     In a text question, the participant can enter multiple lines of text.
     */
    ORK1QuestionTypeText,
    
    /**
     In a time of day question, the participant can enter a time of day by using a picker.
     */
    ORK1QuestionTypeTimeOfDay,
    
    /**
     In a date and time question, the participant can enter a combination of date and time by using
     a picker.
     */
    ORK1QuestionTypeDateAndTime,
    
    /**
     In a date question, the participant can enter a date by using a picker.
     */
    ORK1QuestionTypeDate,
    
    /**
     In a time interval question, the participant can enter a time span by using a picker.
     */
    ORK1QuestionTypeTimeInterval,
    
    /**
     In a height question, the participant can enter a height by using a height picker.
     */
    ORK1QuestionTypeHeight,

    /**
     In a weight question, the participant can enter a weight by using a weight picker.
     */
    ORK1QuestionTypeWeight,
    
    /**
     In a location question, the participant can enter a location using a map view.
     */
    ORK1QuestionTypeLocation
} ORK1_ENUM_AVAILABLE;


/**
 An enumeration of the types of answer choices available.
 */
typedef NS_ENUM(NSInteger, ORK1ChoiceAnswerStyle) {
    /**
     A single choice question lets the participant pick a single predefined answer option.
     */
    ORK1ChoiceAnswerStyleSingleChoice,
    
    /**
     A multiple choice question lets the participant pick one or more predefined answer options.
     */
    ORK1ChoiceAnswerStyleMultipleChoice
} ORK1_ENUM_AVAILABLE;

/**
 An enumeration of how to display detailText/description
 */
typedef NS_ENUM(NSInteger, ORK1ChoiceDescriptionStyle) {
    /**
     The detailText/description always appears under the answer choice
     */
    ORK1ChoiceDescriptionStyleDisplayAlways,
    
    /**
     No detailText/description appears
     */
    ORK1ChoiceDescriptionStyleNone,
    
    /**
     The detailText/description only shows when it is expanded
     */
    ORK1ChoiceDescriptionStyleDisplayWhenExpanded
} ORK1_ENUM_AVAILABLE;

/**
 An enumeration of the format styles available for scale answers.
 */
typedef NS_ENUM(NSInteger, ORK1NumberFormattingStyle) {
    /**
     The default decimal style.
     */
    ORK1NumberFormattingStyleDefault,
    
    /**
     Percent style.
     */
    ORK1NumberFormattingStylePercent
} ORK1_ENUM_AVAILABLE;


/**
 You can use a permission mask to specify a set of permissions to acquire or
 that have been acquired for a task or step.
 */
typedef NS_OPTIONS(NSInteger, ORK1PermissionMask) {
    /// No permissions.
    ORK1PermissionNone                     = 0,
    
    /// Access to CoreMotion activity is required.
    ORK1PermissionCoreMotionActivity       = (1 << 1),
    
    /// Access to CoreMotion accelerometer data.
    ORK1PermissionCoreMotionAccelerometer  = (1 << 2),
    
    /// Access for audio recording.
    ORK1PermissionAudioRecording           = (1 << 3),
    
    /// Access to location.
    ORK1PermissionCoreLocation             = (1 << 4),
    
    /// Access to camera.
    ORK1PermissionCamera                   = (1 << 5),
} ORK1_ENUM_AVAILABLE;


/**
 File protection mode constants.
 
 The file protection mode constants correspond directly to `NSFileProtection` constants, but are
 more convenient to manipulate than strings. Complete file protection is
 highly recommended for files containing personal data that will be kept
 persistently.
 */
typedef NS_ENUM(NSInteger, ORK1FileProtectionMode) {
    /// No file protection.
    ORK1FileProtectionNone = 0,
    
    /// Complete file protection until first user authentication.
    ORK1FileProtectionCompleteUntilFirstUserAuthentication,
    
    /// Complete file protection unless there was an open file handle before lock.
    ORK1FileProtectionCompleteUnlessOpen,
    
    /// Complete file protection while the device is locked.
    ORK1FileProtectionComplete
} ORK1_ENUM_AVAILABLE;


/**
 Audio channel constants.
 */
typedef NS_ENUM(NSInteger, ORK1AudioChannel) {
    /// The left audio channel.
    ORK1AudioChannelLeft,
    
    /// The right audio channel.
    ORK1AudioChannelRight
} ORK1_ENUM_AVAILABLE;


/**
 Body side constants.
 */
typedef NS_ENUM(NSInteger, ORK1BodySagittal) {
    /// The left side.
    ORK1BodySagittalLeft,
    
    /// The right side.
    ORK1BodySagittalRight
} ORK1_ENUM_AVAILABLE;

/**
 Values that identify the presentation mode of paced serial addition tests that are auditory and/or visual (PSAT).
 */
typedef NS_OPTIONS(NSInteger, ORK1PSATPresentationMode) {
    /// The PASAT (Paced Auditory Serial Addition Test).
    ORK1PSATPresentationModeAuditory = 1 << 0,
    
    /// The PVSAT (Paced Visual Serial Addition Test).
    ORK1PSATPresentationModeVisual = 1 << 1
} ORK1_ENUM_AVAILABLE;


/**
 Identify the type of passcode authentication for `ORK1PasscodeStepViewController`.
 */
typedef NS_ENUM(NSInteger, ORK1PasscodeType) {
    /// 4 digit pin entry
    ORK1PasscodeType4Digit,
    
    /// 6 digit pin entry
    ORK1PasscodeType6Digit
} ORK1_ENUM_AVAILABLE;


/**
 Progress indicator type for `ORK1WaitStep`.
 */
typedef NS_ENUM(NSInteger, ORK1ProgressIndicatorType) {
    /// Spinner animation.
    ORK1ProgressIndicatorTypeIndeterminate = 0,
    
    /// Progressbar animation.
    ORK1ProgressIndicatorTypeProgressBar,
} ORK1_ENUM_AVAILABLE;


/**
 Measurement system.
 
 Used by ORK1HeightAnswerFormat and ORK1WeightAnswerFormat.
 */
typedef NS_ENUM(NSInteger, ORK1MeasurementSystem) {
    /// Measurement system in use by the current locale.
    ORK1MeasurementSystemLocal = 0,
    
    /// Metric measurement system.
    ORK1MeasurementSystemMetric,

    /// United States customary system.
    ORK1MeasurementSystemUSC,
} ORK1_ENUM_AVAILABLE;


/**
 Numeric precision.
 
 Used by ORK1WeightAnswerFormat.
 */
typedef NS_ENUM(NSInteger, ORK1NumericPrecision) {
    /// Default numeric precision.
    ORK1NumericPrecisionDefault = 0,
    
    /// Low numeric precision.
    ORK1NumericPrecisionLow,
    
    /// High numeric preicision.
    ORK1NumericPrecisionHigh,
} ORK1_ENUM_AVAILABLE;


extern const double ORK1DoubleDefaultValue ORK1_AVAILABLE_DECL;


NS_ASSUME_NONNULL_END
