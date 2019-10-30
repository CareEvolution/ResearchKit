/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 Copyright (c) 2016, Sage Bionetworks
 
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


#import "ORKOrderedTask.h"

#import "ORKAudioStepViewController.h"
#import "ORKCountdownStepViewController.h"
#import "ORKTouchAnywhereStepViewController.h"
#import "ORKFitnessStepViewController.h"
#import "ORKToneAudiometryStepViewController.h"
#import "ORKSpatialSpanMemoryStepViewController.h"
#import "ORKStroopStepViewController.h"
#import "ORKWalkingTaskStepViewController.h"

#import "ORKAccelerometerRecorder.h"
#import "ORKActiveStep_Internal.h"
#import "ORKAnswerFormat_Internal.h"
#import "ORKAudioLevelNavigationRule.h"
#import "ORKAudioRecorder.h"
#import "ORKAudioStep.h"
#import "ORKCompletionStep.h"
#import "ORKCountdownStep.h"
#import "ORKTouchAnywhereStep.h"
#import "ORKFitnessStep.h"
#import "ORKFormStep.h"
#import "ORKNavigableOrderedTask.h"
#import "ORKPSATStep.h"
#import "ORKQuestionStep.h"
#import "ORKReactionTimeStep.h"
#import "ORKSpatialSpanMemoryStep.h"
#import "ORKStep_Private.h"
#import "ORKStroopStep.h"
#import "ORKTappingIntervalStep.h"
#import "ORKTimedWalkStep.h"
#import "ORKToneAudiometryStep.h"
#import "ORKToneAudiometryPracticeStep.h"
#import "ORKTowerOfHanoiStep.h"
#import "ORKTrailmakingStep.h"
#import "ORKVisualConsentStep.h"
#import "ORKRangeOfMotionStep.h"
#import "ORKShoulderRangeOfMotionStep.h"
#import "ORKWaitStep.h"
#import "ORKWalkingTaskStep.h"
#import "ORKResultPredicate.h"

#import "ORKHelpers_Internal.h"
#import "UIImage+ResearchKit.h"
#import <limits.h>

ORK1TrailMakingTypeIdentifier const ORK1TrailMakingTypeIdentifierA = @"A";
ORK1TrailMakingTypeIdentifier const ORK1TrailMakingTypeIdentifierB = @"B";


ORK1TaskProgress ORK1TaskProgressMake(NSUInteger current, NSUInteger total) {
    return (ORK1TaskProgress){.current=current, .total=total};
}


@implementation ORK1OrderedTask {
    NSString *_identifier;
}

@synthesize cev_theme = _cev_theme;

+ (instancetype)new {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)initWithIdentifier:(NSString *)identifier steps:(NSArray<ORK1Step *> *)steps {
    self = [super init];
    if (self) {
        ORK1ThrowInvalidArgumentExceptionIfNil(identifier);
        
        _identifier = [identifier copy];
        _steps = steps;
        
        [self validateParameters];
    }
    return self;
}

- (instancetype)copyWithSteps:(NSArray <ORK1Step *> *)steps {
    ORK1OrderedTask *task = [self copyWithZone:nil];
    task->_steps = ORK1ArrayCopyObjects(steps);
    return task;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORK1OrderedTask *task = [[[self class] allocWithZone:zone] initWithIdentifier:[_identifier copy]
                                                                           steps:ORK1ArrayCopyObjects(_steps)];
    return task;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return (ORK1EqualObjects(self.identifier, castObject.identifier)
            && ORK1EqualObjects(self.steps, castObject.steps));
}

- (NSUInteger)hash {
    return _identifier.hash ^ _steps.hash;
}

#pragma mark - ORK1Task

- (void)validateParameters {
    NSArray *uniqueIdentifiers = [self.steps valueForKeyPath:@"@distinctUnionOfObjects.identifier"];
    BOOL itemsHaveNonUniqueIdentifiers = ( self.steps.count != uniqueIdentifiers.count );
    
    if (itemsHaveNonUniqueIdentifiers) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"Each step should have a unique identifier" userInfo:nil];
    }
}

- (NSString *)identifier {
    return _identifier;
}

- (NSUInteger)indexOfStep:(ORK1Step *)step {
    NSUInteger index = [_steps indexOfObject:step];
    if (index == NSNotFound) {
        NSArray *identifiers = [_steps valueForKey:@"identifier"];
        index = [identifiers indexOfObject:step.identifier];
    }
    return index;
}

- (ORK1Step *)stepAfterStep:(ORK1Step *)step withResult:(ORK1TaskResult *)result {
    NSArray *steps = _steps;
    
    if (steps.count <= 0) {
        return nil;
    }
    
    ORK1Step *currentStep = step;
    ORK1Step *nextStep = nil;
    
    if (currentStep == nil) {
        nextStep = steps[0];
    } else {
        NSUInteger index = [self indexOfStep:step];
        
        if (NSNotFound != index && index != (steps.count - 1)) {
            nextStep = steps[index + 1];
        }
    }
    return nextStep;
}

- (ORK1Step *)stepBeforeStep:(ORK1Step *)step withResult:(ORK1TaskResult *)result {
    NSArray *steps = _steps;
    
    if (steps.count <= 0) {
        return nil;
    }
    
    ORK1Step *currentStep = step;
    ORK1Step *nextStep = nil;
    
    if (currentStep == nil) {
        nextStep = nil;
        
    } else {
        NSUInteger index = [self indexOfStep:step];
        
        if (NSNotFound != index && index != 0) {
            nextStep = steps[index - 1];
        }
    }
    return nextStep;
}

- (ORK1Step *)stepWithIdentifier:(NSString *)identifier {
    __block ORK1Step *step = nil;
    [_steps enumerateObjectsUsingBlock:^(ORK1Step *obj, NSUInteger idx, BOOL *stop) {
        if ([obj.identifier isEqualToString:identifier]) {
            step = obj;
            *stop = YES;
        }
    }];
    return step;
}

- (ORK1TaskProgress)progressOfCurrentStep:(ORK1Step *)step withResult:(ORK1TaskResult *)taskResult {
    ORK1TaskProgress progress;
    progress.current = [self indexOfStep:step];
    progress.total = _steps.count;
    
    if (![step showsProgress]) {
        progress.total = 0;
    }
    return progress;
}

- (NSSet *)requestedHealthKitTypesForReading {
    NSMutableSet *healthTypes = [NSMutableSet set];
    for (ORK1Step *step in self.steps) {
        NSSet *stepSet = [step requestedHealthKitTypesForReading];
        if (stepSet) {
            [healthTypes unionSet:stepSet];
        }
    }
    return healthTypes.count ? healthTypes : nil;
}

- (NSSet *)requestedHealthKitTypesForWriting {
    return nil;
}

- (ORK1PermissionMask)requestedPermissions {
    ORK1PermissionMask mask = ORK1PermissionNone;
    for (ORK1Step *step in self.steps) {
        mask |= [step requestedPermissions];
    }
    return mask;
}

- (BOOL)providesBackgroundAudioPrompts {
    BOOL providesAudioPrompts = NO;
    for (ORK1Step *step in self.steps) {
        if ([step isKindOfClass:[ORK1ActiveStep class]]) {
            ORK1ActiveStep *activeStep = (ORK1ActiveStep *)step;
            if ([activeStep hasVoice] || [activeStep hasCountDown]) {
                providesAudioPrompts = YES;
                break;
            }
        }
    }
    return providesAudioPrompts;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    ORK1_ENCODE_OBJ(aCoder, identifier);
    ORK1_ENCODE_OBJ(aCoder, steps);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, identifier, NSString);
        ORK1_DECODE_OBJ_ARRAY(aDecoder, steps, ORK1Step);
        
        for (ORK1Step *step in _steps) {
            if ([step isKindOfClass:[ORK1Step class]]) {
                [step setTask:self];
            }
        }
    }
    return self;
}

#pragma mark - Predefined

NSString *const ORK1Instruction0StepIdentifier = @"instruction";
NSString *const ORK1Instruction1StepIdentifier = @"instruction1";
NSString *const ORK1Instruction2StepIdentifier = @"instruction2";
NSString *const ORK1Instruction3StepIdentifier = @"instruction3";
NSString *const ORK1Instruction4StepIdentifier = @"instruction4";
NSString *const ORK1Instruction5StepIdentifier = @"instruction5";
NSString *const ORK1Instruction6StepIdentifier = @"instruction6";
NSString *const ORK1Instruction7StepIdentifier = @"instruction7";
NSString *const ORK1CountdownStepIdentifier = @"countdown";
NSString *const ORK1Countdown1StepIdentifier = @"countdown1";
NSString *const ORK1Countdown2StepIdentifier = @"countdown2";
NSString *const ORK1Countdown3StepIdentifier = @"countdown3";
NSString *const ORK1Countdown4StepIdentifier = @"countdown4";
NSString *const ORK1Countdown5StepIdentifier = @"countdown5";
NSString *const ORK1TouchAnywhereStepIdentifier = @"touch.anywhere";
NSString *const ORK1AudioStepIdentifier = @"audio";
NSString *const ORK1AudioTooLoudStepIdentifier = @"audio.tooloud";
NSString *const ORK1TappingStepIdentifier = @"tapping";
NSString *const ORK1ActiveTaskLeftHandIdentifier = @"left";
NSString *const ORK1ActiveTaskRightHandIdentifier = @"right";
NSString *const ORK1ActiveTaskSkipHandStepIdentifier = @"skipHand";
NSString *const ORK1ConclusionStepIdentifier = @"conclusion";
NSString *const ORK1FitnessWalkStepIdentifier = @"fitness.walk";
NSString *const ORK1FitnessRestStepIdentifier = @"fitness.rest";
NSString *const ORK1KneeRangeOfMotionStepIdentifier = @"knee.range.of.motion";
NSString *const ORK1ShoulderRangeOfMotionStepIdentifier = @"shoulder.range.of.motion";
NSString *const ORK1ShortWalkOutboundStepIdentifier = @"walking.outbound";
NSString *const ORK1ShortWalkReturnStepIdentifier = @"walking.return";
NSString *const ORK1ShortWalkRestStepIdentifier = @"walking.rest";
NSString *const ORK1SpatialSpanMemoryStepIdentifier = @"cognitive.memory.spatialspan";
NSString *const ORK1StroopStepIdentifier = @"stroop";
NSString *const ORK1ToneAudiometryPracticeStepIdentifier = @"tone.audiometry.practice";
NSString *const ORK1ToneAudiometryStepIdentifier = @"tone.audiometry";
NSString *const ORK1ReactionTimeStepIdentifier = @"reactionTime";
NSString *const ORK1TowerOfHanoiStepIdentifier = @"towerOfHanoi";
NSString *const ORK1TimedWalkFormStepIdentifier = @"timed.walk.form";
NSString *const ORK1TimedWalkFormAFOStepIdentifier = @"timed.walk.form.afo";
NSString *const ORK1TimedWalkFormAssistanceStepIdentifier = @"timed.walk.form.assistance";
NSString *const ORK1TimedWalkTrial1StepIdentifier = @"timed.walk.trial1";
NSString *const ORK1TimedWalkTurnAroundStepIdentifier = @"timed.walk.turn.around";
NSString *const ORK1TimedWalkTrial2StepIdentifier = @"timed.walk.trial2";
NSString *const ORK1TremorTestInLapStepIdentifier = @"tremor.handInLap";
NSString *const ORK1TremorTestExtendArmStepIdentifier = @"tremor.handAtShoulderLength";
NSString *const ORK1TremorTestBendArmStepIdentifier = @"tremor.handAtShoulderLengthWithElbowBent";
NSString *const ORK1TremorTestTouchNoseStepIdentifier = @"tremor.handToNose";
NSString *const ORK1TremorTestTurnWristStepIdentifier = @"tremor.handQueenWave";
NSString *const ORK1TrailmakingStepIdentifier = @"trailmaking";
NSString *const ORK1ActiveTaskMostAffectedHandIdentifier = @"mostAffected";
NSString *const ORK1PSATStepIdentifier = @"psat";
NSString *const ORK1AudioRecorderIdentifier = @"audio";
NSString *const ORK1AccelerometerRecorderIdentifier = @"accelerometer";
NSString *const ORK1PedometerRecorderIdentifier = @"pedometer";
NSString *const ORK1DeviceMotionRecorderIdentifier = @"deviceMotion";
NSString *const ORK1LocationRecorderIdentifier = @"location";
NSString *const ORK1HeartRateRecorderIdentifier = @"heartRate";

+ (ORK1CompletionStep *)makeCompletionStep {
    ORK1CompletionStep *step = [[ORK1CompletionStep alloc] initWithIdentifier:ORK1ConclusionStepIdentifier];
    step.title = ORK1LocalizedString(@"TASK_COMPLETE_TITLE", nil);
    step.text = ORK1LocalizedString(@"TASK_COMPLETE_TEXT", nil);
    step.shouldTintImages = YES;
    return step;
}

void ORK1StepArrayAddStep(NSMutableArray *array, ORK1Step *step) {
    [step validateParameters];
    [array addObject:step];
}

+ (ORK1OrderedTask *)twoFingerTappingIntervalTaskWithIdentifier:(NSString *)identifier
                                       intendedUseDescription:(NSString *)intendedUseDescription
                                                     duration:(NSTimeInterval)duration
                                                      options:(ORK1PredefinedTaskOption)options {
    return [self twoFingerTappingIntervalTaskWithIdentifier:identifier
                                     intendedUseDescription:intendedUseDescription
                                                   duration:duration
                                                handOptions:0
                                                    options:options];
}
    
