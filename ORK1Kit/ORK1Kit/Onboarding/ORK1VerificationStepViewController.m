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


#import "ORK1VerificationStepViewController.h"

#import "ORK1StepHeaderView_Internal.h"
#import "ORK1VerificationStepView.h"

#import "ORK1StepViewController_Internal.h"

#import "ORK1VerificationStep.h"

#import "ORK1Helpers_Internal.h"


@implementation ORK1VerificationStepViewController {
    ORK1VerificationStepView *_verificationStepView;
}

- (ORK1VerificationStep *)verificationStep {
    return (ORK1VerificationStep *)self.step;
}

- (void)stepDidChange {
    [super stepDidChange];
    
    if (self.step && [self isViewLoaded]) {
        self.navigationItem.title = ORK1LocalizedString(@"VERIFICATION_NAV_TITLE", nil);
        
        _verificationStepView = [[ORK1VerificationStepView alloc] initWithFrame:self.view.bounds];
        _verificationStepView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _verificationStepView.headerView.captionLabel.text = [self verificationStep].title;
        _verificationStepView.headerView.instructionTextView.textValue = [[self verificationStep].text stringByAppendingString:[NSString stringWithFormat:@"\n\n%@", ORK1LocalizedString(@"RESEND_EMAIL_LABEL_MESSAGE", nil)]];
        
        [self.view addSubview:_verificationStepView];
        
        [_verificationStepView.resendEmailButton addTarget:self
                                                   action:@selector(resendEmailButtonHandler:)
                                         forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self stepDidChange];
}

- (void)resendEmailButtonHandler:(id)sender {
    [self resendEmailButtonTapped];
}

#pragma mark Override methods

- (void)resendEmailButtonTapped {
    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:[NSString stringWithFormat:@"%s must be overridden in a subclass/category", __PRETTY_FUNCTION__]
                                 userInfo:nil];
}

@end
