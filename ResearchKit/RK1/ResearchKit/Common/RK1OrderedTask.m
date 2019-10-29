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


#import "RK1OrderedTask.h"

#import "RK1AudioStepViewController.h"
#import "RK1CountdownStepViewController.h"
#import "RK1TouchAnywhereStepViewController.h"
#import "RK1FitnessStepViewController.h"
#import "RK1ToneAudiometryStepViewController.h"
#import "RK1SpatialSpanMemoryStepViewController.h"
#import "RK1StroopStepViewController.h"
#import "RK1WalkingTaskStepViewController.h"

#import "RK1AccelerometerRecorder.h"
#import "RK1ActiveStep_Internal.h"
#import "RK1AnswerFormat_Internal.h"
#import "RK1AudioLevelNavigationRule.h"
#import "RK1AudioRecorder.h"
#import "RK1AudioStep.h"
#import "RK1CompletionStep.h"
#import "RK1CountdownStep.h"
#import "RK1TouchAnywhereStep.h"
#import "RK1FitnessStep.h"
#import "RK1FormStep.h"
#import "RK1NavigableOrderedTask.h"
#import "RK1PSATStep.h"
#import "RK1QuestionStep.h"
#import "RK1ReactionTimeStep.h"
#import "RK1SpatialSpanMemoryStep.h"
#import "RK1Step_Private.h"
#import "RK1StroopStep.h"
#import "RK1TappingIntervalStep.h"
#import "RK1TimedWalkStep.h"
#import "RK1ToneAudiometryStep.h"
#import "RK1ToneAudiometryPracticeStep.h"
#import "RK1TowerOfHanoiStep.h"
#import "RK1TrailmakingStep.h"
#import "RK1VisualConsentStep.h"
#import "RK1RangeOfMotionStep.h"
#import "RK1ShoulderRangeOfMotionStep.h"
#import "RK1WaitStep.h"
#import "RK1WalkingTaskStep.h"
#import "RK1ResultPredicate.h"

#import "RK1Helpers_Internal.h"
#import "UIImage+ResearchKit.h"
#import <limits.h>

RK1TrailMakingTypeIdentifier const RK1TrailMakingTypeIdentifierA = @"A";
RK1TrailMakingTypeIdentifier const RK1TrailMakingTypeIdentifierB = @"B";


RK1TaskProgress RK1TaskProgressMake(NSUInteger current, NSUInteger total) {
    return (RK1TaskProgress){.current=current, .total=total};
}


@implementation RK1OrderedTask {
    NSString *_identifier;
}

@synthesize cev_theme = _cev_theme;

+ (instancetype)new {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    RK1ThrowMethodUnavailableException();
}

- (instancetype)initWithIdentifier:(NSString *)identifier steps:(NSArray<RK1Step *> *)steps {
    self = [super init];
    if (self) {
        RK1ThrowInvalidArgumentExceptionIfNil(identifier);
        
        _identifier = [identifier copy];
        _steps = steps;
        
        [self validateParameters];
    }
    return self;
}

- (instancetype)copyWithSteps:(NSArray <RK1Step *> *)steps {
    RK1OrderedTask *task = [self copyWithZone:nil];
    task->_steps = RK1ArrayCopyObjects(steps);
    return task;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    RK1OrderedTask *task = [[[self class] allocWithZone:zone] initWithIdentifier:[_identifier copy]
                                                                           steps:RK1ArrayCopyObjects(_steps)];
    return task;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return (RK1EqualObjects(self.identifier, castObject.identifier)
            && RK1EqualObjects(self.steps, castObject.steps));
}

- (NSUInteger)hash {
    return _identifier.hash ^ _steps.hash;
}

#pragma mark - RK1Task

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

- (NSUInteger)indexOfStep:(RK1Step *)step {
    NSUInteger index = [_steps indexOfObject:step];
    if (index == NSNotFound) {
        NSArray *identifiers = [_steps valueForKey:@"identifier"];
        index = [identifiers indexOfObject:step.identifier];
    }
    return index;
}

