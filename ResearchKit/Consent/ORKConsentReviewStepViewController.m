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


#import "ORKConsentReviewStepViewController.h"

#import "ORKConsentReviewController.h"
#import "ORKFormStepViewController.h"
#import "ORKSignatureStepViewController.h"
#import "ORKStepViewController_Internal.h"
#import "ORKTaskViewController_Internal.h"

#import "ORKAnswerFormat_Internal.h"
#import "ORKConsentDocument_Internal.h"
#import "ORKConsentReviewStep.h"
#import "ORKConsentSignature.h"
#import "ORKFormStep.h"
#import "ORKResult.h"
#import "ORKSignatureStep.h"
#import "ORKStep_Private.h"

#import "ORKHelpers_Internal.h"
#import "UIBarButtonItem+ORKBarButtonItem.h"


@interface ORKLegacyConsentReviewStepViewController () <UIPageViewControllerDelegate, ORKLegacyStepViewControllerDelegate, ORKLegacyConsentReviewControllerDelegate> {
    ORKLegacyConsentSignature *_currentSignature;
    UIPageViewController *_pageViewController;

    NSMutableArray *_pageIndices;
    
    NSString *_signatureFirst;
    NSString *_signatureLast;
    UIImage *_signatureImage;
    BOOL _documentReviewed;
    
    NSUInteger _currentPageIndex;
}

@end


@implementation ORKLegacyConsentReviewStepViewController

- (instancetype)initWithConsentReviewStep:(ORKLegacyConsentReviewStep *)step result:(ORKLegacyConsentSignatureResult *)result {
    self = [super initWithStep:step];
    if (self) {
        _signatureFirst = [result.signature givenName];
        _signatureLast = [result.signature familyName];
        _signatureImage = [result.signature signatureImage];
        _documentReviewed = NO;
        
        _currentSignature = [result.signature copy];
        
        _currentPageIndex = NSNotFound;
    }
    return self;
}

