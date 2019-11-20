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


#import "ORK1ConsentReviewStepViewController.h"

#import "ORK1ConsentReviewController.h"
#import "ORK1FormStepViewController.h"
#import "ORK1SignatureStepViewController.h"
#import "ORK1StepViewController_Internal.h"
#import "ORK1TaskViewController_Internal.h"

#import "ORK1AnswerFormat_Internal.h"
#import "ORK1ConsentDocument_Internal.h"
#import "ORK1ConsentReviewStep.h"
#import "ORK1ConsentSignature.h"
#import "ORK1FormStep.h"
#import "ORK1Result.h"
#import "ORK1SignatureStep.h"
#import "ORK1Step_Private.h"

#import "ORK1Helpers_Internal.h"
#import "UIBarButtonItem+ORK1BarButtonItem.h"


@interface ORK1ConsentReviewStepViewController () <UIPageViewControllerDelegate, ORK1StepViewControllerDelegate, ORK1ConsentReviewControllerDelegate> {
    ORK1ConsentSignature *_currentSignature;
    UIPageViewController *_pageViewController;

    NSMutableArray *_pageIndices;
    
    NSString *_signatureFirst;
    NSString *_signatureLast;
    UIImage *_signatureImage;
    BOOL _documentReviewed;
    
    NSUInteger _currentPageIndex;
}

@end


@implementation ORK1ConsentReviewStepViewController

