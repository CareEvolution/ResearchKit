/*
 Copyright (c) 2016, Sage Bionetworks
 Copyright (c) 2016, Apple Inc.
 
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


#import "ORK1AudioLevelNavigationRule.h"

#import "ORK1Result.h"
#import "ORK1ResultPredicate.h"
#import "ORK1StepNavigationRule_Internal.h"

#import "ORK1Helpers_Internal.h"

#import <AVFoundation/AVFoundation.h>


Float32 const VolumeThreshold = 0.45;
UInt16  const LinearPCMBitDepth = 16;
Float32 const MaxAmplitude = 32767.0;
Float32 const VolumeClamp = 60.0;


@interface ORK1AudioLevelNavigationRule ()

@property (nonatomic, copy, readwrite) NSString *audioLevelStepIdentifier;
@property (nonatomic, copy, readwrite) NSString *destinationStepIdentifier;
@property (nonatomic, copy, readwrite) NSDictionary *recordingSettings;

@end


@implementation ORK1AudioLevelNavigationRule

+ (instancetype)new {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)init {
    ORK1ThrowMethodUnavailableException();
}

- (instancetype)initWithAudioLevelStepIdentifier:(NSString *)audioLevelStepIdentifier
                       destinationStepIdentifier:(NSString *)destinationStepIdentifier
                               recordingSettings:(NSDictionary *)recordingSettings
{
    ORK1ThrowInvalidArgumentExceptionIfNil(audioLevelStepIdentifier);
    ORK1ThrowInvalidArgumentExceptionIfNil(destinationStepIdentifier);
    ORK1ThrowInvalidArgumentExceptionIfNil(recordingSettings);
    self = [super init];
    if (self) {
        _audioLevelStepIdentifier = [audioLevelStepIdentifier copy];
        _destinationStepIdentifier = [destinationStepIdentifier copy];
        _recordingSettings = [recordingSettings copy];
    }
    return self;
}

#pragma mark NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK1_DECODE_OBJ_CLASS(aDecoder, audioLevelStepIdentifier, NSString);
        ORK1_DECODE_OBJ_CLASS(aDecoder, destinationStepIdentifier, NSString);
        ORK1_DECODE_OBJ_CLASS(aDecoder, recordingSettings, NSDictionary);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK1_ENCODE_OBJ(aCoder, audioLevelStepIdentifier);
    ORK1_ENCODE_OBJ(aCoder, destinationStepIdentifier);
    ORK1_ENCODE_OBJ(aCoder, recordingSettings);
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    typeof(self) rule = [[[self class] allocWithZone:zone] initWithAudioLevelStepIdentifier:self.audioLevelStepIdentifier destinationStepIdentifier:self.destinationStepIdentifier recordingSettings:self.recordingSettings];
    return rule;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    __typeof(self) castObject = object;
    return (isParentSame
            && ORK1EqualObjects(self.audioLevelStepIdentifier, castObject.audioLevelStepIdentifier)
            && ORK1EqualObjects(self.destinationStepIdentifier, castObject.destinationStepIdentifier)
            && ORK1EqualObjects(self.recordingSettings, castObject.recordingSettings));
}

- (NSUInteger)hash {
    return _audioLevelStepIdentifier.hash ^ _destinationStepIdentifier.hash ^ _recordingSettings.hash;
}

#pragma mark - Required overrides

- (NSString *)identifierForDestinationStepWithTaskResult:(ORK1TaskResult *)taskResult {
    
    // Get the result file
    ORK1StepResult *stepResult = (ORK1StepResult *)[taskResult resultForIdentifier:self.audioLevelStepIdentifier];
    ORK1FileResult *audioLevelResult = (ORK1FileResult *)[stepResult.results firstObject];
    
    // Check the volume
    if ((audioLevelResult.fileURL != nil) && [self checkAudioLevelFromSoundFile:audioLevelResult.fileURL]) {
        // Returning nil will drop through to the next step (which should be the the step that has the instructions
        // for moving to a quieter room).
        return nil;
    }
    
    return self.destinationStepIdentifier;
}

- (BOOL)checkAudioLevelFromSoundFile:(NSURL *)fileURL {
    // Setup reader
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:fileURL options:nil];
    if (urlAsset.tracks.count == 0) {
        NSLog(@"No tracks found for urlAsset: %@", fileURL);
        return NO;
    }
    
    NSError *error = nil;
    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:urlAsset error:&error];
    AVAssetTrack *track = [urlAsset.tracks objectAtIndex:0];
    NSDictionary *outputSettings = @{AVFormatIDKey: @(kAudioFormatLinearPCM),
                                     AVLinearPCMBitDepthKey: @(LinearPCMBitDepth),
                                     AVLinearPCMIsBigEndianKey: @(NO),
                                     AVLinearPCMIsFloatKey: @(NO),
                                     AVLinearPCMIsNonInterleaved: @(NO)};
    AVAssetReaderTrackOutput *output = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:outputSettings];
    [reader addOutput:output];
    
    // Setup initial values - Assume 2 channels if not in recording settings
    const UInt32 channelCount = (UInt32)[self.recordingSettings[AVNumberOfChannelsKey] unsignedIntegerValue] ? : 2;
    const UInt32 bytesPerSample = 2 * channelCount;
    
    // setup criteria block - Use a high-pass filter and a rolling average of the amplitude
    // normalized to be < 1
    __block Float32 rollingAvg = 0;
    __block UInt64 totalCount = 0;
    void (^processVolume)(Float32) = ^(Float32 amplitude) {
        if (amplitude != 0) {
            Float32 dB = 20 * log10(ABS(amplitude) / MaxAmplitude);
            float clampedValue = MAX(dB / VolumeClamp, -1) + 1;
            totalCount++;
            rollingAvg = (rollingAvg * (totalCount - 1) + clampedValue) / totalCount;
        }
    };
    
    // While there are samples to read and the number of samples above the decibel threshold
    // is less than the total number of allowed samples over the limit, keep going
    [reader startReading];
    while (reader.status == AVAssetReaderStatusReading) {
        
        AVAssetReaderTrackOutput *trackOutput = (AVAssetReaderTrackOutput *)[reader.outputs objectAtIndex:0];
        CMSampleBufferRef sampleBufferRef = [trackOutput copyNextSampleBuffer];
        
        if (sampleBufferRef) {
            CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBufferRef);
            size_t length = CMBlockBufferGetDataLength(blockBufferRef);
            
            NSMutableData *data = [NSMutableData dataWithLength:length];
            CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, data.mutableBytes);
            
            SInt16 *samples = (SInt16 *) data.mutableBytes;
            UInt64 sampleCount = length / bytesPerSample;
            for (UInt32 i = 0; i < sampleCount ; i++) {
                Float32 left = (Float32) *samples++;
                processVolume(left);
                if (channelCount == 2) {
                    Float32 right = (Float32) *samples++;
                    processVolume(right);
                }
            }
            
            CMSampleBufferInvalidate(sampleBufferRef);
            CFRelease(sampleBufferRef);
        }
    }
    
    return rollingAvg > VolumeThreshold;
}


@end
