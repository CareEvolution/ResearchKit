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


#import "ORK1PasscodeStepViewController.h"
#import "ORK1PasscodeStepViewController_Internal.h"

#import "ORK1PasscodeStepView.h"
#import "ORK1StepHeaderView_Internal.h"
#import "ORK1TextFieldView.h"

#import "ORK1PasscodeViewController.h"
#import "ORK1StepViewController_Internal.h"

#import "ORK1PasscodeStep.h"
#import "ORK1Result.h"

#import "ORK1KeychainWrapper.h"
#import "ORK1Helpers_Internal.h"

#import <AudioToolbox/AudioToolbox.h>
#import <LocalAuthentication/LocalAuthentication.h>

static CGFloat const kForgotPasscodeVerticalPadding     = 50.0f;
static CGFloat const kForgotPasscodeHorizontalPadding   = 30.0f;
static CGFloat const kForgotPasscodeHeight              = 100.0f;

@implementation ORK1PasscodeStepViewController {
    ORK1PasscodeStepView *_passcodeStepView;
    CGFloat _originalForgotPasscodeY;
    UIButton* _forgotPasscodeButton;
    UITextField *_accessibilityPasscodeField;
    NSMutableString *_passcode;
    NSMutableString *_confirmPasscode;
    NSInteger _numberOfFilledBullets;
    ORK1PasscodeState _passcodeState;
    BOOL _shouldResignFirstResponder;
    BOOL _isChangingState;
    BOOL _isTouchIdAuthenticated;
    BOOL _isPasscodeSaved;
    LAContext *_touchContext;
    ORK1PasscodeType _authenticationPasscodeType;
    BOOL _useTouchId;
}

- (ORK1PasscodeStep *)passcodeStep {
    return (ORK1PasscodeStep *)self.step;
}

