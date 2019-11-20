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


#import "ORK1NavigableOrderedTask.h"

#import "ORK1OrderedTask_Private.h"
#import "ORK1Result.h"
#import "ORK1Step_Private.h"
#import "ORK1StepNavigationRule.h"

#import "ORK1Helpers_Internal.h"

#import "ORK1HolePegTestPlaceStep.h"
#import "ORK1HolePegTestRemoveStep.h"
#import "ORK1InstructionStep.h"
#import "ORK1OrderedTask_Private.h"
#import "ORK1CompletionStep.h"


@implementation ORK1NavigableOrderedTask {
    NSMutableDictionary<NSString *, ORK1StepNavigationRule *> *_stepNavigationRules;
    NSMutableDictionary<NSString *, ORK1SkipStepNavigationRule *> *_skipStepNavigationRules;
    NSMutableDictionary<NSString *, ORK1StepModifier *> *_stepModifiers;
}

- (instancetype)initWithIdentifier:(NSString *)identifier steps:(NSArray<ORK1Step *> *)steps {
    self = [super initWithIdentifier:identifier steps:steps];
    if (self) {
        _stepNavigationRules = nil;
        _skipStepNavigationRules = nil;
        _shouldReportProgress = NO;
    }
    return self;
}

- (void)setNavigationRule:(ORK1StepNavigationRule *)stepNavigationRule forTriggerStepIdentifier:(NSString *)triggerStepIdentifier {
    ORK1ThrowInvalidArgumentExceptionIfNil(stepNavigationRule);
    ORK1ThrowInvalidArgumentExceptionIfNil(triggerStepIdentifier);
    
    if (!_stepNavigationRules) {
        _stepNavigationRules = [NSMutableDictionary new];
    }
    _stepNavigationRules[triggerStepIdentifier] = stepNavigationRule;
}

- (ORK1StepNavigationRule *)navigationRuleForTriggerStepIdentifier:(NSString *)triggerStepIdentifier {
    ORK1ThrowInvalidArgumentExceptionIfNil(triggerStepIdentifier);

    return _stepNavigationRules[triggerStepIdentifier];
}

- (void)removeNavigationRuleForTriggerStepIdentifier:(NSString *)triggerStepIdentifier {
    ORK1ThrowInvalidArgumentExceptionIfNil(triggerStepIdentifier);
    
    [_stepNavigationRules removeObjectForKey:triggerStepIdentifier];
}

- (NSDictionary<NSString *, ORK1StepNavigationRule *> *)stepNavigationRules {
    if (!_stepNavigationRules) {
        return @{};
    }
    return [_stepNavigationRules copy];
}

- (void)setSkipNavigationRule:(ORK1SkipStepNavigationRule *)skipStepNavigationRule forStepIdentifier:(NSString *)stepIdentifier {
    ORK1ThrowInvalidArgumentExceptionIfNil(skipStepNavigationRule);
    ORK1ThrowInvalidArgumentExceptionIfNil(stepIdentifier);
    
    if (!_skipStepNavigationRules) {
        _skipStepNavigationRules = [NSMutableDictionary new];
    }
    _skipStepNavigationRules[stepIdentifier] = skipStepNavigationRule;
}

- (ORK1SkipStepNavigationRule *)skipNavigationRuleForStepIdentifier:(NSString *)stepIdentifier {
    ORK1ThrowInvalidArgumentExceptionIfNil(stepIdentifier);
    
    return _skipStepNavigationRules[stepIdentifier];
}

- (void)removeSkipNavigationRuleForStepIdentifier:(NSString *)stepIdentifier {
    ORK1ThrowInvalidArgumentExceptionIfNil(stepIdentifier);
    
    [_skipStepNavigationRules removeObjectForKey:stepIdentifier];
}

- (NSDictionary<NSString *, ORK1SkipStepNavigationRule *> *)skipStepNavigationRules {
    if (!_skipStepNavigationRules) {
        return @{};
    }
    return [_skipStepNavigationRules copy];
}

- (void)setStepModifier:(ORK1StepModifier *)stepModifier forStepIdentifier:(NSString *)stepIdentifier {
    ORK1ThrowInvalidArgumentExceptionIfNil(stepModifier);
    ORK1ThrowInvalidArgumentExceptionIfNil(stepIdentifier);
    
    if (!_stepModifiers) {
        _stepModifiers = [NSMutableDictionary new];
    }
    _stepModifiers[stepIdentifier] = stepModifier;
}

- (ORK1StepModifier *)stepModifierForStepIdentifier:(NSString *)stepIdentifier {
    ORK1ThrowInvalidArgumentExceptionIfNil(stepIdentifier);
    return _stepModifiers[stepIdentifier];
}

