//
//  ORKStroopStepTests.m
//  ResearchKitTests
//
//  Created by Eric Schramm on 2/25/20.
//  Copyright © 2020 researchkit.org. All rights reserved.
//

@import XCTest;
@import ResearchKit.Private;


@interface ORKStroopStepTests : XCTestCase

@end


@implementation ORKStroopStepTests

- (double)realTruesRandomizationTrialForStroopViewController:(ORKStroopStepViewController *)stroopVC {
    const NSInteger trialCount = 10000;
    NSInteger trueCount = 0;
    ORKStroopStep *stroopStep = (ORKStroopStep *)stroopVC.step;
    for (NSInteger trialIdx = 0; trialIdx < trialCount; trialIdx++) {
        if (randomBoolWithTrueProbability(stroopStep.probabilityOfVisualAndColorAlignment)) {
            trueCount++;
        }
    }
    return (double)trueCount / (double)trialCount;
}

- (void)testAlwaysAlignmentRandomization {
    ORKStroopStep *stroopStep = [[ORKStroopStep alloc] initWithIdentifier:@"testStroop"];
    stroopStep.probabilityOfVisualAndColorAlignment = @(1.0);
    stroopStep.numberOfAttempts = 10;
    ORKStroopStepViewController *stroopVC = [[ORKStroopStepViewController alloc] initWithStep:stroopStep];
    XCTAssertLessThan(fabs([self realTruesRandomizationTrialForStroopViewController:stroopVC] - 1.0), 0.00000001);
}

- (void)testNeverAlignmentRandomization {
    ORKStroopStep *stroopStep = [[ORKStroopStep alloc] initWithIdentifier:@"testStroop"];
    stroopStep.probabilityOfVisualAndColorAlignment = @(0.0);
    stroopStep.numberOfAttempts = 10;
    ORKStroopStepViewController *stroopVC = [[ORKStroopStepViewController alloc] initWithStep:stroopStep];
    XCTAssertLessThan(fabs([self realTruesRandomizationTrialForStroopViewController:stroopVC]), 0.00000001);
}

- (void)testSometimesAlignmentRandomization {
    ORKStroopStep *stroopStep = [[ORKStroopStep alloc] initWithIdentifier:@"testStroop"];
    stroopStep.numberOfAttempts = 10;
    NSArray<NSNumber *> *probabilitiesToTest = @[@(0.25), @(0.5), @(0.75)];
    // test with n = 10,000 and tolerance of 1 %
    for (NSNumber *probability in probabilitiesToTest) {
        stroopStep.probabilityOfVisualAndColorAlignment = probability;
        ORKStroopStepViewController *stroopVC = [[ORKStroopStepViewController alloc] initWithStep:stroopStep];
        XCTAssertLessThan(fabs([self realTruesRandomizationTrialForStroopViewController:stroopVC] - probability.doubleValue), 0.01);
    }
}

@end


