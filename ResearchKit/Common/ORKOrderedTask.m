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

ORKLegacyTrailMakingTypeIdentifier const ORKLegacyTrailMakingTypeIdentifierA = @"A";
ORKLegacyTrailMakingTypeIdentifier const ORKLegacyTrailMakingTypeIdentifierB = @"B";


ORKLegacyTaskProgress ORKLegacyTaskProgressMake(NSUInteger current, NSUInteger total) {
    return (ORKLegacyTaskProgress){.current=current, .total=total};
}


@implementation ORKLegacyOrderedTask {
    NSString *_identifier;
}

@synthesize cev_theme = _cev_theme;

+ (instancetype)new {
    ORKLegacyThrowMethodUnavailableException();
}

- (instancetype)init {
    ORKLegacyThrowMethodUnavailableException();
}

- (instancetype)initWithIdentifier:(NSString *)identifier steps:(NSArray<ORKLegacyStep *> *)steps {
    self = [super init];
    if (self) {
        ORKLegacyThrowInvalidArgumentExceptionIfNil(identifier);
        
        _identifier = [identifier copy];
        _steps = steps;
        
        [self validateParameters];
    }
    return self;
}

- (instancetype)copyWithSteps:(NSArray <ORKLegacyStep *> *)steps {
    ORKLegacyOrderedTask *task = [self copyWithZone:nil];
    task->_steps = ORKLegacyArrayCopyObjects(steps);
    return task;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLegacyOrderedTask *task = [[[self class] allocWithZone:zone] initWithIdentifier:[_identifier copy]
                                                                           steps:ORKLegacyArrayCopyObjects(_steps)];
    return task;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return (ORKLegacyEqualObjects(self.identifier, castObject.identifier)
            && ORKLegacyEqualObjects(self.steps, castObject.steps));
}

- (NSUInteger)hash {
    return _identifier.hash ^ _steps.hash;
}

#pragma mark - ORKLegacyTask

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

- (NSUInteger)indexOfStep:(ORKLegacyStep *)step {
    NSUInteger index = [_steps indexOfObject:step];
    if (index == NSNotFound) {
        NSArray *identifiers = [_steps valueForKey:@"identifier"];
        index = [identifiers indexOfObject:step.identifier];
    }
    return index;
}