- (void)stepDidChange {
    if (![self isViewLoaded]) {
        return;
    }
    
    _currentPageIndex = NSNotFound;
    ORKLegacyConsentReviewStep *step = [self consentReviewStep];
    NSMutableArray *indices = [NSMutableArray array];
    if (step.consentDocument && !step.autoAgree) {
        [indices addObject:@(ORKLegacyConsentReviewPhaseReviewDocument)];
    }
    if (step.signature.requiresName) {
        [indices addObject:@(ORKLegacyConsentReviewPhaseName)];
    }
    if (step.signature.requiresSignatureImage) {
        [indices addObject:@(ORKLegacyConsentReviewPhaseSignature)];
    }
    
    _pageIndices = indices;
    
    [self goToPage:0 animated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Prepare pageViewController
    _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                          navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                        options:nil];
    _pageViewController.delegate = self;
    
    if ([_pageViewController respondsToSelector:@selector(edgesForExtendedLayout)]) {
        _pageViewController.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    _pageViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _pageViewController.view.frame = self.view.bounds;
    [self.view addSubview:_pageViewController.view];
    [self addChildViewController:_pageViewController];
    [_pageViewController didMoveToParentViewController:self];
    
    [self stepDidChange];
}

- (UIBarButtonItem *)goToPreviousPageButtonItem {
    UIBarButtonItem *button = [UIBarButtonItem ork_backBarButtonItemWithTarget:self action:@selector(goToPreviousPage)];
    button.accessibilityLabel = ORKLegacyLocalizedString(@"AX_BUTTON_BACK", nil);
    return button;
}

- (void)updateNavLeftBarButtonItem {
    if (_currentPageIndex == 0) {
        [super updateNavLeftBarButtonItem];
    } else {
        self.navigationItem.leftBarButtonItem = [self goToPreviousPageButtonItem];
    }
}

- (void)updateBackButton {
    if (_currentPageIndex == NSNotFound) {
        return;
    }
    
    [self updateNavLeftBarButtonItem];
}

static NSString *const _NameFormIdentifier = @"nameForm";
static NSString *const _GivenNameIdentifier = @"given";
static NSString *const _FamilyNameIdentifier = @"family";

- (ORKLegacyFormStepViewController *)makeNameFormViewController {
    ORKLegacyFormStep *formStep = [[ORKLegacyFormStep alloc] initWithIdentifier:_NameFormIdentifier
                                                            title:self.step.title ? : ORKLegacyLocalizedString(@"CONSENT_NAME_TITLE", nil)
                                                             text:self.step.text];
    formStep.useSurveyMode = NO;
    
    ORKLegacyTextAnswerFormat *nameAnswerFormat = [ORKLegacyTextAnswerFormat textAnswerFormat];
    nameAnswerFormat.multipleLines = NO;
    nameAnswerFormat.autocapitalizationType = UITextAutocapitalizationTypeWords;
    nameAnswerFormat.autocorrectionType = UITextAutocorrectionTypeNo;
    nameAnswerFormat.spellCheckingType = UITextSpellCheckingTypeNo;
    ORKLegacyFormItem *givenNameFormItem = [[ORKLegacyFormItem alloc] initWithIdentifier:_GivenNameIdentifier
                                                              text:ORKLegacyLocalizedString(@"CONSENT_NAME_GIVEN", nil)
                                                      answerFormat:nameAnswerFormat];
    givenNameFormItem.placeholder = ORKLegacyLocalizedString(@"CONSENT_NAME_PLACEHOLDER", nil);
    
    ORKLegacyFormItem *familyNameFormItem = [[ORKLegacyFormItem alloc] initWithIdentifier:_FamilyNameIdentifier
                                                             text:ORKLegacyLocalizedString(@"CONSENT_NAME_FAMILY", nil)
                                                     answerFormat:nameAnswerFormat];
    familyNameFormItem.placeholder = ORKLegacyLocalizedString(@"CONSENT_NAME_PLACEHOLDER", nil);
    
    givenNameFormItem.optional = NO;
    familyNameFormItem.optional = NO;
    
    NSArray *formItems = @[givenNameFormItem, familyNameFormItem];
    if (ORKLegacyCurrentLocalePresentsFamilyNameFirst()) {
        formItems = @[familyNameFormItem, givenNameFormItem];
    }
    
    [formStep setFormItems:formItems];
    
    formStep.optional = NO;
    
    ORKLegacyTextQuestionResult *givenNameDefault = [[ORKLegacyTextQuestionResult alloc] initWithIdentifier:_GivenNameIdentifier];
    givenNameDefault.textAnswer = _signatureFirst;
    ORKLegacyTextQuestionResult *familyNameDefault = [[ORKLegacyTextQuestionResult alloc] initWithIdentifier:_FamilyNameIdentifier];
    familyNameDefault.textAnswer = _signatureLast;
    ORKLegacyStepResult *defaults = [[ORKLegacyStepResult alloc] initWithStepIdentifier:_NameFormIdentifier results:@[givenNameDefault, familyNameDefault]];
    
    ORKLegacyFormStepViewController *viewController = [[ORKLegacyFormStepViewController alloc] initWithStep:formStep result:defaults];
    viewController.delegate = self;
    
    return viewController;
}

- (ORKLegacyConsentReviewController *)makeDocumentReviewViewController {
    ORKLegacyConsentSignature *originalSignature = [self.consentReviewStep signature];
    ORKLegacyConsentDocument *origninalDocument = self.consentReviewStep.consentDocument;
    
    NSUInteger index = [origninalDocument.signatures indexOfObject:originalSignature];
    
    // Deep copy
    ORKLegacyConsentDocument *document = [origninalDocument copy];
    
    if (index != NSNotFound) {
        ORKLegacyConsentSignature *signature = document.signatures[index];
        
        if (signature.requiresName) {
            signature.givenName = _signatureFirst;
            signature.familyName = _signatureLast;
        }
    }
    
    NSString *html = [document mobileHTMLWithTitle:ORKLegacyLocalizedString(@"CONSENT_REVIEW_TITLE", nil)
                                             detail:ORKLegacyLocalizedString(@"CONSENT_REVIEW_INSTRUCTION", nil)];

    ORKLegacyConsentReviewController *reviewViewController = [[ORKLegacyConsentReviewController alloc] initWithHTML:html delegate:self requiresScrollToBottom:[[self consentReviewStep] requiresScrollToBottom]];
    reviewViewController.localizedReasonForConsent = [[self consentReviewStep] reasonForConsent];
    return reviewViewController;
}

static NSString *const _SignatureStepIdentifier = @"signatureStep";

- (ORKLegacySignatureStepViewController *)makeSignatureViewController {
    ORKLegacySignatureStep *step = [[ORKLegacySignatureStep alloc] initWithIdentifier:_SignatureStepIdentifier];
    step.optional = NO;
    ORKLegacySignatureStepViewController *signatureController = [[ORKLegacySignatureStepViewController alloc] initWithStep:step];
    signatureController.delegate = self;
    return signatureController;
}

- (void)goToPreviousPage {
    [self navigateDelta:-1];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (UIViewController *)viewControllerForIndex:(NSUInteger)index {
    if (index >= _pageIndices.count) {
        return nil;
    }
    
    ORKLegacyConsentReviewPhase phase = ((NSNumber *)_pageIndices[index]).integerValue;
    
    UIViewController *viewController = nil;
    switch (phase) {
        case ORKLegacyConsentReviewPhaseName: {
            // A form step VC with a form step with a first name and a last name
            ORKLegacyFormStepViewController *formViewController = [self makeNameFormViewController];
            viewController = formViewController;
            break;
        }
        case ORKLegacyConsentReviewPhaseReviewDocument: {
            // Document review VC
            ORKLegacyConsentReviewController *reviewViewController = [self makeDocumentReviewViewController];
            viewController = reviewViewController;
            break;
        }
        case ORKLegacyConsentReviewPhaseSignature: {
            // Signature VC
            ORKLegacySignatureStepViewController *signatureViewController = [self makeSignatureViewController];
            viewController = signatureViewController;
            break;
        }
    }
    return viewController;
}

- (ORKLegacyStepResult *)result {
    ORKLegacyStepResult *parentResult = [super result];
    if (!_currentSignature) {
        _currentSignature = [[self.consentReviewStep signature] copy];
        
        if (_currentSignature.requiresName) {
            _currentSignature.givenName = _signatureFirst;
            _currentSignature.familyName = _signatureLast;
        }
        if (_currentSignature.requiresSignatureImage) {
            _currentSignature.signatureImage = _signatureImage;
        }
        
        if (_currentSignature.signatureDateFormatString.length > 0) {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:_currentSignature.signatureDateFormatString];
            _currentSignature.signatureDate = [dateFormatter stringFromDate:[NSDate date]];
        } else {
            _currentSignature.signatureDate = ORKLegacySignatureStringFromDate([NSDate date]);
        }
    }
    
    ORKLegacyConsentSignatureResult *result = [[ORKLegacyConsentSignatureResult alloc] init];
    result.signature = _currentSignature;
    result.identifier = _currentSignature.identifier;
    result.consented = _documentReviewed;
    result.startDate = parentResult.startDate;
    result.endDate = parentResult.endDate;
    
    // Add the result
    parentResult.results = [self.addedResults arrayByAddingObject:result] ? : @[result];
    
    return parentResult;
}

- (ORKLegacyConsentReviewStep *)consentReviewStep {
    assert(self.step == nil || [self.step isKindOfClass:[ORKLegacyConsentReviewStep class]]);
    return (ORKLegacyConsentReviewStep *)self.step;
}

- (void)notifyDelegateOnResultChange {
    _currentSignature = nil;
    [super notifyDelegateOnResultChange];
}

#pragma mark ORKLegacyStepViewControllerDelegate

- (void)stepViewController:(ORKLegacyStepViewController *)stepViewController didFinishWithNavigationDirection:(ORKLegacyStepViewControllerNavigationDirection)direction {
    if (_currentPageIndex == NSNotFound) {
        return;
    }
    
    NSInteger delta = (direction == ORKLegacyStepViewControllerNavigationDirectionForward) ? 1 : -1;
    [self navigateDelta:delta];
}

- (void)navigateDelta:(NSInteger)delta {
    // Entry point for forward/back navigation.
    NSUInteger pageCount = _pageIndices.count;
    
    if (_currentPageIndex == 0 && delta < 0) {
        // Navigate back in our parent task VC.
        [self goBackward];
    } else if (_currentPageIndex >= (pageCount - 1) && delta > 0) {
        // Navigate forward in our parent task VC.
        [self goForward];
    } else {
        // Navigate within our managed steps
        [self goToPage:(_currentPageIndex + delta) animated:YES];
    }
}

- (void)goToPage:(NSInteger)page animated:(BOOL)animated {
    UIViewController *viewController = [self viewControllerForIndex:page];
    
    if (!viewController) {
        ORKLegacy_Log_Debug(@"No view controller!");
        return;
    }
    
    NSUInteger currentIndex = _currentPageIndex;
    if (currentIndex == NSNotFound) {
        animated = NO;
    }
    
    UIPageViewControllerNavigationDirection direction = (!animated || page > currentIndex) ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
    
    ORKLegacyAdjustPageViewControllerNavigationDirectionForRTL(&direction);
    
    _currentPageIndex = page;
    ORKLegacyWeakTypeOf(self) weakSelf = self;
    
    //unregister ScrollView to clear hairline
    [self.taskViewController setRegisteredScrollView:nil];
    
    [_pageViewController setViewControllers:@[viewController] direction:direction animated:animated completion:^(BOOL finished) {
        if (finished) {
            ORKLegacyStrongTypeOf(weakSelf) strongSelf = weakSelf;
            [strongSelf updateBackButton];
            
            NSUInteger currentPageIndex = strongSelf->_currentPageIndex;
            NSArray *pageIndices = strongSelf->_pageIndices;
            if (currentPageIndex < pageIndices.count
                && [[strongSelf consentReviewDelegate] respondsToSelector:@selector(consentReviewStepViewController:didShowPhase:pageIndex:)]) {
                ORKLegacyConsentReviewPhase phase = ((NSNumber *)pageIndices[currentPageIndex]).integerValue;
                [[strongSelf consentReviewDelegate] consentReviewStepViewController:strongSelf didShowPhase:phase pageIndex:currentPageIndex];
            }
            
            //register ScrollView to update hairline
            if ([viewController isKindOfClass:[ORKLegacyConsentReviewController class]]) {
                ORKLegacyConsentReviewController *reviewViewController =  (ORKLegacyConsentReviewController *)viewController;
                [strongSelf.taskViewController setRegisteredScrollView:reviewViewController.webView.scrollView];
            }
            
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
        }
    }];
}

- (void)stepViewControllerResultDidChange:(ORKLegacyStepViewController *)stepViewController {
    if ([stepViewController.step.identifier isEqualToString:_NameFormIdentifier]) {
        // If this is the form step then update the values from the form
        ORKLegacyStepResult *result = [stepViewController result];
        ORKLegacyTextQuestionResult *fnr = (ORKLegacyTextQuestionResult *)[result resultForIdentifier:_GivenNameIdentifier];
        _signatureFirst = (NSString *)fnr.textAnswer;
        ORKLegacyTextQuestionResult *lnr = (ORKLegacyTextQuestionResult *)[result resultForIdentifier:_FamilyNameIdentifier];
        _signatureLast = (NSString *)lnr.textAnswer;
        [self notifyDelegateOnResultChange];
        
    } else if ([stepViewController.step.identifier isEqualToString:_SignatureStepIdentifier]) {
        // If this is the signature step then update the image from the signature
        ORKLegacyStepResult *result = [stepViewController result];
        [result.results enumerateObjectsUsingBlock:^(ORKLegacyResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[ORKLegacySignatureResult class]]) {
                _signatureImage = ((ORKLegacySignatureResult *)obj).signatureImage;
                *stop = YES;
    }
        }];
        [self notifyDelegateOnResultChange];
    }
}

