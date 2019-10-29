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
#import <ResearchKitLegacy/ORKDefines.h>


NS_ASSUME_NONNULL_BEGIN

/**
 An enumeration of values that identify the different types of questions that the ResearchKit
 framework supports.
 */
typedef NS_ENUM(NSInteger, ORKLegacyQuestionType) {
    /**
     No question.
     */
    ORKLegacyQuestionTypeNone,
    
    /**
     The scale question type asks participants to place a mark at an appropriate position on a
     continuous or discrete line.
     */
    ORKLegacyQuestionTypeScale,
    
    /**
     In a single choice question, the participant can pick only one predefined option.
     */
    ORKLegacyQuestionTypeSingleChoice,
    
    /**
     In a multiple choice question, the participant can pick one or more predefined options.
     */
    ORKLegacyQuestionTypeMultipleChoice,
    
    /**
     In a multiple component choice picker, the participant can pick one choice from each component.
     */
    ORKLegacyQuestionTypeMultiplePicker,
    
    /**
     The decimal question type asks the participant to enter a decimal number.
     */
    ORKLegacyQuestionTypeDecimal,
    
    /**
     The integer question type asks the participant to enter an integer number.
     */
    ORKLegacyQuestionTypeInteger,
    
    /**
     The Boolean question type asks the participant to enter Yes or No (or the appropriate
     equivalents).
     */
    ORKLegacyQuestionTypeBoolean,
    
    /**
     In a text question, the participant can enter multiple lines of text.
     */
    ORKLegacyQuestionTypeText,
    
    /**
     In a time of day question, the participant can enter a time of day by using a picker.
     */
    ORKLegacyQuestionTypeTimeOfDay,
    
    /**
     In a date and time question, the participant can enter a combination of date and time by using
     a picker.
     */
    ORKLegacyQuestionTypeDateAndTime,
    
    /**
     In a date question, the participant can enter a date by using a picker.
     */
    ORKLegacyQuestionTypeDate,
    
    /**
     In a time interval question, the participant can enter a time span by using a picker.
     */
    ORKLegacyQuestionTypeTimeInterval,
    
    /**
     In a height question, the participant can enter a height by using a height picker.
     */
    ORKLegacyQuestionTypeHeight,

    /**
     In a weight question, the participant can enter a weight by using a weight picker.
     */
    ORKLegacyQuestionTypeWeight,
    
    /**
     In a location question, the participant can enter a location using a map view.
     */
    ORKLegacyQuestionTypeLocation
} ORKLegacy_ENUM_AVAILABLE;


/**
 An enumeration of the types of answer choices available.
 */
typedef NS_ENUM(NSInteger, ORKLegacyChoiceAnswerStyle) {
    /**
     A single choice question lets the participant pick a single predefined answer option.
     */
    ORKLegacyChoiceAnswerStyleSingleChoice,
    
    /**
     A multiple choice question lets the participant pick one or more predefined answer options.
     */
    ORKLegacyChoiceAnswerStyleMultipleChoice
} ORKLegacy_ENUM_AVAILABLE;


/**
 An enumeration of the format styles available for scale answers.
 */
typedef NS_ENUM(NSInteger, ORKLegacyNumberFormattingStyle) {
    /**
     The default decimal style.
     */
    ORKLegacyNumberFormattingStyleDefault,
    
    /**
     Percent style.
     */
    ORKLegacyNumberFormattingStylePercent
} ORKLegacy_ENUM_AVAILABLE;


/**
 You can use a permission mask to specify a set of permissions to acquire or
 that have been acquired for a task or step.
 */
typedef NS_OPTIONS(NSInteger, ORKLegacyPermissionMask) {
    /// No permissions.
    ORKLegacyPermissionNone                     = 0,
    
    /// Access to CoreMotion activity is required.
    ORKLegacyPermissionCoreMotionActivity       = (1 << 1),
    
    /// Access to CoreMotion accelerometer data.
    ORKLegacyPermissionCoreMotionAccelerometer  = (1 << 2),
    
    /// Access for audio recording.
    ORKLegacyPermissionAudioRecording           = (1 << 3),
    
    /// Access to location.
    ORKLegacyPermissionCoreLocation             = (1 << 4),
    
    /// Access to camera.
    ORKLegacyPermissionCamera                   = (1 << 5),
} ORKLegacy_ENUM_AVAILABLE;