- (ORKLegacyStep *)stepAfterStep:(ORKLegacyStep *)step withResult:(ORKLegacyTaskResult *)result {
    NSArray *steps = _steps;
    
    if (steps.count <= 0) {
        return nil;
    }
    
    ORKLegacyStep *currentStep = step;
    ORKLegacyStep *nextStep = nil;
    
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

- (ORKLegacyStep *)stepBeforeStep:(ORKLegacyStep *)step withResult:(ORKLegacyTaskResult *)result {
    NSArray *steps = _steps;
    
    if (steps.count <= 0) {
        return nil;
    }
    
    ORKLegacyStep *currentStep = step;
    ORKLegacyStep *nextStep = nil;
    
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

- (ORKLegacyStep *)stepWithIdentifier:(NSString *)identifier {
    __block ORKLegacyStep *step = nil;
    [_steps enumerateObjectsUsingBlock:^(ORKLegacyStep *obj, NSUInteger idx, BOOL *stop) {
        if ([obj.identifier isEqualToString:identifier]) {
            step = obj;
            *stop = YES;
        }
    }];
    return step;
}

- (ORKLegacyTaskProgress)progressOfCurrentStep:(ORKLegacyStep *)step withResult:(ORKLegacyTaskResult *)taskResult {
    ORKLegacyTaskProgress progress;
    progress.current = [self indexOfStep:step];
    progress.total = _steps.count;
    
    if (![step showsProgress]) {
        progress.total = 0;
    }
    return progress;
}

- (NSSet *)requestedHealthKitTypesForReading {
    NSMutableSet *healthTypes = [NSMutableSet set];
    for (ORKLegacyStep *step in self.steps) {
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

- (ORKLegacyPermissionMask)requestedPermissions {
    ORKLegacyPermissionMask mask = ORKLegacyPermissionNone;
    for (ORKLegacyStep *step in self.steps) {
        mask |= [step requestedPermissions];
    }
    return mask;
}

- (BOOL)providesBackgroundAudioPrompts {
    BOOL providesAudioPrompts = NO;
    for (ORKLegacyStep *step in self.steps) {
        if ([step isKindOfClass:[ORKLegacyActiveStep class]]) {
            ORKLegacyActiveStep *activeStep = (ORKLegacyActiveStep *)step;
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
    ORKLegacy_ENCODE_OBJ(aCoder, identifier);
    ORKLegacy_ENCODE_OBJ(aCoder, steps);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        ORKLegacy_DECODE_OBJ_CLASS(aDecoder, identifier, NSString);
        ORKLegacy_DECODE_OBJ_ARRAY(aDecoder, steps, ORKLegacyStep);
        
        for (ORKLegacyStep *step in _steps) {
            if ([step isKindOfClass:[ORKLegacyStep class]]) {
                [step setTask:self];
            }
        }
    }
    return self;
}

#pragma mark - Predefined

NSString *const ORKLegacyInstruction0StepIdentifier = @"instruction";
NSString *const ORKLegacyInstruction1StepIdentifier = @"instruction1";
NSString *const ORKLegacyInstruction2StepIdentifier = @"instruction2";
NSString *const ORKLegacyInstruction3StepIdentifier = @"instruction3";
NSString *const ORKLegacyInstruction4StepIdentifier = @"instruction4";
NSString *const ORKLegacyInstruction5StepIdentifier = @"instruction5";
NSString *const ORKLegacyInstruction6StepIdentifier = @"instruction6";
NSString *const ORKLegacyInstruction7StepIdentifier = @"instruction7";
NSString *const ORKLegacyCountdownStepIdentifier = @"countdown";
NSString *const ORKLegacyCountdown1StepIdentifier = @"countdown1";
NSString *const ORKLegacyCountdown2StepIdentifier = @"countdown2";
NSString *const ORKLegacyCountdown3StepIdentifier = @"countdown3";
NSString *const ORKLegacyCountdown4StepIdentifier = @"countdown4";
NSString *const ORKLegacyCountdown5StepIdentifier = @"countdown5";
NSString *const ORKLegacyTouchAnywhereStepIdentifier = @"touch.anywhere";
NSString *const ORKLegacyAudioStepIdentifier = @"audio";
NSString *const ORKLegacyAudioTooLoudStepIdentifier = @"audio.tooloud";
NSString *const ORKLegacyTappingStepIdentifier = @"tapping";
NSString *const ORKLegacyActiveTaskLeftHandIdentifier = @"left";
NSString *const ORKLegacyActiveTaskRightHandIdentifier = @"right";
NSString *const ORKLegacyActiveTaskSkipHandStepIdentifier = @"skipHand";
NSString *const ORKLegacyConclusionStepIdentifier = @"conclusion";
NSString *const ORKLegacyFitnessWalkStepIdentifier = @"fitness.walk";
NSString *const ORKLegacyFitnessRestStepIdentifier = @"fitness.rest";
NSString *const ORKLegacyKneeRangeOfMotionStepIdentifier = @"knee.range.of.motion";
NSString *const ORKLegacyShoulderRangeOfMotionStepIdentifier = @"shoulder.range.of.motion";
NSString *const ORKLegacyShortWalkOutboundStepIdentifier = @"walking.outbound";
NSString *const ORKLegacyShortWalkReturnStepIdentifier = @"walking.return";
NSString *const ORKLegacyShortWalkRestStepIdentifier = @"walking.rest";
NSString *const ORKLegacySpatialSpanMemoryStepIdentifier = @"cognitive.memory.spatialspan";
NSString *const ORKLegacyStroopStepIdentifier = @"stroop";
NSString *const ORKLegacyToneAudiometryPracticeStepIdentifier = @"tone.audiometry.practice";
NSString *const ORKLegacyToneAudiometryStepIdentifier = @"tone.audiometry";
NSString *const ORKLegacyReactionTimeStepIdentifier = @"reactionTime";
NSString *const ORKLegacyTowerOfHanoiStepIdentifier = @"towerOfHanoi";
NSString *const ORKLegacyTimedWalkFormStepIdentifier = @"timed.walk.form";
NSString *const ORKLegacyTimedWalkFormAFOStepIdentifier = @"timed.walk.form.afo";
NSString *const ORKLegacyTimedWalkFormAssistanceStepIdentifier = @"timed.walk.form.assistance";
NSString *const ORKLegacyTimedWalkTrial1StepIdentifier = @"timed.walk.trial1";
NSString *const ORKLegacyTimedWalkTurnAroundStepIdentifier = @"timed.walk.turn.around";
NSString *const ORKLegacyTimedWalkTrial2StepIdentifier = @"timed.walk.trial2";
NSString *const ORKLegacyTremorTestInLapStepIdentifier = @"tremor.handInLap";
NSString *const ORKLegacyTremorTestExtendArmStepIdentifier = @"tremor.handAtShoulderLength";
NSString *const ORKLegacyTremorTestBendArmStepIdentifier = @"tremor.handAtShoulderLengthWithElbowBent";
NSString *const ORKLegacyTremorTestTouchNoseStepIdentifier = @"tremor.handToNose";
NSString *const ORKLegacyTremorTestTurnWristStepIdentifier = @"tremor.handQueenWave";
NSString *const ORKLegacyTrailmakingStepIdentifier = @"trailmaking";
NSString *const ORKLegacyActiveTaskMostAffectedHandIdentifier = @"mostAffected";
NSString *const ORKLegacyPSATStepIdentifier = @"psat";
NSString *const ORKLegacyAudioRecorderIdentifier = @"audio";
NSString *const ORKLegacyAccelerometerRecorderIdentifier = @"accelerometer";
NSString *const ORKLegacyPedometerRecorderIdentifier = @"pedometer";
NSString *const ORKLegacyDeviceMotionRecorderIdentifier = @"deviceMotion";
NSString *const ORKLegacyLocationRecorderIdentifier = @"location";
NSString *const ORKLegacyHeartRateRecorderIdentifier = @"heartRate";

+ (ORKLegacyCompletionStep *)makeCompletionStep {
    ORKLegacyCompletionStep *step = [[ORKLegacyCompletionStep alloc] initWithIdentifier:ORKLegacyConclusionStepIdentifier];
    step.title = ORKLegacyLocalizedString(@"TASK_COMPLETE_TITLE", nil);
    step.text = ORKLegacyLocalizedString(@"TASK_COMPLETE_TEXT", nil);
    step.shouldTintImages = YES;
    return step;
}

void ORKLegacyStepArrayAddStep(NSMutableArray *array, ORKLegacyStep *step) {
    [step validateParameters];
    [array addObject:step];
}

+ (ORKLegacyOrderedTask *)twoFingerTappingIntervalTaskWithIdentifier:(NSString *)identifier
                                       intendedUseDescription:(NSString *)intendedUseDescription
                                                     duration:(NSTimeInterval)duration
                                                      options:(ORKLegacyPredefinedTaskOption)options {
    return [self twoFingerTappingIntervalTaskWithIdentifier:identifier
                                     intendedUseDescription:intendedUseDescription
                                                   duration:duration
                                                handOptions:0
                                                    options:options];
}
    
+ (ORKLegacyOrderedTask *)twoFingerTappingIntervalTaskWithIdentifier:(NSString *)identifier
                                        intendedUseDescription:(NSString *)intendedUseDescription
                                                      duration:(NSTimeInterval)duration
                                                   handOptions:(ORKLegacyPredefinedTaskHandOption)handOptions
                                                       options:(ORKLegacyPredefinedTaskOption)options {
    
    NSString *durationString = [ORKLegacyDurationStringFormatter() stringFromTimeInterval:duration];
    
    NSMutableArray *steps = [NSMutableArray array];
    
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction0StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"TAPPING_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = ORKLegacyLocalizedString(@"TAPPING_INTRO_TEXT", nil);
            
            NSString *imageName = @"phonetapping";
            if (![[NSLocale preferredLanguages].firstObject hasPrefix:@"en"]) {
                imageName = [imageName stringByAppendingString:@"_notap"];
            }
            step.image = [UIImage imageNamed:imageName inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
    }
    
    // Setup which hand to start with and how many hands to add based on the handOptions parameter
    // Hand order is randomly determined.
    NSUInteger handCount = ((handOptions & ORKLegacyPredefinedTaskHandOptionBoth) == ORKLegacyPredefinedTaskHandOptionBoth) ? 2 : 1;
    BOOL undefinedHand = (handOptions == 0);
    BOOL rightHand;
    switch (handOptions) {
        case ORKLegacyPredefinedTaskHandOptionLeft:
            rightHand = NO; break;
        case ORKLegacyPredefinedTaskHandOptionRight:
        case ORKLegacyPredefinedTaskHandOptionUnspecified:
            rightHand = YES; break;
        default:
            rightHand = (arc4random()%2 == 0); break;
        }
        
    for (NSUInteger hand = 1; hand <= handCount; hand++) {
        
        NSString * (^appendIdentifier) (NSString *) = ^ (NSString * identifier) {
            if (undefinedHand) {
                return identifier;
            } else {
                NSString *handIdentifier = rightHand ? ORKLegacyActiveTaskRightHandIdentifier : ORKLegacyActiveTaskLeftHandIdentifier;
                return [NSString stringWithFormat:@"%@.%@", identifier, handIdentifier];
            }
        };
        
        if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:appendIdentifier(ORKLegacyInstruction1StepIdentifier)];
            
            // Set the title based on the hand
            if (undefinedHand) {
                step.title = ORKLegacyLocalizedString(@"TAPPING_TASK_TITLE", nil);
            } else if (rightHand) {
                step.title = ORKLegacyLocalizedString(@"TAPPING_TASK_TITLE_RIGHT", nil);
            } else {
                step.title = ORKLegacyLocalizedString(@"TAPPING_TASK_TITLE_LEFT", nil);
            }
            
            // Set the instructions for the tapping test screen that is displayed prior to each hand test
            NSString *restText = ORKLegacyLocalizedString(@"TAPPING_INTRO_TEXT_2_REST_PHONE", nil);
            NSString *tappingTextFormat = ORKLegacyLocalizedString(@"TAPPING_INTRO_TEXT_2_FORMAT", nil);
            NSString *tappingText = [NSString localizedStringWithFormat:tappingTextFormat, durationString];
            NSString *handText = nil;
            
            if (hand == 1) {
                if (undefinedHand) {
                    handText = ORKLegacyLocalizedString(@"TAPPING_INTRO_TEXT_2_MOST_AFFECTED", nil);
                } else if (rightHand) {
                    handText = ORKLegacyLocalizedString(@"TAPPING_INTRO_TEXT_2_RIGHT_FIRST", nil);
                } else {
                    handText = ORKLegacyLocalizedString(@"TAPPING_INTRO_TEXT_2_LEFT_FIRST", nil);
                }
            } else {
                if (rightHand) {
                    handText = ORKLegacyLocalizedString(@"TAPPING_INTRO_TEXT_2_RIGHT_SECOND", nil);
                } else {
                    handText = ORKLegacyLocalizedString(@"TAPPING_INTRO_TEXT_2_LEFT_SECOND", nil);
                }
            }
            
            step.text = [NSString localizedStringWithFormat:@"%@ %@ %@", restText, handText, tappingText];
            
            // Continue button will be different from first hand and second hand
            if (hand == 1) {
                step.detailText = ORKLegacyLocalizedString(@"TAPPING_CALL_TO_ACTION", nil);
            } else {
                step.detailText = ORKLegacyLocalizedString(@"TAPPING_CALL_TO_ACTION_NEXT", nil);
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
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
    
        // TAPPING STEP
    {
        NSMutableArray *recorderConfigurations = [NSMutableArray arrayWithCapacity:5];
        if (!(ORKLegacyPredefinedTaskOptionExcludeAccelerometer & options)) {
            [recorderConfigurations addObject:[[ORKLegacyAccelerometerRecorderConfiguration alloc] initWithIdentifier:ORKLegacyAccelerometerRecorderIdentifier
                                                                                                      frequency:100]];
        }
        
            ORKLegacyTappingIntervalStep *step = [[ORKLegacyTappingIntervalStep alloc] initWithIdentifier:appendIdentifier(ORKLegacyTappingStepIdentifier)];
            if (undefinedHand) {
                step.title = ORKLegacyLocalizedString(@"TAPPING_INSTRUCTION", nil);
            } else if (rightHand) {
                step.title = ORKLegacyLocalizedString(@"TAPPING_INSTRUCTION_RIGHT", nil);
            } else {
                step.title = ORKLegacyLocalizedString(@"TAPPING_INSTRUCTION_LEFT", nil);
            }
            step.stepDuration = duration;
            step.shouldContinueOnFinish = YES;
            step.recorderConfigurations = recorderConfigurations;
            step.optional = (handCount == 2);
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        // Flip to the other hand (ignored if handCount == 1)
        rightHand = !rightHand;
    }
    
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeConclusion)) {
        ORKLegacyInstructionStep *step = [self makeCompletionStep];
        
        ORKLegacyStepArrayAddStep(steps, step);
    }
    
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:identifier steps:[steps copy]];
    
    return task;
}

+ (ORKLegacyOrderedTask *)audioTaskWithIdentifier:(NSString *)identifier
                     intendedUseDescription:(NSString *)intendedUseDescription
                          speechInstruction:(NSString *)speechInstruction
                     shortSpeechInstruction:(NSString *)shortSpeechInstruction
                                   duration:(NSTimeInterval)duration
                          recordingSettings:(NSDictionary *)recordingSettings
                                    options:(ORKLegacyPredefinedTaskOption)options {
    
    return [self audioTaskWithIdentifier:identifier
                  intendedUseDescription:intendedUseDescription
                       speechInstruction:speechInstruction
                  shortSpeechInstruction:shortSpeechInstruction
                                duration:duration
                       recordingSettings:recordingSettings
                         checkAudioLevel:NO
                                 options:options];
}

+ (ORKLegacyNavigableOrderedTask *)audioTaskWithIdentifier:(NSString *)identifier
                              intendedUseDescription:(nullable NSString *)intendedUseDescription
                                   speechInstruction:(nullable NSString *)speechInstruction
                              shortSpeechInstruction:(nullable NSString *)shortSpeechInstruction
                                            duration:(NSTimeInterval)duration
                                   recordingSettings:(nullable NSDictionary *)recordingSettings
                                     checkAudioLevel:(BOOL)checkAudioLevel
                                             options:(ORKLegacyPredefinedTaskOption)options {

    recordingSettings = recordingSettings ? : @{ AVFormatIDKey : @(kAudioFormatAppleLossless),
                                                 AVNumberOfChannelsKey : @(2),
                                                AVSampleRateKey: @(44100.0) };
    
    if (options & ORKLegacyPredefinedTaskOptionExcludeAudio) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"Audio collection cannot be excluded from audio task" userInfo:nil];
    }
    
    NSMutableArray *steps = [NSMutableArray array];
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction0StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"AUDIO_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = ORKLegacyLocalizedString(@"AUDIO_INTENDED_USE", nil);
            step.image = [UIImage imageNamed:@"phonewaves" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction1StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"AUDIO_TASK_TITLE", nil);
            step.text = speechInstruction ? : ORKLegacyLocalizedString(@"AUDIO_INTRO_TEXT",nil);
            step.detailText = ORKLegacyLocalizedString(@"AUDIO_CALL_TO_ACTION", nil);
            step.image = [UIImage imageNamed:@"phonesoundwaves" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
    }

    {
        ORKLegacyCountdownStep *step = [[ORKLegacyCountdownStep alloc] initWithIdentifier:ORKLegacyCountdownStepIdentifier];
        step.stepDuration = 5.0;
        
        // Collect audio during the countdown step too, to provide a baseline.
        step.recorderConfigurations = @[[[ORKLegacyAudioRecorderConfiguration alloc] initWithIdentifier:ORKLegacyAudioRecorderIdentifier
                                                                                 recorderSettings:recordingSettings]];
        
        // If checking the sound level then add text indicating that's what is happening
        if (checkAudioLevel) {
            step.text = ORKLegacyLocalizedString(@"AUDIO_LEVEL_CHECK_LABEL", nil);
        }
        
        ORKLegacyStepArrayAddStep(steps, step);
    }
    
    if (checkAudioLevel) {
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyAudioTooLoudStepIdentifier];
        step.text = ORKLegacyLocalizedString(@"AUDIO_TOO_LOUD_MESSAGE", nil);
        step.detailText = ORKLegacyLocalizedString(@"AUDIO_TOO_LOUD_ACTION_NEXT", nil);
        
        ORKLegacyStepArrayAddStep(steps, step);
    }
    
    {
        ORKLegacyAudioStep *step = [[ORKLegacyAudioStep alloc] initWithIdentifier:ORKLegacyAudioStepIdentifier];
        step.title = shortSpeechInstruction ? : ORKLegacyLocalizedString(@"AUDIO_INSTRUCTION", nil);
        step.recorderConfigurations = @[[[ORKLegacyAudioRecorderConfiguration alloc] initWithIdentifier:ORKLegacyAudioRecorderIdentifier
                                                                                 recorderSettings:recordingSettings]];
        step.stepDuration = duration;
        step.shouldContinueOnFinish = YES;
        
        ORKLegacyStepArrayAddStep(steps, step);
    }
    
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeConclusion)) {
        ORKLegacyInstructionStep *step = [self makeCompletionStep];
        
        ORKLegacyStepArrayAddStep(steps, step);
    }

    ORKLegacyNavigableOrderedTask *task = [[ORKLegacyNavigableOrderedTask alloc] initWithIdentifier:identifier steps:steps];
    
    if (checkAudioLevel) {
    
        // Add rules to check for audio and fail, looping back to the countdown step if required
        ORKLegacyAudioLevelNavigationRule *audioRule = [[ORKLegacyAudioLevelNavigationRule alloc] initWithAudioLevelStepIdentifier:ORKLegacyCountdownStepIdentifier destinationStepIdentifier:ORKLegacyAudioStepIdentifier recordingSettings:recordingSettings];
        ORKLegacyDirectStepNavigationRule *loopRule = [[ORKLegacyDirectStepNavigationRule alloc] initWithDestinationStepIdentifier:ORKLegacyCountdownStepIdentifier];
    
        [task setNavigationRule:audioRule forTriggerStepIdentifier:ORKLegacyCountdownStepIdentifier];
        [task setNavigationRule:loopRule forTriggerStepIdentifier:ORKLegacyAudioTooLoudStepIdentifier];
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

+ (ORKLegacyOrderedTask *)fitnessCheckTaskWithIdentifier:(NSString *)identifier
                           intendedUseDescription:(NSString *)intendedUseDescription
                                     walkDuration:(NSTimeInterval)walkDuration
                                     restDuration:(NSTimeInterval)restDuration
                                          options:(ORKLegacyPredefinedTaskOption)options {
    
    NSDateComponentsFormatter *formatter = [self textTimeFormatter];
    
    NSMutableArray *steps = [NSMutableArray array];
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction0StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"FITNESS_TASK_TITLE", nil);
            step.text = intendedUseDescription ? : [NSString localizedStringWithFormat:ORKLegacyLocalizedString(@"FITNESS_INTRO_TEXT_FORMAT", nil), [formatter stringFromTimeInterval:walkDuration]];
            step.image = [UIImage imageNamed:@"heartbeat" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction1StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"FITNESS_TASK_TITLE", nil);
            step.text = [NSString localizedStringWithFormat:ORKLegacyLocalizedString(@"FITNESS_INTRO_2_TEXT_FORMAT", nil), [formatter stringFromTimeInterval:walkDuration], [formatter stringFromTimeInterval:restDuration]];
            step.image = [UIImage imageNamed:@"walkingman" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
    }
    
    {
        ORKLegacyCountdownStep *step = [[ORKLegacyCountdownStep alloc] initWithIdentifier:ORKLegacyCountdownStepIdentifier];
        step.stepDuration = 5.0;
        
        ORKLegacyStepArrayAddStep(steps, step);
    }
    
    HKUnit *bpmUnit = [[HKUnit countUnit] unitDividedByUnit:[HKUnit minuteUnit]];
    HKQuantityType *heartRateType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    {
        if (walkDuration > 0) {
            NSMutableArray *recorderConfigurations = [NSMutableArray arrayWithCapacity:5];
            if (!(ORKLegacyPredefinedTaskOptionExcludePedometer & options)) {
                [recorderConfigurations addObject:[[ORKLegacyPedometerRecorderConfiguration alloc] initWithIdentifier:ORKLegacyPedometerRecorderIdentifier]];
            }
            if (!(ORKLegacyPredefinedTaskOptionExcludeAccelerometer & options)) {
                [recorderConfigurations addObject:[[ORKLegacyAccelerometerRecorderConfiguration alloc] initWithIdentifier:ORKLegacyAccelerometerRecorderIdentifier
                                                                                                          frequency:100]];
            }
            if (!(ORKLegacyPredefinedTaskOptionExcludeDeviceMotion & options)) {
                [recorderConfigurations addObject:[[ORKLegacyDeviceMotionRecorderConfiguration alloc] initWithIdentifier:ORKLegacyDeviceMotionRecorderIdentifier
                                                                                                         frequency:100]];
            }
            if (!(ORKLegacyPredefinedTaskOptionExcludeLocation & options)) {
                [recorderConfigurations addObject:[[ORKLegacyLocationRecorderConfiguration alloc] initWithIdentifier:ORKLegacyLocationRecorderIdentifier]];
            }
            if (!(ORKLegacyPredefinedTaskOptionExcludeHeartRate & options)) {
                [recorderConfigurations addObject:[[ORKLegacyHealthQuantityTypeRecorderConfiguration alloc] initWithIdentifier:ORKLegacyHeartRateRecorderIdentifier
                                                                                                      healthQuantityType:heartRateType unit:bpmUnit]];
            }
            ORKLegacyFitnessStep *fitnessStep = [[ORKLegacyFitnessStep alloc] initWithIdentifier:ORKLegacyFitnessWalkStepIdentifier];
            fitnessStep.stepDuration = walkDuration;
            fitnessStep.title = [NSString localizedStringWithFormat:ORKLegacyLocalizedString(@"FITNESS_WALK_INSTRUCTION_FORMAT", nil), [formatter stringFromTimeInterval:walkDuration]];
            fitnessStep.spokenInstruction = fitnessStep.title;
            fitnessStep.recorderConfigurations = recorderConfigurations;
            fitnessStep.shouldContinueOnFinish = YES;
            fitnessStep.optional = NO;
            fitnessStep.shouldStartTimerAutomatically = YES;
            fitnessStep.shouldTintImages = YES;
            fitnessStep.image = [UIImage imageNamed:@"walkingman" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            fitnessStep.shouldVibrateOnStart = YES;
            fitnessStep.shouldPlaySoundOnStart = YES;
            
            ORKLegacyStepArrayAddStep(steps, fitnessStep);
        }
        
        if (restDuration > 0) {
            NSMutableArray *recorderConfigurations = [NSMutableArray arrayWithCapacity:5];
            if (!(ORKLegacyPredefinedTaskOptionExcludeAccelerometer & options)) {
                [recorderConfigurations addObject:[[ORKLegacyAccelerometerRecorderConfiguration alloc] initWithIdentifier:ORKLegacyAccelerometerRecorderIdentifier
                                                                                                          frequency:100]];
            }
            if (!(ORKLegacyPredefinedTaskOptionExcludeDeviceMotion & options)) {
                [recorderConfigurations addObject:[[ORKLegacyDeviceMotionRecorderConfiguration alloc] initWithIdentifier:ORKLegacyDeviceMotionRecorderIdentifier
                                                                                                         frequency:100]];
            }
            if (!(ORKLegacyPredefinedTaskOptionExcludeHeartRate & options)) {
                [recorderConfigurations addObject:[[ORKLegacyHealthQuantityTypeRecorderConfiguration alloc] initWithIdentifier:ORKLegacyHeartRateRecorderIdentifier
                                                                                                      healthQuantityType:heartRateType unit:bpmUnit]];
            }
            
            ORKLegacyFitnessStep *stillStep = [[ORKLegacyFitnessStep alloc] initWithIdentifier:ORKLegacyFitnessRestStepIdentifier];
            stillStep.stepDuration = restDuration;
            stillStep.title = [NSString localizedStringWithFormat:ORKLegacyLocalizedString(@"FITNESS_SIT_INSTRUCTION_FORMAT", nil), [formatter stringFromTimeInterval:restDuration]];
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
            
            ORKLegacyStepArrayAddStep(steps, stillStep);
        }
    }
    
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeConclusion)) {
        ORKLegacyInstructionStep *step = [self makeCompletionStep];
        ORKLegacyStepArrayAddStep(steps, step);
    }
    
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:identifier steps:steps];
    
    return task;
}

