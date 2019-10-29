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
#import <ResearchKit/RK1Defines.h>


NS_ASSUME_NONNULL_BEGIN

/**
 An enumeration of values that identify the different types of questions that the ResearchKit
 framework supports.
 */
typedef NS_ENUM(NSInteger, RK1QuestionType) {
    /**
     No question.
     */
    RK1QuestionTypeNone,
    
    /**
     The scale question type asks participants to place a mark at an appropriate position on a
     continuous or discrete line.
     */
    RK1QuestionTypeScale,
    
    /**
     In a single choice question, the participant can pick only one predefined option.
     */
    RK1QuestionTypeSingleChoice,
    
    /**
     In a multiple choice question, the participant can pick one or more predefined options.
     */
    RK1QuestionTypeMultipleChoice,
    
    /**
     In a multiple component choice picker, the participant can pick one choice from each component.
     */
    RK1QuestionTypeMultiplePicker,
    
    /**
     The decimal question type asks the participant to enter a decimal number.
     */
    RK1QuestionTypeDecimal,
    
    /**
     The integer question type asks the participant to enter an integer number.
     */
    RK1QuestionTypeInteger,
    
    /**
     The Boolean question type asks the participant to enter Yes or No (or the appropriate
     equivalents).
     */
    RK1QuestionTypeBoolean,
    
    /**
     In a text question, the participant can enter multiple lines of text.
     */
    RK1QuestionTypeText,
    
    /**
     In a time of day question, the participant can enter a time of day by using a picker.
     */
    RK1QuestionTypeTimeOfDay,
    
    /**
     In a date and time question, the participant can enter a combination of date and time by using
     a picker.
     */
    RK1QuestionTypeDateAndTime,
    
    /**
     In a date question, the participant can enter a date by using a picker.
     */
    RK1QuestionTypeDate,
    
    /**
     In a time interval question, the participant can enter a time span by using a picker.
     */
    RK1QuestionTypeTimeInterval,
    
    /**
     In a height question, the participant can enter a height by using a height picker.
     */
    RK1QuestionTypeHeight,

    /**
     In a weight question, the participant can enter a weight by using a weight picker.
     */
    RK1QuestionTypeWeight,
    
    /**
     In a location question, the participant can enter a location using a map view.
     */
    RK1QuestionTypeLocation
} RK1_ENUM_AVAILABLE;


/**
 An enumeration of the types of answer choices available.
 */
typedef NS_ENUM(NSInteger, RK1ChoiceAnswerStyle) {
    /**
     A single choice question lets the participant pick a single predefined answer option.
     */
    RK1ChoiceAnswerStyleSingleChoice,
    
    /**
     A multiple choice question lets the participant pick one or more predefined answer options.
     */
    RK1ChoiceAnswerStyleMultipleChoice
} RK1_ENUM_AVAILABLE;


/**
 An enumeration of the format styles available for scale answers.
 */
typedef NS_ENUM(NSInteger, RK1NumberFormattingStyle) {
    /**
     The default decimal style.
     */
    RK1NumberFormattingStyleDefault,
    
    /**
     Percent style.
     */
    RK1NumberFormattingStylePercent
} RK1_ENUM_AVAILABLE;


/**
 You can use a permission mask to specify a set of permissions to acquire or
 that have been acquired for a task or step.
 */
typedef NS_OPTIONS(NSInteger, RK1PermissionMask) {
    /// No permissions.
    RK1PermissionNone                     = 0,
    
    /// Access to CoreMotion activity is required.
    RK1PermissionCoreMotionActivity       = (1 << 1),
    
    /// Access to CoreMotion accelerometer data.
    RK1PermissionCoreMotionAccelerometer  = (1 << 2),
    
    /// Access for audio recording.
    RK1PermissionAudioRecording           = (1 << 3),
    
    /// Access to location.
    RK1PermissionCoreLocation             = (1 << 4),
    
    /// Access to camera.
    RK1PermissionCamera                   = (1 << 5),
} RK1_ENUM_AVAILABLE;


/**
 File protection mode constants.
 
 The file protection mode constants correspond directly to `NSFileProtection` constants, but are
 more convenient to manipulate than strings. Complete file protection is
 highly recommended for files containing personal data that will be kept
 persistently.
 */
typedef NS_ENUM(NSInteger, RK1FileProtectionMode) {
    /// No file protection.
    RK1FileProtectionNone = 0,
    
    /// Complete file protection until first user authentication.
    RK1FileProtectionCompleteUntilFirstUserAuthentication,
    
    /// Complete file protection unless there was an open file handle before lock.
    RK1FileProtectionCompleteUnlessOpen,
    
    /// Complete file protection while the device is locked.
    RK1FileProtectionComplete
} RK1_ENUM_AVAILABLE;


/**
 Audio channel constants.
 */
typedef NS_ENUM(NSInteger, RK1AudioChannel) {
    /// The left audio channel.
    RK1AudioChannelLeft,
    
    /// The right audio channel.
    RK1AudioChannelRight
} RK1_ENUM_AVAILABLE;


/**
 Body side constants.
 */
typedef NS_ENUM(NSInteger, RK1BodySagittal) {
    /// The left side.
    RK1BodySagittalLeft,
    
    /// The right side.
    RK1BodySagittalRight
} RK1_ENUM_AVAILABLE;

/**
 Values that identify the presentation mode of paced serial addition tests that are auditory and/or visual (PSAT).
 */
typedef NS_OPTIONS(NSInteger, RK1PSATPresentationMode) {
    /// The PASAT (Paced Auditory Serial Addition Test).
    RK1PSATPresentationModeAuditory = 1 << 0,
    
    /// The PVSAT (Paced Visual Serial Addition Test).
    RK1PSATPresentationModeVisual = 1 << 1
} RK1_ENUM_AVAILABLE;


/**
 Identify the type of passcode authentication for `RK1PasscodeStepViewController`.
 */
typedef NS_ENUM(NSInteger, RK1PasscodeType) {
    /// 4 digit pin entry
    RK1PasscodeType4Digit,
    
    /// 6 digit pin entry
    RK1PasscodeType6Digit
} RK1_ENUM_AVAILABLE;


/**
 Progress indicator type for `RK1WaitStep`.
 */
typedef NS_ENUM(NSInteger, RK1ProgressIndicatorType) {
    /// Spinner animation.
    RK1ProgressIndicatorTypeIndeterminate = 0,
    
    /// Progressbar animation.
    RK1ProgressIndicatorTypeProgressBar,
} RK1_ENUM_AVAILABLE;


/**
 Measurement system.
 
 Used by RK1HeightAnswerFormat and RK1WeightAnswerFormat.
 */
typedef NS_ENUM(NSInteger, RK1MeasurementSystem) {
    /// Measurement system in use by the current locale.
    RK1MeasurementSystemLocal = 0,
    
    /// Metric measurement system.
    RK1MeasurementSystemMetric,

    /// United States customary system.
    RK1MeasurementSystemUSC,
} RK1_ENUM_AVAILABLE;


/**
 Numeric precision.
 
 Used by RK1WeightAnswerFormat.
 */
typedef NS_ENUM(NSInteger, RK1NumericPrecision) {
    /// Default numeric precision.
    RK1NumericPrecisionDefault = 0,
    
    /// Low numeric precision.
    RK1NumericPrecisionLow,
    
    /// High numeric preicision.
    RK1NumericPrecisionHigh,
} RK1_ENUM_AVAILABLE;


extern const double RK1DoubleDefaultValue RK1_AVAILABLE_DECL;


NS_ASSUME_NONNULL_END