- (RK1Step *)stepAfterStep:(RK1Step *)step withResult:(RK1TaskResult *)result {
    NSArray *steps = _steps;
    
    if (steps.count <= 0) {
        return nil;
    }
    
    RK1Step *currentStep = step;
    RK1Step *nextStep = nil;
    
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

- (RK1Step *)stepBeforeStep:(RK1Step *)step withResult:(RK1TaskResult *)result {
    NSArray *steps = _steps;
    
    if (steps.count <= 0) {
        return nil;
    }
    
    RK1Step *currentStep = step;
    RK1Step *nextStep = nil;
    
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

- (RK1Step *)stepWithIdentifier:(NSString *)identifier {
    __block RK1Step *step = nil;
    [_steps enumerateObjectsUsingBlock:^(RK1Step *obj, NSUInteger idx, BOOL *stop) {
        if ([obj.identifier isEqualToString:identifier]) {
            step = obj;
            *stop = YES;
        }
    }];
    return step;
}

- (RK1TaskProgress)progressOfCurrentStep:(RK1Step *)step withResult:(RK1TaskResult *)taskResult {
    RK1TaskProgress progress;
    progress.current = [self indexOfStep:step];
    progress.total = _steps.count;
    
    if (![step showsProgress]) {
        progress.total = 0;
    }
    return progress;
}

- (NSSet *)requestedHealthKitTypesForReading {
    NSMutableSet *healthTypes = [NSMutableSet set];
    for (RK1Step *step in self.steps) {
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

- (RK1PermissionMask)requestedPermissions {
    RK1PermissionMask mask = RK1PermissionNone;
    for (RK1Step *step in self.steps) {
        mask |= [step requestedPermissions];
    }
    return mask;
}

- (BOOL)providesBackgroundAudioPrompts {
    BOOL providesAudioPrompts = NO;
    for (RK1Step *step in self.steps) {
        if ([step isKindOfClass:[RK1ActiveStep class]]) {
            RK1ActiveStep *activeStep = (RK1ActiveStep *)step;
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
    RK1_ENCODE_OBJ(aCoder, identifier);
    RK1_ENCODE_OBJ(aCoder, steps);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        RK1_DECODE_OBJ_CLASS(aDecoder, identifier, NSString);
        RK1_DECODE_OBJ_ARRAY(aDecoder, steps, RK1Step);
        
        for (RK1Step *step in _steps) {
            if ([step isKindOfClass:[RK1Step class]]) {
                [step setTask:self];
            }
        }
    }
    return self;
}

#pragma mark - Predefined

NSString *const RK1Instruction0StepIdentifier = @"instruction";
NSString *const RK1Instruction1StepIdentifier = @"instruction1";
NSString *const RK1Instruction2StepIdentifier = @"instruction2";
NSString *const RK1Instruction3StepIdentifier = @"instruction3";
NSString *const RK1Instruction4StepIdentifier = @"instruction4";
NSString *const RK1Instruction5StepIdentifier = @"instruction5";
NSString *const RK1Instruction6StepIdentifier = @"instruction6";
NSString *const RK1Instruction7StepIdentifier = @"instruction7";
NSString *const RK1CountdownStepIdentifier = @"countdown";
NSString *const RK1Countdown1StepIdentifier = @"countdown1";
NSString *const RK1Countdown2StepIdentifier = @"countdown2";
NSString *const RK1Countdown3StepIdentifier = @"countdown3";
NSString *const RK1Countdown4StepIdentifier = @"countdown4";
NSString *const RK1Countdown5StepIdentifier = @"countdown5";
NSString *const RK1TouchAnywhereStepIdentifier = @"touch.anywhere";
NSString *const RK1AudioStepIdentifier = @"audio";
NSString *const RK1AudioTooLoudStepIdentifier = @"audio.tooloud";
NSString *const RK1TappingStepIdentifier = @"tapping";
NSString *const RK1ActiveTaskLeftHandIdentifier = @"left";
NSString *const RK1ActiveTaskRightHandIdentifier = @"right";
NSString *const RK1ActiveTaskSkipHandStepIdentifier = @"skipHand";
NSString *const RK1ConclusionStepIdentifier = @"conclusion";
NSString *const RK1FitnessWalkStepIdentifier = @"fitness.walk";
NSString *const RK1FitnessRestStepIdentifier = @"fitness.rest";
NSString *const RK1KneeRangeOfMotionStepIdentifier = @"knee.range.of.motion";
NSString *const RK1ShoulderRangeOfMotionStepIdentifier = @"shoulder.range.of.motion";
NSString *const RK1ShortWalkOutboundStepIdentifier = @"walking.outbound";
NSString *const RK1ShortWalkReturnStepIdentifier = @"walking.return";
NSString *const RK1ShortWalkRestStepIdentifier = @"walking.rest";
NSString *const RK1SpatialSpanMemoryStepIdentifier = @"cognitive.memory.spatialspan";
NSString *const RK1StroopStepIdentifier = @"stroop";
NSString *const RK1ToneAudiometryPracticeStepIdentifier = @"tone.audiometry.practice";
NSString *const RK1ToneAudiometryStepIdentifier = @"tone.audiometry";
NSString *const RK1ReactionTimeStepIdentifier = @"reactionTime";
NSString *const RK1TowerOfHanoiStepIdentifier = @"towerOfHanoi";
NSString *const RK1TimedWalkFormStepIdentifier = @"timed.walk.form";
NSString *const RK1TimedWalkFormAFOStepIdentifier = @"timed.walk.form.afo";
NSString *const RK1TimedWalkFormAssistanceStepIdentifier = @"timed.walk.form.assistance";
NSString *const RK1TimedWalkTrial1StepIdentifier = @"timed.walk.trial1";
NSString *const RK1TimedWalkTurnAroundStepIdentifier = @"timed.walk.turn.around";
NSString *const RK1TimedWalkTrial2StepIdentifier = @"timed.walk.trial2";
NSString *const RK1TremorTestInLapStepIdentifier = @"tremor.handInLap";
NSString *const RK1TremorTestExtendArmStepIdentifier = @"tremor.handAtShoulderLength";
NSString *const RK1TremorTestBendArmStepIdentifier = @"tremor.handAtShoulderLengthWithElbowBent";
NSString *const RK1TremorTestTouchNoseStepIdentifier = @"tremor.handToNose";
NSString *const RK1TremorTestTurnWristStepIdentifier = @"tremor.handQueenWave";
NSString *const RK1TrailmakingStepIdentifier = @"trailmaking";
NSString *const RK1ActiveTaskMostAffectedHandIdentifier = @"mostAffected";
NSString *const RK1PSATStepIdentifier = @"psat";
NSString *const RK1AudioRecorderIdentifier = @"audio";
NSString *const RK1AccelerometerRecorderIdentifier = @"accelerometer";
NSString *const RK1PedometerRecorderIdentifier = @"pedometer";
NSString *const RK1DeviceMotionRecorderIdentifier = @"deviceMotion";
NSString *const RK1LocationRecorderIdentifier = @"location";
NSString *const RK1HeartRateRecorderIdentifier = @"heartRate";

+ (RK1CompletionStep *)makeCompletionStep {
    RK1CompletionStep *step = [[RK1CompletionStep alloc] initWithIdentifier:RK1ConclusionStepIdentifier];
    step.title = RK1LocalizedString(@"TASK_COMPLETE_TITLE", nil);
    step.text = RK1LocalizedString(@"TASK_COMPLETE_TEXT", nil);
    step.shouldTintImages = YES;
    return step;
}

void RK1StepArrayAddStep(NSMutableArray *array, RK1Step *step) {
    [step validateParameters];
    [array addObject:step];
}

+ (RK1OrderedTask *)twoFingerTappingIntervalTaskWithIdentifier:(NSString *)identifier
                                       intendedUseDescription:(NSString *)intendedUseDescription
                                                     duration:(NSTimeInterval)duration
                                                      options:(RK1PredefinedTaskOption)options {
    return [self twoFingerTappingIntervalTaskWithIdentifier:identifier
                                     intendedUseDescription:intendedUseDescription
                                                   duration:duration
                                                handOptions:0
                                                    options:options];
}
    
+ (RK1OrderedTask *)twoFingerTappingIntervalTaskWithIdentifier:(NSString *)identifier
                                        intendedUseDescription:(NSString *)intendedUseDescription
                                                      duration:(NSTimeInterval)duration
                                                   handOptions:(RK1PredefinedTaskHandOption)handOptions
                                                       options:(RK1PredefinedTaskOption)options {
    
    NSString *durationString = [RK1DurationStringFormatter() stringFromTimeInterval:duration];
    
    NSMutableArray *steps = [NSMutableArray array];
    
    if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction0StepIdentifier];
            step.title = RK1LocalizedString(@"TAPPING_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = RK1LocalizedString(@"TAPPING_INTRO_TEXT", nil);
            
            NSString *imageName = @"phonetapping";
            if (![[NSLocale preferredLanguages].firstObject hasPrefix:@"en"]) {
                imageName = [imageName stringByAppendingString:@"_notap"];
            }
            step.image = [UIImage imageNamed:imageName inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
    }
    
    // Setup which hand to start with and how many hands to add based on the handOptions parameter
    // Hand order is randomly determined.
    NSUInteger handCount = ((handOptions & RK1PredefinedTaskHandOptionBoth) == RK1PredefinedTaskHandOptionBoth) ? 2 : 1;
    BOOL undefinedHand = (handOptions == 0);
    BOOL rightHand;
    switch (handOptions) {
        case RK1PredefinedTaskHandOptionLeft:
            rightHand = NO; break;
        case RK1PredefinedTaskHandOptionRight:
        case RK1PredefinedTaskHandOptionUnspecified:
            rightHand = YES; break;
        default:
            rightHand = (arc4random()%2 == 0); break;
        }
        
    for (NSUInteger hand = 1; hand <= handCount; hand++) {
        
        NSString * (^appendIdentifier) (NSString *) = ^ (NSString * identifier) {
            if (undefinedHand) {
                return identifier;
            } else {
                NSString *handIdentifier = rightHand ? RK1ActiveTaskRightHandIdentifier : RK1ActiveTaskLeftHandIdentifier;
                return [NSString stringWithFormat:@"%@.%@", identifier, handIdentifier];
            }
        };
        
        if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:appendIdentifier(RK1Instruction1StepIdentifier)];
            
            // Set the title based on the hand
            if (undefinedHand) {
                step.title = RK1LocalizedString(@"TAPPING_TASK_TITLE", nil);
            } else if (rightHand) {
                step.title = RK1LocalizedString(@"TAPPING_TASK_TITLE_RIGHT", nil);
            } else {
                step.title = RK1LocalizedString(@"TAPPING_TASK_TITLE_LEFT", nil);
            }
            
            // Set the instructions for the tapping test screen that is displayed prior to each hand test
            NSString *restText = RK1LocalizedString(@"TAPPING_INTRO_TEXT_2_REST_PHONE", nil);
            NSString *tappingTextFormat = RK1LocalizedString(@"TAPPING_INTRO_TEXT_2_FORMAT", nil);
            NSString *tappingText = [NSString localizedStringWithFormat:tappingTextFormat, durationString];
            NSString *handText = nil;
            
            if (hand == 1) {
                if (undefinedHand) {
                    handText = RK1LocalizedString(@"TAPPING_INTRO_TEXT_2_MOST_AFFECTED", nil);
                } else if (rightHand) {
                    handText = RK1LocalizedString(@"TAPPING_INTRO_TEXT_2_RIGHT_FIRST", nil);
                } else {
                    handText = RK1LocalizedString(@"TAPPING_INTRO_TEXT_2_LEFT_FIRST", nil);
                }
            } else {
                if (rightHand) {
                    handText = RK1LocalizedString(@"TAPPING_INTRO_TEXT_2_RIGHT_SECOND", nil);
                } else {
                    handText = RK1LocalizedString(@"TAPPING_INTRO_TEXT_2_LEFT_SECOND", nil);
                }
            }
            
            step.text = [NSString localizedStringWithFormat:@"%@ %@ %@", restText, handText, tappingText];
            
            // Continue button will be different from first hand and second hand
            if (hand == 1) {
                step.detailText = RK1LocalizedString(@"TAPPING_CALL_TO_ACTION", nil);
            } else {
                step.detailText = RK1LocalizedString(@"TAPPING_CALL_TO_ACTION_NEXT", nil);
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
            
            RK1StepArrayAddStep(steps, step);
        }
    
        // TAPPING STEP
    {
        NSMutableArray *recorderConfigurations = [NSMutableArray arrayWithCapacity:5];
        if (!(RK1PredefinedTaskOptionExcludeAccelerometer & options)) {
            [recorderConfigurations addObject:[[RK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:RK1AccelerometerRecorderIdentifier
                                                                                                      frequency:100]];
        }
        
            RK1TappingIntervalStep *step = [[RK1TappingIntervalStep alloc] initWithIdentifier:appendIdentifier(RK1TappingStepIdentifier)];
            if (undefinedHand) {
                step.title = RK1LocalizedString(@"TAPPING_INSTRUCTION", nil);
            } else if (rightHand) {
                step.title = RK1LocalizedString(@"TAPPING_INSTRUCTION_RIGHT", nil);
            } else {
                step.title = RK1LocalizedString(@"TAPPING_INSTRUCTION_LEFT", nil);
            }
            step.stepDuration = duration;
            step.shouldContinueOnFinish = YES;
            step.recorderConfigurations = recorderConfigurations;
            step.optional = (handCount == 2);
            
            RK1StepArrayAddStep(steps, step);
        }
        
        // Flip to the other hand (ignored if handCount == 1)
        rightHand = !rightHand;
    }
    
    if (!(options & RK1PredefinedTaskOptionExcludeConclusion)) {
        RK1InstructionStep *step = [self makeCompletionStep];
        
        RK1StepArrayAddStep(steps, step);
    }
    
    RK1OrderedTask *task = [[RK1OrderedTask alloc] initWithIdentifier:identifier steps:[steps copy]];
    
    return task;
}

+ (RK1OrderedTask *)audioTaskWithIdentifier:(NSString *)identifier
                     intendedUseDescription:(NSString *)intendedUseDescription
                          speechInstruction:(NSString *)speechInstruction
                     shortSpeechInstruction:(NSString *)shortSpeechInstruction
                                   duration:(NSTimeInterval)duration
                          recordingSettings:(NSDictionary *)recordingSettings
                                    options:(RK1PredefinedTaskOption)options {
    
    return [self audioTaskWithIdentifier:identifier
                  intendedUseDescription:intendedUseDescription
                       speechInstruction:speechInstruction
                  shortSpeechInstruction:shortSpeechInstruction
                                duration:duration
                       recordingSettings:recordingSettings
                         checkAudioLevel:NO
                                 options:options];
}

+ (RK1NavigableOrderedTask *)audioTaskWithIdentifier:(NSString *)identifier
                              intendedUseDescription:(nullable NSString *)intendedUseDescription
                                   speechInstruction:(nullable NSString *)speechInstruction
                              shortSpeechInstruction:(nullable NSString *)shortSpeechInstruction
                                            duration:(NSTimeInterval)duration
                                   recordingSettings:(nullable NSDictionary *)recordingSettings
                                     checkAudioLevel:(BOOL)checkAudioLevel
                                             options:(RK1PredefinedTaskOption)options {

    recordingSettings = recordingSettings ? : @{ AVFormatIDKey : @(kAudioFormatAppleLossless),
                                                 AVNumberOfChannelsKey : @(2),
                                                AVSampleRateKey: @(44100.0) };
    
    if (options & RK1PredefinedTaskOptionExcludeAudio) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"Audio collection cannot be excluded from audio task" userInfo:nil];
    }
    
    NSMutableArray *steps = [NSMutableArray array];
    if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction0StepIdentifier];
            step.title = RK1LocalizedString(@"AUDIO_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = RK1LocalizedString(@"AUDIO_INTENDED_USE", nil);
            step.image = [UIImage imageNamed:@"phonewaves" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
        
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction1StepIdentifier];
            step.title = RK1LocalizedString(@"AUDIO_TASK_TITLE", nil);
            step.text = speechInstruction ? : RK1LocalizedString(@"AUDIO_INTRO_TEXT",nil);
            step.detailText = RK1LocalizedString(@"AUDIO_CALL_TO_ACTION", nil);
            step.image = [UIImage imageNamed:@"phonesoundwaves" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
    }

    {
        RK1CountdownStep *step = [[RK1CountdownStep alloc] initWithIdentifier:RK1CountdownStepIdentifier];
        step.stepDuration = 5.0;
        
        // Collect audio during the countdown step too, to provide a baseline.
        step.recorderConfigurations = @[[[RK1AudioRecorderConfiguration alloc] initWithIdentifier:RK1AudioRecorderIdentifier
                                                                                 recorderSettings:recordingSettings]];
        
        // If checking the sound level then add text indicating that's what is happening
        if (checkAudioLevel) {
            step.text = RK1LocalizedString(@"AUDIO_LEVEL_CHECK_LABEL", nil);
        }
        
        RK1StepArrayAddStep(steps, step);
    }
    
    if (checkAudioLevel) {
        RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1AudioTooLoudStepIdentifier];
        step.text = RK1LocalizedString(@"AUDIO_TOO_LOUD_MESSAGE", nil);
        step.detailText = RK1LocalizedString(@"AUDIO_TOO_LOUD_ACTION_NEXT", nil);
        
        RK1StepArrayAddStep(steps, step);
    }
    
    {
        RK1AudioStep *step = [[RK1AudioStep alloc] initWithIdentifier:RK1AudioStepIdentifier];
        step.title = shortSpeechInstruction ? : RK1LocalizedString(@"AUDIO_INSTRUCTION", nil);
        step.recorderConfigurations = @[[[RK1AudioRecorderConfiguration alloc] initWithIdentifier:RK1AudioRecorderIdentifier
                                                                                 recorderSettings:recordingSettings]];
        step.stepDuration = duration;
        step.shouldContinueOnFinish = YES;
        
        RK1StepArrayAddStep(steps, step);
    }
    
    if (!(options & RK1PredefinedTaskOptionExcludeConclusion)) {
        RK1InstructionStep *step = [self makeCompletionStep];
        
        RK1StepArrayAddStep(steps, step);
    }

    RK1NavigableOrderedTask *task = [[RK1NavigableOrderedTask alloc] initWithIdentifier:identifier steps:steps];
    
    if (checkAudioLevel) {
    
        // Add rules to check for audio and fail, looping back to the countdown step if required
        RK1AudioLevelNavigationRule *audioRule = [[RK1AudioLevelNavigationRule alloc] initWithAudioLevelStepIdentifier:RK1CountdownStepIdentifier destinationStepIdentifier:RK1AudioStepIdentifier recordingSettings:recordingSettings];
        RK1DirectStepNavigationRule *loopRule = [[RK1DirectStepNavigationRule alloc] initWithDestinationStepIdentifier:RK1CountdownStepIdentifier];
    
        [task setNavigationRule:audioRule forTriggerStepIdentifier:RK1CountdownStepIdentifier];
        [task setNavigationRule:loopRule forTriggerStepIdentifier:RK1AudioTooLoudStepIdentifier];
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

+ (RK1OrderedTask *)fitnessCheckTaskWithIdentifier:(NSString *)identifier
                           intendedUseDescription:(NSString *)intendedUseDescription
                                     walkDuration:(NSTimeInterval)walkDuration
                                     restDuration:(NSTimeInterval)restDuration
                                          options:(RK1PredefinedTaskOption)options {
    
    NSDateComponentsFormatter *formatter = [self textTimeFormatter];
    
    NSMutableArray *steps = [NSMutableArray array];
    if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction0StepIdentifier];
            step.title = RK1LocalizedString(@"FITNESS_TASK_TITLE", nil);
            step.text = intendedUseDescription ? : [NSString localizedStringWithFormat:RK1LocalizedString(@"FITNESS_INTRO_TEXT_FORMAT", nil), [formatter stringFromTimeInterval:walkDuration]];
            step.image = [UIImage imageNamed:@"heartbeat" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
        
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction1StepIdentifier];
            step.title = RK1LocalizedString(@"FITNESS_TASK_TITLE", nil);
            step.text = [NSString localizedStringWithFormat:RK1LocalizedString(@"FITNESS_INTRO_2_TEXT_FORMAT", nil), [formatter stringFromTimeInterval:walkDuration], [formatter stringFromTimeInterval:restDuration]];
            step.image = [UIImage imageNamed:@"walkingman" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
    }
    
    {
        RK1CountdownStep *step = [[RK1CountdownStep alloc] initWithIdentifier:RK1CountdownStepIdentifier];
        step.stepDuration = 5.0;
        
        RK1StepArrayAddStep(steps, step);
    }
    
    HKUnit *bpmUnit = [[HKUnit countUnit] unitDividedByUnit:[HKUnit minuteUnit]];
    HKQuantityType *heartRateType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    {
        if (walkDuration > 0) {
            NSMutableArray *recorderConfigurations = [NSMutableArray arrayWithCapacity:5];
            if (!(RK1PredefinedTaskOptionExcludePedometer & options)) {
                [recorderConfigurations addObject:[[RK1PedometerRecorderConfiguration alloc] initWithIdentifier:RK1PedometerRecorderIdentifier]];
            }
            if (!(RK1PredefinedTaskOptionExcludeAccelerometer & options)) {
                [recorderConfigurations addObject:[[RK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:RK1AccelerometerRecorderIdentifier
                                                                                                          frequency:100]];
            }
            if (!(RK1PredefinedTaskOptionExcludeDeviceMotion & options)) {
                [recorderConfigurations addObject:[[RK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:RK1DeviceMotionRecorderIdentifier
                                                                                                         frequency:100]];
            }
            if (!(RK1PredefinedTaskOptionExcludeLocation & options)) {
                [recorderConfigurations addObject:[[RK1LocationRecorderConfiguration alloc] initWithIdentifier:RK1LocationRecorderIdentifier]];
            }
            if (!(RK1PredefinedTaskOptionExcludeHeartRate & options)) {
                [recorderConfigurations addObject:[[RK1HealthQuantityTypeRecorderConfiguration alloc] initWithIdentifier:RK1HeartRateRecorderIdentifier
                                                                                                      healthQuantityType:heartRateType unit:bpmUnit]];
            }
            RK1FitnessStep *fitnessStep = [[RK1FitnessStep alloc] initWithIdentifier:RK1FitnessWalkStepIdentifier];
            fitnessStep.stepDuration = walkDuration;
            fitnessStep.title = [NSString localizedStringWithFormat:RK1LocalizedString(@"FITNESS_WALK_INSTRUCTION_FORMAT", nil), [formatter stringFromTimeInterval:walkDuration]];
            fitnessStep.spokenInstruction = fitnessStep.title;
            fitnessStep.recorderConfigurations = recorderConfigurations;
            fitnessStep.shouldContinueOnFinish = YES;
            fitnessStep.optional = NO;
            fitnessStep.shouldStartTimerAutomatically = YES;
            fitnessStep.shouldTintImages = YES;
            fitnessStep.image = [UIImage imageNamed:@"walkingman" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            fitnessStep.shouldVibrateOnStart = YES;
            fitnessStep.shouldPlaySoundOnStart = YES;
            
            RK1StepArrayAddStep(steps, fitnessStep);
        }
        
        if (restDuration > 0) {
            NSMutableArray *recorderConfigurations = [NSMutableArray arrayWithCapacity:5];
            if (!(RK1PredefinedTaskOptionExcludeAccelerometer & options)) {
                [recorderConfigurations addObject:[[RK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:RK1AccelerometerRecorderIdentifier
                                                                                                          frequency:100]];
            }
            if (!(RK1PredefinedTaskOptionExcludeDeviceMotion & options)) {
                [recorderConfigurations addObject:[[RK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:RK1DeviceMotionRecorderIdentifier
                                                                                                         frequency:100]];
            }
            if (!(RK1PredefinedTaskOptionExcludeHeartRate & options)) {
                [recorderConfigurations addObject:[[RK1HealthQuantityTypeRecorderConfiguration alloc] initWithIdentifier:RK1HeartRateRecorderIdentifier
                                                                                                      healthQuantityType:heartRateType unit:bpmUnit]];
            }
            
            RK1FitnessStep *stillStep = [[RK1FitnessStep alloc] initWithIdentifier:RK1FitnessRestStepIdentifier];
            stillStep.stepDuration = restDuration;
            stillStep.title = [NSString localizedStringWithFormat:RK1LocalizedString(@"FITNESS_SIT_INSTRUCTION_FORMAT", nil), [formatter stringFromTimeInterval:restDuration]];
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
            
            RK1StepArrayAddStep(steps, stillStep);
        }
    }
    
    if (!(options & RK1PredefinedTaskOptionExcludeConclusion)) {
        RK1InstructionStep *step = [self makeCompletionStep];
        RK1StepArrayAddStep(steps, step);
    }
    
    RK1OrderedTask *task = [[RK1OrderedTask alloc] initWithIdentifier:identifier steps:steps];
    
    return task;
}

+ (RK1OrderedTask *)shortWalkTaskWithIdentifier:(NSString *)identifier
                         intendedUseDescription:(NSString *)intendedUseDescription
                            numberOfStepsPerLeg:(NSInteger)numberOfStepsPerLeg
                                   restDuration:(NSTimeInterval)restDuration
                                        options:(RK1PredefinedTaskOption)options {
    
    NSDateComponentsFormatter *formatter = [self textTimeFormatter];
    
    NSMutableArray *steps = [NSMutableArray array];
    if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction0StepIdentifier];
            step.title = RK1LocalizedString(@"WALK_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = RK1LocalizedString(@"WALK_INTRO_TEXT", nil);
            step.shouldTintImages = YES;
            RK1StepArrayAddStep(steps, step);
        }
        
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction1StepIdentifier];
            step.title = RK1LocalizedString(@"WALK_TASK_TITLE", nil);
            step.text = [NSString localizedStringWithFormat:RK1LocalizedString(@"WALK_INTRO_2_TEXT_%ld", nil),numberOfStepsPerLeg];
            step.detailText = RK1LocalizedString(@"WALK_INTRO_2_DETAIL", nil);
            step.image = [UIImage imageNamed:@"pocket" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            RK1StepArrayAddStep(steps, step);
        }
    }
    
    {
        RK1CountdownStep *step = [[RK1CountdownStep alloc] initWithIdentifier:RK1CountdownStepIdentifier];
        step.stepDuration = 5.0;
        
        RK1StepArrayAddStep(steps, step);
    }
    
    {
        {
            NSMutableArray *recorderConfigurations = [NSMutableArray array];
            if (!(RK1PredefinedTaskOptionExcludePedometer & options)) {
                [recorderConfigurations addObject:[[RK1PedometerRecorderConfiguration alloc] initWithIdentifier:RK1PedometerRecorderIdentifier]];
            }
            if (!(RK1PredefinedTaskOptionExcludeAccelerometer & options)) {
                [recorderConfigurations addObject:[[RK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:RK1AccelerometerRecorderIdentifier
                                                                                                          frequency:100]];
            }
            if (!(RK1PredefinedTaskOptionExcludeDeviceMotion & options)) {
                [recorderConfigurations addObject:[[RK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:RK1DeviceMotionRecorderIdentifier
                                                                                                         frequency:100]];
            }

            RK1WalkingTaskStep *walkingStep = [[RK1WalkingTaskStep alloc] initWithIdentifier:RK1ShortWalkOutboundStepIdentifier];
            walkingStep.numberOfStepsPerLeg = numberOfStepsPerLeg;
            walkingStep.title = [NSString localizedStringWithFormat:RK1LocalizedString(@"WALK_OUTBOUND_INSTRUCTION_FORMAT", nil), (long long)numberOfStepsPerLeg];
            walkingStep.spokenInstruction = walkingStep.title;
            walkingStep.recorderConfigurations = recorderConfigurations;
            walkingStep.shouldContinueOnFinish = YES;
            walkingStep.optional = NO;
            walkingStep.shouldStartTimerAutomatically = YES;
            walkingStep.stepDuration = numberOfStepsPerLeg * 1.5; // fallback duration in case no step count
            walkingStep.shouldVibrateOnStart = YES;
            walkingStep.shouldPlaySoundOnStart = YES;
            
            RK1StepArrayAddStep(steps, walkingStep);
        }
        
        {
            NSMutableArray *recorderConfigurations = [NSMutableArray array];
            if (!(RK1PredefinedTaskOptionExcludePedometer & options)) {
                [recorderConfigurations addObject:[[RK1PedometerRecorderConfiguration alloc] initWithIdentifier:RK1PedometerRecorderIdentifier]];
            }
            if (!(RK1PredefinedTaskOptionExcludeAccelerometer & options)) {
                [recorderConfigurations addObject:[[RK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:RK1AccelerometerRecorderIdentifier
                                                                                                          frequency:100]];
            }
            if (!(RK1PredefinedTaskOptionExcludeDeviceMotion & options)) {
                [recorderConfigurations addObject:[[RK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:RK1DeviceMotionRecorderIdentifier
                                                                                                         frequency:100]];
            }

            RK1WalkingTaskStep *walkingStep = [[RK1WalkingTaskStep alloc] initWithIdentifier:RK1ShortWalkReturnStepIdentifier];
            walkingStep.numberOfStepsPerLeg = numberOfStepsPerLeg;
            walkingStep.title = [NSString localizedStringWithFormat:RK1LocalizedString(@"WALK_RETURN_INSTRUCTION_FORMAT", nil), (long long)numberOfStepsPerLeg];
            walkingStep.spokenInstruction = walkingStep.title;
            walkingStep.recorderConfigurations = recorderConfigurations;
            walkingStep.shouldContinueOnFinish = YES;
            walkingStep.shouldStartTimerAutomatically = YES;
            walkingStep.optional = NO;
            walkingStep.stepDuration = numberOfStepsPerLeg * 1.5; // fallback duration in case no step count
            walkingStep.shouldVibrateOnStart = YES;
            walkingStep.shouldPlaySoundOnStart = YES;
            
            RK1StepArrayAddStep(steps, walkingStep);
        }
        
        if (restDuration > 0) {
            NSMutableArray *recorderConfigurations = [NSMutableArray array];
            if (!(RK1PredefinedTaskOptionExcludeAccelerometer & options)) {
                [recorderConfigurations addObject:[[RK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:RK1AccelerometerRecorderIdentifier
                                                                                                          frequency:100]];
            }
            if (!(RK1PredefinedTaskOptionExcludeDeviceMotion & options)) {
                [recorderConfigurations addObject:[[RK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:RK1DeviceMotionRecorderIdentifier
                                                                                                         frequency:100]];
            }

            RK1FitnessStep *activeStep = [[RK1FitnessStep alloc] initWithIdentifier:RK1ShortWalkRestStepIdentifier];
            activeStep.recorderConfigurations = recorderConfigurations;
            NSString *durationString = [formatter stringFromTimeInterval:restDuration];
            activeStep.title = [NSString localizedStringWithFormat:RK1LocalizedString(@"WALK_STAND_INSTRUCTION_FORMAT", nil), durationString];
            activeStep.spokenInstruction = [NSString localizedStringWithFormat:RK1LocalizedString(@"WALK_STAND_VOICE_INSTRUCTION_FORMAT", nil), durationString];
            activeStep.shouldStartTimerAutomatically = YES;
            activeStep.stepDuration = restDuration;
            activeStep.shouldContinueOnFinish = YES;
            activeStep.optional = NO;
            activeStep.shouldVibrateOnStart = YES;
            activeStep.shouldPlaySoundOnStart = YES;
            activeStep.shouldVibrateOnFinish = YES;
            activeStep.shouldPlaySoundOnFinish = YES;
            
            RK1StepArrayAddStep(steps, activeStep);
        }
    }
    
    if (!(options & RK1PredefinedTaskOptionExcludeConclusion)) {
        RK1InstructionStep *step = [self makeCompletionStep];
        
        RK1StepArrayAddStep(steps, step);
    }
    
    RK1OrderedTask *task = [[RK1OrderedTask alloc] initWithIdentifier:identifier steps:steps];
    return task;
}


+ (RK1OrderedTask *)walkBackAndForthTaskWithIdentifier:(NSString *)identifier
                                intendedUseDescription:(NSString *)intendedUseDescription
                                          walkDuration:(NSTimeInterval)walkDuration
                                          restDuration:(NSTimeInterval)restDuration
                                               options:(RK1PredefinedTaskOption)options {
    
    NSDateComponentsFormatter *formatter = [self textTimeFormatter];
    formatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
    
    NSMutableArray *steps = [NSMutableArray array];
    if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction0StepIdentifier];
            step.title = RK1LocalizedString(@"WALK_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = RK1LocalizedString(@"WALK_INTRO_TEXT", nil);
            step.shouldTintImages = YES;
            RK1StepArrayAddStep(steps, step);
        }
        
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction1StepIdentifier];
            step.title = RK1LocalizedString(@"WALK_TASK_TITLE", nil);
            step.text = RK1LocalizedString(@"WALK_INTRO_2_TEXT_BACK_AND_FORTH_INSTRUCTION", nil);
            step.detailText = RK1LocalizedString(@"WALK_INTRO_2_DETAIL_BACK_AND_FORTH_INSTRUCTION", nil);
            step.image = [UIImage imageNamed:@"pocket" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            RK1StepArrayAddStep(steps, step);
        }
    }
    
    {
        RK1CountdownStep *step = [[RK1CountdownStep alloc] initWithIdentifier:RK1CountdownStepIdentifier];
        step.stepDuration = 5.0;
        
        RK1StepArrayAddStep(steps, step);
    }
    
    {
        {
            NSMutableArray *recorderConfigurations = [NSMutableArray array];
            if (!(RK1PredefinedTaskOptionExcludePedometer & options)) {
                [recorderConfigurations addObject:[[RK1PedometerRecorderConfiguration alloc] initWithIdentifier:RK1PedometerRecorderIdentifier]];
            }
            if (!(RK1PredefinedTaskOptionExcludeAccelerometer & options)) {
                [recorderConfigurations addObject:[[RK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:RK1AccelerometerRecorderIdentifier
                                                                                                          frequency:100]];
            }
            if (!(RK1PredefinedTaskOptionExcludeDeviceMotion & options)) {
                [recorderConfigurations addObject:[[RK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:RK1DeviceMotionRecorderIdentifier
                                                                                                         frequency:100]];
            }
            
            RK1WalkingTaskStep *walkingStep = [[RK1WalkingTaskStep alloc] initWithIdentifier:RK1ShortWalkOutboundStepIdentifier];
            walkingStep.numberOfStepsPerLeg = 1000; // Set the number of steps very high so it is ignored
            NSString *walkingDurationString = [formatter stringFromTimeInterval:walkDuration];
            walkingStep.title = [NSString localizedStringWithFormat:RK1LocalizedString(@"WALK_BACK_AND_FORTH_INSTRUCTION_FORMAT", nil), walkingDurationString];
            walkingStep.spokenInstruction = walkingStep.title;
            walkingStep.recorderConfigurations = recorderConfigurations;
            walkingStep.shouldContinueOnFinish = YES;
            walkingStep.optional = NO;
            walkingStep.shouldStartTimerAutomatically = YES;
            walkingStep.stepDuration = walkDuration; // Set the walking duration to the step duration
            walkingStep.shouldVibrateOnStart = YES;
            walkingStep.shouldPlaySoundOnStart = YES;
            walkingStep.shouldSpeakRemainingTimeAtHalfway = (walkDuration > 20);
            
            RK1StepArrayAddStep(steps, walkingStep);
        }
        
        if (restDuration > 0) {
            NSMutableArray *recorderConfigurations = [NSMutableArray array];
            if (!(RK1PredefinedTaskOptionExcludeAccelerometer & options)) {
                [recorderConfigurations addObject:[[RK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:RK1AccelerometerRecorderIdentifier
                                                                                                          frequency:100]];
            }
            if (!(RK1PredefinedTaskOptionExcludeDeviceMotion & options)) {
                [recorderConfigurations addObject:[[RK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:RK1DeviceMotionRecorderIdentifier
                                                                                                         frequency:100]];
            }
            
            RK1FitnessStep *activeStep = [[RK1FitnessStep alloc] initWithIdentifier:RK1ShortWalkRestStepIdentifier];
            activeStep.recorderConfigurations = recorderConfigurations;
            NSString *durationString = [formatter stringFromTimeInterval:restDuration];
            activeStep.title = [NSString localizedStringWithFormat:RK1LocalizedString(@"WALK_BACK_AND_FORTH_STAND_INSTRUCTION_FORMAT", nil), durationString];
            activeStep.spokenInstruction = activeStep.title;
            activeStep.shouldStartTimerAutomatically = YES;
            activeStep.stepDuration = restDuration;
            activeStep.shouldContinueOnFinish = YES;
            activeStep.optional = NO;
            activeStep.shouldVibrateOnStart = YES;
            activeStep.shouldPlaySoundOnStart = YES;
            activeStep.shouldVibrateOnFinish = YES;
            activeStep.shouldPlaySoundOnFinish = YES;
            activeStep.finishedSpokenInstruction = RK1LocalizedString(@"WALK_BACK_AND_FORTH_FINISHED_VOICE", nil);
            activeStep.shouldSpeakRemainingTimeAtHalfway = (restDuration > 20);
            
            RK1StepArrayAddStep(steps, activeStep);
        }
    }
    
    if (!(options & RK1PredefinedTaskOptionExcludeConclusion)) {
        RK1InstructionStep *step = [self makeCompletionStep];
        
        RK1StepArrayAddStep(steps, step);
    }
    
    RK1OrderedTask *task = [[RK1OrderedTask alloc] initWithIdentifier:identifier steps:steps];
    return task;
}

+ (RK1OrderedTask *)kneeRangeOfMotionTaskWithIdentifier:(NSString *)identifier
                                             limbOption:(RK1PredefinedTaskLimbOption)limbOption
                                 intendedUseDescription:(NSString *)intendedUseDescription
                                                options:(RK1PredefinedTaskOption)options {
    NSMutableArray *steps = [NSMutableArray array];
    NSString *limbType = RK1LocalizedString(@"LIMB_RIGHT", nil);
    UIImage *kneeFlexedImage = [UIImage imageNamed:@"knee_flexed_right" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    UIImage *kneeExtendedImage = [UIImage imageNamed:@"knee_extended_right" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];

    if (limbOption == RK1PredefinedTaskLimbOptionLeft) {
        limbType = RK1LocalizedString(@"LIMB_LEFT", nil);
    
        kneeFlexedImage = [UIImage imageNamed:@"knee_flexed_left" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
        kneeExtendedImage = [UIImage imageNamed:@"knee_extended_left" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    }
    
    if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
        RK1InstructionStep *instructionStep0 = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction0StepIdentifier];
        instructionStep0.title = ([limbType isEqualToString:RK1LocalizedString(@"LIMB_LEFT", nil)])? RK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TITLE_LEFT", nil) : RK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TITLE_RIGHT", nil);
        instructionStep0.text = intendedUseDescription;
        instructionStep0.detailText = ([limbType isEqualToString:RK1LocalizedString(@"LIMB_LEFT", nil)])? RK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TEXT_INSTRUCTION_0_LEFT", nil) : RK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TEXT_INSTRUCTION_0_RIGHT", nil);
        instructionStep0.shouldTintImages = YES;
        RK1StepArrayAddStep(steps, instructionStep0);
 
        RK1InstructionStep *instructionStep1 = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction1StepIdentifier];
        instructionStep1.title = ([limbType isEqualToString:RK1LocalizedString(@"LIMB_LEFT", nil)])? RK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TITLE_LEFT", nil) : RK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TITLE_RIGHT", nil);
        
        instructionStep1.detailText = ([limbType isEqualToString:RK1LocalizedString(@"LIMB_LEFT", nil)])? RK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TEXT_INSTRUCTION_1_LEFT", nil) : RK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TEXT_INSTRUCTION_1_RIGHT", nil);
        RK1StepArrayAddStep(steps, instructionStep1);
        
        RK1InstructionStep *instructionStep2 = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction2StepIdentifier];
        instructionStep2.title = ([limbType isEqualToString:RK1LocalizedString(@"LIMB_LEFT", nil)])? RK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TITLE_LEFT", nil) : RK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TITLE_RIGHT", nil);
        
        instructionStep2.detailText = ([limbType isEqualToString:RK1LocalizedString(@"LIMB_LEFT", nil)])? RK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TEXT_INSTRUCTION_2_LEFT", nil) : RK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TEXT_INSTRUCTION_2_RIGHT", nil);
        instructionStep2.image = kneeFlexedImage;
        instructionStep2.shouldTintImages = YES;
        RK1StepArrayAddStep(steps, instructionStep2);
        
        RK1InstructionStep *instructionStep3 = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction3StepIdentifier];
        instructionStep3.title = ([limbType isEqualToString:RK1LocalizedString(@"LIMB_LEFT", nil)])? RK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TITLE_LEFT", nil) : RK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TITLE_RIGHT", nil);
        instructionStep3.detailText = ([limbType isEqualToString:RK1LocalizedString(@"LIMB_LEFT", nil)])? RK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TEXT_INSTRUCTION_3_LEFT", nil) : RK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TEXT_INSTRUCTION_3_RIGHT", nil);

        instructionStep3.image = kneeExtendedImage;
        instructionStep3.shouldTintImages = YES;
        RK1StepArrayAddStep(steps, instructionStep3);
    }
    NSString *instructionText = ([limbType isEqualToString:RK1LocalizedString(@"LIMB_LEFT", nil)])? RK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TOUCH_ANYWHERE_STEP_INSTRUCTION_LEFT", nil) : RK1LocalizedString(@"KNEE_RANGE_OF_MOTION_TOUCH_ANYWHERE_STEP_INSTRUCTION_RIGHT", nil);
    RK1TouchAnywhereStep *touchAnywhereStep = [[RK1TouchAnywhereStep alloc] initWithIdentifier:RK1TouchAnywhereStepIdentifier instructionText:instructionText];
    RK1StepArrayAddStep(steps, touchAnywhereStep);
    
    RK1DeviceMotionRecorderConfiguration *deviceMotionRecorderConfig = [[RK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:RK1DeviceMotionRecorderIdentifier frequency:100];
    
    RK1RangeOfMotionStep *kneeRangeOfMotionStep = [[RK1RangeOfMotionStep alloc] initWithIdentifier:RK1KneeRangeOfMotionStepIdentifier limbOption:limbOption];
    kneeRangeOfMotionStep.title = ([limbType isEqualToString: RK1LocalizedString(@"LIMB_LEFT", nil)])? RK1LocalizedString(@"KNEE_RANGE_OF_MOTION_SPOKEN_INSTRUCTION_LEFT", nil) :
    RK1LocalizedString(@"KNEE_RANGE_OF_MOTION_SPOKEN_INSTRUCTION_RIGHT", nil);
    
    kneeRangeOfMotionStep.spokenInstruction = kneeRangeOfMotionStep.title;
    kneeRangeOfMotionStep.recorderConfigurations = @[deviceMotionRecorderConfig];
    kneeRangeOfMotionStep.optional = NO;

    RK1StepArrayAddStep(steps, kneeRangeOfMotionStep);

    if (!(options & RK1PredefinedTaskOptionExcludeConclusion)) {
        RK1CompletionStep *completionStep = [self makeCompletionStep];
        RK1StepArrayAddStep(steps, completionStep);
    }
    
    RK1OrderedTask *task = [[RK1OrderedTask alloc] initWithIdentifier:identifier steps:steps];
    return task;
}

+ (RK1OrderedTask *)shoulderRangeOfMotionTaskWithIdentifier:(NSString *)identifier
                                                 limbOption:(RK1PredefinedTaskLimbOption)limbOption
                                     intendedUseDescription:(NSString *)intendedUseDescription
                                                    options:(RK1PredefinedTaskOption)options {
    NSMutableArray *steps = [NSMutableArray array];
    NSString *limbType = RK1LocalizedString(@"LIMB_RIGHT", nil);
    UIImage *shoulderFlexedImage = [UIImage imageNamed:@"shoulder_flexed_right" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    UIImage *shoulderExtendedImage = [UIImage imageNamed:@"shoulder_extended_right" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];

    if (limbOption == RK1PredefinedTaskLimbOptionLeft) {
        limbType = RK1LocalizedString(@"LIMB_LEFT", nil);
        shoulderFlexedImage = [UIImage imageNamed:@"shoulder_flexed_left" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
        shoulderExtendedImage = [UIImage imageNamed:@"shoulder_extended_left" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    }
    
    if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
        RK1InstructionStep *instructionStep0 = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction0StepIdentifier];
        instructionStep0.title = ([limbType isEqualToString:RK1LocalizedString(@"LIMB_LEFT", nil)])? RK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TITLE_LEFT", nil) : RK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TITLE_RIGHT", nil);
        instructionStep0.text = intendedUseDescription;
        instructionStep0.detailText = ([limbType isEqualToString:RK1LocalizedString(@"LIMB_LEFT", nil)])? RK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TEXT_INSTRUCTION_0_LEFT", nil) : RK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TEXT_INSTRUCTION_0_RIGHT", nil);
        instructionStep0.shouldTintImages = YES;
        RK1StepArrayAddStep(steps, instructionStep0);
        
        RK1InstructionStep *instructionStep1 = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction1StepIdentifier];
        instructionStep1.title = ([limbType isEqualToString:RK1LocalizedString(@"LIMB_LEFT", nil)])? RK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TITLE_LEFT", nil) : RK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TITLE_RIGHT", nil);
        
        instructionStep1.detailText = ([limbType isEqualToString:RK1LocalizedString(@"LIMB_LEFT", nil)])? RK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TEXT_INSTRUCTION_1_LEFT", nil) : RK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TEXT_INSTRUCTION_1_RIGHT", nil);
        RK1StepArrayAddStep(steps, instructionStep1);
        
        RK1InstructionStep *instructionStep2 = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction2StepIdentifier];
        instructionStep2.title = ([limbType isEqualToString:RK1LocalizedString(@"LIMB_LEFT", nil)])? RK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TITLE_LEFT", nil) : RK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TITLE_RIGHT", nil);
        
        instructionStep2.detailText = ([limbType isEqualToString:RK1LocalizedString(@"LIMB_LEFT", nil)])? RK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TEXT_INSTRUCTION_2_LEFT", nil) : RK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TEXT_INSTRUCTION_2_RIGHT", nil);
        instructionStep2.image = shoulderFlexedImage;
        instructionStep2.shouldTintImages = YES;
        RK1StepArrayAddStep(steps, instructionStep2);
        
        RK1InstructionStep *instructionStep3 = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction3StepIdentifier];
        instructionStep3.title = ([limbType isEqualToString:RK1LocalizedString(@"LIMB_LEFT", nil)])? RK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TITLE_LEFT", nil) : RK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TITLE_RIGHT", nil);
        
        instructionStep3.detailText = ([limbType isEqualToString:RK1LocalizedString(@"LIMB_LEFT", nil)])? RK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TEXT_INSTRUCTION_3_LEFT", nil) : RK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TEXT_INSTRUCTION_3_RIGHT", nil);
        instructionStep3.image = shoulderExtendedImage;
        instructionStep3.shouldTintImages = YES;
        RK1StepArrayAddStep(steps, instructionStep3);
    }
    
    NSString *instructionText = ([limbType isEqualToString:RK1LocalizedString(@"LIMB_LEFT", nil)])? RK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TOUCH_ANYWHERE_STEP_INSTRUCTION_LEFT", nil) : RK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_TOUCH_ANYWHERE_STEP_INSTRUCTION_RIGHT", nil);
    RK1TouchAnywhereStep *touchAnywhereStep = [[RK1TouchAnywhereStep alloc] initWithIdentifier:RK1TouchAnywhereStepIdentifier instructionText:instructionText];
    RK1StepArrayAddStep(steps, touchAnywhereStep);
    
    RK1DeviceMotionRecorderConfiguration *deviceMotionRecorderConfig = [[RK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:RK1DeviceMotionRecorderIdentifier frequency:100];
    
    RK1ShoulderRangeOfMotionStep *shoulderRangeOfMotionStep = [[RK1ShoulderRangeOfMotionStep alloc] initWithIdentifier:RK1ShoulderRangeOfMotionStepIdentifier limbOption:limbOption];
    shoulderRangeOfMotionStep.title = ([limbType isEqualToString: RK1LocalizedString(@"LIMB_LEFT", nil)])? RK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_SPOKEN_INSTRUCTION_LEFT", nil) :
    RK1LocalizedString(@"SHOULDER_RANGE_OF_MOTION_SPOKEN_INSTRUCTION_RIGHT", nil);

    shoulderRangeOfMotionStep.spokenInstruction = shoulderRangeOfMotionStep.title;
    
    shoulderRangeOfMotionStep.recorderConfigurations = @[deviceMotionRecorderConfig];
    shoulderRangeOfMotionStep.optional = NO;
    
    RK1StepArrayAddStep(steps, shoulderRangeOfMotionStep);
    
    if (!(options & RK1PredefinedTaskOptionExcludeConclusion)) {
        RK1CompletionStep *completionStep = [self makeCompletionStep];
        RK1StepArrayAddStep(steps, completionStep);
    }
    
    RK1OrderedTask *task = [[RK1OrderedTask alloc] initWithIdentifier:identifier steps:steps];
    return task;
}