+ (ORKLegacyOrderedTask *)shortWalkTaskWithIdentifier:(NSString *)identifier
                         intendedUseDescription:(NSString *)intendedUseDescription
                            numberOfStepsPerLeg:(NSInteger)numberOfStepsPerLeg
                                   restDuration:(NSTimeInterval)restDuration
                                        options:(ORKLegacyPredefinedTaskOption)options {
    
    NSDateComponentsFormatter *formatter = [self textTimeFormatter];
    
    NSMutableArray *steps = [NSMutableArray array];
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction0StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"WALK_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = ORKLegacyLocalizedString(@"WALK_INTRO_TEXT", nil);
            step.shouldTintImages = YES;
            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction1StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"WALK_TASK_TITLE", nil);
            step.text = [NSString localizedStringWithFormat:ORKLegacyLocalizedString(@"WALK_INTRO_2_TEXT_%ld", nil),numberOfStepsPerLeg];
            step.detailText = ORKLegacyLocalizedString(@"WALK_INTRO_2_DETAIL", nil);
            step.image = [UIImage imageNamed:@"pocket" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            ORKLegacyStepArrayAddStep(steps, step);
        }
    }
    
    {
        ORKLegacyCountdownStep *step = [[ORKLegacyCountdownStep alloc] initWithIdentifier:ORKLegacyCountdownStepIdentifier];
        step.stepDuration = 5.0;
        
        ORKLegacyStepArrayAddStep(steps, step);
    }
    
    {
        {
            NSMutableArray *recorderConfigurations = [NSMutableArray array];
            if (!(ORKLegacyPredefinedTaskOptionExcludePedometer & options)) {
                [recorderConfigurations addObject:[[ORKLegacyPedometerRecorderConfiguration alloc] initWithIdentifier:ORKLegacyPedometerRecorderIdentifier]];
            }
            if (!(ORKLegacyPredefinedTaskOptionExcludeAccelerometer & options)) {
                [recorderConfigurations addObject:[[ORKLegacyAccelerometerRecorderConfiguration alloc] initWithIdentifier:ORKLegacyAccelerometerRecorderIdentifier
                                                                                                          frequency:100]];
            }
            if (!(ORKLegacyPredefinedTaskOptionExcludeDeviceMotion & options)) {
                [recorderConfigurations addObject:[[ORKLegacyDeviceMotionRecorderConfiguration alloc] initWithIdentifier:ORKLegacyDeviceMotionRecorderIdentifier
                                                                                                         frequency:100]];
            }

            ORKLegacyWalkingTaskStep *walkingStep = [[ORKLegacyWalkingTaskStep alloc] initWithIdentifier:ORKLegacyShortWalkOutboundStepIdentifier];
            walkingStep.numberOfStepsPerLeg = numberOfStepsPerLeg;
            walkingStep.title = [NSString localizedStringWithFormat:ORKLegacyLocalizedString(@"WALK_OUTBOUND_INSTRUCTION_FORMAT", nil), (long long)numberOfStepsPerLeg];
            walkingStep.spokenInstruction = walkingStep.title;
            walkingStep.recorderConfigurations = recorderConfigurations;
            walkingStep.shouldContinueOnFinish = YES;
            walkingStep.optional = NO;
            walkingStep.shouldStartTimerAutomatically = YES;
            walkingStep.stepDuration = numberOfStepsPerLeg * 1.5; // fallback duration in case no step count
            walkingStep.shouldVibrateOnStart = YES;
            walkingStep.shouldPlaySoundOnStart = YES;
            
            ORKLegacyStepArrayAddStep(steps, walkingStep);
        }
        
        {
            NSMutableArray *recorderConfigurations = [NSMutableArray array];
            if (!(ORKLegacyPredefinedTaskOptionExcludePedometer & options)) {
                [recorderConfigurations addObject:[[ORKLegacyPedometerRecorderConfiguration alloc] initWithIdentifier:ORKLegacyPedometerRecorderIdentifier]];
            }
            if (!(ORKLegacyPredefinedTaskOptionExcludeAccelerometer & options)) {
                [recorderConfigurations addObject:[[ORKLegacyAccelerometerRecorderConfiguration alloc] initWithIdentifier:ORKLegacyAccelerometerRecorderIdentifier
                                                                                                          frequency:100]];
            }
            if (!(ORKLegacyPredefinedTaskOptionExcludeDeviceMotion & options)) {
                [recorderConfigurations addObject:[[ORKLegacyDeviceMotionRecorderConfiguration alloc] initWithIdentifier:ORKLegacyDeviceMotionRecorderIdentifier
                                                                                                         frequency:100]];
            }

            ORKLegacyWalkingTaskStep *walkingStep = [[ORKLegacyWalkingTaskStep alloc] initWithIdentifier:ORKLegacyShortWalkReturnStepIdentifier];
            walkingStep.numberOfStepsPerLeg = numberOfStepsPerLeg;
            walkingStep.title = [NSString localizedStringWithFormat:ORKLegacyLocalizedString(@"WALK_RETURN_INSTRUCTION_FORMAT", nil), (long long)numberOfStepsPerLeg];
            walkingStep.spokenInstruction = walkingStep.title;
            walkingStep.recorderConfigurations = recorderConfigurations;
            walkingStep.shouldContinueOnFinish = YES;
            walkingStep.shouldStartTimerAutomatically = YES;
            walkingStep.optional = NO;
            walkingStep.stepDuration = numberOfStepsPerLeg * 1.5; // fallback duration in case no step count
            walkingStep.shouldVibrateOnStart = YES;
            walkingStep.shouldPlaySoundOnStart = YES;
            
            ORKLegacyStepArrayAddStep(steps, walkingStep);
        }
        
        if (restDuration > 0) {
            NSMutableArray *recorderConfigurations = [NSMutableArray array];
            if (!(ORKLegacyPredefinedTaskOptionExcludeAccelerometer & options)) {
                [recorderConfigurations addObject:[[ORKLegacyAccelerometerRecorderConfiguration alloc] initWithIdentifier:ORKLegacyAccelerometerRecorderIdentifier
                                                                                                          frequency:100]];
            }
            if (!(ORKLegacyPredefinedTaskOptionExcludeDeviceMotion & options)) {
                [recorderConfigurations addObject:[[ORKLegacyDeviceMotionRecorderConfiguration alloc] initWithIdentifier:ORKLegacyDeviceMotionRecorderIdentifier
                                                                                                         frequency:100]];
            }

            ORKLegacyFitnessStep *activeStep = [[ORKLegacyFitnessStep alloc] initWithIdentifier:ORKLegacyShortWalkRestStepIdentifier];
            activeStep.recorderConfigurations = recorderConfigurations;
            NSString *durationString = [formatter stringFromTimeInterval:restDuration];
            activeStep.title = [NSString localizedStringWithFormat:ORKLegacyLocalizedString(@"WALK_STAND_INSTRUCTION_FORMAT", nil), durationString];
            activeStep.spokenInstruction = [NSString localizedStringWithFormat:ORKLegacyLocalizedString(@"WALK_STAND_VOICE_INSTRUCTION_FORMAT", nil), durationString];
            activeStep.shouldStartTimerAutomatically = YES;
            activeStep.stepDuration = restDuration;
            activeStep.shouldContinueOnFinish = YES;
            activeStep.optional = NO;
            activeStep.shouldVibrateOnStart = YES;
            activeStep.shouldPlaySoundOnStart = YES;
            activeStep.shouldVibrateOnFinish = YES;
            activeStep.shouldPlaySoundOnFinish = YES;
            
            ORKLegacyStepArrayAddStep(steps, activeStep);
        }
    }
    
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeConclusion)) {
        ORKLegacyInstructionStep *step = [self makeCompletionStep];
        
        ORKLegacyStepArrayAddStep(steps, step);
    }
    
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:identifier steps:steps];
    return task;
}


+ (ORKLegacyOrderedTask *)walkBackAndForthTaskWithIdentifier:(NSString *)identifier
                                intendedUseDescription:(NSString *)intendedUseDescription
                                          walkDuration:(NSTimeInterval)walkDuration
                                          restDuration:(NSTimeInterval)restDuration
                                               options:(ORKLegacyPredefinedTaskOption)options {
    
    NSDateComponentsFormatter *formatter = [self textTimeFormatter];
    formatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
    
    NSMutableArray *steps = [NSMutableArray array];
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction0StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"WALK_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = ORKLegacyLocalizedString(@"WALK_INTRO_TEXT", nil);
            step.shouldTintImages = YES;
            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction1StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"WALK_TASK_TITLE", nil);
            step.text = ORKLegacyLocalizedString(@"WALK_INTRO_2_TEXT_BACK_AND_FORTH_INSTRUCTION", nil);
            step.detailText = ORKLegacyLocalizedString(@"WALK_INTRO_2_DETAIL_BACK_AND_FORTH_INSTRUCTION", nil);
            step.image = [UIImage imageNamed:@"pocket" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            ORKLegacyStepArrayAddStep(steps, step);
        }
    }
    
    {
        ORKLegacyCountdownStep *step = [[ORKLegacyCountdownStep alloc] initWithIdentifier:ORKLegacyCountdownStepIdentifier];
        step.stepDuration = 5.0;
        
        ORKLegacyStepArrayAddStep(steps, step);
    }
    
    {
        {
            NSMutableArray *recorderConfigurations = [NSMutableArray array];
            if (!(ORKLegacyPredefinedTaskOptionExcludePedometer & options)) {
                [recorderConfigurations addObject:[[ORKLegacyPedometerRecorderConfiguration alloc] initWithIdentifier:ORKLegacyPedometerRecorderIdentifier]];
            }
            if (!(ORKLegacyPredefinedTaskOptionExcludeAccelerometer & options)) {
                [recorderConfigurations addObject:[[ORKLegacyAccelerometerRecorderConfiguration alloc] initWithIdentifier:ORKLegacyAccelerometerRecorderIdentifier
                                                                                                          frequency:100]];
            }
            if (!(ORKLegacyPredefinedTaskOptionExcludeDeviceMotion & options)) {
                [recorderConfigurations addObject:[[ORKLegacyDeviceMotionRecorderConfiguration alloc] initWithIdentifier:ORKLegacyDeviceMotionRecorderIdentifier
                                                                                                         frequency:100]];
            }
            
            ORKLegacyWalkingTaskStep *walkingStep = [[ORKLegacyWalkingTaskStep alloc] initWithIdentifier:ORKLegacyShortWalkOutboundStepIdentifier];
            walkingStep.numberOfStepsPerLeg = 1000; // Set the number of steps very high so it is ignored
            NSString *walkingDurationString = [formatter stringFromTimeInterval:walkDuration];
            walkingStep.title = [NSString localizedStringWithFormat:ORKLegacyLocalizedString(@"WALK_BACK_AND_FORTH_INSTRUCTION_FORMAT", nil), walkingDurationString];
            walkingStep.spokenInstruction = walkingStep.title;
            walkingStep.recorderConfigurations = recorderConfigurations;
            walkingStep.shouldContinueOnFinish = YES;
            walkingStep.optional = NO;
            walkingStep.shouldStartTimerAutomatically = YES;
            walkingStep.stepDuration = walkDuration; // Set the walking duration to the step duration
            walkingStep.shouldVibrateOnStart = YES;
            walkingStep.shouldPlaySoundOnStart = YES;
            walkingStep.shouldSpeakRemainingTimeAtHalfway = (walkDuration > 20);
            
            ORKLegacyStepArrayAddStep(steps, walkingStep);
        }
        
        if (restDuration > 0) {
            NSMutableArray *recorderConfigurations = [NSMutableArray array];
            if (!(ORKLegacyPredefinedTaskOptionExcludeAccelerometer & options)) {
                [recorderConfigurations addObject:[[ORKLegacyAccelerometerRecorderConfiguration alloc] initWithIdentifier:ORKLegacyAccelerometerRecorderIdentifier
                                                                                                          frequency:100]];
            }
            if (!(ORKLegacyPredefinedTaskOptionExcludeDeviceMotion & options)) {
                [recorderConfigurations addObject:[[ORKLegacyDeviceMotionRecorderConfiguration alloc] initWithIdentifier:ORKLegacyDeviceMotionRecorderIdentifier
                                                                                                         frequency:100]];
            }
            
            ORKLegacyFitnessStep *activeStep = [[ORKLegacyFitnessStep alloc] initWithIdentifier:ORKLegacyShortWalkRestStepIdentifier];
            activeStep.recorderConfigurations = recorderConfigurations;
            NSString *durationString = [formatter stringFromTimeInterval:restDuration];
            activeStep.title = [NSString localizedStringWithFormat:ORKLegacyLocalizedString(@"WALK_BACK_AND_FORTH_STAND_INSTRUCTION_FORMAT", nil), durationString];
            activeStep.spokenInstruction = activeStep.title;
            activeStep.shouldStartTimerAutomatically = YES;
            activeStep.stepDuration = restDuration;
            activeStep.shouldContinueOnFinish = YES;
            activeStep.optional = NO;
            activeStep.shouldVibrateOnStart = YES;
            activeStep.shouldPlaySoundOnStart = YES;
            activeStep.shouldVibrateOnFinish = YES;
            activeStep.shouldPlaySoundOnFinish = YES;
            activeStep.finishedSpokenInstruction = ORKLegacyLocalizedString(@"WALK_BACK_AND_FORTH_FINISHED_VOICE", nil);
            activeStep.shouldSpeakRemainingTimeAtHalfway = (restDuration > 20);
            
            ORKLegacyStepArrayAddStep(steps, activeStep);
        }
    }
    
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeConclusion)) {
        ORKLegacyInstructionStep *step = [self makeCompletionStep];
        
        ORKLegacyStepArrayAddStep(steps, step);
    }
    
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:identifier steps:steps];
    return task;
}

