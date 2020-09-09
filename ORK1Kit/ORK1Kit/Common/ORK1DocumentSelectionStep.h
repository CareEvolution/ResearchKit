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


#import <ORK1Kit/ORK1Step.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The `ORK1WebViewStep` class represents a step that allows selection of an image or
 other file from one of multiple sources. The selected file is referenced in the step's
 `ORK1FileResult` object.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1DocumentSelectionStep : ORK1Step

/**
 A Boolean value indicating whether the user can provide an image using the device's
 camera (if available). When the value is `YES`, a button is displayed that allows the
 user to open a camera view, after prompting for permission if necessary.
 */
@property (nonatomic) BOOL allowCamera;

/**
 A Boolean value indicating whether the user can select an image from the Photos app.
 When the value is `YES`, a button is displayed that allows the user to open the photo
 picker, after prompting for permission if necessary.
 */
@property (nonatomic) BOOL allowPhotoLibrary;

/**
 Configures the preferred behavior of the camera view.
 If `AVCaptureDevicePositionUnspecified` is set, then it defaults to `AVCaptureDevicePositionBack`.
 */
@property (nonatomic) AVCaptureDevicePosition preferredCameraPosition;

@end

NS_ASSUME_NONNULL_END
