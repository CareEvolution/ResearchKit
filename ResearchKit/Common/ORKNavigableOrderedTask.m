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


#import "ORKNavigableOrderedTask.h"

#import "ORKOrderedTask_Private.h"
#import "ORKResult.h"
#import "ORKStep_Private.h"
#import "ORKStepNavigationRule.h"

#import "ORKHelpers_Internal.h"

#import "ORKHolePegTestPlaceStep.h"
#import "ORKHolePegTestRemoveStep.h"
#import "ORKInstructionStep.h"
#import "ORKOrderedTask_Private.h"
#import "ORKCompletionStep.h"


@implementation ORKLegacyNavigableOrderedTask {
    NSMutableDictionary<NSString *, ORKLegacyStepNavigationRule *> *_stepNavigationRules;
    NSMutableDictionary<NSString *, ORKLegacySkipStepNavigationRule *> *_skipStepNavigationRules;
    NSMutableDictionary<NSString *, ORKLegacyStepModifier *> *_stepModifiers;
}

- (instancetype)initWithIdentifier:(NSString *)identifier steps:(NSArray<ORKLegacyStep *> *)steps {
    self = [super initWithIdentifier:identifier steps:steps];
    if (self) {
        _stepNavigationRules = nil;
        _skipStepNavigationRules = nil;
        _shouldReportProgress = NO;
    }
    return self;
}

- (void)setNavigationRule:(ORKLegacyStepNavigationRule *)stepNavigationRule forTriggerStepIdentifier:(NSString *)triggerStepIdentifier {
    ORKLegacyThrowInvalidArgumentExceptionIfNil(stepNavigationRule);
    ORKLegacyThrowInvalidArgumentExceptionIfNil(triggerStepIdentifier);
    
    if (!_stepNavigationRules) {
        _stepNavigationRules = [NSMutableDictionary new];
    }
    _stepNavigationRules[triggerStepIdentifier] = stepNavigationRule;
}

- (ORKLegacyStepNavigationRule *)navigationRuleForTriggerStepIdentifier:(NSString *)triggerStepIdentifier {
    ORKLegacyThrowInvalidArgumentExceptionIfNil(triggerStepIdentifier);

    return _stepNavigationRules[triggerStepIdentifier];
}

- (void)removeNavigationRuleForTriggerStepIdentifier:(NSString *)triggerStepIdentifier {
    ORKLegacyThrowInvalidArgumentExceptionIfNil(triggerStepIdentifier);
    
    [_stepNavigationRules removeObjectForKey:triggerStepIdentifier];
}

- (NSDictionary<NSString *, ORKLegacyStepNavigationRule *> *)stepNavigationRules {
    if (!_stepNavigationRules) {
        return @{};
    }
    return [_stepNavigationRules copy];
}

- (void)setSkipNavigationRule:(ORKLegacySkipStepNavigationRule *)skipStepNavigationRule forStepIdentifier:(NSString *)stepIdentifier {
    ORKLegacyThrowInvalidArgumentExceptionIfNil(skipStepNavigationRule);
    ORKLegacyThrowInvalidArgumentExceptionIfNil(stepIdentifier);
    
    if (!_skipStepNavigationRules) {
        _skipStepNavigationRules = [NSMutableDictionary new];
    }
    _skipStepNavigationRules[stepIdentifier] = skipStepNavigationRule;
}

- (ORKLegacySkipStepNavigationRule *)skipNavigationRuleForStepIdentifier:(NSString *)stepIdentifier {
    ORKLegacyThrowInvalidArgumentExceptionIfNil(stepIdentifier);
    
    return _skipStepNavigationRules[stepIdentifier];
}

- (void)removeSkipNavigationRuleForStepIdentifier:(NSString *)stepIdentifier {
    ORKLegacyThrowInvalidArgumentExceptionIfNil(stepIdentifier);
    
    [_skipStepNavigationRules removeObjectForKey:stepIdentifier];
}

- (NSDictionary<NSString *, ORKLegacySkipStepNavigationRule *> *)skipStepNavigationRules {
    if (!_skipStepNavigationRules) {
        return @{};
    }
    return [_skipStepNavigationRules copy];
}

- (void)setStepModifier:(ORKLegacyStepModifier *)stepModifier forStepIdentifier:(NSString *)stepIdentifier {
    ORKLegacyThrowInvalidArgumentExceptionIfNil(stepModifier);
    ORKLegacyThrowInvalidArgumentExceptionIfNil(stepIdentifier);
    
    if (!_stepModifiers) {
        _stepModifiers = [NSMutableDictionary new];
    }
    _stepModifiers[stepIdentifier] = stepModifier;
}

- (ORKLegacyStepModifier *)stepModifierForStepIdentifier:(NSString *)stepIdentifier {
    ORKLegacyThrowInvalidArgumentExceptionIfNil(stepIdentifier);
    return _stepModifiers[stepIdentifier];
}