- (void)stepDidChange {
    [super stepDidChange];
    
    [_accessibilityPasscodeField removeFromSuperview];
    _accessibilityPasscodeField = nil;
    
    [_passcodeStepView removeFromSuperview];
    _passcodeStepView = nil;
    
    if (self.step && [self isViewLoaded]) {
        
        _accessibilityPasscodeField = [UITextField new];
        _accessibilityPasscodeField.hidden = YES;
        _accessibilityPasscodeField.delegate = self;
        _accessibilityPasscodeField.secureTextEntry = YES;
        _accessibilityPasscodeField.keyboardType = UIKeyboardTypeNumberPad;
        [self.view addSubview:_accessibilityPasscodeField];
        
        _passcodeStepView = [[ORK1PasscodeStepView alloc] initWithFrame:self.view.bounds];
        _passcodeStepView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _passcodeStepView.headerView.instructionTextView.textValue = [self passcodeStep].text;
        _passcodeStepView.textField.delegate = self;
        [self.view addSubview:_passcodeStepView];
        
        _passcode = [NSMutableString new];
        _confirmPasscode = [NSMutableString new];
        _numberOfFilledBullets = 0;
        _shouldResignFirstResponder = NO;
        _isChangingState = NO;
        _isTouchIdAuthenticated = NO;
        _isPasscodeSaved = NO;
        _useTouchId = YES;
        
        // If this has text, we should add the forgot passcode button with this title
        if ([self hasForgotPasscode]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        
            CGFloat x = kForgotPasscodeHorizontalPadding;
            _originalForgotPasscodeY = self.view.bounds.size.height - kForgotPasscodeVerticalPadding - kForgotPasscodeHeight;
            CGFloat width = self.view.bounds.size.width - 2 * kForgotPasscodeHorizontalPadding;

            UIButton *forgotPasscodeButton = [ORK1TextButton new];
            forgotPasscodeButton.contentEdgeInsets = (UIEdgeInsets){12, 10, 8, 10};
            forgotPasscodeButton.frame = CGRectMake(x, _originalForgotPasscodeY, width, kForgotPasscodeHeight);
            
            NSString *buttonTitle = [self forgotPasscodeButtonText];
            [forgotPasscodeButton setTitle:buttonTitle forState:UIControlStateNormal];
            [forgotPasscodeButton addTarget:self
                                     action:@selector(forgotPasscodeTapped)
                           forControlEvents:UIControlEventTouchUpInside];
            
            [self.view addSubview:forgotPasscodeButton];            
            _forgotPasscodeButton = forgotPasscodeButton;
        }
        
        // Set the starting passcode state and textfield based on flow.
        ORK1PasscodeStep *passcodeStep = [self passcodeStep];
        switch (passcodeStep.passcodeFlow) {
            case ORK1PasscodeFlowCreate:
                _passcodeStepView.textField.numberOfDigits = [self numberOfDigitsForPasscodeType:passcodeStep.passcodeType];
                [self changeStateTo:ORK1PasscodeStateEntry];
                break;
                
            case ORK1PasscodeFlowAuthenticate:
                [self setValuesFromKeychain];
                _passcodeStepView.textField.numberOfDigits = [self numberOfDigitsForPasscodeType:_authenticationPasscodeType];
                [self changeStateTo:ORK1PasscodeStateEntry];
                break;
                
            case ORK1PasscodeFlowEdit:
                [self setValuesFromKeychain];
                _passcodeStepView.textField.numberOfDigits = [self numberOfDigitsForPasscodeType:_authenticationPasscodeType];
                [self changeStateTo:ORK1PasscodeStateOldEntry];
                break;
        }
        
        // If Touch ID was enabled then present it for authentication flow.
        if (_useTouchId &&
            passcodeStep.passcodeFlow == ORK1PasscodeFlowAuthenticate) {
            [self promptTouchId];
        }
        
        // Check to see if cancel button should be set or not.
        if (self.passcodeDelegate &&
            [self.passcodeDelegate respondsToSelector:@selector(passcodeViewControllerDidCancel:)]) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:ORK1LocalizedString(@"BUTTON_CANCEL", nil)
                                                                                      style:UIBarButtonItemStylePlain
                                                                                     target:self
                                                                                     action:@selector(cancelButtonAction)];
        }
    
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(makePasscodeViewBecomeFirstResponder)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Destructive: Only clear the passcode when the step starts in creation mode
    if ([self passcodeStep].passcodeFlow == ORK1PasscodeFlowCreate) {
        [self removePasscodeFromKeychain];
    }
    
    if (!_shouldResignFirstResponder) {
        [self.view layoutIfNeeded]; // layout pass might be required before showing the keyboard
        [self makePasscodeViewBecomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self makePasscodeViewResignFirstResponder];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self stepDidChange];
}

- (void)updatePasscodeView {
    
    switch (_passcodeState) {
        case ORK1PasscodeStateEntry:
            _passcodeStepView.headerView.captionLabel.text = ORK1LocalizedString(@"PASSCODE_PROMPT_MESSAGE", nil);
            _numberOfFilledBullets = 0;
            _accessibilityPasscodeField.text = @"";
            _passcode = [NSMutableString new];
            _confirmPasscode = [NSMutableString new];
            break;
            
        case ORK1PasscodeStateConfirm:
            _passcodeStepView.headerView.captionLabel.text = ORK1LocalizedString(@"PASSCODE_CONFIRM_MESSAGE", nil);
            _numberOfFilledBullets = 0;
            _accessibilityPasscodeField.text = @"";
            _confirmPasscode = [NSMutableString new];
            break;
            
        case ORK1PasscodeStateSaved:
            _passcodeStepView.headerView.captionLabel.text = ORK1LocalizedString(@"PASSCODE_SAVED_MESSAGE", nil);
            _passcodeStepView.headerView.instructionTextView.textValue = @"";
            _passcodeStepView.textField.hidden = YES;
            [self makePasscodeViewResignFirstResponder];
            break;
            
        case ORK1PasscodeStateOldEntry:
            _passcodeStepView.headerView.captionLabel.text = ORK1LocalizedString(@"PASSCODE_OLD_ENTRY_MESSAGE", nil);
            _numberOfFilledBullets = 0;
            _accessibilityPasscodeField.text = @"";
            _passcode = [NSMutableString new];
            _confirmPasscode = [NSMutableString new];
            break;
            
        case ORK1PasscodeStateNewEntry:
            _passcodeStepView.headerView.captionLabel.text = ORK1LocalizedString(@"PASSCODE_NEW_ENTRY_MESSAGE", nil);
            _numberOfFilledBullets = 0;
            _accessibilityPasscodeField.text = @"";
            _passcode = [NSMutableString new];
            _confirmPasscode = [NSMutableString new];
            break;
            
        case ORK1PasscodeStateConfirmNewEntry:
            _passcodeStepView.headerView.captionLabel.text = ORK1LocalizedString(@"PASSCODE_CONFIRM_NEW_ENTRY_MESSAGE", nil);
            _numberOfFilledBullets = 0;
            _accessibilityPasscodeField.text = @"";
            _confirmPasscode = [NSMutableString new];
            break;
    }
    
    // Regenerate the textField.
    [_passcodeStepView.textField updateTextWithNumberOfFilledBullets:_numberOfFilledBullets];
    
    // Enable input.
    _isChangingState = NO;
}