+ (ORK1OrderedTask *)twoFingerTappingIntervalTaskWithIdentifier:(NSString *)identifier
                                        intendedUseDescription:(NSString *)intendedUseDescription
                                                      duration:(NSTimeInterval)duration
                                                   handOptions:(ORK1PredefinedTaskHandOption)handOptions
                                                       options:(ORK1PredefinedTaskOption)options {
    
    NSString *durationString = [ORK1DurationStringFormatter() stringFromTimeInterval:duration];
    
    NSMutableArray *steps = [NSMutableArray array];
    
    if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction0StepIdentifier];
            step.title = ORK1LocalizedString(@"TAPPING_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = ORK1LocalizedString(@"TAPPING_INTRO_TEXT", nil);
            
            NSString *imageName = @"phonetapping";
            if (![[NSLocale preferredLanguages].firstObject hasPrefix:@"en"]) {
                imageName = [imageName stringByAppendingString:@"_notap"];
            }
            step.image = [UIImage imageNamed:imageName inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
    }
    
    // Setup which hand to start with and how many hands to add based on the handOptions parameter
    // Hand order is randomly determined.
    NSUInteger handCount = ((handOptions & ORK1PredefinedTaskHandOptionBoth) == ORK1PredefinedTaskHandOptionBoth) ? 2 : 1;
    BOOL undefinedHand = (handOptions == 0);
    BOOL rightHand;
    switch (handOptions) {
        case ORK1PredefinedTaskHandOptionLeft:
            rightHand = NO; break;
        case ORK1PredefinedTaskHandOptionRight:
        case ORK1PredefinedTaskHandOptionUnspecified:
            rightHand = YES; break;
        default:
            rightHand = (arc4random()%2 == 0); break;
        }
        
    for (NSUInteger hand = 1; hand <= handCount; hand++) {
        
        NSString * (^appendIdentifier) (NSString *) = ^ (NSString * identifier) {
            if (undefinedHand) {
                return identifier;
            } else {
                NSString *handIdentifier = rightHand ? ORK1ActiveTaskRightHandIdentifier : ORK1ActiveTaskLeftHandIdentifier;
                return [NSString stringWithFormat:@"%@.%@", identifier, handIdentifier];
            }
        };
        
        if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:appendIdentifier(ORK1Instruction1StepIdentifier)];
            
            // Set the title based on the hand
            if (undefinedHand) {
                step.title = ORK1LocalizedString(@"TAPPING_TASK_TITLE", nil);
            } else if (rightHand) {
                step.title = ORK1LocalizedString(@"TAPPING_TASK_TITLE_RIGHT", nil);
            } else {
                step.title = ORK1LocalizedString(@"TAPPING_TASK_TITLE_LEFT", nil);
            }
            
            // Set the instructions for the tapping test screen that is displayed prior to each hand test
            NSString *restText = ORK1LocalizedString(@"TAPPING_INTRO_TEXT_2_REST_PHONE", nil);
            NSString *tappingTextFormat = ORK1LocalizedString(@"TAPPING_INTRO_TEXT_2_FORMAT", nil);
            NSString *tappingText = [NSString localizedStringWithFormat:tappingTextFormat, durationString];
            NSString *handText = nil;
            
            if (hand == 1) {
                if (undefinedHand) {
                    handText = ORK1LocalizedString(@"TAPPING_INTRO_TEXT_2_MOST_AFFECTED", nil);
                } else if (rightHand) {
                    handText = ORK1LocalizedString(@"TAPPING_INTRO_TEXT_2_RIGHT_FIRST", nil);
                } else {
                    handText = ORK1LocalizedString(@"TAPPING_INTRO_TEXT_2_LEFT_FIRST", nil);
                }
            } else {
                if (rightHand) {
                    handText = ORK1LocalizedString(@"TAPPING_INTRO_TEXT_2_RIGHT_SECOND", nil);
                } else {
                    handText = ORK1LocalizedString(@"TAPPING_INTRO_TEXT_2_LEFT_SECOND", nil);
                }
            }
            
            step.text = [NSString localizedStringWithFormat:@"%@ %@ %@", restText, handText, tappingText];
            
            // Continue button will be different from first hand and second hand
            if (hand == 1) {
                step.detailText = ORK1LocalizedString(@"TAPPING_CALL_TO_ACTION", nil);
            } else {
                step.detailText = ORK1LocalizedString(@"TAPPING_CALL_TO_ACTION_NEXT", nil);
            }
            
            // Set the image
            UIImage *im1 = [UIImage imageNamed:@"handtapping01" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            UIImage *im2 = [UIImage imageNamed:@"handtapping02" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            UIImage *imageAnimation = [UIImage animatedImageWithImages:@[im1, im2] duration:1];
            
            if (rightHand || undefinedHand) {
                step.image = imageAnimation;
            } else {
                step.image = [imageAnimation ork_flippedImage:UIImageOrientationUpMirrored];
            }
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
    
        // TAPPING STEP
    {
        NSMutableArray *recorderConfigurations = [NSMutableArray arrayWithCapacity:5];
        if (!(ORK1PredefinedTaskOptionExcludeAccelerometer & options)) {
            [recorderConfigurations addObject:[[ORK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:ORK1AccelerometerRecorderIdentifier
                                                                                                      frequency:100]];
        }
        
            ORK1TappingIntervalStep *step = [[ORK1TappingIntervalStep alloc] initWithIdentifier:appendIdentifier(ORK1TappingStepIdentifier)];
            if (undefinedHand) {
                step.title = ORK1LocalizedString(@"TAPPING_INSTRUCTION", nil);
            } else if (rightHand) {
                step.title = ORK1LocalizedString(@"TAPPING_INSTRUCTION_RIGHT", nil);
            } else {
                step.title = ORK1LocalizedString(@"TAPPING_INSTRUCTION_LEFT", nil);
            }
            step.stepDuration = duration;
            step.shouldContinueOnFinish = YES;
            step.recorderConfigurations = recorderConfigurations;
            step.optional = (handCount == 2);
            
            ORK1StepArrayAddStep(steps, step);
        }
        
        // Flip to the other hand (ignored if handCount == 1)
        rightHand = !rightHand;
    }
    
    if (!(options & ORK1PredefinedTaskOptionExcludeConclusion)) {
        ORK1InstructionStep *step = [self makeCompletionStep];
        
        ORK1StepArrayAddStep(steps, step);
    }
    
    ORK1OrderedTask *task = [[ORK1OrderedTask alloc] initWithIdentifier:identifier steps:[steps copy]];
    
    return task;
}

+ (ORK1OrderedTask *)audioTaskWithIdentifier:(NSString *)identifier
                     intendedUseDescription:(NSString *)intendedUseDescription
                          speechInstruction:(NSString *)speechInstruction
                     shortSpeechInstruction:(NSString *)shortSpeechInstruction
                                   duration:(NSTimeInterval)duration
                          recordingSettings:(NSDictionary *)recordingSettings
                                    options:(ORK1PredefinedTaskOption)options {
    
    return [self audioTaskWithIdentifier:identifier
                  intendedUseDescription:intendedUseDescription
                       speechInstruction:speechInstruction
                  shortSpeechInstruction:shortSpeechInstruction
                                duration:duration
                       recordingSettings:recordingSettings
                         checkAudioLevel:NO
                                 options:options];
}

+ (ORK1NavigableOrderedTask *)audioTaskWithIdentifier:(NSString *)identifier
                              intendedUseDescription:(nullable NSString *)intendedUseDescription
                                   speechInstruction:(nullable NSString *)speechInstruction
                              shortSpeechInstruction:(nullable NSString *)shortSpeechInstruction
                                            duration:(NSTimeInterval)duration
                                   recordingSettings:(nullable NSDictionary *)recordingSettings
                                     checkAudioLevel:(BOOL)checkAudioLevel
                                             options:(ORK1PredefinedTaskOption)options {

    recordingSettings = recordingSettings ? : @{ AVFormatIDKey : @(kAudioFormatAppleLossless),
                                                 AVNumberOfChannelsKey : @(2),
                                                AVSampleRateKey: @(44100.0) };
    
    if (options & ORK1PredefinedTaskOptionExcludeAudio) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"Audio collection cannot be excluded from audio task" userInfo:nil];
    }
    
    NSMutableArray *steps = [NSMutableArray array];
    if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction0StepIdentifier];
            step.title = ORK1LocalizedString(@"AUDIO_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = ORK1LocalizedString(@"AUDIO_INTENDED_USE", nil);
            step.image = [UIImage imageNamed:@"phonewaves" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
        
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction1StepIdentifier];
            step.title = ORK1LocalizedString(@"AUDIO_TASK_TITLE", nil);
            step.text = speechInstruction ? : ORK1LocalizedString(@"AUDIO_INTRO_TEXT",nil);
            step.detailText = ORK1LocalizedString(@"AUDIO_CALL_TO_ACTION", nil);
            step.image = [UIImage imageNamed:@"phonesoundwaves" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
    }

    {
        ORK1CountdownStep *step = [[ORK1CountdownStep alloc] initWithIdentifier:ORK1CountdownStepIdentifier];
        step.stepDuration = 5.0;
        
        // Collect audio during the countdown step too, to provide a baseline.
        step.recorderConfigurations = @[[[ORK1AudioRecorderConfiguration alloc] initWithIdentifier:ORK1AudioRecorderIdentifier
                                                                                 recorderSettings:recordingSettings]];
        
        // If checking the sound level then add text indicating that's what is happening
        if (checkAudioLevel) {
            step.text = ORK1LocalizedString(@"AUDIO_LEVEL_CHECK_LABEL", nil);
        }
        
        ORK1StepArrayAddStep(steps, step);
    }
    
    if (checkAudioLevel) {
        ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1AudioTooLoudStepIdentifier];
        step.text = ORK1LocalizedString(@"AUDIO_TOO_LOUD_MESSAGE", nil);
        step.detailText = ORK1LocalizedString(@"AUDIO_TOO_LOUD_ACTION_NEXT", nil);
        
        ORK1StepArrayAddStep(steps, step);
    }
    
    {
        ORK1AudioStep *step = [[ORK1AudioStep alloc] initWithIdentifier:ORK1AudioStepIdentifier];
        step.title = shortSpeechInstruction ? : ORK1LocalizedString(@"AUDIO_INSTRUCTION", nil);
        step.recorderConfigurations = @[[[ORK1AudioRecorderConfiguration alloc] initWithIdentifier:ORK1AudioRecorderIdentifier
                                                                                 recorderSettings:recordingSettings]];
        step.stepDuration = duration;
        step.shouldContinueOnFinish = YES;
        
        ORK1StepArrayAddStep(steps, step);
    }
    
    if (!(options & ORK1PredefinedTaskOptionExcludeConclusion)) {
        ORK1InstructionStep *step = [self makeCompletionStep];
        
        ORK1StepArrayAddStep(steps, step);
    }

    ORK1NavigableOrderedTask *task = [[ORK1NavigableOrderedTask alloc] initWithIdentifier:identifier steps:steps];
    
    if (checkAudioLevel) {
    
        // Add rules to check for audio and fail, looping back to the countdown step if required
        ORK1AudioLevelNavigationRule *audioRule = [[ORK1AudioLevelNavigationRule alloc] initWithAudioLevelStepIdentifier:ORK1CountdownStepIdentifier destinationStepIdentifier:ORK1AudioStepIdentifier recordingSettings:recordingSettings];
        ORK1DirectStepNavigationRule *loopRule = [[ORK1DirectStepNavigationRule alloc] initWithDestinationStepIdentifier:ORK1CountdownStepIdentifier];
    
        [task setNavigationRule:audioRule forTriggerStepIdentifier:ORK1CountdownStepIdentifier];
        [task setNavigationRule:loopRule forTriggerStepIdentifier:ORK1AudioTooLoudStepIdentifier];
    }
    
    return task;
}

+ (NSDateComponentsFormatter *)textTimeFormatter {
    NSDateComponentsFormatter *formatter = [NSDateComponentsFormatter new];
    formatter.unitsStyle = NSDateComponentsFormatterUnitsStyleSpellOut;
    
    // Exception list: Korean, Chinese (all), Thai, and Vietnamese.
    NSArray *nonSpelledOutLanguages = @[ @"ko", @"zh", @"th", @"vi", @"ja" ];
    NSString *currentLanguage = [[NSBundle mainBundle] preferredLocalizations].firstObject;
    NSString *currentLanguageCode = [NSLocale componentsFromLocaleIdentifier:currentLanguage][NSLocaleLanguageCode];
    if ((currentLanguageCode != nil) && [nonSpelledOutLanguages containsObject:currentLanguageCode]) {
        formatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
    }
    
    formatter.allowedUnits = NSCalendarUnitMinute | NSCalendarUnitSecond;
    formatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorDropAll;
    return formatter;
}