- (void)stepViewControllerDidFail:(ORKLegacyStepViewController *)stepViewController withError:(NSError *)error {
    ORKLegacyStrongTypeOf(self.delegate) strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(stepViewControllerDidFail:withError:)]) {
        [strongDelegate stepViewControllerDidFail:self withError:error];
    }
}

- (BOOL)stepViewControllerHasNextStep:(ORKLegacyStepViewController *)stepViewController {
    if (_currentPageIndex < (_pageIndices.count - 1)) {
        return YES;
    }
    return [self hasNextStep];
}

- (BOOL)stepViewControllerHasPreviousStep:(ORKLegacyStepViewController *)stepViewController {
    return [self hasPreviousStep];
}

- (void)stepViewController:(ORKLegacyStepViewController *)stepViewController recorder:(ORKLegacyRecorder *)recorder didFailWithError:(NSError *)error {
    ORKLegacyStrongTypeOf(self.delegate) strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(stepViewController:recorder:didFailWithError:)]) {
        [strongDelegate stepViewController:self recorder:recorder didFailWithError:error];
    }
}

#pragma mark ORKLegacyConsentReviewControllerDelegate

- (void)consentReviewControllerDidAcknowledge:(ORKLegacyConsentReviewController *)consentReviewController {
    _documentReviewed = YES;
    [self notifyDelegateOnResultChange];
    [self navigateDelta:1];
}