+ (RK1OrderedTask *)spatialSpanMemoryTaskWithIdentifier:(NSString *)identifier
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
                                                options:(RK1PredefinedTaskOption)options {
    
    NSString *targetPluralName = customTargetPluralName ? : RK1LocalizedString(@"SPATIAL_SPAN_MEMORY_TARGET_PLURAL", nil);
    
    NSMutableArray *steps = [NSMutableArray array];
    if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction0StepIdentifier];
            step.title = RK1LocalizedString(@"SPATIAL_SPAN_MEMORY_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = [NSString localizedStringWithFormat:RK1LocalizedString(@"SPATIAL_SPAN_MEMORY_INTRO_TEXT_%@", nil),targetPluralName];
            
            step.image = [UIImage imageNamed:@"phone-memory" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
        
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction1StepIdentifier];
            step.title = RK1LocalizedString(@"SPATIAL_SPAN_MEMORY_TITLE", nil);
            step.text = [NSString localizedStringWithFormat:requireReversal ? RK1LocalizedString(@"SPATIAL_SPAN_MEMORY_INTRO_2_TEXT_REVERSE_%@", nil) : RK1LocalizedString(@"SPATIAL_SPAN_MEMORY_INTRO_2_TEXT_%@", nil), targetPluralName, targetPluralName];
            step.detailText = RK1LocalizedString(@"SPATIAL_SPAN_MEMORY_CALL_TO_ACTION", nil);
            
            if (!customTargetImage) {
                step.image = [UIImage imageNamed:@"memory-second-screen" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            } else {
                step.image = customTargetImage;
            }
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
    }
    
    {
        RK1SpatialSpanMemoryStep *step = [[RK1SpatialSpanMemoryStep alloc] initWithIdentifier:RK1SpatialSpanMemoryStepIdentifier];
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
        
        RK1StepArrayAddStep(steps, step);
    }
    
    if (!(options & RK1PredefinedTaskOptionExcludeConclusion)) {
        RK1InstructionStep *step = [self makeCompletionStep];
        RK1StepArrayAddStep(steps, step);
    }
    
    RK1OrderedTask *task = [[RK1OrderedTask alloc] initWithIdentifier:identifier steps:steps];
    return task;
}