+ (ORKLegacyOrderedTask *)kneeRangeOfMotionTaskWithIdentifier:(NSString *)identifier
                                             limbOption:(ORKLegacyPredefinedTaskLimbOption)limbOption
                                 intendedUseDescription:(NSString *)intendedUseDescription
                                                options:(ORKLegacyPredefinedTaskOption)options {
    NSMutableArray *steps = [NSMutableArray array];
    NSString *limbType = ORKLegacyLocalizedString(@"LIMB_RIGHT", nil);
    UIImage *kneeFlexedImage = [UIImage imageNamed:@"knee_flexed_right" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    UIImage *kneeExtendedImage = [UIImage imageNamed:@"knee_extended_right" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];

    if (limbOption == ORKLegacyPredefinedTaskLimbOptionLeft) {
        limbType = ORKLegacyLocalizedString(@"LIMB_LEFT", nil);
    
        kneeFlexedImage = [UIImage imageNamed:@"knee_flexed_left" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
        kneeExtendedImage = [UIImage imageNamed:@"knee_extended_left" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    }
    
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
        ORKLegacyInstructionStep *instructionStep0 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction0StepIdentifier];
        instructionStep0.title = ([limbType isEqualToString:ORKLegacyLocalizedString(@"LIMB_LEFT", nil)])? ORKLegacyLocalizedString(@"KNEE_RANGE_OF_MOTION_TITLE_LEFT", nil) : ORKLegacyLocalizedString(@"KNEE_RANGE_OF_MOTION_TITLE_RIGHT", nil);
        instructionStep0.text = intendedUseDescription;
        instructionStep0.detailText = ([limbType isEqualToString:ORKLegacyLocalizedString(@"LIMB_LEFT", nil)])? ORKLegacyLocalizedString(@"KNEE_RANGE_OF_MOTION_TEXT_INSTRUCTION_0_LEFT", nil) : ORKLegacyLocalizedString(@"KNEE_RANGE_OF_MOTION_TEXT_INSTRUCTION_0_RIGHT", nil);
        instructionStep0.shouldTintImages = YES;
        ORKLegacyStepArrayAddStep(steps, instructionStep0);
 
        ORKLegacyInstructionStep *instructionStep1 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction1StepIdentifier];
        instructionStep1.title = ([limbType isEqualToString:ORKLegacyLocalizedString(@"LIMB_LEFT", nil)])? ORKLegacyLocalizedString(@"KNEE_RANGE_OF_MOTION_TITLE_LEFT", nil) : ORKLegacyLocalizedString(@"KNEE_RANGE_OF_MOTION_TITLE_RIGHT", nil);
        
        instructionStep1.detailText = ([limbType isEqualToString:ORKLegacyLocalizedString(@"LIMB_LEFT", nil)])? ORKLegacyLocalizedString(@"KNEE_RANGE_OF_MOTION_TEXT_INSTRUCTION_1_LEFT", nil) : ORKLegacyLocalizedString(@"KNEE_RANGE_OF_MOTION_TEXT_INSTRUCTION_1_RIGHT", nil);
        ORKLegacyStepArrayAddStep(steps, instructionStep1);
        
        ORKLegacyInstructionStep *instructionStep2 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction2StepIdentifier];
        instructionStep2.title = ([limbType isEqualToString:ORKLegacyLocalizedString(@"LIMB_LEFT", nil)])? ORKLegacyLocalizedString(@"KNEE_RANGE_OF_MOTION_TITLE_LEFT", nil) : ORKLegacyLocalizedString(@"KNEE_RANGE_OF_MOTION_TITLE_RIGHT", nil);
        
        instructionStep2.detailText = ([limbType isEqualToString:ORKLegacyLocalizedString(@"LIMB_LEFT", nil)])? ORKLegacyLocalizedString(@"KNEE_RANGE_OF_MOTION_TEXT_INSTRUCTION_2_LEFT", nil) : ORKLegacyLocalizedString(@"KNEE_RANGE_OF_MOTION_TEXT_INSTRUCTION_2_RIGHT", nil);
        instructionStep2.image = kneeFlexedImage;
        instructionStep2.shouldTintImages = YES;
        ORKLegacyStepArrayAddStep(steps, instructionStep2);
        
        ORKLegacyInstructionStep *instructionStep3 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction3StepIdentifier];
        instructionStep3.title = ([limbType isEqualToString:ORKLegacyLocalizedString(@"LIMB_LEFT", nil)])? ORKLegacyLocalizedString(@"KNEE_RANGE_OF_MOTION_TITLE_LEFT", nil) : ORKLegacyLocalizedString(@"KNEE_RANGE_OF_MOTION_TITLE_RIGHT", nil);
        instructionStep3.detailText = ([limbType isEqualToString:ORKLegacyLocalizedString(@"LIMB_LEFT", nil)])? ORKLegacyLocalizedString(@"KNEE_RANGE_OF_MOTION_TEXT_INSTRUCTION_3_LEFT", nil) : ORKLegacyLocalizedString(@"KNEE_RANGE_OF_MOTION_TEXT_INSTRUCTION_3_RIGHT", nil);

        instructionStep3.image = kneeExtendedImage;
        instructionStep3.shouldTintImages = YES;
        ORKLegacyStepArrayAddStep(steps, instructionStep3);
    }
    NSString *instructionText = ([limbType isEqualToString:ORKLegacyLocalizedString(@"LIMB_LEFT", nil)])? ORKLegacyLocalizedString(@"KNEE_RANGE_OF_MOTION_TOUCH_ANYWHERE_STEP_INSTRUCTION_LEFT", nil) : ORKLegacyLocalizedString(@"KNEE_RANGE_OF_MOTION_TOUCH_ANYWHERE_STEP_INSTRUCTION_RIGHT", nil);
    ORKLegacyTouchAnywhereStep *touchAnywhereStep = [[ORKLegacyTouchAnywhereStep alloc] initWithIdentifier:ORKLegacyTouchAnywhereStepIdentifier instructionText:instructionText];
    ORKLegacyStepArrayAddStep(steps, touchAnywhereStep);
    
    ORKLegacyDeviceMotionRecorderConfiguration *deviceMotionRecorderConfig = [[ORKLegacyDeviceMotionRecorderConfiguration alloc] initWithIdentifier:ORKLegacyDeviceMotionRecorderIdentifier frequency:100];
    
    ORKLegacyRangeOfMotionStep *kneeRangeOfMotionStep = [[ORKLegacyRangeOfMotionStep alloc] initWithIdentifier:ORKLegacyKneeRangeOfMotionStepIdentifier limbOption:limbOption];
    kneeRangeOfMotionStep.title = ([limbType isEqualToString: ORKLegacyLocalizedString(@"LIMB_LEFT", nil)])? ORKLegacyLocalizedString(@"KNEE_RANGE_OF_MOTION_SPOKEN_INSTRUCTION_LEFT", nil) :
    ORKLegacyLocalizedString(@"KNEE_RANGE_OF_MOTION_SPOKEN_INSTRUCTION_RIGHT", nil);
    
    kneeRangeOfMotionStep.spokenInstruction = kneeRangeOfMotionStep.title;
    kneeRangeOfMotionStep.recorderConfigurations = @[deviceMotionRecorderConfig];
    kneeRangeOfMotionStep.optional = NO;

    ORKLegacyStepArrayAddStep(steps, kneeRangeOfMotionStep);

    if (!(options & ORKLegacyPredefinedTaskOptionExcludeConclusion)) {
        ORKLegacyCompletionStep *completionStep = [self makeCompletionStep];
        ORKLegacyStepArrayAddStep(steps, completionStep);
    }
    
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:identifier steps:steps];
    return task;
}

+ (ORKLegacyOrderedTask *)shoulderRangeOfMotionTaskWithIdentifier:(NSString *)identifier
                                                 limbOption:(ORKLegacyPredefinedTaskLimbOption)limbOption
                                     intendedUseDescription:(NSString *)intendedUseDescription
                                                    options:(ORKLegacyPredefinedTaskOption)options {
    NSMutableArray *steps = [NSMutableArray array];
    NSString *limbType = ORKLegacyLocalizedString(@"LIMB_RIGHT", nil);
    UIImage *shoulderFlexedImage = [UIImage imageNamed:@"shoulder_flexed_right" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    UIImage *shoulderExtendedImage = [UIImage imageNamed:@"shoulder_extended_right" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];

    if (limbOption == ORKLegacyPredefinedTaskLimbOptionLeft) {
        limbType = ORKLegacyLocalizedString(@"LIMB_LEFT", nil);
        shoulderFlexedImage = [UIImage imageNamed:@"shoulder_flexed_left" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
        shoulderExtendedImage = [UIImage imageNamed:@"shoulder_extended_left" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    }
    
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
        ORKLegacyInstructionStep *instructionStep0 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction0StepIdentifier];
        instructionStep0.title = ([limbType isEqualToString:ORKLegacyLocalizedString(@"LIMB_LEFT", nil)])? ORKLegacyLocalizedString(@"SHOULDER_RANGE_OF_MOTION_TITLE_LEFT", nil) : ORKLegacyLocalizedString(@"SHOULDER_RANGE_OF_MOTION_TITLE_RIGHT", nil);
        instructionStep0.text = intendedUseDescription;
        instructionStep0.detailText = ([limbType isEqualToString:ORKLegacyLocalizedString(@"LIMB_LEFT", nil)])? ORKLegacyLocalizedString(@"SHOULDER_RANGE_OF_MOTION_TEXT_INSTRUCTION_0_LEFT", nil) : ORKLegacyLocalizedString(@"SHOULDER_RANGE_OF_MOTION_TEXT_INSTRUCTION_0_RIGHT", nil);
        instructionStep0.shouldTintImages = YES;
        ORKLegacyStepArrayAddStep(steps, instructionStep0);
        
        ORKLegacyInstructionStep *instructionStep1 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction1StepIdentifier];
        instructionStep1.title = ([limbType isEqualToString:ORKLegacyLocalizedString(@"LIMB_LEFT", nil)])? ORKLegacyLocalizedString(@"SHOULDER_RANGE_OF_MOTION_TITLE_LEFT", nil) : ORKLegacyLocalizedString(@"SHOULDER_RANGE_OF_MOTION_TITLE_RIGHT", nil);
        
        instructionStep1.detailText = ([limbType isEqualToString:ORKLegacyLocalizedString(@"LIMB_LEFT", nil)])? ORKLegacyLocalizedString(@"SHOULDER_RANGE_OF_MOTION_TEXT_INSTRUCTION_1_LEFT", nil) : ORKLegacyLocalizedString(@"SHOULDER_RANGE_OF_MOTION_TEXT_INSTRUCTION_1_RIGHT", nil);
        ORKLegacyStepArrayAddStep(steps, instructionStep1);
        
        ORKLegacyInstructionStep *instructionStep2 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction2StepIdentifier];
        instructionStep2.title = ([limbType isEqualToString:ORKLegacyLocalizedString(@"LIMB_LEFT", nil)])? ORKLegacyLocalizedString(@"SHOULDER_RANGE_OF_MOTION_TITLE_LEFT", nil) : ORKLegacyLocalizedString(@"SHOULDER_RANGE_OF_MOTION_TITLE_RIGHT", nil);
        
        instructionStep2.detailText = ([limbType isEqualToString:ORKLegacyLocalizedString(@"LIMB_LEFT", nil)])? ORKLegacyLocalizedString(@"SHOULDER_RANGE_OF_MOTION_TEXT_INSTRUCTION_2_LEFT", nil) : ORKLegacyLocalizedString(@"SHOULDER_RANGE_OF_MOTION_TEXT_INSTRUCTION_2_RIGHT", nil);
        instructionStep2.image = shoulderFlexedImage;
        instructionStep2.shouldTintImages = YES;
        ORKLegacyStepArrayAddStep(steps, instructionStep2);
        
        ORKLegacyInstructionStep *instructionStep3 = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction3StepIdentifier];
        instructionStep3.title = ([limbType isEqualToString:ORKLegacyLocalizedString(@"LIMB_LEFT", nil)])? ORKLegacyLocalizedString(@"SHOULDER_RANGE_OF_MOTION_TITLE_LEFT", nil) : ORKLegacyLocalizedString(@"SHOULDER_RANGE_OF_MOTION_TITLE_RIGHT", nil);
        
        instructionStep3.detailText = ([limbType isEqualToString:ORKLegacyLocalizedString(@"LIMB_LEFT", nil)])? ORKLegacyLocalizedString(@"SHOULDER_RANGE_OF_MOTION_TEXT_INSTRUCTION_3_LEFT", nil) : ORKLegacyLocalizedString(@"SHOULDER_RANGE_OF_MOTION_TEXT_INSTRUCTION_3_RIGHT", nil);
        instructionStep3.image = shoulderExtendedImage;
        instructionStep3.shouldTintImages = YES;
        ORKLegacyStepArrayAddStep(steps, instructionStep3);
    }
    
    NSString *instructionText = ([limbType isEqualToString:ORKLegacyLocalizedString(@"LIMB_LEFT", nil)])? ORKLegacyLocalizedString(@"SHOULDER_RANGE_OF_MOTION_TOUCH_ANYWHERE_STEP_INSTRUCTION_LEFT", nil) : ORKLegacyLocalizedString(@"SHOULDER_RANGE_OF_MOTION_TOUCH_ANYWHERE_STEP_INSTRUCTION_RIGHT", nil);
    ORKLegacyTouchAnywhereStep *touchAnywhereStep = [[ORKLegacyTouchAnywhereStep alloc] initWithIdentifier:ORKLegacyTouchAnywhereStepIdentifier instructionText:instructionText];
    ORKLegacyStepArrayAddStep(steps, touchAnywhereStep);
    
    ORKLegacyDeviceMotionRecorderConfiguration *deviceMotionRecorderConfig = [[ORKLegacyDeviceMotionRecorderConfiguration alloc] initWithIdentifier:ORKLegacyDeviceMotionRecorderIdentifier frequency:100];
    
    ORKLegacyShoulderRangeOfMotionStep *shoulderRangeOfMotionStep = [[ORKLegacyShoulderRangeOfMotionStep alloc] initWithIdentifier:ORKLegacyShoulderRangeOfMotionStepIdentifier limbOption:limbOption];
    shoulderRangeOfMotionStep.title = ([limbType isEqualToString: ORKLegacyLocalizedString(@"LIMB_LEFT", nil)])? ORKLegacyLocalizedString(@"SHOULDER_RANGE_OF_MOTION_SPOKEN_INSTRUCTION_LEFT", nil) :
    ORKLegacyLocalizedString(@"SHOULDER_RANGE_OF_MOTION_SPOKEN_INSTRUCTION_RIGHT", nil);

    shoulderRangeOfMotionStep.spokenInstruction = shoulderRangeOfMotionStep.title;
    
    shoulderRangeOfMotionStep.recorderConfigurations = @[deviceMotionRecorderConfig];
    shoulderRangeOfMotionStep.optional = NO;
    
    ORKLegacyStepArrayAddStep(steps, shoulderRangeOfMotionStep);
    
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeConclusion)) {
        ORKLegacyCompletionStep *completionStep = [self makeCompletionStep];
        ORKLegacyStepArrayAddStep(steps, completionStep);
    }
    
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:identifier steps:steps];
    return task;
}