- (void)initializeInternalButtonItems {
    [super initializeInternalButtonItems];
    
    self.internalContinueButtonItem = nil;
    self.internalDoneButtonItem = nil;
}
                                                              
- (void)showValidityAlertWithMessage:(NSString *)text {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:ORK1LocalizedString(@"PASSCODE_INVALID_ALERT_TITLE", nil)
                                                                   message:text
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:ORK1LocalizedString(@"BUTTON_OK", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (ORK1StepResult *)result {
    ORK1StepResult *stepResult = [super result];
    NSDate *now = stepResult.endDate;
    
    ORK1PasscodeResult *passcodeResult = [[ORK1PasscodeResult alloc] initWithIdentifier:[self passcodeStep].identifier];
    passcodeResult.passcodeSaved = _isPasscodeSaved;
    passcodeResult.touchIdEnabled = _isTouchIdAuthenticated;
    passcodeResult.startDate = stepResult.startDate;
    passcodeResult.endDate = now;
    
    stepResult.results = @[passcodeResult];
    return stepResult;
}

- (void)addResult:(ORK1Result *)result {
    ORK1ThrowMethodUnavailableException();
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [[ORK1PasscodeStepViewController class] supportedInterfaceOrientations];
}

+ (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Helpers

- (void)changeStateTo:(ORK1PasscodeState)passcodeState {
    _passcodeState = passcodeState;
    [self updatePasscodeView];
}

- (NSInteger)numberOfDigitsForPasscodeType:(ORK1PasscodeType)passcodeType {
    switch (passcodeType) {
        case ORK1PasscodeType4Digit:
            return 4;
        case ORK1PasscodeType6Digit:
            return 6;
    }
}

- (void)cancelButtonAction {
    if (self.passcodeDelegate &&
        [self.passcodeDelegate respondsToSelector:@selector(passcodeViewControllerDidCancel:)]) {
        [self.passcodeDelegate passcodeViewControllerDidCancel:self];
    }
}

- (void)makePasscodeViewBecomeFirstResponder {
    _shouldResignFirstResponder = NO;
    if (![_accessibilityPasscodeField isFirstResponder]) {
        [_accessibilityPasscodeField becomeFirstResponder];
    }
}

- (void)makePasscodeViewResignFirstResponder {
    _shouldResignFirstResponder = YES;
    if ([_accessibilityPasscodeField isFirstResponder]) {
        [_accessibilityPasscodeField resignFirstResponder];
    }
}

- (void)promptTouchId {
    _touchContext = [LAContext new];
    _touchContext.localizedFallbackTitle = @"";
    
    // Check to see if the device supports Touch ID.
    if (_useTouchId &&
        [_touchContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil]) {
        /// Device does support Touch ID.
        
        // Resign the keyboard to allow the alert to be centered on the screen.
        [self makePasscodeViewResignFirstResponder];
        
        NSString *localizedReason = ORK1LocalizedString(@"PASSCODE_TOUCH_ID_MESSAGE", nil);
        ORK1WeakTypeOf(self) weakSelf = self;
        [_touchContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                      localizedReason:localizedReason
                                reply:^(BOOL success, NSError *error) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                ORK1StrongTypeOf(self) strongSelf = weakSelf;
                
                if (success) {
                    // Store that user passed authentication.
                    _isTouchIdAuthenticated = YES;
                    
                    // Send a delegate callback for authentication flow.
                    if ([strongSelf passcodeStep].passcodeFlow == ORK1PasscodeFlowAuthenticate) {
                        [strongSelf.passcodeDelegate passcodeViewControllerDidFinishWithSuccess:strongSelf];
                    }
                } else if (error.code != LAErrorUserCancel) {
                    // Display the error message.
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:ORK1LocalizedString(@"PASSCODE_TOUCH_ID_ERROR_ALERT_TITLE", nil)
                                                                                   message:error.localizedDescription
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:ORK1LocalizedString(@"BUTTON_OK", nil)
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {
                                                                ORK1StrongTypeOf(self) strongSelf = weakSelf;
                                                                [strongSelf makePasscodeViewBecomeFirstResponder];
                                                            }]];
                    [strongSelf presentViewController:alert animated:YES completion:nil];
                } else if (error.code == LAErrorUserCancel) {

                    // call becomeFirstResponder here to show the keyboard. dispatch to main queue with
                    // delay because without it, the transition from the touch ID context back to the app
                    // inexplicably causes the keyboard to be invisble. It's not hidden, as user can still
                    // tap keys, but cannot see them
                    
                    double delayInSeconds = 0.3;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        [strongSelf makePasscodeViewBecomeFirstResponder];
                    });
                }
                
                [strongSelf finishTouchId];
            });
        }];
        
    } else {
        /// Device does not support Touch ID.
        [self finishTouchId];
    }
}