+ (RK1OrderedTask *)stroopTaskWithIdentifier:(NSString *)identifier
                      intendedUseDescription:(nullable NSString *)intendedUseDescription
                            numberOfAttempts:(NSInteger)numberOfAttempts
                                     options:(RK1PredefinedTaskOption)options {
    NSMutableArray *steps = [NSMutableArray array];
    if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction0StepIdentifier];
            step.title = RK1LocalizedString(@"STROOP_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.image = [UIImage imageNamed:@"phonestrooplabel" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction1StepIdentifier];
            step.title = RK1LocalizedString(@"STROOP_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = RK1LocalizedString(@"STROOP_TASK_INTRO1_DETAIL_TEXT", nil);
            step.image = [UIImage imageNamed:@"phonestroopbutton" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction2StepIdentifier];
            step.title = RK1LocalizedString(@"STROOP_TASK_TITLE", nil);
            step.detailText = RK1LocalizedString(@"STROOP_TASK_INTRO2_DETAIL_TEXT", nil);
            step.image = [UIImage imageNamed:@"phonestroopbutton" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
    }
    {
        RK1CountdownStep *step = [[RK1CountdownStep alloc] initWithIdentifier:RK1CountdownStepIdentifier];
        step.stepDuration = 5.0;
        
        RK1StepArrayAddStep(steps, step);
    }
    {
        RK1StroopStep *step = [[RK1StroopStep alloc] initWithIdentifier:RK1StroopStepIdentifier];
        step.text = RK1LocalizedString(@"STROOP_TASK_STEP_TEXT", nil);
        step.numberOfAttempts = numberOfAttempts;
        
        RK1StepArrayAddStep(steps, step);
    }
    
    if (!(options & RK1PredefinedTaskOptionExcludeConclusion)) {
        RK1InstructionStep *step = [self makeCompletionStep];
        
        RK1StepArrayAddStep(steps, step);
    }
    
    RK1OrderedTask *task = [[RK1OrderedTask alloc] initWithIdentifier:identifier steps:steps];
    return task;
}

+ (RK1OrderedTask *)toneAudiometryTaskWithIdentifier:(NSString *)identifier
                              intendedUseDescription:(nullable NSString *)intendedUseDescription
                                   speechInstruction:(nullable NSString *)speechInstruction
                              shortSpeechInstruction:(nullable NSString *)shortSpeechInstruction
                                        toneDuration:(NSTimeInterval)toneDuration
                                             options:(RK1PredefinedTaskOption)options {

    if (options & RK1PredefinedTaskOptionExcludeAudio) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"Audio collection cannot be excluded from audio task" userInfo:nil];
    }

    NSMutableArray *steps = [NSMutableArray array];
    if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction0StepIdentifier];
            step.title = RK1LocalizedString(@"TONE_AUDIOMETRY_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = RK1LocalizedString(@"TONE_AUDIOMETRY_INTENDED_USE", nil);
            step.image = [UIImage imageNamed:@"phonewaves_inverted" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;

            RK1StepArrayAddStep(steps, step);
        }
        
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction1StepIdentifier];
            step.title = RK1LocalizedString(@"TONE_AUDIOMETRY_TASK_TITLE", nil);
            step.text = speechInstruction ? : RK1LocalizedString(@"TONE_AUDIOMETRY_INTRO_TEXT", nil);
            step.detailText = RK1LocalizedString(@"TONE_AUDIOMETRY_CALL_TO_ACTION", nil);
            step.image = [UIImage imageNamed:@"phonewaves_tapping" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;

            RK1StepArrayAddStep(steps, step);
        }
    }

    {
        RK1ToneAudiometryPracticeStep *step = [[RK1ToneAudiometryPracticeStep alloc] initWithIdentifier:RK1ToneAudiometryPracticeStepIdentifier];
        step.title = RK1LocalizedString(@"TONE_AUDIOMETRY_TASK_TITLE", nil);
        step.text = speechInstruction ? : RK1LocalizedString(@"TONE_AUDIOMETRY_PREP_TEXT", nil);
        RK1StepArrayAddStep(steps, step);
        
    }
    
    {
        RK1CountdownStep *step = [[RK1CountdownStep alloc] initWithIdentifier:RK1CountdownStepIdentifier];
        step.stepDuration = 5.0;

        RK1StepArrayAddStep(steps, step);
    }

    {
        RK1ToneAudiometryStep *step = [[RK1ToneAudiometryStep alloc] initWithIdentifier:RK1ToneAudiometryStepIdentifier];
        step.title = shortSpeechInstruction ? : RK1LocalizedString(@"TONE_AUDIOMETRY_INSTRUCTION", nil);
        step.toneDuration = toneDuration;

        RK1StepArrayAddStep(steps, step);
    }

    if (!(options & RK1PredefinedTaskOptionExcludeConclusion)) {
        RK1InstructionStep *step = [self makeCompletionStep];

        RK1StepArrayAddStep(steps, step);
    }

    RK1OrderedTask *task = [[RK1OrderedTask alloc] initWithIdentifier:identifier steps:steps];

    return task;
}

