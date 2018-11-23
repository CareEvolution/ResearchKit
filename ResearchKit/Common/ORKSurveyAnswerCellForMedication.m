//
//  ORKSurveyAnswerCellForMedication.m
//  ResearchKit
//
//  Created by Eric Schramm on 5/24/18.
//  Copyright © 2018 researchkit.org. All rights reserved.
//

#import "ORKSurveyAnswerCellForMedication.h"

#import "ORKAnswerTextField.h"
#import "ORKLocationSelectionView.h"

#import "ORKAnswerFormat_Internal.h"
#import "ORKQuestionStep_Internal.h"

#import "ORKHelpers_Internal.h"
#import "ORKSkin.h"


@interface ORKSurveyAnswerCellForMedication ()

@end


@implementation ORKSurveyAnswerCellForMedication { }

- (void)prepareView {
    self.textLabel.text = @"[Add a medication]";
    [super prepareView];
}

@end