+ (ORK1OrderedTask *)fitnessCheckTaskWithIdentifier:(NSString *)identifier
                           intendedUseDescription:(NSString *)intendedUseDescription
                                     walkDuration:(NSTimeInterval)walkDuration
                                     restDuration:(NSTimeInterval)restDuration
                                          options:(ORK1PredefinedTaskOption)options {
    
    NSDateComponentsFormatter *formatter = [self textTimeFormatter];
    
    NSMutableArray *steps = [NSMutableArray array];
    if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction0StepIdentifier];
            step.title = ORK1LocalizedString(@"FITNESS_TASK_TITLE", nil);
            step.text = intendedUseDescription ? : [NSString localizedStringWithFormat:ORK1LocalizedString(@"FITNESS_INTRO_TEXT_FORMAT", nil), [formatter stringFromTimeInterval:walkDuration]];
            step.image = [UIImage imageNamed:@"heartbeat" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
        
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction1StepIdentifier];
            step.title = ORK1LocalizedString(@"FITNESS_TASK_TITLE", nil);
            step.text = [NSString localizedStringWithFormat:ORK1LocalizedString(@"FITNESS_INTRO_2_TEXT_FORMAT", nil), [formatter stringFromTimeInterval:walkDuration], [formatter stringFromTimeInterval:restDuration]];
            step.image = [UIImage imageNamed:@"walkingman" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
    }
    
    {
        ORK1CountdownStep *step = [[ORK1CountdownStep alloc] initWithIdentifier:ORK1CountdownStepIdentifier];
        step.stepDuration = 5.0;
        
        ORK1StepArrayAddStep(steps, step);
    }
    
    HKUnit *bpmUnit = [[HKUnit countUnit] unitDividedByUnit:[HKUnit minuteUnit]];
    HKQuantityType *heartRateType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    {
        if (walkDuration > 0) {
            NSMutableArray *recorderConfigurations = [NSMutableArray arrayWithCapacity:5];
            if (!(ORK1PredefinedTaskOptionExcludePedometer & options)) {
                [recorderConfigurations addObject:[[ORK1PedometerRecorderConfiguration alloc] initWithIdentifier:ORK1PedometerRecorderIdentifier]];
            }
            if (!(ORK1PredefinedTaskOptionExcludeAccelerometer & options)) {
                [recorderConfigurations addObject:[[ORK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:ORK1AccelerometerRecorderIdentifier
                                                                                                          frequency:100]];
            }
            if (!(ORK1PredefinedTaskOptionExcludeDeviceMotion & options)) {
                [recorderConfigurations addObject:[[ORK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:ORK1DeviceMotionRecorderIdentifier
                                                                                                         frequency:100]];
            }
            if (!(ORK1PredefinedTaskOptionExcludeLocation & options)) {
                [recorderConfigurations addObject:[[ORK1LocationRecorderConfiguration alloc] initWithIdentifier:ORK1LocationRecorderIdentifier]];
            }
            if (!(ORK1PredefinedTaskOptionExcludeHeartRate & options)) {
                [recorderConfigurations addObject:[[ORK1HealthQuantityTypeRecorderConfiguration alloc] initWithIdentifier:ORK1HeartRateRecorderIdentifier
                                                                                                      healthQuantityType:heartRateType unit:bpmUnit]];
            }
            ORK1FitnessStep *fitnessStep = [[ORK1FitnessStep alloc] initWithIdentifier:ORK1FitnessWalkStepIdentifier];
            fitnessStep.stepDuration = walkDuration;
            fitnessStep.title = [NSString localizedStringWithFormat:ORK1LocalizedString(@"FITNESS_WALK_INSTRUCTION_FORMAT", nil), [formatter stringFromTimeInterval:walkDuration]];
            fitnessStep.spokenInstruction = fitnessStep.title;
            fitnessStep.recorderConfigurations = recorderConfigurations;
            fitnessStep.shouldContinueOnFinish = YES;
            fitnessStep.optional = NO;
            fitnessStep.shouldStartTimerAutomatically = YES;
            fitnessStep.shouldTintImages = YES;
            fitnessStep.image = [UIImage imageNamed:@"walkingman" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            fitnessStep.shouldVibrateOnStart = YES;
            fitnessStep.shouldPlaySoundOnStart = YES;
            
            ORK1StepArrayAddStep(steps, fitnessStep);
        }
        
        if (restDuration > 0) {
            NSMutableArray *recorderConfigurations = [NSMutableArray arrayWithCapacity:5];
            if (!(ORK1PredefinedTaskOptionExcludeAccelerometer & options)) {
                [recorderConfigurations addObject:[[ORK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:ORK1AccelerometerRecorderIdentifier
                                                                                                          frequency:100]];
            }
            if (!(ORK1PredefinedTaskOptionExcludeDeviceMotion & options)) {
                [recorderConfigurations addObject:[[ORK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:ORK1DeviceMotionRecorderIdentifier
                                                                                                         frequency:100]];
            }
            if (!(ORK1PredefinedTaskOptionExcludeHeartRate & options)) {
                [recorderConfigurations addObject:[[ORK1HealthQuantityTypeRecorderConfiguration alloc] initWithIdentifier:ORK1HeartRateRecorderIdentifier
                                                                                                      healthQuantityType:heartRateType unit:bpmUnit]];
            }
            
            ORK1FitnessStep *stillStep = [[ORK1FitnessStep alloc] initWithIdentifier:ORK1FitnessRestStepIdentifier];
            stillStep.stepDuration = restDuration;
            stillStep.title = [NSString localizedStringWithFormat:ORK1LocalizedString(@"FITNESS_SIT_INSTRUCTION_FORMAT", nil), [formatter stringFromTimeInterval:restDuration]];
            stillStep.spokenInstruction = stillStep.title;
            stillStep.recorderConfigurations = recorderConfigurations;
            stillStep.shouldContinueOnFinish = YES;
            stillStep.optional = NO;
            stillStep.shouldStartTimerAutomatically = YES;
            stillStep.shouldTintImages = YES;
            stillStep.image = [UIImage imageNamed:@"sittingman" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            stillStep.shouldVibrateOnStart = YES;
            stillStep.shouldPlaySoundOnStart = YES;
            stillStep.shouldPlaySoundOnFinish = YES;
            stillStep.shouldVibrateOnFinish = YES;
            
            ORK1StepArrayAddStep(steps, stillStep);
        }
    }
    
    if (!(options & ORK1PredefinedTaskOptionExcludeConclusion)) {
        ORK1InstructionStep *step = [self makeCompletionStep];
        ORK1StepArrayAddStep(steps, step);
    }
    
    ORK1OrderedTask *task = [[ORK1OrderedTask alloc] initWithIdentifier:identifier steps:steps];
    
    return task;
}

+ (ORK1OrderedTask *)shortWalkTaskWithIdentifier:(NSString *)identifier
                         intendedUseDescription:(NSString *)intendedUseDescription
                            numberOfStepsPerLeg:(NSInteger)numberOfStepsPerLeg
                                   restDuration:(NSTimeInterval)restDuration
                                        options:(ORK1PredefinedTaskOption)options {
    
    NSDateComponentsFormatter *formatter = [self textTimeFormatter];
    
    NSMutableArray *steps = [NSMutableArray array];
    if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction0StepIdentifier];
            step.title = ORK1LocalizedString(@"WALK_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = ORK1LocalizedString(@"WALK_INTRO_TEXT", nil);
            step.shouldTintImages = YES;
            ORK1StepArrayAddStep(steps, step);
        }
        
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction1StepIdentifier];
            step.title = ORK1LocalizedString(@"WALK_TASK_TITLE", nil);
            step.text = [NSString localizedStringWithFormat:ORK1LocalizedString(@"WALK_INTRO_2_TEXT_%ld", nil),numberOfStepsPerLeg];
            step.detailText = ORK1LocalizedString(@"WALK_INTRO_2_DETAIL", nil);
            step.image = [UIImage imageNamed:@"pocket" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            ORK1StepArrayAddStep(steps, step);
        }
    }
    
    {
        ORK1CountdownStep *step = [[ORK1CountdownStep alloc] initWithIdentifier:ORK1CountdownStepIdentifier];
        step.stepDuration = 5.0;
        
        ORK1StepArrayAddStep(steps, step);
    }
    
    {
        {
            NSMutableArray *recorderConfigurations = [NSMutableArray array];
            if (!(ORK1PredefinedTaskOptionExcludePedometer & options)) {
                [recorderConfigurations addObject:[[ORK1PedometerRecorderConfiguration alloc] initWithIdentifier:ORK1PedometerRecorderIdentifier]];
            }
            if (!(ORK1PredefinedTaskOptionExcludeAccelerometer & options)) {
                [recorderConfigurations addObject:[[ORK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:ORK1AccelerometerRecorderIdentifier
                                                                                                          frequency:100]];
            }
            if (!(ORK1PredefinedTaskOptionExcludeDeviceMotion & options)) {
                [recorderConfigurations addObject:[[ORK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:ORK1DeviceMotionRecorderIdentifier
                                                                                                         frequency:100]];
            }

            ORK1WalkingTaskStep *walkingStep = [[ORK1WalkingTaskStep alloc] initWithIdentifier:ORK1ShortWalkOutboundStepIdentifier];
            walkingStep.numberOfStepsPerLeg = numberOfStepsPerLeg;
            walkingStep.title = [NSString localizedStringWithFormat:ORK1LocalizedString(@"WALK_OUTBOUND_INSTRUCTION_FORMAT", nil), (long long)numberOfStepsPerLeg];
            walkingStep.spokenInstruction = walkingStep.title;
            walkingStep.recorderConfigurations = recorderConfigurations;
            walkingStep.shouldContinueOnFinish = YES;
            walkingStep.optional = NO;
            walkingStep.shouldStartTimerAutomatically = YES;
            walkingStep.stepDuration = numberOfStepsPerLeg * 1.5; // fallback duration in case no step count
            walkingStep.shouldVibrateOnStart = YES;
            walkingStep.shouldPlaySoundOnStart = YES;
            
            ORK1StepArrayAddStep(steps, walkingStep);
        }
        
        {
            NSMutableArray *recorderConfigurations = [NSMutableArray array];
            if (!(ORK1PredefinedTaskOptionExcludePedometer & options)) {
                [recorderConfigurations addObject:[[ORK1PedometerRecorderConfiguration alloc] initWithIdentifier:ORK1PedometerRecorderIdentifier]];
            }
            if (!(ORK1PredefinedTaskOptionExcludeAccelerometer & options)) {
                [recorderConfigurations addObject:[[ORK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:ORK1AccelerometerRecorderIdentifier
                                                                                                          frequency:100]];
            }
            if (!(ORK1PredefinedTaskOptionExcludeDeviceMotion & options)) {
                [recorderConfigurations addObject:[[ORK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:ORK1DeviceMotionRecorderIdentifier
                                                                                                         frequency:100]];
            }

            ORK1WalkingTaskStep *walkingStep = [[ORK1WalkingTaskStep alloc] initWithIdentifier:ORK1ShortWalkReturnStepIdentifier];
            walkingStep.numberOfStepsPerLeg = numberOfStepsPerLeg;
            walkingStep.title = [NSString localizedStringWithFormat:ORK1LocalizedString(@"WALK_RETURN_INSTRUCTION_FORMAT", nil), (long long)numberOfStepsPerLeg];
            walkingStep.spokenInstruction = walkingStep.title;
            walkingStep.recorderConfigurations = recorderConfigurations;
            walkingStep.shouldContinueOnFinish = YES;
            walkingStep.shouldStartTimerAutomatically = YES;
            walkingStep.optional = NO;
            walkingStep.stepDuration = numberOfStepsPerLeg * 1.5; // fallback duration in case no step count
            walkingStep.shouldVibrateOnStart = YES;
            walkingStep.shouldPlaySoundOnStart = YES;
            
            ORK1StepArrayAddStep(steps, walkingStep);
        }
        
        if (restDuration > 0) {
            NSMutableArray *recorderConfigurations = [NSMutableArray array];
            if (!(ORK1PredefinedTaskOptionExcludeAccelerometer & options)) {
                [recorderConfigurations addObject:[[ORK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:ORK1AccelerometerRecorderIdentifier
                                                                                                          frequency:100]];
            }
            if (!(ORK1PredefinedTaskOptionExcludeDeviceMotion & options)) {
                [recorderConfigurations addObject:[[ORK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:ORK1DeviceMotionRecorderIdentifier
                                                                                                         frequency:100]];
            }

            ORK1FitnessStep *activeStep = [[ORK1FitnessStep alloc] initWithIdentifier:ORK1ShortWalkRestStepIdentifier];
            activeStep.recorderConfigurations = recorderConfigurations;
            NSString *durationString = [formatter stringFromTimeInterval:restDuration];
            activeStep.title = [NSString localizedStringWithFormat:ORK1LocalizedString(@"WALK_STAND_INSTRUCTION_FORMAT", nil), durationString];
            activeStep.spokenInstruction = [NSString localizedStringWithFormat:ORK1LocalizedString(@"WALK_STAND_VOICE_INSTRUCTION_FORMAT", nil), durationString];
            activeStep.shouldStartTimerAutomatically = YES;
            activeStep.stepDuration = restDuration;
            activeStep.shouldContinueOnFinish = YES;
            activeStep.optional = NO;
            activeStep.shouldVibrateOnStart = YES;
            activeStep.shouldPlaySoundOnStart = YES;
            activeStep.shouldVibrateOnFinish = YES;
            activeStep.shouldPlaySoundOnFinish = YES;
            
            ORK1StepArrayAddStep(steps, activeStep);
        }
    }
    
    if (!(options & ORK1PredefinedTaskOptionExcludeConclusion)) {
        ORK1InstructionStep *step = [self makeCompletionStep];
        
        ORK1StepArrayAddStep(steps, step);
    }
    
    ORK1OrderedTask *task = [[ORK1OrderedTask alloc] initWithIdentifier:identifier steps:steps];
    return task;
}


+ (ORK1OrderedTask *)walkBackAndForthTaskWithIdentifier:(NSString *)identifier
                                intendedUseDescription:(NSString *)intendedUseDescription
                                          walkDuration:(NSTimeInterval)walkDuration
                                          restDuration:(NSTimeInterval)restDuration
                                               options:(ORK1PredefinedTaskOption)options {
    
    NSDateComponentsFormatter *formatter = [self textTimeFormatter];
    formatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
    
    NSMutableArray *steps = [NSMutableArray array];
    if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction0StepIdentifier];
            step.title = ORK1LocalizedString(@"WALK_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = ORK1LocalizedString(@"WALK_INTRO_TEXT", nil);
            step.shouldTintImages = YES;
            ORK1StepArrayAddStep(steps, step);
        }
        
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction1StepIdentifier];
            step.title = ORK1LocalizedString(@"WALK_TASK_TITLE", nil);
            step.text = ORK1LocalizedString(@"WALK_INTRO_2_TEXT_BACK_AND_FORTH_INSTRUCTION", nil);
            step.detailText = ORK1LocalizedString(@"WALK_INTRO_2_DETAIL_BACK_AND_FORTH_INSTRUCTION", nil);
            step.image = [UIImage imageNamed:@"pocket" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            ORK1StepArrayAddStep(steps, step);
        }
    }
    
    {
        ORK1CountdownStep *step = [[ORK1CountdownStep alloc] initWithIdentifier:ORK1CountdownStepIdentifier];
        step.stepDuration = 5.0;
        
        ORK1StepArrayAddStep(steps, step);
    }
    
    {
        {
            NSMutableArray *recorderConfigurations = [NSMutableArray array];
            if (!(ORK1PredefinedTaskOptionExcludePedometer & options)) {
                [recorderConfigurations addObject:[[ORK1PedometerRecorderConfiguration alloc] initWithIdentifier:ORK1PedometerRecorderIdentifier]];
            }
            if (!(ORK1PredefinedTaskOptionExcludeAccelerometer & options)) {
                [recorderConfigurations addObject:[[ORK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:ORK1AccelerometerRecorderIdentifier
                                                                                                          frequency:100]];
            }
            if (!(ORK1PredefinedTaskOptionExcludeDeviceMotion & options)) {
                [recorderConfigurations addObject:[[ORK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:ORK1DeviceMotionRecorderIdentifier
                                                                                                         frequency:100]];
            }
            
            ORK1WalkingTaskStep *walkingStep = [[ORK1WalkingTaskStep alloc] initWithIdentifier:ORK1ShortWalkOutboundStepIdentifier];
            walkingStep.numberOfStepsPerLeg = 1000; // Set the number of steps very high so it is ignored
            NSString *walkingDurationString = [formatter stringFromTimeInterval:walkDuration];
            walkingStep.title = [NSString localizedStringWithFormat:ORK1LocalizedString(@"WALK_BACK_AND_FORTH_INSTRUCTION_FORMAT", nil), walkingDurationString];
            walkingStep.spokenInstruction = walkingStep.title;
            walkingStep.recorderConfigurations = recorderConfigurations;
            walkingStep.shouldContinueOnFinish = YES;
            walkingStep.optional = NO;
            walkingStep.shouldStartTimerAutomatically = YES;
            walkingStep.stepDuration = walkDuration; // Set the walking duration to the step duration
            walkingStep.shouldVibrateOnStart = YES;
            walkingStep.shouldPlaySoundOnStart = YES;
            walkingStep.shouldSpeakRemainingTimeAtHalfway = (walkDuration > 20);
            
            ORK1StepArrayAddStep(steps, walkingStep);
        }
        
        if (restDuration > 0) {
            NSMutableArray *recorderConfigurations = [NSMutableArray array];
            if (!(ORK1PredefinedTaskOptionExcludeAccelerometer & options)) {
                [recorderConfigurations addObject:[[ORK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:ORK1AccelerometerRecorderIdentifier
                                                                                                          frequency:100]];
            }
            if (!(ORK1PredefinedTaskOptionExcludeDeviceMotion & options)) {
                [recorderConfigurations addObject:[[ORK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:ORK1DeviceMotionRecorderIdentifier
                                                                                                         frequency:100]];
            }
            
            ORK1FitnessStep *activeStep = [[ORK1FitnessStep alloc] initWithIdentifier:ORK1ShortWalkRestStepIdentifier];
            activeStep.recorderConfigurations = recorderConfigurations;
            NSString *durationString = [formatter stringFromTimeInterval:restDuration];
            activeStep.title = [NSString localizedStringWithFormat:ORK1LocalizedString(@"WALK_BACK_AND_FORTH_STAND_INSTRUCTION_FORMAT", nil), durationString];
            activeStep.spokenInstruction = activeStep.title;
            activeStep.shouldStartTimerAutomatically = YES;
            activeStep.stepDuration = restDuration;
            activeStep.shouldContinueOnFinish = YES;
            activeStep.optional = NO;
            activeStep.shouldVibrateOnStart = YES;
            activeStep.shouldPlaySoundOnStart = YES;
            activeStep.shouldVibrateOnFinish = YES;
            activeStep.shouldPlaySoundOnFinish = YES;
            activeStep.finishedSpokenInstruction = ORK1LocalizedString(@"WALK_BACK_AND_FORTH_FINISHED_VOICE", nil);
            activeStep.shouldSpeakRemainingTimeAtHalfway = (restDuration > 20);
            
            ORK1StepArrayAddStep(steps, activeStep);
        }
    }
    
    if (!(options & ORK1PredefinedTaskOptionExcludeConclusion)) {
        ORK1InstructionStep *step = [self makeCompletionStep];
        
        ORK1StepArrayAddStep(steps, step);
    }
    
    ORK1OrderedTask *task = [[ORK1OrderedTask alloc] initWithIdentifier:identifier steps:steps];
    return task;
}

+ (ORK1OrderedTask *)kneeRangeOfMotionTaskWithIdentifier:(NSString *)identifier
                                             limbOption:(ORK1PredefinedTaskLimbOption)limbOption
                                 intendedUseDescription:(NSString *)intendedUseDescription
                                                options:(ORK1PredefinedTaskOption)options {
    NSMutableArray *steps = [NSMutableArray array];
    NSString *limbType = ORK1LocalizedString(@"LIMB_RIGHT", nil);
    UIImage *kneeFlexedImage = [UIImage imageNamed:@"knee_flexed_right" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    UIImage *kneeExtendedImage = [UIImage imageNamed:@"knee_extended_right" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];

    if (limbOption == ORK1PredefinedTaskLimbOptionLeft) {
        limbType = ORK1LocalizedString(@"LIMB_LEFT", nil);
    
        kneeFlexedImage = [UIImage imageNamed:@"knee_flexed_left" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
        kneeExtendedImage = [UIImage imageNamed:@"knee_extended_left" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    }
    
    if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
        ORK1InstructionStep *instructionStep0 = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction0StepIdentifier];
        instructionStep0.title = ([limbType isEqualToString:ORK1LocalizedString(@"LIMB_LEFT", nil)])? ORK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TITLE_LEFT", nil) : ORK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TITLE_RIGHT", nil);
        instructionStep0.text = intendedUseDescription;
        instructionStep0.detailText = ([limbType isEqualToString:ORK1LocalizedString(@"LIMB_LEFT", nil)])? ORK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TEXT_INSTRUCTION_0_LEFT", nil) : ORK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TEXT_INSTRUCTION_0_RIGHT", nil);
        instructionStep0.shouldTintImages = YES;
        ORK1StepArrayAddStep(steps, instructionStep0);
 
        ORK1InstructionStep *instructionStep1 = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction1StepIdentifier];
        instructionStep1.title = ([limbType isEqualToString:ORK1LocalizedString(@"LIMB_LEFT", nil)])? ORK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TITLE_LEFT", nil) : ORK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TITLE_RIGHT", nil);
        
        instructionStep1.detailText = ([limbType isEqualToString:ORK1LocalizedString(@"LIMB_LEFT", nil)])? ORK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TEXT_INSTRUCTION_1_LEFT", nil) : ORK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TEXT_INSTRUCTION_1_RIGHT", nil);
        ORK1StepArrayAddStep(steps, instructionStep1);
        
        ORK1InstructionStep *instructionStep2 = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction2StepIdentifier];
        instructionStep2.title = ([limbType isEqualToString:ORK1LocalizedString(@"LIMB_LEFT", nil)])? ORK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TITLE_LEFT", nil) : ORK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TITLE_RIGHT", nil);
        
        instructionStep2.detailText = ([limbType isEqualToString:ORK1LocalizedString(@"LIMB_LEFT", nil)])? ORK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TEXT_INSTRUCTION_2_LEFT", nil) : ORK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TEXT_INSTRUCTION_2_RIGHT", nil);
        instructionStep2.image = kneeFlexedImage;
        instructionStep2.shouldTintImages = YES;
        ORK1StepArrayAddStep(steps, instructionStep2);
        
        ORK1InstructionStep *instructionStep3 = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction3StepIdentifier];
        instructionStep3.title = ([limbType isEqualToString:ORK1LocalizedString(@"LIMB_LEFT", nil)])? ORK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TITLE_LEFT", nil) : ORK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TITLE_RIGHT", nil);
        instructionStep3.detailText = ([limbType isEqualToString:ORK1LocalizedString(@"LIMB_LEFT", nil)])? ORK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TEXT_INSTRUCTION_3_LEFT", nil) : ORK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TEXT_INSTRUCTION_3_RIGHT", nil);

        instructionStep3.image = kneeExtendedImage;
        instructionStep3.shouldTintImages = YES;
        ORK1StepArrayAddStep(steps, instructionStep3);
    }
    NSString *instructionText = ([limbType isEqualToString:ORK1LocalizedString(@"LIMB_LEFT", nil)])? ORK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TOUCH_ANYWHERE_STEP_INSTRUCTION_LEFT", nil) : ORK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TOUCH_ANYWHERE_STEP_INSTRUCTION_RIGHT", nil);
    ORK1TouchAnywhereStep *touchAnywhereStep = [[ORK1TouchAnywhereStep alloc] initWithIdentifier:ORK1TouchAnywhereStepIdentifier instructionText:instructionText];
    ORK1StepArrayAddStep(steps, touchAnywhereStep);
    
    ORK1DeviceMotionRecorderConfiguration *deviceMotionRecorderConfig = [[ORK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:ORK1DeviceMotionRecorderIdentifier frequency:100];
    
    ORK1RangeOfMotionStep *kneeRangeOfMotionStep = [[ORK1RangeOfMotionStep alloc] initWithIdentifier:ORK1KneeRangeOfMotionStepIdentifier limbOption:limbOption];
    kneeRangeOfMotionStep.title = ([limbType isEqualToString: ORK1LocalizedString(@"LIMB_LEFT", nil)])? ORK1LocalizedString(@"KNEE_RANGE_OF_MOTION_SPOKEN_INSTRUCTION_LEFT", nil) :
    ORK1LocalizedString(@"KNEE_RANGE_OF_MOTION_SPOKEN_INSTRUCTION_RIGHT", nil);
    
    kneeRangeOfMotionStep.spokenInstruction = kneeRangeOfMotionStep.title;
    kneeRangeOfMotionStep.recorderConfigurations = @[deviceMotionRecorderConfig];
    kneeRangeOfMotionStep.optional = NO;

    ORK1StepArrayAddStep(steps, kneeRangeOfMotionStep);

    if (!(options & ORK1PredefinedTaskOptionExcludeConclusion)) {
        ORK1CompletionStep *completionStep = [self makeCompletionStep];
        ORK1StepArrayAddStep(steps, completionStep);
    }
    
    ORK1OrderedTask *task = [[ORK1OrderedTask alloc] initWithIdentifier:identifier steps:steps];
    return task;
}

