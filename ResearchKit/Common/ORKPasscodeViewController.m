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


#import "ORKPasscodeViewController.h"

#import "ORKPasscodeStepViewController_Internal.h"
#import "ORKStepViewController_Internal.h"

#import "ORKPasscodeStep.h"

#import "ORKHelpers_Internal.h"
#import "ORKKeychainWrapper.h"


@implementation ORKLegacyPasscodeViewController

+ (instancetype)new {
    ORKLegacyThrowMethodUnavailableException();
}

- (instancetype)init {
    ORKLegacyThrowMethodUnavailableException();
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        [self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        self.navigationBar.shadowImage = [UIImage new];
        self.navigationBar.translucent = NO;
    }
    return self;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [[ORKLegacyPasscodeStepViewController class] supportedInterfaceOrientations];
}

+ (instancetype)passcodeAuthenticationViewControllerWithText:(NSString *)text
                                                    delegate:(id<ORKLegacyPasscodeDelegate>)delegate {
    return [self passcodeViewControllerWithText:text
                                       delegate:delegate
                                   passcodeFlow:ORKLegacyPasscodeFlowAuthenticate
                                   passcodeType:0];
}

+ (instancetype)passcodeEditingViewControllerWithText:(NSString *)text
                                             delegate:(id<ORKLegacyPasscodeDelegate>)delegate
                                         passcodeType:(ORKLegacyPasscodeType)passcodeType {
    return [self passcodeViewControllerWithText:text
                                       delegate:delegate
                                   passcodeFlow:ORKLegacyPasscodeFlowEdit
                                   passcodeType:passcodeType];
}

+ (instancetype)passcodeViewControllerWithText:(NSString *)text
                                      delegate:(id<ORKLegacyPasscodeDelegate>)delegate
                                  passcodeFlow:(ORKLegacyPasscodeFlow)passcodeFlow
                                  passcodeType:(ORKLegacyPasscodeType)passcodeType {
    
    ORKLegacyPasscodeStep *step = [[ORKLegacyPasscodeStep alloc] initWithIdentifier:PasscodeStepIdentifier];
    step.passcodeFlow = passcodeFlow;
    step.passcodeType = passcodeType;
    step.text = text;
    
    ORKLegacyPasscodeStepViewController *passcodeStepViewController = [ORKLegacyPasscodeStepViewController new];
    passcodeStepViewController.passcodeDelegate = delegate;
    passcodeStepViewController.step = step;
    
    ORKLegacyPasscodeViewController *navigationController = [[ORKLegacyPasscodeViewController alloc] initWithRootViewController:passcodeStepViewController];
    return navigationController;
}

+ (BOOL)isPasscodeStoredInKeychain {
    NSDictionary *dictionary = (NSDictionary *)[ORKLegacyKeychainWrapper objectForKey:PasscodeKey error:nil];
    return ([dictionary objectForKey:KeychainDictionaryPasscodeKey]) ? YES : NO;
}

+ (BOOL)removePasscodeFromKeychain {
    return [ORKLegacyKeychainWrapper removeObjectForKey:PasscodeKey error:nil];
}

+ (void)forcePasscode:(NSString *)passcode withTouchIdEnabled:(BOOL)touchIdEnabled {
    ORKLegacyThrowInvalidArgumentExceptionIfNil(passcode)
    [ORKLegacyPasscodeStepViewController savePasscode:passcode withTouchIdEnabled:touchIdEnabled];
}

@end