+ (ORKLegacyOrderedTask *)spatialSpanMemoryTaskWithIdentifier:(NSString *)identifier
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
                                                options:(ORKLegacyPredefinedTaskOption)options {
    
    NSString *targetPluralName = customTargetPluralName ? : ORKLegacyLocalizedString(@"SPATIAL_SPAN_MEMORY_TARGET_PLURAL", nil);
    
    NSMutableArray *steps = [NSMutableArray array];
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction0StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"SPATIAL_SPAN_MEMORY_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = [NSString localizedStringWithFormat:ORKLegacyLocalizedString(@"SPATIAL_SPAN_MEMORY_INTRO_TEXT_%@", nil),targetPluralName];
            
            step.image = [UIImage imageNamed:@"phone-memory" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction1StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"SPATIAL_SPAN_MEMORY_TITLE", nil);
            step.text = [NSString localizedStringWithFormat:requireReversal ? ORKLegacyLocalizedString(@"SPATIAL_SPAN_MEMORY_INTRO_2_TEXT_REVERSE_%@", nil) : ORKLegacyLocalizedString(@"SPATIAL_SPAN_MEMORY_INTRO_2_TEXT_%@", nil), targetPluralName, targetPluralName];
            step.detailText = ORKLegacyLocalizedString(@"SPATIAL_SPAN_MEMORY_CALL_TO_ACTION", nil);
            
            if (!customTargetImage) {
                step.image = [UIImage imageNamed:@"memory-second-screen" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            } else {
                step.image = customTargetImage;
            }
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
    }
    
    {
        ORKLegacySpatialSpanMemoryStep *step = [[ORKLegacySpatialSpanMemoryStep alloc] initWithIdentifier:ORKLegacySpatialSpanMemoryStepIdentifier];
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
        
        ORKLegacyStepArrayAddStep(steps, step);
    }
    
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeConclusion)) {
        ORKLegacyInstructionStep *step = [self makeCompletionStep];
        ORKLegacyStepArrayAddStep(steps, step);
    }
    
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:identifier steps:steps];
    return task;
}

+ (ORKLegacyOrderedTask *)stroopTaskWithIdentifier:(NSString *)identifier
                      intendedUseDescription:(nullable NSString *)intendedUseDescription
                            numberOfAttempts:(NSInteger)numberOfAttempts
                                     options:(ORKLegacyPredefinedTaskOption)options {
    NSMutableArray *steps = [NSMutableArray array];
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction0StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"STROOP_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.image = [UIImage imageNamed:@"phonestrooplabel" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction1StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"STROOP_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = ORKLegacyLocalizedString(@"STROOP_TASK_INTRO1_DETAIL_TEXT", nil);
            step.image = [UIImage imageNamed:@"phonestroopbutton" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction2StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"STROOP_TASK_TITLE", nil);
            step.detailText = ORKLegacyLocalizedString(@"STROOP_TASK_INTRO2_DETAIL_TEXT", nil);
            step.image = [UIImage imageNamed:@"phonestroopbutton" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
    }
    {
        ORKLegacyCountdownStep *step = [[ORKLegacyCountdownStep alloc] initWithIdentifier:ORKLegacyCountdownStepIdentifier];
        step.stepDuration = 5.0;
        
        ORKLegacyStepArrayAddStep(steps, step);
    }
    {
        ORKLegacyStroopStep *step = [[ORKLegacyStroopStep alloc] initWithIdentifier:ORKLegacyStroopStepIdentifier];
        step.text = ORKLegacyLocalizedString(@"STROOP_TASK_STEP_TEXT", nil);
        step.numberOfAttempts = numberOfAttempts;
        
        ORKLegacyStepArrayAddStep(steps, step);
    }
    
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeConclusion)) {
        ORKLegacyInstructionStep *step = [self makeCompletionStep];
        
        ORKLegacyStepArrayAddStep(steps, step);
    }
    
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:identifier steps:steps];
    return task;
}

+ (ORKLegacyOrderedTask *)toneAudiometryTaskWithIdentifier:(NSString *)identifier
                              intendedUseDescription:(nullable NSString *)intendedUseDescription
                                   speechInstruction:(nullable NSString *)speechInstruction
                              shortSpeechInstruction:(nullable NSString *)shortSpeechInstruction
                                        toneDuration:(NSTimeInterval)toneDuration
                                             options:(ORKLegacyPredefinedTaskOption)options {

    if (options & ORKLegacyPredefinedTaskOptionExcludeAudio) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"Audio collection cannot be excluded from audio task" userInfo:nil];
    }

    NSMutableArray *steps = [NSMutableArray array];
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction0StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"TONE_AUDIOMETRY_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = ORKLegacyLocalizedString(@"TONE_AUDIOMETRY_INTENDED_USE", nil);
            step.image = [UIImage imageNamed:@"phonewaves_inverted" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;

            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction1StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"TONE_AUDIOMETRY_TASK_TITLE", nil);
            step.text = speechInstruction ? : ORKLegacyLocalizedString(@"TONE_AUDIOMETRY_INTRO_TEXT", nil);
            step.detailText = ORKLegacyLocalizedString(@"TONE_AUDIOMETRY_CALL_TO_ACTION", nil);
            step.image = [UIImage imageNamed:@"phonewaves_tapping" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;

            ORKLegacyStepArrayAddStep(steps, step);
        }
    }

    {
        ORKLegacyToneAudiometryPracticeStep *step = [[ORKLegacyToneAudiometryPracticeStep alloc] initWithIdentifier:ORKLegacyToneAudiometryPracticeStepIdentifier];
        step.title = ORKLegacyLocalizedString(@"TONE_AUDIOMETRY_TASK_TITLE", nil);
        step.text = speechInstruction ? : ORKLegacyLocalizedString(@"TONE_AUDIOMETRY_PREP_TEXT", nil);
        ORKLegacyStepArrayAddStep(steps, step);
        
    }
    
    {
        ORKLegacyCountdownStep *step = [[ORKLegacyCountdownStep alloc] initWithIdentifier:ORKLegacyCountdownStepIdentifier];
        step.stepDuration = 5.0;

        ORKLegacyStepArrayAddStep(steps, step);
    }

    {
        ORKLegacyToneAudiometryStep *step = [[ORKLegacyToneAudiometryStep alloc] initWithIdentifier:ORKLegacyToneAudiometryStepIdentifier];
        step.title = shortSpeechInstruction ? : ORKLegacyLocalizedString(@"TONE_AUDIOMETRY_INSTRUCTION", nil);
        step.toneDuration = toneDuration;

        ORKLegacyStepArrayAddStep(steps, step);
    }

    if (!(options & ORKLegacyPredefinedTaskOptionExcludeConclusion)) {
        ORKLegacyInstructionStep *step = [self makeCompletionStep];

        ORKLegacyStepArrayAddStep(steps, step);
    }

    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:identifier steps:steps];

    return task;
}

+ (ORKLegacyOrderedTask *)towerOfHanoiTaskWithIdentifier:(NSString *)identifier
                            intendedUseDescription:(nullable NSString *)intendedUseDescription
                                     numberOfDisks:(NSUInteger)numberOfDisks
                                           options:(ORKLegacyPredefinedTaskOption)options {
    
    NSMutableArray *steps = [NSMutableArray array];
    
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction0StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"TOWER_OF_HANOI_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = ORKLegacyLocalizedString(@"TOWER_OF_HANOI_TASK_INTENDED_USE", nil);
            step.image = [UIImage imageNamed:@"phone-tower-of-hanoi" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction1StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"TOWER_OF_HANOI_TASK_TITLE", nil);
            step.text = ORKLegacyLocalizedString(@"TOWER_OF_HANOI_TASK_INTRO_TEXT", nil);
            step.detailText = ORKLegacyLocalizedString(@"TOWER_OF_HANOI_TASK_TASK_CALL_TO_ACTION", nil);
            step.image = [UIImage imageNamed:@"tower-of-hanoi-second-screen" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
    }
    
    ORKLegacyTowerOfHanoiStep *towerOfHanoiStep = [[ORKLegacyTowerOfHanoiStep alloc]initWithIdentifier:ORKLegacyTowerOfHanoiStepIdentifier];
    towerOfHanoiStep.numberOfDisks = numberOfDisks;
    ORKLegacyStepArrayAddStep(steps, towerOfHanoiStep);
    
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeConclusion)) {
        ORKLegacyInstructionStep *step = [self makeCompletionStep];
        
        ORKLegacyStepArrayAddStep(steps, step);
    }
    
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc]initWithIdentifier:identifier steps:steps];
    
    return task;
}

+ (ORKLegacyOrderedTask *)reactionTimeTaskWithIdentifier:(NSString *)identifier
                            intendedUseDescription:(nullable NSString *)intendedUseDescription
                           maximumStimulusInterval:(NSTimeInterval)maximumStimulusInterval
                           minimumStimulusInterval:(NSTimeInterval)minimumStimulusInterval
                             thresholdAcceleration:(double)thresholdAcceleration
                                  numberOfAttempts:(int)numberOfAttempts
                                           timeout:(NSTimeInterval)timeout
                                      successSound:(UInt32)successSoundID
                                      timeoutSound:(UInt32)timeoutSoundID
                                      failureSound:(UInt32)failureSoundID
                                           options:(ORKLegacyPredefinedTaskOption)options {
    
    NSMutableArray *steps = [NSMutableArray array];
    
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction0StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"REACTION_TIME_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = ORKLegacyLocalizedString(@"REACTION_TIME_TASK_INTENDED_USE", nil);
            step.image = [UIImage imageNamed:@"phoneshake" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction1StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"REACTION_TIME_TASK_TITLE", nil);
            step.text = [NSString localizedStringWithFormat: ORKLegacyLocalizedString(@"REACTION_TIME_TASK_INTRO_TEXT_FORMAT", nil), numberOfAttempts];
            step.detailText = ORKLegacyLocalizedString(@"REACTION_TIME_TASK_CALL_TO_ACTION", nil);
            step.image = [UIImage imageNamed:@"phoneshakecircle" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
    }
    
    ORKLegacyReactionTimeStep *step = [[ORKLegacyReactionTimeStep alloc] initWithIdentifier:ORKLegacyReactionTimeStepIdentifier];
    step.maximumStimulusInterval = maximumStimulusInterval;
    step.minimumStimulusInterval = minimumStimulusInterval;
    step.thresholdAcceleration = thresholdAcceleration;
    step.numberOfAttempts = numberOfAttempts;
    step.timeout = timeout;
    step.successSound = successSoundID;
    step.timeoutSound = timeoutSoundID;
    step.failureSound = failureSoundID;
    step.recorderConfigurations = @[ [[ORKLegacyDeviceMotionRecorderConfiguration  alloc] initWithIdentifier:ORKLegacyDeviceMotionRecorderIdentifier frequency: 100]];

    ORKLegacyStepArrayAddStep(steps, step);
    
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeConclusion)) {
        ORKLegacyInstructionStep *step = [self makeCompletionStep];
        ORKLegacyStepArrayAddStep(steps, step);
    }
    
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:identifier steps:steps];
    
    return task;
}