+ (ORK1OrderedTask *)shoulderRangeOfMotionTaskWithIdentifier:(NSString *)identifier
                                                 limbOption:(ORK1PredefinedTaskLimbOption)limbOption
                                     intendedUseDescription:(NSString *)intendedUseDescription
                                                    options:(ORK1PredefinedTaskOption)options {
    NSMutableArray *steps = [NSMutableArray array];
    NSString *limbType = ORK1LocalizedString(@"LIMB_RIGHT", nil);
    UIImage *shoulderFlexedImage = [UIImage imageNamed:@"shoulder_flexed_right" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    UIImage *shoulderExtendedImage = [UIImage imageNamed:@"shoulder_extended_right" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];

    if (limbOption == ORK1PredefinedTaskLimbOptionLeft) {
        limbType = ORK1LocalizedString(@"LIMB_LEFT", nil);
        shoulderFlexedImage = [UIImage imageNamed:@"shoulder_flexed_left" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
        shoulderExtendedImage = [UIImage imageNamed:@"shoulder_extended_left" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    }
    
    if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
        ORK1InstructionStep *instructionStep0 = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction0StepIdentifier];
        instructionStep0.title = ([limbType isEqualToString:ORK1LocalizedString(@"LIMB_LEFT", nil)])? ORK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TITLE_LEFT", nil) : ORK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TITLE_RIGHT", nil);
        instructionStep0.text = intendedUseDescription;
        instructionStep0.detailText = ([limbType isEqualToString:ORK1LocalizedString(@"LIMB_LEFT", nil)])? ORK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TEXT_INSTRUCTION_0_LEFT", nil) : ORK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TEXT_INSTRUCTION_0_RIGHT", nil);
        instructionStep0.shouldTintImages = YES;
        ORK1StepArrayAddStep(steps, instructionStep0);
        
        ORK1InstructionStep *instructionStep1 = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction1StepIdentifier];
        instructionStep1.title = ([limbType isEqualToString:ORK1LocalizedString(@"LIMB_LEFT", nil)])? ORK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TITLE_LEFT", nil) : ORK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TITLE_RIGHT", nil);
        
        instructionStep1.detailText = ([limbType isEqualToString:ORK1LocalizedString(@"LIMB_LEFT", nil)])? ORK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TEXT_INSTRUCTION_1_LEFT", nil) : ORK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TEXT_INSTRUCTION_1_RIGHT", nil);
        ORK1StepArrayAddStep(steps, instructionStep1);
        
        ORK1InstructionStep *instructionStep2 = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction2StepIdentifier];
        instructionStep2.title = ([limbType isEqualToString:ORK1LocalizedString(@"LIMB_LEFT", nil)])? ORK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TITLE_LEFT", nil) : ORK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TITLE_RIGHT", nil);
        
        instructionStep2.detailText = ([limbType isEqualToString:ORK1LocalizedString(@"LIMB_LEFT", nil)])? ORK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TEXT_INSTRUCTION_2_LEFT", nil) : ORK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TEXT_INSTRUCTION_2_RIGHT", nil);
        instructionStep2.image = shoulderFlexedImage;
        instructionStep2.shouldTintImages = YES;
        ORK1StepArrayAddStep(steps, instructionStep2);
        
        ORK1InstructionStep *instructionStep3 = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction3StepIdentifier];
        instructionStep3.title = ([limbType isEqualToString:ORK1LocalizedString(@"LIMB_LEFT", nil)])? ORK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TITLE_LEFT", nil) : ORK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TITLE_RIGHT", nil);
        
        instructionStep3.detailText = ([limbType isEqualToString:ORK1LocalizedString(@"LIMB_LEFT", nil)])? ORK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TEXT_INSTRUCTION_3_LEFT", nil) : ORK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TEXT_INSTRUCTION_3_RIGHT", nil);
        instructionStep3.image = shoulderExtendedImage;
        instructionStep3.shouldTintImages = YES;
        ORK1StepArrayAddStep(steps, instructionStep3);
    }
    
    NSString *instructionText = ([limbType isEqualToString:ORK1LocalizedString(@"LIMB_LEFT", nil)])? ORK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TOUCH_ANYWHERE_STEP_INSTRUCTION_LEFT", nil) : ORK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TOUCH_ANYWHERE_STEP_INSTRUCTION_RIGHT", nil);
    ORK1TouchAnywhereStep *touchAnywhereStep = [[ORK1TouchAnywhereStep alloc] initWithIdentifier:ORK1TouchAnywhereStepIdentifier instructionText:instructionText];
    ORK1StepArrayAddStep(steps, touchAnywhereStep);
    
    ORK1DeviceMotionRecorderConfiguration *deviceMotionRecorderConfig = [[ORK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:ORK1DeviceMotionRecorderIdentifier frequency:100];
    
    ORK1ShoulderRangeOfMotionStep *shoulderRangeOfMotionStep = [[ORK1ShoulderRangeOfMotionStep alloc] initWithIdentifier:ORK1ShoulderRangeOfMotionStepIdentifier limbOption:limbOption];
    shoulderRangeOfMotionStep.title = ([limbType isEqualToString: ORK1LocalizedString(@"LIMB_LEFT", nil)])? ORK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_SPOKEN_INSTRUCTION_LEFT", nil) :
    ORK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_SPOKEN_INSTRUCTION_RIGHT", nil);

    shoulderRangeOfMotionStep.spokenInstruction = shoulderRangeOfMotionStep.title;
    
    shoulderRangeOfMotionStep.recorderConfigurations = @[deviceMotionRecorderConfig];
    shoulderRangeOfMotionStep.optional = NO;
    
    ORK1StepArrayAddStep(steps, shoulderRangeOfMotionStep);
    
    if (!(options & ORK1PredefinedTaskOptionExcludeConclusion)) {
        ORK1CompletionStep *completionStep = [self makeCompletionStep];
        ORK1StepArrayAddStep(steps, completionStep);
    }
    
    ORK1OrderedTask *task = [[ORK1OrderedTask alloc] initWithIdentifier:identifier steps:steps];
    return task;
}