- (void)promptTouchIdWithDelay {
    
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    ORK1WeakTypeOf(self) weakSelf = self;
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        ORK1StrongTypeOf(self) strongSelf = weakSelf;
        [strongSelf promptTouchId];
    });
}

- (void)finishTouchId {
    // Only save to keychain if it is not in authenticate flow.
    ORK1PasscodeFlow passcodeFlow = [self passcodeStep].passcodeFlow;
    if (passcodeFlow != ORK1PasscodeFlowAuthenticate) {
        [self savePasscodeToKeychain];
    }
    
    if (passcodeFlow == ORK1PasscodeFlowCreate) {
        // If it is in creation flow (consent step), go to the next step.
        [self goForward];
    } else if (passcodeFlow == ORK1PasscodeFlowAuthenticate) {
        // If it is in authentication flow (any task), go to the next step.
        [self goForward];
    } else if (passcodeFlow == ORK1PasscodeFlowEdit) {
        // If it is in editing flow, send a delegate callback.
        [self.passcodeDelegate passcodeViewControllerDidFinishWithSuccess:self];
    }
}

- (void)savePasscodeToKeychain {
    [[self class] savePasscode:_passcode withTouchIdEnabled:_isTouchIdAuthenticated];
    _isPasscodeSaved = YES;     // otherwise an exception would have been thrown
}

+ (void)savePasscode:(NSString *)passcode withTouchIdEnabled:(BOOL)touchIdEnabled {
    ORK1ThrowInvalidArgumentExceptionIfNil(passcode)
    NSDictionary *dictionary = @{
                                 KeychainDictionaryPasscodeKey: [passcode copy],
                                 KeychainDictionaryTouchIdKey: @(touchIdEnabled)
                                 };
    NSError *error;
    [ORK1KeychainWrapper setObject:dictionary forKey:PasscodeKey error:&error];
    if (error) {
        @throw [NSException exceptionWithName:NSGenericException reason:error.localizedDescription userInfo:nil];
    }
}