- (void)removeStepModifierForStepIdentifier:(NSString *)stepIdentifier {
    ORK1ThrowInvalidArgumentExceptionIfNil(stepIdentifier);
    
    [_stepModifiers removeObjectForKey:stepIdentifier];
}

- (NSDictionary<NSString *, ORK1StepModifier *> *)stepModifiers {
    if (!_stepModifiers) {
        return @{};
    }
    return [_stepModifiers copy];
}

- (ORK1Step *)stepAfterStep:(ORK1Step *)step withResult:(ORK1TaskResult *)result {
    ORK1Step *nextStep = nil;
    ORK1StepNavigationRule *navigationRule = _stepNavigationRules[step.identifier];
    NSString *nextStepIdentifier = [navigationRule identifierForDestinationStepWithTaskResult:result];
    if (![nextStepIdentifier isEqualToString:ORK1NullStepIdentifier]) { // If ORK1NullStepIdentifier, return nil to end task
        if (nextStepIdentifier) {
            nextStep = [self stepWithIdentifier:nextStepIdentifier];
            
            if (step && nextStep && [self indexOfStep:nextStep] <= [self indexOfStep:step]) {
                ORK1_Log_Warning(@"Index of next step (\"%@\") is equal or lower than index of current step (\"%@\") in ordered task. Make sure this is intentional as you could loop idefinitely without appropriate navigation rules. Also please note that you'll get duplicate result entries each time you loop over the same step.", nextStep.identifier, step.identifier);
            }
        } else {
            nextStep = [super stepAfterStep:step withResult:result];
        }
        
        ORK1SkipStepNavigationRule *skipNavigationRule = _skipStepNavigationRules[nextStep.identifier];
        if ([skipNavigationRule stepShouldSkipWithTaskResult:result]) {
            return [self stepAfterStep:nextStep withResult:result];
        }
    }
    
    if (nextStep != nil) {
        ORK1StepModifier *stepModifier = [self stepModifierForStepIdentifier:nextStep.identifier];
        [stepModifier modifyStep:nextStep withTaskResult:result];
    }
    
    return nextStep;
}

