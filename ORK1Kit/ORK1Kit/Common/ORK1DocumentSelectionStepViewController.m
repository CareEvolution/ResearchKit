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

#import "ORK1DocumentSelectionStepViewController.h"
#import "ORK1DocumentSelectionStep.h"

#import "ORK1Result.h"

#import "ORK1Step_Private.h"
#import "ORK1Helpers_Internal.h"
#import "ORK1BorderedButton.h"
#import "ORK1NavigationContainerView_Internal.h"
#import "ORK1Skin.h"

#import "CEVRK1Theme.h"

@import AVFoundation;
@import MobileCoreServices;
@import Photos;

@interface ORK1DocumentSelectionStepViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, readonly) BOOL isCameraAvailable;
@property (nonatomic, readonly) BOOL isPhotoLibraryAvailable;
@property (nonatomic, readonly) ORK1DocumentSelectionStep *documentSelectionStep;
@property (nonatomic, strong) UIImage *selectedPhoto;

@end

@implementation ORK1DocumentSelectionStepViewController {
    NSURL *_fileURL;
    ORK1NavigationContainerView *_continueSkipContainer;
}

- (BOOL)isCameraAvailable {
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

- (BOOL)isPhotoLibraryAvailable {
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (ORK1DocumentSelectionStep *)documentSelectionStep {
    return (ORK1DocumentSelectionStep *)self.step;
}

- (void)setSelectedPhoto:(UIImage *)selectedPhoto {
    _selectedPhoto = selectedPhoto;
    if (_fileURL) {
        [[NSFileManager defaultManager] removeItemAtURL:_fileURL error:NULL];
        _fileURL = nil;
    }
}

#pragma mark - Initialization

- (instancetype)initWithStep:(ORK1Step *)step result:(ORK1Result *)result {
    self = [self initWithStep:step];
    if (self) {
        ORK1StepResult *stepResult = (ORK1StepResult *)result;
        if (stepResult && [stepResult results].count > 0) {
            ORK1FileResult *fileResult = ORK1DynamicCast([stepResult results].firstObject, ORK1FileResult);
            if (fileResult.fileURL) {
                NSData *data = [NSData dataWithContentsOfURL:fileResult.fileURL];
                self.selectedPhoto = [UIImage imageWithData:data];
                if (self.selectedPhoto) {
                    _fileURL = fileResult.fileURL;
                }
            }
        }
    }
    return self;
}

- (instancetype)initWithStep:(ORK1Step *)step {
    self = [super initWithStep:step];
    if (self) {
        NSParameterAssert([step isKindOfClass:[ORK1DocumentSelectionStep class]]);
        [self setUpViews];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = ORK1Color(ORK1BackgroundColorKey);
}

- (void)setUpViews {
    ORK1StepHeaderView *headerView = [[ORK1StepHeaderView alloc] init];
    headerView.captionLabel.useSurveyMode = self.step.useSurveyMode;
    headerView.captionLabel.text = self.step.title;
    headerView.instructionTextView.hidden = !self.step.text.length;
    headerView.instructionTextView.textValue = self.step.text;
    [self.view addSubview:headerView];
    
    UIStackView *sourceStackView = [[UIStackView alloc] init];
    sourceStackView.axis = UILayoutConstraintAxisVertical;
    sourceStackView.alignment = UIStackViewAlignmentFill;
    sourceStackView.distribution = UIStackViewDistributionEqualSpacing;
    sourceStackView.spacing = 8;
    
    if (self.documentSelectionStep.allowCamera && self.isCameraAvailable) {
        ORK1BorderedButton *button = [[ORK1BorderedButton alloc] init];
        [button setTitle:ORK1LocalizedString(@"TAKE_PHOTO_BUTTON_TITLE", nil) forState:UIControlStateNormal];
        [button addTarget:self action:@selector(takePhoto) forControlEvents:UIControlEventTouchUpInside];
        button.contentEdgeInsets = UIEdgeInsetsMake(13, 35, 13, 35);
        [sourceStackView addArrangedSubview:button];
    }
    
    if (self.documentSelectionStep.allowPhotoLibrary && self.isPhotoLibraryAvailable) {
        ORK1BorderedButton *button = [[ORK1BorderedButton alloc] init];
        [button setTitle:ORK1LocalizedString(@"CHOOSE_PHOTO_BUTTON_TITLE", nil) forState:UIControlStateNormal];
        [button addTarget:self action:@selector(choosePhoto) forControlEvents:UIControlEventTouchUpInside];
        button.contentEdgeInsets = UIEdgeInsetsMake(13, 35, 13, 35);
        [sourceStackView addArrangedSubview:button];
    }
    
    [self.view addSubview:sourceStackView];
    
    _continueSkipContainer = [[ORK1NavigationContainerView alloc] init];
    _continueSkipContainer.neverHasContinueButton = YES;
    [self.view addSubview:_continueSkipContainer];
    
    NSMutableArray *constraints = [NSMutableArray new];
    NSDictionary *views = NSDictionaryOfVariableBindings(headerView, sourceStackView, _continueSkipContainer);
    ORK1EnableAutoLayoutForViews([views allValues]);

    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[headerView]-8-[sourceStackView]-(>=8)-[_continueSkipContainer]-36-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[headerView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_continueSkipContainer]-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:views]];

    id viewMarginItem = self.view;
    if (@available(iOS 11.0, *)) {
        viewMarginItem = self.view.safeAreaLayoutGuide;
    }
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:sourceStackView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:viewMarginItem attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:sourceStackView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationLessThanOrEqual toItem:viewMarginItem attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:sourceStackView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:viewMarginItem attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:sourceStackView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.view.readableContentGuide attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
    
    [NSLayoutConstraint activateConstraints:constraints];
    
    self.skipButtonItem = self.internalSkipButtonItem;
}

- (void)setSkipButtonItem:(UIBarButtonItem *)skipButtonItem {
    [super setSkipButtonItem:skipButtonItem];
    _continueSkipContainer.skipButtonItem = skipButtonItem;
    _continueSkipContainer.optional = self.step.isOptional;
    _continueSkipContainer.skipEnabled = self.step.isOptional;
}

- (void)notifyDelegateOnResultChange {
    [super notifyDelegateOnResultChange];
    self.skipButtonItem = self.internalSkipButtonItem;
}

#pragma mark - User interaction

- (void)takePhoto {
    ORK1WeakTypeOf(self) weakSelf = self;
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusDenied:
            [self handleError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSFeatureUnsupportedError userInfo:@{NSLocalizedDescriptionKey:ORK1LocalizedString(@"DOCUMENT_SELECTION_ERROR_NO_CAMERA_PERMISSIONS", nil)}] showSettingsButton:YES];
            break;
        case AVAuthorizationStatusRestricted:
            [self handleError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSFeatureUnsupportedError userInfo:@{NSLocalizedDescriptionKey:ORK1LocalizedString(@"DOCUMENT_SELECTION_ERROR_NO_CAMERA_PERMISSIONS", nil)}] showSettingsButton:YES];
            break;
        case AVAuthorizationStatusNotDetermined:
        case AVAuthorizationStatusAuthorized:
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (granted) {
                        [weakSelf presentAuthorizedPicker:UIImagePickerControllerSourceTypeCamera];
                    } else {
                        [weakSelf handleError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSFeatureUnsupportedError userInfo:@{NSLocalizedDescriptionKey:ORK1LocalizedString(@"DOCUMENT_SELECTION_ERROR_NO_CAMERA_PERMISSIONS", nil)}] showSettingsButton:YES];
                    }
                });
            }];
            break;
    }
}