- (void)removePasscodeFromKeychain {
    NSError *error;
    [ORK1KeychainWrapper objectForKey:PasscodeKey error:&error];
    
    if (!error) {
        [ORK1KeychainWrapper removeObjectForKey:PasscodeKey error:&error];
    
        if (error) {
            @throw [NSException exceptionWithName:NSGenericException reason:error.localizedDescription userInfo:nil];
        }
    }
}

- (BOOL)passcodeMatchesKeychain {
    NSError *error;
    NSDictionary *dictionary = (NSDictionary *) [ORK1KeychainWrapper objectForKey:PasscodeKey error:&error];
    if (error) {
        [self throwExceptionWithKeychainError:error];
    }
    
    NSString *storedPasscode = dictionary[KeychainDictionaryPasscodeKey];
    return [storedPasscode isEqualToString:_passcode];
}

- (void)setValuesFromKeychain {
    NSError *error;
    NSDictionary *dictionary = (NSDictionary*) [ORK1KeychainWrapper objectForKey:PasscodeKey error:&error];
    if (error) {
        [self throwExceptionWithKeychainError:error];
    }
    
    NSString *storedPasscode = dictionary[KeychainDictionaryPasscodeKey];
    _authenticationPasscodeType = (storedPasscode.length == 4) ? ORK1PasscodeType4Digit : ORK1PasscodeType6Digit;
    
    if ([self passcodeStep].passcodeFlow == ORK1PasscodeFlowAuthenticate) {
        _useTouchId = [dictionary[KeychainDictionaryTouchIdKey] boolValue];
    }
}

- (void)wrongAttempt {
    
    // Vibrate the device, if available.
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
    // Shake animation.
    CAKeyframeAnimation *shakeAnimation = [CAKeyframeAnimation animation];
    shakeAnimation.keyPath = @"position.x";
    shakeAnimation.values = @[ @0, @15, @-15, @15, @-15, @0 ];
    shakeAnimation.keyTimes = @[ @0, @(1 / 8.0), @(3 / 8.0), @(5 / 8.0), @(7 / 8.0), @1 ];
    shakeAnimation.duration = 0.27;
    shakeAnimation.delegate = self;
    shakeAnimation.additive = YES;
    
    [_passcodeStepView.textField.layer addAnimation:shakeAnimation forKey:@"shakeAnimation"];
    
    // Update the passcode view after the shake animation has ended.
    double delayInSeconds = 0.27;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    ORK1WeakTypeOf(self) weakSelf = self;
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        ORK1StrongTypeOf(self) strongSelf = weakSelf;
        [strongSelf updatePasscodeView];
    });
}

- (void)throwExceptionWithKeychainError:(NSError *)error {
    NSString *errorReason = error.localizedDescription;
    if (error.code == errSecItemNotFound) {
        errorReason = @"There is no passcode stored in the keychain.";
    }
    @throw [NSException exceptionWithName:NSGenericException reason:errorReason userInfo:nil];
}

#pragma mark - Passcode flows

- (void)passcodeFlowCreate {

    /* Passcode Flow Create
        1) ORK1PasscodeStateEntry        - User enters a passcode.
        2) ORK1PasscodeStateConfirm      - User re-enters the passcode.
        3) ORK1SavedStateSaved           - User is shown a passcode saved message.
        4) TouchID                      - A Touch ID prompt is shown.
     */
    
    if (_passcodeState == ORK1PasscodeStateEntry) {
        // Move to confirm state.
        [self changeStateTo:ORK1PasscodeStateConfirm];
    } else if (_passcodeState == ORK1PasscodeStateConfirm) {
        // Check to see if the input matches the first passcode.
        if ([_passcode isEqualToString:_confirmPasscode]) {
            // Move to saved state.
            [self changeStateTo:ORK1PasscodeStateSaved];
            
            // Show Touch ID prompt after a short delay of showing passcode saved message.
            [self promptTouchIdWithDelay];
        } else {
            // Visual cue.
            [self wrongAttempt];
            
            // If the input does not match, change back to entry state.
            [self changeStateTo:ORK1PasscodeStateEntry];
            
            // Show an alert to the user.
            [self showValidityAlertWithMessage:ORK1LocalizedString(@"PASSCODE_INVALID_ALERT_MESSAGE", nil)];
        }
    }
}

