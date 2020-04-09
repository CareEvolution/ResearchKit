/*
 Copyright (c) 2015, Alejandro Martinez, Quintiles Inc.
 Copyright (c) 2015, Brian Kelly, Quintiles Inc.
 Copyright (c) 2015, Bryan Strothmann, Quintiles Inc.
 Copyright (c) 2015, Greg Yip, Quintiles Inc.
 Copyright (c) 2015, John Reites, Quintiles Inc.
 Copyright (c) 2015, Pavel Kanzelsberger, Quintiles Inc.
 Copyright (c) 2015, Richard Thomas, Quintiles Inc.
 Copyright (c) 2015, Shelby Brooks, Quintiles Inc.
 Copyright (c) 2015, Steve Cadwallader, Quintiles Inc.
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


#import "ORK1WaitStepViewController.h"

#import "ORK1StepHeaderView_Internal.h"
#import "ORK1WaitStepView.h"

#import "ORK1StepViewController_Internal.h"

#import "ORK1WaitStep.h"

#import "ORK1Helpers_Internal.h"

NSString *const ORK1WaitStepViewControllerUpdateText = @"ORK1WaitStepViewControllerUpdateText";
NSString *const ORK1WaitStepUpdatedTitleKey = @"ORK1WaitStepUpdatedTitleKey";
NSString *const ORK1WaitStepUpdatedTextKey = @"ORK1WaitStepUpdatedTextKey";

@implementation ORK1WaitStepViewController {
    ORK1WaitStepView *_waitStepView;
    ORK1ProgressIndicatorType _indicatorType;
    NSString *_updatedText;
}

- (ORK1WaitStep *)waitStep {
    return (ORK1WaitStep *)self.step;
}

- (void)stepDidChange {
    [super stepDidChange];
    
    [_waitStepView removeFromSuperview];
    
    if (self.step && [self isViewLoaded]) {
        if (!_waitStepView) {
            // Collect the text content from step during the when _waitStepView hasn't been initialized.
            _updatedText = [self waitStep].text;
        }
        
        _waitStepView = [[ORK1WaitStepView alloc] initWithIndicatorType:[self waitStep].indicatorType];
        _waitStepView.frame = self.view.bounds;
        _waitStepView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:_waitStepView];
        
        _waitStepView.headerView.captionLabel.text = [self waitStep].title;
        _waitStepView.headerView.instructionLabel.text = _updatedText;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self stepDidChange];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTitleFromNotification:) name:ORK1WaitStepViewControllerUpdateText object:nil];
}

- (void)updateTitleFromNotification:(NSNotification *)notification {
    id updatedTitle = notification.userInfo[ORK1WaitStepUpdatedTitleKey];
    if ([updatedTitle isKindOfClass:[NSString class]]) {
        [self updateTitle:updatedTitle];
    }
    id updatedText = notification.userInfo[ORK1WaitStepUpdatedTextKey];
    if ([updatedText isKindOfClass:[NSString class]]) {
        [self updateText:updatedText];
    }
}

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated {
    [_waitStepView.progressView setProgress:progress animated:animated];
}

- (void)updateTitle:(NSString *)title {
    _waitStepView.headerView.captionLabel.text = title;
}

- (void)updateText:(NSString *)text {
    _updatedText = text;
    [self stepDidChange];
}

@end