- (void)consentReviewControllerDidCancel:(ORKLegacyConsentReviewController *)consentReviewController {
    _signatureFirst = nil;
    _signatureLast = nil;
    _signatureImage = nil;
    _documentReviewed = NO;
    [self notifyDelegateOnResultChange];
    
    [self goForward];
}

static NSString *const _ORKLegacyCurrentSignatureRestoreKey = @"currentSignature";
static NSString *const _ORKLegacySignatureFirstRestoreKey = @"signatureFirst";
static NSString *const _ORKLegacySignatureLastRestoreKey = @"signatureLast";
static NSString *const _ORKLegacySignatureImageRestoreKey = @"signatureImage";
static NSString *const _ORKLegacyDocumentReviewedRestoreKey = @"documentReviewed";
static NSString *const _ORKLegacyCurrentPageIndexRestoreKey = @"currentPageIndex";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:_currentSignature forKey:_ORKLegacyCurrentSignatureRestoreKey];
    [coder encodeObject:_signatureFirst forKey:_ORKLegacySignatureFirstRestoreKey];
    [coder encodeObject:_signatureLast forKey:_ORKLegacySignatureLastRestoreKey];
    [coder encodeObject:_signatureImage forKey:_ORKLegacySignatureImageRestoreKey];
    [coder encodeBool:_documentReviewed forKey:_ORKLegacyDocumentReviewedRestoreKey];
    [coder encodeInteger:_currentPageIndex forKey:_ORKLegacyCurrentPageIndexRestoreKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    _currentSignature = [coder decodeObjectOfClass:[ORKLegacyConsentSignature class]
                                            forKey:_ORKLegacyCurrentSignatureRestoreKey];
    
    _signatureFirst = [coder decodeObjectOfClass:[NSString class] forKey:_ORKLegacySignatureFirstRestoreKey];
    _signatureLast = [coder decodeObjectOfClass:[NSString class] forKey:_ORKLegacySignatureLastRestoreKey];
    _signatureImage = [coder decodeObjectOfClass:[NSString class] forKey:_ORKLegacySignatureImageRestoreKey];
    _documentReviewed = [coder decodeBoolForKey:_ORKLegacyDocumentReviewedRestoreKey];
    _currentPageIndex = [coder decodeIntegerForKey:_ORKLegacyCurrentPageIndexRestoreKey];
    
    [self goToPage:_currentPageIndex animated:NO];
}

@end