+ (RK1OrderedTask *)towerOfHanoiTaskWithIdentifier:(NSString *)identifier
                            intendedUseDescription:(nullable NSString *)intendedUseDescription
                                     numberOfDisks:(NSUInteger)numberOfDisks
                                           options:(RK1PredefinedTaskOption)options {
    
    NSMutableArray *steps = [NSMutableArray array];
    
    if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction0StepIdentifier];
            step.title = RK1LocalizedString(@"TOWER_OF_HANOI_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = RK1LocalizedString(@"TOWER_OF_HANOI_TASK_INTENDED_USE", nil);
            step.image = [UIImage imageNamed:@"phone-tower-of-hanoi" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
        
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction1StepIdentifier];
            step.title = RK1LocalizedString(@"TOWER_OF_HANOI_TASK_TITLE", nil);
            step.text = RK1LocalizedString(@"TOWER_OF_HANOI_TASK_INTRO_TEXT", nil);
            step.detailText = RK1LocalizedString(@"TOWER_OF_HANOI_TASK_TASK_CALL_TO_ACTION", nil);
            step.image = [UIImage imageNamed:@"tower-of-hanoi-second-screen" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
    }
    
    RK1TowerOfHanoiStep *towerOfHanoiStep = [[RK1TowerOfHanoiStep alloc]initWithIdentifier:RK1TowerOfHanoiStepIdentifier];
    towerOfHanoiStep.numberOfDisks = numberOfDisks;
    RK1StepArrayAddStep(steps, towerOfHanoiStep);
    
    if (!(options & RK1PredefinedTaskOptionExcludeConclusion)) {
        RK1InstructionStep *step = [self makeCompletionStep];
        
        RK1StepArrayAddStep(steps, step);
    }
    
    RK1OrderedTask *task = [[RK1OrderedTask alloc]initWithIdentifier:identifier steps:steps];
    
    return task;
}

+ (RK1OrderedTask *)reactionTimeTaskWithIdentifier:(NSString *)identifier
                            intendedUseDescription:(nullable NSString *)intendedUseDescription
                           maximumStimulusInterval:(NSTimeInterval)maximumStimulusInterval
                           minimumStimulusInterval:(NSTimeInterval)minimumStimulusInterval
                             thresholdAcceleration:(double)thresholdAcceleration
                                  numberOfAttempts:(int)numberOfAttempts
                                           timeout:(NSTimeInterval)timeout
                                      successSound:(UInt32)successSoundID
                                      timeoutSound:(UInt32)timeoutSoundID
                                      failureSound:(UInt32)failureSoundID
                                           options:(RK1PredefinedTaskOption)options {
    
    NSMutableArray *steps = [NSMutableArray array];
    
    if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction0StepIdentifier];
            step.title = RK1LocalizedString(@"REACTION_TIME_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = RK1LocalizedString(@"REACTION_TIME_TASK_INTENDED_USE", nil);
            step.image = [UIImage imageNamed:@"phoneshake" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
        
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction1StepIdentifier];
            step.title = RK1LocalizedString(@"REACTION_TIME_TASK_TITLE", nil);
            step.text = [NSString localizedStringWithFormat: RK1LocalizedString(@"REACTION_TIME_TASK_INTRO_TEXT_FORMAT", nil), numberOfAttempts];
            step.detailText = RK1LocalizedString(@"REACTION_TIME_TASK_CALL_TO_ACTION", nil);
            step.image = [UIImage imageNamed:@"phoneshakecircle" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
    }
    
    RK1ReactionTimeStep *step = [[RK1ReactionTimeStep alloc] initWithIdentifier:RK1ReactionTimeStepIdentifier];
    step.maximumStimulusInterval = maximumStimulusInterval;
    step.minimumStimulusInterval = minimumStimulusInterval;
    step.thresholdAcceleration = thresholdAcceleration;
    step.numberOfAttempts = numberOfAttempts;
    step.timeout = timeout;
    step.successSound = successSoundID;
    step.timeoutSound = timeoutSoundID;
    step.failureSound = failureSoundID;
    step.recorderConfigurations = @[ [[RK1DeviceMotionRecorderConfiguration  alloc] initWithIdentifier:RK1DeviceMotionRecorderIdentifier frequency: 100]];

    RK1StepArrayAddStep(steps, step);
    
    if (!(options & RK1PredefinedTaskOptionExcludeConclusion)) {
        RK1InstructionStep *step = [self makeCompletionStep];
        RK1StepArrayAddStep(steps, step);
    }
    
    RK1OrderedTask *task = [[RK1OrderedTask alloc] initWithIdentifier:identifier steps:steps];
    
    return task;
}