- (void)choosePhoto {
    ORK1WeakTypeOf(self) weakSelf = self;
    switch ([PHPhotoLibrary authorizationStatus]) {
        case PHAuthorizationStatusDenied:
            [self handleError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSFeatureUnsupportedError userInfo:@{NSLocalizedDescriptionKey:ORK1LocalizedString(@"DOCUMENT_SELECTION_ERROR_NO_PHOTO_PERMISSIONS", nil)}] showSettingsButton:YES];
            break;
        case PHAuthorizationStatusRestricted:
            [self handleError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSFeatureUnsupportedError userInfo:@{NSLocalizedDescriptionKey:ORK1LocalizedString(@"DOCUMENT_SELECTION_ERROR_NO_PHOTO_PERMISSIONS", nil)}] showSettingsButton:YES];
            break;
        case PHAuthorizationStatusNotDetermined:
        case PHAuthorizationStatusAuthorized:
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (status == PHAuthorizationStatusAuthorized) {
                        [weakSelf presentAuthorizedPicker:UIImagePickerControllerSourceTypePhotoLibrary];
                    } else {
                        [weakSelf handleError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSFeatureUnsupportedError userInfo:@{NSLocalizedDescriptionKey:ORK1LocalizedString(@"DOCUMENT_SELECTION_ERROR_NO_PHOTO_PERMISSIONS", nil)}] showSettingsButton:YES];
                    }
                });
            }];
            break;
    }
}