- (instancetype)initWithConsentReviewStep:(ORK1ConsentReviewStep *)step result:(ORK1ConsentSignatureResult *)result {
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
    ORK1ConsentReviewStep *step = [self consentReviewStep];
    NSMutableArray *indices = [NSMutableArray array];
    if (step.consentDocument && !step.autoAgree) {
        [indices addObject:@(ORK1ConsentReviewPhaseReviewDocument)];
    }
    if (step.signature.requiresName) {
        [indices addObject:@(ORK1ConsentReviewPhaseName)];
    }
    if (step.signature.requiresSignatureImage) {
        [indices addObject:@(ORK1ConsentReviewPhaseSignature)];
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
    button.accessibilityLabel = ORK1LocalizedString(@"AX_BUTTON_BACK", nil);
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

- (ORK1FormStepViewController *)makeNameFormViewController {
    ORK1FormStep *formStep = [[ORK1FormStep alloc] initWithIdentifier:_NameFormIdentifier
                                                            title:self.step.title ? : ORK1LocalizedString(@"CONSENT_NAME_TITLE", nil)
                                                             text:self.step.text];
    formStep.useSurveyMode = NO;
    
    ORK1TextAnswerFormat *nameAnswerFormat = [ORK1TextAnswerFormat textAnswerFormat];
    nameAnswerFormat.multipleLines = NO;
    nameAnswerFormat.autocapitalizationType = UITextAutocapitalizationTypeWords;
    nameAnswerFormat.autocorrectionType = UITextAutocorrectionTypeNo;
    nameAnswerFormat.spellCheckingType = UITextSpellCheckingTypeNo;
    ORK1FormItem *givenNameFormItem = [[ORK1FormItem alloc] initWithIdentifier:_GivenNameIdentifier
                                                              text:ORK1LocalizedString(@"CONSENT_NAME_GIVEN", nil)
                                                      answerFormat:nameAnswerFormat];
    givenNameFormItem.placeholder = ORK1LocalizedString(@"CONSENT_NAME_PLACEHOLDER", nil);
    
    ORK1FormItem *familyNameFormItem = [[ORK1FormItem alloc] initWithIdentifier:_FamilyNameIdentifier
                                                             text:ORK1LocalizedString(@"CONSENT_NAME_FAMILY", nil)
                                                     answerFormat:nameAnswerFormat];
    familyNameFormItem.placeholder = ORK1LocalizedString(@"CONSENT_NAME_PLACEHOLDER", nil);
    
    givenNameFormItem.optional = NO;
    familyNameFormItem.optional = NO;
    
    NSArray *formItems = @[givenNameFormItem, familyNameFormItem];
    if (ORK1CurrentLocalePresentsFamilyNameFirst()) {
        formItems = @[familyNameFormItem, givenNameFormItem];
    }
    
    [formStep setFormItems:formItems];
    
    formStep.optional = NO;
    
    ORK1TextQuestionResult *givenNameDefault = [[ORK1TextQuestionResult alloc] initWithIdentifier:_GivenNameIdentifier];
    givenNameDefault.textAnswer = _signatureFirst;
    ORK1TextQuestionResult *familyNameDefault = [[ORK1TextQuestionResult alloc] initWithIdentifier:_FamilyNameIdentifier];
    familyNameDefault.textAnswer = _signatureLast;
    ORK1StepResult *defaults = [[ORK1StepResult alloc] initWithStepIdentifier:_NameFormIdentifier results:@[givenNameDefault, familyNameDefault]];
    
    ORK1FormStepViewController *viewController = [[ORK1FormStepViewController alloc] initWithStep:formStep result:defaults];
    viewController.delegate = self;
    
    return viewController;
}

- (ORK1ConsentReviewController *)makeDocumentReviewViewController {
    ORK1ConsentSignature *originalSignature = [self.consentReviewStep signature];
    ORK1ConsentDocument *origninalDocument = self.consentReviewStep.consentDocument;
    
    NSUInteger index = [origninalDocument.signatures indexOfObject:originalSignature];
    
    // Deep copy
    ORK1ConsentDocument *document = [origninalDocument copy];
    
    if (index != NSNotFound) {
        ORK1ConsentSignature *signature = document.signatures[index];
        
        if (signature.requiresName) {
            signature.givenName = _signatureFirst;
            signature.familyName = _signatureLast;
        }
    }
    
    NSString *html = [document mobileHTMLWithTitle:ORK1LocalizedString(@"CONSENT_REVIEW_TITLE", nil)
                                             detail:ORK1LocalizedString(@"CONSENT_REVIEW_INSTRUCTION", nil)];

    ORK1ConsentReviewController *reviewViewController = [[ORK1ConsentReviewController alloc] initWithHTML:html delegate:self requiresScrollToBottom:[[self consentReviewStep] requiresScrollToBottom]];
    reviewViewController.localizedReasonForConsent = [[self consentReviewStep] reasonForConsent];
    return reviewViewController;
}

static NSString *const _SignatureStepIdentifier = @"signatureStep";

- (ORK1SignatureStepViewController *)makeSignatureViewController {
    ORK1SignatureStep *step = [[ORK1SignatureStep alloc] initWithIdentifier:_SignatureStepIdentifier];
    step.optional = NO;
    ORK1SignatureStepViewController *signatureController = [[ORK1SignatureStepViewController alloc] initWithStep:step];
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
    
    ORK1ConsentReviewPhase phase = ((NSNumber *)_pageIndices[index]).integerValue;
    
    UIViewController *viewController = nil;
    switch (phase) {
        case ORK1ConsentReviewPhaseName: {
            // A form step VC with a form step with a first name and a last name
            ORK1FormStepViewController *formViewController = [self makeNameFormViewController];
            viewController = formViewController;
            break;
        }
        case ORK1ConsentReviewPhaseReviewDocument: {
            // Document review VC
            ORK1ConsentReviewController *reviewViewController = [self makeDocumentReviewViewController];
            viewController = reviewViewController;
            break;
        }
        case ORK1ConsentReviewPhaseSignature: {
            // Signature VC
            ORK1SignatureStepViewController *signatureViewController = [self makeSignatureViewController];
            viewController = signatureViewController;
            break;
        }
    }
    return viewController;
}

- (ORK1StepResult *)result {
    ORK1StepResult *parentResult = [super result];
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
            _currentSignature.signatureDate = ORK1SignatureStringFromDate([NSDate date]);
        }
    }
    
    ORK1ConsentSignatureResult *result = [[ORK1ConsentSignatureResult alloc] init];
    result.signature = _currentSignature;
    result.identifier = _currentSignature.identifier;
    result.consented = _documentReviewed;
    result.startDate = parentResult.startDate;
    result.endDate = parentResult.endDate;
    
    // Add the result
    parentResult.results = [self.addedResults arrayByAddingObject:result] ? : @[result];
    
    return parentResult;
}