+ (ORK1OrderedTask *)spatialSpanMemoryTaskWithIdentifier:(NSString *)identifier
                                 intendedUseDescription:(NSString *)intendedUseDescription
                                            initialSpan:(NSInteger)initialSpan
                                            minimumSpan:(NSInteger)minimumSpan
                                            maximumSpan:(NSInteger)maximumSpan
                                              playSpeed:(NSTimeInterval)playSpeed
                                               maximumTests:(NSInteger)maximumTests
                                 maximumConsecutiveFailures:(NSInteger)maximumConsecutiveFailures
                                      customTargetImage:(UIImage *)customTargetImage
                                 customTargetPluralName:(NSString *)customTargetPluralName
                                        requireReversal:(BOOL)requireReversal
                                                options:(ORK1PredefinedTaskOption)options {
    
    NSString *targetPluralName = customTargetPluralName ? : ORK1LocalizedString(@"SPATIAL_SPAN_MEMORY_TARGET_PLURAL", nil);
    
    NSMutableArray *steps = [NSMutableArray array];
    if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction0StepIdentifier];
            step.title = ORK1LocalizedString(@"SPATIAL_SPAN_MEMORY_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = [NSString localizedStringWithFormat:ORK1LocalizedString(@"SPATIAL_SPAN_MEMORY_INTRO_TEXT_%@", nil),targetPluralName];
            
            step.image = [UIImage imageNamed:@"phone-memory" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
        
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction1StepIdentifier];
            step.title = ORK1LocalizedString(@"SPATIAL_SPAN_MEMORY_TITLE", nil);
            step.text = [NSString localizedStringWithFormat:requireReversal ? ORK1LocalizedString(@"SPATIAL_SPAN_MEMORY_INTRO_2_TEXT_REVERSE_%@", nil) : ORK1LocalizedString(@"SPATIAL_SPAN_MEMORY_INTRO_2_TEXT_%@", nil), targetPluralName, targetPluralName];
            step.detailText = ORK1LocalizedString(@"SPATIAL_SPAN_MEMORY_CALL_TO_ACTION", nil);
            
            if (!customTargetImage) {
                step.image = [UIImage imageNamed:@"memory-second-screen" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            } else {
                step.image = customTargetImage;
            }
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
    }
    
    {
        ORK1SpatialSpanMemoryStep *step = [[ORK1SpatialSpanMemoryStep alloc] initWithIdentifier:ORK1SpatialSpanMemoryStepIdentifier];
        step.title = nil;
        step.text = nil;
        
        step.initialSpan = initialSpan;
        step.minimumSpan = minimumSpan;
        step.maximumSpan = maximumSpan;
        step.playSpeed = playSpeed;
        step.maximumTests = maximumTests;
        step.maximumConsecutiveFailures = maximumConsecutiveFailures;
        step.customTargetImage = customTargetImage;
        step.customTargetPluralName = customTargetPluralName;
        step.requireReversal = requireReversal;
        
        ORK1StepArrayAddStep(steps, step);
    }
    
    if (!(options & ORK1PredefinedTaskOptionExcludeConclusion)) {
        ORK1InstructionStep *step = [self makeCompletionStep];
        ORK1StepArrayAddStep(steps, step);
    }
    
    ORK1OrderedTask *task = [[ORK1OrderedTask alloc] initWithIdentifier:identifier steps:steps];
    return task;
}

+ (ORK1OrderedTask *)stroopTaskWithIdentifier:(NSString *)identifier
                      intendedUseDescription:(nullable NSString *)intendedUseDescription
                            numberOfAttempts:(NSInteger)numberOfAttempts
                                     options:(ORK1PredefinedTaskOption)options {
    NSMutableArray *steps = [NSMutableArray array];
    if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction0StepIdentifier];
            step.title = ORK1LocalizedString(@"STROOP_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.image = [UIImage imageNamed:@"phonestrooplabel" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction1StepIdentifier];
            step.title = ORK1LocalizedString(@"STROOP_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = ORK1LocalizedString(@"STROOP_TASK_INTRO1_DETAIL_TEXT", nil);
            step.image = [UIImage imageNamed:@"phonestroopbutton" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction2StepIdentifier];
            step.title = ORK1LocalizedString(@"STROOP_TASK_TITLE", nil);
            step.detailText = ORK1LocalizedString(@"STROOP_TASK_INTRO2_DETAIL_TEXT", nil);
            step.image = [UIImage imageNamed:@"phonestroopbutton" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
    }
    {
        ORK1CountdownStep *step = [[ORK1CountdownStep alloc] initWithIdentifier:ORK1CountdownStepIdentifier];
        step.stepDuration = 5.0;
        
        ORK1StepArrayAddStep(steps, step);
    }
    {
        ORK1StroopStep *step = [[ORK1StroopStep alloc] initWithIdentifier:ORK1StroopStepIdentifier];
        step.text = ORK1LocalizedString(@"STROOP_TASK_STEP_TEXT", nil);
        step.numberOfAttempts = numberOfAttempts;
        
        ORK1StepArrayAddStep(steps, step);
    }
    
    if (!(options & ORK1PredefinedTaskOptionExcludeConclusion)) {
        ORK1InstructionStep *step = [self makeCompletionStep];
        
        ORK1StepArrayAddStep(steps, step);
    }
    
    ORK1OrderedTask *task = [[ORK1OrderedTask alloc] initWithIdentifier:identifier steps:steps];
    return task;
}

+ (ORK1OrderedTask *)toneAudiometryTaskWithIdentifier:(NSString *)identifier
                              intendedUseDescription:(nullable NSString *)intendedUseDescription
                                   speechInstruction:(nullable NSString *)speechInstruction
                              shortSpeechInstruction:(nullable NSString *)shortSpeechInstruction
                                        toneDuration:(NSTimeInterval)toneDuration
                                             options:(ORK1PredefinedTaskOption)options {

    if (options & ORK1PredefinedTaskOptionExcludeAudio) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"Audio collection cannot be excluded from audio task" userInfo:nil];
    }

    NSMutableArray *steps = [NSMutableArray array];
    if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction0StepIdentifier];
            step.title = ORK1LocalizedString(@"TONE_AUDIOMETRY_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = ORK1LocalizedString(@"TONE_AUDIOMETRY_INTENDED_USE", nil);
            step.image = [UIImage imageNamed:@"phonewaves_inverted" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;

            ORK1StepArrayAddStep(steps, step);
        }
        
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction1StepIdentifier];
            step.title = ORK1LocalizedString(@"TONE_AUDIOMETRY_TASK_TITLE", nil);
            step.text = speechInstruction ? : ORK1LocalizedString(@"TONE_AUDIOMETRY_INTRO_TEXT", nil);
            step.detailText = ORK1LocalizedString(@"TONE_AUDIOMETRY_CALL_TO_ACTION", nil);
            step.image = [UIImage imageNamed:@"phonewaves_tapping" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;

            ORK1StepArrayAddStep(steps, step);
        }
    }

    {
        ORK1ToneAudiometryPracticeStep *step = [[ORK1ToneAudiometryPracticeStep alloc] initWithIdentifier:ORK1ToneAudiometryPracticeStepIdentifier];
        step.title = ORK1LocalizedString(@"TONE_AUDIOMETRY_TASK_TITLE", nil);
        step.text = speechInstruction ? : ORK1LocalizedString(@"TONE_AUDIOMETRY_PREP_TEXT", nil);
        ORK1StepArrayAddStep(steps, step);
        
    }
    
    {
        ORK1CountdownStep *step = [[ORK1CountdownStep alloc] initWithIdentifier:ORK1CountdownStepIdentifier];
        step.stepDuration = 5.0;

        ORK1StepArrayAddStep(steps, step);
    }

    {
        ORK1ToneAudiometryStep *step = [[ORK1ToneAudiometryStep alloc] initWithIdentifier:ORK1ToneAudiometryStepIdentifier];
        step.title = shortSpeechInstruction ? : ORK1LocalizedString(@"TONE_AUDIOMETRY_INSTRUCTION", nil);
        step.toneDuration = toneDuration;

        ORK1StepArrayAddStep(steps, step);
    }

    if (!(options & ORK1PredefinedTaskOptionExcludeConclusion)) {
        ORK1InstructionStep *step = [self makeCompletionStep];

        ORK1StepArrayAddStep(steps, step);
    }

    ORK1OrderedTask *task = [[ORK1OrderedTask alloc] initWithIdentifier:identifier steps:steps];

    return task;
}

+ (ORK1OrderedTask *)towerOfHanoiTaskWithIdentifier:(NSString *)identifier
                            intendedUseDescription:(nullable NSString *)intendedUseDescription
                                     numberOfDisks:(NSUInteger)numberOfDisks
                                           options:(ORK1PredefinedTaskOption)options {
    
    NSMutableArray *steps = [NSMutableArray array];
    
    if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction0StepIdentifier];
            step.title = ORK1LocalizedString(@"TOWER_OF_HANOI_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = ORK1LocalizedString(@"TOWER_OF_HANOI_TASK_INTENDED_USE", nil);
            step.image = [UIImage imageNamed:@"phone-tower-of-hanoi" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
        
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction1StepIdentifier];
            step.title = ORK1LocalizedString(@"TOWER_OF_HANOI_TASK_TITLE", nil);
            step.text = ORK1LocalizedString(@"TOWER_OF_HANOI_TASK_INTRO_TEXT", nil);
            step.detailText = ORK1LocalizedString(@"TOWER_OF_HANOI_TASK_TASK_CALL_TO_ACTION", nil);
            step.image = [UIImage imageNamed:@"tower-of-hanoi-second-screen" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
    }
    
    ORK1TowerOfHanoiStep *towerOfHanoiStep = [[ORK1TowerOfHanoiStep alloc]initWithIdentifier:ORK1TowerOfHanoiStepIdentifier];
    towerOfHanoiStep.numberOfDisks = numberOfDisks;
    ORK1StepArrayAddStep(steps, towerOfHanoiStep);
    
    if (!(options & ORK1PredefinedTaskOptionExcludeConclusion)) {
        ORK1InstructionStep *step = [self makeCompletionStep];
        
        ORK1StepArrayAddStep(steps, step);
    }
    
    ORK1OrderedTask *task = [[ORK1OrderedTask alloc]initWithIdentifier:identifier steps:steps];
    
    return task;
}

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
                                           options:(ORK1PredefinedTaskOption)options {
    
    NSMutableArray *steps = [NSMutableArray array];
    
    if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction0StepIdentifier];
            step.title = ORK1LocalizedString(@"REACTION_TIME_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = ORK1LocalizedString(@"REACTION_TIME_TASK_INTENDED_USE", nil);
            step.image = [UIImage imageNamed:@"phoneshake" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
        
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction1StepIdentifier];
            step.title = ORK1LocalizedString(@"REACTION_TIME_TASK_TITLE", nil);
            step.text = [NSString localizedStringWithFormat: ORK1LocalizedString(@"REACTION_TIME_TASK_INTRO_TEXT_FORMAT", nil), numberOfAttempts];
            step.detailText = ORK1LocalizedString(@"REACTION_TIME_TASK_CALL_TO_ACTION", nil);
            step.image = [UIImage imageNamed:@"phoneshakecircle" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
    }
    
    ORK1ReactionTimeStep *step = [[ORK1ReactionTimeStep alloc] initWithIdentifier:ORK1ReactionTimeStepIdentifier];
    step.maximumStimulusInterval = maximumStimulusInterval;
    step.minimumStimulusInterval = minimumStimulusInterval;
    step.thresholdAcceleration = thresholdAcceleration;
    step.numberOfAttempts = numberOfAttempts;
    step.timeout = timeout;
    step.successSound = successSoundID;
    step.timeoutSound = timeoutSoundID;
    step.failureSound = failureSoundID;
    step.recorderConfigurations = @[ [[ORK1DeviceMotionRecorderConfiguration  alloc] initWithIdentifier:ORK1DeviceMotionRecorderIdentifier frequency: 100]];

    ORK1StepArrayAddStep(steps, step);
    
    if (!(options & ORK1PredefinedTaskOptionExcludeConclusion)) {
        ORK1InstructionStep *step = [self makeCompletionStep];
        ORK1StepArrayAddStep(steps, step);
    }
    
    ORK1OrderedTask *task = [[ORK1OrderedTask alloc] initWithIdentifier:identifier steps:steps];
    
    return task;
}