+ (ORKLegacyOrderedTask *)timedWalkTaskWithIdentifier:(NSString *)identifier
                         intendedUseDescription:(nullable NSString *)intendedUseDescription
                               distanceInMeters:(double)distanceInMeters
                                      timeLimit:(NSTimeInterval)timeLimit
                     includeAssistiveDeviceForm:(BOOL)includeAssistiveDeviceForm
                                        options:(ORKLegacyPredefinedTaskOption)options {

    NSMutableArray *steps = [NSMutableArray array];

    NSLengthFormatter *lengthFormatter = [NSLengthFormatter new];
    lengthFormatter.numberFormatter.maximumFractionDigits = 1;
    lengthFormatter.numberFormatter.maximumSignificantDigits = 3;
    NSString *formattedLength = [lengthFormatter stringFromMeters:distanceInMeters];

    if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction0StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"TIMED_WALK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = ORKLegacyLocalizedString(@"TIMED_WALK_INTRO_DETAIL", nil);
            step.shouldTintImages = YES;

            ORKLegacyStepArrayAddStep(steps, step);
        }
    }

    if (includeAssistiveDeviceForm) {
        ORKLegacyFormStep *step = [[ORKLegacyFormStep alloc] initWithIdentifier:ORKLegacyTimedWalkFormStepIdentifier
                                                              title:ORKLegacyLocalizedString(@"TIMED_WALK_FORM_TITLE", nil)
                                                               text:ORKLegacyLocalizedString(@"TIMED_WALK_FORM_TEXT", nil)];

        ORKLegacyAnswerFormat *answerFormat1 = [ORKLegacyAnswerFormat booleanAnswerFormat];
        ORKLegacyFormItem *formItem1 = [[ORKLegacyFormItem alloc] initWithIdentifier:ORKLegacyTimedWalkFormAFOStepIdentifier
                                                                    text:ORKLegacyLocalizedString(@"TIMED_WALK_QUESTION_TEXT", nil)
                                                            answerFormat:answerFormat1];
        formItem1.optional = NO;

        NSArray *textChoices = @[ORKLegacyLocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE", nil),
                                 ORKLegacyLocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_2", nil),
                                 ORKLegacyLocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_3", nil),
                                 ORKLegacyLocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_4", nil),
                                 ORKLegacyLocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_5", nil),
                                 ORKLegacyLocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_6", nil)];
        ORKLegacyAnswerFormat *answerFormat2 = [ORKLegacyAnswerFormat valuePickerAnswerFormatWithTextChoices:textChoices];
        ORKLegacyFormItem *formItem2 = [[ORKLegacyFormItem alloc] initWithIdentifier:ORKLegacyTimedWalkFormAssistanceStepIdentifier
                                                                    text:ORKLegacyLocalizedString(@"TIMED_WALK_QUESTION_2_TITLE", nil)
                                                            answerFormat:answerFormat2];
        formItem2.placeholder = ORKLegacyLocalizedString(@"TIMED_WALK_QUESTION_2_TEXT", nil);
        formItem2.optional = NO;

        step.formItems = @[formItem1, formItem2];
        step.optional = NO;

        ORKLegacyStepArrayAddStep(steps, step);
    }

    if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction1StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"TIMED_WALK_TITLE", nil);
            step.text = [NSString localizedStringWithFormat:ORKLegacyLocalizedString(@"TIMED_WALK_INTRO_2_TEXT_%@", nil), formattedLength];
            step.detailText = ORKLegacyLocalizedString(@"TIMED_WALK_INTRO_2_DETAIL", nil);
            step.image = [UIImage imageNamed:@"timer" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;

            ORKLegacyStepArrayAddStep(steps, step);
        }
    }

    {
        ORKLegacyCountdownStep *step = [[ORKLegacyCountdownStep alloc] initWithIdentifier:ORKLegacyCountdownStepIdentifier];
        step.stepDuration = 5.0;

        ORKLegacyStepArrayAddStep(steps, step);
    }
    
    {
        NSMutableArray *recorderConfigurations = [NSMutableArray array];
        if (!(options & ORKLegacyPredefinedTaskOptionExcludePedometer)) {
            [recorderConfigurations addObject:[[ORKLegacyPedometerRecorderConfiguration alloc] initWithIdentifier:ORKLegacyPedometerRecorderIdentifier]];
        }
        if (!(options & ORKLegacyPredefinedTaskOptionExcludeAccelerometer)) {
            [recorderConfigurations addObject:[[ORKLegacyAccelerometerRecorderConfiguration alloc] initWithIdentifier:ORKLegacyAccelerometerRecorderIdentifier
                                                                                                      frequency:100]];
        }
        if (!(options & ORKLegacyPredefinedTaskOptionExcludeDeviceMotion)) {
            [recorderConfigurations addObject:[[ORKLegacyDeviceMotionRecorderConfiguration alloc] initWithIdentifier:ORKLegacyDeviceMotionRecorderIdentifier
                                                                                                     frequency:100]];
        }
        if (! (options & ORKLegacyPredefinedTaskOptionExcludeLocation)) {
            [recorderConfigurations addObject:[[ORKLegacyLocationRecorderConfiguration alloc] initWithIdentifier:ORKLegacyLocationRecorderIdentifier]];
        }

        {
            ORKLegacyTimedWalkStep *step = [[ORKLegacyTimedWalkStep alloc] initWithIdentifier:ORKLegacyTimedWalkTrial1StepIdentifier];
            step.title = [[NSString alloc] initWithFormat:ORKLegacyLocalizedString(@"TIMED_WALK_INSTRUCTION_%@", nil), formattedLength];
            step.text = ORKLegacyLocalizedString(@"TIMED_WALK_INSTRUCTION_TEXT", nil);
            step.spokenInstruction = step.title;
            step.recorderConfigurations = recorderConfigurations;
            step.distanceInMeters = distanceInMeters;
            step.shouldTintImages = YES;
            step.image = [UIImage imageNamed:@"timed-walkingman-outbound" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.stepDuration = timeLimit == 0 ? CGFLOAT_MAX : timeLimit;

            ORKLegacyStepArrayAddStep(steps, step);
        }

        {
            ORKLegacyTimedWalkStep *step = [[ORKLegacyTimedWalkStep alloc] initWithIdentifier:ORKLegacyTimedWalkTrial2StepIdentifier];
            step.title = [[NSString alloc] initWithFormat:ORKLegacyLocalizedString(@"TIMED_WALK_INSTRUCTION_2", nil), formattedLength];
            step.text = ORKLegacyLocalizedString(@"TIMED_WALK_INSTRUCTION_TEXT", nil);
            step.spokenInstruction = step.title;
            step.recorderConfigurations = recorderConfigurations;
            step.distanceInMeters = distanceInMeters;
            step.shouldTintImages = YES;
            step.image = [UIImage imageNamed:@"timed-walkingman-return" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.stepDuration = timeLimit == 0 ? CGFLOAT_MAX : timeLimit;

            ORKLegacyStepArrayAddStep(steps, step);
        }
    }

    if (!(options & ORKLegacyPredefinedTaskOptionExcludeConclusion)) {
        ORKLegacyInstructionStep *step = [self makeCompletionStep];

        ORKLegacyStepArrayAddStep(steps, step);
    }

    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:identifier steps:steps];
    return task;
}

+ (ORKLegacyOrderedTask *)timedWalkTaskWithIdentifier:(NSString *)identifier
                         intendedUseDescription:(nullable NSString *)intendedUseDescription
                               distanceInMeters:(double)distanceInMeters
                                      timeLimit:(NSTimeInterval)timeLimit
                            turnAroundTimeLimit:(NSTimeInterval)turnAroundTimeLimit
                     includeAssistiveDeviceForm:(BOOL)includeAssistiveDeviceForm
                                        options:(ORKLegacyPredefinedTaskOption)options {

    NSMutableArray *steps = [NSMutableArray array];

    NSLengthFormatter *lengthFormatter = [NSLengthFormatter new];
    lengthFormatter.numberFormatter.maximumFractionDigits = 1;
    lengthFormatter.numberFormatter.maximumSignificantDigits = 3;
    NSString *formattedLength = [lengthFormatter stringFromMeters:distanceInMeters];

    if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction0StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"TIMED_WALK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = ORKLegacyLocalizedString(@"TIMED_WALK_INTRO_DETAIL", nil);
            step.shouldTintImages = YES;

            ORKLegacyStepArrayAddStep(steps, step);
        }
    }

    if (includeAssistiveDeviceForm) {
        ORKLegacyFormStep *step = [[ORKLegacyFormStep alloc] initWithIdentifier:ORKLegacyTimedWalkFormStepIdentifier
                                                              title:ORKLegacyLocalizedString(@"TIMED_WALK_FORM_TITLE", nil)
                                                               text:ORKLegacyLocalizedString(@"TIMED_WALK_FORM_TEXT", nil)];

        ORKLegacyAnswerFormat *answerFormat1 = [ORKLegacyAnswerFormat booleanAnswerFormat];
        ORKLegacyFormItem *formItem1 = [[ORKLegacyFormItem alloc] initWithIdentifier:ORKLegacyTimedWalkFormAFOStepIdentifier
                                                                    text:ORKLegacyLocalizedString(@"TIMED_WALK_QUESTION_TEXT", nil)
                                                            answerFormat:answerFormat1];
        formItem1.optional = NO;

        NSArray *textChoices = @[ORKLegacyLocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE", nil),
                                 ORKLegacyLocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_2", nil),
                                 ORKLegacyLocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_3", nil),
                                 ORKLegacyLocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_4", nil),
                                 ORKLegacyLocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_5", nil),
                                 ORKLegacyLocalizedString(@"TIMED_WALK_QUESTION_2_CHOICE_6", nil)];
        ORKLegacyAnswerFormat *answerFormat2 = [ORKLegacyAnswerFormat valuePickerAnswerFormatWithTextChoices:textChoices];
        ORKLegacyFormItem *formItem2 = [[ORKLegacyFormItem alloc] initWithIdentifier:ORKLegacyTimedWalkFormAssistanceStepIdentifier
                                                                    text:ORKLegacyLocalizedString(@"TIMED_WALK_QUESTION_2_TITLE", nil)
                                                            answerFormat:answerFormat2];
        formItem2.placeholder = ORKLegacyLocalizedString(@"TIMED_WALK_QUESTION_2_TEXT", nil);
        formItem2.optional = NO;

        step.formItems = @[formItem1, formItem2];
        step.optional = NO;

        ORKLegacyStepArrayAddStep(steps, step);
    }

    if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction1StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"TIMED_WALK_TITLE", nil);
            step.text = [NSString localizedStringWithFormat:ORKLegacyLocalizedString(@"TIMED_WALK_INTRO_2_TEXT_%@", nil), formattedLength];
            step.detailText = ORKLegacyLocalizedString(@"TIMED_WALK_INTRO_2_DETAIL", nil);
            step.image = [UIImage imageNamed:@"timer" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;

            ORKLegacyStepArrayAddStep(steps, step);
        }
    }

    {
        ORKLegacyCountdownStep *step = [[ORKLegacyCountdownStep alloc] initWithIdentifier:ORKLegacyCountdownStepIdentifier];
        step.stepDuration = 5.0;

        ORKLegacyStepArrayAddStep(steps, step);
    }

    {
        NSMutableArray *recorderConfigurations = [NSMutableArray array];
        if (!(options & ORKLegacyPredefinedTaskOptionExcludePedometer)) {
            [recorderConfigurations addObject:[[ORKLegacyPedometerRecorderConfiguration alloc] initWithIdentifier:ORKLegacyPedometerRecorderIdentifier]];
        }
        if (!(options & ORKLegacyPredefinedTaskOptionExcludeAccelerometer)) {
            [recorderConfigurations addObject:[[ORKLegacyAccelerometerRecorderConfiguration alloc] initWithIdentifier:ORKLegacyAccelerometerRecorderIdentifier
                                                                                                      frequency:100]];
        }
        if (!(options & ORKLegacyPredefinedTaskOptionExcludeDeviceMotion)) {
            [recorderConfigurations addObject:[[ORKLegacyDeviceMotionRecorderConfiguration alloc] initWithIdentifier:ORKLegacyDeviceMotionRecorderIdentifier
                                                                                                     frequency:100]];
        }
        if (! (options & ORKLegacyPredefinedTaskOptionExcludeLocation)) {
            [recorderConfigurations addObject:[[ORKLegacyLocationRecorderConfiguration alloc] initWithIdentifier:ORKLegacyLocationRecorderIdentifier]];
        }

        {
            ORKLegacyTimedWalkStep *step = [[ORKLegacyTimedWalkStep alloc] initWithIdentifier:ORKLegacyTimedWalkTrial1StepIdentifier];
            step.title = [[NSString alloc] initWithFormat:ORKLegacyLocalizedString(@"TIMED_WALK_INSTRUCTION_%@", nil), formattedLength];
            step.text = ORKLegacyLocalizedString(@"TIMED_WALK_INSTRUCTION_TEXT", nil);
            step.spokenInstruction = step.title;
            step.recorderConfigurations = recorderConfigurations;
            step.distanceInMeters = distanceInMeters;
            step.shouldTintImages = YES;
            step.image = [UIImage imageNamed:@"timed-walkingman-outbound" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.stepDuration = timeLimit == 0 ? CGFLOAT_MAX : timeLimit;

            ORKLegacyStepArrayAddStep(steps, step);
        }

        {
            ORKLegacyTimedWalkStep *step = [[ORKLegacyTimedWalkStep alloc] initWithIdentifier:ORKLegacyTimedWalkTurnAroundStepIdentifier];
            step.title = ORKLegacyLocalizedString(@"TIMED_WALK_INSTRUCTION_TURN", nil);
            step.text = ORKLegacyLocalizedString(@"TIMED_WALK_INSTRUCTION_TEXT", nil);
            step.spokenInstruction = step.title;
            step.recorderConfigurations = recorderConfigurations;
            step.distanceInMeters = 1;
            step.shouldTintImages = YES;
            step.image = [UIImage imageNamed:@"turnaround" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.stepDuration = turnAroundTimeLimit == 0 ? CGFLOAT_MAX : turnAroundTimeLimit;

            ORKLegacyStepArrayAddStep(steps, step);
        }

        {
            ORKLegacyTimedWalkStep *step = [[ORKLegacyTimedWalkStep alloc] initWithIdentifier:ORKLegacyTimedWalkTrial2StepIdentifier];
            step.title = [[NSString alloc] initWithFormat:ORKLegacyLocalizedString(@"TIMED_WALK_INSTRUCTION_2", nil), formattedLength];
            step.text = ORKLegacyLocalizedString(@"TIMED_WALK_INSTRUCTION_TEXT", nil);
            step.spokenInstruction = step.title;
            step.recorderConfigurations = recorderConfigurations;
            step.distanceInMeters = distanceInMeters;
            step.shouldTintImages = YES;
            step.image = [UIImage imageNamed:@"timed-walkingman-return" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.stepDuration = timeLimit == 0 ? CGFLOAT_MAX : timeLimit;

            ORKLegacyStepArrayAddStep(steps, step);
        }
    }

    if (!(options & ORKLegacyPredefinedTaskOptionExcludeConclusion)) {
        ORKLegacyInstructionStep *step = [self makeCompletionStep];

        ORKLegacyStepArrayAddStep(steps, step);
    }

    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:identifier steps:steps];
    return task;
}

+ (ORKLegacyOrderedTask *)PSATTaskWithIdentifier:(NSString *)identifier
                    intendedUseDescription:(nullable NSString *)intendedUseDescription
                          presentationMode:(ORKLegacyPSATPresentationMode)presentationMode
                     interStimulusInterval:(NSTimeInterval)interStimulusInterval
                          stimulusDuration:(NSTimeInterval)stimulusDuration
                              seriesLength:(NSInteger)seriesLength
                                   options:(ORKLegacyPredefinedTaskOption)options {
    
    NSMutableArray *steps = [NSMutableArray array];
    NSString *versionTitle = @"";
    NSString *versionDetailText = @"";
    
    if (presentationMode == ORKLegacyPSATPresentationModeAuditory) {
        versionTitle = ORKLegacyLocalizedString(@"PASAT_TITLE", nil);
        versionDetailText = ORKLegacyLocalizedString(@"PASAT_INTRO_TEXT", nil);
    } else if (presentationMode == ORKLegacyPSATPresentationModeVisual) {
        versionTitle = ORKLegacyLocalizedString(@"PVSAT_TITLE", nil);
        versionDetailText = ORKLegacyLocalizedString(@"PVSAT_INTRO_TEXT", nil);
    } else {
        versionTitle = ORKLegacyLocalizedString(@"PAVSAT_TITLE", nil);
        versionDetailText = ORKLegacyLocalizedString(@"PAVSAT_INTRO_TEXT", nil);
    }
    
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction0StepIdentifier];
            step.title = versionTitle;
            step.detailText = versionDetailText;
            step.text = intendedUseDescription;
            step.image = [UIImage imageNamed:@"phonepsat" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction1StepIdentifier];
            step.title = versionTitle;
            step.text = [NSString localizedStringWithFormat:ORKLegacyLocalizedString(@"PSAT_INTRO_TEXT_2_%@", nil), [NSNumberFormatter localizedStringFromNumber:@(interStimulusInterval) numberStyle:NSNumberFormatterDecimalStyle]];
            step.detailText = ORKLegacyLocalizedString(@"PSAT_CALL_TO_ACTION", nil);
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
    }
    
    {
        ORKLegacyCountdownStep *step = [[ORKLegacyCountdownStep alloc] initWithIdentifier:ORKLegacyCountdownStepIdentifier];
        step.stepDuration = 5.0;
        
        ORKLegacyStepArrayAddStep(steps, step);
    }
    
    {
        ORKLegacyPSATStep *step = [[ORKLegacyPSATStep alloc] initWithIdentifier:ORKLegacyPSATStepIdentifier];
        step.title = ORKLegacyLocalizedString(@"PSAT_INITIAL_INSTRUCTION", nil);
        step.stepDuration = (seriesLength + 1) * interStimulusInterval;
        step.presentationMode = presentationMode;
        step.interStimulusInterval = interStimulusInterval;
        step.stimulusDuration = stimulusDuration;
        step.seriesLength = seriesLength;
        
        ORKLegacyStepArrayAddStep(steps, step);
    }
    
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeConclusion)) {
        ORKLegacyInstructionStep *step = [self makeCompletionStep];
        
        ORKLegacyStepArrayAddStep(steps, step);
    }
    
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:identifier steps:[steps copy]];
    
    return task;
}