+ (RK1OrderedTask *)timedWalkTaskWithIdentifier:(NSString *)identifier
                         intendedUseDescription:(nullable NSString *)intendedUseDescription
                               distanceInMeters:(double)distanceInMeters
                                      timeLimit:(NSTimeInterval)timeLimit
                     includeAssistiveDeviceForm:(BOOL)includeAssistiveDeviceForm
                                        options:(RK1PredefinedTaskOption)options {

    NSMutableArray *steps = [NSMutableArray array];

    NSLengthFormatter *lengthFormatter = [NSLengthFormatter new];
    lengthFormatter.numberFormatter.maximumFractionDigits = 1;
    lengthFormatter.numberFormatter.maximumSignificantDigits = 3;
    NSString *formattedLength = [lengthFormatter stringFromMeters:distanceInMeters];

    if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction0StepIdentifier];
            step.title = RK1LocalizedString(@"TIMED_WALK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = RK1LocalizedString(@"TIMED_WALK_INTRO_DETAIL", nil);
            step.shouldTintImages = YES;

            RK1StepArrayAddStep(steps, step);
        }
    }

    if (includeAssistiveDeviceForm) {
        RK1FormStep *step = [[RK1FormStep alloc] initWithIdentifier:RK1TimedWalkFormStepIdentifier
                                                              title:RK1LocalizedString(@"TIMED_WALK_FORM_TITLE", nil)
                                                               text:RK1LocalizedString(@"TIMED_WALK_FORM_TEXT", nil)];

        RK1AnswerFormat *answerFormat1 = [RK1AnswerFormat booleanAnswerFormat];
        RK1FormItem *formItem1 = [[RK1FormItem alloc] initWithIdentifier:RK1TimedWalkFormAFOStepIdentifier
                                                                    text:RK1LocalizedString(@"TIMED_WALK_QUESTION_TEXT", nil)
                                                            answerFormat:answerFormat1];
        formItem1.optional = NO;

        NSArray *textChoices = @[RK1LocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE", nil),
                                 RK1LocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_2", nil),
                                 RK1LocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_3", nil),
                                 RK1LocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_4", nil),
                                 RK1LocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_5", nil),
                                 RK1LocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_6", nil)];
        RK1AnswerFormat *answerFormat2 = [RK1AnswerFormat valuePickerAnswerFormatWithTextChoices:textChoices];
        RK1FormItem *formItem2 = [[RK1FormItem alloc] initWithIdentifier:RK1TimedWalkFormAssistanceStepIdentifier
                                                                    text:RK1LocalizedString(@"TIMED_WALK_QUESTION_2_TITLE", nil)
                                                            answerFormat:answerFormat2];
        formItem2.placeholder = RK1LocalizedString(@"TIMED_WALK_QUESTION_2_TEXT", nil);
        formItem2.optional = NO;

        step.formItems = @[formItem1, formItem2];
        step.optional = NO;

        RK1StepArrayAddStep(steps, step);
    }

    if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction1StepIdentifier];
            step.title = RK1LocalizedString(@"TIMED_WALK_TITLE", nil);
            step.text = [NSString localizedStringWithFormat:RK1LocalizedString(@"TIMED_WALK_INTRO_2_TEXT_%@", nil), formattedLength];
            step.detailText = RK1LocalizedString(@"TIMED_WALK_INTRO_2_DETAIL", nil);
            step.image = [UIImage imageNamed:@"timer" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;

            RK1StepArrayAddStep(steps, step);
        }
    }

    {
        RK1CountdownStep *step = [[RK1CountdownStep alloc] initWithIdentifier:RK1CountdownStepIdentifier];
        step.stepDuration = 5.0;

        RK1StepArrayAddStep(steps, step);
    }
    
    {
        NSMutableArray *recorderConfigurations = [NSMutableArray array];
        if (!(options & RK1PredefinedTaskOptionExcludePedometer)) {
            [recorderConfigurations addObject:[[RK1PedometerRecorderConfiguration alloc] initWithIdentifier:RK1PedometerRecorderIdentifier]];
        }
        if (!(options & RK1PredefinedTaskOptionExcludeAccelerometer)) {
            [recorderConfigurations addObject:[[RK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:RK1AccelerometerRecorderIdentifier
                                                                                                      frequency:100]];
        }
        if (!(options & RK1PredefinedTaskOptionExcludeDeviceMotion)) {
            [recorderConfigurations addObject:[[RK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:RK1DeviceMotionRecorderIdentifier
                                                                                                     frequency:100]];
        }
        if (! (options & RK1PredefinedTaskOptionExcludeLocation)) {
            [recorderConfigurations addObject:[[RK1LocationRecorderConfiguration alloc] initWithIdentifier:RK1LocationRecorderIdentifier]];
        }

        {
            RK1TimedWalkStep *step = [[RK1TimedWalkStep alloc] initWithIdentifier:RK1TimedWalkTrial1StepIdentifier];
            step.title = [[NSString alloc] initWithFormat:RK1LocalizedString(@"TIMED_WALK_INSTRUCTION_%@", nil), formattedLength];
            step.text = RK1LocalizedString(@"TIMED_WALK_INSTRUCTION_TEXT", nil);
            step.spokenInstruction = step.title;
            step.recorderConfigurations = recorderConfigurations;
            step.distanceInMeters = distanceInMeters;
            step.shouldTintImages = YES;
            step.image = [UIImage imageNamed:@"timed-walkingman-outbound" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.stepDuration = timeLimit == 0 ? CGFLOAT_MAX : timeLimit;

            RK1StepArrayAddStep(steps, step);
        }

        {
            RK1TimedWalkStep *step = [[RK1TimedWalkStep alloc] initWithIdentifier:RK1TimedWalkTrial2StepIdentifier];
            step.title = [[NSString alloc] initWithFormat:RK1LocalizedString(@"TIMED_WALK_INSTRUCTION_2", nil), formattedLength];
            step.text = RK1LocalizedString(@"TIMED_WALK_INSTRUCTION_TEXT", nil);
            step.spokenInstruction = step.title;
            step.recorderConfigurations = recorderConfigurations;
            step.distanceInMeters = distanceInMeters;
            step.shouldTintImages = YES;
            step.image = [UIImage imageNamed:@"timed-walkingman-return" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.stepDuration = timeLimit == 0 ? CGFLOAT_MAX : timeLimit;

            RK1StepArrayAddStep(steps, step);
        }
    }

    if (!(options & RK1PredefinedTaskOptionExcludeConclusion)) {
        RK1InstructionStep *step = [self makeCompletionStep];

        RK1StepArrayAddStep(steps, step);
    }

    RK1OrderedTask *task = [[RK1OrderedTask alloc] initWithIdentifier:identifier steps:steps];
    return task;
}

+ (RK1OrderedTask *)timedWalkTaskWithIdentifier:(NSString *)identifier
                         intendedUseDescription:(nullable NSString *)intendedUseDescription
                               distanceInMeters:(double)distanceInMeters
                                      timeLimit:(NSTimeInterval)timeLimit
                            turnAroundTimeLimit:(NSTimeInterval)turnAroundTimeLimit
                     includeAssistiveDeviceForm:(BOOL)includeAssistiveDeviceForm
                                        options:(RK1PredefinedTaskOption)options {

    NSMutableArray *steps = [NSMutableArray array];

    NSLengthFormatter *lengthFormatter = [NSLengthFormatter new];
    lengthFormatter.numberFormatter.maximumFractionDigits = 1;
    lengthFormatter.numberFormatter.maximumSignificantDigits = 3;
    NSString *formattedLength = [lengthFormatter stringFromMeters:distanceInMeters];

    if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction0StepIdentifier];
            step.title = RK1LocalizedString(@"TIMED_WALK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = RK1LocalizedString(@"TIMED_WALK_INTRO_DETAIL", nil);
            step.shouldTintImages = YES;

            RK1StepArrayAddStep(steps, step);
        }
    }

    if (includeAssistiveDeviceForm) {
        RK1FormStep *step = [[RK1FormStep alloc] initWithIdentifier:RK1TimedWalkFormStepIdentifier
                                                              title:RK1LocalizedString(@"TIMED_WALK_FORM_TITLE", nil)
                                                               text:RK1LocalizedString(@"TIMED_WALK_FORM_TEXT", nil)];

        RK1AnswerFormat *answerFormat1 = [RK1AnswerFormat booleanAnswerFormat];
        RK1FormItem *formItem1 = [[RK1FormItem alloc] initWithIdentifier:RK1TimedWalkFormAFOStepIdentifier
                                                                    text:RK1LocalizedString(@"TIMED_WALK_QUESTION_TEXT", nil)
                                                            answerFormat:answerFormat1];
        formItem1.optional = NO;

        NSArray *textChoices = @[RK1LocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE", nil),
                                 RK1LocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_2", nil),
                                 RK1LocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_3", nil),
                                 RK1LocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_4", nil),
                                 RK1LocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_5", nil),
                                 RK1LocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_6", nil)];
        RK1AnswerFormat *answerFormat2 = [RK1AnswerFormat valuePickerAnswerFormatWithTextChoices:textChoices];
        RK1FormItem *formItem2 = [[RK1FormItem alloc] initWithIdentifier:RK1TimedWalkFormAssistanceStepIdentifier
                                                                    text:RK1LocalizedString(@"TIMED_WALK_QUESTION_2_TITLE", nil)
                                                            answerFormat:answerFormat2];
        formItem2.placeholder = RK1LocalizedString(@"TIMED_WALK_QUESTION_2_TEXT", nil);
        formItem2.optional = NO;

        step.formItems = @[formItem1, formItem2];
        step.optional = NO;

        RK1StepArrayAddStep(steps, step);
    }

    if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction1StepIdentifier];
            step.title = RK1LocalizedString(@"TIMED_WALK_TITLE", nil);
            step.text = [NSString localizedStringWithFormat:RK1LocalizedString(@"TIMED_WALK_INTRO_2_TEXT_%@", nil), formattedLength];
            step.detailText = RK1LocalizedString(@"TIMED_WALK_INTRO_2_DETAIL", nil);
            step.image = [UIImage imageNamed:@"timer" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;

            RK1StepArrayAddStep(steps, step);
        }
    }

    {
        RK1CountdownStep *step = [[RK1CountdownStep alloc] initWithIdentifier:RK1CountdownStepIdentifier];
        step.stepDuration = 5.0;

        RK1StepArrayAddStep(steps, step);
    }

    {
        NSMutableArray *recorderConfigurations = [NSMutableArray array];
        if (!(options & RK1PredefinedTaskOptionExcludePedometer)) {
            [recorderConfigurations addObject:[[RK1PedometerRecorderConfiguration alloc] initWithIdentifier:RK1PedometerRecorderIdentifier]];
        }
        if (!(options & RK1PredefinedTaskOptionExcludeAccelerometer)) {
            [recorderConfigurations addObject:[[RK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:RK1AccelerometerRecorderIdentifier
                                                                                                      frequency:100]];
        }
        if (!(options & RK1PredefinedTaskOptionExcludeDeviceMotion)) {
            [recorderConfigurations addObject:[[RK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:RK1DeviceMotionRecorderIdentifier
                                                                                                     frequency:100]];
        }
        if (! (options & RK1PredefinedTaskOptionExcludeLocation)) {
            [recorderConfigurations addObject:[[RK1LocationRecorderConfiguration alloc] initWithIdentifier:RK1LocationRecorderIdentifier]];
        }

        {
            RK1TimedWalkStep *step = [[RK1TimedWalkStep alloc] initWithIdentifier:RK1TimedWalkTrial1StepIdentifier];
            step.title = [[NSString alloc] initWithFormat:RK1LocalizedString(@"TIMED_WALK_INSTRUCTION_%@", nil), formattedLength];
            step.text = RK1LocalizedString(@"TIMED_WALK_INSTRUCTION_TEXT", nil);
            step.spokenInstruction = step.title;
            step.recorderConfigurations = recorderConfigurations;
            step.distanceInMeters = distanceInMeters;
            step.shouldTintImages = YES;
            step.image = [UIImage imageNamed:@"timed-walkingman-outbound" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.stepDuration = timeLimit == 0 ? CGFLOAT_MAX : timeLimit;

            RK1StepArrayAddStep(steps, step);
        }

        {
            RK1TimedWalkStep *step = [[RK1TimedWalkStep alloc] initWithIdentifier:RK1TimedWalkTurnAroundStepIdentifier];
            step.title = RK1LocalizedString(@"TIMED_WALK_INSTRUCTION_TURN", nil);
            step.text = RK1LocalizedString(@"TIMED_WALK_INSTRUCTION_TEXT", nil);
            step.spokenInstruction = step.title;
            step.recorderConfigurations = recorderConfigurations;
            step.distanceInMeters = 1;
            step.shouldTintImages = YES;
            step.image = [UIImage imageNamed:@"turnaround" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.stepDuration = turnAroundTimeLimit == 0 ? CGFLOAT_MAX : turnAroundTimeLimit;

            RK1StepArrayAddStep(steps, step);
        }

        {
            RK1TimedWalkStep *step = [[RK1TimedWalkStep alloc] initWithIdentifier:RK1TimedWalkTrial2StepIdentifier];
            step.title = [[NSString alloc] initWithFormat:RK1LocalizedString(@"TIMED_WALK_INSTRUCTION_2", nil), formattedLength];
            step.text = RK1LocalizedString(@"TIMED_WALK_INSTRUCTION_TEXT", nil);
            step.spokenInstruction = step.title;
            step.recorderConfigurations = recorderConfigurations;
            step.distanceInMeters = distanceInMeters;
            step.shouldTintImages = YES;
            step.image = [UIImage imageNamed:@"timed-walkingman-return" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.stepDuration = timeLimit == 0 ? CGFLOAT_MAX : timeLimit;

            RK1StepArrayAddStep(steps, step);
        }
    }

    if (!(options & RK1PredefinedTaskOptionExcludeConclusion)) {
        RK1InstructionStep *step = [self makeCompletionStep];

        RK1StepArrayAddStep(steps, step);
    }

    RK1OrderedTask *task = [[RK1OrderedTask alloc] initWithIdentifier:identifier steps:steps];
    return task;
}

+ (RK1OrderedTask *)PSATTaskWithIdentifier:(NSString *)identifier
                    intendedUseDescription:(nullable NSString *)intendedUseDescription
                          presentationMode:(RK1PSATPresentationMode)presentationMode
                     interStimulusInterval:(NSTimeInterval)interStimulusInterval
                          stimulusDuration:(NSTimeInterval)stimulusDuration
                              seriesLength:(NSInteger)seriesLength
                                   options:(RK1PredefinedTaskOption)options {
    
    NSMutableArray *steps = [NSMutableArray array];
    NSString *versionTitle = @"";
    NSString *versionDetailText = @"";
    
    if (presentationMode == RK1PSATPresentationModeAuditory) {
        versionTitle = RK1LocalizedString(@"PASAT_TITLE", nil);
        versionDetailText = RK1LocalizedString(@"PASAT_INTRO_TEXT", nil);
    } else if (presentationMode == RK1PSATPresentationModeVisual) {
        versionTitle = RK1LocalizedString(@"PVSAT_TITLE", nil);
        versionDetailText = RK1LocalizedString(@"PVSAT_INTRO_TEXT", nil);
    } else {
        versionTitle = RK1LocalizedString(@"PAVSAT_TITLE", nil);
        versionDetailText = RK1LocalizedString(@"PAVSAT_INTRO_TEXT", nil);
    }
    
    if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction0StepIdentifier];
            step.title = versionTitle;
            step.detailText = versionDetailText;
            step.text = intendedUseDescription;
            step.image = [UIImage imageNamed:@"phonepsat" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction1StepIdentifier];
            step.title = versionTitle;
            step.text = [NSString localizedStringWithFormat:RK1LocalizedString(@"PSAT_INTRO_TEXT_2_%@", nil), [NSNumberFormatter localizedStringFromNumber:@(interStimulusInterval) numberStyle:NSNumberFormatterDecimalStyle]];
            step.detailText = RK1LocalizedString(@"PSAT_CALL_TO_ACTION", nil);
            
            RK1StepArrayAddStep(steps, step);
        }
    }
    
    {
        RK1CountdownStep *step = [[RK1CountdownStep alloc] initWithIdentifier:RK1CountdownStepIdentifier];
        step.stepDuration = 5.0;
        
        RK1StepArrayAddStep(steps, step);
    }
    
    {
        RK1PSATStep *step = [[RK1PSATStep alloc] initWithIdentifier:RK1PSATStepIdentifier];
        step.title = RK1LocalizedString(@"PSAT_INITIAL_INSTRUCTION", nil);
        step.stepDuration = (seriesLength + 1) * interStimulusInterval;
        step.presentationMode = presentationMode;
        step.interStimulusInterval = interStimulusInterval;
        step.stimulusDuration = stimulusDuration;
        step.seriesLength = seriesLength;
        
        RK1StepArrayAddStep(steps, step);
    }
    
    if (!(options & RK1PredefinedTaskOptionExcludeConclusion)) {
        RK1InstructionStep *step = [self makeCompletionStep];
        
        RK1StepArrayAddStep(steps, step);
    }
    
    RK1OrderedTask *task = [[RK1OrderedTask alloc] initWithIdentifier:identifier steps:[steps copy]];
    
    return task;
}

+ (NSString *)stepIdentifier:(NSString *)stepIdentifier withHandIdentifier:(NSString *)handIdentifier {
    return [NSString stringWithFormat:@"%@.%@", stepIdentifier, handIdentifier];
}

+ (NSMutableArray *)stepsForOneHandTremorTestTaskWithIdentifier:(NSString *)identifier
                                             activeStepDuration:(NSTimeInterval)activeStepDuration
                                              activeTaskOptions:(RK1TremorActiveTaskOption)activeTaskOptions
                                                       lastHand:(BOOL)lastHand
                                                       leftHand:(BOOL)leftHand
                                                 handIdentifier:(NSString *)handIdentifier
                                                introDetailText:(NSString *)detailText
                                                        options:(RK1PredefinedTaskOption)options {
    NSMutableArray<RK1ActiveStep *> *steps = [NSMutableArray array];
    NSString *stepFinishedInstruction = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_FINISHED_INSTRUCTION", nil);
    BOOL rightHand = !leftHand && ![handIdentifier isEqualToString:RK1ActiveTaskMostAffectedHandIdentifier];
    
    {
        NSString *stepIdentifier = [self stepIdentifier:RK1Instruction1StepIdentifier withHandIdentifier:handIdentifier];
        RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:stepIdentifier];
        step.title = RK1LocalizedString(@"TREMOR_TEST_TITLE", nil);
        
        if ([identifier isEqualToString:RK1ActiveTaskMostAffectedHandIdentifier]) {
            step.text = RK1LocalizedString(@"TREMOR_TEST_INTRO_2_DEFAULT_TEXT", nil);
            step.detailText = detailText;
        } else {
            if (leftHand) {
                step.text = RK1LocalizedString(@"TREMOR_TEST_INTRO_2_LEFT_HAND_TEXT", nil);
            } else {
                step.text = RK1LocalizedString(@"TREMOR_TEST_INTRO_2_RIGHT_HAND_TEXT", nil);
            }
        }
        
        NSString *imageName = leftHand ? @"tremortestLeft" : @"tremortestRight";
        step.image = [UIImage imageNamed:imageName inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
        step.shouldTintImages = YES;
        
        RK1StepArrayAddStep(steps, step);
    }

    if (!(activeTaskOptions & RK1TremorActiveTaskOptionExcludeHandInLap)) {
        if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
            NSString *stepIdentifier = [self stepIdentifier:RK1Instruction2StepIdentifier withHandIdentifier:handIdentifier];
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:stepIdentifier];
            step.title = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_IN_LAP_INTRO", nil);
            step.text = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_INTRO_TEXT", nil);
            step.image = [UIImage imageNamed:@"tremortest3a" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.auxiliaryImage = [UIImage imageNamed:@"tremortest3b" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            if (leftHand) {
                step.title = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_IN_LAP_INTRO_LEFT", nil);
                step.image = [step.image ork_flippedImage:UIImageOrientationUpMirrored];
                step.auxiliaryImage = [step.auxiliaryImage ork_flippedImage:UIImageOrientationUpMirrored];
            } else if (rightHand) {
                step.title = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_IN_LAP_INTRO_RIGHT", nil);
            }
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
        
        {
            NSString *stepIdentifier = [self stepIdentifier:RK1Countdown1StepIdentifier withHandIdentifier:handIdentifier];
            RK1CountdownStep *step = [[RK1CountdownStep alloc] initWithIdentifier:stepIdentifier];
            
            RK1StepArrayAddStep(steps, step);
        }
        
        {
            NSString *titleFormat = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_IN_LAP_INSTRUCTION_%ld", nil);
            NSString *stepIdentifier = [self stepIdentifier:RK1TremorTestInLapStepIdentifier withHandIdentifier:handIdentifier];
            RK1ActiveStep *step = [[RK1ActiveStep alloc] initWithIdentifier:stepIdentifier];
            step.recorderConfigurations = @[[[RK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:@"ac1_acc" frequency:100.0], [[RK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:@"ac1_motion" frequency:100.0]];
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
            
            RK1StepArrayAddStep(steps, step);
        }
    }
    
    if (!(activeTaskOptions & RK1TremorActiveTaskOptionExcludeHandAtShoulderHeight)) {
        if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
            NSString *stepIdentifier = [self stepIdentifier:RK1Instruction4StepIdentifier withHandIdentifier:handIdentifier];
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:stepIdentifier];
            step.title = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_EXTEND_ARM_INTRO", nil);
            step.text = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_INTRO_TEXT", nil);
            step.image = [UIImage imageNamed:@"tremortest4a" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.auxiliaryImage = [UIImage imageNamed:@"tremortest4b" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            if (leftHand) {
                step.title = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_EXTEND_ARM_INTRO_LEFT", nil);
                step.image = [step.image ork_flippedImage:UIImageOrientationUpMirrored];
                step.auxiliaryImage = [step.auxiliaryImage ork_flippedImage:UIImageOrientationUpMirrored];
            } else if (rightHand) {
                step.title = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_EXTEND_ARM_INTRO_RIGHT", nil);
            }
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
        
        {
            NSString *stepIdentifier = [self stepIdentifier:RK1Countdown2StepIdentifier withHandIdentifier:handIdentifier];
            RK1CountdownStep *step = [[RK1CountdownStep alloc] initWithIdentifier:stepIdentifier];
            
            RK1StepArrayAddStep(steps, step);
        }
        
        {
            NSString *titleFormat = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_EXTEND_ARM_INSTRUCTION_%ld", nil);
            NSString *stepIdentifier = [self stepIdentifier:RK1TremorTestExtendArmStepIdentifier withHandIdentifier:handIdentifier];
            RK1ActiveStep *step = [[RK1ActiveStep alloc] initWithIdentifier:stepIdentifier];
            step.recorderConfigurations = @[[[RK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:@"ac2_acc" frequency:100.0], [[RK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:@"ac2_motion" frequency:100.0]];
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
            
            RK1StepArrayAddStep(steps, step);
        }
    }
    
    if (!(activeTaskOptions & RK1TremorActiveTaskOptionExcludeHandAtShoulderHeightElbowBent)) {
        if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
            NSString *stepIdentifier = [self stepIdentifier:RK1Instruction5StepIdentifier withHandIdentifier:handIdentifier];
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:stepIdentifier];
            step.title = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_BEND_ARM_INTRO", nil);
            step.text = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_INTRO_TEXT", nil);
            step.image = [UIImage imageNamed:@"tremortest5a" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.auxiliaryImage = [UIImage imageNamed:@"tremortest5b" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            if (leftHand) {
                step.title = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_BEND_ARM_INTRO_LEFT", nil);
                step.image = [step.image ork_flippedImage:UIImageOrientationUpMirrored];
                step.auxiliaryImage = [step.auxiliaryImage ork_flippedImage:UIImageOrientationUpMirrored];
            } else if (rightHand) {
                step.title = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_BEND_ARM_INTRO_RIGHT", nil);
            }
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
        
        {
            NSString *stepIdentifier = [self stepIdentifier:RK1Countdown3StepIdentifier withHandIdentifier:handIdentifier];
            RK1CountdownStep *step = [[RK1CountdownStep alloc] initWithIdentifier:stepIdentifier];
            
            RK1StepArrayAddStep(steps, step);
        }
        
        {
            NSString *titleFormat = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_BEND_ARM_INSTRUCTION_%ld", nil);
            NSString *stepIdentifier = [self stepIdentifier:RK1TremorTestBendArmStepIdentifier withHandIdentifier:handIdentifier];
            RK1ActiveStep *step = [[RK1ActiveStep alloc] initWithIdentifier:stepIdentifier];
            step.recorderConfigurations = @[[[RK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:@"ac3_acc" frequency:100.0], [[RK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:@"ac3_motion" frequency:100.0]];
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
            
            RK1StepArrayAddStep(steps, step);
        }
    }
    
    if (!(activeTaskOptions & RK1TremorActiveTaskOptionExcludeHandToNose)) {
        if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
            NSString *stepIdentifier = [self stepIdentifier:RK1Instruction6StepIdentifier withHandIdentifier:handIdentifier];
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:stepIdentifier];
            step.title = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_TOUCH_NOSE_INTRO", nil);
            step.text = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_INTRO_TEXT", nil);
            step.image = [UIImage imageNamed:@"tremortest6a" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.auxiliaryImage = [UIImage imageNamed:@"tremortest6b" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            if (leftHand) {
                step.title = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_TOUCH_NOSE_INTRO_LEFT", nil);
                step.image = [step.image ork_flippedImage:UIImageOrientationUpMirrored];
                step.auxiliaryImage = [step.auxiliaryImage ork_flippedImage:UIImageOrientationUpMirrored];
            } else if (rightHand) {
                step.title = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_TOUCH_NOSE_INTRO_RIGHT", nil);
            }
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
        
        {
            NSString *stepIdentifier = [self stepIdentifier:RK1Countdown4StepIdentifier withHandIdentifier:handIdentifier];
            RK1CountdownStep *step = [[RK1CountdownStep alloc] initWithIdentifier:stepIdentifier];
            
            RK1StepArrayAddStep(steps, step);
        }
        
        {
            NSString *titleFormat = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_TOUCH_NOSE_INSTRUCTION_%ld", nil);
            NSString *stepIdentifier = [self stepIdentifier:RK1TremorTestTouchNoseStepIdentifier withHandIdentifier:handIdentifier];
            RK1ActiveStep *step = [[RK1ActiveStep alloc] initWithIdentifier:stepIdentifier];
            step.recorderConfigurations = @[[[RK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:@"ac4_acc" frequency:100.0], [[RK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:@"ac4_motion" frequency:100.0]];
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
            
            RK1StepArrayAddStep(steps, step);
        }
    }
    
    if (!(activeTaskOptions & RK1TremorActiveTaskOptionExcludeQueenWave)) {
        if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
            NSString *stepIdentifier = [self stepIdentifier:RK1Instruction7StepIdentifier withHandIdentifier:handIdentifier];
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:stepIdentifier];
            step.title = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_TURN_WRIST_INTRO", nil);
            step.text = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_INTRO_TEXT", nil);
            step.image = [UIImage imageNamed:@"tremortest7" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            if (leftHand) {
                step.title = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_TURN_WRIST_INTRO_LEFT", nil);
                step.image = [step.image ork_flippedImage:UIImageOrientationUpMirrored];
            } else if (rightHand) {
                step.title = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_TURN_WRIST_INTRO_RIGHT", nil);
            }
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
        
        {
            NSString *stepIdentifier = [self stepIdentifier:RK1Countdown5StepIdentifier withHandIdentifier:handIdentifier];
            RK1CountdownStep *step = [[RK1CountdownStep alloc] initWithIdentifier:stepIdentifier];
            
            RK1StepArrayAddStep(steps, step);
        }
        
        {
            NSString *titleFormat = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_TURN_WRIST_INSTRUCTION_%ld", nil);
            NSString *stepIdentifier = [self stepIdentifier:RK1TremorTestTurnWristStepIdentifier withHandIdentifier:handIdentifier];
            RK1ActiveStep *step = [[RK1ActiveStep alloc] initWithIdentifier:stepIdentifier];
            step.recorderConfigurations = @[[[RK1AccelerometerRecorderConfiguration alloc] initWithIdentifier:@"ac5_acc" frequency:100.0], [[RK1DeviceMotionRecorderConfiguration alloc] initWithIdentifier:@"ac5_motion" frequency:100.0]];
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
            
            RK1StepArrayAddStep(steps, step);
        }
    }
    
    // fix the spoken instruction on the last included step, depending on which hand we're on
    RK1ActiveStep *lastStep = (RK1ActiveStep *)[steps lastObject];
    if (lastHand) {
        lastStep.finishedSpokenInstruction = RK1LocalizedString(@"TREMOR_TEST_COMPLETED_INSTRUCTION", nil);
    } else if (leftHand) {
        lastStep.finishedSpokenInstruction = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_SWITCH_HANDS_RIGHT_INSTRUCTION", nil);
    } else {
        lastStep.finishedSpokenInstruction = RK1LocalizedString(@"TREMOR_TEST_ACTIVE_STEP_SWITCH_HANDS_LEFT_INSTRUCTION", nil);
    }
    
    return steps;
}

+ (RK1NavigableOrderedTask *)tremorTestTaskWithIdentifier:(NSString *)identifier
                                   intendedUseDescription:(nullable NSString *)intendedUseDescription
                                       activeStepDuration:(NSTimeInterval)activeStepDuration
                                        activeTaskOptions:(RK1TremorActiveTaskOption)activeTaskOptions
                                              handOptions:(RK1PredefinedTaskHandOption)handOptions
                                                  options:(RK1PredefinedTaskOption)options {
    
    NSMutableArray<__kindof RK1Step *> *steps = [NSMutableArray array];
    // coin toss for which hand first (in case we're doing both)
    BOOL leftFirstIfDoingBoth = arc4random_uniform(2) == 1;
    BOOL doingBoth = ((handOptions & RK1PredefinedTaskHandOptionLeft) && (handOptions & RK1PredefinedTaskHandOptionRight));
    BOOL firstIsLeft = (leftFirstIfDoingBoth && doingBoth) || (!doingBoth && (handOptions & RK1PredefinedTaskHandOptionLeft));
    
    if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction0StepIdentifier];
            step.title = RK1LocalizedString(@"TREMOR_TEST_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = RK1LocalizedString(@"TREMOR_TEST_INTRO_1_DETAIL", nil);
            step.image = [UIImage imageNamed:@"tremortest1" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            if (firstIsLeft) {
                step.image = [step.image ork_flippedImage:UIImageOrientationUpMirrored];
            }
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
    }
    
    // Build the string for the detail texts
    NSArray<NSString *>*detailStringForNumberOfTasks = @[
                                                         RK1LocalizedString(@"TREMOR_TEST_INTRO_2_DETAIL_1_TASK", nil),
                                                         RK1LocalizedString(@"TREMOR_TEST_INTRO_2_DETAIL_2_TASK", nil),
                                                         RK1LocalizedString(@"TREMOR_TEST_INTRO_2_DETAIL_3_TASK", nil),
                                                         RK1LocalizedString(@"TREMOR_TEST_INTRO_2_DETAIL_4_TASK", nil),
                                                         RK1LocalizedString(@"TREMOR_TEST_INTRO_2_DETAIL_5_TASK", nil)
                                                         ];
    
    // start with the count for all the tasks, then subtract one for each excluded task flag
    static const NSInteger allTasks = 5; // hold in lap, outstretched arm, elbow bent, repeatedly touching nose, queen wave
    NSInteger actualTasksIndex = allTasks - 1;
    for (NSInteger i = 0; i < allTasks; ++i) {
        if (activeTaskOptions & (1 << i)) {
            actualTasksIndex--;
        }
    }
    
    NSString *detailFormat = doingBoth ? RK1LocalizedString(@"TREMOR_TEST_SKIP_QUESTION_BOTH_HANDS_%@", nil) : RK1LocalizedString(@"TREMOR_TEST_INTRO_2_DETAIL_DEFAULT_%@", nil);
    NSString *detailText = [NSString localizedStringWithFormat:detailFormat, detailStringForNumberOfTasks[actualTasksIndex]];
    
    if (doingBoth) {
        // If doing both hands then ask the user if they need to skip one of the hands
        RK1TextChoice *skipRight = [RK1TextChoice choiceWithText:RK1LocalizedString(@"TREMOR_SKIP_RIGHT_HAND", nil)
                                                          value:RK1ActiveTaskRightHandIdentifier];
        RK1TextChoice *skipLeft = [RK1TextChoice choiceWithText:RK1LocalizedString(@"TREMOR_SKIP_LEFT_HAND", nil)
                                                          value:RK1ActiveTaskLeftHandIdentifier];
        RK1TextChoice *skipNeither = [RK1TextChoice choiceWithText:RK1LocalizedString(@"TREMOR_SKIP_NEITHER", nil)
                                                             value:@""];

        RK1AnswerFormat *answerFormat = [RK1AnswerFormat choiceAnswerFormatWithStyle:RK1ChoiceAnswerStyleSingleChoice
                                                                         textChoices:@[skipRight, skipLeft, skipNeither]];
        RK1QuestionStep *step = [RK1QuestionStep questionStepWithIdentifier:RK1ActiveTaskSkipHandStepIdentifier
                                                                      title:RK1LocalizedString(@"TREMOR_TEST_TITLE", nil)
                                                                       text:detailText
                                                                     answer:answerFormat];
        step.optional = NO;
        
        RK1StepArrayAddStep(steps, step);
    }
    
    // right or most-affected hand
    NSArray<__kindof RK1Step *> *rightSteps = nil;
    if (handOptions == RK1PredefinedTaskHandOptionUnspecified) {
        rightSteps = [self stepsForOneHandTremorTestTaskWithIdentifier:identifier
                                                    activeStepDuration:activeStepDuration
                                                     activeTaskOptions:activeTaskOptions
                                                              lastHand:YES
                                                              leftHand:NO
                                                        handIdentifier:RK1ActiveTaskMostAffectedHandIdentifier
                                                       introDetailText:detailText
                                                               options:options];
    } else if (handOptions & RK1PredefinedTaskHandOptionRight) {
        rightSteps = [self stepsForOneHandTremorTestTaskWithIdentifier:identifier
                                                    activeStepDuration:activeStepDuration
                                                     activeTaskOptions:activeTaskOptions
                                                              lastHand:firstIsLeft
                                                              leftHand:NO
                                                        handIdentifier:RK1ActiveTaskRightHandIdentifier
                                                       introDetailText:nil
                                                               options:options];
    }
    
    // left hand
    NSArray<__kindof RK1Step *> *leftSteps = nil;
    if (handOptions & RK1PredefinedTaskHandOptionLeft) {
        leftSteps = [self stepsForOneHandTremorTestTaskWithIdentifier:identifier
                                                   activeStepDuration:activeStepDuration
                                                    activeTaskOptions:activeTaskOptions
                                                             lastHand:!firstIsLeft || !(handOptions & RK1PredefinedTaskHandOptionRight)
                                                             leftHand:YES
                                                       handIdentifier:RK1ActiveTaskLeftHandIdentifier
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
    if (!(options & RK1PredefinedTaskOptionExcludeConclusion)) {
        hasCompletionStep = YES;
        RK1CompletionStep *step = [self makeCompletionStep];
        
        RK1StepArrayAddStep(steps, step);
    }

    RK1NavigableOrderedTask *task = [[RK1NavigableOrderedTask alloc] initWithIdentifier:identifier steps:steps];
    
    if (doingBoth) {
        // Setup rules for skipping all the steps in either the left or right hand if called upon to do so.
        RK1ResultSelector *resultSelector = [RK1ResultSelector selectorWithStepIdentifier:RK1ActiveTaskSkipHandStepIdentifier
                                                                         resultIdentifier:RK1ActiveTaskSkipHandStepIdentifier];
        NSPredicate *predicateRight = [RK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector expectedAnswerValue:RK1ActiveTaskRightHandIdentifier];
        NSPredicate *predicateLeft = [RK1ResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector expectedAnswerValue:RK1ActiveTaskLeftHandIdentifier];
        
        // Setup rule for skipping first hand
        NSString *secondHandIdentifier = firstIsLeft ? [[rightSteps firstObject] identifier] : [[leftSteps firstObject] identifier];
        NSPredicate *firstPredicate = firstIsLeft ? predicateLeft : predicateRight;
        RK1StepNavigationRule *skipFirst = [[RK1PredicateStepNavigationRule alloc] initWithResultPredicates:@[firstPredicate]
                                                                                 destinationStepIdentifiers:@[secondHandIdentifier]];
        [task setNavigationRule:skipFirst forTriggerStepIdentifier:RK1ActiveTaskSkipHandStepIdentifier];
        
        // Setup rule for skipping the second hand
        NSString *triggerIdentifier = firstIsLeft ? [[leftSteps lastObject] identifier] : [[rightSteps lastObject] identifier];
        NSString *conclusionIdentifier = hasCompletionStep ? [[steps lastObject] identifier] : RK1NullStepIdentifier;
        NSPredicate *secondPredicate = firstIsLeft ? predicateRight : predicateLeft;
        RK1StepNavigationRule *skipSecond = [[RK1PredicateStepNavigationRule alloc] initWithResultPredicates:@[secondPredicate]
                                                                                  destinationStepIdentifiers:@[conclusionIdentifier]];
        [task setNavigationRule:skipSecond forTriggerStepIdentifier:triggerIdentifier];
        
        // Setup step modifier to change the finished spoken step if skipping the second hand
        NSString *key = NSStringFromSelector(@selector(finishedSpokenInstruction));
        NSString *value = RK1LocalizedString(@"TREMOR_TEST_COMPLETED_INSTRUCTION", nil);
        RK1StepModifier *stepModifier = [[RK1KeyValueStepModifier alloc] initWithResultPredicate:secondPredicate
                                                                                     keyValueMap:@{key: value}];
        [task setStepModifier:stepModifier forStepIdentifier:triggerIdentifier];
    }
    
    return task;
}

+ (RK1OrderedTask *)trailmakingTaskWithIdentifier:(NSString *)identifier
                           intendedUseDescription:(nullable NSString *)intendedUseDescription
                           trailmakingInstruction:(nullable NSString *)trailmakingInstruction
                                        trailType:(RK1TrailMakingTypeIdentifier)trailType
                                          options:(RK1PredefinedTaskOption)options {
    
    NSArray *supportedTypes = @[RK1TrailMakingTypeIdentifierA, RK1TrailMakingTypeIdentifierB];
    NSAssert1([supportedTypes containsObject:trailType], @"Trail type %@ is not supported.", trailType);
    
    NSMutableArray<__kindof RK1Step *> *steps = [NSMutableArray array];
    
    if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction0StepIdentifier];
            step.title = RK1LocalizedString(@"TRAILMAKING_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = RK1LocalizedString(@"TRAILMAKING_INTENDED_USE", nil);
            step.image = [UIImage imageNamed:@"trailmaking" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
        
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction1StepIdentifier];
            step.title = RK1LocalizedString(@"TRAILMAKING_TASK_TITLE", nil);
            if ([trailType isEqualToString:RK1TrailMakingTypeIdentifierA]) {
                step.detailText = RK1LocalizedString(@"TRAILMAKING_INTENDED_USE2_A", nil);
            } else {
                step.detailText = RK1LocalizedString(@"TRAILMAKING_INTENDED_USE2_B", nil);
            }
            step.image = [UIImage imageNamed:@"trailmaking" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
        
        
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction2StepIdentifier];
            step.title = RK1LocalizedString(@"TRAILMAKING_TASK_TITLE", nil);
            step.text = trailmakingInstruction ? : RK1LocalizedString(@"TRAILMAKING_INTRO_TEXT",nil);
            step.detailText = RK1LocalizedString(@"TRAILMAKING_CALL_TO_ACTION", nil);
            step.image = [UIImage imageNamed:@"trailmaking" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
    }
    
    {
        RK1CountdownStep *step = [[RK1CountdownStep alloc] initWithIdentifier:RK1CountdownStepIdentifier];
        step.stepDuration = 3.0;
        
        RK1StepArrayAddStep(steps, step);
    }
    
    {
        RK1TrailmakingStep *step = [[RK1TrailmakingStep alloc] initWithIdentifier:RK1TrailmakingStepIdentifier];
        step.trailType = trailType;
        
        RK1StepArrayAddStep(steps, step);
    }
    
    if (!(options & RK1PredefinedTaskOptionExcludeConclusion)) {
        RK1InstructionStep *step = [self makeCompletionStep];
        
        RK1StepArrayAddStep(steps, step);
    }

    
    RK1OrderedTask *task = [[RK1OrderedTask alloc] initWithIdentifier:identifier steps:steps];
    
    return task;
}

@end
