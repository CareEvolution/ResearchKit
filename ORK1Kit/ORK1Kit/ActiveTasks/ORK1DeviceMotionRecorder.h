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


@import UIKit;
#import <ORK1Kit/ORK1Recorder.h>


NS_ASSUME_NONNULL_BEGIN

@class CMDeviceMotion;

@protocol ORK1DeviceMotionRecorderDelegate <ORK1RecorderDelegate>

@optional

- (void)deviceMotionRecorderDidUpdateWithMotion:(CMDeviceMotion *)motion;

@end

/**
 The `ORK1DeviceMotionRecorder` class represents a recorder that requests and collects device motion data from CoreMotion at a fixed frequency.
 
 To ensure that the motion recorder continues to record when the app enters the
 background, use the background task support provided by `UIApplication`.
 */
ORK1_CLASS_AVAILABLE
@interface ORK1DeviceMotionRecorder : ORK1Recorder

/**
 The frequency of motion data collection from CoreMotion in hertz (Hz).
 */
@property (nonatomic, readonly) double frequency;

/**
 Returns an initialized device motion recorder using the specified frequency.
 
 @param identifier          The unique identifier of the recorder (assigned by the recorder configuration).
 @param frequency           The frequency of motion data collection from CoreMotion in hertz (Hz).
 @param step                The step that requested this recorder.
 @param outputDirectory     The directory in which the device motion data should be stored.
 
 @return An initialized motion data recorder.
 */
- (instancetype)initWithIdentifier:(NSString *)identifier
                         frequency:(double)frequency
                              step:(nullable ORK1Step *)step
                   outputDirectory:(nullable NSURL *)outputDirectory NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