- (ORK1ConsentReviewStep *)consentReviewStep {
    assert(self.step == nil || [self.step isKindOfClass:[ORK1ConsentReviewStep class]]);
    return (ORK1ConsentReviewStep *)self.step;
}

- (void)notifyDelegateOnResultChange {
    _currentSignature = nil;
    [super notifyDelegateOnResultChange];
}

#pragma mark ORK1StepViewControllerDelegate

- (void)stepViewController:(ORK1StepViewController *)stepViewController didFinishWithNavigationDirection:(ORK1StepViewControllerNavigationDirection)direction {
    if (_currentPageIndex == NSNotFound) {
        return;
    }
    
    NSInteger delta = (direction == ORK1StepViewControllerNavigationDirectionForward) ? 1 : -1;
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
        ORK1_Log_Debug(@"No view controller!");
        return;
    }
    
    NSUInteger currentIndex = _currentPageIndex;
    if (currentIndex == NSNotFound) {
        animated = NO;
    }
    
    UIPageViewControllerNavigationDirection direction = (!animated || page > currentIndex) ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
    
    ORK1AdjustPageViewControllerNavigationDirectionForRTL(&direction);
    
    _currentPageIndex = page;
    ORK1WeakTypeOf(self) weakSelf = self;
    
    //unregister ScrollView to clear hairline
    [self.taskViewController setRegisteredScrollView:nil];
    
    [_pageViewController setViewControllers:@[viewController] direction:direction animated:animated completion:^(BOOL finished) {
        if (finished) {
            ORK1StrongTypeOf(weakSelf) strongSelf = weakSelf;
            [strongSelf updateBackButton];
            
            NSUInteger currentPageIndex = strongSelf->_currentPageIndex;
            NSArray *pageIndices = strongSelf->_pageIndices;
            if (currentPageIndex < pageIndices.count
                && [[strongSelf consentReviewDelegate] respondsToSelector:@selector(consentReviewStepViewController:didShowPhase:pageIndex:)]) {
                ORK1ConsentReviewPhase phase = ((NSNumber *)pageIndices[currentPageIndex]).integerValue;
                [[strongSelf consentReviewDelegate] consentReviewStepViewController:strongSelf didShowPhase:phase pageIndex:currentPageIndex];
            }
            
            //register ScrollView to update hairline
            if ([viewController isKindOfClass:[ORK1ConsentReviewController class]]) {
                ORK1ConsentReviewController *reviewViewController =  (ORK1ConsentReviewController *)viewController;
                [strongSelf.taskViewController setRegisteredScrollView:reviewViewController.webView.scrollView];
            }
            
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
        }
    }];
}

- (void)stepViewControllerResultDidChange:(ORK1StepViewController *)stepViewController {
    if ([stepViewController.step.identifier isEqualToString:_NameFormIdentifier]) {
        // If this is the form step then update the values from the form
        ORK1StepResult *result = [stepViewController result];
        ORK1TextQuestionResult *fnr = (ORK1TextQuestionResult *)[result resultForIdentifier:_GivenNameIdentifier];
        _signatureFirst = (NSString *)fnr.textAnswer;
        ORK1TextQuestionResult *lnr = (ORK1TextQuestionResult *)[result resultForIdentifier:_FamilyNameIdentifier];
        _signatureLast = (NSString *)lnr.textAnswer;
        [self notifyDelegateOnResultChange];
        
    } else if ([stepViewController.step.identifier isEqualToString:_SignatureStepIdentifier]) {
        // If this is the signature step then update the image from the signature
        ORK1StepResult *result = [stepViewController result];
        [result.results enumerateObjectsUsingBlock:^(ORK1Result * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[ORK1SignatureResult class]]) {
                _signatureImage = ((ORK1SignatureResult *)obj).signatureImage;
                *stop = YES;
    }
        }];
        [self notifyDelegateOnResultChange];
    }
}