- (void)removeStepModifierForStepIdentifier:(NSString *)stepIdentifier {
    ORKLegacyThrowInvalidArgumentExceptionIfNil(stepIdentifier);
    
    [_stepModifiers removeObjectForKey:stepIdentifier];
}

- (NSDictionary<NSString *, ORKLegacyStepModifier *> *)stepModifiers {
    if (!_stepModifiers) {
        return @{};
    }
    return [_stepModifiers copy];
}

- (ORKLegacyStep *)stepAfterStep:(ORKLegacyStep *)step withResult:(ORKLegacyTaskResult *)result {
    ORKLegacyStep *nextStep = nil;
    ORKLegacyStepNavigationRule *navigationRule = _stepNavigationRules[step.identifier];
    NSString *nextStepIdentifier = [navigationRule identifierForDestinationStepWithTaskResult:result];
    if (![nextStepIdentifier isEqualToString:ORKLegacyNullStepIdentifier]) { // If ORKLegacyNullStepIdentifier, return nil to end task
        if (nextStepIdentifier) {
            nextStep = [self stepWithIdentifier:nextStepIdentifier];
            
            if (step && nextStep && [self indexOfStep:nextStep] <= [self indexOfStep:step]) {
                ORKLegacy_Log_Warning(@"Index of next step (\"%@\") is equal or lower than index of current step (\"%@\") in ordered task. Make sure this is intentional as you could loop idefinitely without appropriate navigation rules. Also please note that you'll get duplicate result entries each time you loop over the same step.", nextStep.identifier, step.identifier);
            }
        } else {
            nextStep = [super stepAfterStep:step withResult:result];
        }
        
        ORKLegacySkipStepNavigationRule *skipNavigationRule = _skipStepNavigationRules[nextStep.identifier];
        if ([skipNavigationRule stepShouldSkipWithTaskResult:result]) {
            return [self stepAfterStep:nextStep withResult:result];
        }
    }
    
    if (nextStep != nil) {
        ORKLegacyStepModifier *stepModifier = [self stepModifierForStepIdentifier:nextStep.identifier];
        [stepModifier modifyStep:nextStep withTaskResult:result];
    }
    
    return nextStep;
}