+ (NSString *)stepIdentifier:(NSString *)stepIdentifier withHandIdentifier:(NSString *)handIdentifier {
    return [NSString stringWithFormat:@"%@.%@", stepIdentifier, handIdentifier];
}

+ (NSMutableArray *)stepsForOneHandTremorTestTaskWithIdentifier:(NSString *)identifier
                                             activeStepDuration:(NSTimeInterval)activeStepDuration
                                              activeTaskOptions:(ORKLegacyTremorActiveTaskOption)activeTaskOptions
                                                       lastHand:(BOOL)lastHand
                                                       leftHand:(BOOL)leftHand
                                                 handIdentifier:(NSString *)handIdentifier
                                                introDetailText:(NSString *)detailText
                                                        options:(ORKLegacyPredefinedTaskOption)options {
    NSMutableArray<ORKLegacyActiveStep *> *steps = [NSMutableArray array];
    NSString *stepFinishedInstruction = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_FINISHED_INSTRUCTION", nil);
    BOOL rightHand = !leftHand && ![handIdentifier isEqualToString:ORKLegacyActiveTaskMostAffectedHandIdentifier];
    
    {
        NSString *stepIdentifier = [self stepIdentifier:ORKLegacyInstruction1StepIdentifier withHandIdentifier:handIdentifier];
        ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:stepIdentifier];
        step.title = ORKLegacyLocalizedString(@"TREMOR_TEST_TITLE", nil);
        
        if ([identifier isEqualToString:ORKLegacyActiveTaskMostAffectedHandIdentifier]) {
            step.text = ORKLegacyLocalizedString(@"TREMOR_TEST_INTRO_2_DEFAULT_TEXT", nil);
            step.detailText = detailText;
        } else {
            if (leftHand) {
                step.text = ORKLegacyLocalizedString(@"TREMOR_TEST_INTRO_2_LEFT_HAND_TEXT", nil);
            } else {
                step.text = ORKLegacyLocalizedString(@"TREMOR_TEST_INTRO_2_RIGHT_HAND_TEXT", nil);
            }
        }
        
        NSString *imageName = leftHand ? @"tremortestLeft" : @"tremortestRight";
        step.image = [UIImage imageNamed:imageName inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
        step.shouldTintImages = YES;
        
        ORKLegacyStepArrayAddStep(steps, step);
    }

    if (!(activeTaskOptions & ORKLegacyTremorActiveTaskOptionExcludeHandInLap)) {
        if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
            NSString *stepIdentifier = [self stepIdentifier:ORKLegacyInstruction2StepIdentifier withHandIdentifier:handIdentifier];
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:stepIdentifier];
            step.title = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_IN_LAP_INTRO", nil);
            step.text = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_INTRO_TEXT", nil);
            step.image = [UIImage imageNamed:@"tremortest3a" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.auxiliaryImage = [UIImage imageNamed:@"tremortest3b" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            if (leftHand) {
                step.title = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_IN_LAP_INTRO_LEFT", nil);
                step.image = [step.image ork_flippedImage:UIImageOrientationUpMirrored];
                step.auxiliaryImage = [step.auxiliaryImage ork_flippedImage:UIImageOrientationUpMirrored];
            } else if (rightHand) {
                step.title = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_IN_LAP_INTRO_RIGHT", nil);
            }
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        {
            NSString *stepIdentifier = [self stepIdentifier:ORKLegacyCountdown1StepIdentifier withHandIdentifier:handIdentifier];
            ORKLegacyCountdownStep *step = [[ORKLegacyCountdownStep alloc] initWithIdentifier:stepIdentifier];
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        {
            NSString *titleFormat = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_IN_LAP_INSTRUCTION_%ld", nil);
            NSString *stepIdentifier = [self stepIdentifier:ORKLegacyTremorTestInLapStepIdentifier withHandIdentifier:handIdentifier];
            ORKLegacyActiveStep *step = [[ORKLegacyActiveStep alloc] initWithIdentifier:stepIdentifier];
            step.recorderConfigurations = @[[[ORKLegacyAccelerometerRecorderConfiguration alloc] initWithIdentifier:@"ac1_acc" frequency:100.0], [[ORKLegacyDeviceMotionRecorderConfiguration alloc] initWithIdentifier:@"ac1_motion" frequency:100.0]];
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
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
    }
    
    if (!(activeTaskOptions & ORKLegacyTremorActiveTaskOptionExcludeHandAtShoulderHeight)) {
        if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
            NSString *stepIdentifier = [self stepIdentifier:ORKLegacyInstruction4StepIdentifier withHandIdentifier:handIdentifier];
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:stepIdentifier];
            step.title = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_EXTEND_ARM_INTRO", nil);
            step.text = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_INTRO_TEXT", nil);
            step.image = [UIImage imageNamed:@"tremortest4a" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.auxiliaryImage = [UIImage imageNamed:@"tremortest4b" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            if (leftHand) {
                step.title = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_EXTEND_ARM_INTRO_LEFT", nil);
                step.image = [step.image ork_flippedImage:UIImageOrientationUpMirrored];
                step.auxiliaryImage = [step.auxiliaryImage ork_flippedImage:UIImageOrientationUpMirrored];
            } else if (rightHand) {
                step.title = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_EXTEND_ARM_INTRO_RIGHT", nil);
            }
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        {
            NSString *stepIdentifier = [self stepIdentifier:ORKLegacyCountdown2StepIdentifier withHandIdentifier:handIdentifier];
            ORKLegacyCountdownStep *step = [[ORKLegacyCountdownStep alloc] initWithIdentifier:stepIdentifier];
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        {
            NSString *titleFormat = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_EXTEND_ARM_INSTRUCTION_%ld", nil);
            NSString *stepIdentifier = [self stepIdentifier:ORKLegacyTremorTestExtendArmStepIdentifier withHandIdentifier:handIdentifier];
            ORKLegacyActiveStep *step = [[ORKLegacyActiveStep alloc] initWithIdentifier:stepIdentifier];
            step.recorderConfigurations = @[[[ORKLegacyAccelerometerRecorderConfiguration alloc] initWithIdentifier:@"ac2_acc" frequency:100.0], [[ORKLegacyDeviceMotionRecorderConfiguration alloc] initWithIdentifier:@"ac2_motion" frequency:100.0]];
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
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
    }
    
    if (!(activeTaskOptions & ORKLegacyTremorActiveTaskOptionExcludeHandAtShoulderHeightElbowBent)) {
        if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
            NSString *stepIdentifier = [self stepIdentifier:ORKLegacyInstruction5StepIdentifier withHandIdentifier:handIdentifier];
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:stepIdentifier];
            step.title = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_BEND_ARM_INTRO", nil);
            step.text = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_INTRO_TEXT", nil);
            step.image = [UIImage imageNamed:@"tremortest5a" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.auxiliaryImage = [UIImage imageNamed:@"tremortest5b" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            if (leftHand) {
                step.title = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_BEND_ARM_INTRO_LEFT", nil);
                step.image = [step.image ork_flippedImage:UIImageOrientationUpMirrored];
                step.auxiliaryImage = [step.auxiliaryImage ork_flippedImage:UIImageOrientationUpMirrored];
            } else if (rightHand) {
                step.title = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_BEND_ARM_INTRO_RIGHT", nil);
            }
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        {
            NSString *stepIdentifier = [self stepIdentifier:ORKLegacyCountdown3StepIdentifier withHandIdentifier:handIdentifier];
            ORKLegacyCountdownStep *step = [[ORKLegacyCountdownStep alloc] initWithIdentifier:stepIdentifier];
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        {
            NSString *titleFormat = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_BEND_ARM_INSTRUCTION_%ld", nil);
            NSString *stepIdentifier = [self stepIdentifier:ORKLegacyTremorTestBendArmStepIdentifier withHandIdentifier:handIdentifier];
            ORKLegacyActiveStep *step = [[ORKLegacyActiveStep alloc] initWithIdentifier:stepIdentifier];
            step.recorderConfigurations = @[[[ORKLegacyAccelerometerRecorderConfiguration alloc] initWithIdentifier:@"ac3_acc" frequency:100.0], [[ORKLegacyDeviceMotionRecorderConfiguration alloc] initWithIdentifier:@"ac3_motion" frequency:100.0]];
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
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
    }
    
    if (!(activeTaskOptions & ORKLegacyTremorActiveTaskOptionExcludeHandToNose)) {
        if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
            NSString *stepIdentifier = [self stepIdentifier:ORKLegacyInstruction6StepIdentifier withHandIdentifier:handIdentifier];
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:stepIdentifier];
            step.title = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_TOUCH_NOSE_INTRO", nil);
            step.text = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_INTRO_TEXT", nil);
            step.image = [UIImage imageNamed:@"tremortest6a" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.auxiliaryImage = [UIImage imageNamed:@"tremortest6b" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            if (leftHand) {
                step.title = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_TOUCH_NOSE_INTRO_LEFT", nil);
                step.image = [step.image ork_flippedImage:UIImageOrientationUpMirrored];
                step.auxiliaryImage = [step.auxiliaryImage ork_flippedImage:UIImageOrientationUpMirrored];
            } else if (rightHand) {
                step.title = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_TOUCH_NOSE_INTRO_RIGHT", nil);
            }
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        {
            NSString *stepIdentifier = [self stepIdentifier:ORKLegacyCountdown4StepIdentifier withHandIdentifier:handIdentifier];
            ORKLegacyCountdownStep *step = [[ORKLegacyCountdownStep alloc] initWithIdentifier:stepIdentifier];
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        {
            NSString *titleFormat = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_TOUCH_NOSE_INSTRUCTION_%ld", nil);
            NSString *stepIdentifier = [self stepIdentifier:ORKLegacyTremorTestTouchNoseStepIdentifier withHandIdentifier:handIdentifier];
            ORKLegacyActiveStep *step = [[ORKLegacyActiveStep alloc] initWithIdentifier:stepIdentifier];
            step.recorderConfigurations = @[[[ORKLegacyAccelerometerRecorderConfiguration alloc] initWithIdentifier:@"ac4_acc" frequency:100.0], [[ORKLegacyDeviceMotionRecorderConfiguration alloc] initWithIdentifier:@"ac4_motion" frequency:100.0]];
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
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
    }
    
    if (!(activeTaskOptions & ORKLegacyTremorActiveTaskOptionExcludeQueenWave)) {
        if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
            NSString *stepIdentifier = [self stepIdentifier:ORKLegacyInstruction7StepIdentifier withHandIdentifier:handIdentifier];
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:stepIdentifier];
            step.title = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_TURN_WRIST_INTRO", nil);
            step.text = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_INTRO_TEXT", nil);
            step.image = [UIImage imageNamed:@"tremortest7" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            if (leftHand) {
                step.title = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_TURN_WRIST_INTRO_LEFT", nil);
                step.image = [step.image ork_flippedImage:UIImageOrientationUpMirrored];
            } else if (rightHand) {
                step.title = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_TURN_WRIST_INTRO_RIGHT", nil);
            }
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        {
            NSString *stepIdentifier = [self stepIdentifier:ORKLegacyCountdown5StepIdentifier withHandIdentifier:handIdentifier];
            ORKLegacyCountdownStep *step = [[ORKLegacyCountdownStep alloc] initWithIdentifier:stepIdentifier];
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        {
            NSString *titleFormat = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_TURN_WRIST_INSTRUCTION_%ld", nil);
            NSString *stepIdentifier = [self stepIdentifier:ORKLegacyTremorTestTurnWristStepIdentifier withHandIdentifier:handIdentifier];
            ORKLegacyActiveStep *step = [[ORKLegacyActiveStep alloc] initWithIdentifier:stepIdentifier];
            step.recorderConfigurations = @[[[ORKLegacyAccelerometerRecorderConfiguration alloc] initWithIdentifier:@"ac5_acc" frequency:100.0], [[ORKLegacyDeviceMotionRecorderConfiguration alloc] initWithIdentifier:@"ac5_motion" frequency:100.0]];
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
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
    }
    
    // fix the spoken instruction on the last included step, depending on which hand we're on
    ORKLegacyActiveStep *lastStep = (ORKLegacyActiveStep *)[steps lastObject];
    if (lastHand) {
        lastStep.finishedSpokenInstruction = ORKLegacyLocalizedString(@"TREMOR_TEST_COMPLETED_INSTRUCTION", nil);
    } else if (leftHand) {
        lastStep.finishedSpokenInstruction = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_SWITCH_HANDS_RIGHT_INSTRUCTION", nil);
    } else {
        lastStep.finishedSpokenInstruction = ORKLegacyLocalizedString(@"TREMOR_TEST_ACTIVE_STEP_SWITCH_HANDS_LEFT_INSTRUCTION", nil);
    }
    
    return steps;
}

+ (ORKLegacyNavigableOrderedTask *)tremorTestTaskWithIdentifier:(NSString *)identifier
                                   intendedUseDescription:(nullable NSString *)intendedUseDescription
                                       activeStepDuration:(NSTimeInterval)activeStepDuration
                                        activeTaskOptions:(ORKLegacyTremorActiveTaskOption)activeTaskOptions
                                              handOptions:(ORKLegacyPredefinedTaskHandOption)handOptions
                                                  options:(ORKLegacyPredefinedTaskOption)options {
    
    NSMutableArray<__kindof ORKLegacyStep *> *steps = [NSMutableArray array];
    // coin toss for which hand first (in case we're doing both)
    BOOL leftFirstIfDoingBoth = arc4random_uniform(2) == 1;
    BOOL doingBoth = ((handOptions & ORKLegacyPredefinedTaskHandOptionLeft) && (handOptions & ORKLegacyPredefinedTaskHandOptionRight));
    BOOL firstIsLeft = (leftFirstIfDoingBoth && doingBoth) || (!doingBoth && (handOptions & ORKLegacyPredefinedTaskHandOptionLeft));
    
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction0StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"TREMOR_TEST_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = ORKLegacyLocalizedString(@"TREMOR_TEST_INTRO_1_DETAIL", nil);
            step.image = [UIImage imageNamed:@"tremortest1" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            if (firstIsLeft) {
                step.image = [step.image ork_flippedImage:UIImageOrientationUpMirrored];
            }
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
    }
    
    // Build the string for the detail texts
    NSArray<NSString *>*detailStringForNumberOfTasks = @[
                                                         ORKLegacyLocalizedString(@"TREMOR_TEST_INTRO_2_DETAIL_1_TASK", nil),
                                                         ORKLegacyLocalizedString(@"TREMOR_TEST_INTRO_2_DETAIL_2_TASK", nil),
                                                         ORKLegacyLocalizedString(@"TREMOR_TEST_INTRO_2_DETAIL_3_TASK", nil),
                                                         ORKLegacyLocalizedString(@"TREMOR_TEST_INTRO_2_DETAIL_4_TASK", nil),
                                                         ORKLegacyLocalizedString(@"TREMOR_TEST_INTRO_2_DETAIL_5_TASK", nil)
                                                         ];
    
    // start with the count for all the tasks, then subtract one for each excluded task flag
    static const NSInteger allTasks = 5; // hold in lap, outstretched arm, elbow bent, repeatedly touching nose, queen wave
    NSInteger actualTasksIndex = allTasks - 1;
    for (NSInteger i = 0; i < allTasks; ++i) {
        if (activeTaskOptions & (1 << i)) {
            actualTasksIndex--;
        }
    }
    
    NSString *detailFormat = doingBoth ? ORKLegacyLocalizedString(@"TREMOR_TEST_SKIP_QUESTION_BOTH_HANDS_%@", nil) : ORKLegacyLocalizedString(@"TREMOR_TEST_INTRO_2_DETAIL_DEFAULT_%@", nil);
    NSString *detailText = [NSString localizedStringWithFormat:detailFormat, detailStringForNumberOfTasks[actualTasksIndex]];
    
    if (doingBoth) {
        // If doing both hands then ask the user if they need to skip one of the hands
        ORKLegacyTextChoice *skipRight = [ORKLegacyTextChoice choiceWithText:ORKLegacyLocalizedString(@"TREMOR_SKIP_RIGHT_HAND", nil)
                                                          value:ORKLegacyActiveTaskRightHandIdentifier];
        ORKLegacyTextChoice *skipLeft = [ORKLegacyTextChoice choiceWithText:ORKLegacyLocalizedString(@"TREMOR_SKIP_LEFT_HAND", nil)
                                                          value:ORKLegacyActiveTaskLeftHandIdentifier];
        ORKLegacyTextChoice *skipNeither = [ORKLegacyTextChoice choiceWithText:ORKLegacyLocalizedString(@"TREMOR_SKIP_NEITHER", nil)
                                                             value:@""];

        ORKLegacyAnswerFormat *answerFormat = [ORKLegacyAnswerFormat choiceAnswerFormatWithStyle:ORKLegacyChoiceAnswerStyleSingleChoice
                                                                         textChoices:@[skipRight, skipLeft, skipNeither]];
        ORKLegacyQuestionStep *step = [ORKLegacyQuestionStep questionStepWithIdentifier:ORKLegacyActiveTaskSkipHandStepIdentifier
                                                                      title:ORKLegacyLocalizedString(@"TREMOR_TEST_TITLE", nil)
                                                                       text:detailText
                                                                     answer:answerFormat];
        step.optional = NO;
        
        ORKLegacyStepArrayAddStep(steps, step);
    }
    
    // right or most-affected hand
    NSArray<__kindof ORKLegacyStep *> *rightSteps = nil;
    if (handOptions == ORKLegacyPredefinedTaskHandOptionUnspecified) {
        rightSteps = [self stepsForOneHandTremorTestTaskWithIdentifier:identifier
                                                    activeStepDuration:activeStepDuration
                                                     activeTaskOptions:activeTaskOptions
                                                              lastHand:YES
                                                              leftHand:NO
                                                        handIdentifier:ORKLegacyActiveTaskMostAffectedHandIdentifier
                                                       introDetailText:detailText
                                                               options:options];
    } else if (handOptions & ORKLegacyPredefinedTaskHandOptionRight) {
        rightSteps = [self stepsForOneHandTremorTestTaskWithIdentifier:identifier
                                                    activeStepDuration:activeStepDuration
                                                     activeTaskOptions:activeTaskOptions
                                                              lastHand:firstIsLeft
                                                              leftHand:NO
                                                        handIdentifier:ORKLegacyActiveTaskRightHandIdentifier
                                                       introDetailText:nil
                                                               options:options];
    }
    
    // left hand
    NSArray<__kindof ORKLegacyStep *> *leftSteps = nil;
    if (handOptions & ORKLegacyPredefinedTaskHandOptionLeft) {
        leftSteps = [self stepsForOneHandTremorTestTaskWithIdentifier:identifier
                                                   activeStepDuration:activeStepDuration
                                                    activeTaskOptions:activeTaskOptions
                                                             lastHand:!firstIsLeft || !(handOptions & ORKLegacyPredefinedTaskHandOptionRight)
                                                             leftHand:YES
                                                       handIdentifier:ORKLegacyActiveTaskLeftHandIdentifier
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
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeConclusion)) {
        hasCompletionStep = YES;
        ORKLegacyCompletionStep *step = [self makeCompletionStep];
        
        ORKLegacyStepArrayAddStep(steps, step);
    }

    ORKLegacyNavigableOrderedTask *task = [[ORKLegacyNavigableOrderedTask alloc] initWithIdentifier:identifier steps:steps];
    
    if (doingBoth) {
        // Setup rules for skipping all the steps in either the left or right hand if called upon to do so.
        ORKLegacyResultSelector *resultSelector = [ORKLegacyResultSelector selectorWithStepIdentifier:ORKLegacyActiveTaskSkipHandStepIdentifier
                                                                         resultIdentifier:ORKLegacyActiveTaskSkipHandStepIdentifier];
        NSPredicate *predicateRight = [ORKLegacyResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector expectedAnswerValue:ORKLegacyActiveTaskRightHandIdentifier];
        NSPredicate *predicateLeft = [ORKLegacyResultPredicate predicateForChoiceQuestionResultWithResultSelector:resultSelector expectedAnswerValue:ORKLegacyActiveTaskLeftHandIdentifier];
        
        // Setup rule for skipping first hand
        NSString *secondHandIdentifier = firstIsLeft ? [[rightSteps firstObject] identifier] : [[leftSteps firstObject] identifier];
        NSPredicate *firstPredicate = firstIsLeft ? predicateLeft : predicateRight;
        ORKLegacyStepNavigationRule *skipFirst = [[ORKLegacyPredicateStepNavigationRule alloc] initWithResultPredicates:@[firstPredicate]
                                                                                 destinationStepIdentifiers:@[secondHandIdentifier]];
        [task setNavigationRule:skipFirst forTriggerStepIdentifier:ORKLegacyActiveTaskSkipHandStepIdentifier];
        
        // Setup rule for skipping the second hand
        NSString *triggerIdentifier = firstIsLeft ? [[leftSteps lastObject] identifier] : [[rightSteps lastObject] identifier];
        NSString *conclusionIdentifier = hasCompletionStep ? [[steps lastObject] identifier] : ORKLegacyNullStepIdentifier;
        NSPredicate *secondPredicate = firstIsLeft ? predicateRight : predicateLeft;
        ORKLegacyStepNavigationRule *skipSecond = [[ORKLegacyPredicateStepNavigationRule alloc] initWithResultPredicates:@[secondPredicate]
                                                                                  destinationStepIdentifiers:@[conclusionIdentifier]];
        [task setNavigationRule:skipSecond forTriggerStepIdentifier:triggerIdentifier];
        
        // Setup step modifier to change the finished spoken step if skipping the second hand
        NSString *key = NSStringFromSelector(@selector(finishedSpokenInstruction));
        NSString *value = ORKLegacyLocalizedString(@"TREMOR_TEST_COMPLETED_INSTRUCTION", nil);
        ORKLegacyStepModifier *stepModifier = [[ORKLegacyKeyValueStepModifier alloc] initWithResultPredicate:secondPredicate
                                                                                     keyValueMap:@{key: value}];
        [task setStepModifier:stepModifier forStepIdentifier:triggerIdentifier];
    }
    
    return task;
}

+ (ORKLegacyOrderedTask *)trailmakingTaskWithIdentifier:(NSString *)identifier
                           intendedUseDescription:(nullable NSString *)intendedUseDescription
                           trailmakingInstruction:(nullable NSString *)trailmakingInstruction
                                        trailType:(ORKLegacyTrailMakingTypeIdentifier)trailType
                                          options:(ORKLegacyPredefinedTaskOption)options {
    
    NSArray *supportedTypes = @[ORKLegacyTrailMakingTypeIdentifierA, ORKLegacyTrailMakingTypeIdentifierB];
    NSAssert1([supportedTypes containsObject:trailType], @"Trail type %@ is not supported.", trailType);
    
    NSMutableArray<__kindof ORKLegacyStep *> *steps = [NSMutableArray array];
    
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction0StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"TRAILMAKING_TASK_TITLE", nil);
            step.text = intendedUseDescription;
            step.detailText = ORKLegacyLocalizedString(@"TRAILMAKING_INTENDED_USE", nil);
            step.image = [UIImage imageNamed:@"trailmaking" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction1StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"TRAILMAKING_TASK_TITLE", nil);
            if ([trailType isEqualToString:ORKLegacyTrailMakingTypeIdentifierA]) {
                step.detailText = ORKLegacyLocalizedString(@"TRAILMAKING_INTENDED_USE2_A", nil);
            } else {
                step.detailText = ORKLegacyLocalizedString(@"TRAILMAKING_INTENDED_USE2_B", nil);
            }
            step.image = [UIImage imageNamed:@"trailmaking" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction2StepIdentifier];
            step.title = ORKLegacyLocalizedString(@"TRAILMAKING_TASK_TITLE", nil);
            step.text = trailmakingInstruction ? : ORKLegacyLocalizedString(@"TRAILMAKING_INTRO_TEXT",nil);
            step.detailText = ORKLegacyLocalizedString(@"TRAILMAKING_CALL_TO_ACTION", nil);
            step.image = [UIImage imageNamed:@"trailmaking" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
    }
    
    {
        ORKLegacyCountdownStep *step = [[ORKLegacyCountdownStep alloc] initWithIdentifier:ORKLegacyCountdownStepIdentifier];
        step.stepDuration = 3.0;
        
        ORKLegacyStepArrayAddStep(steps, step);
    }
    
    {
        ORKLegacyTrailmakingStep *step = [[ORKLegacyTrailmakingStep alloc] initWithIdentifier:ORKLegacyTrailmakingStepIdentifier];
        step.trailType = trailType;
        
        ORKLegacyStepArrayAddStep(steps, step);
    }
    
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeConclusion)) {
        ORKLegacyInstructionStep *step = [self makeCompletionStep];
        
        ORKLegacyStepArrayAddStep(steps, step);
    }

    
    ORKLegacyOrderedTask *task = [[ORKLegacyOrderedTask alloc] initWithIdentifier:identifier steps:steps];
    
    return task;
}

@end