/**
 File protection mode constants.
 
 The file protection mode constants correspond directly to `NSFileProtection` constants, but are
 more convenient to manipulate than strings. Complete file protection is
 highly recommended for files containing personal data that will be kept
 persistently.
 */
typedef NS_ENUM(NSInteger, ORKLegacyFileProtectionMode) {
    /// No file protection.
    ORKLegacyFileProtectionNone = 0,
    
    /// Complete file protection until first user authentication.
    ORKLegacyFileProtectionCompleteUntilFirstUserAuthentication,
    
    /// Complete file protection unless there was an open file handle before lock.
    ORKLegacyFileProtectionCompleteUnlessOpen,
    
    /// Complete file protection while the device is locked.
    ORKLegacyFileProtectionComplete
} ORKLegacy_ENUM_AVAILABLE;


/**
 Audio channel constants.
 */
typedef NS_ENUM(NSInteger, ORKLegacyAudioChannel) {
    /// The left audio channel.
    ORKLegacyAudioChannelLeft,
    
    /// The right audio channel.
    ORKLegacyAudioChannelRight
} ORKLegacy_ENUM_AVAILABLE;


/**
 Body side constants.
 */
typedef NS_ENUM(NSInteger, ORKLegacyBodySagittal) {
    /// The left side.
    ORKLegacyBodySagittalLeft,
    
    /// The right side.
    ORKLegacyBodySagittalRight
} ORKLegacy_ENUM_AVAILABLE;

/**
 Values that identify the presentation mode of paced serial addition tests that are auditory and/or visual (PSAT).
 */
typedef NS_OPTIONS(NSInteger, ORKLegacyPSATPresentationMode) {
    /// The PASAT (Paced Auditory Serial Addition Test).
    ORKLegacyPSATPresentationModeAuditory = 1 << 0,
    
    /// The PVSAT (Paced Visual Serial Addition Test).
    ORKLegacyPSATPresentationModeVisual = 1 << 1
} ORKLegacy_ENUM_AVAILABLE;


/**
 Identify the type of passcode authentication for `ORKLegacyPasscodeStepViewController`.
 */
typedef NS_ENUM(NSInteger, ORKLegacyPasscodeType) {
    /// 4 digit pin entry
    ORKLegacyPasscodeType4Digit,
    
    /// 6 digit pin entry
    ORKLegacyPasscodeType6Digit
} ORKLegacy_ENUM_AVAILABLE;


/**
 Progress indicator type for `ORKLegacyWaitStep`.
 */
typedef NS_ENUM(NSInteger, ORKLegacyProgressIndicatorType) {
    /// Spinner animation.
    ORKLegacyProgressIndicatorTypeIndeterminate = 0,
    
    /// Progressbar animation.
    ORKLegacyProgressIndicatorTypeProgressBar,
} ORKLegacy_ENUM_AVAILABLE;


/**
 Measurement system.
 
 Used by ORKLegacyHeightAnswerFormat and ORKLegacyWeightAnswerFormat.
 */
typedef NS_ENUM(NSInteger, ORKLegacyMeasurementSystem) {
    /// Measurement system in use by the current locale.
    ORKLegacyMeasurementSystemLocal = 0,
    
    /// Metric measurement system.
    ORKLegacyMeasurementSystemMetric,

    /// United States customary system.
    ORKLegacyMeasurementSystemUSC,
} ORKLegacy_ENUM_AVAILABLE;


/**
 Numeric precision.
 
 Used by ORKLegacyWeightAnswerFormat.
 */
typedef NS_ENUM(NSInteger, ORKLegacyNumericPrecision) {
    /// Default numeric precision.
    ORKLegacyNumericPrecisionDefault = 0,
    
    /// Low numeric precision.
    ORKLegacyNumericPrecisionLow,
    
    /// High numeric preicision.
    ORKLegacyNumericPrecisionHigh,
} ORKLegacy_ENUM_AVAILABLE;


extern const double ORKLegacyDoubleDefaultValue ORKLegacy_AVAILABLE_DECL;


NS_ASSUME_NONNULL_END