- (ORKLegacyStep *)stepBeforeStep:(ORKLegacyStep *)step withResult:(ORKLegacyTaskResult *)result {
    ORKLegacyStep *previousStep = nil;
    __block NSInteger indexOfCurrentStepResult = -1;
    [result.results enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(ORKLegacyResult *result, NSUInteger idx, BOOL *stop) {
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

// Assume ORKLegacyNavigableOrderedTask doesn't have a linear order unless user specifically overrides
- (ORKLegacyTaskProgress)progressOfCurrentStep:(ORKLegacyStep *)step withResult:(ORKLegacyTaskResult *)result {
    if (_shouldReportProgress) {
        return [super progressOfCurrentStep:step withResult:result];
    }

    return ORKLegacyTaskProgressMake(0, 0);
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
        ORKLegacy_DECODE_OBJ_MUTABLE_DICTIONARY(aDecoder, stepNavigationRules, NSString, ORKLegacyStepNavigationRule);
        ORKLegacy_DECODE_OBJ_MUTABLE_DICTIONARY(aDecoder, skipStepNavigationRules, NSString, ORKLegacySkipStepNavigationRule);
        ORKLegacy_DECODE_OBJ_MUTABLE_DICTIONARY(aDecoder, stepModifiers, NSString, ORKLegacyStepModifier);
        ORKLegacy_DECODE_BOOL(aDecoder, shouldReportProgress);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    
    ORKLegacy_ENCODE_OBJ(aCoder, stepNavigationRules);
    ORKLegacy_ENCODE_OBJ(aCoder, skipStepNavigationRules);
    ORKLegacy_ENCODE_OBJ(aCoder, stepModifiers);
    ORKLegacy_ENCODE_BOOL(aCoder, shouldReportProgress);
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    __typeof(self) task = [super copyWithZone:zone];
    task->_stepNavigationRules = ORKLegacyMutableDictionaryCopyObjects(_stepNavigationRules);
    task->_skipStepNavigationRules = ORKLegacyMutableDictionaryCopyObjects(_skipStepNavigationRules);
    task->_stepModifiers = ORKLegacyMutableDictionaryCopyObjects(_stepModifiers);
    task->_shouldReportProgress = _shouldReportProgress;
    return task;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return isParentSame
    && ORKLegacyEqualObjects(self.stepNavigationRules, castObject.stepNavigationRules)
    && ORKLegacyEqualObjects(self.skipStepNavigationRules, castObject.skipStepNavigationRules)
    && ORKLegacyEqualObjects(self.stepModifiers, castObject.stepModifiers)
    && self.shouldReportProgress == castObject.shouldReportProgress;
}

- (NSUInteger)hash {
    return super.hash ^ _stepNavigationRules.hash ^ _skipStepNavigationRules.hash ^ _stepModifiers.hash ^ (_shouldReportProgress ? 0xf : 0x0);
}

#pragma mark - Predefined

NSString *const ORKLegacyHolePegTestDominantPlaceStepIdentifier = @"hole.peg.test.dominant.place";
NSString *const ORKLegacyHolePegTestDominantRemoveStepIdentifier = @"hole.peg.test.dominant.remove";
NSString *const ORKLegacyHolePegTestNonDominantPlaceStepIdentifier = @"hole.peg.test.non.dominant.place";
NSString *const ORKLegacyHolePegTestNonDominantRemoveStepIdentifier = @"hole.peg.test.non.dominant.remove";

+ (ORKLegacyNavigableOrderedTask *)holePegTestTaskWithIdentifier:(NSString *)identifier
                                    intendedUseDescription:(nullable NSString *)intendedUseDescription
                                              dominantHand:(ORKLegacyBodySagittal)dominantHand
                                              numberOfPegs:(int)numberOfPegs
                                                 threshold:(double)threshold
                                                   rotated:(BOOL)rotated
                                                 timeLimit:(NSTimeInterval)timeLimit
                                                   options:(ORKLegacyPredefinedTaskOption)options {
    
    NSMutableArray *steps = [NSMutableArray array];
    BOOL dominantHandLeft = (dominantHand == ORKLegacyBodySagittalLeft);
    NSTimeInterval stepDuration = (timeLimit == 0) ? CGFLOAT_MAX : timeLimit;
    
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeInstructions)) {
        NSString *pegs = [NSNumberFormatter localizedStringFromNumber:@(numberOfPegs) numberStyle:NSNumberFormatterNoStyle];
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction0StepIdentifier];
            step.title = [[NSString alloc] initWithFormat:ORKLegacyLocalizedString(@"HOLE_PEG_TEST_TITLE_%@", nil), pegs];
            step.text = intendedUseDescription;
            step.detailText = [[NSString alloc] initWithFormat:ORKLegacyLocalizedString(@"HOLE_PEG_TEST_INTRO_TEXT_%@", nil), pegs];
            step.image = [UIImage imageNamed:@"phoneholepeg" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        {
            ORKLegacyInstructionStep *step = [[ORKLegacyInstructionStep alloc] initWithIdentifier:ORKLegacyInstruction1StepIdentifier];
            step.title = [[NSString alloc] initWithFormat:ORKLegacyLocalizedString(@"HOLE_PEG_TEST_TITLE_%@", nil), pegs];
            step.text = dominantHandLeft ? [[NSString alloc] initWithFormat:ORKLegacyLocalizedString(@"HOLE_PEG_TEST_INTRO_TEXT_2_LEFT_HAND_FIRST_%@", nil), pegs, pegs] : [[NSString alloc] initWithFormat:ORKLegacyLocalizedString(@"HOLE_PEG_TEST_INTRO_TEXT_2_RIGHT_HAND_FIRST_%@", nil), pegs, pegs];
            step.detailText = ORKLegacyLocalizedString(@"HOLE_PEG_TEST_CALL_TO_ACTION", nil);
            UIImage *image1 = [UIImage imageNamed:@"holepegtest1" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            UIImage *image2 = [UIImage imageNamed:@"holepegtest2" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            UIImage *image3 = [UIImage imageNamed:@"holepegtest3" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            UIImage *image4 = [UIImage imageNamed:@"holepegtest4" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            UIImage *image5 = [UIImage imageNamed:@"holepegtest5" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            UIImage *image6 = [UIImage imageNamed:@"holepegtest6" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
            step.image = [UIImage animatedImageWithImages:@[image1, image2, image3, image4, image5, image6] duration:4];
            step.shouldTintImages = YES;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
    }
    
    {
        {
            ORKLegacyHolePegTestPlaceStep *step = [[ORKLegacyHolePegTestPlaceStep alloc] initWithIdentifier:ORKLegacyHolePegTestDominantPlaceStepIdentifier];
            step.title = dominantHandLeft ? ORKLegacyLocalizedString(@"HOLE_PEG_TEST_PLACE_INSTRUCTION_LEFT_HAND", nil) : ORKLegacyLocalizedString(@"HOLE_PEG_TEST_PLACE_INSTRUCTION_RIGHT_HAND", nil);
            step.text = ORKLegacyLocalizedString(@"HOLE_PEG_TEST_TEXT", nil);
            step.spokenInstruction = step.title;
            step.movingDirection = dominantHand;
            step.dominantHandTested = YES;
            step.numberOfPegs = numberOfPegs;
            step.threshold = threshold;
            step.rotated = rotated;
            step.shouldTintImages = YES;
            step.stepDuration = stepDuration;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        {
            ORKLegacyHolePegTestRemoveStep *step = [[ORKLegacyHolePegTestRemoveStep alloc] initWithIdentifier:ORKLegacyHolePegTestDominantRemoveStepIdentifier];
            step.title = dominantHandLeft ? ORKLegacyLocalizedString(@"HOLE_PEG_TEST_REMOVE_INSTRUCTION_LEFT_HAND", nil) : ORKLegacyLocalizedString(@"HOLE_PEG_TEST_REMOVE_INSTRUCTION_RIGHT_HAND", nil);
            step.text = ORKLegacyLocalizedString(@"HOLE_PEG_TEST_TEXT", nil);
            step.spokenInstruction = step.title;
            step.movingDirection = (dominantHand == ORKLegacyBodySagittalLeft) ? ORKLegacyBodySagittalRight : ORKLegacyBodySagittalLeft;
            step.dominantHandTested = YES;
            step.numberOfPegs = numberOfPegs;
            step.threshold = threshold;
            step.shouldTintImages = YES;
            step.stepDuration = stepDuration;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        {
            ORKLegacyHolePegTestPlaceStep *step = [[ORKLegacyHolePegTestPlaceStep alloc] initWithIdentifier:ORKLegacyHolePegTestNonDominantPlaceStepIdentifier];
            step.title = dominantHandLeft ? ORKLegacyLocalizedString(@"HOLE_PEG_TEST_PLACE_INSTRUCTION_RIGHT_HAND", nil) : ORKLegacyLocalizedString(@"HOLE_PEG_TEST_PLACE_INSTRUCTION_LEFT_HAND", nil);
            step.text = ORKLegacyLocalizedString(@"HOLE_PEG_TEST_TEXT", nil);
            step.spokenInstruction = step.title;
            step.movingDirection = (dominantHand == ORKLegacyBodySagittalLeft) ? ORKLegacyBodySagittalRight : ORKLegacyBodySagittalLeft;
            step.dominantHandTested = NO;
            step.numberOfPegs = numberOfPegs;
            step.threshold = threshold;
            step.rotated = rotated;
            step.shouldTintImages = YES;
            step.stepDuration = stepDuration;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
        
        {
            ORKLegacyHolePegTestRemoveStep *step = [[ORKLegacyHolePegTestRemoveStep alloc] initWithIdentifier:ORKLegacyHolePegTestNonDominantRemoveStepIdentifier];
            step.title = dominantHandLeft ? ORKLegacyLocalizedString(@"HOLE_PEG_TEST_REMOVE_INSTRUCTION_RIGHT_HAND", nil) : ORKLegacyLocalizedString(@"HOLE_PEG_TEST_REMOVE_INSTRUCTION_LEFT_HAND", nil);
            step.text = ORKLegacyLocalizedString(@"HOLE_PEG_TEST_TEXT", nil);
            step.spokenInstruction = step.title;
            step.movingDirection = dominantHand;
            step.dominantHandTested = NO;
            step.numberOfPegs = numberOfPegs;
            step.threshold = threshold;
            step.shouldTintImages = YES;
            step.stepDuration = stepDuration;
            
            ORKLegacyStepArrayAddStep(steps, step);
        }
    }
    
    if (!(options & ORKLegacyPredefinedTaskOptionExcludeConclusion)) {
        ORKLegacyCompletionStep *step = [self makeCompletionStep];
        ORKLegacyStepArrayAddStep(steps, step);
    }
    
    
    // The task is actually dynamic. The direct navigation rules are used for skipping the peg
    // removal steps if the user doesn't succeed in placing all the pegs in the allotted time
    // (the rules are removed from `ORKLegacyHolePegTestPlaceStepViewController` if she succeeds).
    ORKLegacyNavigableOrderedTask *task = [[ORKLegacyNavigableOrderedTask alloc] initWithIdentifier:identifier steps:steps];
    
    ORKLegacyStepNavigationRule *navigationRule = [[ORKLegacyDirectStepNavigationRule alloc] initWithDestinationStepIdentifier:ORKLegacyHolePegTestNonDominantPlaceStepIdentifier];
    [task setNavigationRule:navigationRule forTriggerStepIdentifier:ORKLegacyHolePegTestDominantPlaceStepIdentifier];
    navigationRule = [[ORKLegacyDirectStepNavigationRule alloc] initWithDestinationStepIdentifier:ORKLegacyConclusionStepIdentifier];
    [task setNavigationRule:navigationRule forTriggerStepIdentifier:ORKLegacyHolePegTestNonDominantPlaceStepIdentifier];
    
    return task;
}

@end
