/*
 Copyright (c) 2015-2016, Ricardo Sánchez-Sáez.
 
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


#import "RK1NavigableOrderedTask.h"

#import "RK1OrderedTask_Private.h"
#import "RK1Result.h"
#import "RK1Step_Private.h"
#import "RK1StepNavigationRule.h"

#import "RK1Helpers_Internal.h"

#import "RK1HolePegTestPlaceStep.h"
#import "RK1HolePegTestRemoveStep.h"
#import "RK1InstructionStep.h"
#import "RK1OrderedTask_Private.h"
#import "RK1CompletionStep.h"


@implementation RK1NavigableOrderedTask {
    NSMutableDictionary<NSString *, RK1StepNavigationRule *> *_stepNavigationRules;
    NSMutableDictionary<NSString *, RK1SkipStepNavigationRule *> *_skipStepNavigationRules;
    NSMutableDictionary<NSString *, RK1StepModifier *> *_stepModifiers;
}

- (instancetype)initWithIdentifier:(NSString *)identifier steps:(NSArray<RK1Step *> *)steps {
    self = [super initWithIdentifier:identifier steps:steps];
    if (self) {
        _stepNavigationRules = nil;
        _skipStepNavigationRules = nil;
        _shouldReportProgress = NO;
    }
    return self;
}

- (void)setNavigationRule:(RK1StepNavigationRule *)stepNavigationRule forTriggerStepIdentifier:(NSString *)triggerStepIdentifier {
    RK1ThrowInvalidArgumentExceptionIfNil(stepNavigationRule);
    RK1ThrowInvalidArgumentExceptionIfNil(triggerStepIdentifier);
    
    if (!_stepNavigationRules) {
        _stepNavigationRules = [NSMutableDictionary new];
    }
    _stepNavigationRules[triggerStepIdentifier] = stepNavigationRule;
}

- (RK1StepNavigationRule *)navigationRuleForTriggerStepIdentifier:(NSString *)triggerStepIdentifier {
    RK1ThrowInvalidArgumentExceptionIfNil(triggerStepIdentifier);

    return _stepNavigationRules[triggerStepIdentifier];
}

- (void)removeNavigationRuleForTriggerStepIdentifier:(NSString *)triggerStepIdentifier {
    RK1ThrowInvalidArgumentExceptionIfNil(triggerStepIdentifier);
    
    [_stepNavigationRules removeObjectForKey:triggerStepIdentifier];
}

- (NSDictionary<NSString *, RK1StepNavigationRule *> *)stepNavigationRules {
    if (!_stepNavigationRules) {
        return @{};
    }
    return [_stepNavigationRules copy];
}

- (void)setSkipNavigationRule:(RK1SkipStepNavigationRule *)skipStepNavigationRule forStepIdentifier:(NSString *)stepIdentifier {
    RK1ThrowInvalidArgumentExceptionIfNil(skipStepNavigationRule);
    RK1ThrowInvalidArgumentExceptionIfNil(stepIdentifier);
    
    if (!_skipStepNavigationRules) {
        _skipStepNavigationRules = [NSMutableDictionary new];
    }
    _skipStepNavigationRules[stepIdentifier] = skipStepNavigationRule;
}

- (RK1SkipStepNavigationRule *)skipNavigationRuleForStepIdentifier:(NSString *)stepIdentifier {
    RK1ThrowInvalidArgumentExceptionIfNil(stepIdentifier);
    
    return _skipStepNavigationRules[stepIdentifier];
}

- (void)removeSkipNavigationRuleForStepIdentifier:(NSString *)stepIdentifier {
    RK1ThrowInvalidArgumentExceptionIfNil(stepIdentifier);
    
    [_skipStepNavigationRules removeObjectForKey:stepIdentifier];
}

- (NSDictionary<NSString *, RK1SkipStepNavigationRule *> *)skipStepNavigationRules {
    if (!_skipStepNavigationRules) {
        return @{};
    }
    return [_skipStepNavigationRules copy];
}

- (void)setStepModifier:(RK1StepModifier *)stepModifier forStepIdentifier:(NSString *)stepIdentifier {
    RK1ThrowInvalidArgumentExceptionIfNil(stepModifier);
    RK1ThrowInvalidArgumentExceptionIfNil(stepIdentifier);
    
    if (!_stepModifiers) {
        _stepModifiers = [NSMutableDictionary new];
    }
    _stepModifiers[stepIdentifier] = stepModifier;
}

- (RK1StepModifier *)stepModifierForStepIdentifier:(NSString *)stepIdentifier {
    RK1ThrowInvalidArgumentExceptionIfNil(stepIdentifier);
    return _stepModifiers[stepIdentifier];
}

- (void)removeStepModifierForStepIdentifier:(NSString *)stepIdentifier {
    RK1ThrowInvalidArgumentExceptionIfNil(stepIdentifier);
    
    [_stepModifiers removeObjectForKey:stepIdentifier];
}

- (NSDictionary<NSString *, RK1StepModifier *> *)stepModifiers {
    if (!_stepModifiers) {
        return @{};
    }
    return [_stepModifiers copy];
}

- (RK1Step *)stepAfterStep:(RK1Step *)step withResult:(RK1TaskResult *)result {
    RK1Step *nextStep = nil;
    RK1StepNavigationRule *navigationRule = _stepNavigationRules[step.identifier];
    NSString *nextStepIdentifier = [navigationRule identifierForDestinationStepWithTaskResult:result];
    if (![nextStepIdentifier isEqualToString:RK1NullStepIdentifier]) { // If RK1NullStepIdentifier, return nil to end task
        if (nextStepIdentifier) {
            nextStep = [self stepWithIdentifier:nextStepIdentifier];
            
            if (step && nextStep && [self indexOfStep:nextStep] <= [self indexOfStep:step]) {
                RK1_Log_Warning(@"Index of next step (\"%@\") is equal or lower than index of current step (\"%@\") in ordered task. Make sure this is intentional as you could loop idefinitely without appropriate navigation rules. Also please note that you'll get duplicate result entries each time you loop over the same step.", nextStep.identifier, step.identifier);
            }
        } else {
            nextStep = [super stepAfterStep:step withResult:result];
        }
        
        RK1SkipStepNavigationRule *skipNavigationRule = _skipStepNavigationRules[nextStep.identifier];
        if ([skipNavigationRule stepShouldSkipWithTaskResult:result]) {
            return [self stepAfterStep:nextStep withResult:result];
        }
    }
    
    if (nextStep != nil) {
        RK1StepModifier *stepModifier = [self stepModifierForStepIdentifier:nextStep.identifier];
        [stepModifier modifyStep:nextStep withTaskResult:result];
    }
    
    return nextStep;
}

- (RK1Step *)stepBeforeStep:(RK1Step *)step withResult:(RK1TaskResult *)result {
    RK1Step *previousStep = nil;
    __block NSInteger indexOfCurrentStepResult = -1;
    [result.results enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(RK1Result *result, NSUInteger idx, BOOL *stop) {
        if ([result.identifier isEqualToString:step.identifier]) {
            indexOfCurrentStepResult = idx;
            *stop = YES;
        }
    }];
    if (indexOfCurrentStepResult != -1 && indexOfCurrentStepResult != 0) {
        previousStep = [self stepWithIdentifier:result.results[indexOfCurrentStepResult - 1].identifier];
    }
    return previousStep;
}

// Assume RK1NavigableOrderedTask doesn't have a linear order unless user specifically overrides
- (RK1TaskProgress)progressOfCurrentStep:(RK1Step *)step withResult:(RK1TaskResult *)result {
    if (_shouldReportProgress) {
        return [super progressOfCurrentStep:step withResult:result];
    }

    return RK1TaskProgressMake(0, 0);
}

#pragma mark Serialization private methods

// These methods should only be used by serialization tests (the stepNavigationRules and skipStepNavigationRules properties are published as readonly)
- (void)setStepNavigationRules:(NSDictionary *)stepNavigationRules {
    _stepNavigationRules = [stepNavigationRules mutableCopy];
}

- (void)setSkipStepNavigationRules:(NSDictionary *)skipStepNavigationRules {
    _skipStepNavigationRules = [skipStepNavigationRules mutableCopy];
}

#pragma mark NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        RK1_DECODE_OBJ_MUTABLE_DICTIONARY(aDecoder, stepNavigationRules, NSString, RK1StepNavigationRule);
        RK1_DECODE_OBJ_MUTABLE_DICTIONARY(aDecoder, skipStepNavigationRules, NSString, RK1SkipStepNavigationRule);
        RK1_DECODE_OBJ_MUTABLE_DICTIONARY(aDecoder, stepModifiers, NSString, RK1StepModifier);
        RK1_DECODE_BOOL(aDecoder, shouldReportProgress);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    
    RK1_ENCODE_OBJ(aCoder, stepNavigationRules);
    RK1_ENCODE_OBJ(aCoder, skipStepNavigationRules);
    RK1_ENCODE_OBJ(aCoder, stepModifiers);
    RK1_ENCODE_BOOL(aCoder, shouldReportProgress);
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    __typeof(self) task = [super copyWithZone:zone];
    task->_stepNavigationRules = RK1MutableDictionaryCopyObjects(_stepNavigationRules);
    task->_skipStepNavigationRules = RK1MutableDictionaryCopyObjects(_skipStepNavigationRules);
    task->_stepModifiers = RK1MutableDictionaryCopyObjects(_stepModifiers);
    task->_shouldReportProgress = _shouldReportProgress;
    return task;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return isParentSame
    && RK1EqualObjects(self.stepNavigationRules, castObject.stepNavigationRules)
    && RK1EqualObjects(self.skipStepNavigationRules, castObject.skipStepNavigationRules)
    && RK1EqualObjects(self.stepModifiers, castObject.stepModifiers)
    && self.shouldReportProgress == castObject.shouldReportProgress;
}

- (NSUInteger)hash {
    return super.hash ^ _stepNavigationRules.hash ^ _skipStepNavigationRules.hash ^ _stepModifiers.hash ^ (_shouldReportProgress ? 0xf : 0x0);
}

#pragma mark - Predefined

NSString *const RK1HolePegTestDominantPlaceStepIdentifier = @"hole.peg.test.dominant.place";
NSString *const RK1HolePegTestDominantRemoveStepIdentifier = @"hole.peg.test.dominant.remove";
NSString *const RK1HolePegTestNonDominantPlaceStepIdentifier = @"hole.peg.test.non.dominant.place";
NSString *const RK1HolePegTestNonDominantRemoveStepIdentifier = @"hole.peg.test.non.dominant.remove";

+ (RK1NavigableOrderedTask *)holePegTestTaskWithIdentifier:(NSString *)identifier
                                    intendedUseDescription:(nullable NSString *)intendedUseDescription
                                              dominantHand:(RK1BodySagittal)dominantHand
                                              numberOfPegs:(int)numberOfPegs
                                                 threshold:(double)threshold
                                                   rotated:(BOOL)rotated
                                                 timeLimit:(NSTimeInterval)timeLimit
                                                   options:(RK1PredefinedTaskOption)options {
    
    NSMutableArray *steps = [NSMutableArray array];
    BOOL dominantHandLeft = (dominantHand == RK1BodySagittalLeft);
    NSTimeInterval stepDuration = (timeLimit == 0) ? CGFLOAT_MAX : timeLimit;
    
    if (!(options & RK1PredefinedTaskOptionExcludeInstructions)) {
        NSString *pegs = [NSNumberFormatter localizedStringFromNumber:@(numberOfPegs) numberStyle:NSNumberFormatterNoStyle];
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction0StepIdentifier];
            step.title = [[NSString alloc] initWithFormat:RK1LocalizedString(@"HOLE_PEG_TEST_TITLE_%@", nil), pegs];
            step.text = intendedUseDescription;
            step.detailText = [[NSString alloc] initWithFormat:RK1LocalizedString(@"HOLE_PEG_TEST_INTRO_TEXT_%@", nil), pegs];
            step.image = [UIImage imageNamed:@"phoneholepeg" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
        
        {
            RK1InstructionStep *step = [[RK1InstructionStep alloc] initWithIdentifier:RK1Instruction1StepIdentifier];
            step.title = [[NSString alloc] initWithFormat:RK1LocalizedString(@"HOLE_PEG_TEST_TITLE_%@", nil), pegs];
            step.text = dominantHandLeft ? [[NSString alloc] initWithFormat:RK1LocalizedString(@"HOLE_PEG_TEST_INTRO_TEXT_2_LEFT_HAND_FIRST_%@", nil), pegs, pegs] : [[NSString alloc] initWithFormat:RK1LocalizedString(@"HOLE_PEG_TEST_INTRO_TEXT_2_RIGHT_HAND_FIRST_%@", nil), pegs, pegs];
            step.detailText = RK1LocalizedString(@"HOLE_PEG_TEST_CALL_TO_ACTION", nil);
            UIImage *image1 = [UIImage imageNamed:@"holepegtest1" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            UIImage *image2 = [UIImage imageNamed:@"holepegtest2" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            UIImage *image3 = [UIImage imageNamed:@"holepegtest3" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            UIImage *image4 = [UIImage imageNamed:@"holepegtest4" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            UIImage *image5 = [UIImage imageNamed:@"holepegtest5" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            UIImage *image6 = [UIImage imageNamed:@"holepegtest6" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.image = [UIImage animatedImageWithImages:@[image1, image2, image3, image4, image5, image6] duration:4];
            step.shouldTintImages = YES;
            
            RK1StepArrayAddStep(steps, step);
        }
    }
    
    {
        {
            RK1HolePegTestPlaceStep *step = [[RK1HolePegTestPlaceStep alloc] initWithIdentifier:RK1HolePegTestDominantPlaceStepIdentifier];
            step.title = dominantHandLeft ? RK1LocalizedString(@"HOLE_PEG_TEST_PLACE_INSTRUCTION_LEFT_HAND", nil) : RK1LocalizedString(@"HOLE_PEG_TEST_PLACE_INSTRUCTION_RIGHT_HAND", nil);
            step.text = RK1LocalizedString(@"HOLE_PEG_TEST_TEXT", nil);
            step.spokenInstruction = step.title;
            step.movingDirection = dominantHand;
            step.dominantHandTested = YES;
            step.numberOfPegs = numberOfPegs;
            step.threshold = threshold;
            step.rotated = rotated;
            step.shouldTintImages = YES;
            step.stepDuration = stepDuration;
            
            RK1StepArrayAddStep(steps, step);
        }
        
        {
            RK1HolePegTestRemoveStep *step = [[RK1HolePegTestRemoveStep alloc] initWithIdentifier:RK1HolePegTestDominantRemoveStepIdentifier];
            step.title = dominantHandLeft ? RK1LocalizedString(@"HOLE_PEG_TEST_REMOVE_INSTRUCTION_LEFT_HAND", nil) : RK1LocalizedString(@"HOLE_PEG_TEST_REMOVE_INSTRUCTION_RIGHT_HAND", nil);
            step.text = RK1LocalizedString(@"HOLE_PEG_TEST_TEXT", nil);
            step.spokenInstruction = step.title;
            step.movingDirection = (dominantHand == RK1BodySagittalLeft) ? RK1BodySagittalRight : RK1BodySagittalLeft;
            step.dominantHandTested = YES;
            step.numberOfPegs = numberOfPegs;
            step.threshold = threshold;
            step.shouldTintImages = YES;
            step.stepDuration = stepDuration;
            
            RK1StepArrayAddStep(steps, step);
        }
        
        {
            RK1HolePegTestPlaceStep *step = [[RK1HolePegTestPlaceStep alloc] initWithIdentifier:RK1HolePegTestNonDominantPlaceStepIdentifier];
            step.title = dominantHandLeft ? RK1LocalizedString(@"HOLE_PEG_TEST_PLACE_INSTRUCTION_RIGHT_HAND", nil) : RK1LocalizedString(@"HOLE_PEG_TEST_PLACE_INSTRUCTION_LEFT_HAND", nil);
            step.text = RK1LocalizedString(@"HOLE_PEG_TEST_TEXT", nil);
            step.spokenInstruction = step.title;
            step.movingDirection = (dominantHand == RK1BodySagittalLeft) ? RK1BodySagittalRight : RK1BodySagittalLeft;
            step.dominantHandTested = NO;
            step.numberOfPegs = numberOfPegs;
            step.threshold = threshold;
            step.rotated = rotated;
            step.shouldTintImages = YES;
            step.stepDuration = stepDuration;
            
            RK1StepArrayAddStep(steps, step);
        }
        
        {
            RK1HolePegTestRemoveStep *step = [[RK1HolePegTestRemoveStep alloc] initWithIdentifier:RK1HolePegTestNonDominantRemoveStepIdentifier];
            step.title = dominantHandLeft ? RK1LocalizedString(@"HOLE_PEG_TEST_REMOVE_INSTRUCTION_RIGHT_HAND", nil) : RK1LocalizedString(@"HOLE_PEG_TEST_REMOVE_INSTRUCTION_LEFT_HAND", nil);
            step.text = RK1LocalizedString(@"HOLE_PEG_TEST_TEXT", nil);
            step.spokenInstruction = step.title;
            step.movingDirection = dominantHand;
            step.dominantHandTested = NO;
            step.numberOfPegs = numberOfPegs;
            step.threshold = threshold;
            step.shouldTintImages = YES;
            step.stepDuration = stepDuration;
            
            RK1StepArrayAddStep(steps, step);
        }
    }
    
    if (!(options & RK1PredefinedTaskOptionExcludeConclusion)) {
        RK1CompletionStep *step = [self makeCompletionStep];
        RK1StepArrayAddStep(steps, step);
    }
    
    
    // The task is actually dynamic. The direct navigation rules are used for skipping the peg
    // removal steps if the user doesn't succeed in placing all the pegs in the allotted time
    // (the rules are removed from `RK1HolePegTestPlaceStepViewController` if she succeeds).
    RK1NavigableOrderedTask *task = [[RK1NavigableOrderedTask alloc] initWithIdentifier:identifier steps:steps];
    
    RK1StepNavigationRule *navigationRule = [[RK1DirectStepNavigationRule alloc] initWithDestinationStepIdentifier:RK1HolePegTestNonDominantPlaceStepIdentifier];
    [task setNavigationRule:navigationRule forTriggerStepIdentifier:RK1HolePegTestDominantPlaceStepIdentifier];
    navigationRule = [[RK1DirectStepNavigationRule alloc] initWithDestinationStepIdentifier:RK1ConclusionStepIdentifier];
    [task setNavigationRule:navigationRule forTriggerStepIdentifier:RK1HolePegTestNonDominantPlaceStepIdentifier];
    
    return task;
}

@end