- (void)stepViewControllerDidFail:(ORK1StepViewController *)stepViewController withError:(NSError *)error {
    ORK1StrongTypeOf(self.delegate) strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(stepViewControllerDidFail:withError:)]) {
        [strongDelegate stepViewControllerDidFail:self withError:error];
    }
}

- (BOOL)stepViewControllerHasNextStep:(ORK1StepViewController *)stepViewController {
    if (_currentPageIndex < (_pageIndices.count - 1)) {
        return YES;
    }
    return [self hasNextStep];
}

- (BOOL)stepViewControllerHasPreviousStep:(ORK1StepViewController *)stepViewController {
    return [self hasPreviousStep];
}

- (void)stepViewController:(ORK1StepViewController *)stepViewController recorder:(ORK1Recorder *)recorder didFailWithError:(NSError *)error {
    ORK1StrongTypeOf(self.delegate) strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(stepViewController:recorder:didFailWithError:)]) {
        [strongDelegate stepViewController:self recorder:recorder didFailWithError:error];
    }
}

#pragma mark ORK1ConsentReviewControllerDelegate

- (void)consentReviewControllerDidAcknowledge:(ORK1ConsentReviewController *)consentReviewController {
    _documentReviewed = YES;
    [self notifyDelegateOnResultChange];
    [self navigateDelta:1];
}

- (void)consentReviewControllerDidCancel:(ORK1ConsentReviewController *)consentReviewController {
    _signatureFirst = nil;
    _signatureLast = nil;
    _signatureImage = nil;
    _documentReviewed = NO;
    [self notifyDelegateOnResultChange];
    
    [self goForward];
}

static NSString *const _ORK1CurrentSignatureRestoreKey = @"currentSignature";
static NSString *const _ORK1SignatureFirstRestoreKey = @"signatureFirst";
static NSString *const _ORK1SignatureLastRestoreKey = @"signatureLast";
static NSString *const _ORK1SignatureImageRestoreKey = @"signatureImage";
static NSString *const _ORK1DocumentReviewedRestoreKey = @"documentReviewed";
static NSString *const _ORK1CurrentPageIndexRestoreKey = @"currentPageIndex";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:_currentSignature forKey:_ORK1CurrentSignatureRestoreKey];
    [coder encodeObject:_signatureFirst forKey:_ORK1SignatureFirstRestoreKey];
    [coder encodeObject:_signatureLast forKey:_ORK1SignatureLastRestoreKey];
    [coder encodeObject:_signatureImage forKey:_ORK1SignatureImageRestoreKey];
    [coder encodeBool:_documentReviewed forKey:_ORK1DocumentReviewedRestoreKey];
    [coder encodeInteger:_currentPageIndex forKey:_ORK1CurrentPageIndexRestoreKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    _currentSignature = [coder decodeObjectOfClass:[ORK1ConsentSignature class]
                                            forKey:_ORK1CurrentSignatureRestoreKey];
    
    _signatureFirst = [coder decodeObjectOfClass:[NSString class] forKey:_ORK1SignatureFirstRestoreKey];
    _signatureLast = [coder decodeObjectOfClass:[NSString class] forKey:_ORK1SignatureLastRestoreKey];
    _signatureImage = [coder decodeObjectOfClass:[NSString class] forKey:_ORK1SignatureImageRestoreKey];
    _documentReviewed = [coder decodeBoolForKey:_ORK1DocumentReviewedRestoreKey];
    _currentPageIndex = [coder decodeIntegerForKey:_ORK1CurrentPageIndexRestoreKey];
    
    [self goToPage:_currentPageIndex animated:NO];
}

@end