- (ORK1Step *)stepBeforeStep:(ORK1Step *)step withResult:(ORK1TaskResult *)result {
    ORK1Step *previousStep = nil;
    __block NSInteger indexOfCurrentStepResult = -1;
    [result.results enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(ORK1Result *result, NSUInteger idx, BOOL *stop) {
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

// Assume ORK1NavigableOrderedTask doesn't have a linear order unless user specifically overrides
- (ORK1TaskProgress)progressOfCurrentStep:(ORK1Step *)step withResult:(ORK1TaskResult *)result {
    if (_shouldReportProgress) {
        return [super progressOfCurrentStep:step withResult:result];
    }

    return ORK1TaskProgressMake(0, 0);
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
        ORK1_DECODE_OBJ_MUTABLE_DICTIONARY(aDecoder, stepNavigationRules, NSString, ORK1StepNavigationRule);
        ORK1_DECODE_OBJ_MUTABLE_DICTIONARY(aDecoder, skipStepNavigationRules, NSString, ORK1SkipStepNavigationRule);
        ORK1_DECODE_OBJ_MUTABLE_DICTIONARY(aDecoder, stepModifiers, NSString, ORK1StepModifier);
        ORK1_DECODE_BOOL(aDecoder, shouldReportProgress);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    
    ORK1_ENCODE_OBJ(aCoder, stepNavigationRules);
    ORK1_ENCODE_OBJ(aCoder, skipStepNavigationRules);
    ORK1_ENCODE_OBJ(aCoder, stepModifiers);
    ORK1_ENCODE_BOOL(aCoder, shouldReportProgress);
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    __typeof(self) task = [super copyWithZone:zone];
    task->_stepNavigationRules = ORK1MutableDictionaryCopyObjects(_stepNavigationRules);
    task->_skipStepNavigationRules = ORK1MutableDictionaryCopyObjects(_skipStepNavigationRules);
    task->_stepModifiers = ORK1MutableDictionaryCopyObjects(_stepModifiers);
    task->_shouldReportProgress = _shouldReportProgress;
    return task;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return isParentSame
    && ORK1EqualObjects(self.stepNavigationRules, castObject.stepNavigationRules)
    && ORK1EqualObjects(self.skipStepNavigationRules, castObject.skipStepNavigationRules)
    && ORK1EqualObjects(self.stepModifiers, castObject.stepModifiers)
    && self.shouldReportProgress == castObject.shouldReportProgress;
}

- (NSUInteger)hash {
    return super.hash ^ _stepNavigationRules.hash ^ _skipStepNavigationRules.hash ^ _stepModifiers.hash ^ (_shouldReportProgress ? 0xf : 0x0);
}

#pragma mark - Predefined

NSString *const ORK1HolePegTestDominantPlaceStepIdentifier = @"hole.peg.test.dominant.place";
NSString *const ORK1HolePegTestDominantRemoveStepIdentifier = @"hole.peg.test.dominant.remove";
NSString *const ORK1HolePegTestNonDominantPlaceStepIdentifier = @"hole.peg.test.non.dominant.place";
NSString *const ORK1HolePegTestNonDominantRemoveStepIdentifier = @"hole.peg.test.non.dominant.remove";

+ (ORK1NavigableOrderedTask *)holePegTestTaskWithIdentifier:(NSString *)identifier
                                    intendedUseDescription:(nullable NSString *)intendedUseDescription
                                              dominantHand:(ORK1BodySagittal)dominantHand
                                              numberOfPegs:(int)numberOfPegs
                                                 threshold:(double)threshold
                                                   rotated:(BOOL)rotated
                                                 timeLimit:(NSTimeInterval)timeLimit
                                                   options:(ORK1PredefinedTaskOption)options {
    
    NSMutableArray *steps = [NSMutableArray array];
    BOOL dominantHandLeft = (dominantHand == ORK1BodySagittalLeft);
    NSTimeInterval stepDuration = (timeLimit == 0) ? CGFLOAT_MAX : timeLimit;
    
    if (!(options & ORK1PredefinedTaskOptionExcludeInstructions)) {
        NSString *pegs = [NSNumberFormatter localizedStringFromNumber:@(numberOfPegs) numberStyle:NSNumberFormatterNoStyle];
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction0StepIdentifier];
            step.title = [[NSString alloc] initWithFormat:ORK1LocalizedString(@"HOLE_PEG_TEST_TITLE_%@", nil), pegs];
            step.text = intendedUseDescription;
            step.detailText = [[NSString alloc] initWithFormat:ORK1LocalizedString(@"HOLE_PEG_TEST_INTRO_TEXT_%@", nil), pegs];
            step.image = [UIImage imageNamed:@"phoneholepeg" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
        
        {
            ORK1InstructionStep *step = [[ORK1InstructionStep alloc] initWithIdentifier:ORK1Instruction1StepIdentifier];
            step.title = [[NSString alloc] initWithFormat:ORK1LocalizedString(@"HOLE_PEG_TEST_TITLE_%@", nil), pegs];
            step.text = dominantHandLeft ? [[NSString alloc] initWithFormat:ORK1LocalizedString(@"HOLE_PEG_TEST_INTRO_TEXT_2_LEFT_HAND_FIRST_%@", nil), pegs, pegs] : [[NSString alloc] initWithFormat:ORK1LocalizedString(@"HOLE_PEG_TEST_INTRO_TEXT_2_RIGHT_HAND_FIRST_%@", nil), pegs, pegs];
            step.detailText = ORK1LocalizedString(@"HOLE_PEG_TEST_CALL_TO_ACTION", nil);
            UIImage *image1 = [UIImage imageNamed:@"holepegtest1" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            UIImage *image2 = [UIImage imageNamed:@"holepegtest2" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            UIImage *image3 = [UIImage imageNamed:@"holepegtest3" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            UIImage *image4 = [UIImage imageNamed:@"holepegtest4" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            UIImage *image5 = [UIImage imageNamed:@"holepegtest5" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            UIImage *image6 = [UIImage imageNamed:@"holepegtest6" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.image = [UIImage animatedImageWithImages:@[image1, image2, image3, image4, image5, image6] duration:4];
            step.shouldTintImages = YES;
            
            ORK1StepArrayAddStep(steps, step);
        }
    }
    
    {
        {
            ORK1HolePegTestPlaceStep *step = [[ORK1HolePegTestPlaceStep alloc] initWithIdentifier:ORK1HolePegTestDominantPlaceStepIdentifier];
            step.title = dominantHandLeft ? ORK1LocalizedString(@"HOLE_PEG_TEST_PLACE_INSTRUCTION_LEFT_HAND", nil) : ORK1LocalizedString(@"HOLE_PEG_TEST_PLACE_INSTRUCTION_RIGHT_HAND", nil);
            step.text = ORK1LocalizedString(@"HOLE_PEG_TEST_TEXT", nil);
            step.spokenInstruction = step.title;
            step.movingDirection = dominantHand;
            step.dominantHandTested = YES;
            step.numberOfPegs = numberOfPegs;
            step.threshold = threshold;
            step.rotated = rotated;
            step.shouldTintImages = YES;
            step.stepDuration = stepDuration;
            
            ORK1StepArrayAddStep(steps, step);
        }
        
        {
            ORK1HolePegTestRemoveStep *step = [[ORK1HolePegTestRemoveStep alloc] initWithIdentifier:ORK1HolePegTestDominantRemoveStepIdentifier];
            step.title = dominantHandLeft ? ORK1LocalizedString(@"HOLE_PEG_TEST_REMOVE_INSTRUCTION_LEFT_HAND", nil) : ORK1LocalizedString(@"HOLE_PEG_TEST_REMOVE_INSTRUCTION_RIGHT_HAND", nil);
            step.text = ORK1LocalizedString(@"HOLE_PEG_TEST_TEXT", nil);
            step.spokenInstruction = step.title;
            step.movingDirection = (dominantHand == ORK1BodySagittalLeft) ? ORK1BodySagittalRight : ORK1BodySagittalLeft;
            step.dominantHandTested = YES;
            step.numberOfPegs = numberOfPegs;
            step.threshold = threshold;
            step.shouldTintImages = YES;
            step.stepDuration = stepDuration;
            
            ORK1StepArrayAddStep(steps, step);
        }
        
        {
            ORK1HolePegTestPlaceStep *step = [[ORK1HolePegTestPlaceStep alloc] initWithIdentifier:ORK1HolePegTestNonDominantPlaceStepIdentifier];
            step.title = dominantHandLeft ? ORK1LocalizedString(@"HOLE_PEG_TEST_PLACE_INSTRUCTION_RIGHT_HAND", nil) : ORK1LocalizedString(@"HOLE_PEG_TEST_PLACE_INSTRUCTION_LEFT_HAND", nil);
            step.text = ORK1LocalizedString(@"HOLE_PEG_TEST_TEXT", nil);
            step.spokenInstruction = step.title;
            step.movingDirection = (dominantHand == ORK1BodySagittalLeft) ? ORK1BodySagittalRight : ORK1BodySagittalLeft;
            step.dominantHandTested = NO;
            step.numberOfPegs = numberOfPegs;
            step.threshold = threshold;
            step.rotated = rotated;
            step.shouldTintImages = YES;
            step.stepDuration = stepDuration;
            
            ORK1StepArrayAddStep(steps, step);
        }
        
        {
            ORK1HolePegTestRemoveStep *step = [[ORK1HolePegTestRemoveStep alloc] initWithIdentifier:ORK1HolePegTestNonDominantRemoveStepIdentifier];
            step.title = dominantHandLeft ? ORK1LocalizedString(@"HOLE_PEG_TEST_REMOVE_INSTRUCTION_RIGHT_HAND", nil) : ORK1LocalizedString(@"HOLE_PEG_TEST_REMOVE_INSTRUCTION_LEFT_HAND", nil);
            step.text = ORK1LocalizedString(@"HOLE_PEG_TEST_TEXT", nil);
            step.spokenInstruction = step.title;
            step.movingDirection = dominantHand;
            step.dominantHandTested = NO;
            step.numberOfPegs = numberOfPegs;
            step.threshold = threshold;
            step.shouldTintImages = YES;
            step.stepDuration = stepDuration;
            
            ORK1StepArrayAddStep(steps, step);
        }
    }
    
    if (!(options & ORK1PredefinedTaskOptionExcludeConclusion)) {
        ORK1CompletionStep *step = [self makeCompletionStep];
        ORK1StepArrayAddStep(steps, step);
    }
    
    
    // The task is actually dynamic. The direct navigation rules are used for skipping the peg
    // removal steps if the user doesn't succeed in placing all the pegs in the allotted time
    // (the rules are removed from `ORK1HolePegTestPlaceStepViewController` if she succeeds).
    ORK1NavigableOrderedTask *task = [[ORK1NavigableOrderedTask alloc] initWithIdentifier:identifier steps:steps];
    
    ORK1StepNavigationRule *navigationRule = [[ORK1DirectStepNavigationRule alloc] initWithDestinationStepIdentifier:ORK1HolePegTestNonDominantPlaceStepIdentifier];
    [task setNavigationRule:navigationRule forTriggerStepIdentifier:ORK1HolePegTestDominantPlaceStepIdentifier];
    navigationRule = [[ORK1DirectStepNavigationRule alloc] initWithDestinationStepIdentifier:ORK1ConclusionStepIdentifier];
    [task setNavigationRule:navigationRule forTriggerStepIdentifier:ORK1HolePegTestNonDominantPlaceStepIdentifier];
    
    return task;
}

@end