- (void)presentAuthorizedPicker:(UIImagePickerControllerSourceType)sourceType {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = sourceType;
    picker.mediaTypes = @[(NSString *)kUTTypeImage];
    
    if (sourceType == UIImagePickerControllerSourceTypeCamera) {
        switch (self.documentSelectionStep.preferredCameraPosition) {
            case AVCaptureDevicePositionUnspecified:
            case AVCaptureDevicePositionBack:
                if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
                    picker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
                }
                break;
            case AVCaptureDevicePositionFront:
                if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
                    picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
                }
                break;
        }
    }
    
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)handleError:(NSError *)error showSettingsButton:(BOOL)showSettings {
    ORK1_Log_Warning(@"Document selection step error: %@", error.localizedDescription);
    self.selectedPhoto = nil;
    [self notifyDelegateOnResultChange];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    if (showSettings) {
        [alert addAction:[UIAlertAction actionWithTitle:ORK1LocalizedString(@"BUTTON_OPEN_SETTINGS", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSURL *URL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            if (URL) {
                [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:NULL];
            }
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:ORK1LocalizedString(@"BUTTON_CANCEL", nil) style:UIAlertActionStyleCancel handler:NULL]];

    [self presentViewController:alert animated:YES completion:NULL];
}

#pragma mark - Results and file handling

- (void)skipForward {
    self.selectedPhoto = nil;
    [self notifyDelegateOnResultChange];
    [super skipForward];
}

- (ORK1StepResult *)result {
    ORK1StepResult *stepResult = [super result];
    if (!stepResult) {
        return nil;
    }
    
    NSDate *now = stepResult.endDate;
    
    // If we have captured data, but have not yet written that data to a file, do it now
    if (!_fileURL && _selectedPhoto) {
        NSError *error = nil;
        _fileURL = [self writeSelectedPhotoWithError:&error];
        if (!_fileURL) {
            ORK1_Log_Warning(@"Document selection step error: %@", error.localizedDescription);
            self.selectedPhoto = nil;
        }
    }
    
    ORK1FileResult *fileResult = [[ORK1FileResult alloc] initWithIdentifier:self.step.identifier];
    fileResult.startDate = stepResult.startDate;
    fileResult.endDate = now;
    fileResult.contentType = @"image/jpeg";
    fileResult.fileURL = _fileURL;
    
    NSMutableArray *results = [NSMutableArray arrayWithArray:stepResult.results];
    [results addObject:fileResult];
    stepResult.results = [results copy];
    return stepResult;
}

- (NSURL *)writeSelectedPhotoWithError:(NSError **)error {
    NSURL *URL = [self.outputDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg",self.step.identifier]];
    if (!URL) {
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteInvalidFileNameError userInfo:@{NSLocalizedDescriptionKey:ORK1LocalizedString(@"ERROR_RECORDER_NO_OUTPUT_DIRECTORY", nil)}];
        }
        return nil;
    }
    
    NSData *data = UIImageJPEGRepresentation(_selectedPhoto, 0.95);
    if (!data) {
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteInvalidFileNameError userInfo:@{NSLocalizedDescriptionKey:ORK1LocalizedString(@"ERROR_DATALOGGER_CREATE_FILE", nil)}];
        }
        return nil;
    }
    
    NSError *writeError = nil;
    if (![data writeToURL:URL options:NSDataWritingAtomic|NSDataWritingFileProtectionCompleteUnlessOpen error:&writeError]) {
        if (writeError) {
            ORK1_Log_Warning(@"%@", writeError);
        }
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteInvalidFileNameError userInfo:@{NSLocalizedDescriptionKey:ORK1LocalizedString(@"ERROR_DATALOGGER_CREATE_FILE", nil)}];
        }
        return nil;
    }
    
    return URL;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    self.selectedPhoto = nil;
    [self notifyDelegateOnResultChange];
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    ORK1WeakTypeOf(self) weakSelf = self;
    UIImage *selectedPhoto = [info objectForKey:UIImagePickerControllerEditedImage] ?: [info objectForKey:UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:^{
        ORK1StrongTypeOf(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            strongSelf.selectedPhoto = selectedPhoto;
            // Triggers updating the result which can produce errors.
            // Only go forward if there's no error.
            [strongSelf notifyDelegateOnResultChange];
            if (strongSelf.selectedPhoto) {
                [strongSelf goForward];
            } else {
                [strongSelf handleError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteInvalidFileNameError userInfo:@{NSLocalizedDescriptionKey:ORK1LocalizedString(@"ERROR_DATALOGGER_CREATE_FILE", nil)}] showSettingsButton:NO];
            }
        }
    }];
}

@end
