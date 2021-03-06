/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 Copyright (c) 2015, Ricardo Sánchez-Sáez.

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


#import "ORKConsentSceneViewController.h"
#import "ORKConsentSceneViewController_Internal.h"

#import "ORKNavigationContainerView_Internal.h"
#import "ORKStepHeaderView_Internal.h"
#import "ORKTintedImageView.h"
#import "ORKVerticalContainerView_Internal.h"

#import "ORKConsentLearnMoreViewController.h"

#import "ORKConsentDocument_Internal.h"
#import "ORKConsentSection_Private.h"

#import "ORKHelpers_Internal.h"
#import "ORKSkin.h"


@interface ORKConsentSceneView ()

@property (nonatomic, strong) ORKConsentSection *consentSection;

@end

@implementation ORKConsentSceneView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView.shouldApplyTint = YES;
        self.imageView.enableTintedImageCaching = YES;
    }
    return self;
}

- (void)setConsentSection:(ORKConsentSection *)consentSection {
    _consentSection = consentSection;
    
    BOOL isOverview = (consentSection.type == ORKConsentSectionTypeOverview);
    self.verticalCenteringEnabled = NO;
    self.continueHugsContent =  isOverview;
    
    self.headerView.instructionLabel.hidden = ![consentSection summary].length;
    
    self.imageView.image = consentSection.image;
    self.headerView.instructionLabel.text = [consentSection summary];
    
}

@end


static NSString *localizedLearnMoreForType(ORKConsentSectionType sectionType) {
    NSString *str = ORKLocalizedString(@"BUTTON_LEARN_MORE", nil);
    switch (sectionType) {
        case ORKConsentSectionTypeOverview:
            str = ORKLocalizedString(@"LEARN_MORE_WELCOME", nil);
            break;
        case ORKConsentSectionTypeDataGathering:
            str = ORKLocalizedString(@"LEARN_MORE_DATA_GATHERING", nil);
            break;
        case ORKConsentSectionTypePrivacy:
            str = ORKLocalizedString(@"LEARN_MORE_PRIVACY", nil);
            break;
        case ORKConsentSectionTypeDataUse:
            str = ORKLocalizedString(@"LEARN_MORE_DATA_USE", nil);
            break;
        case ORKConsentSectionTypeTimeCommitment:
            str = ORKLocalizedString(@"LEARN_MORE_TIME_COMMITMENT", nil);
            break;
        case ORKConsentSectionTypeStudySurvey:
            str = ORKLocalizedString(@"LEARN_MORE_STUDY_SURVEY", nil);
            break;
        case ORKConsentSectionTypeStudyTasks:
            str = ORKLocalizedString(@"LEARN_MORE_TASKS", nil);
            break;
        case ORKConsentSectionTypeWithdrawing:
            str = ORKLocalizedString(@"LEARN_MORE_WITHDRAWING", nil);
            break;
        case ORKConsentSectionTypeOnlyInDocument:
            assert(0); // assert and fall through to custom
        case ORKConsentSectionTypeCustom:
            break;
    }
    return str;
}


@implementation ORKConsentSceneViewController {
    ORKNavigationContainerView *_navigationFooterView;
    NSArray<NSLayoutConstraint *> *_constraints;
    
}

