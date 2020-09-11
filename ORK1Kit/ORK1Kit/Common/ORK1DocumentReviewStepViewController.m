/*
 Copyright (c) 2020, CareEvolution, Inc.
 
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

#import "ORK1StepViewController_Internal.h"
#import "ORK1StepHeaderView_Internal.h"

#import "ORK1DocumentReviewStepViewController.h"
#import "ORK1DocumentReviewStep.h"

#import "ORK1TaskViewController.h"
#import "ORK1Result.h"
#import "ORK1Step_Private.h"
#import "ORK1Helpers_Internal.h"
#import "ORK1NavigationContainerView_Internal.h"
#import "ORK1Skin.h"

#import "CEVRK1Theme.h"

@interface ORK1DocumentReviewStepViewController ()

@property (nonatomic, readonly) ORK1DocumentReviewStep* documentReviewStep;

@end

@implementation ORK1DocumentReviewStepViewController {
    ORK1StepHeaderView *_headerView;
    ORK1NavigationContainerView *_continueView;
    UIImageView *_imageView;
}

- (ORK1DocumentReviewStep *)documentReviewStep {
    return (ORK1DocumentReviewStep *)self.step;
}

- (instancetype)initWithStep:(ORK1Step *)step {
    self = [super initWithStep:step];
    if (self) {
        NSParameterAssert([step isKindOfClass:[ORK1DocumentReviewStep class]]);
        [self setUpViews];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = ORK1Color(ORK1BackgroundColorKey);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self displayResult];
}

- (void)setUpViews {
    _headerView = [[ORK1StepHeaderView alloc] init];
    _headerView.captionLabel.useSurveyMode = self.step.useSurveyMode;
    _headerView.captionLabel.text = self.step.title;
    [self displayInstructionText:self.step.text];
    [self.view addSubview:_headerView];
    
    _imageView = [[UIImageView alloc] init];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:_imageView];
    
    _continueView = [[ORK1NavigationContainerView alloc] init];
    _continueView.skipEnabled = NO;
    [self.view addSubview:_continueView];
    
    NSMutableArray *constraints = [NSMutableArray new];
    NSDictionary *views = NSDictionaryOfVariableBindings(_headerView, _imageView, _continueView);
    ORK1EnableAutoLayoutForViews([views allValues]);
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[_headerView]-8-[_imageView]-8-[_continueView]-36-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_headerView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_imageView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_continueView]-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:views]];
    
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)displayResult {
    ORK1StepResult *stepResult = [self.taskViewController.result stepResultForStepIdentifier:self.documentReviewStep.sourceStepIdentifier];
    ORK1FileResult *fileResult = (ORK1FileResult *)stepResult.firstResult;
    if (!fileResult.fileURL) {
        [self displayImage:nil];
        return;
    }
    
    if (![fileResult.contentType hasPrefix:@"image/"]) {
        ORK1_Log_Warning(@"Document review step: unsupported file result content type: %@", fileResult);
        [self displayImage:nil];
        return;
    }
    
    NSData *data = [NSData dataWithContentsOfURL:fileResult.fileURL];
    if (data) {
        [self displayImage:[UIImage imageWithData:data]];
    } else {
        ORK1_Log_Warning(@"Document review step: unable to load file from result %@", fileResult);
        [self displayImage:nil];
    }
}

- (void)displayImage:(UIImage *)image {
    if (image) {
        _imageView.image = image;
        _imageView.hidden = NO;
        [self displayInstructionText:self.step.text];
        _continueView.continueEnabled = YES;
    } else {
        _imageView.image = nil;
        _imageView.hidden = YES;
        [self displayInstructionText:self.documentReviewStep.noFileText ?: self.step.text];
        _continueView.continueEnabled = self.step.isOptional;
    }
}

- (void)displayInstructionText:(NSString *)text {
    _headerView.instructionTextView.hidden = !text.length;
    _headerView.instructionTextView.textValue = text;
}

- (void)setContinueButtonItem:(UIBarButtonItem *)continueButtonItem {
    [super setContinueButtonItem:continueButtonItem];
    _continueView.continueButtonItem = continueButtonItem;
}

@end