- (void)passcodeFlowEdit {
    
    /* Passcode Flow Edit
        1) ORK1PasscodeStateOldEntry                 - User enters their old passcode.
        2) ORK1PasscodeStateNewEntry                 - User enters a new passcode.
        3) ORK1PasscodeStateConfirmNewEntry          - User re-enters the new passcode.
        4) ORK1PasscodeSaved                         - User is shown a passcode saved message.
        5) TouchID                                  - A Touch ID prompt is shown.
     */
    
    if (_passcodeState == ORK1PasscodeStateOldEntry) {
        // Check if the inputted passcode matches the old user passcode.
        if ([self passcodeMatchesKeychain]) {
            // Move to new entry step.
            _passcodeStepView.textField.numberOfDigits = [self numberOfDigitsForPasscodeType:[self passcodeStep].passcodeType];
            [self changeStateTo:ORK1PasscodeStateNewEntry];
        } else {
            // Failed authentication, send delegate callback.
            [self.passcodeDelegate passcodeViewControllerDidFailAuthentication:self];
                
            // Visual cue.
            [self wrongAttempt];
        }
    } else if (_passcodeState == ORK1PasscodeStateNewEntry) {
        // Move to confirm new entry state.
        [self changeStateTo:ORK1PasscodeStateConfirmNewEntry];
    } else if ( _passcodeState == ORK1PasscodeStateConfirmNewEntry) {
        // Check to see if the input matches the first passcode.
        if ([_passcode isEqualToString:_confirmPasscode]) {
            // Move to saved state.
            [self changeStateTo:ORK1PasscodeStateSaved];
            
            // Show Touch ID prompt after a short delay of showing passcode saved message.
            [self promptTouchIdWithDelay];
        } else {
            // Visual cue.
            [self wrongAttempt];
            
            // If the input does not match, change back to entry state.
            [self changeStateTo:ORK1PasscodeStateNewEntry];
            
            // Show an alert to the user.
            [self showValidityAlertWithMessage:ORK1LocalizedString(@"PASSCODE_INVALID_ALERT_MESSAGE", nil)];
        }
    }
    
}