- (instancetype)initWithSection:(ORKConsentSection *)section {
    self = [super init];
    if (self) {
        _section = section;
        self.title = section.title;
        self.learnMoreButtonTitle = _section.customLearnMoreButtonTitle;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _sceneView = [ORKConsentSceneView new];
    _sceneView.consentSection = _section;
    _sceneView.imageView.hidden = _imageHidden;
    
    [self.view addSubview:_sceneView];
    
    if (_section.content.length||_section.htmlContent.length || _section.contentURL) {
        _sceneView.headerView.learnMoreButtonItem = [[UIBarButtonItem alloc] initWithTitle:_learnMoreButtonTitle ? : localizedLearnMoreForType(_section.type) style:UIBarButtonItemStylePlain target:self action:@selector(showContent:)];
    }
    [self setupNavigationFooterView];
    [self setupConstraints];
}

- (void)setupNavigationFooterView {
    if (!_navigationFooterView) {
        _navigationFooterView = [[ORKNavigationContainerView alloc] initFromStepViewController:nil];
    }
    _navigationFooterView.continueButtonItem = _continueButtonItem;
    _navigationFooterView.cancelButtonItem = _cancelButtonItem;
    _navigationFooterView.continueEnabled = YES;
    [_navigationFooterView updateContinueAndSkipEnabled];
    [self.view addSubview:_navigationFooterView];
}

- (void)setupConstraints {
    if (_constraints) {
        [NSLayoutConstraint deactivateConstraints:_constraints];
    }
    _constraints = nil;
    _sceneView.translatesAutoresizingMaskIntoConstraints = NO;
    _navigationFooterView.translatesAutoresizingMaskIntoConstraints = NO;
    
    _constraints = @[
                     [NSLayoutConstraint constraintWithItem:_sceneView
                                                  attribute:NSLayoutAttributeTop
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.view.safeAreaLayoutGuide
                                                  attribute:NSLayoutAttributeTop
                                                 multiplier:1.0
                                                   constant:0.0],
                     [NSLayoutConstraint constraintWithItem:_sceneView
                                                  attribute:NSLayoutAttributeLeft
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.view.safeAreaLayoutGuide
                                                  attribute:NSLayoutAttributeLeft
                                                 multiplier:1.0
                                                   constant:0.0],
                     [NSLayoutConstraint constraintWithItem:_sceneView
                                                  attribute:NSLayoutAttributeRight
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.view.safeAreaLayoutGuide
                                                  attribute:NSLayoutAttributeRight
                                                 multiplier:1.0
                                                   constant:0.0],
                     [NSLayoutConstraint constraintWithItem:_navigationFooterView
                                                  attribute:NSLayoutAttributeBottom
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.view
                                                  attribute:NSLayoutAttributeBottom
                                                 multiplier:1.0
                                                   constant:0.0],
                     [NSLayoutConstraint constraintWithItem:_navigationFooterView
                                                  attribute:NSLayoutAttributeLeft
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.view
                                                  attribute:NSLayoutAttributeLeft
                                                 multiplier:1.0
                                                   constant:0.0],
                     [NSLayoutConstraint constraintWithItem:_navigationFooterView
                                                  attribute:NSLayoutAttributeRight
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.view
                                                  attribute:NSLayoutAttributeRight
                                                 multiplier:1.0
                                                   constant:0.0],
                     [NSLayoutConstraint constraintWithItem:_sceneView
                                                  attribute:NSLayoutAttributeBottom
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:_navigationFooterView
                                                  attribute:NSLayoutAttributeTop
                                                 multiplier:1.0
                                                   constant:0.0]
                     ];
    [NSLayoutConstraint activateConstraints:_constraints];
}


- (void)setImageHidden:(BOOL)imageHidden {
    _imageHidden = imageHidden;
    _sceneView.imageView.hidden = imageHidden;
}

- (void)setContinueButtonItem:(UIBarButtonItem *)continueButtonItem {
    _continueButtonItem = continueButtonItem;
    _navigationFooterView.continueButtonItem = continueButtonItem;
}

- (void)setCancelButtonItem:(UIBarButtonItem *)cancelButtonItem {
    _cancelButtonItem = cancelButtonItem;
    _navigationFooterView.cancelButtonItem = cancelButtonItem;
}

- (void)setLearnMoreButtonTitle:(NSString *)learnMoreButtonTitle {
    _learnMoreButtonTitle = learnMoreButtonTitle;
    
    UIBarButtonItem *item = _sceneView.headerView.learnMoreButtonItem;
    if (item) {
        item.title = _learnMoreButtonTitle ? : localizedLearnMoreForType(_section.type);
        _sceneView.headerView.learnMoreButtonItem = item;
    }
}

- (UIScrollView *)scrollView {
    return (UIScrollView *)self.view;
}

- (void)scrollToTopAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
    ORKConsentSceneView *consentSceneView = (ORKConsentSceneView *)self.view;
    CGRect targetBounds = consentSceneView.bounds;
    targetBounds.origin.y = 0;
    if (animated) {
        [UIView animateWithDuration:ORKScrollToTopAnimationDuration animations:^{
            consentSceneView.bounds = targetBounds;
        } completion:completion];
    } else {
        consentSceneView.bounds = targetBounds;
        if (completion) {
            completion(YES);
        }
    }
}

#pragma mark - Action

- (IBAction)showContent:(id)sender {
    ORKConsentLearnMoreViewController *viewController = nil;
    
    if (_section.contentURL) {
        viewController = [[ORKConsentLearnMoreViewController alloc] initWithContentURL:_section.contentURL];
    } else {
        viewController = [[ORKConsentLearnMoreViewController alloc] initWithHTMLContent:((_section.htmlContent.length > 0) ? _section.htmlContent : _section.escapedContent)];
    }
    viewController.title = _section.title ?: ORKLocalizedString(@"CONSENT_LEARN_MORE_TITLE", nil);
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    navigationController.navigationBar.prefersLargeTitles = YES;
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationOverFullScreen;
}

@end
