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


#import "RK1ConsentSceneViewController.h"
#import "RK1ConsentSceneViewController_Internal.h"

#import "RK1NavigationContainerView_Internal.h"
#import "RK1StepHeaderView_Internal.h"
#import "RK1TintedImageView.h"
#import "RK1VerticalContainerView_Internal.h"

#import "RK1ConsentLearnMoreViewController.h"

#import "RK1ConsentDocument_Internal.h"
#import "RK1ConsentSection_Private.h"

#import "RK1Helpers_Internal.h"
#import "RK1Skin.h"


@interface RK1ConsentSceneView ()

@property (nonatomic, strong) RK1ConsentSection *consentSection;

@end


@implementation RK1ConsentSceneView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView.shouldApplyTint = YES;
        self.imageView.enableTintedImageCaching = YES;
    }
    return self;
}

- (void)setConsentSection:(RK1ConsentSection *)consentSection {
    _consentSection = consentSection;
    
    BOOL isOverview = (consentSection.type == RK1ConsentSectionTypeOverview);
    self.verticalCenteringEnabled = isOverview;
    self.continueHugsContent =  isOverview;
    
    self.headerView.instructionLabel.hidden = ![consentSection summary].length;
    self.headerView.captionLabel.text = consentSection.title;
    
    self.imageView.image = consentSection.image;
    self.headerView.instructionLabel.text = [consentSection summary];
    
    self.continueSkipContainer.continueEnabled = YES;
    [self.continueSkipContainer updateContinueAndSkipEnabled];
}

@end


static NSString *localizedLearnMoreForType(RK1ConsentSectionType sectionType) {
    NSString *str = RK1LocalizedString(@"BUTTON_LEARN_MORE", nil);
    switch (sectionType) {
        case RK1ConsentSectionTypeOverview:
            str = RK1LocalizedString(@"LEARN_MORE_WELCOME", nil);
            break;
        case RK1ConsentSectionTypeDataGathering:
            str = RK1LocalizedString(@"LEARN_MORE_DATA_GATHERING", nil);
            break;
        case RK1ConsentSectionTypePrivacy:
            str = RK1LocalizedString(@"LEARN_MORE_PRIVACY", nil);
            break;
        case RK1ConsentSectionTypeDataUse:
            str = RK1LocalizedString(@"LEARN_MORE_DATA_USE", nil);
            break;
        case RK1ConsentSectionTypeTimeCommitment:
            str = RK1LocalizedString(@"LEARN_MORE_TIME_COMMITMENT", nil);
            break;
        case RK1ConsentSectionTypeStudySurvey:
            str = RK1LocalizedString(@"LEARN_MORE_STUDY_SURVEY", nil);
            break;
        case RK1ConsentSectionTypeStudyTasks:
            str = RK1LocalizedString(@"LEARN_MORE_TASKS", nil);
            break;
        case RK1ConsentSectionTypeWithdrawing:
            str = RK1LocalizedString(@"LEARN_MORE_WITHDRAWING", nil);
            break;
        case RK1ConsentSectionTypeOnlyInDocument:
            assert(0); // assert and fall through to custom
        case RK1ConsentSectionTypeCustom:
            break;
    }
    return str;
}


@implementation RK1ConsentSceneViewController

- (instancetype)initWithSection:(RK1ConsentSection *)section {
    self = [super init];
    if (self) {
        _section = section;
        self.learnMoreButtonTitle = _section.customLearnMoreButtonTitle;
    }
    return self;
}

- (void)loadView {
    _sceneView = [RK1ConsentSceneView new];
    self.view = _sceneView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _sceneView.consentSection = _section;
    _sceneView.continueSkipContainer.continueButtonItem = _continueButtonItem;
    _sceneView.imageView.hidden = _imageHidden;
    
    if (_section.content.length||_section.htmlContent.length || _section.contentURL) {
        _sceneView.headerView.learnMoreButtonItem = [[UIBarButtonItem alloc] initWithTitle:_learnMoreButtonTitle ? : localizedLearnMoreForType(_section.type) style:UIBarButtonItemStylePlain target:self action:@selector(showContent:)];
    }
}

- (void)setImageHidden:(BOOL)imageHidden {
    _imageHidden = imageHidden;
    _sceneView.imageView.hidden = imageHidden;
}

- (void)setContinueButtonItem:(UIBarButtonItem *)continueButtonItem {
    _continueButtonItem = continueButtonItem;
    _sceneView.continueSkipContainer.continueButtonItem = continueButtonItem;
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
    RK1ConsentSceneView *consentSceneView = (RK1ConsentSceneView *)self.view;
    CGRect targetBounds = consentSceneView.bounds;
    targetBounds.origin.y = 0;
    if (animated) {
        [UIView animateWithDuration:RK1ScrollToTopAnimationDuration animations:^{
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
    RK1ConsentLearnMoreViewController *viewController = nil;
    
    if (_section.contentURL) {
        viewController = [[RK1ConsentLearnMoreViewController alloc] initWithContentURL:_section.contentURL];
    } else {
        viewController = [[RK1ConsentLearnMoreViewController alloc] initWithHTMLContent:((_section.htmlContent.length > 0) ? _section.htmlContent : _section.escapedContent)];
    }
    viewController.title = _section.title ?: RK1LocalizedString(@"CONSENT_LEARN_MORE_TITLE", nil);
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationOverFullScreen;
}

@end