- (void)passcodeFlowAuthenticate {
    
    /* Passcode Flow Authenticate
        1) TouchID                                  - A Touch ID prompt is shown.
        1) ORK1PasscodeStateEntry                    - User enters their passcode.
     */
    
    if (_passcodeState == ORK1PasscodeStateEntry) {
        if ([self passcodeMatchesKeychain]) {
            // Passed authentication, send delegate callback.
            [self.passcodeDelegate passcodeViewControllerDidFinishWithSuccess:self];
            
            // If we're in a task with many steps, time to go to the next one.
            [self goForward];
        } else {
            // Failed authentication, send delegate callback.
            [self.passcodeDelegate passcodeViewControllerDidFailAuthentication:self];
                
            // Visual cue.
            [self wrongAttempt];
        }
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    ORK1PasscodeTextField *passcodeTextField = _passcodeStepView.textField;
    [passcodeTextField insertText:string];

    // Disable input while changing states.
    if (_isChangingState) {
        return !_isChangingState;
    }
    
    NSString *text = [passcodeTextField.text stringByReplacingCharactersInRange:range withString:string];
    
    // User entered a character.
    if (text.length < passcodeTextField.text.length) {
        // User hit the backspace button.
        if (_numberOfFilledBullets > 0) {
            _numberOfFilledBullets--;
            
            // Remove last character
            if (_passcodeState == ORK1PasscodeStateEntry ||
                _passcodeState == ORK1PasscodeStateOldEntry ||
                _passcodeState == ORK1PasscodeStateNewEntry) {
                [_passcode deleteCharactersInRange:NSMakeRange([_passcode length]-1, 1)];
            } else if (_passcodeState == ORK1PasscodeStateConfirm ||
                       _passcodeState == ORK1PasscodeStateConfirmNewEntry) {
                [_confirmPasscode deleteCharactersInRange:NSMakeRange([_confirmPasscode length]-1, 1)];
            }
        }
    } else if (_numberOfFilledBullets < passcodeTextField.numberOfDigits) {
        // Only allow numeric characters besides backspace (covered by the previous if statement).
        if (![[NSScanner scannerWithString:string] scanFloat:NULL]) {
            [self showValidityAlertWithMessage:ORK1LocalizedString(@"PASSCODE_TEXTFIELD_INVALID_INPUT_MESSAGE", nil)];
            return NO;
        }
        
        // Store the typed input.
        if (_passcodeState == ORK1PasscodeStateEntry ||
            _passcodeState == ORK1PasscodeStateOldEntry ||
            _passcodeState == ORK1PasscodeStateNewEntry) {
            [_passcode appendString:string];
        } else if (_passcodeState == ORK1PasscodeStateConfirm ||
                   _passcodeState == ORK1PasscodeStateConfirmNewEntry) {
            [_confirmPasscode appendString:string];
        }
        
        // User entered a new character.
        _numberOfFilledBullets++;
    }
    [passcodeTextField updateTextWithNumberOfFilledBullets:_numberOfFilledBullets];
    
    // User entered all characters.
    if (_numberOfFilledBullets == passcodeTextField.numberOfDigits) {
        // Disable input.
        _isChangingState = YES;
        
        // Show the user the last digit was entered before continuing.
        double delayInSeconds = 0.25;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        ORK1WeakTypeOf(self) weakSelf = self;
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            ORK1StrongTypeOf(self) strongSelf = weakSelf;
            
            switch ([strongSelf passcodeStep].passcodeFlow) {
                case ORK1PasscodeFlowCreate:
                    [strongSelf passcodeFlowCreate];
                    break;
                    
                case ORK1PasscodeFlowAuthenticate:
                    [strongSelf passcodeFlowAuthenticate];
                    break;
                    
                case ORK1PasscodeFlowEdit:
                    [strongSelf passcodeFlowEdit];
                    break;
            }
        });
    }
    
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return _shouldResignFirstResponder;
}

- (void)forgotPasscodeTapped {
    if ([self.passcodeDelegate respondsToSelector:@selector(passcodeViewControllerForgotPasscodeTapped:)]) {
        [self.passcodeDelegate passcodeViewControllerForgotPasscodeTapped:self ];
    }
}

- (BOOL)hasForgotPasscode {
    if (([self passcodeStep].passcodeFlow == ORK1PasscodeFlowAuthenticate) &&
        [self.passcodeDelegate respondsToSelector:@selector(passcodeViewControllerForgotPasscodeTapped:)]) {
        return YES;
    }
    return NO;
}

- (NSString *)forgotPasscodeButtonText {
    if ([self.passcodeDelegate respondsToSelector:@selector(passcodeViewControllerTextForForgotPasscode:)]) {
        return [self.passcodeDelegate passcodeViewControllerTextForForgotPasscode: self];
    }
    return ORK1LocalizedString(@"PASSCODE_FORGOT_BUTTON_TITLE", @"Prompt for user forgetting their passcode");
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notification {
    
    CGFloat keyboardHeight = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    
    double animationDuration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:animationDuration animations:^{
        [_forgotPasscodeButton setFrame:CGRectMake(_forgotPasscodeButton.frame.origin.x, _originalForgotPasscodeY - keyboardHeight, _forgotPasscodeButton.frame.size.width, _forgotPasscodeButton.frame.size.height)];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    
    double animationDuration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    [UIView animateWithDuration:animationDuration animations:^{
         [_forgotPasscodeButton setFrame:CGRectMake(_forgotPasscodeButton.frame.origin.x, _originalForgotPasscodeY, _forgotPasscodeButton.frame.size.width, _forgotPasscodeButton.frame.size.height)];
     }];
}

@end
