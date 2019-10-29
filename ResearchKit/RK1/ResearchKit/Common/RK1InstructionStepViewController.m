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


#import "RK1InstructionStepViewController.h"

#import "RK1InstructionStepView.h"
#import "RK1NavigationContainerView.h"
#import "RK1StepHeaderView_Internal.h"

#import "RK1InstructionStepViewController_Internal.h"
#import "RK1StepViewController_Internal.h"
#import "RK1TaskViewController_Internal.h"

#import "RK1InstructionStep.h"

#import "RK1Helpers_Internal.h"
#import "RK1Skin.h"


@implementation RK1InstructionStepViewController

- (RK1InstructionStep *)instructionStep {
    return (RK1InstructionStep *)self.step;
}

- (void)stepDidChange {
    [super stepDidChange];
    
    [self.stepView removeFromSuperview];
    self.stepView = nil;
    
    if (self.step && [self isViewLoaded]) {
        self.stepView = [[RK1InstructionStepView alloc] initWithFrame:self.view.bounds];
        self.stepView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:self.stepView];
        
        self.stepView.continueSkipContainer.continueButtonItem = self.continueButtonItem;
        self.stepView.headerView.learnMoreButtonItem = self.learnMoreButtonItem;
        self.stepView.continueSkipContainer.continueEnabled = YES;
        self.stepView.continueSkipContainer.hidden = self.isBeingReviewed;
        
        self.stepView.instructionStep = [self instructionStep];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.taskViewController setRegisteredScrollView:_stepView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self stepDidChange];
}

- (void)useAppropriateButtonTitleAsLastBeginningInstructionStep {
    self.internalContinueButtonItem.title = RK1LocalizedString(@"BUTTON_GET_STARTED",nil);
}

- (void)setContinueButtonItem:(UIBarButtonItem *)continueButtonItem {
    [super setContinueButtonItem:continueButtonItem];
    self.stepView.continueSkipContainer.continueButtonItem = continueButtonItem;
}

- (void)setLearnMoreButtonItem:(UIBarButtonItem *)learnMoreButtonItem {
    [super setLearnMoreButtonItem:learnMoreButtonItem];
    self.stepView.headerView.learnMoreButtonItem = learnMoreButtonItem;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
}

@end