+ (ORK1OrderedTask *)timedWalkTaskWithIdentifier:(NSString *)identifier
                         intendedUseDescription:(nullable NSString *)intendedUseDescription
                               distanceInMeters:(double)distanceInMeters
                                      timeLimit:(NSTimeInterval)timeLimit
                     includeAssistiveDeviceForm:(BOOL)includeAssistiveDeviceForm
                                        options:(ORK1PredefinedTaskOption)options {

    NSMutableArray *steps = [NSMutableArray array];

    NSLengthFormatter *lengthFormatter = [NSLengthFormatter new];
    lengthFormatter.numberFormatter.maximumFractionDigits = 1;
    lengthFormatter.numberFormatter.maximumSignificantDigits = 3;
    NSString *formattedLength = [lengthFormatter stringFromMeters:distanceInMeters];

    if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction0StepIdentifier];
            step.title = ORK1LocalizedString(@"TIMED_WALK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = ORK1LocalizedString(@"TIMED_WALK_INTRO_DETAIL", nil);
            step.shouldTintImages = YES;

            ORK1StepArrayAddStep(steps, step);
        }
    }

    if (includeAssistiveDeviceForm) {
        ORK1FormStep *step = [[ORK1FormStep alloc] initWithIdentifier:ORK1TimedWalkFormStepIdentifier
                                                              title:ORK1LocalizedString(@"TIMED_WALK_FORM_TITLE", nil)
                                                               text:ORK1LocalizedString(@"TIMED_WALK_FORM_TEXT", nil)];

        ORK1AnswerFormat *answerFormat1 = [ORK1AnswerFormat booleanAnswerFormat];
        ORK1FormItem *formItem1 = [[ORK1FormItem alloc] initWithIdentifier:ORK1TimedWalkFormAFOStepIdentifier
                                                                    text:ORK1LocalizedString(@"TIMED_WALK_QUESTION_TEXT", nil)
                                                            answerFormat:answerFormat1];
        formItem1.optional = NO;

        NSArray *textChoices = @[ORK1LocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE", nil),
                                 ORK1LocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_2", nil),
                                 ORK1LocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_3", nil),
                                 ORK1LocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_4", nil),
                                 ORK1LocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_5", nil),
                                 ORK1LocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_6", nil)];
        ORK1AnswerFormat *answerFormat2 = [ORK1AnswerFormat valuePickerAnswerFormatWithTextChoices:textChoices];
        ORK1FormItem *formItem2 = [[ORK1FormItem alloc] initWithIdentifier:ORK1TimedWalkFormAssistanceStepIdentifier
                                                                    text:ORK1LocalizedString(@"TIMED_WALK_QUESTION_2_TITLE", nil)
                                                            answerFormat:answerFormat2];
        formItem2.placeholder = ORK1LocalizedString(@"TIMED_WALK_QUESTION_2_TEXT", nil);
        formItem2.optional = NO;

        step.formItems = @[formItem1, formItem2];
        step.optional = NO;

        ORK1StepArrayAddStep(steps, step);
    }

    if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction1StepIdentifier];
            step.title = ORK1LocalizedString(@"TIMED_WALK_TITLE", nil);
            step.text = [NSString localizedStringWithFormat:ORK1LocalizedString(@"TIMED_WALK_INTRO_2_TEXT_%@", nil), formattedLength];
            step.detailText = ORK1LocalizedString(@"TIMED_WALK_INTRO_2_DETAIL", nil);
            step.image = [UIImage imageNamed:@"timer" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;

            ORK1StepArrayAddStep(steps, step);
        }
    }

    {
        ORK1CountdownStep *step = [[ORK1CountdownStep alloc] initWithIdentifier:ORK1CountdownStepIdentifier];
        step.stepDuration = 5.0;

        ORK1StepArrayAddStep(steps, step);
    }
    
    {
        NSMutableArray *recorderConfigurations = [NSMutableArray array];
        if (!(options & ORK1PredefinedTaskOptionExcludePedometer)) {
            [recorderConfigurations addObject:[[ORK1PedometerRecorderConfiguration alloc] initWithIdentifier:ORK1PedometerRecorderIdentifier]];
        }
        if (!(options & ORK1PredefinedTaskOptionExcludeAccelerometer)) {
            [recorderConfigurations addObject:[[ORK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:ORK1AccelerometerRecorderIdentifier
                                                                                                      frequency:100]];
        }
        if (!(options & ORK1PredefinedTaskOptionExcludeDeviceMotion)) {
            [recorderConfigurations addObject:[[ORK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:ORK1DeviceMotionRecorderIdentifier
                                                                                                     frequency:100]];
        }
        if (! (options & ORK1PredefinedTaskOptionExcludeLocation)) {
            [recorderConfigurations addObject:[[ORK1LocationRecorderConfiguration alloc] initWithIdentifier:ORK1LocationRecorderIdentifier]];
        }

        {
            ORK1TimedWalkStep *step = [[ORK1TimedWalkStep alloc] initWithIdentifier:ORK1TimedWalkTrial1StepIdentifier];
            step.title = [[NSString alloc] initWithFormat:ORK1LocalizedString(@"TIMED_WALK_INSTRUCTION_%@", nil), formattedLength];
            step.text = ORK1LocalizedString(@"TIMED_WALK_INSTRUCTION_TEXT", nil);
            step.spokenInstruction = step.title;
            step.recorderConfigurations = recorderConfigurations;
            step.distanceInMeters = distanceInMeters;
            step.shouldTintImages = YES;
            step.image = [UIImage imageNamed:@"timed-walkingman-outbound" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.stepDuration = timeLimit == 0 ? CGFLOAT_MAX : timeLimit;

            ORK1StepArrayAddStep(steps, step);
        }

        {
            ORK1TimedWalkStep *step = [[ORK1TimedWalkStep alloc] initWithIdentifier:ORK1TimedWalkTrial2StepIdentifier];
            step.title = [[NSString alloc] initWithFormat:ORK1LocalizedString(@"TIMED_WALK_INSTRUCTION_2", nil), formattedLength];
            step.text = ORK1LocalizedString(@"TIMED_WALK_INSTRUCTION_TEXT", nil);
            step.spokenInstruction = step.title;
            step.recorderConfigurations = recorderConfigurations;
            step.distanceInMeters = distanceInMeters;
            step.shouldTintImages = YES;
            step.image = [UIImage imageNamed:@"timed-walkingman-return" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.stepDuration = timeLimit == 0 ? CGFLOAT_MAX : timeLimit;

            ORK1StepArrayAddStep(steps, step);
        }
    }

    if (!(options & ORK1PredefinedTaskOptionExcludeConclusion)) {
        ORK1InstructionStep *step = [self makeCompletionStep];

        ORK1StepArrayAddStep(steps, step);
    }

    ORK1OrderedTask *task = [[ORK1OrderedTask alloc] initWithIdentifier:identifier steps:steps];
    return task;
}

+ (ORK1OrderedTask *)timedWalkTaskWithIdentifier:(NSString *)identifier
                         intendedUseDescription:(nullable NSString *)intendedUseDescription
                               distanceInMeters:(double)distanceInMeters
                                      timeLimit:(NSTimeInterval)timeLimit
                            turnAroundTimeLimit:(NSTimeInterval)turnAroundTimeLimit
                     includeAssistiveDeviceForm:(BOOL)includeAssistiveDeviceForm
                                        options:(ORK1PredefinedTaskOption)options {

    NSMutableArray *steps = [NSMutableArray array];

    NSLengthFormatter *lengthFormatter = [NSLengthFormatter new];
    lengthFormatter.numberFormatter.maximumFractionDigits = 1;
    lengthFormatter.numberFormatter.maximumSignificantDigits = 3;
    NSString *formattedLength = [lengthFormatter stringFromMeters:distanceInMeters];

    if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction0StepIdentifier];
            step.title = ORK1LocalizedString(@"TIMED_WALK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = ORK1LocalizedString(@"TIMED_WALK_INTRO_DETAIL", nil);
            step.shouldTintImages = YES;

            ORK1StepArrayAddStep(steps, step);
        }
    }

    if (includeAssistiveDeviceForm) {
        ORK1FormStep *step = [[ORK1FormStep alloc] initWithIdentifier:ORK1TimedWalkFormStepIdentifier
                                                              title:ORK1LocalizedString(@"TIMED_WALK_FORM_TITLE", nil)
                                                               text:ORK1LocalizedString(@"TIMED_WALK_FORM_TEXT", nil)];

        ORK1AnswerFormat *answerFormat1 = [ORK1AnswerFormat booleanAnswerFormat];
        ORK1FormItem *formItem1 = [[ORK1FormItem alloc] initWithIdentifier:ORK1TimedWalkFormAFOStepIdentifier
                                                                    text:ORK1LocalizedString(@"TIMED_WALK_QUESTION_TEXT", nil)
                                                            answerFormat:answerFormat1];
        formItem1.optional = NO;

        NSArray *textChoices = @[ORK1LocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE", nil),
                                 ORK1LocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_2", nil),
                                 ORK1LocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_3", nil),
                                 ORK1LocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_4", nil),
                                 ORK1LocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_5", nil),
                                 ORK1LocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_6", nil)];
        ORK1AnswerFormat *answerFormat2 = [ORK1AnswerFormat valuePickerAnswerFormatWithTextChoices:textChoices];
        ORK1FormItem *formItem2 = [[ORK1FormItem alloc] initWithIdentifier:ORK1TimedWalkFormAssistanceStepIdentifier
                                                                    text:ORK1LocalizedString(@"TIMED_WALK_QUESTION_2_TITLE", nil)
                                                            answerFormat:answerFormat2];
        formItem2.placeholder = ORK1LocalizedString(@"TIMED_WALK_QUESTION_2_TEXT", nil);
        formItem2.optional = NO;

        step.formItems = @[formItem1, formItem2];
        step.optional = NO;

        ORK1StepArrayAddStep(steps, step);
    }

    if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction1StepIdentifier];
            step.title = ORK1LocalizedString(@"TIMED_WALK_TITLE", nil);
            step.text = [NSString localizedStringWithFormat:ORK1LocalizedString(@"TIMED_WALK_INTRO_2_TEXT_%@", nil), formattedLength];
            step.detailText = ORK1LocalizedString(@"TIMED_WALK_INTRO_2_DETAIL", nil);
            step.image = [UIImage imageNamed:@"timer" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;

            ORK1StepArrayAddStep(steps, step);
        }
    }

    {
        ORK1CountdownStep *step = [[ORK1CountdownStep alloc] initWithIdentifier:ORK1CountdownStepIdentifier];
        step.stepDuration = 5.0;

        ORK1StepArrayAddStep(steps, step);
    }

    {
        NSMutableArray *recorderConfigurations = [NSMutableArray array];
        if (!(options & ORK1PredefinedTaskOptionExcludePedometer)) {
            [recorderConfigurations addObject:[[ORK1PedometerRecorderConfiguration alloc] initWithIdentifier:ORK1PedometerRecorderIdentifier]];
        }
        if (!(options & ORK1PredefinedTaskOptionExcludeAccelerometer)) {
            [recorderConfigurations addObject:[[ORK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:ORK1AccelerometerRecorderIdentifier
                                                                                                      frequency:100]];
        }
        if (!(options & ORK1PredefinedTaskOptionExcludeDeviceMotion)) {
            [recorderConfigurations addObject:[[ORK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:ORK1DeviceMotionRecorderIdentifier
                                                                                                     frequency:100]];
        }
        if (! (options & ORK1PredefinedTaskOptionExcludeLocation)) {
            [recorderConfigurations addObject:[[ORK1LocationRecorderConfiguration alloc] initWithIdentifier:ORK1LocationRecorderIdentifier]];
        }

        {
            ORK1TimedWalkStep *step = [[ORK1TimedWalkStep alloc] initWithIdentifier:ORK1TimedWalkTrial1StepIdentifier];
            step.title = [[NSString alloc] initWithFormat:ORK1LocalizedString(@"TIMED_WALK_INSTRUCTION_%@", nil), formattedLength];
            step.text = ORK1LocalizedString(@"TIMED_WALK_INSTRUCTION_TEXT", nil);
            step.spokenInstruction = step.title;
            step.recorderConfigurations = recorderConfigurations;
            step.distanceInMeters = distanceInMeters;
            step.shouldTintImages = YES;
            step.image = [UIImage imageNamed:@"timed-walkingman-outbound" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.stepDuration = timeLimit == 0 ? CGFLOAT_MAX : timeLimit;

            ORK1StepArrayAddStep(steps, step);
        }

        {
            ORK1TimedWalkStep *step = [[ORK1TimedWalkStep alloc] initWithIdentifier:ORK1TimedWalkTurnAroundStepIdentifier];
            step.title = ORK1LocalizedString(@"TIMED_WALK_INSTRUCTION_TURN", nil);
            step.text = ORK1LocalizedString(@"TIMED_WALK_INSTRUCTION_TEXT", nil);
            step.spokenInstruction = step.title;
            step.recorderConfigurations = recorderConfigurations;
            step.distanceInMeters = 1;
            step.shouldTintImages = YES;
            step.image = [UIImage imageNamed:@"turnaround" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.stepDuration = turnAroundTimeLimit == 0 ? CGFLOAT_MAX : turnAroundTimeLimit;

            ORK1StepArrayAddStep(steps, step);
        }

        {
            ORK1TimedWalkStep *step = [[ORK1TimedWalkStep alloc] initWithIdentifier:ORK1TimedWalkTrial2StepIdentifier];
            step.title = [[NSString alloc] initWithFormat:ORK1LocalizedString(@"TIMED_WALK_INSTRUCTION_2", nil), formattedLength];
            step.text = ORK1LocalizedString(@"TIMED_WALK_INSTRUCTION_TEXT", nil);
            step.spokenInstruction = step.title;
            step.recorderConfigurations = recorderConfigurations;
            step.distanceInMeters = distanceInMeters;
            step.shouldTintImages = YES;
            step.image = [UIImage imageNamed:@"timed-walkingman-return" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.stepDuration = timeLimit == 0 ? CGFLOAT_MAX : timeLimit;

            ORK1StepArrayAddStep(steps, step);
        }
    }

    if (!(options & ORK1PredefinedTaskOptionExcludeConclusion)) {
        ORK1InstructionStep *step = [self makeCompletionStep];

        ORK1StepArrayAddStep(steps, step);
    }

    ORK1OrderedTask *task = [[ORK1OrderedTask alloc] initWithIdentifier:identifier steps:steps];
    return task;
}

+ (ORK1OrderedTask *)PSATTaskWithIdentifier:(NSString *)identifier
                    intendedUseDescription:(nullable NSString *)intendedUseDescription
                          presentationMode:(ORK1PSATPresentationMode)presentationMode
                     interStimulusInterval:(NSTimeInterval)interStimulusInterval
                          stimulusDuration:(NSTimeInterval)stimulusDuration
                              seriesLength:(NSInteger)seriesLength
                                   options:(ORK1PredefinedTaskOption)options {
    
    NSMutableArray *steps = [NSMutableArray array];
    NSString *versionTitle = @"";
    NSString *versionDetailText = @"";
    
    if (presentationMode == ORK1PSATPresentationModeAuditory) {
        versionTitle = ORK1LocalizedString(@"PASAT_TITLE", nil);
        versionDetailText = ORK1LocalizedString(@"PASAT_INTRO_TEXT", nil);
    } else if (presentationMode == ORK1PSATPresentationModeVisual) {
        versionTitle = ORK1LocalizedString(@"PVSAT_TITLE", nil);
        versionDetailText = ORK1LocalizedString(@"PVSAT_INTRO_TEXT", nil);
    } else {
        versionTitle = ORK1LocalizedString(@"PAVSAT_TITLE", nil);
        versionDetailText = ORK1LocalizedString(@"PAVSAT_INTRO_TEXT", nil);
    }
    
    if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction0StepIdentifier];
            step.title = versionTitle;
            step.detailText = versionDetailText;
            step.text = intendedUseDescription;
            step.image = [UIImage imageNamed:@"phonepsat" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction1StepIdentifier];
            step.title = versionTitle;
            step.text = [NSString localizedStringWithFormat:ORK1LocalizedString(@"PSAT_INTRO_TEXT_2_%@", nil), [NSNumberFormatter localizedStringFromNumber:@(interStimulusInterval) numberStyle:NSNumberFormatterDecimalStyle]];
            step.detailText = ORK1LocalizedString(@"PSAT_CALL_TO_ACTION", nil);
            
            ORK1StepArrayAddStep(steps, step);
        }
    }
    
    {
        ORK1CountdownStep *step = [[ORK1CountdownStep alloc] initWithIdentifier:ORK1CountdownStepIdentifier];
        step.stepDuration = 5.0;
        
        ORK1StepArrayAddStep(steps, step);
    }
    
    {
        ORK1PSATStep *step = [[ORK1PSATStep alloc] initWithIdentifier:ORK1PSATStepIdentifier];
        step.title = ORK1LocalizedString(@"PSAT_INITIAL_INSTRUCTION", nil);
        step.stepDuration = (seriesLength + 1) * interStimulusInterval;
        step.presentationMode = presentationMode;
        step.interStimulusInterval = interStimulusInterval;
        step.stimulusDuration = stimulusDuration;
        step.seriesLength = seriesLength;
        
        ORK1StepArrayAddStep(steps, step);
    }
    
    if (!(options & ORK1PredefinedTaskOptionExcludeConclusion)) {
        ORK1InstructionStep *step = [self makeCompletionStep];
        
        ORK1StepArrayAddStep(steps, step);
    }
    
    ORK1OrderedTask *task = [[ORK1OrderedTask alloc] initWithIdentifier:identifier steps:[steps copy]];
    
    return task;
}

+ (NSString *)stepIdentifier:(NSString *)stepIdentifier withHandIdentifier:(NSString *)handIdentifier {
    return [NSString stringWithFormat:@"%@.%@", stepIdentifier, handIdentifier];
}

+ (NSMutableArray *)stepsForOneHandTremorTestTaskWithIdentifier:(NSString *)identifier
                                             activeStepDuration:(NSTimeInterval)activeStepDuration
                                              activeTaskOptions:(ORK1TremorActiveTaskOption)activeTaskOptions
                                                       lastHand:(BOOL)lastHand
                                                       leftHand:(BOOL)leftHand
                                                 handIdentifier:(NSString *)handIdentifier
                                                introDetailText:(NSString *)detailText
                                                        options:(ORK1PredefinedTaskOption)options {
    NSMutableArray<ORK1ActiveStep *> *steps = [NSMutableArray array];
    NSString *stepFinishedInstruction = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_FINISHED_INSTRUCTION", nil);
    BOOL rightHand = !leftHand && ![handIdentifier isEqualToString:ORK1ActiveTaskMostAffectedHandIdentifier];
    
    {
        NSString *stepIdentifier = [self stepIdentifier:ORK1Instruction1StepIdentifier withHandIdentifier:handIdentifier];
        ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:stepIdentifier];
        step.title = ORK1LocalizedString(@"TREMOR_TEST_TITLE", nil);
        
        if ([identifier isEqualToString:ORK1ActiveTaskMostAffectedHandIdentifier]) {
            step.text = ORK1LocalizedString(@"TREMOR_TEST_INTRO_2_DEFAULT_TEXT", nil);
            step.detailText = detailText;
        } else {
            if (leftHand) {
                step.text = ORK1LocalizedString(@"TREMOR_TEST_INTRO_2_LEFT_HAND_TEXT", nil);
            } else {
                step.text = ORK1LocalizedString(@"TREMOR_TEST_INTRO_2_RIGHT_HAND_TEXT", nil);
            }
        }
        
        NSString *imageName = leftHand ? @"tremortestLeft" : @"tremortestRight";
        step.image = [UIImage imageNamed:imageName inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
        step.shouldTintImages = YES;
        
        ORK1StepArrayAddStep(steps, step);
    }

    if (!(activeTaskOptions & ORK1TremorActiveTaskOptionExcludeHandInLap)) {
        if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
            NSString *stepIdentifier = [self stepIdentifier:ORK1Instruction2StepIdentifier withHandIdentifier:handIdentifier];
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:stepIdentifier];
            step.title = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_IN_LAP_INTRO", nil);
            step.text = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_INTRO_TEXT", nil);
            step.image = [UIImage imageNamed:@"tremortest3a" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.auxiliaryImage = [UIImage imageNamed:@"tremortest3b" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            if (leftHand) {
                step.title = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_IN_LAP_INTRO_LEFT", nil);
                step.image = [step.image ork_flippedImage:UIImageOrientationUpMirrored];
                step.auxiliaryImage = [step.auxiliaryImage ork_flippedImage:UIImageOrientationUpMirrored];
            } else if (rightHand) {
                step.title = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_IN_LAP_INTRO_RIGHT", nil);
            }
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
        
        {
            NSString *stepIdentifier = [self stepIdentifier:ORK1Countdown1StepIdentifier withHandIdentifier:handIdentifier];
            ORK1CountdownStep *step = [[ORK1CountdownStep alloc] initWithIdentifier:stepIdentifier];
            
            ORK1StepArrayAddStep(steps, step);
        }
        
        {
            NSString *titleFormat = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_IN_LAP_INSTRUCTION_%ld", nil);
            NSString *stepIdentifier = [self stepIdentifier:ORK1TremorTestInLapStepIdentifier withHandIdentifier:handIdentifier];
            ORK1ActiveStep *step = [[ORK1ActiveStep alloc] initWithIdentifier:stepIdentifier];
            step.recorderConfigurations = @[[[ORK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:@"ac1_acc" frequency:100.0], [[ORK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:@"ac1_motion" frequency:100.0]];
            step.title = [NSString localizedStringWithFormat:titleFormat, (long)activeStepDuration];
            step.spokenInstruction = step.title;
            step.finishedSpokenInstruction = stepFinishedInstruction;
            step.stepDuration = activeStepDuration;
            step.shouldPlaySoundOnStart = YES;
            step.shouldVibrateOnStart = YES;
            step.shouldPlaySoundOnFinish = YES;
            step.shouldVibrateOnFinish = YES;
            step.shouldContinueOnFinish = NO;
            step.shouldStartTimerAutomatically = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
    }
    
    if (!(activeTaskOptions & ORK1TremorActiveTaskOptionExcludeHandAtShoulderHeight)) {
        if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
            NSString *stepIdentifier = [self stepIdentifier:ORK1Instruction4StepIdentifier withHandIdentifier:handIdentifier];
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:stepIdentifier];
            step.title = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_EXTEND_ARM_INTRO", nil);
            step.text = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_INTRO_TEXT", nil);
            step.image = [UIImage imageNamed:@"tremortest4a" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.auxiliaryImage = [UIImage imageNamed:@"tremortest4b" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            if (leftHand) {
                step.title = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_EXTEND_ARM_INTRO_LEFT", nil);
                step.image = [step.image ork_flippedImage:UIImageOrientationUpMirrored];
                step.auxiliaryImage = [step.auxiliaryImage ork_flippedImage:UIImageOrientationUpMirrored];
            } else if (rightHand) {
                step.title = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_EXTEND_ARM_INTRO_RIGHT", nil);
            }
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
        
        {
            NSString *stepIdentifier = [self stepIdentifier:ORK1Countdown2StepIdentifier withHandIdentifier:handIdentifier];
            ORK1CountdownStep *step = [[ORK1CountdownStep alloc] initWithIdentifier:stepIdentifier];
            
            ORK1StepArrayAddStep(steps, step);
        }
        
        {
            NSString *titleFormat = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_EXTEND_ARM_INSTRUCTION_%ld", nil);
            NSString *stepIdentifier = [self stepIdentifier:ORK1TremorTestExtendArmStepIdentifier withHandIdentifier:handIdentifier];
            ORK1ActiveStep *step = [[ORK1ActiveStep alloc] initWithIdentifier:stepIdentifier];
            step.recorderConfigurations = @[[[ORK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:@"ac2_acc" frequency:100.0], [[ORK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:@"ac2_motion" frequency:100.0]];
            step.title = [NSString localizedStringWithFormat:titleFormat, (long)activeStepDuration];
            step.spokenInstruction = step.title;
            step.finishedSpokenInstruction = stepFinishedInstruction;
            step.stepDuration = activeStepDuration;
            step.image = [UIImage imageNamed:@"tremortest4a" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            if (leftHand) {
                step.image = [step.image ork_flippedImage:UIImageOrientationUpMirrored];
            }
            step.shouldPlaySoundOnStart = YES;
            step.shouldVibrateOnStart = YES;
            step.shouldPlaySoundOnFinish = YES;
            step.shouldVibrateOnFinish = YES;
            step.shouldContinueOnFinish = NO;
            step.shouldStartTimerAutomatically = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
    }
    
    if (!(activeTaskOptions & ORK1TremorActiveTaskOptionExcludeHandAtShoulderHeightElbowBent)) {
        if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
            NSString *stepIdentifier = [self stepIdentifier:ORK1Instruction5StepIdentifier withHandIdentifier:handIdentifier];
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:stepIdentifier];
            step.title = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_BEND_ARM_INTRO", nil);
            step.text = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_INTRO_TEXT", nil);
            step.image = [UIImage imageNamed:@"tremortest5a" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.auxiliaryImage = [UIImage imageNamed:@"tremortest5b" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            if (leftHand) {
                step.title = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_BEND_ARM_INTRO_LEFT", nil);
                step.image = [step.image ork_flippedImage:UIImageOrientationUpMirrored];
                step.auxiliaryImage = [step.auxiliaryImage ork_flippedImage:UIImageOrientationUpMirrored];
            } else if (rightHand) {
                step.title = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_BEND_ARM_INTRO_RIGHT", nil);
            }
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
        
        {
            NSString *stepIdentifier = [self stepIdentifier:ORK1Countdown3StepIdentifier withHandIdentifier:handIdentifier];
            ORK1CountdownStep *step = [[ORK1CountdownStep alloc] initWithIdentifier:stepIdentifier];
            
            ORK1StepArrayAddStep(steps, step);
        }
        
        {
            NSString *titleFormat = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_BEND_ARM_INSTRUCTION_%ld", nil);
            NSString *stepIdentifier = [self stepIdentifier:ORK1TremorTestBendArmStepIdentifier withHandIdentifier:handIdentifier];
            ORK1ActiveStep *step = [[ORK1ActiveStep alloc] initWithIdentifier:stepIdentifier];
            step.recorderConfigurations = @[[[ORK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:@"ac3_acc" frequency:100.0], [[ORK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:@"ac3_motion" frequency:100.0]];
            step.title = [NSString localizedStringWithFormat:titleFormat, (long)activeStepDuration];
            step.spokenInstruction = step.title;
            step.finishedSpokenInstruction = stepFinishedInstruction;
            step.stepDuration = activeStepDuration;
            step.shouldPlaySoundOnStart = YES;
            step.shouldVibrateOnStart = YES;
            step.shouldPlaySoundOnFinish = YES;
            step.shouldVibrateOnFinish = YES;
            step.shouldContinueOnFinish = NO;
            step.shouldStartTimerAutomatically = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
    }
    
    if (!(activeTaskOptions & ORK1TremorActiveTaskOptionExcludeHandToNose)) {
        if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
            NSString *stepIdentifier = [self stepIdentifier:ORK1Instruction6StepIdentifier withHandIdentifier:handIdentifier];
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:stepIdentifier];
            step.title = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_TOUCH_NOSE_INTRO", nil);
            step.text = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_INTRO_TEXT", nil);
            step.image = [UIImage imageNamed:@"tremortest6a" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.auxiliaryImage = [UIImage imageNamed:@"tremortest6b" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            if (leftHand) {
                step.title = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_TOUCH_NOSE_INTRO_LEFT", nil);
                step.image = [step.image ork_flippedImage:UIImageOrientationUpMirrored];
                step.auxiliaryImage = [step.auxiliaryImage ork_flippedImage:UIImageOrientationUpMirrored];
            } else if (rightHand) {
                step.title = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_TOUCH_NOSE_INTRO_RIGHT", nil);
            }
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
        
        {
            NSString *stepIdentifier = [self stepIdentifier:ORK1Countdown4StepIdentifier withHandIdentifier:handIdentifier];
            ORK1CountdownStep *step = [[ORK1CountdownStep alloc] initWithIdentifier:stepIdentifier];
            
            ORK1StepArrayAddStep(steps, step);
        }
        
        {
            NSString *titleFormat = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_TOUCH_NOSE_INSTRUCTION_%ld", nil);
            NSString *stepIdentifier = [self stepIdentifier:ORK1TremorTestTouchNoseStepIdentifier withHandIdentifier:handIdentifier];
            ORK1ActiveStep *step = [[ORK1ActiveStep alloc] initWithIdentifier:stepIdentifier];
            step.recorderConfigurations = @[[[ORK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:@"ac4_acc" frequency:100.0], [[ORK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:@"ac4_motion" frequency:100.0]];
            step.title = [NSString localizedStringWithFormat:titleFormat, (long)activeStepDuration];
            step.spokenInstruction = step.title;
            step.finishedSpokenInstruction = stepFinishedInstruction;
            step.stepDuration = activeStepDuration;
            step.shouldPlaySoundOnStart = YES;
            step.shouldVibrateOnStart = YES;
            step.shouldPlaySoundOnFinish = YES;
            step.shouldVibrateOnFinish = YES;
            step.shouldContinueOnFinish = NO;
            step.shouldStartTimerAutomatically = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
    }
    
    if (!(activeTaskOptions & ORK1TremorActiveTaskOptionExcludeQueenWave)) {
        if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
            NSString *stepIdentifier = [self stepIdentifier:ORK1Instruction7StepIdentifier withHandIdentifier:handIdentifier];
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:stepIdentifier];
            step.title = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_TURN_WRIST_INTRO", nil);
            step.text = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_INTRO_TEXT", nil);
            step.image = [UIImage imageNamed:@"tremortest7" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            if (leftHand) {
                step.title = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_TURN_WRIST_INTRO_LEFT", nil);
                step.image = [step.image ork_flippedImage:UIImageOrientationUpMirrored];
            } else if (rightHand) {
                step.title = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_TURN_WRIST_INTRO_RIGHT", nil);
            }
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
        
        {
            NSString *stepIdentifier = [self stepIdentifier:ORK1Countdown5StepIdentifier withHandIdentifier:handIdentifier];
            ORK1CountdownStep *step = [[ORK1CountdownStep alloc] initWithIdentifier:stepIdentifier];
            
            ORK1StepArrayAddStep(steps, step);
        }
        
        {
            NSString *titleFormat = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_TURN_WRIST_INSTRUCTION_%ld", nil);
            NSString *stepIdentifier = [self stepIdentifier:ORK1TremorTestTurnWristStepIdentifier withHandIdentifier:handIdentifier];
            ORK1ActiveStep *step = [[ORK1ActiveStep alloc] initWithIdentifier:stepIdentifier];
            step.recorderConfigurations = @[[[ORK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:@"ac5_acc" frequency:100.0], [[ORK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:@"ac5_motion" frequency:100.0]];
            step.title = [NSString localizedStringWithFormat:titleFormat, (long)activeStepDuration];
            step.spokenInstruction = step.title;
            step.finishedSpokenInstruction = stepFinishedInstruction;
            step.stepDuration = activeStepDuration;
            step.shouldPlaySoundOnStart = YES;
            step.shouldVibrateOnStart = YES;
            step.shouldPlaySoundOnFinish = YES;
            step.shouldVibrateOnFinish = YES;
            step.shouldContinueOnFinish = NO;
            step.shouldStartTimerAutomatically = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
    }
    
    // fix the spoken instruction on the last included step, depending on which hand we're on
    ORK1ActiveStep *lastStep = (ORK1ActiveStep *)[steps lastObject];
    if (lastHand) {
        lastStep.finishedSpokenInstruction = ORK1LocalizedString(@"TREMOR_TEST_COMPLETED_INSTRUCTION", nil);
    } else if (leftHand) {
        lastStep.finishedSpokenInstruction = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_SWITCH_HANDS_RIGHT_INSTRUCTION", nil);
    } else {
        lastStep.finishedSpokenInstruction = ORK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_SWITCH_HANDS_LEFT_INSTRUCTION", nil);
    }
    
    return steps;
}

+ (ORK1NavigableOrderedTask *)tremorTestTaskWithIdentifier:(NSString *)identifier
                                   intendedUseDescription:(nullable NSString *)intendedUseDescription
                                       activeStepDuration:(NSTimeInterval)activeStepDuration
                                        activeTaskOptions:(ORK1TremorActiveTaskOption)activeTaskOptions
                                              handOptions:(ORK1PredefinedTaskHandOption)handOptions
                                                  options:(ORK1PredefinedTaskOption)options {
    
    NSMutableArray<__kindof ORK1Step *> *steps = [NSMutableArray array];
    // coin toss for which hand first (in case we're doing both)
    BOOL leftFirstIfDoingBoth = arc4random_uniform(2) == 1;
    BOOL doingBoth = ((handOptions & ORK1PredefinedTaskHandOptionLeft) && (handOptions & ORK1PredefinedTaskHandOptionRight));
    BOOL firstIsLeft = (leftFirstIfDoingBoth && doingBoth) || (!doingBoth && (handOptions & ORK1PredefinedTaskHandOptionLeft));
    
    if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction0StepIdentifier];
            step.title = ORK1LocalizedString(@"TREMOR_TEST_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = ORK1LocalizedString(@"TREMOR_TEST_INTRO_1_DETAIL", nil);
            step.image = [UIImage imageNamed:@"tremortest1" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            if (firstIsLeft) {
                step.image = [step.image ork_flippedImage:UIImageOrientationUpMirrored];
            }
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
    }
    
    // Build the string for the detail texts
    NSArray<NSString *>*detailStringForNumberOfTasks = @[
                                                         ORK1LocalizedString(@"TREMOR_TEST_INTRO_2_DETAIL_1_TASK", nil),
                                                         ORK1LocalizedString(@"TREMOR_TEST_INTRO_2_DETAIL_2_TASK", nil),
                                                         ORK1LocalizedString(@"TREMOR_TEST_INTRO_2_DETAIL_3_TASK", nil),
                                                         ORK1LocalizedString(@"TREMOR_TEST_INTRO_2_DETAIL_4_TASK", nil),
                                                         ORK1LocalizedString(@"TREMOR_TEST_INTRO_2_DETAIL_5_TASK", nil)
                                                         ];
    
    // start with the count for all the tasks, then subtract one for each excluded task flag
    static const NSInteger allTasks = 5; // hold in lap, outstretched arm, elbow bent, repeatedly touching nose, queen wave
    NSInteger actualTasksIndex = allTasks - 1;
    for (NSInteger i = 0; i < allTasks; ++i) {
        if (activeTaskOptions & (1 << i)) {
            actualTasksIndex--;
        }
    }
    
    NSString *detailFormat = doingBoth ? ORK1LocalizedString(@"TREMOR_TEST_SKIP_QUESTION_BOTH_HANDS_%@", nil) : ORK1LocalizedString(@"TREMOR_TEST_INTRO_2_DETAIL_DEFAULT_%@", nil);
    NSString *detailText = [NSString localizedStringWithFormat:detailFormat, detailStringForNumberOfTasks[actualTasksIndex]];
    
    if (doingBoth) {
        // If doing both hands then ask the user if they need to skip one of the hands
        ORK1TextChoice *skipRight = [ORK1TextChoice choiceWithText:ORK1LocalizedString(@"TREMOR_SKIP_RIGHT_HAND", nil)
                                                          value:ORK1ActiveTaskRightHandIdentifier];
        ORK1TextChoice *skipLeft = [ORK1TextChoice choiceWithText:ORK1LocalizedString(@"TREMOR_SKIP_LEFT_HAND", nil)
                                                          value:ORK1ActiveTaskLeftHandIdentifier];
        ORK1TextChoice *skipNeither = [ORK1TextChoice choiceWithText:ORK1LocalizedString(@"TREMOR_SKIP_NEITHER", nil)
                                                             value:@""];

        ORK1AnswerFormat *answerFormat = [ORK1AnswerFormat choiceAnswerFormatWithStyle:ORK1ChoiceAnswerStyleSingleChoice
                                                                         textChoices:@[skipRight, skipLeft, skipNeither]];
        ORK1QuestionStep *step = [ORK1QuestionStep questionStepWithIdentifier:ORK1ActiveTaskSkipHandStepIdentifier
                                                                      title:ORK1LocalizedString(@"TREMOR_TEST_TITLE", nil)
                                                                       text:detailText
                                                                     answer:answerFormat];
        step.optional = NO;
        
        ORK1StepArrayAddStep(steps, step);
    }
    
    // right or most-affected hand
    NSArray<__kindof ORK1Step *> *rightSteps = nil;
    if (handOptions == ORK1PredefinedTaskHandOptionUnspecified) {
        rightSteps = [self stepsForOneHandTremorTestTaskWithIdentifier:identifier
                                                    activeStepDuration:activeStepDuration
                                                     activeTaskOptions:activeTaskOptions
                                                              lastHand:YES
                                                              leftHand:NO
                                                        handIdentifier:ORK1ActiveTaskMostAffectedHandIdentifier
                                                       introDetailText:detailText
                                                               options:options];
    } else if (handOptions & ORK1PredefinedTaskHandOptionRight) {
        rightSteps = [self stepsForOneHandTremorTestTaskWithIdentifier:identifier
                                                    activeStepDuration:activeStepDuration
                                                     activeTaskOptions:activeTaskOptions
                                                              lastHand:firstIsLeft
                                                              leftHand:NO
                                                        handIdentifier:ORK1ActiveTaskRightHandIdentifier
                                                       introDetailText:nil
                                                               options:options];
    }
    
    // left hand
    NSArray<__kindof ORK1Step *> *leftSteps = nil;
    if (handOptions & ORK1PredefinedTaskHandOptionLeft) {
        leftSteps = [self stepsForOneHandTremorTestTaskWithIdentifier:identifier
                                                   activeStepDuration:activeStepDuration
                                                    activeTaskOptions:activeTaskOptions
                                                             lastHand:!firstIsLeft || !(handOptions & ORK1PredefinedTaskHandOptionRight)
                                                             leftHand:YES
                                                       handIdentifier:ORK1ActiveTaskLeftHandIdentifier
                                                      introDetailText:nil
                                                              options:options];
    }
    
    if (firstIsLeft && leftSteps != nil) {
        [steps addObjectsFromArray:leftSteps];
    }
    
    if (rightSteps != nil) {
        [steps addObjectsFromArray:rightSteps];
    }
    
    if (!firstIsLeft && leftSteps != nil) {
        [steps addObjectsFromArray:leftSteps];
    }
    
    BOOL hasCompletionStep = NO;
    if (!(options & ORK1PredefinedTaskOptionExcludeConclusion)) {
        hasCompletionStep = YES;
        ORK1CompletionStep *step = [self makeCompletionStep];
        
        ORK1StepArrayAddStep(steps, step);
    }

    ORK1NavigableOrderedTask *task = [[ORK1NavigableOrderedTask alloc] initWithIdentifier:identifier steps:steps];
    
    if (doingBoth) {
        // Setup rules for skipping all the steps in either the left or right hand if called upon to do so.
        ORK1ResultSelector *resultSelector = [ORK1ResultSelector selectorWithStepIdentifier:ORK1ActiveTaskSkipHandStepIdentifier
                                                                         resultIdentifier:ORK1ActiveTaskSkipHandStepIdentifier];
        NSPredicate *predicateRight = [ORK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector expectedAnswerValue:ORK1ActiveTaskRightHandIdentifier];
        NSPredicate *predicateLeft = [ORK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector expectedAnswerValue:ORK1ActiveTaskLeftHandIdentifier];
        
        // Setup rule for skipping first hand
        NSString *secondHandIdentifier = firstIsLeft ? [[rightSteps firstObject] identifier] : [[leftSteps firstObject] identifier];
        NSPredicate *firstPredicate = firstIsLeft ? predicateLeft : predicateRight;
        ORK1StepNavigationRule *skipFirst = [[ORK1PredicateStepNavigationRule alloc] initWithResultPredicates:@[firstPredicate]
                                                                                 destinationStepIdentifiers:@[secondHandIdentifier]];
        [task setNavigationRule:skipFirst forTriggerStepIdentifier:ORK1ActiveTaskSkipHandStepIdentifier];
        
        // Setup rule for skipping the second hand
        NSString *triggerIdentifier = firstIsLeft ? [[leftSteps lastObject] identifier] : [[rightSteps lastObject] identifier];
        NSString *conclusionIdentifier = hasCompletionStep ? [[steps lastObject] identifier] : ORK1NullStepIdentifier;
        NSPredicate *secondPredicate = firstIsLeft ? predicateRight : predicateLeft;
        ORK1StepNavigationRule *skipSecond = [[ORK1PredicateStepNavigationRule alloc] initWithResultPredicates:@[secondPredicate]
                                                                                  destinationStepIdentifiers:@[conclusionIdentifier]];
        [task setNavigationRule:skipSecond forTriggerStepIdentifier:triggerIdentifier];
        
        // Setup step modifier to change the finished spoken step if skipping the second hand
        NSString *key = NSStringFromSelector(@selector(finishedSpokenInstruction));
        NSString *value = ORK1LocalizedString(@"TREMOR_TEST_COMPLETED_INSTRUCTION", nil);
        ORK1StepModifier *stepModifier = [[ORK1KeyValueStepModifier alloc] initWithResultPredicate:secondPredicate
                                                                                     keyValueMap:@{key: value}];
        [task setStepModifier:stepModifier forStepIdentifier:triggerIdentifier];
    }
    
    return task;
}

+ (ORK1OrderedTask *)trailmakingTaskWithIdentifier:(NSString *)identifier
                           intendedUseDescription:(nullable NSString *)intendedUseDescription
                           trailmakingInstruction:(nullable NSString *)trailmakingInstruction
                                        trailType:(ORK1TrailMakingTypeIdentifier)trailType
                                          options:(ORK1PredefinedTaskOption)options {
    
    NSArray *supportedTypes = @[ORK1TrailMakingTypeIdentifierA, ORK1TrailMakingTypeIdentifierB];
    NSAssert1([supportedTypes containsObject:trailType], @"Trail type %@ is not supported.", trailType);
    
    NSMutableArray<__kindof ORK1Step *> *steps = [NSMutableArray array];
    
    if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction0StepIdentifier];
            step.title = ORK1LocalizedString(@"TRAILMAKING_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = ORK1LocalizedString(@"TRAILMAKING_INTENDED_USE", nil);
            step.image = [UIImage imageNamed:@"trailmaking" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
        
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction1StepIdentifier];
            step.title = ORK1LocalizedString(@"TRAILMAKING_TASK_TITLE", nil);
            if ([trailType isEqualToString:ORK1TrailMakingTypeIdentifierA]) {
                step.detailText = ORK1LocalizedString(@"TRAILMAKING_INTENDED_USE2_A", nil);
            } else {
                step.detailText = ORK1LocalizedString(@"TRAILMAKING_INTENDED_USE2_B", nil);
            }
            step.image = [UIImage imageNamed:@"trailmaking" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
        
        
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction2StepIdentifier];
            step.title = ORK1LocalizedString(@"TRAILMAKING_TASK_TITLE", nil);
            step.text = trailmakingInstruction ? : ORK1LocalizedString(@"TRAILMAKING_INTRO_TEXT",nil);
            step.detailText = ORK1LocalizedString(@"TRAILMAKING_CALL_TO_ACTION", nil);
            step.image = [UIImage imageNamed:@"trailmaking" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
    }
    
    {
        ORK1CountdownStep *step = [[ORK1CountdownStep alloc] initWithIdentifier:ORK1CountdownStepIdentifier];
        step.stepDuration = 3.0;
        
        ORK1StepArrayAddStep(steps, step);
    }
    
    {
        ORK1TrailmakingStep *step = [[ORK1TrailmakingStep alloc] initWithIdentifier:ORK1TrailmakingStepIdentifier];
        step.trailType = trailType;
        
        ORK1StepArrayAddStep(steps, step);
    }
    
    if (!(options & ORK1PredefinedTaskOptionExcludeConclusion)) {
        ORK1InstructionStep *step = [self makeCompletionStep];
        
        ORK1StepArrayAddStep(steps, step);
    }

    
    ORK1OrderedTask *task = [[ORK1OrderedTask alloc] initWithIdentifier:identifier steps:steps];
    
    return task;
}

@end
